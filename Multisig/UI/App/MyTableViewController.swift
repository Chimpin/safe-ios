//
//  MyTableViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 15.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MyTableViewController: UITableViewController {

    var evenChains: [SCGModels.Chain] = []
    var oddChains: [SCGModels.Chain] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(MyTableViewCell.self)
        loadData()
    }

    func loadData() {
        let cgw = App.shared.clientGatewayService

        cgw.asyncChains { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let response):

                DispatchQueue.main.async {
                    self.evenChains = []
                    self.oddChains = []
                    response.results.forEach {
                        if $0.chainId.value % 2 == 0 {
                            self.evenChains.append($0)
                        } else {
                            self.oddChains.append($0)
                        }
                    }
                    self.tableView.reloadData()
                }

            case .failure(let error):
                print("error: \(error) ")
            }
        }

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return evenChains.count
        }
        return oddChains.count

    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableHeaderView = TableHeaderView()
        if (section == 0) {
            tableHeaderView.set("Even Chains")
        } else {
            tableHeaderView.set("Odd Chains")
        }
        return tableHeaderView

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(MyTableViewCell.self)
        if indexPath.section == 0 {
            let chain = evenChains[indexPath.row]
            cell.myLabel.text = "Chain #\(chain.chainId): \(chain.chainName)"
        } else {
            let chain = oddChains[indexPath.row]
            cell.myLabel.text = "Chain #\(chain.chainId): \(chain.chainName)"
        }

        return cell
    }
}
