//
//  OnboardingGenerateKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingGenerateKeyViewController: AddKeyOnboardingViewController {
    private lazy var mnemonic: String = {
        // 16 bit = 12 words
        let seed = Data.randomBytes(length: 16)!
        return BIP39.generateMnemonicsFromEntropy(entropy: seed)!
    }()

    private lazy var privateKey: PrivateKey = {
        try! PrivateKey(mnemonic: mnemonic, pathIndex: 0)
    }()

    convenience init(completion: @escaping () -> Void) {
        self.init(
            cards: [
                .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                      title: "How does it work?",
                      body: "To use this app as an owner in the Gnosis Safe, you can create a key and add it as an owner of your Safe. When you tap Next, the app will create a new private key from a new unique seed phrase."),

                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "The owner key and the seed phrase are stored in the device's secure store - iOS Keychain.",
                      link: .init(title: "How is a private key stored on mobile?", url: URL(string: "https://help.gnosis-safe.io/en/articles/4866738-how-are-private-keys-stored-on-gnosis-safe-mobile")!)),

                .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                      title: "How to export?",
                      body: "To export your owner key or seed phrase, navigate to the key details.")
            ],
            viewTrackingEvent: .generateOwnerOnboarding,
            completion: completion
        )
        navigationItem.title = "Create Owner Key"
    }

    @objc override func didTapNextButton(_ sender: Any) {
        let vc = EnterAddressNameViewController()
        vc.actionTitle = "Save"
        vc.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        vc.screenTitle = "Enter Key Name"
        vc.trackingEvent = .enterKeyName
        vc.placeholder = "Enter name"
        vc.address = privateKey.address
        vc.badgeName = KeyType.deviceGenerated.imageName
        vc.completion = { [unowned self, unowned vc] name in
            guard OwnerKeyController.importKey(privateKey, name: name, isDrivedFromSeedPhrase: true),
                  let keyInfo = try? KeyInfo.keys(addresses: [privateKey.address]).first else {
                return
            }

            let message = "The key successfully created. Add it to a Safe on desktop and then restart the mobile app."

            let passcodeCompletion = { [unowned self, unowned vc] in
                App.shared.snackbar.show(message: message)
                let detailsVC = OwnerKeyDetailsViewController(keyInfo: keyInfo, completion: self.completion)
                vc.show(detailsVC, sender: vc)
            }

            if App.shared.auth.isPasscodeSet {
                passcodeCompletion()
            } else {
                let createPasscodeViewController = CreatePasscodeViewController(passcodeCompletion)
                createPasscodeViewController.navigationItem.hidesBackButton = true
                createPasscodeViewController.hidesHeadline = false
                vc.show(createPasscodeViewController, sender: vc)
            }

            AppSettings.hasShownImportKeyOnboarding = true
        }

        show(vc, sender: self)
    }
}
