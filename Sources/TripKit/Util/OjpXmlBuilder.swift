import Foundation

/// A minimal XML element tree used to construct OJP request bodies.
///
/// `SWXMLHash`, the package's XML dependency, is a *parser* only — its element/builder types are
/// internal and it offers no public serialization API. Foundation's `XMLDocument` builder is
/// unavailable on iOS/watchOS/tvOS. This lightweight builder fills that gap: it guarantees
/// well-formed output and escapes text/attribute content automatically, so request construction no
/// longer relies on hand-written, manually escaped string interpolation.
class OjpXmlElement {

    let name: String
    private var attributes: [(String, String)] = []
    private var children: [OjpXmlElement] = []
    private var textValue: String?

    init(_ name: String) {
        self.name = name
    }

    /// Convenience initializer for a leaf element with text content.
    init(_ name: String, text: String?) {
        self.name = name
        self.textValue = text
    }

    @discardableResult
    func attribute(_ name: String, _ value: String) -> OjpXmlElement {
        attributes.append((name, value))
        return self
    }

    /// Appends a child element and returns the receiver (for chaining).
    @discardableResult
    func add(_ child: OjpXmlElement) -> OjpXmlElement {
        children.append(child)
        return self
    }

    @discardableResult
    func add(_ elements: [OjpXmlElement]) -> OjpXmlElement {
        children.append(contentsOf: elements)
        return self
    }

    /// Appends a new leaf child `<name>text</name>` if `text` is non-nil, then returns the receiver.
    @discardableResult
    func addLeaf(_ name: String, _ text: String?) -> OjpXmlElement {
        guard let text = text else { return self }
        children.append(OjpXmlElement(name, text: text))
        return self
    }

    /// Serializes the element (and its subtree) to an XML string. Overridable for raw passthrough.
    func serialize() -> String {
        var result = "<" + name
        for (key, value) in attributes {
            result += " \(key)=\"\(OjpXmlElement.escape(value, attribute: true))\""
        }
        if children.isEmpty && (textValue == nil || textValue!.isEmpty) {
            result += "/>"
            return result
        }
        result += ">"
        if let textValue = textValue {
            result += OjpXmlElement.escape(textValue, attribute: false)
        }
        for child in children {
            result += child.serialize()
        }
        result += "</\(name)>"
        return result
    }

    /// Escapes the predefined XML entities. Attribute values additionally escape quotes.
    static func escape(_ string: String, attribute: Bool) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        if attribute {
            result = result.replacingOccurrences(of: "\"", with: "&quot;")
            result = result.replacingOccurrences(of: "'", with: "&apos;")
        }
        return result
    }
}

/// An element whose content is pre-formatted, well-formed XML that must be emitted verbatim.
///
/// Used to splice back an OJP `<TripResult>` element that the server echoed in a previous response
/// (required by `OJPTripRefineRequest`), without re-escaping it.
final class OjpRawXmlElement: OjpXmlElement {

    private let rawXml: String

    init(rawXml: String) {
        self.rawXml = rawXml
        super.init("")
    }

    override func serialize() -> String {
        return rawXml
    }
}
