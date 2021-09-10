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
}
