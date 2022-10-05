//
//  Responses.swift
//  Tangem
//
//  Created by Alexander Osokin on 05.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct RegistrationResponse: Codable, ErrorContainer {
    let results: [RegistrationResponse.Item]
    let error: String?
    let errorCode: String?
    let success: Bool
}

extension RegistrationResponse {
    struct Item: Codable, ErrorContainer {
        let cardId: String
        let error: String?
        let passed: Bool?
        let active: Bool?
        let pinSet: Bool?
        let blockchainInit: Bool?
        let kycPassed: Bool?
        let kycWaiting: Bool?
        let disabledByAdmin: Bool?
        
        enum CodingKeys: String, CodingKey {
            case cardId = "CID"
            case error
            case passed
            case active
            case pinSet = "pin_set"
            case blockchainInit = "blockchain_init"
            case kycPassed = "kyc_passed"
            case kycWaiting = "kyc_waiting"
            case disabledByAdmin = "disabled_by_admin"
        }
    }
}

struct AttestationResponse: Codable, ErrorContainer {
    let challenge: Data
    let error: String?
    let errorCode: String?
    let success: Bool
}

struct RegisterWalletResponse: Codable, ErrorContainer {
    let error: String?
    let errorCode: String?
    let success: Bool
}

protocol ErrorContainer {
    var error: String? { get }
}
