import Foundation

public enum QueryJourneyDetailResult {
    
    case success(trip: Trip, leg: PublicLeg)
    case invalidId
    case failure(Error)
    
}
