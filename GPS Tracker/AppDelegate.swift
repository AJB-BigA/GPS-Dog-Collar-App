//
//  AppDelegate.swift
//  GPS Tracker
//
//  Created by Austin Baker on 10/11/2025.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Kick off both data loads in parallel at startup so the UI has
    // geofence boundaries and dog locations ready as soon as possible.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GeoFenceManager.shared.load{
            success in print(success ? "Loaded GeoFence Data" : "Failed to load GeoFence Data")
        }
        
        LocationUpdateManager.shared.load_all{
            success in print(success ? "Loaded All Dog Data" : "Failed to load Dog Data")
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

