import Foundation
import MapKit

struct GeoFenceResponse: Decodable{
    let id : Int
    let name: String
    let points: [[Double]]
}

class GeoFenceManager {
    static let shared = GeoFenceManager()
    private init() {}
    
    var fences: [GeoFenceResponse] = []
    var polygons: [MKPolygon] = []
    
    private let baseURL = URL(string: "https://api.249dogs.uk")!
    
    private func makeURL(path: String,
                         queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
    
    // converts a GeoFenceResponse into an MKPolygon
    private func makePolygon(from fence: GeoFenceResponse) -> MKPolygon {
        let coordinates = fence.points.map {
            CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1])
        }
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        polygon.title = fence.name
        return polygon
    }
    
    //loads the fence data
    func load(completion: @escaping (Bool) -> Void) {
        guard let url = makeURL(path: "/api/geoFence/data") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            if let decoded = try? JSONDecoder().decode([GeoFenceResponse].self, from: data) {
                DispatchQueue.main.async {
                    self.fences = decoded
                    self.polygons = decoded.map { self.makePolygon(from: $0) }
                    completion(true)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
    //adds a new fence
    func add(name: String, points: [CLLocationCoordinate2D], completion: @escaping (Bool) -> Void) {
        guard let url = makeURL(path: "/api/geo_fence/new-fence/") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let pointArrays = points.map { [$0.latitude, $0.longitude] }
        let body: [String: Any] = ["name": name, "points": pointArrays]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error \(error)")
                completion(false)
                return
            }
            if let data = data,
               let newFence = try? JSONDecoder().decode(GeoFenceResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.fences.append(newFence)
                    self.polygons.append(self.makePolygon(from: newFence))
                    completion(true)
                }
            }
        }.resume()
    }
    //removes polygons
    func delete(id: Int, completion: @escaping (Bool) -> Void) {
        guard let url = makeURL(path: "/api/geoFence/\(id)") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if error == nil {
                DispatchQueue.main.async {
                    self.fences.removeAll { $0.id == id }
                    self.polygons.removeAll { $0.title == String(id) }
                    completion(true)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
}
