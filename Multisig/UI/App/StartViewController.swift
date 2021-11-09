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
    
    var myClosure: (String) -> Void = { (name: String) in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let chainName = "Polygon"
        
//        myClosure = { [weak self] (name :String) in
//            guard let self = self else { return }
//            if let chain = Chain.getByName(name: name) {
//                let chainName = chain.name! // shadowing ok?
//                let chainId = chain.id!
//                let rpcUrl = chain.rpcUrl!
//                self.chainNameLabel.text = "Name: \(chainName), ChainId: \(chainId),\nrpcUrl: \(rpcUrl)"
//            } else {
//                self.chainNameLabel.text = "Chain [\(name)] not found!"
//            }
//        }
//
//        myClosure(chainName)
        
        
        // Do any additional setup after loading the view.
    }
}

