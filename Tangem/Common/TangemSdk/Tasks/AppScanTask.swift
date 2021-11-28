//
//  AppScanTask.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AppScanTaskResponse {
    let card: Card
    let walletData: WalletData?
    let twinIssuerData: Data?
    let isTangemNote: Bool //todo refactor
    let isTangemWallet: Bool
    let derivedKeys: [Data: [ExtendedPublicKey]]
    let primaryCard: PrimaryCard?
    
    func getCardInfo() -> CardInfo {
        return CardInfo(card: card,
                        walletData: walletData,
                        //                        artworkInfo: nil,
                        twinCardInfo: decodeTwinFile(from: self),
                        isTangemNote: isTangemNote,
                        isTangemWallet: isTangemWallet,
                        derivedKeys: derivedKeys,
                        primaryCard: primaryCard)
    }
    
    private func decodeTwinFile(from response: AppScanTaskResponse) -> TwinCardInfo? {
        guard
            card.isTwinCard,
            let series: TwinCardSeries = .series(for: card.cardId)
        else {
            return nil
        }
        
        var pairPublicKey: Data?
        
        if let walletPubKey = card.wallets.first?.publicKey, let fullData = twinIssuerData, fullData.count == 129 {
            let pairPubKey = fullData[0..<65]
            let signature = fullData[65..<fullData.count]
            if let _ = try? Secp256k1Utils.verify(publicKey: walletPubKey, message: pairPubKey, signature: signature) {
                pairPublicKey = pairPubKey
            }
        }
        
        return TwinCardInfo(cid: response.card.cardId,
                            series: series,
                            pairPublicKey: pairPublicKey)
    }
}

final class AppScanTask: CardSessionRunnable {
    deinit {
        print("AppScanTask deinit")
    }
    
    private let tokenItemsRepository: TokenItemsRepository?
    private let userPrefsService: UserPrefsService?
    
    private let targetBatch: String?
    private var twinIssuerData: Data? = nil
    private var noteWalletData: WalletData? = nil
    private var primaryCard: PrimaryCard? = nil

    private var derivedKeys: [Data: [ExtendedPublicKey]] = [:]

    
    init(tokenItemsRepository: TokenItemsRepository?, userPrefsService: UserPrefsService?, targetBatch: String? = nil) {
        self.tokenItemsRepository = tokenItemsRepository
        self.targetBatch = targetBatch
        self.userPrefsService = userPrefsService
    }
    
    /// read ->  readTwinData or note Data or derive wallet's keys -> appendWallets(createwallets+ scan)  -> attestation
    public func run(in session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }
        
        let currentBatch = card.batchId.lowercased()
        
        if let targetBatch = self.targetBatch?.lowercased(),
           targetBatch != currentBatch {
            completion(.failure(TangemSdkError.underlying(error: "alert_wrong_card_scanned".localized)))
            return
        }
        
