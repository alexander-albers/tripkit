//
//  NetworkProviderExtensions.swift
//  Verbindungen
//
//  Created by Alexander Albers on 10/04/2023.
//  Copyright © 2023 Alexander Albers. All rights reserved.
//

import Foundation

/// Contains some useful extensions and utility functions, acting as another level of abstraction for certain tasks.
public extension NetworkProvider {
    
    /**
       Query trips, ensuring that a minimum number of trips gets returned.
    
       - Parameter from: location to route from.
       - Parameter via: location to route via, may be nil.
       - Parameter to: location to route to.
       - Parameter date: desired date for departing. See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
       - Parameter departure: date is departure date? true for departure, false for arrival.
       - Parameter minNumTrips: minimum number of trips that should be returned.
       - Parameter tripOptions: additional options.
       - Parameter completion: result object that can contain alternatives to clear up ambiguousnesses, or contains possible trips.
    
       - Returns: A reference to a cancellable http request.
    */
    @discardableResult func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, minNumTrips: Int, tripOptions: TripOptions, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest {
        let asyncRequest = AsyncRequest(task: nil)
        queryTripsRecursive(asyncRequest: asyncRequest, from: from, via: via, to: to, startTime: date, departure: departure, minNumTrips: minNumTrips, tripOptions: tripOptions, context: nil, trips: [], messages: [], completion: completion)
        return asyncRequest
    }
    
    private func queryTripsRecursive(asyncRequest: AsyncRequest, from: Location, via: Location?, to: Location, startTime: Date, departure: Bool, minNumTrips: Int, tripOptions: TripOptions, context: QueryTripsContext?, trips: [Trip], messages: [InfoText], completion: @escaping (QueryTripsResult) -> Void) {
        if let context = context {
            asyncRequest.task = queryMoreTrips(context: context, later: true, completion: { (_, result) in
                self.handleQueryTripsRecursive(result: result, asyncRequest: asyncRequest, from: from, via: via, to: to, startTime: startTime, departure: departure, minNumTrips: minNumTrips, tripOptions: tripOptions, trips: trips, messages: messages, completion: completion)
            }).task
        } else {
            asyncRequest.task = queryTrips(from: from, via: via, to: to, date: startTime, departure: departure, tripOptions: tripOptions, completion: { (_, result) in
                self.handleQueryTripsRecursive(result: result, asyncRequest: asyncRequest, from: from, via: via, to: to, startTime: startTime, departure: departure, minNumTrips: minNumTrips, tripOptions: tripOptions, trips: trips, messages: messages, completion: completion)
            }).task
        }
    }
    
    private func handleQueryTripsRecursive(result: QueryTripsResult, asyncRequest: AsyncRequest, from: Location, via: Location?, to: Location, startTime: Date, departure: Bool, minNumTrips: Int, tripOptions: TripOptions, trips: [Trip], messages: [InfoText], completion: @escaping (QueryTripsResult) -> Void) {
        var trips = trips
        var messages = messages
        
        switch result {
        case .success(let context, _, _, _, let resultTrips, let resultMessages):
            trips.append(contentsOf: getNonDuplicateEntries(newEntries: resultTrips, existingEntries: trips))
            messages.append(contentsOf: getNonDuplicateEntries(newEntries: resultMessages, existingEntries: messages))
            
            if trips.count < minNumTrips, let context = context {
                self.queryTripsRecursive(asyncRequest: asyncRequest, from: from, via: via, to: to, startTime: startTime, departure: departure, minNumTrips: minNumTrips, tripOptions: tripOptions, context: context, trips: trips, messages: messages, completion: completion)
            } else {
                completion(.success(context: context, from: from, via: via, to: to, trips: trips, messages: messages))
            }
        default:
            if trips.count > 0 {
                completion(.success(context: nil, from: from, via: via, to: to, trips: trips, messages: messages))
            } else {
                completion(result)
            }
        }
    }
    
    /**
    Get departures at a given station, ensuring that a minimum number of departures gets returned.
 
    - Parameter stationId: id of the station.
    - Parameter departures: true for departures, false for arrivals.
    - Parameter time: desired time for departing, or `nil` for the provider default. See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    - Parameter minDepartures: minimum number of departures that should be returned.
    - Parameter maxDepartures: maximum number of departures to get in each network request, or `0`.
    - Parameter equivs: also query equivalent stations?
    - Parameter completion: object containing the departures.
 
    - Returns: A reference to a cancellable http request.
     */
    @discardableResult func queryDepartures(stationId: String, departures: Bool, time: Date?, minDepartures: Int, maxDepartures: Int, equivs: Bool, completion: @escaping (QueryDeparturesResult) -> Void) -> AsyncRequest {
        let asyncRequest = AsyncRequest(task: nil)
        queryDeparturesRecursive(asyncRequest: asyncRequest, stationId: stationId, departures: departures, startTime: time, minDepartures: minDepartures, maxDepartures: maxDepartures, equivs: equivs, stationDepartures: [], completion: completion)
        return asyncRequest
    }
    
    private func queryDeparturesRecursive(asyncRequest: AsyncRequest, stationId: String, departures: Bool, startTime: Date?, minDepartures: Int, maxDepartures: Int, equivs: Bool, stationDepartures: [StationDepartures], completion: @escaping (QueryDeparturesResult) -> Void) {
        asyncRequest.task = queryDepartures(stationId: stationId, departures: departures, time: startTime, maxDepartures: maxDepartures, equivs: equivs) { _, result in
            self.handleQueryDeparturesRecursive(result: result, asyncRequest: asyncRequest, stationId: stationId, departures: departures, startTime: startTime, minDepartures: minDepartures, maxDepartures: maxDepartures, equivs: equivs, stationDepartures: stationDepartures, completion: completion)
        }.task
    }
    
    private func handleQueryDeparturesRecursive(result: QueryDeparturesResult, asyncRequest: AsyncRequest, stationId: String, departures: Bool, startTime: Date?, minDepartures: Int, maxDepartures: Int, equivs: Bool, stationDepartures: [StationDepartures], completion: @escaping (QueryDeparturesResult) -> Void) {
        var stationDepartures = stationDepartures
        switch result {
        case .success(let resultDepartures):
            for stationDeparture in resultDepartures {
                if let existing = stationDepartures.first(where: {$0.stopLocation == stationDeparture.stopLocation}) {
                    existing.lines.append(contentsOf: getNonDuplicateEntries(newEntries: stationDeparture.lines, existingEntries: existing.lines))
                    existing.departures.append(contentsOf: getNonDuplicateEntries(newEntries: stationDeparture.departures, existingEntries: existing.departures))
                } else {
                    stationDepartures.append(stationDeparture)
                }
            }
            
            let sortedDepartures = stationDepartures.flatMap({ $0.departures }).sorted(by: {$0.time < $1.time})
            if sortedDepartures.count < minDepartures {
                queryDeparturesRecursive(asyncRequest: asyncRequest, stationId: stationId, departures: departures, startTime: sortedDepartures.last?.plannedTime, minDepartures: minDepartures, maxDepartures: maxDepartures, equivs: equivs, stationDepartures: stationDepartures, completion: completion)
            } else {
                completion(.success(departures: stationDepartures))
            }
        default:
            if stationDepartures.count > 0 {
                completion(.success(departures: stationDepartures))
            } else {
                completion(result)
            }
        }
    }
    
    private func getNonDuplicateEntries<T: Equatable>(newEntries: [T], existingEntries: [T]) -> [T] {
        var result: [T] = []
        for entry in newEntries {
            if !existingEntries.contains(entry) {
                result.append(entry)
            }
        }
        return result
    }
}
