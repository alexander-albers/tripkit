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
