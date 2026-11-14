//
//  KeychainHelper.swift
//  HobbyPlanet
//
//  大模型 API Key 不能明文放在 UserDefaults 里（后者是一个可直接读取的 plist）。
//  这里用系统钥匙串保存，按 service + account 定位一条通用密码。
//

import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.hobbyplanet.llm"

    @discardableResult
    static func save(_ value: String, account: String = "api-key") -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // 先删后写，避免 duplicate item 错误
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func read(account: String = "api-key") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(account: String = "api-key") -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
