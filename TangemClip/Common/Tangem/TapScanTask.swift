//
//  TapScanTask.swift
//  TangemClip
//
//  Created by Andrew Son on 22/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips

enum ScanError: Error {
    case wrongState
}

struct TapScanTaskResponse: JSONStringConvertible {
    let card: Card
    let twinIssuerData: Data
    
    internal init(card: Card, twinIssuerData: Data = Data()) {
        self.card = card
        self.twinIssuerData = twinIssuerData
    }
}

extension TapScanTaskResponse {
    func getCardInfo() -> CardInfo {
        let cardInfo = CardInfo(card: card,
                                artworkInfo: nil,
                                twinCardInfo: nil)
        return cardInfo
    }
}

final class TapScanTask: CardSessionRunnable, PreflightReadCapable {
    let excludeBatches = ["0027",
                          "0030",
                          "0031", //tags
    ]
    
    var preflightReadSettings: PreflightReadSettings { .fullCardRead }
    
    let excludeIssuers = ["TTM BANK"]
    
    deinit {
        print("TapScanTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        do {
            try checkCard(card)
        } catch let error as TangemSdkError {
            completion(.failure(error))
            return
        } catch { print(error) }
        
        verifyCard(card, session: session, completion: completion)
    }
    
    private func checkCard(_ card: Card) throws {
        if let product = card.cardData?.productMask, !(product.contains(ProductMask.note) || product.contains(.twinCard)) { //filter product
            throw TangemSdkError.underlying(error: "alert_unsupported_card".localized)
        }
        
        if let status = card.status { //filter status
            if status == .notPersonalized {
                throw TangemSdkError.notPersonalized
            }
            
            if status == .purged {
                throw TangemSdkError.cardIsPurged
            }
        }
        
        if let batch = card.cardData?.batchId, self.excludeBatches.contains(batch) { //filter batch
            throw TangemSdkError.underlying(error: "alert_unsupported_card".localized)
        }
        
        if let issuer = card.cardData?.issuerName, excludeIssuers.contains(issuer) { //filter issuer
            throw TangemSdkError.underlying(error: "alert_unsupported_card".localized)
        }
    }
    
//    private func checkWallet(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
//        guard let cardStatus = card.status, cardStatus == .loaded else {
//            self.verifyCard(card, session: session, completion: completion)
//            return
//        }
//
//        guard let curve = card.curve,
//            let publicKey = card.walletPublicKey else {
//                completion(.failure(.cardError))
//                return
//        }
//
//        CheckWalletCommand(curve: curve, publicKey: publicKey).run(in: session) { checkWalletResult in
//            switch checkWalletResult {
//            case .success:
//                self.verifyCard(card, session: session, completion: completion)
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    
    private func verifyCard(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        VerifyCardCommand().run(in: session) { verifyResult in
            switch verifyResult {
            case .success:
                completion(.success(TapScanTaskResponse(card: card)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
