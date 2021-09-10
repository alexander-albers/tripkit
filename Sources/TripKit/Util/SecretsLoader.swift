import Foundation
import os.log
import SwiftyJSON

public class SecretsLoader {
    
    public static func loadSecrets() -> [NetworkId: AuthorizationData] {
        guard
            let url = Bundle.module.url(forResource: "secrets", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSON(data: data)
        else {
            os_log("Failed to load secrets file!", log: .default, type: .error)
            return [:]
        }
        
        var result: [NetworkId: AuthorizationData] = [:]
        for entry in json.arrayValue {
            guard let id = NetworkId(rawValue: entry["id"].stringValue.uppercased()) else { continue }
            let apiBase = entry["apiBase"].stringValue
            let apiAuthorization = entry["apiAuthorization"].dictionaryObject ?? [:]
            let certAuthorization = entry["certAuthorization"].dictionaryObject ?? [:]
            let requestVerificationType = entry["requestVerification"]["type"].stringValue
            let requestVerification: AbstractHafasClientInterfaceProvider.RequestVerification
            switch requestVerificationType {
            case "checksum":
                requestVerification = .checksum(salt: entry["requestVerification"]["salt"].stringValue)
            case "micMac":
                requestVerification = .micMac(salt: entry["requestVerification"]["salt"].stringValue)
            case "rnd":
                requestVerification = .rnd
            default:
                requestVerification = .none
            }
            result[id] = AuthorizationData(apiBase: apiBase, hciAuthorization: apiAuthorization, certAuthorization: certAuthorization, hciRequestVerification: requestVerification)
        }
        return result
    }
    
}
