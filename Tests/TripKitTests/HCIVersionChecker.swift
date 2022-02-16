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
            DbProvider(apiAuthorization: secrets[.DB]!.hciAuthorization, requestVerification: secrets[.DB]!.hciRequestVerification),
            BvgProvider(apiAuthorization: secrets[.BVG]!.hciAuthorization),
            VbbProvider(apiAuthorization: secrets[.VBB]!.hciAuthorization, requestVerification: secrets[.VBB]!.hciRequestVerification),
            RmvProvider(apiAuthorization: secrets[.RMV]!.hciAuthorization),
            AvvAachenProvider(apiAuthorization: secrets[.AVV2]!.hciAuthorization),
            InvgProvider(apiAuthorization: secrets[.INVG]!.hciAuthorization, requestVerification: secrets[.INVG]!.hciRequestVerification),
            NvvProvider(apiAuthorization: secrets[.NVV]!.hciAuthorization, requestVerification: secrets[.NVV]!.hciRequestVerification),
            ShProvider(apiAuthorization: secrets[.SH]!.hciAuthorization),
            GvhProvider(apiAuthorization: secrets[.GVH]!.hciAuthorization), // 1.53
            VbnProvider(apiAuthorization: secrets[.VBN]!.hciAuthorization),
            NasaProvider(apiAuthorization: secrets[.NASA]!.hciAuthorization), // 1.48
            VsnProvider(apiAuthorization: secrets[.VSN]!.hciAuthorization, requestVerification: secrets[.VSN]!.hciRequestVerification),
            VosProvider(apiAuthorization: secrets[.VOS]!.hciAuthorization, requestVerification: secrets[.VOS]!.hciRequestVerification),
            VmtProvider(apiAuthorization: secrets[.VMT]!.hciAuthorization),
            NrwProvider(apiAuthorization: secrets[.NRW]!.hciAuthorization),
            VgsProvider(apiAuthorization: secrets[.VGS]!.hciAuthorization),
            ZvvProvider(apiAuthorization: secrets[.ZVV]!.hciAuthorization, requestVerification: secrets[.ZVV]!.hciRequestVerification),
            OebbProvider(apiAuthorization: secrets[.OEBB]!.hciAuthorization),
            VorProvider(apiAuthorization: secrets[.VOR]!.hciAuthorization),
            OoevvProvider(apiAuthorization: secrets[.OOEVV]!.hciAuthorization, requestVerification: secrets[.OOEVV]!.hciRequestVerification),
            IvbProvider(apiAuthorization: secrets[.IVB]!.hciAuthorization),
            SvvProvider(apiAuthorization: secrets[.SVV]!.hciAuthorization, requestVerification: secrets[.SVV]!.hciRequestVerification),
            VvtProvider(apiAuthorization: secrets[.VVT]!.hciAuthorization),
            StvProvider(apiAuthorization: secrets[.STV]!.hciAuthorization),
            VmobilProvider(apiAuthorization: secrets[.VMOBIL]!.hciAuthorization),
        ]
        
        for provider in providers {
            let urlBuilder = UrlBuilder(path: provider.mgateEndpoint, encoding: .utf8)

            let dict: [String : Any] = ["auth": provider.apiAuthorization ?? "", "client": provider.apiClient ?? "", "ver": "1.99", "lang": "de", "svcReqL": []]
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
                XCTAssertEqual(errString, "VERSION")
                
                let version = json["ver"].stringValue
                XCTAssertFalse(version.isEmpty)
                os_log("%@: latest supported version is %@", provider.id.rawValue, version)
            case .failure(let error):
                os_log("%@: failed to get latest supported version: %@", provider.id.rawValue, (error as NSError).description)
            }
        }
    }
}
