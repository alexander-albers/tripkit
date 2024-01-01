import Foundation

extension Bundle {
    func identity(named name: String, password: String) throws -> SecIdentity {
        return try identity(named: (name as NSString).deletingPathExtension, ext: (name as NSString).pathExtension, password: password)
    }
    func identity(named name: String, ext: String, password: String) throws -> SecIdentity {
        guard let p12URL = self.url(forResource: name, withExtension: ext) else {
            throw ParseError(reason: "could not find specified certificate")
        }
        let p12Data = try Data(contentsOf: p12URL)

        var importedCF: CFArray? = nil
        let options = [kSecImportExportPassphrase as String: password]
        let err = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &importedCF)
        guard err == errSecSuccess else {
            throw ParseError(reason: "failed to import PKCS12: \(err)")
        }
        guard let imported = importedCF as NSArray? as? [[String:AnyObject]] else {
            throw ParseError(reason: "failed to import PKCS12")
        }
        guard imported.count == 1 else {
            throw ParseError(reason: "loaded more than one certificate")
        }

        guard let identity = imported[0][kSecImportItemIdentity as String] else {
            throw ParseError(reason: "failed to import PKCS12")
        }
        return identity as! SecIdentity
    }
    
    func cert(named name: String, ext: String) throws -> SecCertificate {
        guard let url = self.url(forResource: name, withExtension: ext) else {
            throw ParseError(reason: "could not find specified certificate")
        }
        let data = try Data(contentsOf: url) as CFData
        let cert = SecCertificateCreateWithData(nil, data)
        guard let cert = cert else {
            throw ParseError(reason: "failed to create trust from sertificate")
        }
        return cert
    }
    func trust(named name: String, ext: String) throws -> SecTrust {
        guard let url = self.url(forResource: name, withExtension: ext) else {
            throw ParseError(reason: "could not find specified certificate")
        }
        let data = try Data(contentsOf: url) as CFData
        let cert = SecCertificateCreateWithData(nil, data)
        var secTrust: SecTrust?
        guard let cert = cert, SecTrustCreateWithCertificates(cert, SecPolicyCreateBasicX509(), &secTrust) == errSecSuccess, let secTrust = secTrust else {
            throw ParseError(reason: "failed to create trust from sertificate")
        }
        return secTrust
    }
}
extension SecTrust {
    
    func evaluate() -> Bool {
        var trustResult: SecTrustResultType = .invalid
        let err = SecTrustEvaluate(self, &trustResult)
        guard err == errSecSuccess else { return false }
        return [.proceed, .unspecified].contains(trustResult)
    }
    
    func evaluateAllowing(rootCertificates: [SecCertificate]) -> Bool {
        // Apply our custom root to the trust object.
        var err = SecTrustSetAnchorCertificates(self, rootCertificates as CFArray)
        guard err == errSecSuccess else { return false }
        
        // Re-enable the system's built-in root certificates.
        
        err = SecTrustSetAnchorCertificatesOnly(self, false)
        guard err == errSecSuccess else { return false }
        
        // Run a trust evaluation and only allow the connection if it succeeds.
        
        return self.evaluate()
    }
}
