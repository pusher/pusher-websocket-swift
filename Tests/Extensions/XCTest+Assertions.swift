import XCTest

private func executeAndAssignResult<T>(_ expression: () throws -> T?, to: inout T?) rethrows {
    to = try expression()
}

private func executeAndAssignEquatableResult<T>(_ expression: @autoclosure () throws -> T?, to: inout T?) rethrows where T: Equatable {
    to = try expression()
}

func XCTAssertNotNil<T>(_ expression: @autoclosure () throws -> T?, _ message: String = "", file: StaticString = #file, line: UInt = #line, also validateResult: (T) -> Void) {

    var result: T?

    XCTAssertNoThrow(try executeAndAssignResult(expression, to: &result), message, file: file, line: line)
    XCTAssertNotNil(result, message, file: file, line: line)

    if let result = result {
        validateResult(result)
    }
}
