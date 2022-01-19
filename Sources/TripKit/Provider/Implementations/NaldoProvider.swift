import Foundation

public class NaldoProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://efa2.naldo.de/naldo/"
    
    public init() {
        super.init(networkId: .NALDO, apiBase: NaldoProvider.API_BASE)
    }
    
    override func stopFinderRequestParameters(builder: UrlBuilder, constraint: String, types: [LocationType]?, maxLocations: Int, outputFormat: String) {
        super.stopFinderRequestParameters(builder: builder, constraint: constraint, types: types, maxLocations: maxLocations, outputFormat: outputFormat)
        builder.removeParameter(key: "regionID_sf")
        builder.addParameter(key: "naldoSugMacro", value: true)
    }
}
