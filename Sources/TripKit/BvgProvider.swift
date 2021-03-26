import Foundation

public class BvgProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://bvg-apps.hafas.de/bin/"
    static let DESKTOP_QUERY_ENDPOINT = "https://fahrinfo.bvg.de/Fahrinfo/bin/query.bin/dn"
    static let DESKTOP_STBOARD_ENDPOINT = "https://fahrinfo.bvg.de/Fahrinfo/bin/stboard.bin/dn"
    static let PRODUCTS_MAP: [Product?] = [.suburbanTrain, .subway, .tram, .bus, .ferry, .highSpeedTrain, .regionalTrain, .onDemand, nil, nil]
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .BVG, apiBase: BvgProvider.API_BASE, desktopQueryEndpoint: BvgProvider.DESKTOP_QUERY_ENDPOINT, desktopStboardEndpoint: BvgProvider.DESKTOP_STBOARD_ENDPOINT, productsMap: BvgProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.18"
        apiClient = ["id": "BVG", "type": "IPH"]
        extVersion = "BVG.1"
        //jnyFilterIncludes = [["value": "BERLKOENIG", "mode": "INC", "type": "GROUP"]] // when removed, not routes between Hermsdorf and Bundestag can be found...
        
        styles = [
            "SS1": LineStyle(backgroundColor: LineStyle.rgb(221, 77, 174), foregroundColor: LineStyle.white),
            "SS2": LineStyle(backgroundColor: LineStyle.rgb(16, 132, 73), foregroundColor: LineStyle.white),
            "SS25": LineStyle(backgroundColor: LineStyle.rgb(16, 132, 73), foregroundColor: LineStyle.white),
            "SS26": LineStyle(backgroundColor: LineStyle.rgb(16, 132, 73), foregroundColor: LineStyle.white),
            "SS3": LineStyle(backgroundColor: LineStyle.rgb(22, 106, 184), foregroundColor: LineStyle.white),
            "SS41": LineStyle(backgroundColor: LineStyle.rgb(162, 63, 48), foregroundColor: LineStyle.white),
            "SS42": LineStyle(backgroundColor: LineStyle.rgb(191, 90, 42), foregroundColor: LineStyle.white),
            "SS45": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(191, 128, 55), borderColor: LineStyle.rgb(191, 128, 55)),
            "SS46": LineStyle(backgroundColor: LineStyle.rgb(191, 128, 55), foregroundColor: LineStyle.white),
            "SS47": LineStyle(backgroundColor: LineStyle.rgb(191, 128, 55), foregroundColor: LineStyle.white),
            "SS5": LineStyle(backgroundColor: LineStyle.rgb(243, 103, 23), foregroundColor: LineStyle.white),
            "SS7": LineStyle(backgroundColor: LineStyle.rgb(119, 96, 176), foregroundColor: LineStyle.white),
            "SS75": LineStyle(backgroundColor: LineStyle.rgb(119, 96, 176), foregroundColor: LineStyle.white),
            "SS8": LineStyle(backgroundColor: LineStyle.rgb(85, 184, 49), foregroundColor: LineStyle.white),
            "SS85": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(85, 184, 49), borderColor: LineStyle.rgb(85, 184, 49)),
            "SS9": LineStyle(backgroundColor: LineStyle.rgb(148, 36, 64), foregroundColor: LineStyle.white),
            
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(84, 131, 47), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(215, 25, 16), foregroundColor: LineStyle.white),
            "UU12": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(84, 131, 47), backgroundColor2: LineStyle.rgb(215, 25, 16), foregroundColor: LineStyle.white, borderColor: 0),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(47, 152, 154), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(255, 233, 42), foregroundColor: LineStyle.black),
            "UU5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(91, 31, 16), foregroundColor: LineStyle.white),
            "UU55": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(91, 31, 16), foregroundColor: LineStyle.white),
            "UU6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(127, 57, 115), foregroundColor: LineStyle.white),
            "UU7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 153, 204), foregroundColor: LineStyle.white),
            "UU8": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(24, 25, 83), foregroundColor: LineStyle.white),
            "UU9": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(255, 90, 34), foregroundColor: LineStyle.white),
            
            "TM1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#64bae8"), foregroundColor: LineStyle.white),
            "TM2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#68c52f"), foregroundColor: LineStyle.white),
            "TM4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cf1b22"), foregroundColor: LineStyle.white),
            "TM5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#bf8037"), foregroundColor: LineStyle.white),
            "TM6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1e5ca2"), foregroundColor: LineStyle.white),
            "TM8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f46717"), foregroundColor: LineStyle.white),
            "TM10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#108449"), foregroundColor: LineStyle.white),
            "TM13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#36ab94"), foregroundColor: LineStyle.white),
            "TM17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a23f30"), foregroundColor: LineStyle.white),
            
            "T12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8970aa"), foregroundColor: LineStyle.white),
            "T16": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0e80ab"), foregroundColor: LineStyle.white),
            "T18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d5ad00"), foregroundColor: LineStyle.white),
            "T21": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#7d64b2"), foregroundColor: LineStyle.white),
            "T27": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a23f30"), foregroundColor: LineStyle.white),
            "T37": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a23f30"), foregroundColor: LineStyle.white),
            "T50": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ee8f00"), foregroundColor: LineStyle.white),
            "T60": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#108449"), foregroundColor: LineStyle.white),
            "T61": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#108449"), foregroundColor: LineStyle.white),
            "T62": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#125030"), foregroundColor: LineStyle.white),
            "T63": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#36ab94"), foregroundColor: LineStyle.white),
            "T67": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#108449"), foregroundColor: LineStyle.white),
            "T68": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#108449"), foregroundColor: LineStyle.white),
            
            "B": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#993399"), foregroundColor: LineStyle.white),
            "BN": LineStyle(shape: .rect, backgroundColor: LineStyle.black, foregroundColor: LineStyle.white),
            
            "FF1": LineStyle(backgroundColor: LineStyle.blue, foregroundColor: LineStyle.white), // Potsdam
            "FF10": LineStyle(backgroundColor: LineStyle.blue, foregroundColor: LineStyle.white),
            "FF11": LineStyle(backgroundColor: LineStyle.blue, foregroundColor: LineStyle.white),
            "FF12": LineStyle(backgroundColor: LineStyle.blue, foregroundColor: LineStyle.white),
            "FF21": LineStyle(backgroundColor: LineStyle.blue, foregroundColor: LineStyle.white),
            "FF23": LineStyle(backgroundColor: LineStyle.blue, foregroundColor: LineStyle.white),
            "FF24": LineStyle(backgroundColor: LineStyle.blue, foregroundColor: LineStyle.white),
            
            // Regional lines Brandenburg:
            "RRE1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#EE1C23"), foregroundColor: LineStyle.white),
            "RRE2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#FFD403"), foregroundColor: LineStyle.black),
            "RRE3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#F57921"), foregroundColor: LineStyle.white),
            "RRE4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#952D4F"), foregroundColor: LineStyle.white),
            "RRE5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0072BC"), foregroundColor: LineStyle.white),
            "RRE6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#DB6EAB"), foregroundColor: LineStyle.white),
            "RRE7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00854A"), foregroundColor: LineStyle.white),
            "RRE10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#A7653F"), foregroundColor: LineStyle.white),
            "RRE11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#059EDB"), foregroundColor: LineStyle.white),
