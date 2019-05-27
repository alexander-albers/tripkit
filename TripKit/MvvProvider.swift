import Foundation

public class MvvProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://efa.mvv-muenchen.de/ng/"
    static let DESKTOP_ENDPOINT = "http://efa.mvv-muenchen.de/index.html"
    
    public init() {
        super.init(networkId: .MVV, apiBase: MvvProvider.API_BASE, desktopTripEndpoint: MvvProvider.DESKTOP_ENDPOINT, desktopDeparturesEndpoint: MvvProvider.DESKTOP_ENDPOINT)
        
        includeRegionId = false
        styles = [
            "R": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#36397f"), foregroundColor: LineStyle.white),
            "B": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#005262"), foregroundColor: LineStyle.white),
            "BX": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#4e917a"), foregroundColor: LineStyle.white),
            
            "SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#16bae7"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#76b82a"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#951b81"), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#00975f"), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#943126"), foregroundColor: LineStyle.white),
            "SS8": LineStyle(shape: .circle, backgroundColor: LineStyle.black, foregroundColor: LineStyle.parseColor("#ffcc00"), borderColor: LineStyle.gray),
            "SS18": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#16bae7"), backgroundColor2: LineStyle.parseColor("#f0aa00"), foregroundColor: LineStyle.white, borderColor: 0),
            "SS20": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#ea516d"), foregroundColor: LineStyle.white),
            
            "T12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#96368b"), foregroundColor: LineStyle.white),
            "T15": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#f1919c"), borderColor: LineStyle.parseColor("#f1919c")),
            "T16": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0065ae"), foregroundColor: LineStyle.white),
            "T17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8b563e"), foregroundColor: LineStyle.white),
            "T18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#13a538"), foregroundColor: LineStyle.white),
            "T19": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "T20": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#16bae7"), foregroundColor: LineStyle.white),
            "T21": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#16bae7"), borderColor: LineStyle.parseColor("#16bae7")),
            "T22": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#16bae7"), borderColor: LineStyle.parseColor("#16bae7")),
            "T23": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#bccf00"), foregroundColor: LineStyle.white),
            "T25": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f1919c"), foregroundColor: LineStyle.white),
            "T27": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7a600"), foregroundColor: LineStyle.white),
            "T28": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#00a984"), borderColor: LineStyle.parseColor("#00a984")),
            "T38": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1fa22e"), backgroundColor2: LineStyle.parseColor("#23bae2"), foregroundColor: LineStyle.white, borderColor: 0),
            "TN17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#999999"), foregroundColor: LineStyle.parseColor("#ffff00")),
            "TN19": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#999999"), foregroundColor: LineStyle.parseColor("#ffff00")),
            "TN20": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#999999"), foregroundColor: LineStyle.parseColor("#ffff00")),
            "TN27": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#999999"), foregroundColor: LineStyle.parseColor("#ffff00")),
            
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#52822f"), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c20831"), foregroundColor: LineStyle.white),
            "UU2E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c20831"), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ec6726"), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00a984"), foregroundColor: LineStyle.white),
            "UU5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#bc7a00"), foregroundColor: LineStyle.white),
            "UU6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0065ae"), foregroundColor: LineStyle.white),
            "UU7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#52822f"), backgroundColor2: LineStyle.parseColor("#c20831"), foregroundColor: LineStyle.white, borderColor: 0),
            "UU8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c20831"), backgroundColor2: LineStyle.parseColor("#ec6726"), foregroundColor: LineStyle.white, borderColor: 0)
        ]
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?, desktop: Bool) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options, desktop: desktop)
        if desktop {
            builder.setAnchorHash(anchorHash: "trip@enquiry")
        }
    }
    
    override func queryDeparturesParameters(builder: UrlBuilder, stationId: String, time: Date?, maxDepartures: Int, equivs: Bool, desktop: Bool) {
        super.queryDeparturesParameters(builder: builder, stationId: stationId, time: time, maxDepartures: maxDepartures, equivs: equivs, desktop: desktop)
        if desktop {
            builder.setAnchorHash(anchorHash: "departures@enquiry")
        }
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if trainName == "Mittelrheinbahn (trans regio)" {
                return Line(id: id, network: network, product: .regionalTrain, label: "MiRhBa")
            } else if longName == "Süd-Thüringen-Bahn" {
                return Line(id: id, network: network, product: .regionalTrain, label: "STB")
            } else if longName == "agilis" {
                return Line(id: id, network: network, product: .regionalTrain, label: "agilis")
            } else if trainName == "SBB" {
                return Line(id: id, network: network, product: .regionalTrain, label: "SBB")
            } else if trainNum == "A" {
                return Line(id: id, network: network, product: .suburbanTrain, label: "A")
            } else if trainName == "DB AG" {
                return Line(id: id, network: network, product: nil, label: symbol)
            }
        } else if mot == "1" {
            if symbol == "S" && name == "Pendelverkehr" {
                return Line(id: id, network: network, product: .suburbanTrain, label: "S⇆")
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
    let P_POSITION2 = try! NSRegularExpression(pattern: "(Fern|Regio|S-Bahn|U-Bahn|U\\d(?:/U\\d)*)\\s+(.*)", options: .caseInsensitive)
    
    override func parsePosition(position: String?) -> String? {
        guard let position = position else { return nil }
        if let match = position.match(pattern: P_POSITION2), let t = match[0]?[0], let p = super.parsePosition(position: match[1]) {
            if t == "S" || t == "U" {
                return p + "(" + t + ")"
            } else {
                return p
            }
        } else {
            return super.parsePosition(position: position)
        }
    }
    
}
