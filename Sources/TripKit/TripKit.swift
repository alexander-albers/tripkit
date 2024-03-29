import Foundation

public class TripKit {
    
    public static let shared = TripKit()
    
    public let hhmmFormatter = DateFormatter()
    public let ddmmhhmmFormatter = DateFormatter()
    public let ddmmyyyyFormatter = DateFormatter()
    public let multilineWeekDayFormatter = DateFormatter()
    public let weekDayFormatter = DateFormatter()
    
    private init() {
        updateFormats()
    }
    
    public func updateFormats(for locale: Locale = .current) {
        hhmmFormatter.timeStyle = .short
        hhmmFormatter.locale = locale
        
        let ddmmhhmmFormatString: String
        if let format = DateFormatter.dateFormat(fromTemplate: "ddMM", options: 0, locale: locale) {
            ddmmhhmmFormatString = format
        } else {
            ddmmhhmmFormatString = "dd.MM"
        }
        ddmmhhmmFormatter.dateFormat = "\(ddmmhhmmFormatString)', '\(hhmmFormatter.dateFormat!)"
        ddmmhhmmFormatter.locale = locale
        
        let ddmmyyyyFormatString: String
        if let format = DateFormatter.dateFormat(fromTemplate: "ddMMyyyy", options: 0, locale: locale) {
            ddmmyyyyFormatString = format
        } else {
            ddmmyyyyFormatString = "dd.MM.yyyy"
        }
        ddmmyyyyFormatter.dateFormat = ddmmyyyyFormatString
        ddmmyyyyFormatter.locale = locale
        
        let multilineWeekDayFormatString: String
        if let format = DateFormatter.dateFormat(fromTemplate: "EEEddMM", options: 0, locale: locale) {
            multilineWeekDayFormatString = format
        } else {
            multilineWeekDayFormatString = "EEE', 'dd.MM"
        }
        multilineWeekDayFormatter.dateFormat = "\(multilineWeekDayFormatString)'\n'\(hhmmFormatter.dateFormat!)"
        multilineWeekDayFormatter.locale = locale
        
        let weekDayFormatString: String
        if let format = DateFormatter.dateFormat(fromTemplate: "EEEEddMMy", options: 0, locale: locale) {
            weekDayFormatString = format
        } else {
            weekDayFormatString = "EEEE', 'dd.mm.y"
        }
        weekDayFormatter.dateFormat = "\(weekDayFormatString)', '\(hhmmFormatter.dateFormat!)"
        weekDayFormatter.locale = locale
    }
    
}

public var gregorianCalendar = Calendar(identifier: .gregorian)

public func string(from timeInterval: TimeInterval) -> String {
    return String(format: "%0.2d:%0.2d", Int(timeInterval / 60 / 60), Int((timeInterval / 60).truncatingRemainder(dividingBy: 60)))
}

extension String {
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(from: Int) -> String {
        return self[min(from, count) ..< count]
    }
    
    func substring(to: Int) -> String {
        return self[0 ..< max(0, to)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(count, r.lowerBound)),
                                            upper: min(count, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
    var emptyToNil: String? {
        return isEmpty ? nil : self
    }
    
    var ensurePunctuation: String {
        var result = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if !result.hasSuffix(".") && !result.hasSuffix("!") {
            result += "."
        }
        return result
    }
    
    func match(pattern: NSRegularExpression) -> MatchResult? {
        let ns = self as NSString
        guard let match = pattern.firstMatch(in: self, options: [], range: NSMakeRange(0, self.count)) else { return nil }
        var matches: [String?] = []
        if match.numberOfRanges <= 1 {
            return MatchResult(matches: matches)
        }
        for i in 1..<match.numberOfRanges {
            let range = match.range(at: i)
            if range.length == 0 {
                matches.append(nil)
            } else {
                matches.append(ns.substring(with: range))
            }
        }
        return MatchResult(matches: matches)
    }
    
    func matches(pattern: NSRegularExpression) -> [MatchResult] {
        var result: [MatchResult] = []
        let ns = self as NSString
        for match in pattern.matches(in: self, options: [], range: NSMakeRange(0, self.count)) {
            var matches: [String?] = []
            if match.numberOfRanges <= 1 {
                result.append(MatchResult(matches: matches))
                continue
            }
            for i in 1..<match.numberOfRanges {
                let range = match.range(at: i)
                if range.length == 0 {
                    matches.append(nil)
                } else {
                    matches.append(ns.substring(with: range))
                }
            }
            result.append(MatchResult(matches: matches))
        }
        return result
    }
    
    func isSmallerVersionThan(_ other: String) -> Bool {
        return self.compare(other, options: .numeric) == .orderedAscending
    }
    
}

class MatchResult {
    
    private let matches: [String?]
    
    var count: Int {
        return matches.count
    }
    
    init(matches: [String?]) {
        self.matches = matches
    }
    
    subscript (i: Int) -> String? {
        if i >= 0 && i < matches.count {
            return matches[i]
        } else {
            return nil
        }
    }
}

infix operator =~
public func =~(string:String, regex:String) -> Bool {
    if let range = string.range(of: regex, options: .regularExpression) {
        return range.lowerBound == string.startIndex && range.upperBound == string.endIndex
    } else {
        return false
    }
}

func |= (left: inout  Bool, right: Bool) {
    left = left || right
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index?) -> Element? {
        guard let index = index else { return nil }
        return indices.contains(index) ? self[index] : nil
    }
}
