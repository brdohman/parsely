---
name: keychain
description: "Secure storage patterns using Keychain Services for macOS apps. Covers storing credentials, API tokens, and sensitive data. Use when implementing Keychain access, credential storage, or secure data management."
---

# Keychain Skill

## Overview

Secure storage patterns using Keychain for macOS apps.

## Keychain Helper

```swift
import Security
import Foundation

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
    case encodingError
}

actor KeychainHelper {
    static let shared = KeychainHelper()

    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.app") {
        self.service = service
    }

    // MARK: - Save

    func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func save(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        try save(data, forKey: key)
    }

    // MARK: - Read

    func read(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.itemNotFound
        }

        return data
    }

    func readString(forKey key: String) throws -> String {
        let data = try read(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.encodingError
        }
        return string
    }

    // MARK: - Delete

    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
```

## Usage Examples

```swift
// Save API token
try await KeychainHelper.shared.save(token, forKey: "api_token")

// Read API token
let token = try await KeychainHelper.shared.readString(forKey: "api_token")

// Delete on logout
try await KeychainHelper.shared.delete(forKey: "api_token")
```

## Codable Support

```swift
extension KeychainHelper {
    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        try save(data, forKey: key)
    }

    func read<T: Decodable>(forKey key: String) throws -> T {
        let data = try read(forKey: key)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Usage
struct Credentials: Codable {
    let username: String
    let token: String
}

try await KeychainHelper.shared.save(credentials, forKey: "credentials")
let creds: Credentials = try await KeychainHelper.shared.read(forKey: "credentials")
```

## Common Keys

```swift
enum KeychainKey {
    static let apiToken = "api_token"
    static let refreshToken = "refresh_token"
    static let userCredentials = "user_credentials"
}
```

## Do NOT Store in Keychain

- Large data (use encrypted files)
- Non-sensitive data (use UserDefaults)
- Temporary data (use memory)

## Do NOT Use for Secrets

- UserDefaults (not encrypted)
- Plist files (not encrypted)
- Hardcoded values (visible in binary)
