import Foundation

public enum QueryDeparturesResult {
    
    case success(departures: [StationDepartures])
    case invalidStation
    case failure(Error)
    
}
