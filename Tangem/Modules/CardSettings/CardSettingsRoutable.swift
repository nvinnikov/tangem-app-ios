//
//  CardSettingsRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol CardSettingsRoutable: AnyObject {
    func openOnboarding(with input: OnboardingInput, hasOtherCards: Bool)
    func openSecurityMode(cardModel: CardViewModel)
    func openResetCardToFactoryWarning(with input: ResetToFactoryViewModel.Input)
    func openAccessCodeRecoverySettings(using provider: AccessCodeRecoverySettingsProvider)
    func dismiss()
    func popToRoot()
}
