import Foundation

public class SbbProvider: AbstractHafasLegacyProvider {
    
    static let API_BASE = "http://fahrplan.sbb.ch/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .ferry, .suburbanTrain, .bus, .cablecar, .regionalTrain, .tram]
    
    public init() {
        super.init(networkId: .SBB, apiBase: SbbProvider.API_BASE, apiLanguage: "dn", productsMap: SbbProvider.PRODUCTS_MAP)
        
        stationBoardHasStationTable = false
    }
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
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
    
    override func normalize(type: String) -> Product? {
        let ucType = type.uppercased()
        
        switch ucType {
        case "IN": // Italien Roma-Lecce
            return .highSpeedTrain
        case "IT": // Italien Roma-Venezia
            return .highSpeedTrain
        case "T":
            return .regionalTrain
        case "TE2": // Basel - Strasbourg
            return .regionalTrain
        case "TX":
            return .bus
        case "NFO":
            return .bus
        case "KB":
            return .bus
        default:
            return super.normalize(type: type)
        }
    }
    
}
