import Foundation

public enum QueryDeparturesResult {
    
    case success(departures: [StationDepartures], desktopUrl: URL?)
    case invalidStation
    case failure(Error)
    
}
