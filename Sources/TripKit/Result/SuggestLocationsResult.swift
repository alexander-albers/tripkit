import Foundation

public enum SuggestLocationsResult {

    /// Locations have been successfully suggested.
    ///
    /// - Parameter locations: sorted list of suggested locations.
    case success(locations: [SuggestedLocation])
    /// Any other failure reason. Usually one of ``ParseError`` or ``HttpError``.
    case failure(Error)

}
