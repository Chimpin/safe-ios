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
        let cgw = App.shared.clientGatewayService

        cgw.asyncChains { [weak self] result in
            guard let self = self else { return }

            // result is an enum with 2 generic parameters: Success and Failure

            switch result {
            case .success(let response):

                if let chain: SCGModels.Chain = response.results.first {

                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {

                        assert(Thread.isMainThread, "not on main thread") // will not crash in prod
                        self.chainText.text = "ChainID: \(chain.id)"

                    }
                }

            case .failure(let error):
                print("error: \(error)")
            }

        }
    }

    @IBAction func didTapOpen(_ sender: Any) {

        // the new screen will be a navigation stack
            // the root of stack will be the StartVC
        let rootVC = StartViewController(nibName: nil, bundle: nil)

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
