//
//  APNToken.swift
//  GPS Tracker
//
//  Created by Austin Baker on 28/4/2026.
//
import Foundation
import UIKit

struct APNIn: Codable {
    let token: String
}

class APNTokenClass {
    static let shared = APNTokenClass()
    private init() {}

    func add(token: String, completion: @escaping (Bool) -> Void) {
        guard let url = APIClient.makeURL(path: "/api/APNHolder/store") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "token": token,
            "device_id": UIDevice.current.identifierForVendor!.uuidString
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Token registration error: \(error)")
                completion(false)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Token registration status: \(httpResponse.statusCode)")
                completion(httpResponse.statusCode == 200)
                return
            }
            completion(false)
        }.resume()
        
    }
}

