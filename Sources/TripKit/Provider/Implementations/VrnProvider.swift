import Foundation

/// Verkehrsverbund Rhein-Neckar (DE)
public class VrnProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://www.vrn.de/mngvrn/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .VRN, apiBase: VrnProvider.API_BASE)
        includeRegionId = false
        useStatelessTripContexts = true
        
        styles = [
            // Straßen- und Stadtbahn Mannheim-Ludwigshafen rnv
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f39b9a"), foregroundColor: LineStyle.white),
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b00346"), foregroundColor: LineStyle.white),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d6ad00"), foregroundColor: LineStyle.white),
            "T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "T4X": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "T4A": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "T5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00975f"), foregroundColor: LineStyle.white),
            "T5A": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00975f"), foregroundColor: LineStyle.white),
            "T5X": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00975f"), foregroundColor: LineStyle.white),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#956c29"), foregroundColor: LineStyle.white),
            "T6A": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#956c29"), foregroundColor: LineStyle.white),
            "T7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffcc00"), foregroundColor: LineStyle.black),
            "T8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e17600"), foregroundColor: LineStyle.white),
            "T9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e6007e"), foregroundColor: LineStyle.white),
            "T10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a71680"), foregroundColor: LineStyle.white),
            // "T15": LineStyle(shape: .RECT, backgroundColor: LineStyle.parseColor("#7c7c7b"), foregroundColor: LineStyle.WHITE),
            "TX": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#7c7c7b"), foregroundColor: LineStyle.white),
            
            // Busse Mannheim
            "B2": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#b00346"), foregroundColor: LineStyle.white),
            "B4": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "B5": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#00975f"), foregroundColor: LineStyle.black),
            "B7": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#ffcc00"), foregroundColor: LineStyle.black),
            "B40": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4e2583"), foregroundColor: LineStyle.white),
            "B41": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#82d0f5"), foregroundColor: LineStyle.white),
            "B42": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a1c3d6"), foregroundColor: LineStyle.white),
            "B43": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#589bd4"), foregroundColor: LineStyle.white),
            "B44": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009a93"), foregroundColor: LineStyle.white),
            "B45": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#0069b4"), foregroundColor: LineStyle.white),
            "B46": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a89bb1"), foregroundColor: LineStyle.white),
            "B47": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#82d0f5"), foregroundColor: LineStyle.white),
            "B48": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009fe3"), foregroundColor: LineStyle.white),
            "B49": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009640"), foregroundColor: LineStyle.white),
            "B50": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a1c3d6"), foregroundColor: LineStyle.white),
            "B51": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#0069b4"), foregroundColor: LineStyle.white),
            "B52": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a89bb1"), foregroundColor: LineStyle.white),
            "B53": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#10bbef"), foregroundColor: LineStyle.white),
            "B54": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#b2a0cd"), foregroundColor: LineStyle.white),
            "B55": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4e2583"), foregroundColor: LineStyle.white),
            "B56": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#10bbef"), foregroundColor: LineStyle.white),
            "B57": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#5bc5f2"), foregroundColor: LineStyle.white),
            "B57E": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#5bc5f2"), foregroundColor: LineStyle.white),
            "B58": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a1c3d6"), foregroundColor: LineStyle.white),
            "B59": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a89bb1"), foregroundColor: LineStyle.white),
            "B60": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4e2583"), foregroundColor: LineStyle.white),
            "B61": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4b96d2"), foregroundColor: LineStyle.white),
            "B62": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a89bb1"), foregroundColor: LineStyle.white),
            "B63": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a1c3d6"), foregroundColor: LineStyle.white),
            "B64": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#0091a6"), foregroundColor: LineStyle.white),
            
            // Stadtbus Ludwigshafen
            "B70": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4b96d2"), foregroundColor: LineStyle.white),
            "B71": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a89bb1"), foregroundColor: LineStyle.white),
            "B72": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#0069b4"), foregroundColor: LineStyle.white),
            "B73": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#8bc5bd"), foregroundColor: LineStyle.white),
            "B74": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#82d0f5"), foregroundColor: LineStyle.white),
            "B75": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#008f88"), foregroundColor: LineStyle.white),
            "B76": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4e2583"), foregroundColor: LineStyle.white),
            "B77": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#c290b8"), foregroundColor: LineStyle.white),
            "B78": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4b96d2"), foregroundColor: LineStyle.white),
            "B79E": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#993399"), foregroundColor: LineStyle.white),
            "B84": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#8d2176"), foregroundColor: LineStyle.white),
            "B85": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#0069b4"), foregroundColor: LineStyle.white),
            "B86": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#82d0f5"), foregroundColor: LineStyle.white),
            "B87": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#69598f"), foregroundColor: LineStyle.white),
            "B88": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#8bc5bd"), foregroundColor: LineStyle.white),
            
            // Nachtbus Ludwigshafen
            "B90": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#86bc25"), foregroundColor: LineStyle.white),
            // "B91": LineStyle(shape: .CIRCLE, backgroundColor: LineStyle.parseColor("#898F93"), foregroundColor: LineStyle.WHITE),
            "B94": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#83d0f5"), foregroundColor: LineStyle.white),
            "B96": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#c05d18"), foregroundColor: LineStyle.white),
            "B97": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#ffed00"), foregroundColor: LineStyle.black),
            // Nachtbus Ludwigshafen-Mannheim
            "B6": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#956c29"), foregroundColor: LineStyle.white),
            
            // Straßenbahn Heidelberg
            "T21": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e30613"), foregroundColor: LineStyle.white),
            "T22": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fdc300"), foregroundColor: LineStyle.black),
            "T23": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e48f00"), foregroundColor: LineStyle.white),
            "T24": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8d2176"), foregroundColor: LineStyle.white),
            "T26": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f39b9a"), foregroundColor: LineStyle.white),
            
            // Stadtbus Heidelberg rnv
            "B27": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4e2583"), foregroundColor: LineStyle.white),
            "B28": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#b2a0cd"), foregroundColor: LineStyle.white),
            "B29": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#10bbef"), foregroundColor: LineStyle.white),
            "B30": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#baabd4"), foregroundColor: LineStyle.white),
            "B31": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4b96d2"), foregroundColor: LineStyle.white),
            "B32": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a1c3d6"), foregroundColor: LineStyle.white),
            "B33": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#0069b4"), foregroundColor: LineStyle.white),
            "B34": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009fe3"), foregroundColor: LineStyle.white),
            "B35": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4e2583"), foregroundColor: LineStyle.white),
            "B36": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#b2a0cd"), foregroundColor: LineStyle.white),
            "B37": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#10bbef"), foregroundColor: LineStyle.white),
            "B38": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#0097b5"), foregroundColor: LineStyle.white),
            "B39": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#512985"), foregroundColor: LineStyle.white),
            
            // Moonliner Heidelberg
            "BM1": LineStyle(backgroundColor: LineStyle.parseColor("#FFCB06"), foregroundColor: LineStyle.parseColor("#0A3F88")),
            "BM2": LineStyle(backgroundColor: LineStyle.parseColor("#F9A75E"), foregroundColor: LineStyle.parseColor("#0A3F88")),
            "BM3": LineStyle(backgroundColor: LineStyle.parseColor("#FFCB06"), foregroundColor: LineStyle.parseColor("#0A3F88")),
            "BM4": LineStyle(backgroundColor: LineStyle.parseColor("#FFCB06"), foregroundColor: LineStyle.parseColor("#0A3F88")),
            "BM5": LineStyle(backgroundColor: LineStyle.parseColor("#FFF100"), foregroundColor: LineStyle.parseColor("#0A3F88")),
            
            // Bus Rheinpfalz
            "B484": LineStyle(backgroundColor: LineStyle.parseColor("#BE1E2E"), foregroundColor: LineStyle.white),
            "B570": LineStyle(backgroundColor: LineStyle.parseColor("#9B2590"), foregroundColor: LineStyle.white),
            "B571": LineStyle(backgroundColor: LineStyle.parseColor("#303192"), foregroundColor: LineStyle.white),
            "B572": LineStyle(backgroundColor: LineStyle.parseColor("#00A651"), foregroundColor: LineStyle.white),
            "B574": LineStyle(backgroundColor: LineStyle.parseColor("#00ADEE"), foregroundColor: LineStyle.white),
            "B580": LineStyle(backgroundColor: LineStyle.parseColor("#00A8E7"), foregroundColor: LineStyle.white),
            "B581": LineStyle(backgroundColor: LineStyle.parseColor("#F7941D"), foregroundColor: LineStyle.white),
            
            // S-Bahn Rhein-Neckar
            "SS1": LineStyle(backgroundColor: LineStyle.parseColor("#EE1C25"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(backgroundColor: LineStyle.parseColor("#0077C0"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(backgroundColor: LineStyle.parseColor("#4F2E92"), foregroundColor: LineStyle.white),
            "SS33": LineStyle(backgroundColor: LineStyle.parseColor("#4F2E92"), foregroundColor: LineStyle.white),
            "SS4": LineStyle(backgroundColor: LineStyle.parseColor("#00A651"), foregroundColor: LineStyle.black),
            "SS5": LineStyle(backgroundColor: LineStyle.parseColor("#F89735"), foregroundColor: LineStyle.white),
            "SS51": LineStyle(backgroundColor: LineStyle.parseColor("#F89735"), foregroundColor: LineStyle.white),
            
            // Bus Bad Bergzabern
            "B540": LineStyle(backgroundColor: LineStyle.parseColor("#FDC500"), foregroundColor: LineStyle.white),
            "B541": LineStyle(backgroundColor: LineStyle.parseColor("#C10625"), foregroundColor: LineStyle.white),
            "B543": LineStyle(backgroundColor: LineStyle.parseColor("#417B1C"), foregroundColor: LineStyle.white),
            "B544": LineStyle(backgroundColor: LineStyle.parseColor("#00527E"), foregroundColor: LineStyle.white),
            
            // Bus Grünstadt und Umgebung
            "B451": LineStyle(backgroundColor: LineStyle.parseColor("#1AA94A"), foregroundColor: LineStyle.white),
            "B453": LineStyle(backgroundColor: LineStyle.parseColor("#F495BF"), foregroundColor: LineStyle.white),
            "B454": LineStyle(backgroundColor: LineStyle.parseColor("#60B7D4"), foregroundColor: LineStyle.white),
            "B455": LineStyle(backgroundColor: LineStyle.parseColor("#FECC2F"), foregroundColor: LineStyle.white),
            "B457": LineStyle(backgroundColor: LineStyle.parseColor("#AAA23D"), foregroundColor: LineStyle.white),
            "B458": LineStyle(backgroundColor: LineStyle.parseColor("#E54D6F"), foregroundColor: LineStyle.white),
            "B460": LineStyle(backgroundColor: LineStyle.parseColor("#9F0833"), foregroundColor: LineStyle.white),
            "B461": LineStyle(backgroundColor: LineStyle.parseColor("#F68D31"), foregroundColor: LineStyle.white),
            
            // Bus Sinsheim
            "B741": LineStyle(backgroundColor: LineStyle.parseColor("#459959"), foregroundColor: LineStyle.white),
            "B761": LineStyle(backgroundColor: LineStyle.parseColor("#BECE31"), foregroundColor: LineStyle.white),
            "B762": LineStyle(backgroundColor: LineStyle.parseColor("#5997C1"), foregroundColor: LineStyle.white),
            "B763": LineStyle(backgroundColor: LineStyle.parseColor("#FFC20A"), foregroundColor: LineStyle.white),
            "B765": LineStyle(backgroundColor: LineStyle.parseColor("#066D6C"), foregroundColor: LineStyle.white),
            "B768": LineStyle(backgroundColor: LineStyle.parseColor("#0FAD99"), foregroundColor: LineStyle.white),
            "B782": LineStyle(backgroundColor: LineStyle.parseColor("#3BC1CF"), foregroundColor: LineStyle.white),
            "B795": LineStyle(backgroundColor: LineStyle.parseColor("#0056A7"), foregroundColor: LineStyle.white),
            "B796": LineStyle(backgroundColor: LineStyle.parseColor("#F47922"), foregroundColor: LineStyle.white),
            "B797": LineStyle(backgroundColor: LineStyle.parseColor("#A62653"), foregroundColor: LineStyle.white),
            
            // Bus Wonnegau-Altrhein
            "B427": LineStyle(backgroundColor: LineStyle.parseColor("#00A651"), foregroundColor: LineStyle.white),
            "B435": LineStyle(backgroundColor: LineStyle.parseColor("#A3788C"), foregroundColor: LineStyle.white),
            "B660": LineStyle(backgroundColor: LineStyle.parseColor("#0FAD99"), foregroundColor: LineStyle.white),
            "B436": LineStyle(backgroundColor: LineStyle.parseColor("#8169AF"), foregroundColor: LineStyle.white),
            "B663": LineStyle(backgroundColor: LineStyle.parseColor("#7FB6A4"), foregroundColor: LineStyle.white),
            "B921": LineStyle(backgroundColor: LineStyle.parseColor("#F7941D"), foregroundColor: LineStyle.white),
            "B437": LineStyle(backgroundColor: LineStyle.parseColor("#00ADEE"), foregroundColor: LineStyle.white),
            "B418": LineStyle(backgroundColor: LineStyle.parseColor("#BFB677"), foregroundColor: LineStyle.white),
            "B434": LineStyle(backgroundColor: LineStyle.parseColor("#A65631"), foregroundColor: LineStyle.white),
            "B431": LineStyle(backgroundColor: LineStyle.parseColor("#CA5744"), foregroundColor: LineStyle.white),
            "B406": LineStyle(backgroundColor: LineStyle.parseColor("#00A99D"), foregroundColor: LineStyle.white),
            "B433": LineStyle(backgroundColor: LineStyle.parseColor("#5D8AC6"), foregroundColor: LineStyle.white),
            "B432": LineStyle(backgroundColor: LineStyle.parseColor("#82A958"), foregroundColor: LineStyle.white),
            
            // Bus Odenwald-Mitte
            "B667": LineStyle(backgroundColor: LineStyle.parseColor("#00A651"), foregroundColor: LineStyle.white),
            "B684": LineStyle(backgroundColor: LineStyle.parseColor("#039CDB"), foregroundColor: LineStyle.white),
            "B687": LineStyle(backgroundColor: LineStyle.parseColor("#86D1D1"), foregroundColor: LineStyle.white),
            "B691": LineStyle(backgroundColor: LineStyle.parseColor("#BBAFD6"), foregroundColor: LineStyle.white),
            "B697": LineStyle(backgroundColor: LineStyle.parseColor("#002B5C"), foregroundColor: LineStyle.white),
            "B698": LineStyle(backgroundColor: LineStyle.parseColor("#AA568D"), foregroundColor: LineStyle.white),
            
            // Bus Saarbrücken und Umland
            "B231": LineStyle(backgroundColor: LineStyle.parseColor("#94C11C"), foregroundColor: LineStyle.white),
            "B232": LineStyle(backgroundColor: LineStyle.parseColor("#A12785"), foregroundColor: LineStyle.white),
            "B233": LineStyle(backgroundColor: LineStyle.parseColor("#0098D8"), foregroundColor: LineStyle.white),
            "B234": LineStyle(backgroundColor: LineStyle.parseColor("#FDC500"), foregroundColor: LineStyle.white),
            "B235": LineStyle(backgroundColor: LineStyle.parseColor("#C10525"), foregroundColor: LineStyle.white),
            "B236": LineStyle(backgroundColor: LineStyle.parseColor("#104291"), foregroundColor: LineStyle.white),
            "B237": LineStyle(backgroundColor: LineStyle.parseColor("#23AD7A"), foregroundColor: LineStyle.white),
            "B238": LineStyle(backgroundColor: LineStyle.parseColor("#F39100"), foregroundColor: LineStyle.white),
            "B240": LineStyle(backgroundColor: LineStyle.parseColor("#E5007D"), foregroundColor: LineStyle.white),
            
            // Bus Neckargemünd
            "B735": LineStyle(backgroundColor: LineStyle.parseColor("#F47922"), foregroundColor: LineStyle.white),
            "B743": LineStyle(backgroundColor: LineStyle.parseColor("#EE1C25"), foregroundColor: LineStyle.white),
            "B752": LineStyle(backgroundColor: LineStyle.parseColor("#0D7253"), foregroundColor: LineStyle.white),
            "B753": LineStyle(backgroundColor: LineStyle.parseColor("#3BC1CF"), foregroundColor: LineStyle.white),
            "B754": LineStyle(backgroundColor: LineStyle.parseColor("#F99D1D"), foregroundColor: LineStyle.white),
            "B817": LineStyle(backgroundColor: LineStyle.parseColor("#0080A6"), foregroundColor: LineStyle.white),
            
            // Bus Ladenburg
            "B625": LineStyle(backgroundColor: LineStyle.parseColor("#006F45"), foregroundColor: LineStyle.white),
            "B626": LineStyle(backgroundColor: LineStyle.parseColor("#5997C1"), foregroundColor: LineStyle.white),
            "B627": LineStyle(backgroundColor: LineStyle.parseColor("#A62653"), foregroundColor: LineStyle.white),
            "B628": LineStyle(backgroundColor: LineStyle.parseColor("#EE1C25"), foregroundColor: LineStyle.white),
            "B629": LineStyle(backgroundColor: LineStyle.parseColor("#008B9E"), foregroundColor: LineStyle.white),
            
            // Bus Worms
            "B407": LineStyle(backgroundColor: LineStyle.parseColor("#F58581"), foregroundColor: LineStyle.white),
            "B402": LineStyle(backgroundColor: LineStyle.parseColor("#078F47"), foregroundColor: LineStyle.white),
            "B410": LineStyle(backgroundColor: LineStyle.parseColor("#9D368F"), foregroundColor: LineStyle.white),
            "B408": LineStyle(backgroundColor: LineStyle.parseColor("#A79A39"), foregroundColor: LineStyle.white),
//            "B406": LineStyle(backgroundColor: LineStyle.parseColor("#00A99D"), foregroundColor: LineStyle.WHITE),
            "B4906": LineStyle(backgroundColor: LineStyle.parseColor("#BEBEC1"), foregroundColor: LineStyle.white),
            "B4905": LineStyle(backgroundColor: LineStyle.parseColor("#BEBEC1"), foregroundColor: LineStyle.white),
            "B409": LineStyle(backgroundColor: LineStyle.parseColor("#8691B3"), foregroundColor: LineStyle.white),
            
            // Bus Kaiserslautern
            "B101": LineStyle(backgroundColor: LineStyle.parseColor("#EB690B"), foregroundColor: LineStyle.white),
            "B102": LineStyle(backgroundColor: LineStyle.parseColor("#B9418E"), foregroundColor: LineStyle.white),
            "B103": LineStyle(backgroundColor: LineStyle.parseColor("#FFED00"), foregroundColor: LineStyle.black),
            "B104": LineStyle(backgroundColor: LineStyle.parseColor("#7AB51D"), foregroundColor: LineStyle.white),
            "B105": LineStyle(backgroundColor: LineStyle.parseColor("#00712C"), foregroundColor: LineStyle.white),
            "B106": LineStyle(backgroundColor: LineStyle.parseColor("#F7AA00"), foregroundColor: LineStyle.black),
            "B107": LineStyle(backgroundColor: LineStyle.parseColor("#A05322"), foregroundColor: LineStyle.white),
            "B108": LineStyle(backgroundColor: LineStyle.parseColor("#FFE081"), foregroundColor: LineStyle.black),
            "B111": LineStyle(backgroundColor: LineStyle.parseColor("#004494"), foregroundColor: LineStyle.white),
            "B112": LineStyle(backgroundColor: LineStyle.parseColor("#009EE0"), foregroundColor: LineStyle.white),
            "B114": LineStyle(backgroundColor: LineStyle.parseColor("#C33F52"), foregroundColor: LineStyle.white),
            "B115": LineStyle(backgroundColor: LineStyle.parseColor("#E2001A"), foregroundColor: LineStyle.white),
            "B116": LineStyle(backgroundColor: LineStyle.parseColor("#007385"), foregroundColor: LineStyle.white),
            "B117": LineStyle(backgroundColor: LineStyle.parseColor("#622379"), foregroundColor: LineStyle.white),
            
            // Bus Weinheim
            "B631": LineStyle(backgroundColor: LineStyle.parseColor("#949599"), foregroundColor: LineStyle.white),
            "B632": LineStyle(backgroundColor: LineStyle.parseColor("#003D72"), foregroundColor: LineStyle.white),
            "B632A": LineStyle(backgroundColor: LineStyle.parseColor("#0083C2"), foregroundColor: LineStyle.white),
            "B633": LineStyle(backgroundColor: LineStyle.parseColor("#EE1C25"), foregroundColor: LineStyle.white),
            "B634": LineStyle(backgroundColor: LineStyle.parseColor("#F58221"), foregroundColor: LineStyle.white),
            "B681": LineStyle(backgroundColor: LineStyle.parseColor("#00B7BD"), foregroundColor: LineStyle.white),
            "B682": LineStyle(backgroundColor: LineStyle.parseColor("#D1AC75"), foregroundColor: LineStyle.white),
//            "B688": LineStyle(backgroundColor: LineStyle.parseColor("#72BAAF"), foregroundColor: LineStyle.WHITE),
            
            // Bus Schwetzingen-Hockenheim und Umgebung
            "B710": LineStyle(backgroundColor: LineStyle.parseColor("#C10625"), foregroundColor: LineStyle.white),
            "B711": LineStyle(backgroundColor: LineStyle.parseColor("#417B1C"), foregroundColor: LineStyle.white),
            "B712": LineStyle(backgroundColor: LineStyle.parseColor("#A12486"), foregroundColor: LineStyle.white),
            "B713": LineStyle(backgroundColor: LineStyle.parseColor("#0398D8"), foregroundColor: LineStyle.white),
            "B715": LineStyle(backgroundColor: LineStyle.parseColor("#FDC500"), foregroundColor: LineStyle.white),
            "B716": LineStyle(backgroundColor: LineStyle.parseColor("#93C11C"), foregroundColor: LineStyle.white),
            "B717": LineStyle(backgroundColor: LineStyle.parseColor("#004F7A"), foregroundColor: LineStyle.white),
            "B718": LineStyle(backgroundColor: LineStyle.parseColor("#EE7221"), foregroundColor: LineStyle.white),
            "B732": LineStyle(backgroundColor: LineStyle.parseColor("#008692"), foregroundColor: LineStyle.white),
            "B738": LineStyle(backgroundColor: LineStyle.parseColor("#9C9D9D"), foregroundColor: LineStyle.white),
            "B128": LineStyle(backgroundColor: LineStyle.parseColor("#9C9D9D"), foregroundColor: LineStyle.white),
            
            // Bus Odenwald-Süd
            "B686": LineStyle(backgroundColor: LineStyle.parseColor("#E2001A"), foregroundColor: LineStyle.white),
            "B683": LineStyle(backgroundColor: LineStyle.parseColor("#C74E1B"), foregroundColor: LineStyle.white),
            "B692": LineStyle(backgroundColor: LineStyle.parseColor("#F7A800"), foregroundColor: LineStyle.white),
            "B685": LineStyle(backgroundColor: LineStyle.parseColor("#B1C903"), foregroundColor: LineStyle.white),
            "B688": LineStyle(backgroundColor: LineStyle.parseColor("#54C3EC"), foregroundColor: LineStyle.white),
            
            // Bus Neustadt/Wstr. und Umgebung
            "B500": LineStyle(backgroundColor: LineStyle.parseColor("#459959"), foregroundColor: LineStyle.white),
            "B501": LineStyle(backgroundColor: LineStyle.parseColor("#F57F22"), foregroundColor: LineStyle.white),
            "B503": LineStyle(backgroundColor: LineStyle.parseColor("#0058A9"), foregroundColor: LineStyle.white),
            "B504": LineStyle(backgroundColor: LineStyle.parseColor("#BECE31"), foregroundColor: LineStyle.white),
            "B505": LineStyle(backgroundColor: LineStyle.parseColor("#BECE31"), foregroundColor: LineStyle.white),
            "B506": LineStyle(backgroundColor: LineStyle.parseColor("#FFC21C"), foregroundColor: LineStyle.white),
            "B507": LineStyle(backgroundColor: LineStyle.parseColor("#A62653"), foregroundColor: LineStyle.white),
            "B508": LineStyle(backgroundColor: LineStyle.parseColor("#3BC1CF"), foregroundColor: LineStyle.white),
            "B509": LineStyle(backgroundColor: LineStyle.parseColor("#F03F23"), foregroundColor: LineStyle.white),
            "B510": LineStyle(backgroundColor: LineStyle.parseColor("#E7ACC6"), foregroundColor: LineStyle.white),
            "B512": LineStyle(backgroundColor: LineStyle.parseColor("#5997C1"), foregroundColor: LineStyle.white),
            "B517": LineStyle(backgroundColor: LineStyle.parseColor("#066D6C"), foregroundColor: LineStyle.white),
            
            // Bus Neckar-Odenwald-Kreis
            "B821": LineStyle(backgroundColor: LineStyle.parseColor("#263791"), foregroundColor: LineStyle.white),
            "B822": LineStyle(backgroundColor: LineStyle.parseColor("#00ADEE"), foregroundColor: LineStyle.white),
            "B823": LineStyle(backgroundColor: LineStyle.parseColor("#056736"), foregroundColor: LineStyle.white),
            "B824": LineStyle(backgroundColor: LineStyle.parseColor("#9A8174"), foregroundColor: LineStyle.white),
            "B828": LineStyle(backgroundColor: LineStyle.parseColor("#9A8174"), foregroundColor: LineStyle.white),
            "B832": LineStyle(backgroundColor: LineStyle.parseColor("#F7941D"), foregroundColor: LineStyle.white),
            "B833": LineStyle(backgroundColor: LineStyle.parseColor("#C1B404"), foregroundColor: LineStyle.white),
            "B834": LineStyle(backgroundColor: LineStyle.parseColor("#90C73E"), foregroundColor: LineStyle.white),
            "B835": LineStyle(backgroundColor: LineStyle.parseColor("#662D91"), foregroundColor: LineStyle.white),
            "B836": LineStyle(backgroundColor: LineStyle.parseColor("#EE2026"), foregroundColor: LineStyle.white),
            "B837": LineStyle(backgroundColor: LineStyle.parseColor("#00A651"), foregroundColor: LineStyle.white),
            "B838": LineStyle(backgroundColor: LineStyle.parseColor("#8B711B"), foregroundColor: LineStyle.white),
            "B839": LineStyle(backgroundColor: LineStyle.parseColor("#662D91"), foregroundColor: LineStyle.white),
            "B841": LineStyle(backgroundColor: LineStyle.parseColor("#C0B296"), foregroundColor: LineStyle.white),
            "B843": LineStyle(backgroundColor: LineStyle.parseColor("#DBE122"), foregroundColor: LineStyle.white),
            "B844": LineStyle(backgroundColor: LineStyle.parseColor("#93B366"), foregroundColor: LineStyle.white),
            "B849": LineStyle(backgroundColor: LineStyle.parseColor("#E19584"), foregroundColor: LineStyle.white),
            "B857": LineStyle(backgroundColor: LineStyle.parseColor("#C01B2A"), foregroundColor: LineStyle.white),
            "B858": LineStyle(backgroundColor: LineStyle.parseColor("#D2B10C"), foregroundColor: LineStyle.white),
            
            // Bus Landkreis Germersheim
            "B550": LineStyle(backgroundColor: LineStyle.parseColor("#870B36"), foregroundColor: LineStyle.white),
            "B552": LineStyle(backgroundColor: LineStyle.parseColor("#96387C"), foregroundColor: LineStyle.white),
            "B554": LineStyle(backgroundColor: LineStyle.parseColor("#EE542E"), foregroundColor: LineStyle.white),
            "B555": LineStyle(backgroundColor: LineStyle.parseColor("#EC2E6B"), foregroundColor: LineStyle.white),
            "B556": LineStyle(backgroundColor: LineStyle.parseColor("#D7DF21"), foregroundColor: LineStyle.white),
            "B557": LineStyle(backgroundColor: LineStyle.parseColor("#BD7BB4"), foregroundColor: LineStyle.white),
            "B558": LineStyle(backgroundColor: LineStyle.parseColor("#ED5956"), foregroundColor: LineStyle.white),
            "B559": LineStyle(backgroundColor: LineStyle.parseColor("#EE4F5E"), foregroundColor: LineStyle.white),
            "B595": LineStyle(backgroundColor: LineStyle.parseColor("#00A65E"), foregroundColor: LineStyle.white),
            "B596": LineStyle(backgroundColor: LineStyle.parseColor("#73479C"), foregroundColor: LineStyle.white),
            "B546": LineStyle(backgroundColor: LineStyle.parseColor("#E81D34"), foregroundColor: LineStyle.white),
            "B547": LineStyle(backgroundColor: LineStyle.parseColor("#991111"), foregroundColor: LineStyle.white),
            "B548": LineStyle(backgroundColor: LineStyle.parseColor("#974E04"), foregroundColor: LineStyle.white),
            "B549": LineStyle(backgroundColor: LineStyle.parseColor("#F7A5AD"), foregroundColor: LineStyle.white),
            "B593": LineStyle(backgroundColor: LineStyle.parseColor("#D1B0A3"), foregroundColor: LineStyle.white),
            "B594": LineStyle(backgroundColor: LineStyle.parseColor("#FAA86F"), foregroundColor: LineStyle.white),
            "B598": LineStyle(backgroundColor: LineStyle.parseColor("#71BF44"), foregroundColor: LineStyle.white),
            "B590": LineStyle(backgroundColor: LineStyle.parseColor("#C50A54"), foregroundColor: LineStyle.white),
            "B592": LineStyle(backgroundColor: LineStyle.parseColor("#00B6BD"), foregroundColor: LineStyle.white),
            "B599": LineStyle(backgroundColor: LineStyle.parseColor("#00AEEF"), foregroundColor: LineStyle.white),
            
            // Bus Südliche Weinstraße
            "B525": LineStyle(backgroundColor: LineStyle.parseColor("#009EE0"), foregroundColor: LineStyle.white),
            "B523": LineStyle(backgroundColor: LineStyle.parseColor("#F4A10B"), foregroundColor: LineStyle.white),
            "B524": LineStyle(backgroundColor: LineStyle.parseColor("#FFEC00"), foregroundColor: LineStyle.black),
            "B531": LineStyle(backgroundColor: LineStyle.parseColor("#2DA84D"), foregroundColor: LineStyle.white),
            "B532": LineStyle(backgroundColor: LineStyle.parseColor("#00FD00"), foregroundColor: LineStyle.black),
            "B520": LineStyle(backgroundColor: LineStyle.parseColor("#FF3333"), foregroundColor: LineStyle.white),
            "B530": LineStyle(backgroundColor: LineStyle.parseColor("#E84A93"), foregroundColor: LineStyle.white),
            
            // Bus Speyer
            "B561": LineStyle(backgroundColor: LineStyle.parseColor("#003D72"), foregroundColor: LineStyle.white),
            "B562": LineStyle(backgroundColor: LineStyle.parseColor("#F58221"), foregroundColor: LineStyle.white),
            "B563": LineStyle(backgroundColor: LineStyle.parseColor("#EE1C25"), foregroundColor: LineStyle.white),
            "B564": LineStyle(backgroundColor: LineStyle.parseColor("#006C3B"), foregroundColor: LineStyle.white),
            "B565": LineStyle(backgroundColor: LineStyle.parseColor("#00B7BD"), foregroundColor: LineStyle.white),
            "B566": LineStyle(backgroundColor: LineStyle.parseColor("#D1AC75"), foregroundColor: LineStyle.white),
            "B567": LineStyle(backgroundColor: LineStyle.parseColor("#95080A"), foregroundColor: LineStyle.white),
            "B568": LineStyle(backgroundColor: LineStyle.parseColor("#0067B3"), foregroundColor: LineStyle.white),
            "B569": LineStyle(backgroundColor: LineStyle.parseColor("#71BF44"), foregroundColor: LineStyle.white),
            
            // Bus Frankenthal/Pfalz
            "B462": LineStyle(backgroundColor: LineStyle.parseColor("#93C11C"), foregroundColor: LineStyle.white),
            "B463": LineStyle(backgroundColor: LineStyle.parseColor("#A12486"), foregroundColor: LineStyle.white),
            "B464": LineStyle(backgroundColor: LineStyle.parseColor("#0398D8"), foregroundColor: LineStyle.white),
            "B466": LineStyle(backgroundColor: LineStyle.parseColor("#FDC500"), foregroundColor: LineStyle.white),
            "B467": LineStyle(backgroundColor: LineStyle.parseColor("#C10625"), foregroundColor: LineStyle.white),
            
            // Stadtwerke Trier
            "swt|B1": LineStyle(backgroundColor: LineStyle.parseColor("#02a54f"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B2": LineStyle(backgroundColor: LineStyle.parseColor("#f070ab"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B3": LineStyle(backgroundColor: LineStyle.parseColor("#ffdc00"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B4": LineStyle(backgroundColor: LineStyle.parseColor("#00b59d"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B5": LineStyle(backgroundColor: LineStyle.parseColor("#504fa1"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B6": LineStyle(backgroundColor: LineStyle.parseColor("#f58220"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B7": LineStyle(backgroundColor: LineStyle.parseColor("#ee1d23"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B8": LineStyle(backgroundColor: LineStyle.parseColor("#8aacbc"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B9": LineStyle(backgroundColor: LineStyle.parseColor("#c5168c"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B10": LineStyle(backgroundColor: LineStyle.parseColor("#c7c8ca"), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "swt|B13": LineStyle(backgroundColor: LineStyle.parseColor("#bdd630"), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "swt|B14": LineStyle(backgroundColor: LineStyle.parseColor("#88322c"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B15": LineStyle(backgroundColor: LineStyle.parseColor("#c7c8ca"), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "swt|B16": LineStyle(backgroundColor: LineStyle.parseColor("#8b2880"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B17": LineStyle(backgroundColor: LineStyle.parseColor("#c7c8ca"), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "swt|B30": LineStyle(backgroundColor: LineStyle.parseColor("#f1d5ab"), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "swt|B31": LineStyle(backgroundColor: LineStyle.parseColor("#e9eb86"), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "swt|B32": LineStyle(backgroundColor: LineStyle.parseColor("#bfe1ca"), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "swt|B81": LineStyle(backgroundColor: LineStyle.parseColor("#a064aa"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B82": LineStyle(backgroundColor: LineStyle.parseColor("#71bf44"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B83": LineStyle(backgroundColor: LineStyle.parseColor("#f7aa96"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B84": LineStyle(backgroundColor: LineStyle.parseColor("#01aeef"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B85": LineStyle(backgroundColor: LineStyle.parseColor("#f6b7d4"), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "swt|B86": LineStyle(backgroundColor: LineStyle.parseColor("#6bcef6"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B87": LineStyle(backgroundColor: LineStyle.parseColor("#d2acd0"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B88": LineStyle(backgroundColor: LineStyle.parseColor("#cc9d80"), foregroundColor: LineStyle.white, borderColor: LineStyle.black),
            "swt|B89": LineStyle(backgroundColor: LineStyle.parseColor("#fec34d"), foregroundColor: LineStyle.white, borderColor: LineStyle.black)
        ]
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if longName == "InterRegio" && symbol == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "IR")
            } else if trainNum == "IRE1" && trainName == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
            } else if trainNum == "RE11 (RRX)" {
                return Line(id: id, network: network, product: .regionalTrain, label: "RE11")
            }
        }
        
        if let name = name, name.hasPrefix("RNV Moonliner ") {
            return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: "M" + name.substring(from: 15), longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
        } else if let name = name, name.hasPrefix("RNV ") || name.hasPrefix("SWK ") {
            return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name.substring(from: 4), longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
        } else {
            return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
        }
    }
    
}
