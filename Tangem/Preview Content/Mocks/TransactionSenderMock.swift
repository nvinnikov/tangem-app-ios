//
//  TransactionSenderMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSwapping
import BlockchainSdk

struct TransactionSenderMock: SwappingTransactionSender {
    func sendTransaction(_ data: SwappingTransactionData) async throws -> TransactionSendResult { TransactionSendResult(hash: "") }
}

struct FiatRatesProviderMock: FiatRatesProviding {
    func getSyncFiat(for currency: TangemSwapping.Currency, amount: Decimal) -> Decimal? { .zero }
    func getSyncFiat(for blockchain: TangemSwapping.SwappingBlockchain, amount: Decimal) -> Decimal? { .zero }
    func getFiat(for currency: TangemSwapping.Currency, amount: Decimal) async throws -> Decimal { .zero }
    func getFiat(for blockchain: TangemSwapping.SwappingBlockchain, amount: Decimal) async throws -> Decimal { .zero }
    func hasRates(for currency: Currency) -> Bool { false }
    func hasRates(for blockchain: SwappingBlockchain) -> Bool { false }
}

struct SwappingFeeFormatterMock: SwappingFeeFormatter {
    func format(fee: Decimal, blockchain: SwappingBlockchain) async throws -> String { "" }
    func format(fee: Decimal, blockchain: SwappingBlockchain) throws -> String { "" }
}
