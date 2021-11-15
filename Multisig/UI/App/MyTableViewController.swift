//
//  MyTableViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 15.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MyTableViewController: UITableViewController {
    
    var chains: [SCGModels.Chain] = []
    
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
                    self.chains = response.results
                    self.tableView.reloadData()
                }

            case .failure(let error):
                print("error: \(error) ")
            }
        }

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return chains.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(MyTableViewCell.self)
        let chain = chains[indexPath.row]
        cell.myLabel.text = "Chain #\(chain.chainId): \(chain.chainName)"
        return cell
    }
}
