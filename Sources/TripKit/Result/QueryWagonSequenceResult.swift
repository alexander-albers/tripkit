import Foundation

public enum QueryWagonSequenceResult {
    /// Wagon sequence has been successfully queried.
    ///
    /// - Parameter wagonSequence: contains details about track sectors and coaches.
    case success(wagonSequence: WagonSequence)
    /// The supplied station id for querying the wagon sequence is invalid.
    case invalidId
    /// Any other failure reason. Usually one of ``ParseError`` or ``HttpError``.
    case failure(Error)
}
