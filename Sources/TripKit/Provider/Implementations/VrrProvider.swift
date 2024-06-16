import Foundation

/// Verkehrsverbund Rhein-Ruhr (DE)
public class VrrProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://efa.vrr.de/standard/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .VRR, apiBase: VrrProvider.API_BASE)
        includeRegionId = false
        needsSpEncId = true
        useProxFootSearch = false
        useRouteIndexAsTripId = false
        styles = [
            
            // RRX (copied from NrwProvider.swift)
            "RRE1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d7242a"), foregroundColor: LineStyle.white),
            "RRE2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00a3db"), foregroundColor: LineStyle.white),
            "RRE3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c66c2f"), foregroundColor: LineStyle.white),
            "RRE4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cb8b26"), foregroundColor: LineStyle.white),
            "RRE5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0273a2"), foregroundColor: LineStyle.white),
            "RRE6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#912a7d"), foregroundColor: LineStyle.white),
            "RRE7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0c2954"), foregroundColor: LineStyle.white),
            "RRE8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0062a2"), foregroundColor: LineStyle.white),
            "RRE9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#39143a"), foregroundColor: LineStyle.white),
            "RRE10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cd5c91"), foregroundColor: LineStyle.white),
            "RRE11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5ebcb1"), foregroundColor: LineStyle.white),
            "RRE12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#952b4b"), foregroundColor: LineStyle.white),
            "RRE13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6d5525"), foregroundColor: LineStyle.white),
            "RRE14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#013929"), foregroundColor: LineStyle.white),
            "RRE15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#805492"), foregroundColor: LineStyle.white),
            "RRE16": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#005368"), foregroundColor: LineStyle.white),
            "RRE17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#488d42"), foregroundColor: LineStyle.white),
            "RRE18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#15aba2"), foregroundColor: LineStyle.white),
            "RRE19": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1d5828"), foregroundColor: LineStyle.white),
            "RRE22": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#efa940"), foregroundColor: LineStyle.white),
            "RRE29": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c788b1"), foregroundColor: LineStyle.white),
            "RRE42": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cab631"), foregroundColor: LineStyle.white),
            "RRE44": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#628da0"), foregroundColor: LineStyle.white),
            "RRE49": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b78970"), foregroundColor: LineStyle.white),
            "RRE57": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#3c6390"), foregroundColor: LineStyle.white),
            "RRE60": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#005129"), foregroundColor: LineStyle.white),
            "RRE70": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8883b0"), foregroundColor: LineStyle.white),
            "RRE78": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#56a9b9"), foregroundColor: LineStyle.white),
            "RRE82": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#488d42"), foregroundColor: LineStyle.white),
            "RRE99": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#01a249"), foregroundColor: LineStyle.white),
            
            // Schnellbusse VRR
            "vrr|BSB": LineStyle(backgroundColor: LineStyle.parseColor("#00919d"), foregroundColor: LineStyle.white),
            
            // Dortmund
            "dsw|UU41": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffe700"), foregroundColor: LineStyle.gray),
            "dsw|UU42": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fcb913"), foregroundColor: LineStyle.white),
            "dsw|UU43": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#409387"), foregroundColor: LineStyle.white),
            "dsw|UU44": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#66a3b1"), foregroundColor: LineStyle.white),
            "dsw|UU45": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ee1c23"), foregroundColor: LineStyle.white),
            "dsw|UU46": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#756fb3"), foregroundColor: LineStyle.white),
            "dsw|UU47": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8dc63e"), foregroundColor: LineStyle.white),
            "dsw|UU49": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7acbc"), foregroundColor: LineStyle.white),
            "dsw|BNE": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#2e2382"), foregroundColor: LineStyle.white),
            // Dortmund NachtExpress
            "dsw|BNE1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc1214"), foregroundColor: LineStyle.white),
            "dsw|BNE2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1399e1"), foregroundColor: LineStyle.white),
            "dsw|BNE3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#686fb8"), foregroundColor: LineStyle.white),
            "dsw|BNE4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#febc29"), foregroundColor: LineStyle.white),
            "dsw|BNE5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f93e9d"), foregroundColor: LineStyle.white),
            "dsw|BNE6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fe9222"), foregroundColor: LineStyle.white),
            "dsw|BNE7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1399e1"), foregroundColor: LineStyle.white),
            "dsw|BNE8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffbc29"), foregroundColor: LineStyle.white),
            "dsw|BNE9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#976e25"), foregroundColor: LineStyle.white),
            "dsw|BNE11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8f9555"), foregroundColor: LineStyle.white),
            "dsw|BNE12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#686fb8"), foregroundColor: LineStyle.white),
            "dsw|BNE13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fe9123"), foregroundColor: LineStyle.white),
            "dsw|BNE22": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#167834"), foregroundColor: LineStyle.white),
            "dsw|BNE20": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc1215"), foregroundColor: LineStyle.white),
            "dsw|BNE24": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#167834"), foregroundColor: LineStyle.white),
            "dsw|BNE25": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#30ab3b"), foregroundColor: LineStyle.white),
            "dsw|BNE40": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc1215"), foregroundColor: LineStyle.white),
            
            // Düsseldorf (Rheinbahn)
            "rbg|UU70": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#69b0cd"), foregroundColor: LineStyle.white),
            "rbg|UU71": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#66cef6"), foregroundColor: LineStyle.white),
            "rbg|UU72": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#4cc4c5"), foregroundColor: LineStyle.white),
            "rbg|UU73": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#4763b8"), foregroundColor: LineStyle.white),
            "rbg|UU75": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#079acb"), foregroundColor: LineStyle.white),
            "rbg|UU76": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1969bc"), foregroundColor: LineStyle.white),
            "rbg|UU77": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6d90d2"), foregroundColor: LineStyle.white),
            "rbg|UU78": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#02a7eb"), foregroundColor: LineStyle.white),
            "rbg|UU79": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00aaa0"), foregroundColor: LineStyle.white),
            "rbg|UU83": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#2743a0"), foregroundColor: LineStyle.white),
            "rbg|T701": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f57215"), foregroundColor: LineStyle.white),
            "rbg|T704": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c01c23"), foregroundColor: LineStyle.white),
            "rbg|T705": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#bd0c8e"), foregroundColor: LineStyle.white),
            "rbg|T706": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "rbg|T707": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#72177a"), foregroundColor: LineStyle.white),
            "rbg|T708": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f680b4"), foregroundColor: LineStyle.white),
            "rbg|T709": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ef269d"), foregroundColor: LineStyle.white),
            "rbg|BNE1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fec210"), foregroundColor: LineStyle.black),
            "rbg|BNE2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f17cb0"), foregroundColor: LineStyle.white),
            "rbg|BNE3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#99ca3b"), foregroundColor: LineStyle.white),
            "rbg|BNE4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ee1d23"), foregroundColor: LineStyle.white),
            "rbg|BNE5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#90268f"), foregroundColor: LineStyle.white),
            "rbg|BNE6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f47921"), foregroundColor: LineStyle.white),
            "rbg|BNE7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#009247"), foregroundColor: LineStyle.white),
            "rbg|BNE8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#bdaa8b"), foregroundColor: LineStyle.black),
            "rbg|BM1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#31b759"), foregroundColor: LineStyle.white),
            "rbg|BM2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#31b759"), foregroundColor: LineStyle.white),
            "rbg|BM3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#31b759"), foregroundColor: LineStyle.white),
            
            // Krefeld
            "swk|T041": LineStyle(backgroundColor: LineStyle.parseColor("#ee4036"), foregroundColor: LineStyle.white),
            "swk|T042": LineStyle(backgroundColor: LineStyle.parseColor("#f49392"), foregroundColor: LineStyle.white),
            "swk|T043": LineStyle(backgroundColor: LineStyle.parseColor("#bc6ead"), foregroundColor: LineStyle.white),
            "swk|T044": LineStyle(backgroundColor: LineStyle.parseColor("#f36c21"), foregroundColor: LineStyle.white),
            "swk|B045": LineStyle(backgroundColor: LineStyle.parseColor("#00b5e6"), foregroundColor: LineStyle.white),
            "swk|B046": LineStyle(backgroundColor: LineStyle.parseColor("#695073"), foregroundColor: LineStyle.white),
            "swk|B047": LineStyle(backgroundColor: LineStyle.parseColor("#fbce99"), foregroundColor: LineStyle.white),
            "swk|B051": LineStyle(backgroundColor: LineStyle.parseColor("#a1cf73"), foregroundColor: LineStyle.white),
            "swk|B052": LineStyle(backgroundColor: LineStyle.parseColor("#f68f2a"), foregroundColor: LineStyle.white),
            "swk|B054": LineStyle(backgroundColor: LineStyle.parseColor("#048546"), foregroundColor: LineStyle.white),
            "swk|B055": LineStyle(backgroundColor: LineStyle.parseColor("#00b2b7"), foregroundColor: LineStyle.white),
            "swk|B056": LineStyle(backgroundColor: LineStyle.parseColor("#a2689d"), foregroundColor: LineStyle.white),
            "swk|B057": LineStyle(backgroundColor: LineStyle.parseColor("#3bc4e6"), foregroundColor: LineStyle.white),
            "swk|B058": LineStyle(backgroundColor: LineStyle.parseColor("#0081c6"), foregroundColor: LineStyle.white),
            "swk|B059": LineStyle(backgroundColor: LineStyle.parseColor("#9ad099"), foregroundColor: LineStyle.white),
            "swk|B060": LineStyle(backgroundColor: LineStyle.parseColor("#aac3bf"), foregroundColor: LineStyle.white),
            "swk|B061": LineStyle(backgroundColor: LineStyle.parseColor("#ce8d29"), foregroundColor: LineStyle.white),
            "swk|B062": LineStyle(backgroundColor: LineStyle.parseColor("#ae7544"), foregroundColor: LineStyle.white),
            "swk|B068": LineStyle(backgroundColor: LineStyle.parseColor("#1857a7"), foregroundColor: LineStyle.white),
            "swk|B069": LineStyle(backgroundColor: LineStyle.parseColor("#cd7762"), foregroundColor: LineStyle.white),
            "rvn|B076": LineStyle(backgroundColor: LineStyle.parseColor("#56a44d"), foregroundColor: LineStyle.white),
            "rvn|B077": LineStyle(backgroundColor: LineStyle.parseColor("#fcef08"), foregroundColor: LineStyle.white),
            "rvn|B079": LineStyle(backgroundColor: LineStyle.parseColor("#98a3a4"), foregroundColor: LineStyle.white),
            "swk|BNE5": LineStyle(backgroundColor: LineStyle.parseColor("#99d64c"), foregroundColor: LineStyle.white),
            "swk|BNE6": LineStyle(backgroundColor: LineStyle.parseColor("#f6811d"), foregroundColor: LineStyle.white),
            "swk|BNE7": LineStyle(backgroundColor: LineStyle.parseColor("#5dcbe8"), foregroundColor: LineStyle.white),
            "swk|BNE8": LineStyle(backgroundColor: LineStyle.parseColor("#187fcb"), foregroundColor: LineStyle.white),
            "swk|BNE10": LineStyle(backgroundColor: LineStyle.parseColor("#a32240"), foregroundColor: LineStyle.white),
            "swk|BNE27": LineStyle(backgroundColor: LineStyle.parseColor("#138544"), foregroundColor: LineStyle.white),
            
            // Essen
            "eva|UU17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#68b6e3"), foregroundColor: LineStyle.white),
            "eva|T101": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#986b17"), foregroundColor: LineStyle.white),
            "eva|T103": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffcc00"), foregroundColor: LineStyle.white),
            "eva|T105": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b6cd00"), foregroundColor: LineStyle.white),
            "eva|T106": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a695ba"), foregroundColor: LineStyle.white),
            "eva|T108": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#eca900"), foregroundColor: LineStyle.white),
            "eva|T109": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00933a"), foregroundColor: LineStyle.white),
            "eva|BNE1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7a500"), foregroundColor: LineStyle.white),
            "eva|BNE2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#009dcc"), foregroundColor: LineStyle.white),
            "eva|BNE3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#534395"), foregroundColor: LineStyle.white),
            "eva|BNE4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f29ec4"), foregroundColor: LineStyle.white),
            "eva|BNE5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00964e"), foregroundColor: LineStyle.white),
            "eva|BNE6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e5007c"), foregroundColor: LineStyle.white),
            "eva|BNE7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6e9ed4"), foregroundColor: LineStyle.white),
            "eva|BNE8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#877bb0"), foregroundColor: LineStyle.white),
            "eva|BNE9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed6da6"), foregroundColor: LineStyle.white),
            "eva|BNE10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ab901c"), foregroundColor: LineStyle.white),
            "eva|BNE11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e3000b"), foregroundColor: LineStyle.white),
            "eva|BNE12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#92120a"), foregroundColor: LineStyle.white),
            "eva|BNE13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffde0c"), foregroundColor: LineStyle.black),
            "eva|BNE14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ee7100"), foregroundColor: LineStyle.white),
            "eva|BNE15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#94c11a"), foregroundColor: LineStyle.white),
            "eva|BNE16": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#004e9e"), foregroundColor: LineStyle.white),
            
            // Duisburg
            "dvg|B905": LineStyle(backgroundColor: LineStyle.parseColor("#c8242b"), foregroundColor: LineStyle.white),
            "dvg|B906": LineStyle(backgroundColor: LineStyle.parseColor("#b5ab3a"), foregroundColor: LineStyle.white),
            "dvg|B907": LineStyle(backgroundColor: LineStyle.parseColor("#6891c3"), foregroundColor: LineStyle.white),
            "dvg|B909": LineStyle(backgroundColor: LineStyle.parseColor("#217e5b"), foregroundColor: LineStyle.white),
            "dvg|B910": LineStyle(backgroundColor: LineStyle.parseColor("#d48018"), foregroundColor: LineStyle.white),
            "dvg|B917": LineStyle(backgroundColor: LineStyle.parseColor("#23b14b"), foregroundColor: LineStyle.white),
            "dvg|B919": LineStyle(backgroundColor: LineStyle.parseColor("#078b4a"), foregroundColor: LineStyle.white),
            "dvg|B922": LineStyle(backgroundColor: LineStyle.parseColor("#0072bb"), foregroundColor: LineStyle.white),
            "dvg|B923": LineStyle(backgroundColor: LineStyle.parseColor("#00b1c4"), foregroundColor: LineStyle.white),
            "dvg|B924": LineStyle(backgroundColor: LineStyle.parseColor("#f37921"), foregroundColor: LineStyle.white),
            "dvg|B925": LineStyle(backgroundColor: LineStyle.parseColor("#4876b8"), foregroundColor: LineStyle.white),
            "dvg|B926": LineStyle(backgroundColor: LineStyle.parseColor("#649b43"), foregroundColor: LineStyle.white),
            "dvg|B928": LineStyle(backgroundColor: LineStyle.parseColor("#c4428c"), foregroundColor: LineStyle.white),
            "dvg|B933": LineStyle(backgroundColor: LineStyle.parseColor("#975615"), foregroundColor: LineStyle.white),
            "dvg|B934": LineStyle(backgroundColor: LineStyle.parseColor("#009074"), foregroundColor: LineStyle.white),
            "dvg|B937": LineStyle(backgroundColor: LineStyle.parseColor("#6f78b5"), foregroundColor: LineStyle.white),
            "dvg|B940": LineStyle(backgroundColor: LineStyle.parseColor("#bbbb30"), foregroundColor: LineStyle.white),
            "dvg|B942": LineStyle(backgroundColor: LineStyle.parseColor("#930408"), foregroundColor: LineStyle.white),
            "dvg|B944": LineStyle(backgroundColor: LineStyle.parseColor("#c52157"), foregroundColor: LineStyle.white),
            "dvg|B946": LineStyle(backgroundColor: LineStyle.parseColor("#1cbddc"), foregroundColor: LineStyle.white),
            "dvg|BNE1": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "dvg|BNE2": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "dvg|BNE3": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "dvg|BNE4": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            
            // Oberhausen
            "sto|B952": LineStyle(backgroundColor: LineStyle.parseColor("#f59598"), foregroundColor: LineStyle.white),
            "sto|B953": LineStyle(backgroundColor: LineStyle.parseColor("#5eb6d9"), foregroundColor: LineStyle.white),
            "sto|B954": LineStyle(backgroundColor: LineStyle.parseColor("#f89d3d"), foregroundColor: LineStyle.white),
            "sto|B955": LineStyle(backgroundColor: LineStyle.parseColor("#8879b8"), foregroundColor: LineStyle.white),
            "sto|B956": LineStyle(backgroundColor: LineStyle.parseColor("#23b24b"), foregroundColor: LineStyle.white),
            "sto|B957": LineStyle(backgroundColor: LineStyle.parseColor("#ebc531"), foregroundColor: LineStyle.white),
            "sto|B960": LineStyle(backgroundColor: LineStyle.parseColor("#aed57f"), foregroundColor: LineStyle.white),
            "sto|B961": LineStyle(backgroundColor: LineStyle.parseColor("#a46f73"), foregroundColor: LineStyle.white),
            "sto|B962": LineStyle(backgroundColor: LineStyle.parseColor("#0a776f"), foregroundColor: LineStyle.white),
            "sto|B966": LineStyle(backgroundColor: LineStyle.parseColor("#c8b3d6"), foregroundColor: LineStyle.white),
            "sto|B976": LineStyle(backgroundColor: LineStyle.parseColor("#d063a5"), foregroundColor: LineStyle.white),
            "sto|BNE1": LineStyle(backgroundColor: LineStyle.parseColor("#e22225"), foregroundColor: LineStyle.white),
            "sto|BNE2": LineStyle(backgroundColor: LineStyle.parseColor("#28ad78"), foregroundColor: LineStyle.white),
            "sto|BNE3": LineStyle(backgroundColor: LineStyle.parseColor("#85499c"), foregroundColor: LineStyle.white),
            "sto|BNE4": LineStyle(backgroundColor: LineStyle.parseColor("#395aa8"), foregroundColor: LineStyle.white),
            "sto|BNE5": LineStyle(backgroundColor: LineStyle.parseColor("#ede929"), foregroundColor: LineStyle.white),
            "sto|BNE6": LineStyle(backgroundColor: LineStyle.parseColor("#d488ba"), foregroundColor: LineStyle.white),
            "sto|BNE7": LineStyle(backgroundColor: LineStyle.parseColor("#fbae3e"), foregroundColor: LineStyle.white),
            "sto|BNE10": LineStyle(backgroundColor: LineStyle.parseColor("#270039"), foregroundColor: LineStyle.white),
            
            // Mülheim an der Ruhr
            "vrr|T102": LineStyle(backgroundColor: LineStyle.parseColor("#756fb3"), foregroundColor: LineStyle.white),
            "vrr|B132": LineStyle(backgroundColor: LineStyle.parseColor("#a3c3d1"), foregroundColor: LineStyle.black),
            "vrr|B133": LineStyle(backgroundColor: LineStyle.parseColor("#a9a575"), foregroundColor: LineStyle.black),
            "vrr|B134": LineStyle(backgroundColor: LineStyle.parseColor("#806a63"), foregroundColor: LineStyle.white),
            "vrr|B135": LineStyle(backgroundColor: LineStyle.parseColor("#425159"), foregroundColor: LineStyle.white),
            
            // Neuss
            "swn|B842": LineStyle(backgroundColor: LineStyle.parseColor("#fdcc10"), foregroundColor: LineStyle.white),
            "swn|B843": LineStyle(backgroundColor: LineStyle.parseColor("#808180"), foregroundColor: LineStyle.white),
            "swn|B844": LineStyle(backgroundColor: LineStyle.parseColor("#cb1f25"), foregroundColor: LineStyle.white),
            "swn|B848": LineStyle(backgroundColor: LineStyle.parseColor("#be4e26"), foregroundColor: LineStyle.white),
            "swn|B849": LineStyle(backgroundColor: LineStyle.parseColor("#c878b1"), foregroundColor: LineStyle.white),
            "swn|B854": LineStyle(backgroundColor: LineStyle.parseColor("#35bb93"), foregroundColor: LineStyle.white),
            "swn|BNE1": LineStyle(backgroundColor: LineStyle.parseColor("#ff9900"), foregroundColor: LineStyle.white),
            "swn|BNE2": LineStyle(backgroundColor: LineStyle.parseColor("#0000ff"), foregroundColor: LineStyle.white),
            "swn|BNE3": LineStyle(backgroundColor: LineStyle.parseColor("#ff0000"), foregroundColor: LineStyle.white),
            "swn|BNE4": LineStyle(backgroundColor: LineStyle.parseColor("#ff9900"), foregroundColor: LineStyle.white),
            "swn|BNE5": LineStyle(backgroundColor: LineStyle.parseColor("#9900cc"), foregroundColor: LineStyle.white),
            "swn|BNE6": LineStyle(backgroundColor: LineStyle.parseColor("#00cc99"), foregroundColor: LineStyle.white),
            
            // Remscheid
            "swr|B655": LineStyle(backgroundColor: LineStyle.parseColor("#dbcd00"), foregroundColor: LineStyle.white),
            "swr|B657": LineStyle(backgroundColor: LineStyle.parseColor("#deb993"), foregroundColor: LineStyle.white),
            "swr|B659": LineStyle(backgroundColor: LineStyle.parseColor("#f59b00"), foregroundColor: LineStyle.white),
            "swr|B660": LineStyle(backgroundColor: LineStyle.parseColor("#f5a387"), foregroundColor: LineStyle.white),
            "swr|B664": LineStyle(backgroundColor: LineStyle.parseColor("#b1a8d3"), foregroundColor: LineStyle.white),
            "swr|B666": LineStyle(backgroundColor: LineStyle.parseColor("#0074be"), foregroundColor: LineStyle.white),
            "swr|B673": LineStyle(backgroundColor: LineStyle.parseColor("#ee7555"), foregroundColor: LineStyle.white),
            "swr|B675": LineStyle(backgroundColor: LineStyle.parseColor("#004e9e"), foregroundColor: LineStyle.white),
            "swr|B680": LineStyle(backgroundColor: LineStyle.parseColor("#c78711"), foregroundColor: LineStyle.white),
            "swr|BNE14": LineStyle(backgroundColor: LineStyle.parseColor("#2d247b"), foregroundColor: LineStyle.white),
            "swr|BNE17": LineStyle(backgroundColor: LineStyle.parseColor("#ef7c00"), foregroundColor: LineStyle.white),
            "swr|BNE18": LineStyle(backgroundColor: LineStyle.parseColor("#e5007c"), foregroundColor: LineStyle.white),
            "swr|BNE20": LineStyle(backgroundColor: LineStyle.parseColor("#0a5d34"), foregroundColor: LineStyle.white),
            
            // Solingen
            "sws|B681": LineStyle(backgroundColor: LineStyle.parseColor("#016f42"), foregroundColor: LineStyle.white),
            "sws|B682": LineStyle(backgroundColor: LineStyle.parseColor("#009b78"), foregroundColor: LineStyle.white),
            "sws|B684": LineStyle(backgroundColor: LineStyle.parseColor("#009247"), foregroundColor: LineStyle.white),
            "sws|B685": LineStyle(backgroundColor: LineStyle.parseColor("#539138"), foregroundColor: LineStyle.white),
            "sws|B686": LineStyle(backgroundColor: LineStyle.parseColor("#a6c539"), foregroundColor: LineStyle.white),
            "sws|B687": LineStyle(backgroundColor: LineStyle.parseColor("#406ab4"), foregroundColor: LineStyle.white),
            "sws|B689": LineStyle(backgroundColor: LineStyle.parseColor("#8d5e48"), foregroundColor: LineStyle.white),
            "sws|B690": LineStyle(backgroundColor: LineStyle.parseColor("#0099cd"), foregroundColor: LineStyle.white),
            "sws|B691": LineStyle(backgroundColor: LineStyle.parseColor("#963838"), foregroundColor: LineStyle.white),
            "sws|B693": LineStyle(backgroundColor: LineStyle.parseColor("#9a776f"), foregroundColor: LineStyle.white),
            "sws|B695": LineStyle(backgroundColor: LineStyle.parseColor("#bf4b75"), foregroundColor: LineStyle.white),
            "sws|B696": LineStyle(backgroundColor: LineStyle.parseColor("#6c77b4"), foregroundColor: LineStyle.white),
            "sws|B697": LineStyle(backgroundColor: LineStyle.parseColor("#00baf1"), foregroundColor: LineStyle.white),
            "sws|B698": LineStyle(backgroundColor: LineStyle.parseColor("#444fa1"), foregroundColor: LineStyle.white),
            "sws|B699": LineStyle(backgroundColor: LineStyle.parseColor("#c4812f"), foregroundColor: LineStyle.white),
            "sws|BNE21": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "sws|BNE22": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "sws|BNE24": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "sws|BNE25": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "sws|BNE28": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            
            // Busse Wuppertal
            "wsw|B600": LineStyle(backgroundColor: LineStyle.parseColor("#cc4e97"), foregroundColor: LineStyle.white),
            "wsw|B603": LineStyle(backgroundColor: LineStyle.parseColor("#a77251"), foregroundColor: LineStyle.white),
            "wsw|B604": LineStyle(backgroundColor: LineStyle.parseColor("#f39100"), foregroundColor: LineStyle.white),
            "wsw|B606": LineStyle(backgroundColor: LineStyle.parseColor("#88301b"), foregroundColor: LineStyle.white),
            "wsw|B607": LineStyle(backgroundColor: LineStyle.parseColor("#629e38"), foregroundColor: LineStyle.white),
            "wsw|B609": LineStyle(backgroundColor: LineStyle.parseColor("#53ae2e"), foregroundColor: LineStyle.white),
            "wsw|B610": LineStyle(backgroundColor: LineStyle.parseColor("#eb5575"), foregroundColor: LineStyle.white),
            "wsw|B611": LineStyle(backgroundColor: LineStyle.parseColor("#896a9a"), foregroundColor: LineStyle.white),
            "wsw|B612": LineStyle(backgroundColor: LineStyle.parseColor("#cd7c00"), foregroundColor: LineStyle.white),
            "wsw|B613": LineStyle(backgroundColor: LineStyle.parseColor("#491d5c"), foregroundColor: LineStyle.white),
            "wsw|B614": LineStyle(backgroundColor: LineStyle.parseColor("#00a7c1"), foregroundColor: LineStyle.white),
            "wsw|B616": LineStyle(backgroundColor: LineStyle.parseColor("#e4003a"), foregroundColor: LineStyle.white),
            "wsw|B617": LineStyle(backgroundColor: LineStyle.parseColor("#95114d"), foregroundColor: LineStyle.white),
            "wsw|B618": LineStyle(backgroundColor: LineStyle.parseColor("#cf8360"), foregroundColor: LineStyle.white),
            "wsw|B619": LineStyle(backgroundColor: LineStyle.parseColor("#304c9d"), foregroundColor: LineStyle.white),
            "wsw|B620": LineStyle(backgroundColor: LineStyle.parseColor("#00a47b"), foregroundColor: LineStyle.white),
            "wsw|B622": LineStyle(backgroundColor: LineStyle.parseColor("#aabd81"), foregroundColor: LineStyle.white),
            "wsw|B623": LineStyle(backgroundColor: LineStyle.parseColor("#e04a23"), foregroundColor: LineStyle.white),
            "wsw|B624": LineStyle(backgroundColor: LineStyle.parseColor("#0e9580"), foregroundColor: LineStyle.white),
            "wsw|B625": LineStyle(backgroundColor: LineStyle.parseColor("#7aad3b"), foregroundColor: LineStyle.white),
            "wsw|B628": LineStyle(backgroundColor: LineStyle.parseColor("#80753b"), foregroundColor: LineStyle.white),
            "wsw|B629": LineStyle(backgroundColor: LineStyle.parseColor("#dd72a1"), foregroundColor: LineStyle.white),
            "wsw|B630": LineStyle(backgroundColor: LineStyle.parseColor("#0074be"), foregroundColor: LineStyle.white),
            "wsw|B631": LineStyle(backgroundColor: LineStyle.parseColor("#5a8858"), foregroundColor: LineStyle.white),
            "wsw|B632": LineStyle(backgroundColor: LineStyle.parseColor("#ebac3d"), foregroundColor: LineStyle.white),
            "wsw|B633": LineStyle(backgroundColor: LineStyle.parseColor("#4c2182"), foregroundColor: LineStyle.white),
            "wsw|B635": LineStyle(backgroundColor: LineStyle.parseColor("#cb6c2b"), foregroundColor: LineStyle.white),
            "wsw|B638": LineStyle(backgroundColor: LineStyle.parseColor("#588d58"), foregroundColor: LineStyle.white),
            "wsw|B639": LineStyle(backgroundColor: LineStyle.parseColor("#0097c1"), foregroundColor: LineStyle.white),
            "wsw|B640": LineStyle(backgroundColor: LineStyle.parseColor("#89ba7a"), foregroundColor: LineStyle.white),
            "wsw|B642": LineStyle(backgroundColor: LineStyle.parseColor("#4b72aa"), foregroundColor: LineStyle.white),
            "wsw|B643": LineStyle(backgroundColor: LineStyle.parseColor("#009867"), foregroundColor: LineStyle.white),
            "wsw|B644": LineStyle(backgroundColor: LineStyle.parseColor("#a57400"), foregroundColor: LineStyle.white),
            "wsw|B645": LineStyle(backgroundColor: LineStyle.parseColor("#aeba0e"), foregroundColor: LineStyle.white),
            "wsw|B646": LineStyle(backgroundColor: LineStyle.parseColor("#008db5"), foregroundColor: LineStyle.white),
            "wsw|B650": LineStyle(backgroundColor: LineStyle.parseColor("#f5bd00"), foregroundColor: LineStyle.white),
            "wsw|BE800": LineStyle(backgroundColor: LineStyle.parseColor("#9c9c9d"), foregroundColor: LineStyle.white), //UniExpress
            "wsw|SBSB66": LineStyle(backgroundColor: LineStyle.parseColor("#00919d"), foregroundColor: LineStyle.white),
            "wsw|SBSB67": LineStyle(backgroundColor: LineStyle.parseColor("#00919d"), foregroundColor: LineStyle.white),
            "wsw|SBSB68": LineStyle(backgroundColor: LineStyle.parseColor("#00919d"), foregroundColor: LineStyle.white),
            "wsw|SBSB69": LineStyle(backgroundColor: LineStyle.parseColor("#00919d"), foregroundColor: LineStyle.white),
            "wsw|SBCE61": LineStyle(backgroundColor: LineStyle.parseColor("#e3001d"), foregroundColor: LineStyle.white),
            "wsw|SBCE62": LineStyle(backgroundColor: LineStyle.parseColor("#e3001d"), foregroundColor: LineStyle.white),
            "wsw|SBCE64": LineStyle(backgroundColor: LineStyle.parseColor("#e3001d"), foregroundColor: LineStyle.white),
            "wsw|SBCE65": LineStyle(backgroundColor: LineStyle.parseColor("#e3001d"), foregroundColor: LineStyle.white),
            "wsw|BNE1": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "wsw|BNE2": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "wsw|BNE3": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "wsw|BNE4": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "wsw|BNE5": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "wsw|BNE6": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "wsw|BNE7": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "wsw|BNE8": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            
            // H-Bahn Dortmund
            "dsw|CHB1": LineStyle(backgroundColor: LineStyle.parseColor("#e5007c"), foregroundColor: LineStyle.white),
            "dsw|CHB2": LineStyle(backgroundColor: LineStyle.parseColor("#e5007c"), foregroundColor: LineStyle.white),
            "dsw|CHB5": LineStyle(backgroundColor: LineStyle.parseColor("#e5007c"), foregroundColor: LineStyle.white),
            
            // Schwebebahn Wuppertal
            "wsw|C60": LineStyle(backgroundColor: LineStyle.parseColor("#003090"), foregroundColor: LineStyle.white),
            
            // Stadtbahn Köln-Bonn
            "vrs|T1": LineStyle(backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "vrs|T3": LineStyle(backgroundColor: LineStyle.parseColor("#f680c5"), foregroundColor: LineStyle.white),
            "vrs|T4": LineStyle(backgroundColor: LineStyle.parseColor("#f24dae"), foregroundColor: LineStyle.white),
            "vrs|T5": LineStyle(backgroundColor: LineStyle.parseColor("#9c8dce"), foregroundColor: LineStyle.white),
            "vrs|T7": LineStyle(backgroundColor: LineStyle.parseColor("#f57947"), foregroundColor: LineStyle.white),
            "vrs|T9": LineStyle(backgroundColor: LineStyle.parseColor("#f5777b"), foregroundColor: LineStyle.white),
            "vrs|T12": LineStyle(backgroundColor: LineStyle.parseColor("#80cc28"), foregroundColor: LineStyle.white),
            "vrs|T13": LineStyle(backgroundColor: LineStyle.parseColor("#9e7b65"), foregroundColor: LineStyle.white),
            "vrs|T15": LineStyle(backgroundColor: LineStyle.parseColor("#4dbd38"), foregroundColor: LineStyle.white),
            "vrs|T16": LineStyle(backgroundColor: LineStyle.parseColor("#33baab"), foregroundColor: LineStyle.white),
            "vrs|T18": LineStyle(backgroundColor: LineStyle.parseColor("#05a1e6"), foregroundColor: LineStyle.white),
            "vrs|T61": LineStyle(backgroundColor: LineStyle.parseColor("#80cc28"), foregroundColor: LineStyle.white),
            "vrs|T62": LineStyle(backgroundColor: LineStyle.parseColor("#4dbd38"), foregroundColor: LineStyle.white),
            "vrs|T63": LineStyle(backgroundColor: LineStyle.parseColor("#73d2f6"), foregroundColor: LineStyle.white),
            "vrs|T65": LineStyle(backgroundColor: LineStyle.parseColor("#b3db18"), foregroundColor: LineStyle.white),
            "vrs|T66": LineStyle(backgroundColor: LineStyle.parseColor("#ec008c"), foregroundColor: LineStyle.white),
            "vrs|T67": LineStyle(backgroundColor: LineStyle.parseColor("#f680c5"), foregroundColor: LineStyle.white),
            "vrs|T68": LineStyle(backgroundColor: LineStyle.parseColor("#ca93d0"), foregroundColor: LineStyle.white),
            
            // Stadtbahn Bielefeld
            "owl|T1": LineStyle(backgroundColor: LineStyle.parseColor("#00aeef"), foregroundColor: LineStyle.white),
            "owl|T2": LineStyle(backgroundColor: LineStyle.parseColor("#00a650"), foregroundColor: LineStyle.white),
            "owl|T3": LineStyle(backgroundColor: LineStyle.parseColor("#fff200"), foregroundColor: LineStyle.black),
            "owl|T4": LineStyle(backgroundColor: LineStyle.parseColor("#e2001a"), foregroundColor: LineStyle.white),
            
            // Busse Bonn
            "vrs|B63": LineStyle(backgroundColor: LineStyle.parseColor("#0065ae"), foregroundColor: LineStyle.white),
            "vrs|B16": LineStyle(backgroundColor: LineStyle.parseColor("#0065ae"), foregroundColor: LineStyle.white),
            "vrs|B66": LineStyle(backgroundColor: LineStyle.parseColor("#0065ae"), foregroundColor: LineStyle.white),
            "vrs|B67": LineStyle(backgroundColor: LineStyle.parseColor("#0065ae"), foregroundColor: LineStyle.white),
            "vrs|B68": LineStyle(backgroundColor: LineStyle.parseColor("#0065ae"), foregroundColor: LineStyle.white),
            "vrs|B18": LineStyle(backgroundColor: LineStyle.parseColor("#0065ae"), foregroundColor: LineStyle.white),
            "vrs|B61": LineStyle(backgroundColor: LineStyle.parseColor("#e4000b"), foregroundColor: LineStyle.white),
            "vrs|B62": LineStyle(backgroundColor: LineStyle.parseColor("#e4000b"), foregroundColor: LineStyle.white),
            "vrs|B65": LineStyle(backgroundColor: LineStyle.parseColor("#e4000b"), foregroundColor: LineStyle.white),
            "vrs|BSB55": LineStyle(backgroundColor: LineStyle.parseColor("#00919e"), foregroundColor: LineStyle.white),
            "vrs|BSB60": LineStyle(backgroundColor: LineStyle.parseColor("#8f9867"), foregroundColor: LineStyle.white),
            "vrs|BSB69": LineStyle(backgroundColor: LineStyle.parseColor("#db5f1f"), foregroundColor: LineStyle.white),
            "vrs|B529": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "vrs|B537": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "vrs|B541": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "vrs|B550": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "vrs|B163": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "vrs|B551": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "vrs|B600": LineStyle(backgroundColor: LineStyle.parseColor("#817db7"), foregroundColor: LineStyle.white),
            "vrs|B601": LineStyle(backgroundColor: LineStyle.parseColor("#831b82"), foregroundColor: LineStyle.white),
            "vrs|B602": LineStyle(backgroundColor: LineStyle.parseColor("#dd6ba6"), foregroundColor: LineStyle.white),
            "vrs|B603": LineStyle(backgroundColor: LineStyle.parseColor("#e6007d"), foregroundColor: LineStyle.white),
            "vrs|B604": LineStyle(backgroundColor: LineStyle.parseColor("#009f5d"), foregroundColor: LineStyle.white),
            "vrs|B605": LineStyle(backgroundColor: LineStyle.parseColor("#007b3b"), foregroundColor: LineStyle.white),
            "vrs|B606": LineStyle(backgroundColor: LineStyle.parseColor("#9cbf11"), foregroundColor: LineStyle.white),
            "vrs|B607": LineStyle(backgroundColor: LineStyle.parseColor("#60ad2a"), foregroundColor: LineStyle.white),
            "vrs|B608": LineStyle(backgroundColor: LineStyle.parseColor("#f8a600"), foregroundColor: LineStyle.white),
            "vrs|B609": LineStyle(backgroundColor: LineStyle.parseColor("#ef7100"), foregroundColor: LineStyle.white),
            "vrs|B610": LineStyle(backgroundColor: LineStyle.parseColor("#3ec1f1"), foregroundColor: LineStyle.white),
            "vrs|B611": LineStyle(backgroundColor: LineStyle.parseColor("#0099db"), foregroundColor: LineStyle.white),
            "vrs|B612": LineStyle(backgroundColor: LineStyle.parseColor("#ce9d53"), foregroundColor: LineStyle.white),
            "vrs|B613": LineStyle(backgroundColor: LineStyle.parseColor("#7b3600"), foregroundColor: LineStyle.white),
            "vrs|B614": LineStyle(backgroundColor: LineStyle.parseColor("#806839"), foregroundColor: LineStyle.white),
            "vrs|B615": LineStyle(backgroundColor: LineStyle.parseColor("#532700"), foregroundColor: LineStyle.white),
            "vrs|B630": LineStyle(backgroundColor: LineStyle.parseColor("#c41950"), foregroundColor: LineStyle.white),
            "vrs|B631": LineStyle(backgroundColor: LineStyle.parseColor("#9b1c44"), foregroundColor: LineStyle.white),
            "vrs|B633": LineStyle(backgroundColor: LineStyle.parseColor("#88cdc7"), foregroundColor: LineStyle.white),
            "vrs|B635": LineStyle(backgroundColor: LineStyle.parseColor("#cec800"), foregroundColor: LineStyle.white),
            "vrs|B636": LineStyle(backgroundColor: LineStyle.parseColor("#af0223"), foregroundColor: LineStyle.white),
            "vrs|B637": LineStyle(backgroundColor: LineStyle.parseColor("#e3572a"), foregroundColor: LineStyle.white),
            "vrs|B638": LineStyle(backgroundColor: LineStyle.parseColor("#af5836"), foregroundColor: LineStyle.white),
            "vrs|B640": LineStyle(backgroundColor: LineStyle.parseColor("#004f81"), foregroundColor: LineStyle.white),
            "vrs|BT650": LineStyle(backgroundColor: LineStyle.parseColor("#54baa2"), foregroundColor: LineStyle.white),
            "vrs|BT651": LineStyle(backgroundColor: LineStyle.parseColor("#005738"), foregroundColor: LineStyle.white),
            "vrs|BT680": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "vrs|B800": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "vrs|B812": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "vrs|B843": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "vrs|B845": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "vrs|B852": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "vrs|B855": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "vrs|B856": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "vrs|B857": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
        ]
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        if let products = tripOptions.products, products.contains(.cablecar) {
            builder.addParameter(key: "inclMOT_11", value: "on")
        }
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if trainName == "Regionalbahn" && symbol != nil {
                return Line(id: id, network: network, product: .regionalTrain, label: symbol)
            } else if trainName == "NordWestBahn" && symbol != nil {
                return Line(id: id, network: network, product: .regionalTrain, label: symbol)
            } else if trainNum == "RE11 (RRX)" {
                return Line(id: id, network: network, product: .regionalTrain, label: "RE11")
            } else if trainNum == "MRB26" && trainType == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
            } else if trainType == nil && trainNum == "SEV7" {
                return Line(id: id, network: network, product: .bus, label: trainNum)
            } else if trainType == nil && trainNum == "3SEV" {
                return Line(id: id, network: network, product: .bus, label: trainNum)
            }
        } else if mot == "5" {
            // Bielefeld Uni/Laborschule, Stadtbus
            if network == "owl" && (name ?? "").isEmpty && (longName == "Stadtbus" || trainName == "Stadtbus") {
                return Line(id: id, network: network, product: .bus, label: "LBS")
            }
        } else if mot == "11" {
            // Wuppertaler Schwebebahn & SkyTrain D'dorf
            if trainName == "Schwebebahn" || (longName ?? "").hasPrefix("Schwebebahn") {
                return Line(id: id, network: network, product: .cablecar, label: name)
            // H-Bahn TU Dortmund
            } else if trainName == "H-Bahn" || (longName ?? "").hasPrefix("H-Bahn") {
                return Line(id: id, network: network, product: .cablecar, label: name)
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
    override func lineStyle(network: String?, product: Product?, label: String?) -> LineStyle {
        if product == .bus, let label = label, label.hasPrefix("SB") {
            return super.lineStyle(network: network, product: product, label: "SB")
        } else {
            return super.lineStyle(network: network, product: product, label: label)
        }
    }
}
