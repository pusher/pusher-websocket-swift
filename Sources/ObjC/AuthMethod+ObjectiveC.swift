import Foundation

public extension AuthMethod {
    func toObjc() -> OCAuthMethod {
        switch self {
        case let .endpoint(authEndpoint):
            return OCAuthMethod(authEndpoint: authEndpoint)

        case let .authRequestBuilder(authRequestBuilder):
            return OCAuthMethod(authRequestBuilder: authRequestBuilder)

        case let .inline(secret):
            return OCAuthMethod(secret: secret)

        case let .authorizer(authorizer):
            return OCAuthMethod(authorizer: authorizer)

        case .noMethod:
            return OCAuthMethod(type: 4)
        }
    }

    static func fromObjc(source: OCAuthMethod) -> AuthMethod {
        switch source.type {
        case 0: return AuthMethod.endpoint(authEndpoint: source.authEndpoint!)
        case 1: return AuthMethod.authRequestBuilder(authRequestBuilder: source.authRequestBuilder!)
        case 2: return AuthMethod.inline(secret: source.secret!)
        case 3: return AuthMethod.authorizer(authorizer: source.authorizer!)
        case 4: return AuthMethod.noMethod
        default: return AuthMethod.noMethod
        }
    }
}
