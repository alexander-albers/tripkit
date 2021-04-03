import Foundation

public enum NearbyLocationsResult {
    
    case success(locations: [Location])
    case invalidId
    case failure(Error)
    
}
