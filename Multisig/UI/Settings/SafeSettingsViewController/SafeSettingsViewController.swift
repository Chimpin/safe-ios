//
//  SafeSettingsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

fileprivate protocol SectionItem {}

class SafeSettingsViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var clientGatewayService = App.shared.clientGatewayService
    let tableBackgroundColor: UIColor = .primaryBackground
    let advancedSectionHeaderHeight: CGFloat = 28

    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var currentDataTask: URLSessionTask?
    private var sections = [SectionItems]()
    private var safe: Safe!
    private var ensLoader: ENSNameLoader!

    enum Section {
        case name(String)
        case requiredConfirmations(String)
        case ownerAddresses(String)
        case safeVersion(String)
        case ensName(String)
        case advanced

        enum Name: SectionItem {
            case name(String)
        }

        enum RequiredConfirmations: SectionItem {
            case confirmations(String)
        }

        enum OwnerAddresses: SectionItem {
            case ownerInfo(AddressInfo)
        }

        enum ContractVersion: SectionItem {
            case versionInfo(AddressInfo, SCGModels.ImplementationVersionState, String)
        }

        enum EnsName: SectionItem {
            case ensName
        }

        enum Advanced: SectionItem {
            case advanced(String)
            case removeSafe
        }
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = tableBackgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68

        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(ContractVersionStatusCell.self)
        tableView.registerCell(LoadingValueCell.self)
        tableView.registerCell(RemoveCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        for notification in [Notification.Name.ownerKeyImported,
                                .ownerKeyRemoved,
                                .ownerKeyUpdated,
                                .selectedSafeUpdated,
                                .addressbookChanged] {
            notificationCenter.addObserver(
                self,
                selector: #selector(lazyReloadData),
                name: notification,
                object: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.settingsSafe)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            safe = try Safe.getSelected()!
            currentDataTask = clientGatewayService.asyncSafeInfo(safeAddress: safe.addressValue,
                                                                 chainId: safe.chain!.id!) { [weak self] result in
                guard let `self` = self else { return }
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
                        self.onError(GSError.error(description: "Failed to load safe settings", error: error))
                    }
                case .success(let safeInfo):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.safe.update(from: safeInfo)
                        self.updateSections(with: safeInfo)
                        self.ensLoader = ENSNameLoader(safe: self.safe, delegate: self)
                        self.onSuccess()
                    }
                }
            }
        } catch {
            onError(GSError.error(description: "Failed to load safe settings", error: error))
        }
    }

    private func updateSections(with info: SafeInfoRequest.ResponseType) {
        sections = [
            (section: .name("Safe Name"), items: [Section.Name.name(safe.name ?? "Safe \(safe.addressValue.ellipsized())")]),

            (section: .requiredConfirmations("Required confirmations"),
             items: [Section.RequiredConfirmations.confirmations("\(info.threshold) out of \(info.owners.count)")]),

            (section: .ownerAddresses("Owner addresses"),
             items: info.owners.map { Section.OwnerAddresses.ownerInfo($0.addressInfo) }),

            (section: .safeVersion("Safe version"),
             items: [Section.ContractVersion.versionInfo(info.implementation.addressInfo, info.implementationVersionState, info.version)]),

            (section: .ensName("ENS name"), items: [Section.EnsName.ensName]),

            (section: .advanced, items: [
                Section.Advanced.advanced("Advanced"),
                Section.Advanced.removeSafe])
        ]
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.RequiredConfirmations.confirmations(let name):
            return tableView.basicCell(name: name, indexPath: indexPath, withDisclosure: false, canSelect: false)

        case Section.OwnerAddresses.ownerInfo(let info):
            let keyInfo = try? KeyInfo.keys(addresses: [info.address]).first
            let (name, _) = NamingPolicy.name(for: info.address,
                                                        info: info,
                                                        chainId: safe.chain!.id!)

            return addressDetailsCell(address: info.address,
                                      name: name,
                                      indexPath: indexPath,
                                      badgeName: keyInfo?.keyType.imageName)

        case Section.ContractVersion.versionInfo(let info, let status, let version):
            return safeVersionCell(info: info, status: status, version: version, indexPath: indexPath)

        case Section.EnsName.ensName:
            if ensLoader.isLoading {
                return loadingCell(name: nil, indexPath: indexPath)
            } else {
                return loadingCell(name: safe.ensName ?? "Reverse record not set", indexPath: indexPath)
            }

        case Section.Advanced.advanced(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)

        case Section.Advanced.removeSafe:
            return removeSafeCell(indexPath: indexPath)

        default:
            return UITableViewCell()
        }
    }

    private func addressDetailsCell(address: Address, name: String?, indexPath: IndexPath, badgeName: String? = nil) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(address: address, label: name, badgeName: badgeName)
        return cell
    }

    private func safeVersionCell(info: AddressInfo, status: SCGModels.ImplementationVersionState, version: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ContractVersionStatusCell.self, for: indexPath)
        cell.setAddress(info, status: status, version: version)
        cell.selectionStyle = .none
        cell.onViewDetails = { [weak self] in
            guard let `self` = self else { return }
            self.openInSafari(self.safe.chain!.browserURL(address: info.address.checksummed))
        }
        return cell
    }

    private func loadingCell(name: String?, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(LoadingValueCell.self, for: indexPath)
        if let name = name {
            cell.setTitle(name)
        } else {
            cell.displayLoading()
        }
        cell.selectionStyle = .none
        return cell
    }

    private func removeSafeCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(RemoveCell.self, for: indexPath)
        cell.set(title: "Remove Safe")
        cell.onRemove = { [weak self] in
            guard let `self` = self else { return }
            let alertController = UIAlertController(
                title: nil,
                message: "Removing a Safe only removes it from this app. It does not delete the Safe from the blockchain. Funds will not get lost.",
                preferredStyle: .actionSheet)
            let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
                Safe.remove(safe: self.safe)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(remove)
            alertController.addAction(cancel)
            self.present(alertController, animated: true)
        }
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Name.name(_):
            let editSafeNameViewController = EditSafeNameViewController()
            editSafeNameViewController.safe = safe
            editSafeNameViewController.completion = {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.navigationController?.popViewController(animated: true)
                }
            }
            show(editSafeNameViewController, sender: self)
        case Section.Advanced.advanced(_):
            let advancedSafeSettingsViewController = AdvancedSafeSettingsViewController()
            let ribbon = RibbonViewController(rootViewController: advancedSafeSettingsViewController)
            show(ribbon, sender: self)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.OwnerAddresses.ownerInfo:
            return UITableView.automaticDimension

        case Section.ContractVersion.versionInfo:
            return UITableView.automaticDimension

        case Section.EnsName.ensName:
            return LoadingValueCell.rowHeight

        case Section.Advanced.removeSafe:
            return RemoveCell.rowHeight

        default:
            return BasicCell.rowHeight
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.name(let name):
            view.setName(name)

        case Section.requiredConfirmations(let name):
            view.setName(name)

        case Section.ownerAddresses(let name):
            view.setName(name)

        case Section.safeVersion(let name):
            view.setName(name)

        case Section.ensName(let name):
            view.setName(name)

        case Section.advanced:
            break
        }

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section].section
        if case Section.advanced = section {
            return advancedSectionHeaderHeight
        }
        return BasicHeaderView.headerHeight
    }
}

extension SafeSettingsViewController: ENSNameLoaderDelegate {
    func ensNameLoaderDidLoadName(_ loader: ENSNameLoader) {
        tableView.reloadData()
    }
}