        self.readExtra(card, session: session, completion: completion)
    }
    
    private func readExtra(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        if card.isTwinCard {
            readTwin(card, session: session, completion: completion)
            return
        }
        
        if card.firmwareVersion.doubleValue >= 4.39 {
            if card.settings.maxWalletsCount == 1 {
                readNote(card, session: session, completion: completion)
                return
            }
            
            if let userPrefsService = self.userPrefsService,
               userPrefsService.cardsStartedActivation.contains(card.cardId),
               card.backupStatus == .noBackup {
                readPrimaryCard(session, completion)
                return
            } else {
                deriveKeysIfNeeded(session, completion)
                return
            }
            
        }
        
        
        runAttestation(session, completion)
    }
    
    private func readNote(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        // self.noteWalletData = WalletData(blockchain: "BTC") //for test without file
        // self.runAttestation(session, completion)
        // return
        
        let readFileCommand = ReadFilesTask(fileName: "blockchainInfo", walletPublicKey: nil)
        readFileCommand.run(in: session) { (result) in
            switch result {
            case .success(let response):
                
                func exit() {
                    self.noteWalletData = nil
                    self.appendWalletsIfNeeded(session: session, completion: completion)
                }
                
                guard let file = response.first,
                      let namedFile = try? NamedFile(tlvData: file.data),
                      let tlv = Tlv.deserialize(namedFile.payload),
                      let fileSignature = namedFile.signature,
                      let fileCounter = namedFile.counter,
                      let walletData = try? WalletDataDeserializer().deserialize(decoder: TlvDecoder(tlv: tlv)) else {
                    exit()
                    return
                }
                
                let dataToVerify = Data(hexString: card.cardId) + namedFile.payload + fileCounter.bytes4
                let isVerified: Bool = (try? CryptoUtils.verify(curve: .secp256k1,
                                                                publicKey: card.issuer.publicKey,
                                                                message: dataToVerify,
                                                                signature: fileSignature)) ?? false
                
                guard isVerified else {
                    exit()
                    return
                }
                
                self.noteWalletData = walletData
                self.runAttestation(session, completion)
            case .failure(let error):
                switch error {
                case .fileNotFound, .insNotSupported:
                    self.noteWalletData = nil
                    self.appendWalletsIfNeeded(session: session, completion: completion)
                default:
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func readTwin(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let readIssuerDataCommand = ReadIssuerDataCommand()
        readIssuerDataCommand.run(in: session) { (result) in
            switch result {
            case .success(let response):
                self.twinIssuerData = response.issuerData
                
                guard session.environment.card != nil else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                self.runAttestation(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func appendWalletsIfNeeded(session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let card = session.environment.card!
        
        let existingCurves: Set<EllipticCurve> = .init(card.wallets.map({ $0.curve }))
        let mandatoryСurves: Set<EllipticCurve> = [.secp256k1, .ed25519]
        let missingCurves = mandatoryСurves.subtracting(existingCurves)
        
        if !existingCurves.isEmpty, // not empty card
           !missingCurves.isEmpty //not enough curves
        {
            appendWallets(Array(missingCurves), session: session, completion: completion)
            return
        }
        
        deriveKeysIfNeeded(session, completion)
    }
    
    private func appendWallets(_ curves: [EllipticCurve], session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        CreateMultiWalletTask(curves: curves).run(in: session) { result in
            switch result {
            case .success:
                self.runAttestation(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readPrimaryCard(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        StartPrimaryCardLinkingCommand().run(in: session) { result in
            switch result {
            case .success(let primaryCard):
                self.primaryCard = primaryCard
                self.deriveKeysIfNeeded(session, completion)
            case .failure: //ignore any error
                self.deriveKeysIfNeeded(session, completion)
            }
        }
    }
    
    private func deriveKeysIfNeeded(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let tokenItemsRepository = self.tokenItemsRepository,
              let wallet = session.environment.card?.wallets.first( where: { $0.curve == .secp256k1 }),
              wallet.chainCode != nil else {
                  self.runAttestation(session, completion)
                  return
              }
        
        let derivationPathes = Set(tokenItemsRepository.getItems(for: session.environment.card!.cardId).map { $0.blockchain })
            .filter { $0.curve == .secp256k1 }
            .compactMap { $0.derivationPath }
        
        if derivationPathes.isEmpty {
            self.runAttestation(session, completion)
            return
        }
        
        DeriveWalletPublicKeysTask(walletPublicKey: wallet.publicKey, derivationPathes: derivationPathes).run(in: session) { result in
            switch result {
            case .success(let keys):
                self.derivedKeys = [wallet.publicKey : keys]
                self.runAttestation(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func runAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let attestationTask = AttestationTask(mode: session.environment.config.attestationMode)
        attestationTask.run(in: session) { result in
            switch result {
            case .success(let report):
                self.processAttestationReport(report, attestationTask, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //TODO: Localize
    private func processAttestationReport(_ report: Attestation,
                                          _ attestationTask: AttestationTask,
                                          _ session: CardSession,
                                          _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        switch report.status {
        case .failed, .skipped:
            let isDevelopmentCard = session.environment.card!.firmwareVersion.type == .sdk
        
            //Possible production sample or development card
            session.viewDelegate.setState(.empty)
            if isDevelopmentCard || session.environment.config.allowUntrustedCards {
                session.viewDelegate.attestationDidFail(isDevelopmentCard: isDevelopmentCard) {
                    self.complete(session, completion)
                } onCancel: {
                    completion(.failure(.userCancelled))
                }
                
                return
            }
            
            completion(.failure(.cardVerificationFailed))
            
        case .verified:
            self.complete(session, completion)
            
        case .verifiedOffline:
            if session.environment.config.attestationMode == .offline {
                self.complete(session, completion)
                return
            }
            
            session.viewDelegate.setState(.empty)
            session.viewDelegate.attestationCompletedOffline() {
                self.complete(session, completion)
            } onCancel: {
                completion(.failure(.userCancelled))
            } onRetry: {
                attestationTask.retryOnline(session) { result in
                    switch result {
                    case .success(let report):
                        self.processAttestationReport(report, attestationTask, session, completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            
        case .warning:
            session.viewDelegate.setState(.empty)
            session.viewDelegate.attestationCompletedWithWarnings {
                self.complete(session, completion)
            }
        }
    }
    
    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let card = session.environment.card!
        let isNote = noteWalletData != nil
        let isWallet = card.firmwareVersion.doubleValue >= 4.39 && !isNote
        completion(.success(AppScanTaskResponse(card: session.environment.card!,
                                                walletData: noteWalletData ?? session.environment.walletData,
                                                twinIssuerData: twinIssuerData,
                                                isTangemNote: noteWalletData != nil,
                                                isTangemWallet: isWallet,
                                                derivedKeys: derivedKeys,
                                                primaryCard: self.primaryCard)))
    }
}
