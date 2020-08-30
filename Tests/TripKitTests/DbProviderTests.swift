import Foundation
@testable import TripKit

class DbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .DB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return DbProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 52517139, lon: 13388749) } // Berlin - Mitte, Unter den Linden 24
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47994243, lon: 11338543) } // Starnberg, Possenhofener Straße 13
    
    var stationIdFrom: String { return "8011160" } // Berlin Hbf
    
    var stationIdTo: String { return "8010205" } // Leipzig Hbf
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Berlin Hbf" }
    
    var suggestLocationsIncomplete: String { return "Dammt" } // Hamburg Dammtor
    
    var suggestLocationsUmlaut: String { return "Güntzelstr. (U)" }
    
    var suggestLocationsAddress: String { return "Friedenstraße 2, München - Berg am Laim" }
    
}
