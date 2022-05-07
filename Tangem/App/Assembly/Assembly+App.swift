//
//  Assembly+App.swift
//  Tangem
//
//  Created by Andrew Son on 04/08/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

extension Assembly {
    // MARK: - Onboarding
    func getLaunchOnboardingViewModel() -> OnboardingBaseViewModel {
        let key = "launch_onboarding_screen"
        if let restored: OnboardingBaseViewModel = get(key: key) {
            return restored
        }
        
        let vm = OnboardingBaseViewModel()
        initialize(vm, with: key, isResetable: false)
        
        return vm
    }
    func getLetsStartOnboardingViewModel() -> WelcomeOnboardingViewModel? {
        if let restored: WelcomeOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    func getLetsStartOnboardingViewModel(with callback: @escaping (OnboardingInput) -> Void) -> WelcomeOnboardingViewModel {
        if let restored: WelcomeOnboardingViewModel = get() {
            restored.successCallback = callback
            return restored
        }
        
        let vm = WelcomeOnboardingViewModel(successCallback: callback)
        initialize(vm, isResetable: false)
        vm.cardsRepository = services.cardsRepository
        vm.stepsSetupService = services.onboardingStepsSetupService
        vm.failedCardScanTracker = services.failedCardScanTracker
        vm.backupService = services.backupService
        return vm
    }
    
    func getCardOnboardingViewModel() -> OnboardingBaseViewModel {
        if let restored: OnboardingBaseViewModel = get() {
            return restored
        }
        
        return getLaunchOnboardingViewModel()
    }
    
    
    @discardableResult
    func makeCardOnboardingViewModel(with input: OnboardingInput) -> OnboardingBaseViewModel {
        let vm = OnboardingBaseViewModel(input: input)
        initialize(vm, isResetable: false)
        
        switch input.steps {
        case .singleWallet:
            makeNoteOnboardingViewModel(with: input)
        case .twins:
            makeTwinOnboardingViewModel(with: input)
        case .wallet:
            makeWalletOnboardingViewModel(with: input)
        }
        
        return vm
    }
    
    func getOnboardingViewModel() -> SingleCardOnboardingViewModel {
        if let restored: SingleCardOnboardingViewModel = get() {
            return restored
        }
        
        return makeNoteOnboardingViewModel(with: previewNoteCardOnboardingInput)
    }
    
    @discardableResult
    func makeNoteOnboardingViewModel(with input: OnboardingInput) -> SingleCardOnboardingViewModel {
        let vm = SingleCardOnboardingViewModel(exchangeService: services.exchangeService, input: input)
        initialize(vm, isResetable: false)
        vm.cardsRepository = services.cardsRepository
        vm.stepsSetupService = services.onboardingStepsSetupService
        vm.exchangeService = services.exchangeService
        vm.tokensRepo = services.tokenItemsRepository
        return vm
    }
    
    func getTwinsOnboardingViewModel() -> TwinsOnboardingViewModel {
        if let restored: TwinsOnboardingViewModel = get() {
            return restored
        }
        
        return makeTwinOnboardingViewModel(with: previewTwinOnboardingInput)
    }
    
    @discardableResult
    func makeTwinOnboardingViewModel(with input: OnboardingInput) -> TwinsOnboardingViewModel {
        let vm = TwinsOnboardingViewModel(twinsService: services.twinsWalletCreationService,
                                          exchangeService: services.exchangeService,
                                          input: input)
        initialize(vm, isResetable: false)
        
        return vm
    }
    
    func getWalletOnboardingViewModel() -> WalletOnboardingViewModel {
        if let restored: WalletOnboardingViewModel = get() {
            return restored
        }
        
        return makeWalletOnboardingViewModel(with: previewWalletOnboardingInput)
    }
    
    //temp
    func getTwinOnboardingViewModel() -> TwinsOnboardingViewModel? {
        if let restored: TwinsOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    //temp
    func getWalletOnboardingViewModel() -> WalletOnboardingViewModel? {
        if let restored: WalletOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    @discardableResult
    func makeWalletOnboardingViewModel(with input: OnboardingInput) -> WalletOnboardingViewModel {
        let sdk = services.tangemSdk
        let vm = WalletOnboardingViewModel(input: input,
                                           backupService: services.backupService,
                                           tangemSdk: sdk,
                                           tokensRepo: services.tokenItemsRepository)
        
        initialize(vm, isResetable: false)
        
        return vm
    }
    
    func makeWelcomeStoriesModel() -> StoriesViewModel {
        if let restored: StoriesViewModel = get() {
            return restored
        }
        
        let vm = StoriesViewModel()
        initialize(vm, isResetable: false)
        return vm
    }

    
    //    func makeReadViewModel() -> ReadViewModel {
    //        if let restored: ReadViewModel = get() {
    //            return restored
    //        }
    //
    //        let vm =  ReadViewModel()
    //        initialize(vm, isResetable: false)
    //        vm.failedCardScanTracker = services.failedCardScanTracker
    //        vm.userPrefsService = services.userPrefsService
    //        vm.cardsRepository = services.cardsRepository
    //        return vm
    //    }
    
    // MARK: - Main view model
    func makeMainViewModel() -> MainViewModel {
        if let restored: MainViewModel = get() {
            return restored
        }
        
        let vm =  MainViewModel()
        initialize(vm, isResetable: false)
        vm.cardsRepository = services.cardsRepository
        vm.exchangeService = services.exchangeService
        vm.warningsManager = services.warningsService
        vm.rateAppController = services.rateAppService
        vm.cardOnboardingStepSetupService = services.onboardingStepsSetupService
        
        vm.state = services.cardsRepository.lastScanResult
        
        vm.negativeFeedbackDataCollector = services.negativeFeedbackDataCollector
        vm.failedCardScanTracker = services.failedCardScanTracker
        
        return vm
    }
    
    func makeTokenDetailsViewModel(blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType = .coin) -> TokenDetailsViewModel {
        if let restored: TokenDetailsViewModel = get() {
//            if let cardModel = services.cardsRepository.lastScanResult.cardModel {
//                   restored.card = cardModel
//            }
            return restored
        }
        
        let vm =  TokenDetailsViewModel(blockchainNetwork: blockchainNetwork, amountType: amountType)
        initialize(vm)
        if let cardModel = services.cardsRepository.lastScanResult.cardModel {
            vm.card = cardModel
        }
        vm.exchangeService = services.exchangeService
        return vm
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel {
        let vm = CardViewModel(cardInfo: info)
        vm.featuresService = services.featuresService
        vm.assembly = self
        vm.tangemSdk = services.tangemSdk
        vm.warningsConfigurator = services.warningsService
        vm.warningsAppendor = services.warningsService
        vm.tokenItemsRepository = services.tokenItemsRepository
        vm.coinsService = services.coinsService
        vm.updateState()
        return vm
    }
    
    // MARK: - Details
    
    func makeDetailsViewModel() -> DetailsViewModel {
        
        if let restored: DetailsViewModel = get() {
            if let cardModel = services.cardsRepository.lastScanResult.cardModel {
                restored.cardModel = cardModel
            }
            return restored
        }
        
        let vm =  DetailsViewModel()
        initialize(vm)
        
        if let cardModel = services.cardsRepository.lastScanResult.cardModel {
            vm.cardModel = cardModel
            vm.dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel)
        }
        vm.cardsRepository = services.cardsRepository
        vm.ratesService = services.ratesService
        vm.onboardingStepsSetupService = services.onboardingStepsSetupService
        return vm
    }
    
    func makeSecurityManagementViewModel(with card: CardViewModel) -> SecurityManagementViewModel {
        if let restored: SecurityManagementViewModel = get() {
            return restored
        }
        
        let vm = SecurityManagementViewModel()
        initialize(vm)
        vm.cardViewModel = card
        return vm
    }
    
    func makeCurrencySelectViewModel() -> CurrencySelectViewModel {
        if let restored: CurrencySelectViewModel = get() {
            return restored
        }
        
        let vm =  CurrencySelectViewModel()
        initialize(vm)
        vm.ratesService = services.ratesService
        return vm
    }
    
    func makeTokenListViewModel(mode: TokenListViewModel.Mode) -> TokenListViewModel {
        let restorationKey = "\(TokenListViewModel.self).\(mode.id)"
        if let restored: TokenListViewModel = get(key: restorationKey) {
            return restored
        }
        
        let vm = TokenListViewModel(mode: mode)
        initialize(vm, with: restorationKey, isResetable: true)
        return vm
    }
    
    func makeAddCustomTokenModel() -> AddCustomTokenViewModel {
        if let restored: AddCustomTokenViewModel = get() {
            return restored
        }
        
        let vm = AddCustomTokenViewModel()
        initialize(vm)
        vm.cardModel = services.cardsRepository.lastScanResult.cardModel
        vm.coinsService = services.coinsService
        return vm
    }
    
    func makeSendViewModel(with amount: Amount, blockchainNetwork: BlockchainNetwork, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm: SendViewModel = SendViewModel(amountToSend: amount,
                                              blockchainNetwork: blockchainNetwork,
                                              cardViewModel: card,
                                              warningsManager: services.warningsService)
        
        if services.featuresService.isPayIdEnabled, let payIdService = PayIDService.make(from: blockchainNetwork.blockchain) {
            vm.payIDService = payIdService
        }
        
        prepareSendViewModel(vm)
        return vm
    }
    
    func makeSellCryptoSendViewModel(with amount: Amount, destination: String, blockchainNetwork: BlockchainNetwork, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm = SendViewModel(amountToSend: amount,
                               destination: destination,
                               blockchainNetwork: blockchainNetwork,
                               cardViewModel: card,
                               warningsManager: services.warningsService)
        prepareSendViewModel(vm)
        return vm
    }
    
    func makePushViewModel(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel) -> PushTxViewModel {
        if let restored: PushTxViewModel = get() {
            restored.transaction = tx
            return restored
        }
        
        let vm = PushTxViewModel(transaction: tx, blockchainNetwork: blockchainNetwork, cardViewModel: card, signer: services.signer, ratesService: services.ratesService)
        initialize(vm)
        vm.emailDataCollector = PushScreenDataCollector(pushTxViewModel: vm)
        return vm
    }
    
   
    func makeWalletConnectViewModel(cardModel: CardViewModel) -> WalletConnectViewModel {
        let vm = WalletConnectViewModel(cardModel: cardModel)
        initialize(vm)
        vm.walletConnectController = services.walletConnectService
        return vm
    }
    
    func makeShopViewModel() -> ShopViewModel {
        if let restored: ShopViewModel = get() {
            return restored
        }
        
        let vm = ShopViewModel()
        initialize(vm)
        vm.shopifyService = services.shopifyService
        return vm
    }
    
    func makeAllWalletModels(from cardInfo: CardInfo) -> [WalletModel] {
        let walletManagerFactory = WalletManagerFactory(config: services.keysManager.blockchainConfig)
        let assembly = WalletManagerAssembly(factory: walletManagerFactory,
                                             tokenItemsRepository: services.tokenItemsRepository)
        let walletManagers = assembly.makeAllWalletManagers(for: cardInfo)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard,
                                defaultToken: cardInfo.defaultToken,
                                defaultBlockchain: cardInfo.defaultBlockchain)
    }
    
    func makeWalletModels(from cardInfo: CardInfo, entries: [StorageEntry]) -> [WalletModel] {
        let walletManagerFactory = WalletManagerFactory(config: services.keysManager.blockchainConfig)
        let assembly = WalletManagerAssembly(factory: walletManagerFactory,
                                             tokenItemsRepository: services.tokenItemsRepository)
        let walletManagers = assembly.makeWalletManagers(from: cardInfo, entries: entries)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard,
                                defaultToken: cardInfo.defaultToken,
                                defaultBlockchain: cardInfo.defaultBlockchain)
    }
    
    func makeWalletModels(from cardDto: SavedCard, blockchainNetworks: [BlockchainNetwork]) -> [WalletModel] {
        let walletManagerFactory = WalletManagerFactory(config: services.keysManager.blockchainConfig)
        let assembly = WalletManagerAssembly(factory: walletManagerFactory,
                                             tokenItemsRepository: services.tokenItemsRepository)
        let walletManagers = assembly.makeWalletManagers(from: cardDto, blockchainNetworks: blockchainNetworks)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardDto.derivationStyle,
                                isDemoCard: false)
    }
    
