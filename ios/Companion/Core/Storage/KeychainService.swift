import Foundation
import Security

actor KeychainService {
    private let service = "ai.companion.keychain"

    func store(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.encodeFailed }
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.storeFailed(status) }
    }

    func read(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { throw KeychainError.readFailed(status) }
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8)
        else { throw KeychainError.encodeFailed }
        return value
    }

    func hasKey(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    static func isValidKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("sk-or-") && trimmed.count > 20
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error, CustomStringConvertible {
    case encodeFailed
    case storeFailed(OSStatus)
    case readFailed(OSStatus)
    case invalidKeyFormat

    var description: String {
        switch self {
        case .encodeFailed: return "Could not encode value for keychain storage"
        case .storeFailed(let status): return "Keychain write failed (OSStatus: \(status))"
        case .readFailed(let status): return "Keychain read failed (OSStatus: \(status))"
        case .invalidKeyFormat: return "Key should start with 'sk-or-'"
        }
    }
}

extension KeychainService {
    static let apiKeyAccount = "openrouter_api_key"
}
