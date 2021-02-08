import Foundation

public enum AuthMethod {
    case endpoint(authEndpoint: String)
    case authRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)
    case authorizer(authorizer: Authorizer)
    case inline(secret: String)
    case noMethod
}
