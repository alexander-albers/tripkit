import Foundation

public enum QueryTripsResult {
    
    /// Trips have been successfully queried.
    ///
    /// - Parameter context: context object for querying more trips using ``NetworkProvider/queryMoreTrips(context:later:completion:)``.
    /// - Parameter from: Usually the same as the supplied location.
    /// - Parameter via: Usually the same as the supplied location.
    /// - Parameter to: Usually the same as the supplied location.
    /// - Parameter trips: List of trips that have been found for the specified route.
    /// - Parameter messages: List of informational messages for the specified route.
    case success(context: QueryTripsContext?, from: Location?, via: Location?, to: Location?, trips: [Trip], messages: [InfoText])
    /// From, via or to location could not be identified (probably because no stop id has been provided). Possible candidates are supplied in this result.
    case ambiguous(ambiguousFrom: [Location], ambiguousVia: [Location], ambiguousTo: [Location])
    /// From and To location are too close nearby.
    case tooClose
    /// Location could not be identified.
    case unknownFrom, unknownVia, unknownTo
    /// No trips could be found for the specified route.
    case noTrips
    /// The specified date is outside the valid range.
    case invalidDate
    /// When querying more trips or refreshing an existing trip, this error means that the used context object is no longer valid.
    case sessionExpired
    /// Any other failure reason. Usually one of ``ParseError`` or ``HttpError``.
    case failure(Error)
    
}
