//
//  Helpers.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Foundation
import PusherSwift

func convertStringToDictionary(text: String) -> [String:AnyObject]? {
    if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
            return json
        } catch {
            print("Something went wrong")
        }
    }
    return nil
}

extension AuthMethod: Equatable {
}

public func ==(lhs: AuthMethod, rhs: AuthMethod) -> Bool {
    switch (lhs, rhs) {
    case (let .Endpoint(authEndpoint1) , let .Endpoint(authEndpoint2)):
        return authEndpoint1 == authEndpoint2

    case (let .Internal(secret1), let .Internal(secret2)):
        return secret1 == secret2

    case (.NoMethod, .NoMethod):
        return true

    default:
        return false
    }
}
