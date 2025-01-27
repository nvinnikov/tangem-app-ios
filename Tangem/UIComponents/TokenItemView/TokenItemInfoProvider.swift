//
//  TokenItemInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol TokenItemInfoProvider: AnyObject {
    var walletStatePublisher: AnyPublisher<WalletModel.State, Never> { get }
    var pendingTransactionPublisher: AnyPublisher<(WalletModelId, Bool), Never> { get }

    func balance(for amountType: Amount.AmountType) -> Decimal
}
