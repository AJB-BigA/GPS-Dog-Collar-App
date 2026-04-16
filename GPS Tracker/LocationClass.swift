//
//  Server_Update_File.swift
//  GPS Tracker
//
//  Created by Austin Baker on 14/11/2025.
//

import Foundation
import MapKit

/// Represents the latest location snapshot returned by the `/api/location/latest` endpoint.
struct LocationResponse: Decodable {
    let device_id: String  // Unique identifier for the GPS collar
    let lat: Double        // Latitude in decimal degrees
    let lng: Double        // Longitude in decimal degrees
    let bat: Double        // Battery level as a percentage (0–100)
    let status: Bool       // true = connected to Wi-Fi, false = using cellular/SIM
    let timestamp: String  // ISO-8601 timestamp of the last recorded location
}

class LocationUpdateManager {
    
    static let shared = LocationUpdateManager()
    private init() {}
    
    // Ordered list of device IDs fetched from the server; used to query location data per collar.
    var dogs_ids:[String] = []
    
    // Maps each device ID to its most recent location response.
    var dogs_data:[String : LocationResponse] = [:]
    
    // Maps each device ID to its map annotation so pins can be updated in place.
    var dogAnnotations: [String: MKPointAnnotation] = [:]
    
    private let baseURL = URL(string: "https://api.249dogs.uk")!
    
    /// Builds a full API URL by appending the given path and optional query items to the base URL.
    private func makeURL(path: String,
                         queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
    
    /// Fetches the latest location data for a single device from the server and stores it in `dogs_data`.
    /// - Parameters:
    ///   - d_id: The device ID of the GPS collar to query.
    ///   - completion: Returns `true` if the location was successfully fetched and decoded, `false` otherwise.
    func load_data(d_id:String,completion: @escaping(Bool)->Void){
        let query: [URLQueryItem] = [
            URLQueryItem(name: "device_id", value: d_id)
        ]
        guard let url = makeURL(path: "/api/location/latest", queryItems: query)
        else {
            completion(false)
            return}
        
        URLSession.shared.dataTask(with: url){data, _, error in
            guard let data = data, error == nil
            else{
                completion(false)
                return
            }
            if let json = try? JSONDecoder().decode(LocationResponse.self, from:data){
                DispatchQueue.main.async{
                    self.dogs_data[d_id] = json
                    completion(true)
                }
            }else{
                completion(false)
            }
        }.resume()
    }
    
    /// Fetches the list of registered device IDs from the server and stores them in `dogs_ids`.
    /// - Parameter completion: Returns `true` if the IDs were successfully fetched and decoded, `false` otherwise.
    func load_dog_ids(completion: @escaping(Bool)->Void){
        guard let url = makeURL(path: "/api/device_id")
        else {
            completion(false)
            return}
        
        URLSession.shared.dataTask(with: url){data, _, error in
            guard let data = data, error == nil
            else{
                completion(false)
                return
            }
            if let ids = try? JSONDecoder().decode([String].self, from:data){
                DispatchQueue.main.async {
                    self.dogs_ids = ids
                    completion(true)
                }
            }else{
                completion(false)
            }
        }.resume()
    }
    /// Fetches all device IDs and then loads location data for each in parallel.
    /// Uses `DispatchGroup` so the completion fires only after every request finishes.
    /// - Parameter completion: Returns `true` if all data was loaded successfully, `false` if the initial ID fetch failed.
    func load_all(completion: @escaping (Bool) -> Void) {
        load_dog_ids { success in
            guard success else {
                completion(false)
                return
            }
            let group = DispatchGroup()
            
            for id in self.dogs_ids {
                group.enter()
                self.load_data(d_id: id) { _ in
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(true)
            }
        }
    }
}
