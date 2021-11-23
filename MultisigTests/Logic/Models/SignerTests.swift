//
//  SignerTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import Web3

class SignerTests: XCTestCase {
    func testSigner() throws {
        let key = try PrivateKey(data:  Data(hex: "0xe7979e5f2ceb1d4ef76019d1fdba88b50ceefe0575bbfdf94969837c50a5d895"))
        let expectedSignature = "0x99a7a03e9597e85a0cc4188d270b72b1df2de943de804f144976f4c1e23116ff274d2dec4ee7201b88bdadf08259a5dc8e7e2bbf372347de3470beeab904e5d01b"
        let expectedSigner = "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0"
        let preimage = "gnosis-safe"
        let message = preimage.data(using: .utf8)!

        let hash = EthHasher.hash(message)
        let signature = try key.sign(hash: hash)

        XCTAssertEqual(signature.hexadecimal, expectedSignature)
        XCTAssertEqual(signature.signer, Address(exactly: expectedSigner))

        do {
            let pubKey = try EthereumPublicKey(message: message.makeBytes(),
                                               v: EthereumQuantity(quantity: BigUInt(signature.v - 27)),
                                               r: EthereumQuantity(signature.r.makeBytes()),
                                               s: EthereumQuantity(signature.s.makeBytes()))
            XCTAssertEqual(pubKey.address.hex(eip55: true), expectedSigner)
        } catch {
            XCTFail()
            print("error: \(error)")
        }
    }

    func testSignRecover() throws {
        let pk = try PrivateKey(mnemonic: "talent amateur nation duty virtual vanish broken piano ignore clock dash merit", pathIndex: 0)
        // sign something
        let address = pk.address
        print(address.hexadecimal)

        // recover it
        let preimage = "gnosis-safe"
        let message = preimage.data(using: .utf8)!
        let sig = try pk.sign(hash: EthHasher.hash(message))

        let pubKey = try EthereumPublicKey(message: message.makeBytes(),
                                           v: EthereumQuantity(quantity: BigUInt(sig.v - 27)),
                                           r: EthereumQuantity(sig.r),
                                           s: EthereumQuantity(sig.s))

        XCTAssertEqual(pubKey.address.hex(eip55: false), address.hexadecimal)
    }

    func testRecoverLedgerSignature() throws {
        let address = Address(exactly: "0xe44F9E113Fbd671Bf697d5a1cf1716E1a8c3F35b")
        let messageHash = Data(hex: "0xcf52e1c42dc9860829c6aeddf4e0ed3f92101e78bed888d62afa4f0ffb410bd6")
        let v = BigUInt("1c", radix: 16)! - 27
        let r = Data(hex: "0x63f95ce578ed280ffe4e95cdd40924bb8bfbc1d16f15602a199333c27365f62b")
        let s = Data(hex: "0x7eca738aef5a19fdc33da5d6bd267cf28034317ea54262067f55867450c7a533")

        // eth_sign(keccak256("\x19Ethereum Signed Message:\n" + len(message) + message)))
        let prefixedMessageHash = "\u{19}Ethereum Signed Message:\n32cf52e1c42dc9860829c6aeddf4e0ed3f92101e78bed888d62afa4f0ffb410bd6"
        let ethSignHash = EthHasher.hash(messageHash)

        let pubKey = try EthereumPublicKey(
            message: ethSignHash.makeBytes(),
            v: EthereumQuantity(quantity: v),
            r: EthereumQuantity(r.makeBytes()),
            s: EthereumQuantity(s.makeBytes()))

        XCTAssertEqual(address.hexadecimal, pubKey.address.hex(eip55: false))
    }
}


