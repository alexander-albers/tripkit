import Foundation

/// RailTeam (EU)
public class RtProvider: AbstractHafasLegacyProvider {
    
    static let API_BASE = "http://railteam.hafas.eu/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .bus, .ferry, .subway, .tram, .onDemand]
    
    public init() {
        super.init(networkId: .RT, apiBase: RtProvider.API_BASE, apiLanguage: "dn", productsMap: RtProvider.PRODUCTS_MAP)
        
        stationBoardHasStationTable = false
    }
    
    override func normalize(type: String) -> Product? {
        let ucType = type.uppercased()
        
        if ucType == "N" { // Frankreich, Tours
            return .regionalTrain
        } else if ucType == "U70" || ucType == "X70" || ucType == "T84" {
            return nil
        } else if type =~ "\\d{4,5}" {
            return nil
        } else {
            return super.normalize(type: type)
        }
    }
    
}
