//
//  GPS_TrackerTests.swift
//  GPS TrackerTests
//
//  Created by Austin Baker on 10/11/2025.
//

import XCTest
import MapKit
@testable import GPS_Tracker

final class GPS_TrackerTests: XCTestCase {

    // MARK: - APIClient Tests

    func testMakeURL_withPath() {
        let url = APIClient.makeURL(path: "/api/location/latest")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.path, "/api/location/latest")
        XCTAssertEqual(url?.host, "api.249dogs.uk")
        XCTAssertEqual(url?.scheme, "https")
    }

    func testMakeURL_withQueryItems() {
        let query = [URLQueryItem(name: "device_id", value: "dog1")]
        let url = APIClient.makeURL(path: "/api/location/latest", queryItems: query)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.query, "device_id=dog1")
    }

    func testMakeURL_withNilQueryItems() {
        let url = APIClient.makeURL(path: "/api/device_id", queryItems: nil)
        XCTAssertNotNil(url)
        XCTAssertNil(url?.query)
    }

    // MARK: - LocationResponse Decoding Tests

    func testLocationResponse_decodesValidJSON() throws {
        let json = """
        {
            "device_id": "dog1",
            "lat": 51.5074,
            "lng": -0.1278,
            "bat": 85.0,
            "status": true,
            "timestamp": "2025-11-14T12:00:00Z"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LocationResponse.self, from: json)
        XCTAssertEqual(response.device_id, "dog1")
        XCTAssertEqual(response.lat, 51.5074)
        XCTAssertEqual(response.lng, -0.1278)
        XCTAssertEqual(response.bat, 85.0)
        XCTAssertTrue(response.status)
        XCTAssertEqual(response.timestamp, "2025-11-14T12:00:00Z")
    }

    func testLocationResponse_failsOnMissingField() {
        let json = """
        {
            "device_id": "dog1",
            "lat": 51.5074
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(LocationResponse.self, from: json))
    }

    func testLocationResponse_statusFalse() throws {
        let json = """
        {
            "device_id": "dog2",
            "lat": 40.7128,
            "lng": -74.0060,
            "bat": 20.0,
            "status": false,
            "timestamp": "2025-11-14T15:30:00Z"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LocationResponse.self, from: json)
        XCTAssertFalse(response.status)
        XCTAssertEqual(response.bat, 20.0)
    }

    // MARK: - GeoFenceResponse Decoding Tests

    func testGeoFenceResponse_decodesValidJSON() throws {
        let json = """
        {
            "id": 1,
            "name": "Backyard",
            "points": [[51.5074, -0.1278], [51.5080, -0.1270], [51.5076, -0.1260]]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(GeoFenceResponse.self, from: json)
        XCTAssertEqual(response.id, 1)
        XCTAssertEqual(response.name, "Backyard")
        XCTAssertEqual(response.points.count, 3)
        XCTAssertEqual(response.points[0][0], 51.5074)
        XCTAssertEqual(response.points[0][1], -0.1278)
    }

    func testGeoFenceResponse_decodesArray() throws {
        let json = """
        [
            {"id": 1, "name": "Yard", "points": [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]]},
            {"id": 2, "name": "Park", "points": [[10.0, 20.0], [30.0, 40.0], [50.0, 60.0]]}
        ]
        """.data(using: .utf8)!

        let fences = try JSONDecoder().decode([GeoFenceResponse].self, from: json)
        XCTAssertEqual(fences.count, 2)
        XCTAssertEqual(fences[0].name, "Yard")
        XCTAssertEqual(fences[1].name, "Park")
    }

    func testGeoFenceResponse_failsOnMissingField() {
        let json = """
        {"id": 1, "name": "Yard"}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(GeoFenceResponse.self, from: json))
    }

    // MARK: - APNIn Encoding/Decoding Tests

    func testAPNIn_encodesAndDecodes() throws {
        let original = APNIn(token: "abc123token")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(APNIn.self, from: data)
        XCTAssertEqual(decoded.token, "abc123token")
    }

    // MARK: - LocationUpdateManager State Tests

    func testLocationUpdateManager_isSingleton() {
        let a = LocationUpdateManager.shared
        let b = LocationUpdateManager.shared
        XCTAssertTrue(a === b)
    }

    func testLocationUpdateManager_storesDogsData() {
        let manager = LocationUpdateManager.shared
        let json = """
        {
            "device_id": "testDog",
            "lat": 51.0,
            "lng": -0.1,
            "bat": 50.0,
            "status": true,
            "timestamp": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let response = try! JSONDecoder().decode(LocationResponse.self, from: json)
        manager.dogs_data["testDog"] = response

        XCTAssertNotNil(manager.dogs_data["testDog"])
        XCTAssertEqual(manager.dogs_data["testDog"]?.lat, 51.0)
        XCTAssertEqual(manager.dogs_data["testDog"]?.bat, 50.0)

        // Cleanup
        manager.dogs_data.removeValue(forKey: "testDog")
    }

    // MARK: - GeoFenceManager State Tests

    func testGeoFenceManager_isSingleton() {
        let a = GeoFenceManager.shared
        let b = GeoFenceManager.shared
        XCTAssertTrue(a === b)
    }

    // MARK: - Notification Name Tests

    func testGeoFenceChangedNotificationName() {
        XCTAssertEqual(Notification.Name.geoFenceChanged.rawValue, "geoFenceChanged")
    }

    // MARK: - Distance Formatting Tests

    func testDistanceFormatting_metres() {
        let metres = 450.0
        let expected = "\(Int(metres))m away"
        XCTAssertEqual(expected, "450m away")
    }

    func testDistanceFormatting_kilometres() {
        let metres = 2500.0
        let expected = String(format: "%f km away", metres / 1000)
        XCTAssertTrue(expected.contains("2.5"))
        XCTAssertTrue(expected.contains("km away"))
    }

    func testDistanceFormatting_thresholdBoundary() {
        // Under 1000m should show metres
        let under = 999.0
        XCTAssertTrue(under < 1000)

        // At 1000m should show kilometres
        let at = 1000.0
        XCTAssertFalse(at < 1000)
    }
}
