//
//  SwitchChainHandler.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import BlockchainSdk

class SwitchChainHandler: TangemWalletConnectRequestHandler {
    var action: WalletConnectAction { .switchChain }

    weak var delegate: WalletConnectHandlerDelegate?
    weak var dataSource: WalletConnectHandlerDataSource?

    private var bag: Set<AnyCancellable> = []

    init(delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
    }

    func handle(request: Request) {
        do {
            let chainIdHexString = (try request.parameter(of: [String: String].self, at: 0))["chainId"]
            let chainId = chainIdHexString.map { Data(hexString: $0) }?.toInt()

            guard let session = dataSource?.session(for: request),
                  let chainId = chainId else {
                delegate?.send(.reject(request), for: action)
                return
            }

            let sessionWalletInfo = try switchChain(session, chainId: chainId)
            delegate?.sendUpdate(for: session.session, with: sessionWalletInfo)
        } catch {
            delegate?.sendReject(for: request, with: error, for: action)
        }
    }

    private func switchChain(_ session: WalletConnectSession, chainId: Int) throws -> Session.WalletInfo {
        var session = session
        let oldWalletInfo = session.wallet

        guard let oldSessionWalletInfo = session.session.walletInfo else {
            throw WalletConnectServiceError.sessionNotFound
        }

        let supportedBlockchains = Blockchain.supportedBlockchains.union(Blockchain.supportedTestnetBlockchains)

        guard let targetBlockchain = supportedBlockchains.first(where: { $0.chainId == chainId }) else {
            throw WalletConnectServiceError.unsupportedNetwork
        }

        let allTargetWallets = dataSource?.cardModel.walletModels
            .filter { $0.wallet.blockchain == targetBlockchain }
            .map { $0.wallet } ?? []

        if allTargetWallets.isEmpty {
            throw WalletConnectServiceError.networkNotFound(name: targetBlockchain.displayName)
        }

        let availableWallets = allTargetWallets
            .filter { $0.address == oldWalletInfo.address }

        guard let wallet = availableWallets.first else {
            throw WalletConnectServiceError.switchChainNotSupported
        }

        let derivedKey = wallet.publicKey.blockchainKey != wallet.publicKey.seedKey ? wallet.publicKey.blockchainKey : nil
        let walletInfo = WalletInfo(
            walletPublicKey: wallet.publicKey.seedKey,
            derivedPublicKey: derivedKey,
            derivationPath: wallet.publicKey.derivationPath,
            blockchain: targetBlockchain
        )

        session.wallet = walletInfo
        dataSource?.updateSession(session)

        return Session.WalletInfo(
            approved: true,
            accounts: [wallet.address],
            chainId: chainId,
            peerId: oldSessionWalletInfo.peerId,
            peerMeta: oldSessionWalletInfo.peerMeta
        )
    }
}
