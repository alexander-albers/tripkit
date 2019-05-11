import XCTest
@testable import TripKit

class LineStyleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testParseColor() {
        XCTAssertEqual(0x11223344, LineStyle.parseColor("#11223344"))
    }
    
    func testParseColorNoOverflow() {
        XCTAssertEqual(0xffffffff, LineStyle.parseColor("#ffffffff"))
    }
    
    func testParseColorAmendAlpha() {
        XCTAssertEqual(0xff000000, LineStyle.parseColor("#ff000000"))
    }
    
    func testParseColorTooShort() {
        XCTAssertEqual(0, LineStyle.parseColor("#"))
    }
    
    func testParseColorNotNumber() {
        XCTAssertEqual(0, LineStyle.parseColor("#11111z"))
    }
    
}

