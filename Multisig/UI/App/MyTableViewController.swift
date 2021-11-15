//
//  MyTableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MyTableViewController: UITableViewController {


    var chains: [SCGModels.Chain] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(MyTableViewCell.self)

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
                    // update chains
                    self.chains = response.results
                    // reload data in tableview
                    self.tableView.reloadData()
                }

            case .failure(let error):
                print("error: \(error)")
            }

        }

    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 3
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chains.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(MyTableViewCell.self)

        let chain = chains[indexPath.row]
        cell.myLabel.text = "Chain #\(chain.chainId): \(chain.chainName)"

        return cell
    }

}
