//
//  UITableViewCell+Extension.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UITableView {
    func basicCell(name: String,
                   detail: String? = nil,
                   indexPath: IndexPath,
                   withDisclosure: Bool = true,
                   disclosureImage: UIImage? = nil,
                   canSelect: Bool = true) -> UITableViewCell {
        let cell = dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        cell.setDetail(detail)
        if !withDisclosure {
            cell.setDisclosureImage(disclosureImage)
        }
        if !canSelect {
            cell.selectionStyle = .none
        }
        return cell
    }

    func detailedCell(imageUrl: URL?,
                      header: String?,
                      description: String?,
                      indexPath: IndexPath,
                      canSelect: Bool = true,
                      placeholderImage: UIImage? = nil) -> UITableViewCell {
        let cell = dequeueCell(DetailedCell.self, for: indexPath)
        cell.setImage(url: imageUrl, placeholder: placeholderImage)
        cell.setHeader(header)
        cell.setDescription(description)
        if !canSelect {
            cell.selectionStyle = .none
        }

        return cell
    }

    func infoCell(name: String,
                  info: String,
                  indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCell(InfoCell.self, for: indexPath)
        cell.setTitle(name)
        cell.setInfo(info)
        cell.selectionStyle = .none
        return cell
    }

    func switchCell(for indexPath: IndexPath, with text: String, isOn: Bool) -> SwitchTableViewCell {
        let cell = dequeueCell(SwitchTableViewCell.self, for: indexPath)
        cell.setText(text)
        cell.setOn(isOn, animated: false)
        return cell
    }

    func helpCell(for indexPath: IndexPath,
                  with text: String,
                  backgroundColor: UIColor = .primaryBackground,
                  textStyle: GNOTextStyle = .secondary) -> UITableViewCell {
        let cell = dequeueCell(UITableViewCell.self, reuseID: "HelpCell", for: indexPath)
        cell.textLabel?.setStyle(.secondary)
        cell.backgroundColor = backgroundColor
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        
        return cell
    }
}
