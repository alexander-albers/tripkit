//

import XCTest
@testable import TripKit

class HTMLFormatDecodingTests: XCTestCase {

    func testComplexXML() {
        let xml = """
        <h1>Title</h1>
        Hello World
        <ul>
            <li>Test 1</li>
            <li>Test 2</li>
        </ul>
        <p>This is a paragraph</p>
        <br/>
        <ol>
            <li>Test 1</li>
            <li>Test 2</li>
        </ol>
        """
        
        let expected = """
        Title
        Hello World
        • Test 1
        • Test 2
        This is a paragraph

        1. Test 1
        2. Test 2
        """
        
        let formatted = xml.stripHTMLTags()
        XCTAssertEqual(formatted, expected)
    }
    
    func testRealText() {
        let xml = """
        Betrifft die Linien: 2, 3, 4, 6, 8, N4<br /><br />Umleitungen (in beiden Richtungen)<br />von Donnerstag, 1.8.2019 ca. 7:00 Uhr<br />bis Montag, 5.8.2019 abends
        """
        
        let expected = """
        Betrifft die Linien: 2, 3, 4, 6, 8, N4
        
        Umleitungen (in beiden Richtungen)
        von Donnerstag, 1.8.2019 ca. 7:00 Uhr
        bis Montag, 5.8.2019 abends
        """
        
        let formatted = xml.stripHTMLTags()
        XCTAssertEqual(formatted, expected)
    }
    
    func testPlainText() {
        let xml = """
        First line.
        Second line.
        
        Third line.
        """
        XCTAssertEqual(xml.stripHTMLTags(), xml)
    }
    
    func testIgnoredTags() {
        let xml = """
        <b>Important:</b> Please wear a mask.
        """
        let formatted = xml.stripHTMLTags()
        XCTAssertEqual(formatted, "Important: Please wear a mask.")
    }
    
    func testXMLTags() {
        let xml = """
        One & two
        One &amp; two
        One &lt; two
        """
        
        let expected = """
        One & two
        One & two
        One < two
        """
        
        let formatted = xml.stripHTMLTags()
        XCTAssertEqual(formatted, expected)
    }
    
    func testSpecialCharacters() {
        let xml = """
        Coronama&szlig;nahmen
        Coronamaßnahmen
        
        Sch&#246;n
        Sch&ouml;n
        Schön
        """
        
        let expected = """
        Coronamaßnahmen
        Coronamaßnahmen
        
        Schön
        Schön
        Schön
        """
        
        let formatted = xml.stripHTMLTags()
        XCTAssertEqual(formatted, expected)
    }

}
