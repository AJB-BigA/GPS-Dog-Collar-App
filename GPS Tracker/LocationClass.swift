//
//  Server_Update_File.swift
//  GPS Tracker
//
//  Created by Austin Baker on 14/11/2025.
//

import Foundation
import MapKit

struct LocationResponse: Decodable {
    let device_id: String
    let lat: Double
    let lng: Double
    let bat: Double
    let status: Bool
    let timestamp: String
}

class LocationUpdateManager {
    
    static let shared = LocationUpdateManager()
    private init() {}
    
    //holds the dogs ids for string and to ask the database for different things
    var dogs_ids:[String] = []
    
    var dogs_data:[String : LocationResponse] = [:]
    
    //holds the points for each dog made
    var dogAnnotations: [String: MKPointAnnotation] = [:]
    
    private let baseURL = URL(string: "https://api.249dogs.uk")!
    
    private func makeURL(path: String,
                         queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
    
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
