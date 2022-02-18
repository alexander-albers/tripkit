import Foundation
import CommonCrypto

extension String {
    var md5: Data {
        return Data(self.utf8).md5
    }
    var sha1: Data {
        return Data(self.utf8).sha1
    }
    var sha256: Data {
        return Data(self.utf8).sha256
    }
    func hmacSha1(key: String) -> Data {
        return Data(self.utf8).hmacSha1(key: key)
    }
}

extension Data {
    var md5: Data {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return Data(hash)
    }
    var sha1: Data {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            CC_SHA1(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return Data(hash)
    }
    var sha256: Data {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return Data(hash)
    }
    func hmacSha1(key: String) -> Data {
        let keyData = Data(key.utf8)
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            return keyData.withUnsafeBytes { (keyBytes: UnsafeRawBufferPointer) -> [UInt8] in
                var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyBytes.baseAddress, key.count, bytes.baseAddress, self.count, &hash)
                return hash
            }
        }
        return Data(hash)
    }
    
    var hex: String {
        return [UInt8](self).map { String(format: "%02x", $0) }.joined()
    }
    var base64: String {
        return self.base64EncodedString()
    }
}
