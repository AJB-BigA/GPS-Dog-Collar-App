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

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error \(error)")
                completion(false)
                return
            }
            if let data = data,
               let _ = try? JSONDecoder().decode(APNIn.self, from: data) {
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }.resume()
    }
}

