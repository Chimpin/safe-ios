//
//  TransferValueView.swift
//  Multisig
//
//  Created by Moaaz on 6/16/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransferValueView: View {
    let transaction: TransferTransactionViewModel

    private let dimention: CGFloat = 36

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if !transaction.tokenLogoURL.isEmpty {
                TokenImage(imageURL: URL(string: transaction.tokenLogoURL)!).frame(width: dimention, height: dimention)
            } else {
                EtherImage().frame(width: dimention, height: dimention)
            }

            VStack (alignment: .leading) {
                BodyText("\(transaction.amount) \(transaction.tokenSymbol)", textColor: amountColor)
                if dataLength != 0 {
                    FootnoteText("\(dataLength) bytes")
                }
            }.opacity(opactiy)
        }
    }

    var amountColor: Color {
        return transaction.isOutgoing ? .gnoDarkBlue : .gnoHold
    }

    var opactiy: Double {
        [.canceled, .failed].contains(transaction.status) ? 0.5 : 1
    }

    var dataLength: Int {
        return (transaction as? CustomTransactionViewModel)?.dataLength ?? 0
    }
}

struct TransferValueView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = TransferTransactionViewModel()
        transaction.address = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        transaction.confirmationCount = 1
        transaction.threshold = 2
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.amount = "5"
        transaction.tokenSymbol = " ETH"
        transaction.isOutgoing = true
        transaction.status = .success

        return TransferValueView(transaction: transaction)
    }
}