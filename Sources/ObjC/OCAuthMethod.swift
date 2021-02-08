import Foundation

@objcMembers
@objc public class OCAuthMethod: NSObject {
    var type: Int
    var secret: String?
    var authEndpoint: String?
    var authRequestBuilder: AuthRequestBuilderProtocol?
    var authorizer: Authorizer?

    public init(type: Int) {
        self.type = type
    }

    public init(authEndpoint: String) {
        self.type = 0
        self.authEndpoint = authEndpoint
    }

    public init(authRequestBuilder: AuthRequestBuilderProtocol) {
        self.type = 1
        self.authRequestBuilder = authRequestBuilder
    }

    public init(secret: String) {
        self.type = 2
        self.secret = secret
    }

    public init(authorizer: Authorizer) {
        self.type = 3
        self.authorizer = authorizer
    }
}
