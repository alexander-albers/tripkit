# TripKit
TripKit is a Swift-port of https://github.com/schildbach/public-transport-enabler with some additional enhancements. This library allows you to get data from public transport providers. You can get an overview of all supported transit providers here: https://navigatorapp.net/coverage.
Look into [NetworkProvider.swift](https://github.com/alexander-albers/tripkit/blob/master/Sources/TripKit/NetworkProvider.swift) for an overview of the API.

TripKit is built using Swift 5.0 and requires iOS 10.0/watchOS 3.0/tvOS 10.0/macOS 10.12.

This library is currently used by the [ÖPNV Navigator app](http://navigatorapp.net) in the iOS App Store.

[![Static tests](https://github.com/alexander-albers/tripkit/actions/workflows/test-static.yml/badge.svg)](https://github.com/alexander-albers/tripkit/actions/workflows/test-static.yml)
[![Provider tests](https://github.com/alexander-albers/tripkit/actions/workflows/test-providers.yml/badge.svg)](https://github.com/alexander-albers/tripkit/actions/workflows/test-providers.yml)

## Example Usage

### Create a new instance of a network provider:
```swift
let provider: NetworkProvider = KvvProvider() // Karlsruher Verkehrsverbund
```

### Find locations for a given keyword:
```swift
let (request, result) = await provider.suggestLocations(constraint: "Marktplatz", types: [.station], maxLocations: 10)
switch result {
case .success(let locations):
    for suggestedLocation in locations {
        print(suggestedLocation.location.getUniqueShortName())
    }
case .failure(let error):
    print(error)
}
```

### Query departures from Marktplatz (id=7000001):
```swift
let (request, result) = await provider.queryDepartures(stationId: "7000001", time: Date(), maxDepartures: 10, equivs: false)
switch result {
case .success(let departures):
    for departure in departures.flatMap { $0.departures } {
        let label = departure.line.label ?? "?"
        let destination = departure.destination?.getUniqueShortName() ?? "?"
        let time = departure.getTime()
        print("\(time): \(line) --> \(destination)")
    }
case .invalidStation:
    print("invalid station id")
case .failure(let error):
    print(error)
}
```

### Query trips between Marktplatz (7000001) and Kronenplatz (7000002):
```swift
let (request, result) = await provider.queryTrips(from: Location(id: "7000001"), via: nil, to: Location(id: "7000002"), date: Date(), departure: true, tripOptions: TripOptions())
switch result {
case .success(let context, let from, let via, let to, let trips, let messages):
    for trip in trips {
        print(trip.id)
    }
case .noTrips:
    print("no trips could be found")
case .sessionExpired: // can only occur when querying for more trips
    print("your session has expired")
case .ambiguous(let ambiguousFrom, let ambiguousVia, let ambiguousTo):
    print("from, via or to location could not be identified (probably because no stop id has been provided)")
case .invalidDate:
    print("invalid date")
case .tooClose:
    print("from and to location are too close nearby")
case .unknownFrom:
    print("unknown from location")
case .unknownVia:
    print("unknown via location")
case .unknownTo:
    print("unknown to location")
case .failure(let error):
    print(error)
}
```

### Query all intermediate stops of a line:
```swift
// journeyContext can be obtained from a PublicLeg instance.
let (request, result) = await provider.queryJourneyDetail(context: journeyContext)
switch result {
case .success(let trip, let leg):
    print(leg.intermediateStops)
case .invalidId:
    print("invalid context")
case .failure(let error):
    print(error)
}
```

More api methods can be found in [NetworkProvider.swift](https://github.com/alexander-albers/tripkit/blob/master/Sources/TripKit/NetworkProvider.swift).

## Using providers that require secrets

For some providers a secret like an API key is required to use their API. You need to request the secrets directly from the provider or use the same ones that are used by the official apps.

For unit testing, you need to specify all required secrets in a secrets.json file. A template can be found [here](Sources/TripKit/Resources/secrets.json.template).

## Contributing and future plans

Feel free to add further transit providers to the project, as long as they don't overlap with already existing ones and don't require too much maintenance or a server to be used. Since this project is based on the public-transport-enabler, my intention is to have this project as close to it as possible. For now, I'd like to stick to transit providers in German-speaking countries, but a further expansion to other countries is imaginable for the future. 
