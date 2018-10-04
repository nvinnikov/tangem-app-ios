//
//  CardDetailsViewController.swift
//  Tangem
//
//  Created by Gennady Berezovsky on 24.07.18.
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import QRCode

class CardDetailsViewController: UIViewController, TestCardParsingCapable {
    
    @IBOutlet var viewModel: CardDetailsViewModel!
    
    var cardDetails: Card?
    var isBalanceVerified = false
    
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    
    let nfcHelper = NFCHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nfcHelper.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupWithCardDetails()
    }
    
    func setupWithCardDetails() {
        setupUI()
        
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        if cardDetails.isWallet {
            getBalance()
            setupBalanceVerified(false)
        } else {
            viewModel.setWalletInfoLoading(false)
            setupBalanceNoWallet()
        }
    }
    
    func setupUI() {
        guard let cardDetails = cardDetails else {
            assertionFailure()
            return
        }
        
        viewModel.updateBlockchainName(cardDetails.blockchain)
        viewModel.updateWalletAddress(cardDetails.address)
        
        var blockchainName = String()
        if cardDetails.type == .btc {
            blockchainName = "bitcoin:"
        } else {
            blockchainName = "ethereum:"
        }
        
        var qrCodeResult = QRCode(blockchainName + cardDetails.address)
        qrCodeResult?.size = viewModel.qrCodeImageView.frame.size
        viewModel.qrCodeImageView.image = qrCodeResult?.image
        
        viewModel.cardImageView.image = UIImage(named: cardDetails.imageName)
        
        viewModel.balanceVerificationActivityIndicator.stopAnimating()
        
//        self.viewModel.updateNetworkSafetyDescription(self.viewModel.networkSafetyDescriptionLabel.text!)
    }
    
    func verifyBalance() {
        guard let cardDetails = cardDetails, let challenge = cardDetails.challenge, let salt = cardDetails.salt else {
            assertionFailure()
            return
        }
        
        viewModel.balanceVerificationActivityIndicator.startAnimating()
        
        let balanceVerificationOperation = BalanceVerificationOperation(saltHex: salt, challengeHex: challenge, signatureArr: cardDetails.signArr, publicKeyArr: cardDetails.pubArr) { (result) in
            self.viewModel.balanceVerificationActivityIndicator.stopAnimating()
            self.setupBalanceVerified(result)
        }
        
        operationQueue.addOperation(balanceVerificationOperation)
    }
    
    func setupBalanceVerified(_ verified: Bool) {
        isBalanceVerified = verified
        
        viewModel.qrCodeContainerView.isHidden = false
        viewModel.walletAddressLabel.isHidden = false
        
        viewModel.updateWalletBalanceVerification(verified)
        viewModel.loadButton.isEnabled = verified
        viewModel.extractButton.isEnabled = verified
        viewModel.buttonsAvailabilityView.isHidden = verified
        let verificationIconName = verified ? "icon-verified" : "icon-unverified"
        viewModel.balanceVefificationIconImageView.image = UIImage(named: verificationIconName)
        
        viewModel.exploreButton.isEnabled = true
        viewModel.copyButton.isEnabled = true
    }
    
    func setupBalanceNoWallet() {
        isBalanceVerified = false
        
        viewModel.updateWalletBalance("--")
        
        viewModel.updateWalletBalanceNoWallet()
        viewModel.loadButton.isEnabled = false
        viewModel.extractButton.isEnabled = false
        viewModel.buttonsAvailabilityView.isHidden = false
        
        viewModel.balanceVefificationIconImageView.isHidden = true
        
        viewModel.qrCodeContainerView.isHidden = true
        viewModel.walletAddressLabel.isHidden = true
    }
    
    func getBalance() {

        let onResult = { (result: Result<Card>) in
            self.viewModel.setWalletInfoLoading(false)
            
            switch result {
            case .success(let card):
                self.cardDetails = card
                self.viewModel.updateWalletBalance(card.walletValue + " " + card.walletUnits)
                
                self.verifyBalance()
            case .failure:
                self.viewModel.updateWalletBalance("--")
                
                let validationAlert = UIAlertController(title: "Error", message: "Cannot obtain full wallet data", preferredStyle: .alert)
                validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(validationAlert, animated: true, completion: nil)
                self.setupBalanceVerified(false)
            }
        }
        
        guard let card = self.cardDetails else {
            return
        }
        
        var operation: Operation
        
        switch card.type {
        case .btc:
            operation = BTCCardBalanceOperation(card: card, completion: onResult)
        case .eth:
            operation = ETHCardBalanceOperation(card: card, completion: onResult)
        default:
            operation = TokenCardBalanceOperation(card: card, completion: onResult)
        }
        
        operationQueue.addOperation(operation)
    }
    
    // MARK: Actions
    
    @IBAction func exploreButtonPressed(_ sender: Any) {
        if let link = cardDetails?.link, let url = URL(string: link) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    var dispatchWorkItem: DispatchWorkItem?
    
    @IBAction func copyButtonPressed(_ sender: Any) {
        UIPasteboard.general.string = cardDetails?.address
        
        dispatchWorkItem?.cancel()
        
        updateCopyButtonTitleForState(copied: true)
        dispatchWorkItem = DispatchWorkItem(block: {
            self.updateCopyButtonTitleForState(copied: false)
        })
        
        guard let dispatchWorkItem = dispatchWorkItem else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: dispatchWorkItem)
    }
    
    func updateCopyButtonTitleForState(copied: Bool) {
        let title = copied ? "Copied!" : "Copy"
        let color = copied ? UIColor.tgm_green() : UIColor.black
        
        UIView.transition(with: viewModel.copyButton, duration: 0.1, options: .transitionCrossDissolve, animations: {
            self.viewModel.copyButton.setTitle(title.uppercased(), for: .normal)
            self.viewModel.copyButton.setTitleColor(color, for: .normal)
        }, completion: nil)
    }
    
    @IBAction func loadButtonPressed(_ sender: Any) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "LoadViewController") as? LoadViewController else {
            return
        }
        
        viewController.cardDetails = cardDetails
        viewController.delegate = self
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 247)
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func extractButtonPressed(_ sender: Any) {

        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ExtractViewController") else {
            return
        }
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 247)
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)

    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        self.showSimulationSheet()
        #else
        self.nfcHelper.restartSession()
        #endif
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        guard let cardDetails = cardDetails, let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CardMoreViewController") as? CardMoreViewController else {
            return
        }
        
        var cardChallenge: String? = nil
        if let challenge = cardDetails.challenge, let saltValue = cardDetails.salt {
            let cardChallenge1 = String(challenge.prefix(3))
            let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
            let cardChallenge3 = String(saltValue.prefix(3))
            let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
            cardChallenge = [cardChallenge1, cardChallenge2, cardChallenge3, cardChallenge4].joined(separator: " ")
        }
        
        let strings = ["Issuer: \(cardDetails.issuer)",
            "Manufacturer: \(cardDetails.issuer)",
            "API node: \(cardDetails.node)",
            "Challenge: \(cardChallenge ?? "N\\A")",
            "Signature: \(isBalanceVerified ? "passed" : "not passed")",
            "Authenticity: attested",
            "Firmware: \(cardDetails.firmware)",
            "Registration date: \(cardDetails.manufactureDateTime)",
            "Serial: \(cardDetails.cardID)",
            "Remaining signatures: \(cardDetails.remainingSignatures)"]
        viewController.contentText = strings.joined(separator: "\n")
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: min(478, self.view.frame.height - 200))
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
    func launchParsingOperationWith(payload: Data) {
        operationQueue.cancelAllOperations()
        viewModel.setWalletInfoLoading(true)
        
        let operation = CardParsingOperation(payload: payload) { (result) in
            switch result {
            case .success(let card):
                self.cardDetails = card
                self.setupWithCardDetails()
            case .locked:
                self.handleCardParserLockedCard()
            case .tlvError:
                self.handleCardParserWrongTLV()
            }
        }
        operationQueue.addOperation(operation)
    }
    
}

extension CardDetailsViewController: NFCHelperDelegate {
    
    func nfcHelper(_ helper: NFCHelper, didInvalidateWith error: Error) {
        print("\(error.localizedDescription)")
    }
    
    func nfcHelper(_ helper: NFCHelper, didDetectCardWith payload: Data) {
        launchParsingOperationWith(payload: payload)
    }
    
}

extension CardDetailsViewController {
    
    func handleCardParserWrongTLV() {
        let validationAlert = UIAlertController(title: "Error", message: "Failed to parse data received from the banknote", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleCardParserLockedCard() {
        print("Card is locked, two first bytes are equal 0x6A86")
        let validationAlert = UIAlertController(title: "Info", message: "This app can’t read protected Tangem banknotes", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }

}

extension CardDetailsViewController: LoadViewControllerDelegate {
    
    func loadViewControllerDidCallShowQRCode(_ controller: LoadViewController) {
        self.dismiss(animated: true) {
            guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "QRCodeViewController") as? QRCodeViewController else {
                return
            }
            
            viewController.cardDetails = self.cardDetails
            
            let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
            self.customPresentationController = presentationController
            viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 441)
            viewController.transitioningDelegate = presentationController
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
}
