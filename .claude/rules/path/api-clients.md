---
paths:
  - "app/**/Networking/**/*.swift"
  - "app/**/Services/*API*.swift"
  - "app/**/Services/*Client*.swift"
---

# API Client Standards (Alamofire)

## Structure

```swift
actor APIClient {
    private let session: Session
    private let decoder: JSONDecoder
    private let baseURL: URL

    init(baseURL: URL, interceptor: RequestInterceptor? = nil) {
        self.baseURL = baseURL
        self.session = Session(interceptor: interceptor)
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        try await session.request(
            baseURL.appendingPathComponent(endpoint.path),
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding
        )
        .validate()
        .serializingDecodable(T.self, decoder: decoder)
        .value
    }
}
```

## Endpoint Pattern

```swift
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
}

enum MyAPIEndpoint: Endpoint {
    case getItems
    case getItem(id: String)
    case createItem(CreateItemRequest)

    var path: String { ... }
    var method: HTTPMethod { ... }
    var parameters: Parameters? { ... }
    var encoding: ParameterEncoding { ... }
}
```

## Error Handling

- Define typed errors (not just throw Error)
- Use Alamofire's `.validate()` for status codes
- Map `AFError` to domain-specific errors
- Log errors (not sensitive data)

```swift
enum APIError: Error {
    case networkError(AFError)
    case serverError(statusCode: Int, message: String?)
    case decodingError(DecodingError)
    case unauthorized
}
```

## Security

- NEVER hardcode API keys
- Store keys in Keychain
- Use RequestInterceptor for auth headers
- Validate all response data

## Required Patterns

- All API clients are `actor` types
- All methods are `async throws`
- Use Codable for request/response types
- Centralize base URL configuration

## Never

- Use URLSession directly (use Alamofire)
- Hardcode API endpoints as strings
- Skip response validation
- Log request/response bodies with sensitive data
