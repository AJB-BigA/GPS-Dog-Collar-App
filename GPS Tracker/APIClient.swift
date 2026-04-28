//
//  APIClient.swift
//  GPS Tracker
//
//  Created by Austin Baker on 28/4/2026.
//


import Foundation

enum APIClient {
    static let baseURL = URL(string: "https://api.249dogs.uk")!

    static func makeURL(path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}