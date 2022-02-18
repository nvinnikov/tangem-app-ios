//
//  Web3StoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct Web3StoryPage: View {
    var scanCard: (() -> Void)
    var orderCard: (() -> Void)
    
    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            Text("story_web3_title")
                .font(.system(size: 36, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding()
                .padding(.top, StoriesConstants.titleExtraTopPadding)
            
            Text("story_web3_description")
                .font(.system(size: 20))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
          
            Spacer()
            
            Color.clear
                .background(
                    Image("dapps")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fixedSize(horizontal: false, vertical: true)
                    ,
                    alignment: .top
                    
                )
                .clipped()
                .overlay(
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            LinearGradient(colors: [.white.opacity(0), .white], startPoint: .top, endPoint: .bottom)
                                .frame(height: geometry.size.height / 4)
                        }
                    }
                )
            
            HStack {
                Button {
                    scanCard()
                } label: {
                    Text("home_button_scan")
                }
                .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt, layout: .flexibleWidth))
                
                Button {
                    orderCard()
                } label: {
                    Text("home_button_order")
                }
                .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Web3StoryPage_Previews: PreviewProvider {
    static var previews: some View {
        Web3StoryPage { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
