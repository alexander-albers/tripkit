import Foundation

public enum QueryJourneyDetailResult {
    
    /// Journey details have been successfully queried.
    ///
    /// - Parameter trip: a trip object which contains a single ``PublicLeg`` instance.
    /// - Parameter leg: the single leg of the supplied trip (this parameter is redundant and is not actually needed).
    case success(trip: Trip, leg: PublicLeg)
    /// The supplied context object for querying the journey details is invalid.
    case invalidId
    /// Any other failure reason. Usually one of ``ParseError`` or ``HttpError``.
    case failure(Error)
    
}
