import Foundation

public enum SuggestLocationsResult {

    case success(locations: [SuggestedLocation])
    case failure(Error)

}
