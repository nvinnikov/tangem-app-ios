//
//  CardsRepository.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 03.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CardInfo {
    var card: Card
    var verificationState: VerifyCardState?
    var artworkInfo: ArtworkInfo?
	var twinCardInfo: TwinCardInfo?
    
    var isMultiWallet: Bool {
        return true //todo
    }
}

enum ScanResult: Equatable {
    case card(model: CardViewModel)
    case unsupported
	case notScannedYet
    
    var cardModel: CardViewModel? {
        switch self {
        case .card(let model):
            return model
        default:
            return nil
        }
    }
    
    var card: Card? {
        switch self {
        case .card(let model):
            return model.cardInfo.card
        default:
            return nil
        }
    }

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool {
		switch (lhs, rhs) {
		
		case (.card, .card): return true
		case (.unsupported, .unsupported): return true
		case (.notScannedYet, .notScannedYet): return true
		default:
			return false
		}
    }
}

class CardsRepository {
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    
    var cards = [String: ScanResult]()
	var lastScanResult: ScanResult = .notScannedYet
    var onScan: ((CardInfo) -> Void)? = nil
    
	private let twinCardFileDecoder: TwinCardFileDecoder
	
    init(twinCardFileDecoder: TwinCardFileDecoder) {
		self.twinCardFileDecoder = twinCardFileDecoder
	}
    
    func scan(_ completion: @escaping (Result<ScanResult, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        tangemSdk.config = Config()
        tangemSdk.startSession(with: TapScanTask()) {[unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            case .success(let response):
				guard response.card.cardId != nil else {
					completion(.failure(TangemSdkError.unknownError))
					return
				}
				
				Analytics.logScan(card: response.card)
				completion(.success(processScan(response.getCardInfo())))
            }
        }
    }

	private func processScan(_ cardInfo: CardInfo) -> ScanResult {
        onScan?(cardInfo)
        
        let cm = assembly.makeCardModel(from: cardInfo)
        let result: ScanResult = cm == nil ? .unsupported : .card(model: cm!)
        cards[cardInfo.card.cardId!] = result
        lastScanResult = result
        return result
	}
}
