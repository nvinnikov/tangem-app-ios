//
//  ScrollableButtonsView.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ScrollableButtonsView: View {
    /// Use this property to expand scroll view beyond parent view
    /// This is usefull when your parent view has paddings, but scroll must
    /// go to the edge of the scree
    let itemsHorizontalOffset: CGFloat
    let buttonsInfo: [ButtonWithIconInfo]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(buttonsInfo) { button in
                    ButtonWithLeadingIcon(
                        title: button.title,
                        icon: button.icon.image,
                        action: button.action
                    )
                }
            }
            .padding(.horizontal, itemsHorizontalOffset)
        }
        .padding(.horizontal, -itemsHorizontalOffset)
    }
}

struct ScrollableButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ScrollableButtonsView(
                itemsHorizontalOffset: 16,
                buttonsInfo: [
                    ButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, action: {}),
                    ButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, action: {}),
                    ButtonWithIconInfo(title: "Receive", icon: Assets.arrowDownMini, action: {}),
                    ButtonWithIconInfo(title: "Exchange", icon: Assets.exchangeMini, action: {}),
                    ButtonWithIconInfo(title: "Organize tokens", icon: Assets.sliders, action: {}),
                    ButtonWithIconInfo(title: "", icon: Assets.horizontalDots, action: {}),
                ]
            )

            ScrollableButtonsView(
                itemsHorizontalOffset: 0,
                buttonsInfo: [
                    ButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, action: {}),
                    ButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, action: {}),
                    ButtonWithIconInfo(title: "Receive", icon: Assets.arrowDownMini, action: {}),
                    ButtonWithIconInfo(title: "Exchange", icon: Assets.exchangeMini, action: {}),
                    ButtonWithIconInfo(title: "Organize tokens", icon: Assets.sliders, action: {}),
                    ButtonWithIconInfo(title: "", icon: Assets.horizontalDots, action: {}),
                ]
            )

            ScrollableButtonsView(
                itemsHorizontalOffset: 0,
                buttonsInfo: [
                    ButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, action: {}),
                    ButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, action: {}),
                ]
            )
        }
        .padding(.horizontal, 16)
    }
}
