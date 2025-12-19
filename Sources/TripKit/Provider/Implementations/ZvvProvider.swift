import Foundation

/// Zürcher Verkehrsverbund (CH)
public class ZvvProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://online.fahrplan.zvv.ch/gate"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .regionalTrain, .regionalTrain, .ferry, .suburbanTrain, .bus, .cablecar, .subway, .tram]
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "it"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .ZVV, apiBase: ZvvProvider.API_BASE, productsMap: ZvvProvider.PRODUCTS_MAP)
        self.mgateEndpoint = ZvvProvider.API_BASE
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.54"
        apiClient = ["id": "ZVV", "type": "WEB", "name": "webapp"]
        extVersion = "ZVV.2"
        
        styles = [
            // S-Bahn
            "SS 2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#70c82c"), foregroundColor: LineStyle.white),
            "SS 3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#587AC2"), foregroundColor: LineStyle.white),
            "SS 4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#EE7267"), foregroundColor: LineStyle.white),
            "SS 5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6aadc3"), foregroundColor: LineStyle.white),
            "SS 6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6f41a4"), foregroundColor: LineStyle.white),
            "SS 7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fbb809"), foregroundColor: LineStyle.black),
            "SS 8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#562691"), foregroundColor: LineStyle.white),
            "SS 9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#069A5D"), foregroundColor: LineStyle.white),
            "SS 10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fbc434"), foregroundColor: LineStyle.black),
            "SS 11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ae90cf"), foregroundColor: LineStyle.white),
            "SS 12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "SS 13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#905723"), foregroundColor: LineStyle.white),
            "SS 14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#753c0c"), foregroundColor: LineStyle.white),
            "SS 15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c79f73"), foregroundColor: LineStyle.white),
            "SS 16": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#68c971"), foregroundColor: LineStyle.white),
            "SS 17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#3b99b5"), foregroundColor: LineStyle.white),
            "SS 18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f14337"), foregroundColor: LineStyle.white),
            "SS 21": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#9acaee"), foregroundColor: LineStyle.white),
            "SS 22": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8dd24e"), foregroundColor: LineStyle.white),
            "SS 24": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ab7745"), foregroundColor: LineStyle.white),
            "SS 26": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0e87aa"), foregroundColor: LineStyle.white),
            "SS 29": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#3dba56"), foregroundColor: LineStyle.white),
            "SS 30": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0b8ed8"), foregroundColor: LineStyle.white),
            "SS 33": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#51aae3"), foregroundColor: LineStyle.white),
            "SS 35": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#81c0eb"), foregroundColor: LineStyle.white),
            "SS 40": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ae90cf"), foregroundColor: LineStyle.white),
            "SS 41": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f89a83"), foregroundColor: LineStyle.white),
            "SS 55": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#905723"), foregroundColor: LineStyle.white),
            
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
            "T20": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#9e1762"), foregroundColor: LineStyle.white),
            "T50": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#231f20"), foregroundColor: LineStyle.white),
            "T51": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#231f20"), foregroundColor: LineStyle.white),
            
            // Bus/Trolley
            "B": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#82bfe7")),
            "B31": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#999bd3"), foregroundColor: LineStyle.white),
            "B32": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d8a1d6"), foregroundColor: LineStyle.black),
            "B33": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#e4e793"), foregroundColor: LineStyle.black),
            "B46": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#c5dfa5"), foregroundColor: LineStyle.black),
            "B61": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#a29a91"), foregroundColor: LineStyle.white),
            "B62": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d7ccbc"), foregroundColor: LineStyle.black),
            "B72": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d8aa99"), foregroundColor: LineStyle.black),
            "B80": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d5ddbe"), foregroundColor: LineStyle.black),
            "B89": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d7ccbc"), foregroundColor: LineStyle.black),
        ]
    }
    
    static let OPERATORS = ["SBB", "SZU"]
    static let PLACES = ["Zürich", "Winterthur"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard var stationName = stationName else { return super.split(stationName: nil) }
        
        for op in ZvvProvider.OPERATORS {
            if stationName.hasSuffix(" " + op) {
                stationName = stationName.substring(to: stationName.count - op.count - 1)
                break
            } else if stationName.hasSuffix(" (\(op)") {
                stationName = stationName.substring(to: stationName.count - op.count - 3)
                break
            }
        }
        
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        
        for place in ZvvProvider.PLACES {
            if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + ",") {
                return (place, stationName.substring(from: place.count + 1))
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
    
}
