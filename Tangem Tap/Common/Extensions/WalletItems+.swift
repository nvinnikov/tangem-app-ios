//
//  WalletItems+.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Array where Element == WalletItem {
    mutating func remove(token: Token) {
        if let index = firstIndex(where: { $0.token == token }) {
            remove(at: index)
        }
    }
    
    mutating func remove(blockchain: Blockchain) {
        if let index = firstIndex(where: { $0.blockchain == blockchain }) {
            remove(at: index)
        }
    }
    
    mutating func remove(_ walletItem: WalletItem) {
        if let index = firstIndex(where: { $0 == walletItem }) {
            remove(at: index)
        }
    }
}
