# TripKit
TripKit is a Swift-port of https://github.com/schildbach/public-transport-enabler with some additional enhancements. This library allows you to get data from public transport providers. You can get an overview of all supported transit providers here: https://navigatorapp.net/coverage.
Look into [NetworkProvider.swift](Sources/TripKit/Provider/NetworkProvider.swift) for an overview of the API.

TripKit is built using Swift 5.0 and requires iOS 12.0/watchOS 5.0/tvOS 12.0/macOS 10.13.

This library is currently used by the [ÖPNV Navigator app](http://navigatorapp.net) in the iOS App Store.

[![Static tests](https://github.com/alexander-albers/tripkit/actions/workflows/test-static.yml/badge.svg)](https://github.com/alexander-albers/tripkit/actions/workflows/test-static.yml)
[![Provider tests](https://github.com/alexander-albers/tripkit/actions/workflows/test-providers.yml/badge.svg)](https://github.com/alexander-albers/tripkit/actions/workflows/test-providers.yml)

## Integration

Use the Swift Package Manager to install TripKit into your project. If you have a Package.swift file, add the following entry to your dependencies:

```swift
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        // Insert the following line into your Swift package dependencies.
        .package(url: "https://github.com/alexander-albers/tripkit.git", .branch("main")),
    ],
)
```

If you are using a regular Xcode project, you can select "File" -> "Add Packages…" from the menu bar and paste the url of this git repository.

The tagged commits of this repository correspond to the released versions of the [ÖPNV Navigator app](http://navigatorapp.net) and have no other meaning. I try to avoid code-breaking changes between releases as far as possible, but since this project is still under active development there is not guarantee that some minor things might break. 

## Example Usage

### Create a new instance of a network provider:
```swift
let provider: NetworkProvider = KvvProvider() // Karlsruher Verkehrsverbund
```

### Find locations for a given keyword:
```swift
let (request, result) = await provider.suggestLocations(constraint: "Marktplatz")
switch result {
case .success(let locations):
    for suggestedLocation in locations {
        print(suggestedLocation.location.getUniqueShortName())
    }
case .failure(let error):
    print(error)
}
```

### Find locations near a coordinate (Marktplatz):
```swift
let (request, result) = await provider.queryNearbyLocations(location: Location(lat: 49009656, lon: 8402383))
switch result {
case .success(let locations):
    for location in locations {
        print(location.getUniqueShortName())
    }
case .failure(let error):
    print(error)
}
```

### Query departures from Marktplatz (id=7001003):
```swift
let (request, result) = await provider.queryDepartures(stationId: "7001003")
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

### Query trips between Marktplatz (7001003) and Kronenplatz (7001002):
```swift
let (request, result) = await provider.queryTrips(from: Location(id: "7001003"), via: nil, to: Location(id: "7001002"))
switch result {
case .success(let context, let from, let via, let to, let trips, let messages):
    for trip in trips {
        print(trip.id)
    }
default:
    print("no trips could be found")
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

More api methods can be found in [NetworkProvider.swift](Sources/TripKit/Provider/NetworkProvider.swift) and [NetworkProvider+Async.swift](Sources/TripKit/Provider/NetworkProvider+Async.swift).

## Using providers that require secrets

For some providers a secret like an API key is required to use their API. You need to request the secrets directly from the provider or use the same ones that are used by the official apps.

For unit testing, you need to specify all required secrets in a secrets.json file. A template can be found [here](Sources/TripKit/Resources/secrets.json.template).

## Contributing and future plans

Feel free to add further transit providers to the project, as long as they don't overlap with already existing ones and don't require too much maintenance or a server to be used. Since this project is based on the public-transport-enabler, my intention is to have this project as close to it as possible. For now, I'd like to stick to transit providers in German-speaking countries, but a further expansion to other countries is imaginable for the future. 

## Related Projects

- [`public-transport-enabler`](https://github.com/schildbach/public-transport-enabler) – Java equivalent; Used by [Öffi](https://oeffi.schildbach.de) & [Transportr](https://transportr.app).
- [`hafas-client`](https://github.com/public-transport/hafas-client) – JavaScript equivalent for HAFAS public transport APIs.
- [`kpublictransport`](https://github.com/KDE/kpublictransport) – C++ equivalent; Used by [KDE Itinerary](https://apps.kde.org/itinerary/).
- [`pyhafas`](https://github.com/n0emis/pyhafas) – Python equivalent.
- [`*.transport.rest`](https://transport.rest/) – Public APIs wrapping some HAFAS endpoints.
- [`BahnhofsAbfahrten`](https://github.com/marudor/BahnhofsAbfahrten) a.k.a. [`marudor.de`](https://marudor.de/) – A very detailed public transport website for Germany. Uses HAFAS underneath, [has an API](https://docs.marudor.de).
