//
//  KYCView.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct KYCView: View {
    let imageType: ImageType
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            imageType.image
                .padding(.bottom, 15)

            Spacer()

            Text(title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(subtitle)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)

            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
    }
}

struct KYCView_Previews: PreviewProvider {
    static var previews: some View {
        KYCView(
            imageType: Assets.passport,
            title: Localization.onboardingTitlePin,
            subtitle: Localization.onboardingSubtitlePin
        )
    }
}
