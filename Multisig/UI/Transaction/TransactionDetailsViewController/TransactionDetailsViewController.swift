//
//  TransactionDetailsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import WalletConnectSwift

class TransactionDetailsViewController: LoadableViewController, UITableViewDataSource, UITableViewDelegate {
    var clientGatewayService = App.shared.clientGatewayService

    private var cells: [UITableViewCell] = []
    private var tx: SCGModels.TransactionDetails?
    private var reloadDataTask: URLSessionTask?
    private var confirmDataTask: URLSessionTask?
    private var rejectTask: URLSessionTask?
    private var builder: TransactionDetailCellBuilder!
    private var confirmButton: UIButton!
    private var rejectButton: UIButton!
    private var executeButton: UIButton!
    private var actionsContainerView: UIStackView!

    private var pendingExecution = false
    private var safe: Safe!
    private var loadSafeInfoDataTask: URLSessionTask?
    private var ledgerController: LedgerController?

    private enum TransactionSource {
        case id(String)
        case safeTxHash(Data)
        case data(SCGModels.TransactionDetails)
    }

    private var txSource: TransactionSource!

    private var ledgerKeyInfo: KeyInfo?

    convenience init(transactionID: String) {
        self.init(namedClass: Self.superclass())
        txSource = .id(transactionID)
    }

    convenience init(safeTxHash: Data) {
        self.init(namedClass: Self.superclass())
        txSource = .safeTxHash(safeTxHash)
    }

    convenience init(transaction: SCGModels.TransactionDetails) {
        self.init(namedClass: Self.superclass())
        txSource = .data(transaction)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Transaction Details"

        safe = try! Safe.getSelected()!

        builder = TransactionDetailCellBuilder(vc: self, tableView: tableView, chain: safe.chain!)

        updateSafeInfo()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        configureActionButtons()

        for notification in [Notification.Name.ownerKeyImported,
                             .ownerKeyRemoved,
                             .ownerKeyUpdated,
                             .chainInfoChanged,
                             .addressbookChanged,
                             .selectedSafeUpdated,
                             .selectedSafeChanged,
                             .chainInfoChanged] {
            notificationCenter.addObserver(
                self,
                selector: #selector(lazyReloadData),
                name: notification,
                object: nil)
        }
        tableView.backgroundColor = .secondaryBackground
    }

