//
//  RateAppProtocol.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol RateAppProtocol: AnyObject {
    var shouldShowRateAppWarning: Bool { get }
    var shouldCheckBalanceForRateApp: Bool { get }
    func registerPositiveBalanceDate()
    func dismissRateAppWarning()
    func userReactToRateAppWarning(isPositive: Bool)
}


private struct RateAppProtocolKey: InjectionKey {
    static var currentValue: RateAppProtocol = RateAppService()
}

extension InjectedValues {
    var rateAppService: RateAppProtocol {
        get { Self[RateAppProtocolKey.self] }
        set { Self[RateAppProtocolKey.self] = newValue }
    }
}
