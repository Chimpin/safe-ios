//
//  ChainSettingsTableViewController.swift
//  Multisig
//
//  Created by Moaaz on 11/4/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChainSettingsTableViewController: UITableViewController {

    fileprivate struct Section {
        let title: String
        let items: [Row]
    }

    enum Row: Int, CaseIterable {
        case copyAddressWithChainPrefix
        case prependChainPrefixToAddresses
        case copyAddressWithChainPrefixHelp
        case prependChainPrefixToAddressesHelp
    }

    private var sections: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Chain Prefix"

        tableView.registerCell(SwitchTableViewCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HelpCell")

        tableView.backgroundColor = .secondaryBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        sections.append(Section(title: "Address prefix", items: [.copyAddressWithChainPrefix,
                                                             .copyAddressWithChainPrefixHelp,
                                                             .prependChainPrefixToAddresses,
                                                             .prependChainPrefixToAddressesHelp]))
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section].items[indexPath.row] {
        case .copyAddressWithChainPrefix:
            return tableView.switchCell(for: indexPath,
                                        with: "Copy addresses with chain prefix",
                                        isOn: AppSettings.copyAddressWithChainPrefix)
        case .copyAddressWithChainPrefixHelp:
            return tableView.helpCell(for: indexPath, with: "When enabled, all chain-specific addresses will have the chain prefix displayed before them")

        case .prependChainPrefixToAddresses:
            return tableView.switchCell(for: indexPath,
                                        with: "Prepend chain prefix to addresses",
                                        isOn: AppSettings.prependingChainPrefixToAddresses)

        case .prependChainPrefixToAddressesHelp:
            return tableView.helpCell(for: indexPath, with: "When you copy any address, the app will prepend the chain accodring to standard EIP-3770")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case .copyAddressWithChainPrefix:
            AppSettings.copyAddressWithChainPrefix.toggle()
            tableView.reloadData()
        case .prependChainPrefixToAddresses:
            AppSettings.prependingChainPrefixToAddresses.toggle()
            tableView.reloadData()
        default:
            break
        }

        NotificationCenter.default.post(name: .chainSettingsChanged, object: self)
    }
}
