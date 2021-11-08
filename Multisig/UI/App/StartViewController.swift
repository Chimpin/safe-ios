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
        if let chain = Chain.getByName(name: "Polygon") {
            let chainName = chain.name!
            let chainId = chain.id!
            chainNameLabel.text = "Name: \(chainName), ChainId: \(chainId)"
        }
        // Do any additional setup after loading the view.
    }
}