    //Make walletModel from walletManager
    private func makeWalletModels(walletManagers: [WalletManager],
                                  derivationStyle: DerivationStyle,
                                  isDemoCard: Bool,
                                  defaultToken: BlockchainSdk.Token? = nil,
                                  defaultBlockchain: Blockchain? = nil) -> [WalletModel] {
        let items = SupportedTokenItems()
        return walletManagers.map { manager -> WalletModel in
            var demoBalance: Decimal? = nil
            if isDemoCard, let balance = items.predefinedDemoBalances[manager.wallet.blockchain] {
                demoBalance = balance
            }
            
            let model = WalletModel(walletManager: manager,
                                    signer: services.signer,
                                    derivationStyle: derivationStyle,
                                    defaultToken: defaultToken,
                                    defaultBlockchain: defaultBlockchain,
                                    demoBalance: demoBalance)
            model.tokenItemsRepository = services.tokenItemsRepository
            model.ratesService = services.ratesService
            return model
        }
    }
    
    private func initialize<V: ViewModel>(_ vm: V, isResetable: Bool = true) {
        vm.navigation = services.navigationCoordinator
        vm.assembly = self
        store(vm, isResetable: isResetable)
    }
    
    private func initialize<V: ViewModel>(_ vm: V, with key: String, isResetable: Bool) {
        vm.navigation = services.navigationCoordinator
        vm.assembly = self
        store(vm, with: key, isResetable: isResetable)
    }
    
    private func get<T>(key: String) -> T? {
        let val = (modelsStorage[key] ?? persistenceStorage[key]) as? ViewModelNavigatable
        val?.navigation = services.navigationCoordinator
        return val as? T
    }
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return get(key: key)
    }
    
    public func reset() {
        modelsStorage.removeAll()
    }
    
    private func prepareSendViewModel(_ vm: SendViewModel) {
        initialize(vm)
        vm.ratesService = services.ratesService
        vm.featuresService = services.featuresService
        vm.emailDataCollector = SendScreenDataCollector(sendViewModel: vm)
    }
}
