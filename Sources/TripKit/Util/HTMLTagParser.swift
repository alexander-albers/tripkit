//

import Foundation
import os.log

fileprivate let DEBUG_XML_STRUCTURE = false

extension String {
    /// Strips HTML tags while respecting some special cases, likes <p>, <br>, <ul>, <ol> and <li> tags.
    ///
    /// Note that the string actually has to be valid XML and not HTML: <br> is technically not allowed and should be <br/>.
    ///
    /// - Returns: the stripped string or the original string in case of an unexpected parse error.
    func stripHTMLTags() -> String {
        // Embed in own tag, since text may not include start and end tags
        let xml = "<TRIPKIT>\(self.replacingOccurrences(of: "<br>", with: "<br/>"))</TRIPKIT>"
        // Convert text to data
        guard let data = xml.data(using: .utf8) else { return self }
        // Start parsing
        let parser = XMLParser(data: data)
        let delegate = ParserDelegate(xml: xml)
        parser.delegate = delegate
        _ = parser.parse()
        return delegate.result.trimmingCharacters(in: .whitespacesAndNewlines).emptyToNil ?? self
    }
}

class ParserDelegate: NSObject, XMLParserDelegate {
    let xml: String
    
    var result: String = ""
    var tabStop = 0
    
    var orderedList = false
    var unorderedList = false
    var listIndex = 0
    
    var shouldStripWhitespaces = false
    
    init(xml: String) {
        self.xml = xml
        super.init()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // DEBUG
        print("DID START ELEMENT \(elementName)")
        tabStop += 1
        //
        
        // Whitespaces and newlines should be stripped before and after specific handled tags.
        checkShouldStripWhitespaces(elementName: elementName)
        switch elementName.lowercased() {
        case "ul":
            unorderedList = true
        case "ol":
            orderedList = true
        case "li":
            // Insert a newline if the result does not end with one yet.
            insertNewlineIfNeeded()
            // Increase index for ordered lists.
            if orderedList {
                listIndex += 1
            }
        case "p":
            // Insert a newline if the result does not end with one yet.
            insertNewlineIfNeeded()
        case "br":
            // Always insert a newline.
            result += "\n"
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // DEBUG
        tabStop -= 1
        //
        
        // Whitespaces and newlines should be stripped before and after specific handled tags.
        checkShouldStripWhitespaces(elementName: elementName)
        switch elementName.lowercased() {
        case "ul":
            unorderedList = false
        case "ol":
            orderedList = false
            // Reset sort index for ordered lists
            listIndex = 0
        default:
            break
        }
        print("DID END ELEMENT \(elementName)")
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Strip whitespaces and newlines if needed (i.e. when specific tags have been handled).
        let chars = shouldStripWhitespaces ? string.trimmingCharacters(in: .whitespacesAndNewlines) : string
        // Skip if text is empty.
        if chars.isEmpty { return }
        // DEBUG
        print("FOUND CHARACTERS \(String(describing: Optional(chars)))")
        //
        
        // Handle ordered and unordered lists
        if unorderedList {
            result += "• " + chars
        } else if orderedList && listIndex > 0 {
            result += "\(listIndex). " + chars
        } else {
            result += chars
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        os_log("Parse error occured while parsing xml: %{public}@", log: .default, type: .error, (parseError as NSError).description)
    }
    
    /// Whitespaces and newlines should be stripped before and after specific handled tags.
    private func checkShouldStripWhitespaces(elementName: String) {
        switch elementName.lowercased() {
        case "ul", "ol", "li", "p":
            shouldStripWhitespaces = true
        default:
            shouldStripWhitespaces = false
        }
    }
    
    /// Insert a newline if the result does not end with one yet.
    private func insertNewlineIfNeeded() {
        if !result.hasSuffix("\n") {
            result += "\n"
        }
    }
    
    /// Prints everything with the corrent indent.
    func print(_ text: String) {
        #if DEBUG
        guard DEBUG_XML_STRUCTURE else { return }
        var tab = ""
        for _ in 0..<tabStop {
            tab += "\t"
        }
        Swift.print(tab + text)
        #endif
    }
}
