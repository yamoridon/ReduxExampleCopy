//
//  KeychainStore.swift
//  ReduxExampleCopy
//
//  Created by Kazuki Ohara on 2019/02/26.
//  Copyright © 2019 Kazuki Ohara. All rights reserved.
//

import Foundation
import KeychainAccess

public protocol KeychainStorable {
    func save(key: String, value: String)
    func load(key: String) -> String?
    func delete(key: String)
}

public struct KeychainStore: KeychainStorable {
    private let keychian: Keychain

    public init(_ keychainServiceName: String) {
        self.keychian = Keychain(service: keychainServiceName)
    }

    public func save(key: String, value: String) {
        keychian[key] = value
    }

    public func load(key: String) -> String? {
        return keychian[key]
    }

    public func delete(key: String) {
        keychian[key] = nil
    }

}
