//
//  MyTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MyTableViewCell: UITableViewCell {

    @IBOutlet weak var myLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        myLabel.text = nil
    }
    
}
