//
//  StartViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 02.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

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

        // Do any additional setup after loading the view.
    }
}

