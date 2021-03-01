import Foundation

@testable import PusherSwift

func convertStringToDictionary(_ text: String) -> [String: AnyObject]? {
    guard let data = text.data(using: .utf8) else {
        return nil
    }

    do {
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
        return json
    } catch {
        print("Something went wrong")

        return nil
    }
}

extension AuthMethod: Equatable {

    public static func == (lhs: AuthMethod, rhs: AuthMethod) -> Bool {
        switch (lhs, rhs) {
        case (let .endpoint(authEndpoint1), let .endpoint(authEndpoint2)):
            return authEndpoint1 == authEndpoint2

        case (let .inline(secret1), let .inline(secret2)):
            return secret1 == secret2

        case (.noMethod, .noMethod):
            return true

        default:
            return false
        }
    }
}
