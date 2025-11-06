import Foundation

/// Verkehrsverbund Neckar-Alb-Donau (DE)
public class NaldoProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://www.naldo.de/_assets/012ccdbd1331184d82aa9387f0ed2f73/efa/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .NALDO, apiBase: NaldoProvider.API_BASE)
        includeRegionId = false
    }
    
    override func stopFinderRequestParameters(builder: UrlBuilder, constraint: String, types: [LocationType]?, maxLocations: Int, outputFormat: String) {
        super.stopFinderRequestParameters(builder: builder, constraint: constraint, types: types, maxLocations: maxLocations, outputFormat: outputFormat)
        builder.addParameter(key: "naldoSugMacro", value: true)
    }
}
