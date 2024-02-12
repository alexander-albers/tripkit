import Foundation

public class AbstractHafasProvider: AbstractNetworkProvider {
 
    var productsMap: [Product?]
    
    var requestUrlEncoding: String.Encoding = .utf8
    var clientType: String? = "ANDROID" // TODO: iPhone
    
    init(networkId: NetworkId, productsMap: [Product?]) {
        self.productsMap = productsMap
        super.init(networkId: networkId)
    }
    
    func productsString(products: [Product]) -> String {
        return productsMap.map { $0 != nil && products.contains($0!) ? "1" : "0" }.joined(separator: "")
    }
    
    func allProductsString() -> String {
        return String(repeating: "1", count: productsMap.count)
    }
    
    func allProductsInt() -> Int {
        return (1 << productsMap.count) - 1
    }
    
    func intToProduct(productInt: Int) throws -> Product? {
        let allProductsInt = (1 << productsMap.count) - 1
        if productInt >= allProductsInt {
            throw ParseError(reason: "product int \(productInt) may not be larger than all products int \(allProductsInt)")
        }
        var value = productInt
        var product: Product? = nil
        for i in (0..<productsMap.count).reversed() {
            let v = 1 << i
            if value >= v {
                let p = productsMap[i]
                if (product == .onDemand && p == .bus) || (product == .bus && p == .onDemand) {
                    product = .onDemand
                } else if let product = product, product != p {
                    throw ParseError(reason: "ambiguous product \(product)-\(String(describing: p))")
                } else {
                    product = p
                }
                value -= v
            }
        }
        return product
    }
    
    func products(from int: Int) -> [Product] {
        var int = int
        
        var result: [Product] = []
        for i in (0..<productsMap.count).reversed() {
            let v = 1 << i
            if int >= v {
                if let product = productsMap[i] {
                    result.append(product)
                }
                int -= v
            }
        }
        return result
    }
    
    func product(from int: Int) -> Product? {
        return products(from: int).first
    }
    
    var P_SPLIT_NAME_FIRST_COMMA: NSRegularExpression { return try! NSRegularExpression(pattern: "^(?:([^,]*), (?!$))?([^,]*)(?:, )?$") }
    var P_SPLIT_NAME_LAST_COMMA: NSRegularExpression { return try! NSRegularExpression(pattern: "^(.*), ([^,]*)$") }
    var P_SPLIT_NAME_FIRST_SPACE: NSRegularExpression { return try! NSRegularExpression(pattern: "^([^ ]*) (.*)$") }
    var P_SPLIT_NAME_PAREN: NSRegularExpression { return try! NSRegularExpression(pattern: "^(.*) \\((.{3,}?)\\)$") }
    
    /**
     Splits the station name into place and station name.
     - Parameter stationName: the display name of the station.
     - Returns: the place and name of the station.
     */
    func split(stationName: String?) -> (place: String?, name: String?) {
        return (nil, stationName)
    }
    
    /**
     Splits the address into place and name.
     - Parameter address: the display name of the address.
     - Returns: the place and name of the address.
     */
    func split(address: String?) -> (place: String?, name: String?) {
        return (nil, address)
    }
    
    /**
     Splits the point of interest into place and name.
     - Parameter poi: the display name of the point of interest.
     - Returns: the place and name of the point of interest.
     */
    func split(poi: String?) -> (place: String?, name: String?) {
        return (nil, poi)
    }
    
    var P_POSITION_PLATFORM: NSRegularExpression { return try! NSRegularExpression(pattern: "^(?:Gleis|Gl\\.)\\s*(.*)\\s*$", options: .caseInsensitive) }
    
    func normalize(position: String?) -> String? {
        guard let position = position, !position.isEmpty else { return nil }
        if position == "null" { return nil }
        if let match = P_POSITION_PLATFORM.firstMatch(in: position, options: [], range: NSMakeRange(0, position.count)) {
            let substring = (position as NSString).substring(with: match.range(at: 1))
            return substring.emptyToNil
        }
        return super.parsePosition(position: position)
    }

