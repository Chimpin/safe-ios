//
//  EnterKeyOrSeedPhraseViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterKeyOrSeedPhraseViewController: UIViewController {

    private var completion: () -> Void = { }

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var placeholderLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var scrollView: UIScrollView!

    private var nextButton: UIBarButtonItem!

    private var keyboardBehavior: KeyboardAvoidingBehavior!

    convenience init(completion: @escaping () -> Void) {
        self.init(namedClass: EnterKeyOrSeedPhraseViewController.self)
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Import Owner Key"

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)

        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.rightBarButtonItem = nextButton
        nextButton.isEnabled = false

        descriptionLabel.setStyle(.primary)

        errorLabel.setStyle(.error)
        errorLabel.isHidden = true

        textView.delegate = self
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.gray4.cgColor
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.setStyle(.primary)
        
        textView.becomeFirstResponder()

        placeholderLabel.setStyle(.tertiary)
        placeholderLabel.text = "Enter private key or seed phrase"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ownerEnterSeed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @objc private func didTapNextButton(_ sender: Any) {
        let phrase = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isPotentiallyValidSeedPhrase(phrase) {
            nextButton.isEnabled = false
            guard let seedData = BIP39.seedFromMmemonics(phrase),
                let rootNode = HDNode(seed: seedData)?.derive(path: HDNode.defaultPathMetamaskPrefix,
                                                              derivePrivateKey: true) else {
                nextButton.isEnabled = true
                setError(GSError.WrongSeedPhrase())
                return
            }
            let vc = KeyPickerController(node: rootNode, completion: completion)
            show(vc, sender: self)
            nextButton.isEnabled = true
        } else if isValidPK(phrase),
                  // we need to use Data(ethHex:) here in case if some software
                  // exported private key without a leading 0
                  let privateKey = try? PrivateKey(data: Data(ethHex: phrase)) {

            if OwnerKeyController.exists(privateKey) {
                setError(GSError.KeyAlreadyImported())
                return
            }

            let vc = EnterAddressNameViewController()
            vc.actionTitle = "Import"
            vc.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
            vc.screenTitle = "Enter Key Name"
            vc.trackingEvent = .enterKeyName
            vc.placeholder = "Enter name"
            vc.address = privateKey.address
            vc.badgeName = KeyType.deviceImported.imageName
            vc.completion = { [unowned vc, unowned self] name in
                let success = OwnerKeyController.importKey(
                    privateKey,
                    name: name,
                    isDrivedFromSeedPhrase: false)
                guard success else { return }
                if App.shared.auth.isPasscodeSet {
                    App.shared.snackbar.show(message: "Owner key successfully imported")
                    self.completion()
                } else {
                    let createPasscodeViewController = CreatePasscodeViewController.init { [unowned self] in
                        self.completion()
                    }
                    createPasscodeViewController.navigationItem.hidesBackButton = true
                    createPasscodeViewController.hidesHeadline = false
                    vc.show(createPasscodeViewController, sender: vc)
                }
                
                AppSettings.hasShownImportKeyOnboarding = true
            }

            show(vc, sender: self)
        }
    }

    private func updateTextDependentViews(with text: String) {
        placeholderLabel.isHidden = !text.isEmpty
        setError(nil)

        let phrase = text.trimmingCharacters(in: .whitespacesAndNewlines)
        nextButton.isEnabled = isPotentiallyValidSeedPhrase(phrase) || isValidPK(phrase)
    }

    private func isPotentiallyValidSeedPhrase(_ phrase: String) -> Bool {
        [12, 15, 18, 21, 24].contains(phrase.split(separator: " ").count)
    }

    private func isValidPK(_ pk: String) -> Bool {
        if let data = Data(exactlyHex: pk),
           data.count == 32,
           data != Data(hex: "0x0000000000000000000000000000000000000000000000000000000000000000") {
            return true
        }
        return false
    }

    private func setError(_ error: Error?) {
        errorLabel.text = error?.localizedDescription
        errorLabel.isHidden = error == nil
        textView.layer.borderColor = error == nil ? UIColor.gray4.cgColor : UIColor.error.cgColor
    }
}

extension EnterKeyOrSeedPhraseViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        keyboardBehavior.activeTextView = textView
    }

    func textViewDidChange(_ textView: UITextView) {
        updateTextDependentViews(with: textView.text)
    }
}
