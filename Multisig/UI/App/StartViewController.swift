//
//  StartViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

    @IBOutlet weak var chainText: UILabel!
    @IBOutlet weak var openButton: UIButton!

    var myClosure: () -> Void = {}

    override func viewDidLoad() {
        super.viewDidLoad()

//        myClosure = { [weak self] in
//            guard let self = self else { return }
//            guard let chain: Chain = Chain.by(name: "Rinkeby") else {
//                return
//            }
//            self.chainText.text = "ChainID: \(chain.id ?? "<nil>")"
//        }
//
//        myClosure()

        // fetch chains from the client gateway
    }

    @IBAction func didTapOpen(_ sender: Any) {

        // the new screen will be a navigation stack
            // the root of stack will be the StartVC
//        let rootVC = StartViewController(nibName: nil, bundle: nil)
        let rootVC = MyTableViewController()

        let vc = UINavigationController(rootViewController: rootVC)

        // open new screen modally
        present(vc, animated: true, completion: nil)
    }

    // add new button in the xib
    // connect it to the action in the file
    // inside the action function create new "StartVC" instance and push it in the navigation stack using "show()" method

    @IBAction func didTapPush(_ sender: Any) {
        let startVC = StartViewController(nibName: nil, bundle: nil)
        show(startVC, sender: nil)
    }

}