    func queryTripsBinaryParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        builder.addParameter(key: "start", value: "Suchen")
        builder.addParameter(key: "REQ0JourneyStopsS0ID", value: locationId(location: from))
        builder.addParameter(key: "REQ0JourneyStopsZ0ID", value: locationId(location: to))
        if let via = via {
            builder.addParameter(key: "REQ0JourneyStops1.0A", value: locationType(location: via))
            if let id = via.id, via.type == .station {
                builder.addParameter(key: "REQ0JourneyStops1.0L", value: id)
            } else if let coord = via.coord {
                builder.addParameter(key: "REQ0JourneyStops1.0X", value: coord.lon)
                builder.addParameter(key: "REQ0JourneyStops1.0Y", value: coord.lat)
                if via.name == nil {
                    builder.addParameter(key: "REQ0JourneyStops1.0O", value: String(format: "%.6f, %.6f", Double(coord.lon) / 1E6, Double(coord.lat) / 1E6))
                }
            } else if let name = via.name {
                builder.addParameter(key: "REQ0JourneyStops1.0G", value: name + (via.type != .any ? "!" : ""))
            }
        }
        
        builder.addParameter(key: "REQ0HafasSearchForw", value: departure ? 1 : 0)
        dateTimeParameters(builder: builder, date: date, dateParamName: "REQ0JourneyDate", timeParamName: "REQ0JourneyTime")
        
        let productsStr: String
        if let products = tripOptions.products {
            productsStr = productsString(products: products)
        } else {
            productsStr = allProductsString()
        }
        builder.addParameter(key: "REQ0JourneyProduct_prod_list_1", value: productsStr)
        
        if let accessibility = tripOptions.accessibility, accessibility != .neutral {
            if accessibility == .limited {
                builder.addParameter(key: "REQ0AddParamBaimprofile", value: 1)
            } else if accessibility == .barrierFree {
                builder.addParameter(key: "REQ0AddParamBaimprofile", value: 0)
            }
            
        } else if let options = tripOptions.options, options.contains(.bike) {
            builder.addParameter(key: "REQ0JourneyProduct_opt3", value: 1)
        }
        if let minChangeTime = tripOptions.minChangeTime {
            builder.addParameter(key: "REQ0HafasChangeTime", value: "\(minChangeTime):\(minChangeTime / 5)")
        }
        builder.addParameter(key: "h2g-direct", value: 11)
        if let clientType = clientType {
            builder.addParameter(key: "clientType", value: clientType)
        }
    }
    
    func xmlStationBoardParameters(builder: UrlBuilder, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, styleSheet: String?) {
        builder.addParameter(key: "productsFilter", value: allProductsString())
        builder.addParameter(key: "boardType", value: departures ? "dep" : "arr")
        builder.addParameter(key: "disableEquivs", value: equivs ? 0 : 1)
        builder.addParameter(key: "maxJourneys", value: maxDepartures > 0 ? maxDepartures : 100)
        builder.addParameter(key: "input", value: normalize(stationId: stationId))
        dateTimeParameters(builder: builder, date: time ?? Date(), dateParamName: "date", timeParamName: "time")
        if let clientType = clientType {
            builder.addParameter(key: "clientType", value: clientType)
        }
        if let styleSheet = styleSheet {
            builder.addParameter(key: "L", value: styleSheet)
        }
        builder.addParameter(key: "hcount", value: 0) // prevents showing old departures
        builder.addParameter(key: "start", value: "yes")
    }
    
    func dateTimeParameters(builder: UrlBuilder, date: Date, dateParamName: String, timeParamName: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.day, .month, .year, .hour, .minute], from: date)
        builder.addParameter(key: dateParamName, value: String(format: "%02d.%02d.%02d", components.day!, components.month!, components.year! - 2000))
        builder.addParameter(key: timeParamName, value: String(format: "%02d:%02d", components.hour!, components.minute!))
    }
    
    func locationId(location: Location) -> String {
        var result = "A=\(locationType(location: location))"
        if location.type == .station && location.id != nil {
            result += "@L=\(normalize(stationId: location.id) ?? "")"
        } else if let coord = location.coord {
            result += "@X=\(coord.lon)"
            result += "@Y=\(coord.lat)"
            result += "@O=\(location.name ?? String(format: "%.6f, %.6f", Double(coord.lon) / 1E6, Double(coord.lat) / 1E6))"
        } else if let name = location.name {
            result += "@G=\(name)"
            if location.type != .any {
                result += "!"
            }
        }
        return result
    }
    
    func locationType(location: Location) -> Int {
        switch location.type {
        case .station:
            return 1
        case .poi:
            return 4
        case .coord:
            return 16
        case .address:
            return location.hasLocation() ? 16 : 2
        case .any:
            return 255
        }
    }
    
    func encodeJson(dict: [String : Any]) -> String? {
        return encodeJson(dict: dict, requestUrlEncoding: requestUrlEncoding)
    }
    
}

