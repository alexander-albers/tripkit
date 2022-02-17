import Foundation

public enum QueryDeparturesResult {
    
    /// Departures have been successfully queried.
    ///
    /// - Parameter departures: List of ``StationDepartures`` objects. When `equivs` is `true`, this list contains one instance for every "equivalent" station (example: Hbf Süd and Hbf Nord would be two different StationDepartures instances). When `equivs` is `false`, this list contains only a single instance. All departures are inside ``StationDepartures/departures``.
    case success(departures: [StationDepartures])
    /// The supplied station id is invalid.
    case invalidStation
    /// Any other failure reason. Usually one of ``ParseError`` or ``HttpError``.
    case failure(Error)
    
}