//            "RRE11": LineStyle(shape: .RECT, backgroundColor: LineStyle.parseColor("#EE1C23"), foregroundColor: LineStyle.WHITE),
            "RRE15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#FFD403"), foregroundColor: LineStyle.black),
            "RRE18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00A65E"), foregroundColor: LineStyle.white),
//            "RRB10": LineStyle(shape: .RECT, backgroundColor: LineStyle.parseColor("#60BB46"), foregroundColor: LineStyle.WHITE),
            "RRB12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#A3238E"), foregroundColor: LineStyle.white),
//            "RRB13": LineStyle(shape: .RECT, backgroundColor: LineStyle.parseColor("#F68B1F"), foregroundColor: LineStyle.WHITE),
            "RRB13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00A65E"), foregroundColor: LineStyle.white),
            "RRB14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#A3238E"), foregroundColor: LineStyle.white),
            "RRB20": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00854A"), foregroundColor: LineStyle.white),
            "RRB21": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5E6DB3"), foregroundColor: LineStyle.white),
            "RRB22": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0087CB"), foregroundColor: LineStyle.white),
            "ROE25": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0087CB"), foregroundColor: LineStyle.white),
            "RNE26": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00A896"), foregroundColor: LineStyle.white),
            "RNE27": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#EE1C23"), foregroundColor: LineStyle.white),
            "RRB30": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00A65E"), foregroundColor: LineStyle.white),
            "RRB31": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#60BB46"), foregroundColor: LineStyle.white),
            "RMR33": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#EE1C23"), foregroundColor: LineStyle.white),
            "ROE35": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5E6DB3"), foregroundColor: LineStyle.white),
            "ROE36": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#A7653F"), foregroundColor: LineStyle.white),
            "RRB43": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5E6DB3"), foregroundColor: LineStyle.white),
            "RRB45": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#FFD403"), foregroundColor: LineStyle.black),
            "ROE46": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#DB6EAB"), foregroundColor: LineStyle.white),
            "RMR51": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#DB6EAB"), foregroundColor: LineStyle.white),
            "RRB51": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#DB6EAB"), foregroundColor: LineStyle.white),
            "RRB54": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#FFD403"), foregroundColor: LineStyle.black),
            "RRB55": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#F57921"), foregroundColor: LineStyle.white),
            "ROE60": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#60BB46"), foregroundColor: LineStyle.white),
            "ROE63": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#FFD403"), foregroundColor: LineStyle.black),
            "ROE65": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0072BC"), foregroundColor: LineStyle.white),
            "RRB66": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#60BB46"), foregroundColor: LineStyle.white),
            "RPE70": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#FFD403"), foregroundColor: LineStyle.black),
            "RPE73": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00A896"), foregroundColor: LineStyle.white),
            "RPE74": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0072BC"), foregroundColor: LineStyle.white),
            "T89": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#EE1C23"), foregroundColor: LineStyle.white),
            "RRB91": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#A7653F"), foregroundColor: LineStyle.white),
            "RRB93": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#A7653F"), foregroundColor: LineStyle.white)
        ]
    }
    
    let P_SPLIT_NAME_SU = try! NSRegularExpression(pattern: "(.*?)(?:\\s+\\((S|U|S\\+U)\\))?")
    let P_SPLIT_NAME_BUS = try! NSRegularExpression(pattern: "(.*?)(\\s+\\[[^\\]]+\\])?")
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        
        var name = stationName
        guard let mSu = name.match(pattern: P_SPLIT_NAME_SU) else { return super.split(stationName: nil) }
        name = mSu[0] ?? name
        let su = mSu[1]
        guard let mBus = name.match(pattern: P_SPLIT_NAME_BUS) else { return super.split(stationName: nil) }
        name = mBus[0] ?? name
        if let mParen = name.match(pattern: P_SPLIT_NAME_PAREN) {
            return (normalize(place: mParen[1]), (su != nil ? su! + " " : "") + (mParen[0] ?? ""))
        }
        if let mComma = name.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (normalize(place: mComma[0]), mComma[1])
        }
        
        return super.split(stationName: stationName)
    }
    
    private func normalize(place: String?) -> String? {
        if place == "Bln" {
            return "Berlin"
        } else {
            return place
        }
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
    
//    let P_NORMALIZE_LINE_NAME_TRAM = try! NSRegularExpression(pattern: "(?:tra|tram)\\s+(.*)")
//    
//    override func normalize(lineName: String) -> String {
//        if let m = lineName.match(pattern: P_NORMALIZE_LINE_NAME_TRAM), let name = m[0] {
//            return name
//        }
//        return super.normalize(lineName: lineName)
//    }
//    
//    override func parse(lineAndType: String) throws -> Line {
//        if lineAndType == "X#" {
//            return newLine(network: nil, product: .HIGH_SPEED_TRAIN, normalizedName: "X", comment: nil, attrs: []) // InterConnex
//        } else {
//            return try super.parse(lineAndType: lineAndType)
//        }
//    }
    
    override func newLine(network: String?, product: Product?, name: String?, shortName: String?, number: String?, trainNumber: String?) -> Line {
        let label = name ?? ""
        if product == .suburbanTrain && label == "S41" {
            return Line(id: nil, network: network, product: product, label: label, name: nil, number: number, trainNumber: trainNumber, style: lineStyle(network: network, product: product, label: label), attr: [.circleClockwise], message: nil)
        } else if product == .suburbanTrain && label == "S42" {
            return Line(id: nil, network: network, product: product, label: label, name: nil, number: number, trainNumber: trainNumber, style: lineStyle(network: network, product: product, label: label), attr: [.circleAnticlockwise], message: nil)
        } else if product == .bus && label == "S41" {
            return Line(id: nil, network: network, product: product, label: label, name: nil, number: number, trainNumber: trainNumber, style: lineStyle(network: network, product: product, label: label), attr: [.serviceReplacement, .circleClockwise], message: nil)
        } else if product == .bus && label == "S42" {
            return Line(id: nil, network: network, product: product, label: label, name: nil, number: number, trainNumber: trainNumber, style: lineStyle(network: network, product: product, label: label), attr: [.serviceReplacement, .circleAnticlockwise], message: nil)
        } else if product == .bus && label == "TXL" {
            return Line(id: nil, network: network, product: product, label: label, name: nil, number: number, trainNumber: trainNumber, style: lineStyle(network: network, product: product, label: label), attr: [.lineAirport], message: nil)
        } else if product == .suburbanTrain && label == "S9" {
            return Line(id: nil, network: network, product: product, label: label, name: nil, number: number, trainNumber: trainNumber, style: lineStyle(network: network, product: product, label: label), attr: [.lineAirport], message: nil)
        } else if product == .suburbanTrain && label == "S45" {
            return Line(id: nil, network: network, product: product, label: label, name: nil, number: number, trainNumber: trainNumber, style: lineStyle(network: network, product: product, label: label), attr: [.lineAirport], message: nil)
        } else {
            return super.newLine(network: network, product: product, name: name, shortName: shortName, number: number, trainNumber: trainNumber)
        }
    }
    
    override func parseJsonTripFare(fareSetName: String, fareSetDescription: String, name: String, currency: String, price: Float) -> Fare? {
        if !fareSetName.hasPrefix("Berlin Tarifgebiet ") || !fareSetName.hasSuffix(" Einzelfahrausweis") {
            return nil
        }
        let fareSetName = "Berlin \(String(fareSetName[fareSetName.index(fareSetName.startIndex, offsetBy: 19)..<fareSetName.index(fareSetName.endIndex, offsetBy: -19)]))"

        if name == "Regeltarif" {
            return Fare(network: fareSetName, type: .adult, currency: currency, fare: price, unitsName: name, units: nil)
        } else if name == "Ermäßigungstarif" {
            return Fare(network: fareSetName, type: .child, currency: currency, fare: price, unitsName: name, units: nil)
        } else if name == "Fahrrad" {
            return Fare(network: fareSetName, type: .bike, currency: currency, fare: price, unitsName: name, units: nil)
        } else {
            return nil
        }
    }
    
}
