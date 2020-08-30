import Foundation
import os.log
import _SwiftOSOverlayShims

extension OSLog {
    static let requestLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Provider request")
}
