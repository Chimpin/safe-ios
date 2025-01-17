//
//  ActionDetailAddressCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ActionDetailAddressCell: ActionDetailTableViewCell {
    @IBOutlet private weak var addressView: AddressInfoView!
    func setAddress(_ value: Address, label: String?, imageUri: URL?, browseURL: URL?, prefix: String?) {
        addressView.setAddress(value, label: label, imageUri: imageUri, browseURL: browseURL, prefix: prefix)
    }
}
