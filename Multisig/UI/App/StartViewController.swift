//
//  StartViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 02.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

    @IBOutlet var chainNameLabel: UILabel!

    @IBAction func buttonPressed() {
        print("buttonPressed() | called")
        let alert = UIAlertController(
                title: "Hello, world",
                message: "Slider",
                preferredStyle: .alert
        )

        let action = UIAlertAction(
                title: "Awesome!",
                style: .default,
                handler: nil
        )

        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let chainName = "Rinkeby"
        if let chain = Chain.getByName(name: chainName) {
            let chainName = chain.name! // shadowing ok?
            let chainId = chain.id!
            let rpcUrl = chain.rpcUrl!
            chainNameLabel.text = "Name: \(chainName), ChainId: \(chainId),\nrpcUrl: \(rpcUrl)" // Why is setting lines not enough to make UILabel multiline?
        } else {
            chainNameLabel.text = "Chain [\(chainName)] not found!"
        }
        // Do any additional setup after loading the view.
    }
}

