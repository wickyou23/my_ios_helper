//
//  Secrets+Ext.swift
//  OWPrototype
//
//  Created by Thang Phung on 20/06/2022.
//  Copyright © 2022 Origin Wireless. All rights reserved.
//

import Foundation

extension Secrets {
    static func decode(_ encoded: [UInt8], cipher: [UInt8]) -> String {
        String(decoding: encoded.enumerated().map { (offset, element) in
            element ^ cipher[offset % cipher.count]
        }, as: UTF8.self)
    }
}
