//
//  RateAppService.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol RateAppService: AnyObject {
    var shouldShowRateAppWarning: Bool { get }
    var shouldCheckBalanceForRateApp: Bool { get }
    func registerPositiveBalanceDate()
    func dismissRateAppWarning()
    func userReactToRateAppWarning(isPositive: Bool)
}

private struct RateAppServiceKey: InjectionKey {
    static var currentValue: RateAppService = CommonRateAppService()
}

extension InjectedValues {
    var rateAppService: RateAppService {
        get { Self[RateAppServiceKey.self] }
        set { Self[RateAppServiceKey.self] = newValue }
    }
}
