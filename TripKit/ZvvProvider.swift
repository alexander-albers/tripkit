import Foundation

public class ZvvProvider: AbstractHafasLegacyProvider {
    
    static let API_BASE = "https://online.fahrplan.zvv.ch/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .regionalTrain, .regionalTrain, .ferry, .suburbanTrain, .bus, .cablecar, .subway, .tram]
    
    public init() {
        super.init(networkId: .ZVV, apiBase: ZvvProvider.API_BASE, apiLanguage: "dn", productsMap: ZvvProvider.PRODUCTS_MAP)
        
        jsonGetStopsEncoding = .utf8
        jsonNearbyLocationsEncoding = .utf8
        
        styles = [
            // S-Bahn
            "SS2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#70c82c"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#587AC2"), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#EE7267"), foregroundColor: LineStyle.white),
            "SS5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6aadc3"), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6f41a4"), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fbb809"), foregroundColor: LineStyle.black),
            "SS8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#562691"), foregroundColor: LineStyle.white),
            "SS9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#069A5D"), foregroundColor: LineStyle.white),
            "SS10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fbc434"), foregroundColor: LineStyle.black),
            "SS11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ae90cf"), foregroundColor: LineStyle.white),
            "SS12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "SS13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#905723"), foregroundColor: LineStyle.white),
            "SS14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#753c0c"), foregroundColor: LineStyle.white),
            "SS15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c79f73"), foregroundColor: LineStyle.white),
            "SS16": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#68c971"), foregroundColor: LineStyle.white),
            "SS17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#3b99b5"), foregroundColor: LineStyle.white),
            "SS18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f14337"), foregroundColor: LineStyle.white),
            "SS21": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#9acaee"), foregroundColor: LineStyle.white),
            "SS22": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8dd24e"), foregroundColor: LineStyle.white),
            "SS24": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ab7745"), foregroundColor: LineStyle.white),
            "SS26": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0e87aa"), foregroundColor: LineStyle.white),
            "SS29": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#3dba56"), foregroundColor: LineStyle.white),
            "SS30": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0b8ed8"), foregroundColor: LineStyle.white),
            "SS33": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#51aae3"), foregroundColor: LineStyle.white),
            "SS35": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#81c0eb"), foregroundColor: LineStyle.white),
            "SS40": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ae90cf"), foregroundColor: LineStyle.white),
            "SS41": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f89a83"), foregroundColor: LineStyle.white),
            "SS55": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#905723"), foregroundColor: LineStyle.white),
            
            // Tram
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#19ae48"), foregroundColor: LineStyle.white),
            "T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#453fa0"), foregroundColor: LineStyle.white),
            "T5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8c5a2c"), foregroundColor: LineStyle.white),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d6973c"), foregroundColor: LineStyle.white),
            "T7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#231f20"), foregroundColor: LineStyle.white),
            "T8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#99d420"), foregroundColor: LineStyle.black),
            "T9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#453fa0"), foregroundColor: LineStyle.white),
            "T10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ee1998"), foregroundColor: LineStyle.white),
            "T11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#19ae48"), foregroundColor: LineStyle.white),
            "T12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#85d7e3"), foregroundColor: LineStyle.black),
            "T13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fdd205"), foregroundColor: LineStyle.black),
            "T14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#2cbbf2"), foregroundColor: LineStyle.white),
            "T15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "T17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#9e1a6e"), foregroundColor: LineStyle.white),
            
            // Bus/Trolley
            "B31": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#999bd3"), foregroundColor: LineStyle.white),
            "B32": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d8a1d6"), foregroundColor: LineStyle.black),
            "B33": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e4e793"), foregroundColor: LineStyle.black),
        ]
    }
    
    static let OPERATORS = ["SBB", "SZU"]
    static let PLACES = ["Zürich", "Winterthur"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard var stationName = stationName else { return super.split(stationName: nil) }
        
        for op in ZvvProvider.OPERATORS {
            if stationName.hasSuffix(" " + op) {
                stationName = stationName.substring(to: stationName.length - op.length - 1)
                break
            } else if stationName.hasSuffix(" (\(op)") {
                stationName = stationName.substring(to: stationName.length - op.length - 3)
                break
            }
        }
        
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        
        for place in ZvvProvider.PLACES {
            if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + ",") {
                return (place, stationName.substring(from: place.length + 1))
            }
        }
        
        return super.split(stationName: stationName)
    }
    
    override func split(poi: String?) -> (String?, String?) {
        guard let poi = poi else { return super.split(poi: nil) }
        if let m = poi.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(poi: poi)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let address = address else { return super.split(address: nil) }
        if let m = address.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(address: address)
    }
    
    let P_NUMBER = try! NSRegularExpression(pattern: "\\d{2,5}")
    
    override func parse(lineAndType: String) throws -> Line {
        guard let lineAndTypeMatch = P_NORMALIZE_LINE_AND_TYPE.firstMatch(in: lineAndType, options: [], range: NSMakeRange(0, lineAndType.count)) else {
            throw ParseError(reason: "cannot normalize \(lineAndType)")
        }
        let number = (lineAndType as NSString).substring(with: lineAndTypeMatch.range(at: 1)).replacingOccurrences(of: " ", with: "")
        let type = (lineAndType as NSString).substring(with: lineAndTypeMatch.range(at: 2))
        
        if type == "Bus" {
            return newLine(network: nil, product: .bus, normalizedName: stripPrefix(of: number, with: "Bus"), comment: nil, attrs: [])
        } else if type == "Bus-NF" {
            return newLine(network: nil, product: .bus, normalizedName: stripPrefix(of: number, with: ["Bus", "Bus-NF"]), comment: nil, attrs: [.wheelChairAccess])
        } else if type == "Tro" || type == "Trolley" {
            return newLine(network: nil, product: .bus, normalizedName: stripPrefix(of: number, with: "Tro"), comment: nil, attrs: [])
        } else if type == "Tro-NF" {
            return newLine(network: nil, product: .bus, normalizedName: stripPrefix(of: number, with: ["Tro", "Tro-NF"]), comment: nil, attrs: [.wheelChairAccess])
        } else if type == "Trm" {
            return newLine(network: nil, product: .tram, normalizedName: stripPrefix(of: number, with: "Trm"), comment: nil, attrs: [])
        } else if type == "Trm-NF" {
            return newLine(network: nil, product: .tram, normalizedName: stripPrefix(of: number, with: ["Trm", "Trm-NF"]), comment: nil, attrs: [.wheelChairAccess])
        } else if number == "S18" {
            return newLine(network: nil, product: .suburbanTrain, normalizedName: "S18", comment: nil, attrs: [])
        }
        
        if let _ = number.match(pattern: P_NUMBER) {
            return newLine(network: nil, product: nil, normalizedName: number, comment: nil, attrs: [])
        }
        
        if let product = normalize(type: type) {
            return newLine(network: nil, product: product, normalizedName: number, comment: nil, attrs: [])
        }
        
        return try super.parse(lineAndType: lineAndType)
    }
    
    private func stripPrefix(of string: String, with prefixes: [String]) -> String {
        for prefix in prefixes {
            if string.hasPrefix(prefix) {
                return string.substring(from: prefix.length)
            }
        }
        return string
    }
    
    private func stripPrefix(of string: String, with prefix: String) -> String {
        return stripPrefix(of: string, with: [prefix])
    }
    
    override func normalize(type: String) -> Product? {
        let ucType = type.uppercased()
        
        switch ucType {
        case "N": // Nachtbus
            return .bus
        case "TX":
            return .bus
        case "KB":
            return .bus
        case "TE2": // Basel - Strasbourg
            return .regionalTrain
        case "D-SCHIFF":
            return .ferry
        case "DAMPFSCH":
            return .ferry
        case "BERGBAHN":
            return .cablecar
        case "LSB": // Luftseilbahn
            return .cablecar
        case "SLB": // Sesselliftbahn
            return .cablecar
        default:
            return super.normalize(type: type)
        }
    }
    
}
