//
//  MyTableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MyTableViewController: UITableViewController {

    // 2 sections
    // "Odd Chains"
    //   // chainId % 2 == 1
    // "Even Chains"
        // chainId % 2 == 0

    struct Section {
        var name: String
        var chains: [SCGModels.Chain]
    }

    var sections: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(MyTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        loadChains()
    }

    func loadChains() {
        let cgw = App.shared.clientGatewayService

        cgw.asyncChains { [weak self] result in
            guard let self = self else { return }

            // result is an enum with 2 generic parameters: Success and Failure

            switch result {
            case .success(let response):

                DispatchQueue.main.async {
                    self.reload(chains: response.results)
                }

            case .failure(let error):
                print("error: \(error)")
            }

        }
    }

    func reload(chains: [SCGModels.Chain]) {
        sections = [
            Section(name: "Odd Chains", chains: chains.filter { $0.chainId.value % 2 == 1 }),
            Section(name: "Even Chains", chains: chains.filter { $0.chainId.value % 2 == 0 }),
        ]
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].chains.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(MyTableViewCell.self)

        let chain = sections[indexPath.section].chains[indexPath.row]
        cell.myLabel.text = "Chain #\(chain.chainId): \(chain.chainName)"

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(sections[section].name)
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        BasicHeaderView.headerHeight
    }

}
