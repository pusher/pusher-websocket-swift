import XCTest

extension String {

    func removing(_ set: CharacterSet) -> String {
        var newString = self
        newString.removeAll { char -> Bool in
            guard let scalar = char.unicodeScalars.first else { return false }
            return set.contains(scalar)
        }
        return newString
    }

    var escaped: String {
        return self.debugDescription
    }

    func toJsonData(validate: Bool = true, file: StaticString = #file, line: UInt = #line) -> Data {
        do {
            let data = try self.toData()
            if validate {
                // Verify the string is valid JSON (either a dict or an array) before returning
                _ = try toJsonAny()
            }
            return data
        } catch {
            XCTFail("\(error)", file: file, line: line)
        }
        return Data()
    }

    func toJsonDict(file: StaticString = #file, line: UInt = #line) -> [String: Any] {
        do {
            let json = try toJsonAny()

            guard let jsonDict = json as? [String: Any] else {
                XCTFail("Not a dictionary", file: file, line: line)
                return [:]
            }
            return jsonDict
        } catch {
            XCTFail("\(error)", file: file, line: line)
        }
        return [:]
    }

    // MARK: - Private methods

    private func toJsonAny() throws -> Any {
        return try JSONSerialization.jsonObject(with: self.toData(), options: .allowFragments)
    }

    private func toData() throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw JSONError.conversionFailed
        }
        return data
    }
}

// MARK: - Error handling

enum JSONError: Error {
    case conversionFailed
}