    private func updateSafeInfo() {
        loadSafeInfoDataTask = App.shared.clientGatewayService.asyncSafeInfo(safeAddress: safe.addressValue,
                                                                             chainId: safe.chain!.id!) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let safeInfo):
                    self?.safe.update(from: safeInfo)
                    self?.onSuccess()
                case .failure(_):
                    break
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.transactionsDetails)
    }

    // MARK: - Events

    override func didChangeSelectedSafe() {
        let isVisible = isViewLoaded && view.window != nil
        navigationController?.popViewController(animated: isVisible)
    }

    // MARK: - Buttons

    fileprivate func configureActionButtons() {
        // Actions Container View sticks to the bottom of the screen
        // and is on top of the table view.
        // it is shown only when table view is shown.

        actionsContainerView = UIStackView()
        actionsContainerView.axis = .horizontal
        actionsContainerView.distribution = .fillEqually
        actionsContainerView.alignment = .fill
        actionsContainerView.spacing = 20
        actionsContainerView.translatesAutoresizingMaskIntoConstraints = false

        rejectButton = UIButton(type: .custom)
        rejectButton.setText("Reject", .filledError)
        rejectButton.addTarget(self, action: #selector(didTapReject), for: .touchUpInside)
        actionsContainerView.addArrangedSubview(rejectButton)

        confirmButton = UIButton(type: .custom)
        confirmButton.setText("Confirm", .filled)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        actionsContainerView.addArrangedSubview(confirmButton)

        executeButton = UIButton(type: .custom)
        executeButton.setText("Execute", .filled)
        executeButton.addTarget(self, action: #selector(didTapExecute), for: .touchUpInside)
        actionsContainerView.addArrangedSubview(executeButton)

        view.addSubview(actionsContainerView)
        NSLayoutConstraint.activate([
            actionsContainerView.heightAnchor.constraint(equalToConstant: 56),
            actionsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            actionsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    override func showOnly(view: UIView) {
        super.showOnly(view: view)
        actionsContainerView.isHidden = view !== tableView || !showsActionsViewContrainer
        confirmButton.isHidden = !showsConfirmButton
        rejectButton.isHidden = !showsRejectButton
        executeButton.isHidden = !showsExecuteButton

        confirmButton.isEnabled = enableConfirmButton
        rejectButton.isEnabled = enableRejectionButton
        executeButton.isEnabled = !pendingExecution
    }

    private var showsActionsViewContrainer: Bool  {
        tx?.multisigInfo?.canSign == true && (showsRejectButton || showsConfirmButton || showsExecuteButton)
    }

    private var showsRejectButton: Bool {
        switch self.tx?.txInfo {
        case .rejection(_):
            return false
        default:
            guard let multisigInfo = tx?.multisigInfo,
                  let status = tx?.txStatus
                    else { return false }

            if status == .awaitingExecution && !multisigInfo.isRejected() && !pendingExecution {
                 return true
            } else if status.isAwatingConfiramtions {
                return true
            }

            return false
        }
    }

    private var showsConfirmButton: Bool {
        switch self.tx?.txInfo {
        case .rejection(_):
            if tx!.txStatus.isAwatingConfiramtions,
               let multisigInfo = tx!.multisigInfo,
               multisigInfo.canSign {
                return true
            }
            return false
        default:
            return tx?.txStatus.isAwatingConfiramtions ?? false
        }
    }

    private var showsExecuteButton: Bool {
        guard let nonce = safe.nonce, nonce == tx?.multisigInfo?.nonce.value else {
            return false
        }
        return tx?.needsYourExecution ?? false
    }

    private var enableRejectionButton: Bool {
        if case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigTx)? = tx?.detailedExecutionInfo,
           !multisigTx.isRejected(),
           showsRejectButton {
            return true
        }

        return false
    }

    private var enableConfirmButton: Bool {
        tx?.needsYourConfirmation ?? false
    }

    // MARK: - Signing, Rejection, Execution

    @objc private func didTapConfirm() {
        guard let signers = tx?.multisigInfo?.signerKeys() else {
            assertionFailure()
            return
        }
        let descriptionText = "You are about to confirm this transaction. This happens off-chain. Please select which owner key to use."
        let vc = ChooseOwnerKeyViewController(owners: signers, chainID: safe.chain!.id, descriptionText: descriptionText) {
            [weak self] keyInfo in

            // dismiss presented ChooseOwnerKeyViewController right after receiving the completion
            self?.dismiss(animated: true) {
                guard let keyInfo = keyInfo else { return }
                self?.sign(keyInfo)
            }
        }

        let navigationController = UINavigationController(rootViewController: vc)
        present(navigationController, animated: true)
    }

    @objc private func didTapReject() {
        guard let transaction = tx else { fatalError() }
        let confirmRejectionViewController = RejectionConfirmationViewController(transaction: transaction)
        show(confirmRejectionViewController, sender: self)
    }

    @objc private func didTapExecute() {
        guard let signers = tx?.multisigInfo?.executionKeys() else {
            return
        }

        let descriptionText = "You are about to execute this transaction. Please select which owner key to use."
        let vc = ChooseOwnerKeyViewController(owners: signers,
                                              chainID: safe.chain!.id,
                                              descriptionText: descriptionText) { [unowned self] keyInfo in
            dismiss(animated: true) {
                if let keyInfo = keyInfo {
                    execute(keyInfo)
                }
            }
        }

        let navigationController = UINavigationController(rootViewController: vc)
        present(navigationController, animated: true)
    }

    private func sign(_ keyInfo: KeyInfo) {
        guard let tx = tx,
              var transaction = Transaction(tx: tx),
              let safeAddress = try? Address(from: safe.address!),
              let chainId = safe.chain?.id,
              let safeTxHash = transaction.safeTxHash?.description else {
            preconditionFailure("Unexpected Error")            
        }

        transaction.safe = AddressString(safeAddress)
        transaction.safeVersion = safe.contractVersion
        transaction.chainId = chainId

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                let signature = try SafeTransactionSigner().sign(transaction, keyInfo: keyInfo)
                confirmAndRefresh(safeTxHash: safeTxHash, signature: signature.hexadecimal, keyType: keyInfo.keyType)
            } catch {
                onError(GSError.error(description: "Failed to confirm transaction", error: error))
            }

        case .walletConnect:
            signWithWalletConnect(transaction, keyInfo: keyInfo)

        case .ledgerNanoX:
            let request = SignRequest(title: "Confirm Transaction",
                                      tracking: ["action" : "confirm"],
                                      signer: keyInfo,
                                      hexToSign: safeTxHash)
            let vc = LedgerSignerViewController(request: request)

            present(vc, animated: true, completion: nil)

            vc.completion = { [weak self] signature in
                self?.confirmAndRefresh(safeTxHash: safeTxHash, signature: signature, keyType: .ledgerNanoX)
            }

            vc.onClose = { [weak self] in
                self?.reloadData()
            }
        }
    }

    private func signWithWalletConnect(_ transaction: Transaction, keyInfo: KeyInfo) {
        guard let safeTxHash = transaction.safeTxHash?.description, presentedViewController == nil else { return }

        let pendingConfirmationVC = WCPendingConfirmationViewController()
        pendingConfirmationVC.modalPresentationStyle = .popover
        pendingConfirmationVC.onClose = { [unowned self] in
            reloadData()
        }
        present(pendingConfirmationVC, animated: false)

        WalletConnectClientController.shared.sign(transaction: transaction) {
            [weak self] signatureOrNil in

            DispatchQueue.main.async {
                // dismiss pending confirmation view controller overlay
                pendingConfirmationVC.dismiss(animated: true, completion: nil)
            }

            guard let signature = signatureOrNil else {
                DispatchQueue.main.async {
                    self?.reloadData()
                    App.shared.snackbar.show(error: GSError.CouldNotSignWithWalletConnect())
                }
                return
            }

            DispatchQueue.main.async {
                self?.confirmAndRefresh(safeTxHash: safeTxHash, signature: signature, keyType: keyInfo.keyType)
            }
        }

        WalletConnectClientController.openWalletIfInstalled(keyInfo: keyInfo)
    }

    private func confirmAndRefresh(safeTxHash: String, signature: String, keyType: KeyType) {
        super.reloadData()
        confirmDataTask = App.shared.clientGatewayService.asyncConfirm(safeTxHash: safeTxHash,
                                                                       signature: signature,
                                                                       chainId: safe.chain!.id!) {
            [weak self] result in

            // NOTE: sometimes the data of the transaction list is not
            // updated right away, we'll give a moment for the backend
            // to catch up before finishing with this request.
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                if case Result.success(_) = result {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                        App.shared.snackbar.show(message: "Confirmation successfully submitted")

                        switch keyType {
                        case .deviceGenerated, .deviceImported:
                            Tracker.trackEvent(.transactionDetailsTransactionConfirmed)
                        case .walletConnect:
                            Tracker.trackEvent(.transactionDetailsTxConfirmedWC)
                        case .ledgerNanoX:
                            Tracker.trackEvent(.transactionDetailsTxConfirmedLedgerNanoX)
                        }
                    }
                }

                self?.onLoadingCompleted(result: result)
            }
        }
    }

    private func execute(_ keyInfo: KeyInfo) {
        guard let tx = tx,
              var transaction = Transaction(tx: tx),
              let multisigInfo = tx.multisigInfo,
              keyInfo.keyType == .walletConnect else {
            preconditionFailure("Unexpected Error")
        }

        do {
            let safeAddress = try Address(from: safe.address!)
            transaction.safe = AddressString(safeAddress)
            transaction.chainId = safe.chain!.id
        } catch {
            onError(GSError.error(description: "Failed to execute transaction", error: error))
        }

        guard presentedViewController == nil else { return }

        let pendingConfirmationVC = WCPendingConfirmationViewController(headerText: "Pending Execution")
        pendingConfirmationVC.modalPresentationStyle = .popover
        pendingConfirmationVC.onClose = { [unowned self] in
            self.reloadData()
        }
        present(pendingConfirmationVC, animated: false)

        WalletConnectClientController.shared.execute(
            transaction: transaction,
            confirmations: tx.ecdsaConfirmations,
            confirmationsRequired: multisigInfo.confirmationsRequired,
            rpcURL: safe.chain!.authenticatedRpcUrl,
            onSend: { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        WalletConnectClientController.openWalletIfInstalled(keyInfo: keyInfo)
                    case .failure(let error):
                        pendingConfirmationVC.dismiss(animated: true, completion: nil)
                        self?.reloadData()
                        let localizedError = (error as? DetailedLocalizedError) ?? GSError.error(
                            description: "Failed to send transaction to wallet", error: error)
                        App.shared.snackbar.show(error: localizedError)
                    }
                }
            },
            onResult: { result in
                DispatchQueue.main.async { [weak self] in
                    pendingConfirmationVC.dismiss(animated: true, completion: nil)

                    switch result {
                    case .success():
                        self?.pendingExecution = true
                        self?.reloadData()
                        App.shared.snackbar.show(message: "Transaction submitted. You can check the transaction status in your wallet.")
                        Tracker.trackEvent(.transactionDetailsTxExecutedWC)

                    case .failure(let error):
                        self?.reloadData()
                        let localizedError = (error as? DetailedLocalizedError) ?? GSError.error(
                            description: "Failed to execute transaction", error: error)
                        App.shared.snackbar.show(error: localizedError)
                    }
                }
            })
    }

    // MARK: - Loading Data

    override func reloadData() {
        super.reloadData()
        reloadDataTask?.cancel()

        // delete all app triggers update cycle
        guard safe != nil && safe.chain != nil else { return }

        switch txSource {
        case .id(let txID):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(id: txID, chainId: safe.chain!.id!) {
                [weak self] in
                
                self?.onLoadingCompleted(result: $0)
            }
        case .safeTxHash(let safeTxHash):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(safeTxHash: safeTxHash, chainId: safe.chain!.id!) { [weak self] in
                self?.onLoadingCompleted(result: $0)
            }
        case .data(let tx):
            buildCells(from: tx)
            onSuccess()
        case .none:
            preconditionFailure("Developer error: txSource is required")
        }
    }

    private func onLoadingCompleted(result: Result<SCGModels.TransactionDetails, Error>) {
        switch result {
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                // ignore cancellation error due to cancelling the
                // currently running task. Otherwise user will see
                // meaningless message.
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }
                self.onError(GSError.error(description: "Failed to load transaction details", error: error))
            }
        case .success(let details):
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.buildCells(from: details)
                self.onSuccess()
            }
        }
    }

    func buildCells(from tx: SCGModels.TransactionDetails) {
        self.tx = tx

        // artificial tx status
        if self.tx!.needsYourConfirmation {
            self.tx!.txStatus = .awaitingYourConfirmation
        }

        cells = builder.build(self.tx!)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if let disclosureCell = cell as? DetailDisclosingCell {
            disclosureCell.action()
        }
    }

}

