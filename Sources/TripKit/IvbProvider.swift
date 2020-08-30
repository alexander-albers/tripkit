import Foundation

public class IvbProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplan.ivb.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .suburbanTrain, .subway, nil, .tram, .regionalTrain, .bus, .bus, .tram, .ferry, .onDemand, .bus, .regionalTrain, nil, nil, nil]
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .IVB, apiBase: IvbProvider.API_BASE, productsMap: IvbProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.20"
        apiClient = ["id": "VAO", "l": "vs_ivb", "type": "WEB", "name": "webapp"]
        extVersion = "VAO.7"
        styles = [
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(210, 161, 163), foregroundColor: LineStyle.white),
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(185, 72, 93), foregroundColor: LineStyle.white),
            "T2A": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(185, 72, 93), foregroundColor: LineStyle.white),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(192, 111, 119), foregroundColor: LineStyle.white),
            "T5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(136, 79, 94), foregroundColor: LineStyle.white),
            "T5E": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(136, 79, 94), foregroundColor: LineStyle.white),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(146, 30, 48), foregroundColor: LineStyle.white),
            "TSTB": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(96, 15, 23), foregroundColor: LineStyle.white),
            "TN1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(29, 49, 86), foregroundColor: LineStyle.white),
            "TN2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(29, 49, 86), foregroundColor: LineStyle.white),
            "TN3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(29, 49, 86), foregroundColor: LineStyle.white),
            "TN7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(29, 49, 86), foregroundColor: LineStyle.white),
            "TN8": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(29, 49, 86), foregroundColor: LineStyle.white),
            "BA": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(46, 106, 159), foregroundColor: LineStyle.white),
            "BB": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(175, 168, 53), foregroundColor: LineStyle.white),
            "BC": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(133, 200, 239), foregroundColor: LineStyle.white),
            "BF": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(119, 37, 125), foregroundColor: LineStyle.white),
            "BH": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(132, 166, 161), foregroundColor: LineStyle.white),
            "BJ": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(159, 88, 148), foregroundColor: LineStyle.white),
            "BLK": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(199, 176, 207), foregroundColor: LineStyle.white),
            "BM": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(208, 140, 80), foregroundColor: LineStyle.white),
            "BR": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(220, 109, 43), foregroundColor: LineStyle.white),
            "BT": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(131, 182, 66), foregroundColor: LineStyle.white),
            "BW": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(66, 148, 73), foregroundColor: LineStyle.white),
            "B501": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(242, 227, 75), foregroundColor: LineStyle.black),
            "B502": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(242, 227, 75), foregroundColor: LineStyle.black),
            "B503": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(242, 227, 75), foregroundColor: LineStyle.black),
            "B504": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(242, 227, 75), foregroundColor: LineStyle.black),
            "B505": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(242, 227, 75), foregroundColor: LineStyle.black),
            "B590": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(242, 227, 75), foregroundColor: LineStyle.black),
            "B502N": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(242, 227, 75), foregroundColor: LineStyle.black),
            "B590N": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(242, 227, 75), foregroundColor: LineStyle.black),
            "THBB": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(225, 140, 180), foregroundColor: LineStyle.white),
            "BTS": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(208, 45, 34), foregroundColor: LineStyle.white)
        ]
    }
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return (nil, nil) }
        if stationName.hasPrefix("Innsbruck ") {
            return ("Innsbruck", stationName.substring(from: "Innsbruck ".count))
        }
        return super.split(stationName: stationName)
    }

}
