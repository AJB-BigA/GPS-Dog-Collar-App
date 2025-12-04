//
//  Server_Update_File.swift
//  GPS Tracker
//
//  Created by Austin Baker on 14/11/2025.
//

import Foundation

struct LocationResponse: Decodable {
    let device_id: String
    let lat: Double
    let lng: Double
    let bat: Double
    let status: Bool
    let timestamp: String
}

struct GeoFenceResponse: Decodable{
    let id : Int
    let name: String
    let points: [[Double]]
}

class update_server_info {
    private let baseURL = URL(string: "https://api.249dogs.uk")!
    
    private func makeURL(path: String,
                         queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
    
    func update_locations(d_id:String,completion: @escaping(LocationResponse?)->Void){
        
        let query: [URLQueryItem] = [
            URLQueryItem(name: "device_id", value: d_id)
        ]
        guard let url = makeURL(path: "/api/location/latest", queryItems: query) 
        else {
        completion(nil)
            return}
                
        URLSession.shared.dataTask(with: url){data, _, error in
            guard let data = data, error == nil 
            else{
                completion(nil)
                return
            }
            let json = try? JSONDecoder().decode(LocationResponse.self, from:data)
            completion(json)
        }.resume()
    }
    
    func get_id(completion: @escaping([String]?)->Void){
        guard let url = makeURL(path: "/api/device_id")
        else {
        completion(nil)
            return}
                
        URLSession.shared.dataTask(with: url){data, _, error in
            guard let data = data, error == nil
            else{
                completion(nil)
                return
            }
            print(data)
            let ids = try? JSONDecoder().decode([String].self, from:data)
            completion(ids)
        }.resume()
    }
    
    func get_rows(completion: @escaping(Int)->Void){
        guard let url = makeURL(path: "/api/dogs") else {
            completion(0)
            return
        }
        
        URLSession.shared.dataTask(with: url){data, _, error in
            guard let data = data, error == nil else {
                completion(0)
                return
            }
            let count = try? JSONDecoder().decode(Int.self, from: data)
            completion(count!)
        }.resume()
    }
    
    func get_geoFence_rows(completion: @escaping(Int)->Void){
        guard let url = makeURL(path: "/api/geoFence/rows") else {
            completion(0)
            return
        }
        
        URLSession.shared.dataTask(with: url){data, _, error in
            guard let data = data, error == nil else {
                completion(0)
                return
            }
            let count = try? JSONDecoder().decode(Int.self, from: data)
            completion(count!)
        }.resume()
    }
}
