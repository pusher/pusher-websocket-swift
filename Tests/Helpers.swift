//
//  Helpers.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Foundation
import PusherSwift

func convertStringToDictionary(_ text: String) -> [String:AnyObject]? {
    if let data = text.data(using: String.Encoding.utf8) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
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
    case (let .endpoint(authEndpoint1) , let .endpoint(authEndpoint2)):
        return authEndpoint1 == authEndpoint2

    case (let .`internal`(secret1), let .`internal`(secret2)):
        return secret1 == secret2

    case (.noMethod, .noMethod):
        return true

    default:
        return false
    }
}
