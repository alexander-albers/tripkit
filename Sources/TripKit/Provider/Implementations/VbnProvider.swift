import Foundation

/// Verkehrsverbund Bremen/Niedersachsen (DE)
public class VbnProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplaner.vbn.de/gate"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .regionalTrain, .regionalTrain, .suburbanTrain, .bus, .ferry, .subway, .tram, .onDemand]
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .VBN, apiBase: VbnProvider.API_BASE, productsMap: VbnProvider.PRODUCTS_MAP)
        self.mgateEndpoint = VbnProvider.API_BASE
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "VBN", "type": "WEB", "name": "webapp"]
        
        styles = [
            // Bremen (BSAG)
            "Bremer Straßenbahn AG|T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#129640"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|T1S": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#129640")),
            "Bremer Straßenbahn AG|T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#115CA8"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#2A9AD6"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#E30C15"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|T4S": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#E30C15")),
            "Bremer Straßenbahn AG|T5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00AAB8"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|T5S": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#00AAB8")),
            "Bremer Straßenbahn AG|T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|T8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#98C21E"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|T10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#16268F"), foregroundColor: LineStyle.white),
            
            "Bremer Straßenbahn AG|B20": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#95C11F"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B21": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009FE3"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B22": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#A69DCD"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B24": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#951B81"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B25": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B26": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#E30613"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B27": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#E30613"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B28": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B29": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#95C11F"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B31": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#95C11F"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B33": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B34": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B37": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#951B81"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B38": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B39": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B40": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#E30613"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B41": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#E30613"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B41S": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#E30613")),
            "Bremer Straßenbahn AG|B42": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B44": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#EF7D00"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B51": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B52": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#95C11F"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B53": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B55": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B57": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#EF7D00"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B58": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#EF7D00"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B61": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#95C11F"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B62": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B63": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B63S": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#FFCC00")),
            "Bremer Straßenbahn AG|B65": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#A8D3AF"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B66": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#A8D3AF"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B77": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#808080"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B80": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#A8D3AF"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B81": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B82": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#EF7D00"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B83": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B87": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B90": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#312783"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B91": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009FE3"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B92": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009FE3"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B93": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|B94": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#E30613"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B95": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#EF7D00"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B96": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#951B81"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B97": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#A6DCDD"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|B98": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            
            // Bremen Nachtverkehr
            "Bremer Straßenbahn AG|TN1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|TN3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#FB3099"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|TN4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#E30613"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|BN5": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#EF7D00"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|BN6": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009FE3"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|BN7": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#95C11F"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|BN9": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#FFCC00"), foregroundColor: LineStyle.black),
            "Bremer Straßenbahn AG|TN10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0075BF"), foregroundColor: LineStyle.white),
            "Bremer Straßenbahn AG|BN94": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#A69DCD"), foregroundColor: LineStyle.white),
            
            // NordWestBahn - Regio-S-Bahn
            "NordWestBahn|SRS1": LineStyle(backgroundColor: LineStyle.parseColor("#214889"), foregroundColor: LineStyle.white),
            "NordWestBahn|SRS2": LineStyle(backgroundColor: LineStyle.parseColor("#DB8F2D"), foregroundColor: LineStyle.white),
            "NordWestBahn|SRS3": LineStyle(backgroundColor: LineStyle.parseColor("#A5C242"), foregroundColor: LineStyle.white),
            "NordWestBahn|SRS30": LineStyle(backgroundColor: LineStyle.parseColor("#51AF3D"), foregroundColor: LineStyle.white),
            "NordWestBahn|SRS4": LineStyle(backgroundColor: LineStyle.parseColor("#C4031E"), foregroundColor: LineStyle.white),
            "NordWestBahn|SRS6": LineStyle(backgroundColor: LineStyle.parseColor("#889DB7"), foregroundColor: LineStyle.white),
            
            // Rostock
            "DB Regio AG|SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009037"), foregroundColor: LineStyle.white),
            "DB Regio AG|SS2": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009037"), foregroundColor: LineStyle.white),
            "DB Regio AG|SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009037"), foregroundColor: LineStyle.white),
            
            "Rostocker Straßenbahn AG|T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#712090"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f47216"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#870e12"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d136a3"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|T5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fab20b"), foregroundColor: LineStyle.white),
            
            "Rostocker Straßenbahn AG|B15": LineStyle(backgroundColor: LineStyle.parseColor("#008dc6"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B16": LineStyle(backgroundColor: LineStyle.parseColor("#1d3c85"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B17": LineStyle(backgroundColor: LineStyle.parseColor("#5784cc"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B18": LineStyle(backgroundColor: LineStyle.parseColor("#0887c9"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B19": LineStyle(backgroundColor: LineStyle.parseColor("#166ab8"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|PRFT 19A": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#166ab8")),
            "Rostocker Straßenbahn AG|PRFT 20A": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#1959a6")),
            "Rostocker Straßenbahn AG|B22": LineStyle(backgroundColor: LineStyle.parseColor("#3871c1"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B23": LineStyle(backgroundColor: LineStyle.parseColor("#173e7d"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B25": LineStyle(backgroundColor: LineStyle.parseColor("#0994dc"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B26": LineStyle(backgroundColor: LineStyle.parseColor("#0994dc"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B27": LineStyle(backgroundColor: LineStyle.parseColor("#6e87cd"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B28": LineStyle(backgroundColor: LineStyle.parseColor("#4fc6f4"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|PRFT 30A": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#1082ce")),
            "Rostocker Straßenbahn AG|B31": LineStyle(backgroundColor: LineStyle.parseColor("#3a9fdf"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B34": LineStyle(backgroundColor: LineStyle.parseColor("#1c63b7"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B35": LineStyle(backgroundColor: LineStyle.parseColor("#1969bc"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|PRFT 35A": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#1969bc")),
            "Rostocker Straßenbahn AG|B36": LineStyle(backgroundColor: LineStyle.parseColor("#1c63b7"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B37": LineStyle(backgroundColor: LineStyle.parseColor("#36aee8"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B38": LineStyle(backgroundColor: LineStyle.parseColor("#6e87cd"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B39": LineStyle(backgroundColor: LineStyle.parseColor("#173e7d"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|B45": LineStyle(backgroundColor: LineStyle.parseColor("#66cef5"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|PRFT 45A": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#66cef5")),
            "Rostocker Straßenbahn AG|B49": LineStyle(backgroundColor: LineStyle.parseColor("#202267"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|BF1": LineStyle(backgroundColor: LineStyle.parseColor("#231f20"), foregroundColor: LineStyle.white),
            "Rostocker Straßenbahn AG|PRFT F1A": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#231f20")),
            "Rostocker Straßenbahn AG|BF2": LineStyle(backgroundColor: LineStyle.parseColor("#656263"), foregroundColor: LineStyle.white),
            
            "rebus Regionalbus Rostock GmbH|B101": LineStyle(backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B102": LineStyle(backgroundColor: LineStyle.parseColor("#2699d6"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B103": LineStyle(backgroundColor: LineStyle.parseColor("#d18f00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B104": LineStyle(backgroundColor: LineStyle.parseColor("#006f9e"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B105": LineStyle(backgroundColor: LineStyle.parseColor("#c2a712"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B106": LineStyle(backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B107": LineStyle(backgroundColor: LineStyle.parseColor("#a62341"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B108": LineStyle(backgroundColor: LineStyle.parseColor("#009fe3"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B109": LineStyle(backgroundColor: LineStyle.parseColor("#aa7fa6"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B110": LineStyle(backgroundColor: LineStyle.parseColor("#95c11f"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B111": LineStyle(backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B112": LineStyle(backgroundColor: LineStyle.parseColor("#e50069"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B113": LineStyle(backgroundColor: LineStyle.parseColor("#935b00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B114": LineStyle(backgroundColor: LineStyle.parseColor("#935b00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B115": LineStyle(backgroundColor: LineStyle.parseColor("#74b959"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B116": LineStyle(backgroundColor: LineStyle.parseColor("#0085ac"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B118": LineStyle(backgroundColor: LineStyle.parseColor("#f9b000"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B119": LineStyle(backgroundColor: LineStyle.parseColor("#055da9"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B120": LineStyle(backgroundColor: LineStyle.parseColor("#74b959"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B121": LineStyle(backgroundColor: LineStyle.parseColor("#e63323"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B122": LineStyle(backgroundColor: LineStyle.parseColor("#009870"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B123": LineStyle(backgroundColor: LineStyle.parseColor("#f39200"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B124": LineStyle(backgroundColor: LineStyle.parseColor("#9dc41a"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B125": LineStyle(backgroundColor: LineStyle.parseColor("#935b00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B127": LineStyle(backgroundColor: LineStyle.parseColor("#079897"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B128": LineStyle(backgroundColor: LineStyle.parseColor("#7263a9"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B129": LineStyle(backgroundColor: LineStyle.parseColor("#e6007e"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B131": LineStyle(backgroundColor: LineStyle.parseColor("#0075bf"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B132": LineStyle(backgroundColor: LineStyle.parseColor("#ef7d00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B134": LineStyle(backgroundColor: LineStyle.parseColor("#008e5c"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B135": LineStyle(backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B136": LineStyle(backgroundColor: LineStyle.parseColor("#aa7fa6"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B137": LineStyle(backgroundColor: LineStyle.parseColor("#ef7c00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B138": LineStyle(backgroundColor: LineStyle.parseColor("#e30513"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B139": LineStyle(backgroundColor: LineStyle.parseColor("#f8ac00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B140": LineStyle(backgroundColor: LineStyle.parseColor("#c2a712"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B200": LineStyle(backgroundColor: LineStyle.parseColor("#e6007e"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B201": LineStyle(backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B203": LineStyle(backgroundColor: LineStyle.parseColor("#f59c00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B204": LineStyle(backgroundColor: LineStyle.parseColor("#b3cf3b"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B205": LineStyle(backgroundColor: LineStyle.parseColor("#dd6ca7"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B208": LineStyle(backgroundColor: LineStyle.parseColor("#9dc41a"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B210": LineStyle(backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B211": LineStyle(backgroundColor: LineStyle.parseColor("#95c11f"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B213": LineStyle(backgroundColor: LineStyle.parseColor("#a877b2"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B215": LineStyle(backgroundColor: LineStyle.parseColor("#009fe3"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B216": LineStyle(backgroundColor: LineStyle.parseColor("#935b00"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B220": LineStyle(backgroundColor: LineStyle.parseColor("#0090d7"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B221": LineStyle(backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B222": LineStyle(backgroundColor: LineStyle.parseColor("#f088b6"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B223": LineStyle(backgroundColor: LineStyle.parseColor("#f9b000"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B224": LineStyle(backgroundColor: LineStyle.parseColor("#004f9f"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B225": LineStyle(backgroundColor: LineStyle.parseColor("#7263a9"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B230": LineStyle(backgroundColor: LineStyle.parseColor("#005ca9"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B231": LineStyle(backgroundColor: LineStyle.parseColor("#00853e"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B232": LineStyle(backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B233": LineStyle(backgroundColor: LineStyle.parseColor("#123274"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B235": LineStyle(backgroundColor: LineStyle.parseColor("#ba0066"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B240": LineStyle(backgroundColor: LineStyle.parseColor("#7263a9"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B241": LineStyle(backgroundColor: LineStyle.parseColor("#ea5297"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B244": LineStyle(backgroundColor: LineStyle.parseColor("#f7ab59"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B245": LineStyle(backgroundColor: LineStyle.parseColor("#76b82a"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B246": LineStyle(backgroundColor: LineStyle.parseColor("#f39a8b"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B247": LineStyle(backgroundColor: LineStyle.parseColor("#009fe3"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B250": LineStyle(backgroundColor: LineStyle.parseColor("#009741"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B251": LineStyle(backgroundColor: LineStyle.parseColor("#033572"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B252": LineStyle(backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B260": LineStyle(backgroundColor: LineStyle.parseColor("#e6007e"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B270": LineStyle(backgroundColor: LineStyle.parseColor("#fbbe5e"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B271": LineStyle(backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B272": LineStyle(backgroundColor: LineStyle.parseColor("#009fe3"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B273": LineStyle(backgroundColor: LineStyle.parseColor("#004899"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B280": LineStyle(backgroundColor: LineStyle.parseColor("#e41b18"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B281": LineStyle(backgroundColor: LineStyle.parseColor("#f9b000"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B282": LineStyle(backgroundColor: LineStyle.parseColor("#005ca9"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B283": LineStyle(backgroundColor: LineStyle.parseColor("#ec619f"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B284": LineStyle(backgroundColor: LineStyle.parseColor("#951b81"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B285": LineStyle(backgroundColor: LineStyle.parseColor("#a42522"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B286": LineStyle(backgroundColor: LineStyle.parseColor("#e6007e"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B290": LineStyle(backgroundColor: LineStyle.parseColor("#312783"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B291": LineStyle(backgroundColor: LineStyle.parseColor("#a71680"), foregroundColor: LineStyle.white),
            "rebus Regionalbus Rostock GmbH|B292": LineStyle(backgroundColor: LineStyle.parseColor("#cabe46"), foregroundColor: LineStyle.white),
            
            "Rostocker Fähren|F": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#17a4da"), foregroundColor: LineStyle.white)
        ]
    }
    
    static let PLACES = ["Bremen", "Bremerhaven", "Oldenburg(Oldb)", "Osnabrück", "Göttingen", "Rostock", "Warnemünde"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in ShProvider.PLACES {
            if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + "-") {
                return (place, stationName.substring(from: place.count + 1))
            }
        }
        return super.split(stationName: stationName)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let address = address else { return super.split(address: nil) }
        if let m = address.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(address: address)
    }
    
    override func newLine(id: String?, network: String?, product: Product?, name: String?, shortName: String?, number: String?, vehicleNumber: String?) -> Line {
        let line = super.newLine(id: id, network: network, product: product, name: name, shortName: shortName, number: number, vehicleNumber: vehicleNumber)
        
        if line.product == .bus && "57" == line.label {
            return Line(id: id, network: line.network, product: line.product, label: line.label, name: line.name, style: line.style, attr: [.serviceReplacement, .circleClockwise], message: line.message)
        } else if line.product == .bus && "82" == line.label {
            return Line(id: id, network: line.network, product: line.product, label: line.label, name: line.name, style: line.style, attr: [.serviceReplacement, .circleClockwise], message: line.message)
        } else if line.product == .bus && "58" == line.label {
            return Line(id: id, network: line.network, product: line.product, label: line.label, name: line.name, style: line.style, attr: [.serviceReplacement, .circleAnticlockwise], message: line.message)
        } else {
            return line
        }
    }
    
}
