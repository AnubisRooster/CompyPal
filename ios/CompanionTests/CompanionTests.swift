import XCTest

final class CompanionTests: XCTestCase {
    func testHealthResponseDecoding() throws {
        let json = """
        {"status": "ok", "service": "companion-api"}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(HealthResponse.self, from: json)
        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.service, "companion-api")
    }
}
