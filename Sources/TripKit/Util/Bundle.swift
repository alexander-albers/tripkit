#if XCODE_BUILD

fileprivate class BundleClass {}

extension Foundation.Bundle {
    
    /// Override SwiftPM bundle
    static var module: Bundle = {
        return Bundle(for: BundleClass.self)
    }()
    
}
#endif
