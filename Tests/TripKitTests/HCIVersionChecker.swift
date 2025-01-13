/// Goes through a list of Hafas Client Interface providers and retrieves the currently running version of its server backend.

import Foundation
import os.log
@testable import TripKit
import XCTest

@available(macOS 10.15, iOS 13.0, *)
class HCIVersionChecker: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["TEST_HCI_VERSIONS"] == nil)
    }
    
    func testMaxVersions() async {
        let secrets: [NetworkId: AuthorizationData] = SecretsLoader.loadSecrets()
        let providers: [AbstractHafasClientInterfaceProvider] = [
            BvgProvider(apiAuthorization: secrets[.BVG]!.hciAuthorization),
            VbbProvider(apiAuthorization: secrets[.VBB]!.hciAuthorization),
            RmvProvider(apiAuthorization: secrets[.RMV]!.hciAuthorization),
            AvvAachenProvider(apiAuthorization: secrets[.AVV2]!.hciAuthorization),
            InvgProvider(apiAuthorization: secrets[.INVG]!.hciAuthorization),
            NvvProvider(apiAuthorization: secrets[.NVV]!.hciAuthorization),
            ShProvider(apiAuthorization: secrets[.SH]!.hciAuthorization),
            GvhProvider(apiAuthorization: secrets[.GVH]!.hciAuthorization),
            VbnProvider(apiAuthorization: secrets[.VBN]!.hciAuthorization),
            KvbProvider(apiAuthorization: secrets[.KVB]!.hciAuthorization),
            NasaProvider(apiAuthorization: secrets[.NASA]!.hciAuthorization),
            VsnProvider(apiAuthorization: secrets[.VSN]!.hciAuthorization),
            VosProvider(apiAuthorization: secrets[.VOS]!.hciAuthorization),
            VmtProvider(apiAuthorization: secrets[.VMT]!.hciAuthorization),
            VgsProvider(apiAuthorization: secrets[.VGS]!.hciAuthorization),
            BlsProvider(apiAuthorization: secrets[.BLS]!.hciAuthorization),
            TpgProvider(apiAuthorization: secrets[.TPG]!.hciAuthorization),
            ZvvProvider(apiAuthorization: secrets[.ZVV]!.hciAuthorization),
            OebbProvider(apiAuthorization: secrets[.OEBB]!.hciAuthorization),
            VorProvider(apiAuthorization: secrets[.VOR]!.hciAuthorization),
            OoevvProvider(apiAuthorization: secrets[.OOEVV]!.hciAuthorization),
            IvbProvider(apiAuthorization: secrets[.IVB]!.hciAuthorization),
            SvvProvider(apiAuthorization: secrets[.SVV]!.hciAuthorization),
            VvtProvider(apiAuthorization: secrets[.VVT]!.hciAuthorization),
            StvProvider(apiAuthorization: secrets[.STV]!.hciAuthorization),
            VmobilProvider(apiAuthorization: secrets[.VMOBIL]!.hciAuthorization),
        ]
        
        for provider in providers {
            let urlBuilder = UrlBuilder(path: provider.mgateEndpoint, encoding: .utf8)

            let dict: [String : Any] = [
                "auth": provider.apiAuthorization ?? "",
                "client": provider.apiClient ?? "",
                "ver": "1.21",
                "lang": "de",
                "svcReqL": [[
                    "meth": "ServerInfo",
                    "req": [
                        "getVersionInfo": true
                    ]
                ] as [String : Any]]
            ]
            let request = provider.encodeJson(dict: dict, requestUrlEncoding: .utf8)
            provider.requestVerification.appendParameters(to: urlBuilder, requestString: request)

            let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request)
            let result = await withCheckedContinuation { continuation in
                _ = HttpClient.getJson(httpRequest: httpRequest) { result in
                    continuation.resume(with: .success(result))
                }
            }

            switch result {
            case .success(let json):
                let errString = json["err"].stringValue
                XCTAssertEqual(errString, "OK")
                
                let version = json["svcResL"][0]["res"]["hciVersion"].stringValue
                XCTAssertFalse(version.isEmpty)
                os_log("%@: latest supported version is %@", provider.id.rawValue, version)
            case .failure(let error):
                os_log("%@: failed to get latest supported version: %@", provider.id.rawValue, (error as NSError).description)
            }
        }
    }
}