extension SCGModels.TransactionDetails {
    var needsYourConfirmation: Bool {
        if txStatus.isAwatingConfiramtions,
           let multisigInfo = multisigInfo,
           !multisigInfo.signerKeys().isEmpty,
           multisigInfo.needsMoreSignatures {
            return true
        }
        return false
    }

    var needsYourExecution: Bool {
        if txStatus == .awaitingExecution,
           let multisigInfo = multisigInfo,
           ecdsaConfirmations.count >= multisigInfo.confirmationsRequired,
           !multisigInfo.executionKeys().isEmpty {
            return true
        }
        return false
    }

    var ecdsaConfirmations: [SCGModels.Confirmation] {
        guard let multisigInfo = multisigInfo else { return [] }
        return multisigInfo.confirmations.filter {
            $0.signature.data.bytes.last ?? 0 > 26
        }
    }

    var multisigInfo: SCGModels.TransactionDetails.DetailedExecutionInfo.Multisig? {
        if case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigTx)? = detailedExecutionInfo {
            return multisigTx
        }

        return nil
    }
}

extension SCGModels.TransactionDetails.DetailedExecutionInfo.Multisig {
    var needsMoreSignatures: Bool {
        confirmationsRequired > confirmations.count
    }

    func hasRejected(address: AddressString) -> Bool {
        rejectors?.map(\.value).contains(address) ?? false
    }

