import Foundation

public enum QueryTripsResult {
    
    case success(context: QueryTripsContext?, from: Location?, via: Location?, to: Location?, trips: [Trip], messages: [InfoText])
    case ambiguous(ambiguousFrom: [Location], ambiguousVia: [Location], ambiguousTo: [Location])
    case tooClose, unknownFrom, unknownVia, unknownTo, noTrips, invalidDate, sessionExpired
    case failure(Error)
    
}
