import XCTest
@testable import PusherSwift

public class DummyPusherKeyProvider: PusherKeyProviding {
    
    private let file: StaticString
    private let line: UInt

    init(file: StaticString = #file, line: UInt = #line) {
        self.file = file
        self.line = line
    }
    
    public var decryptionKey: String {
        XCTFail("Unexpected call to `\(#function)` on `\(String(describing: self))` object. `Dummy` object's should be never interacted with and only used to satisfy the compiler. Consider using a `Stub` instead", file: file, line: line)
        return ""
    }
    
}