    func isRejected() -> Bool {
        if let rejectors = rejectors, !rejectors.isEmpty {
            return true
        } else {
            return false
        }
    }

    func signerKeys() -> [KeyInfo] {
        let confirmationAdresses = confirmations.map({ $0.signer.value })

        let remainingSigners = signers.map(\.value).filter({
            !confirmationAdresses.contains($0)
        }).map( { $0.address } )

        return (try? KeyInfo.keys(addresses: remainingSigners)) ?? []
    }

    // In general, a transaction can be executed with any ethereum key.
    // However, we restrict the ability to execute only to owners for additional protection.
    func executionKeys() -> [KeyInfo] {
        let signerAddresses = signers.map(\.value).map( { $0.address } )
        guard !((try? KeyInfo.keys(addresses: signerAddresses)) ?? []).isEmpty else {
            return []
        }

        // but any WalletConnect key can execute a transaction
        let keys = (try? KeyInfo.all()) ?? []
        let selectedSafeChainId = try! Safe.getSelected()!.chain!.id
        return keys.filter { $0.keyType == .walletConnect }
    }

    func rejectorKeys() -> [KeyInfo] {
        let rejectorsAdresses = rejectors?.map(\.value) ?? []
        let remainingSigners = signers.map(\.value).filter({
            !rejectorsAdresses.contains($0)
        }).map( { $0.address } )

        return (try? KeyInfo.keys(addresses: remainingSigners)) ?? []
    }

    var canSign: Bool {
        let signerAddresses = signers.map(\.value).map( { $0.address } )
        let keys = (try? KeyInfo.keys(addresses: signerAddresses)) ?? []
        return !keys.isEmpty
    }
}

extension SCGModels.TxStatus {
    var isAwatingConfiramtions: Bool {
        [.awaitingYourConfirmation, .awaitingConfirmations].contains(self)
    }
}
