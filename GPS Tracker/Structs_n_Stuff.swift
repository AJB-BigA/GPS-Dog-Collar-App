//  Structs_n_Stuff.swift
//  GPS Tracker
//
//  Created by Austin Baker on 28/1/2026.


import Foundation
import MapKit

//used in ViewController to hold basic info of the differnet dogs
struct dogData{
    let bat: Double
    let status: Bool
}

//used in Server_Update_File to hold the data sent from the database
struct LocationResponse: Decodable {
    let device_id: String
    let lat: Double
    let lng: Double
    let bat: Double
    let status: Bool
    let timestamp: String
}

//Used in the server to hold the geoFence sent from the database
struct GeoFenceResponse: Decodable{
    let id : Int
    let name: String
    let points: [[Double]]
}


