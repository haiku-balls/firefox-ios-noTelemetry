// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingCardProtocol {
    var cardType: IntroViewModel.InformationCards { get set }
    var infoModel: OnboardingModelProtocol { get }
    var shouldShowDescriptionBold: Bool { get }

    func sendCardViewTelemetry()
    func sendTelemetryButton(isPrimaryAction: Bool)
}

struct OnboardingCardViewModel: OnboardingCardProtocol {
    func sendCardViewTelemetry() {
        
    }
    
    func sendTelemetryButton(isPrimaryAction: Bool) {
        
    }
    
    var cardType: IntroViewModel.InformationCards
    var infoModel: OnboardingModelProtocol
    var shouldShowDescriptionBold: Bool

    init(cardType: IntroViewModel.InformationCards,
         infoModel: OnboardingModelProtocol,
         isFeatureEnabled: Bool) {
        self.cardType = cardType
        self.infoModel = infoModel
        self.shouldShowDescriptionBold = cardType == .welcome && !isFeatureEnabled
    }

}
