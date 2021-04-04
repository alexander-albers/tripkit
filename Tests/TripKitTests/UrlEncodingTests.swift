import XCTest
@testable import TripKit

class UrlEncodingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEncode() {
        XCTAssertEqual("Hellö-Wörld".encodeUrl(using: .utf8), "Hell%C3%B6-W%C3%B6rld")
        XCTAssertEqual("Hellö-Wörld".encodeUrl(using: .isoLatin1), "Hell%F6-W%F6rld")
    }

    func testDecode() {
        XCTAssertEqual("Hell%C3%B6-W%C3%B6rld".decodeUrl(using: .utf8), "Hellö-Wörld")
        XCTAssertEqual("Hell%F6-W%F6rld".decodeUrl(using: .isoLatin1), "Hellö-Wörld")
    }

}