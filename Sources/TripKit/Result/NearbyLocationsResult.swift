import Foundation

public enum NearbyLocationsResult {
    
    /// Nearby locations have been queried successfully.
    ///
    /// - Parameter locations: list of nearby locations.
    case success(locations: [Location])
    /// The supplied station id is invalid. This enum case is also returned when the provider does not support querying nearby locations to a given station id.
    case invalidId
    /// Any other failure reason. Usually one of ``ParseError`` or ``HttpError``.
    case failure(Error)
    
}
