import Foundation

let P_ISO_DATE = try! NSRegularExpression(pattern: "(\\d{4})-?(\\d{2})-?(\\d{2})")
let P_ISO_DATE_REVERSE = try! NSRegularExpression(pattern: "(\\d{2})[-\\.](\\d{2})[-\\.](\\d{4})")

func parseIsoDate(from dateString: String, dateComponents: inout DateComponents) {
    if let match = dateString.match(pattern: P_ISO_DATE) {
        dateComponents.day = Int(match[2] ?? "")
        dateComponents.month = Int(match[1] ?? "")
        dateComponents.year = Int(match[0] ?? "")
    } else if let match = dateString.match(pattern: P_ISO_DATE_REVERSE) {
        dateComponents.day = Int(match[0] ?? "")
        dateComponents.month = Int(match[1] ?? "")
        dateComponents.year = Int(match[2] ?? "")
    }
}

let P_ISO_TIME = try! NSRegularExpression(pattern: "(\\d{2})-?(\\d{2})")

func parseIsoTime(from timeString: String, dateComponents: inout DateComponents) {
    if let match = timeString.match(pattern: P_ISO_TIME) {
        dateComponents.hour = Int(match[0] ?? "")
        dateComponents.minute = Int(match[1] ?? "")
    }
}

let P_EUROPEAN_TIME = try! NSRegularExpression(pattern: "(\\d{1,2}):(\\d{2})(?::(\\d{2}))?")

func parseEuropeanTime(from timeString: String, dateComponents: inout DateComponents) {
    if let match = timeString.match(pattern: P_EUROPEAN_TIME) {
        dateComponents.hour = Int(match[0] ?? "")
        dateComponents.minute = Int(match[1] ?? "")
        dateComponents.second = Int(match[2] ?? "")
    }
}

fileprivate let P_HTML_UNORDERED_LIST = try! NSRegularExpression(pattern: "<ul>(.*?)</ul>", options: [.caseInsensitive, .dotMatchesLineSeparators])
fileprivate let P_HTML_LIST_ITEM = try! NSRegularExpression(pattern: "<li>(.*?)</li>", options: [.caseInsensitive, .dotMatchesLineSeparators])
fileprivate let P_HTML_BREAKS = try! NSRegularExpression(pattern: "(<br\\s*/>)", options: [.caseInsensitive, .dotMatchesLineSeparators])

func formatHtml(for string: String?) -> String? {
    guard var string = string else { return nil }
    var result = ""
    
    var pListItem = 0
    for match in P_HTML_LIST_ITEM.matches(in: string, options: [], range: NSRange(location: 0, length: string.length)) {
        let group = match.range(at: 1)
        result += String(string[string.index(string.startIndex, offsetBy: pListItem)..<string.index(string.startIndex, offsetBy: group.location)])
        result += "• "
        result += String(string[string.index(string.startIndex, offsetBy: group.location)..<string.index(string.startIndex, offsetBy: group.location + group.length)])
        result += "\n"
        pListItem = group.location + group.length
    }
    result += String(string[string.index(string.startIndex, offsetBy: pListItem)..<string.endIndex])
    
    string = result
    result = ""
    var pUnorderedList = 0
    for match in P_HTML_UNORDERED_LIST.matches(in: string, options: [], range: NSRange(location: 0, length: string.length)) {
        let group = match.range(at: 1)
        result += String(string[string.index(string.startIndex, offsetBy: pUnorderedList)..<string.index(string.startIndex, offsetBy: group.location)])
        result += "\n"
        result += String(string[string.index(string.startIndex, offsetBy: group.location)..<string.index(string.startIndex, offsetBy: group.location + group.length)])
        pUnorderedList = group.location + group.length
    }
    result += String(string[string.index(string.startIndex, offsetBy: pUnorderedList)..<string.endIndex])
    
    string = result
    result = ""
    var pBreaks = 0
    for match in P_HTML_BREAKS.matches(in: string, options: [], range: NSRange(location: 0, length: string.length)) {
        let startGroup = match.range(at: 1)
        result += String(string[string.index(string.startIndex, offsetBy: pBreaks)..<string.index(string.startIndex, offsetBy: startGroup.location)])
        result += " "
        pBreaks = startGroup.location + startGroup.length
    }
    result += String(string[string.index(string.startIndex, offsetBy: pBreaks)..<string.endIndex])
    
    return resolveEntities(for: result)
}

fileprivate let P_ENTITY = try! NSRegularExpression(pattern: "&(?:#(x[\\da-f]+|\\d+)|(amp|quot|apos|szlig|nbsp));")

func resolveEntities(for string: String?) -> String? {
    guard let string = string else { return nil }
    var result = ""
    
    var pos = 0
    for match in P_ENTITY.matches(in: string, options: [], range: NSRange(location: 0, length: string.length)) {
        let c: Character
        if match.range(at: 1).location != NSNotFound {
            let group = match.range(at: 1)
            let code = String(string[string.index(string.startIndex, offsetBy: group.location)..<string.index(string.startIndex, offsetBy: group.location + group.length)])
            if code[0] == "x" {
                c = Int(code.substring(from: 1), radix: 16).map{ Character(UnicodeScalar($0)!) }!
            } else {
                c = Int(code).map{ Character(UnicodeScalar($0)!) }!
            }
        } else {
            let group = match.range(at: 2)
            let namedEntity = String(string[string.index(string.startIndex, offsetBy: group.location)..<string.index(string.startIndex, offsetBy: group.location + group.length)])
            switch namedEntity {
            case "amp":
                c = "&"
                break
            case "quot":
                c = "\""
                break
            case "szlig":
                c = "\u{00df}"
                break
            case "nbsp":
                c = " "
                break
            default:
                c = " "
                break
            }
        }
        result += String(string[string.index(string.startIndex, offsetBy: pos)..<string.index(string.startIndex, offsetBy: match.range(at: 0).location)])
        result += String(c)
        pos = match.range(at: 0).location + match.range(at: 0).length
    }
    result += String(string[string.index(string.startIndex, offsetBy: pos)..<string.endIndex])
    
    return result
}

extension String {
    
    init?(htmlEncodedString: String?) {
        guard let data = htmlEncodedString?.data(using: .utf8) else {
            return nil
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }
        
        self.init(attributedString.string)
    }
    
}

