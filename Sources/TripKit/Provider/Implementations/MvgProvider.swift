import Foundation

/// Westfalenfahrplan/MVG/moBiel (DE)
public class MvgProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://westfalenfahrplan.de/std3/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .MVG, apiBase: MvgProvider.API_BASE)
        
        styles = [
            // Münster
            "vgm|B1": LineStyle(backgroundColor: LineStyle.parseColor("#b9cf00"), foregroundColor: LineStyle.black),
            "vgm|B2": LineStyle(backgroundColor: LineStyle.parseColor("#0299d8"), foregroundColor: LineStyle.white),
            "vgm|B4": LineStyle(backgroundColor: LineStyle.parseColor("#92c56e"), foregroundColor: LineStyle.white),
            "vgm|B5": LineStyle(backgroundColor: LineStyle.parseColor("#f9d901"), foregroundColor: LineStyle.black),
            "vgm|B6": LineStyle(backgroundColor: LineStyle.parseColor("#762282"), foregroundColor: LineStyle.white),
            "vgm|B7": LineStyle(backgroundColor: LineStyle.parseColor("#00748e"), foregroundColor: LineStyle.white),
            "vgm|B8": LineStyle(backgroundColor: LineStyle.parseColor("#ac6eac"), foregroundColor: LineStyle.white),
            "vgm|B9": LineStyle(backgroundColor: LineStyle.parseColor("#aa7823"), foregroundColor: LineStyle.white),
            "vgm|B10": LineStyle(backgroundColor: LineStyle.parseColor("#e30414"), foregroundColor: LineStyle.white),
            "vgm|B11": LineStyle(backgroundColor: LineStyle.parseColor("#f07d00"), foregroundColor: LineStyle.white),
            "vgm|B12": LineStyle(backgroundColor: LineStyle.parseColor("#4571af"), foregroundColor: LineStyle.white),
            "vgm|B13": LineStyle(backgroundColor: LineStyle.parseColor("#4e9635"), foregroundColor: LineStyle.white),
            "vgm|B14": LineStyle(backgroundColor: LineStyle.parseColor("#83d0f5"), foregroundColor: LineStyle.black),
            "vgm|B15": LineStyle(backgroundColor: LineStyle.parseColor("#03753c"), foregroundColor: LineStyle.white),
            "vgm|B16": LineStyle(backgroundColor: LineStyle.parseColor("#fac17d"), foregroundColor: LineStyle.black),
            "vgm|B17": LineStyle(backgroundColor: LineStyle.parseColor("#eb5a0d"), foregroundColor: LineStyle.white),
            "vgm|B18": LineStyle(backgroundColor: LineStyle.parseColor("#008bd2"), foregroundColor: LineStyle.white),
            "vgm|B19": LineStyle(backgroundColor: LineStyle.parseColor("#5c79bb"), foregroundColor: LineStyle.white),
            "vgm|B20": LineStyle(backgroundColor: LineStyle.parseColor("#9b358c"), foregroundColor: LineStyle.white),
            "vgm|B22": LineStyle(backgroundColor: LineStyle.parseColor("#9c1107"), foregroundColor: LineStyle.white),
            "vgm|BN80": LineStyle(backgroundColor: LineStyle.black, foregroundColor: LineStyle.white),
            "vgm|BN81": LineStyle(backgroundColor: LineStyle.black, foregroundColor: LineStyle.white),
            "vgm|BN82": LineStyle(backgroundColor: LineStyle.black, foregroundColor: LineStyle.white),
            "vgm|BN83": LineStyle(backgroundColor: LineStyle.black, foregroundColor: LineStyle.white),
            "vgm|BN84": LineStyle(backgroundColor: LineStyle.black, foregroundColor: LineStyle.white),
            "vgm|BN85": LineStyle(backgroundColor: LineStyle.black, foregroundColor: LineStyle.white),
            
            // Bielefeld
            "owl|T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#009ee0"), foregroundColor: LineStyle.white),
            "owl|T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#009037"), foregroundColor: LineStyle.white),
            "owl|T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffec00"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e2011a"), foregroundColor: LineStyle.white),
            "owl|B21": LineStyle(backgroundColor: LineStyle.parseColor("#d75163"), foregroundColor: LineStyle.white),
            "owl|B22": LineStyle(backgroundColor: LineStyle.parseColor("#d75163"), foregroundColor: LineStyle.white),
            "owl|B131": LineStyle(backgroundColor: LineStyle.parseColor("#d75163"), foregroundColor: LineStyle.white),
            "owl|B142": LineStyle(backgroundColor: LineStyle.parseColor("#d75163"), foregroundColor: LineStyle.white),
            "owl|B24": LineStyle(backgroundColor: LineStyle.parseColor("#655a9f"), foregroundColor: LineStyle.white),
            "owl|B31": LineStyle(backgroundColor: LineStyle.parseColor("#655a9f"), foregroundColor: LineStyle.white),
            "owl|B46": LineStyle(backgroundColor: LineStyle.parseColor("#655a9f"), foregroundColor: LineStyle.white),
            "owl|B47": LineStyle(backgroundColor: LineStyle.parseColor("#655a9f"), foregroundColor: LineStyle.white),
            "owl|B25": LineStyle(backgroundColor: LineStyle.parseColor("#58aa27"), foregroundColor: LineStyle.black),
            "owl|B26": LineStyle(backgroundColor: LineStyle.parseColor("#58aa27"), foregroundColor: LineStyle.black),
            "owl|B32": LineStyle(backgroundColor: LineStyle.parseColor("#58aa27"), foregroundColor: LineStyle.black),
            "owl|B351": LineStyle(backgroundColor: LineStyle.parseColor("#58aa27"), foregroundColor: LineStyle.black),
            "owl|B27": LineStyle(backgroundColor: LineStyle.parseColor("#f29ec1"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B37": LineStyle(backgroundColor: LineStyle.parseColor("#f29ec1"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B29": LineStyle(backgroundColor: LineStyle.parseColor("#f39400"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B128": LineStyle(backgroundColor: LineStyle.parseColor("#f39400"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B30": LineStyle(backgroundColor: LineStyle.parseColor("#007dc4"), foregroundColor: LineStyle.white),
            "owl|B122": LineStyle(backgroundColor: LineStyle.parseColor("#007dc4"), foregroundColor: LineStyle.white),
            "owl|B123": LineStyle(backgroundColor: LineStyle.parseColor("#007dc4"), foregroundColor: LineStyle.white),
            "owl|B33": LineStyle(backgroundColor: LineStyle.parseColor("#fabd00"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B56": LineStyle(backgroundColor: LineStyle.parseColor("#fabd00"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B34": LineStyle(backgroundColor: LineStyle.parseColor("#ffe501"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B36": LineStyle(backgroundColor: LineStyle.parseColor("#a53723"), foregroundColor: LineStyle.white),
            "owl|B55": LineStyle(backgroundColor: LineStyle.parseColor("#a53723"), foregroundColor: LineStyle.white),
            "owl|B28": LineStyle(backgroundColor: LineStyle.parseColor("#004178"), foregroundColor: LineStyle.white),
            "owl|B38": LineStyle(backgroundColor: LineStyle.parseColor("#004178"), foregroundColor: LineStyle.white),
            "owl|B138": LineStyle(backgroundColor: LineStyle.parseColor("#004178"), foregroundColor: LineStyle.white),
            "owl|B154": LineStyle(backgroundColor: LineStyle.parseColor("#004178"), foregroundColor: LineStyle.white),
            "owl|B39": LineStyle(backgroundColor: LineStyle.parseColor("#004e2d"), foregroundColor: LineStyle.white),
            "owl|B87": LineStyle(backgroundColor: LineStyle.parseColor("#004e2d"), foregroundColor: LineStyle.white),
            "owl|B350": LineStyle(backgroundColor: LineStyle.parseColor("#004e2d"), foregroundColor: LineStyle.white),
            "owl|B48": LineStyle(backgroundColor: LineStyle.parseColor("#39a9dc"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B61": LineStyle(backgroundColor: LineStyle.parseColor("#39a9dc"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B62": LineStyle(backgroundColor: LineStyle.parseColor("#39a9dc"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B155": LineStyle(backgroundColor: LineStyle.parseColor("#39a9dc"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B51": LineStyle(backgroundColor: LineStyle.parseColor("#ad8dbc"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B94": LineStyle(backgroundColor: LineStyle.parseColor("#ad8dbc"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B369": LineStyle(backgroundColor: LineStyle.parseColor("#ad8dbc"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B54": LineStyle(backgroundColor: LineStyle.parseColor("#e2007a"), foregroundColor: LineStyle.white),
            "owl|B135": LineStyle(backgroundColor: LineStyle.parseColor("#e2007a"), foregroundColor: LineStyle.white),
            "owl|B349": LineStyle(backgroundColor: LineStyle.parseColor("#e2007a"), foregroundColor: LineStyle.white),
            "owl|B57": LineStyle(backgroundColor: LineStyle.parseColor("#009036"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B58": LineStyle(backgroundColor: LineStyle.parseColor("#009036"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B95": LineStyle(backgroundColor: LineStyle.parseColor("#009036"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B59": LineStyle(backgroundColor: LineStyle.parseColor("#e2011a"), foregroundColor: LineStyle.white),
            "owl|B80.2": LineStyle(backgroundColor: LineStyle.parseColor("#e2011a"), foregroundColor: LineStyle.white),
            "owl|B83": LineStyle(backgroundColor: LineStyle.parseColor("#e2011a"), foregroundColor: LineStyle.white),
            "owl|B352": LineStyle(backgroundColor: LineStyle.parseColor("#e2011a"), foregroundColor: LineStyle.white),
            "owl|B23": LineStyle(backgroundColor: LineStyle.parseColor("#e85a99"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B88": LineStyle(backgroundColor: LineStyle.parseColor("#e85a99"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B101": LineStyle(backgroundColor: LineStyle.parseColor("#e85a99"), foregroundColor: LineStyle.parseColor("#002650")),
            "owl|B121": LineStyle(backgroundColor: LineStyle.parseColor("#b09d1e"), foregroundColor: LineStyle.white),
            
            // Gütersloh
            "owl|B201": LineStyle(backgroundColor: LineStyle.parseColor("#833a76"), foregroundColor: LineStyle.white),
            "owl|B202": LineStyle(backgroundColor: LineStyle.parseColor("#db669b"), foregroundColor: LineStyle.white),
            "owl|B203": LineStyle(backgroundColor: LineStyle.parseColor("#8cab0e"), foregroundColor: LineStyle.white),
            "owl|B204": LineStyle(backgroundColor: LineStyle.parseColor("#ffcc01"), foregroundColor: LineStyle.black),
            "owl|B205": LineStyle(backgroundColor: LineStyle.parseColor("#004e77"), foregroundColor: LineStyle.white),
            "owl|B206": LineStyle(backgroundColor: LineStyle.parseColor("#007630"), foregroundColor: LineStyle.white),
            "owl|B207": LineStyle(backgroundColor: LineStyle.parseColor("#c59555"), foregroundColor: LineStyle.white),
            "owl|B208": LineStyle(backgroundColor: LineStyle.parseColor("#ef7c01"), foregroundColor: LineStyle.white),
            "owl|B209": LineStyle(backgroundColor: LineStyle.parseColor("#6cbe94"), foregroundColor: LineStyle.white),
            "owl|B210": LineStyle(backgroundColor: LineStyle.parseColor("#54b7e0"), foregroundColor: LineStyle.white),
            "owl|B211": LineStyle(backgroundColor: LineStyle.parseColor("#c10138"), foregroundColor: LineStyle.white),
            
            // Gütersloh Regionallinien
            "owl|B43": LineStyle(backgroundColor: LineStyle.parseColor("#918f79"), foregroundColor: LineStyle.white),
            "owl|B70": LineStyle(backgroundColor: LineStyle.parseColor("#e7400b"), foregroundColor: LineStyle.black),
            "owl|B71": LineStyle(backgroundColor: LineStyle.parseColor("#f69c00"), foregroundColor: LineStyle.white),
            "owl|B72": LineStyle(backgroundColor: LineStyle.parseColor("#018243"), foregroundColor: LineStyle.white),
            "owl|B73": LineStyle(backgroundColor: LineStyle.parseColor("#9d1780"), foregroundColor: LineStyle.white),
            "owl|B74": LineStyle(backgroundColor: LineStyle.parseColor("#019ee3"), foregroundColor: LineStyle.white),
            "owl|B76": LineStyle(backgroundColor: LineStyle.parseColor("#434f4f"), foregroundColor: LineStyle.white),
            "owl|B77": LineStyle(backgroundColor: LineStyle.parseColor("#84bc21"), foregroundColor: LineStyle.white),
            "owl|B78": LineStyle(backgroundColor: LineStyle.parseColor("#00a983"), foregroundColor: LineStyle.white),
            "owl|B79": LineStyle(backgroundColor: LineStyle.parseColor("#1e398f"), foregroundColor: LineStyle.white),
            "owl|B85": LineStyle(backgroundColor: LineStyle.parseColor("#e30118"), foregroundColor: LineStyle.white),
            "owl|B89": LineStyle(backgroundColor: LineStyle.parseColor("#b41b3d"), foregroundColor: LineStyle.white),
            "owl|B90": LineStyle(backgroundColor: LineStyle.parseColor("#7c7b39"), foregroundColor: LineStyle.white),
            "owl|B160": LineStyle(backgroundColor: LineStyle.parseColor("#8a2738"), foregroundColor: LineStyle.white),
            "owl|B190": LineStyle(backgroundColor: LineStyle.parseColor("#925a00"), foregroundColor: LineStyle.white),
            
            // Paderborn
            "vph|B1": LineStyle(backgroundColor: LineStyle.parseColor("#f9c623"), foregroundColor: LineStyle.white),
            "vph|B2": LineStyle(backgroundColor: LineStyle.parseColor("#009c7f"), foregroundColor: LineStyle.white),
            "vph|B3": LineStyle(backgroundColor: LineStyle.parseColor("#9d6098"), foregroundColor: LineStyle.white),
            "vph|B4": LineStyle(backgroundColor: LineStyle.parseColor("#975e34"), foregroundColor: LineStyle.white),
            "vph|B5": LineStyle(backgroundColor: LineStyle.parseColor("#870f34"), foregroundColor: LineStyle.white),
            "vph|B6": LineStyle(backgroundColor: LineStyle.parseColor("#70c8e6"), foregroundColor: LineStyle.white),
            "vph|B7": LineStyle(backgroundColor: LineStyle.parseColor("#d58730"), foregroundColor: LineStyle.white),
            "vph|B8": LineStyle(backgroundColor: LineStyle.parseColor("#83bf42"), foregroundColor: LineStyle.white),
            "vph|B9": LineStyle(backgroundColor: LineStyle.parseColor("#4d1a1c"), foregroundColor: LineStyle.white),
            "vph|B11": LineStyle(backgroundColor: LineStyle.parseColor("#d9222a"), foregroundColor: LineStyle.white),
            "vph|B28": LineStyle(backgroundColor: LineStyle.parseColor("#113063"), foregroundColor: LineStyle.white),
            "vph|B58": LineStyle(backgroundColor: LineStyle.parseColor("#7bc292"), foregroundColor: LineStyle.white),
            "vph|B68": LineStyle(backgroundColor: LineStyle.parseColor("#0089c4"), foregroundColor: LineStyle.white),
        ]
    }
    
    override func parsePosition(position: String?) -> String? {
        guard let position = position else { return super.parsePosition(position: nil) }
        if position.hasPrefix(" - ") {
            return super.parsePosition(position: position.substring(from: 3))
        } else {
            return super.parsePosition(position: position)
        }
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "5" {
            // Bielefeld Uni/Laborschule, Stadtbus
            if network == "owl" && (name ?? "").isEmpty && (longName == "Stadtbus" || trainName == "Stadtbus") {
                return Line(id: id, network: network, product: .bus, label: "LBS")
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }

}
