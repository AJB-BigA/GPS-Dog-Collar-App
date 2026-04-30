//
//  AppDelegate.swift
//  GPS Tracker
//
//  Created by Austin Baker on 10/11/2025.
//

import UIKit
import CoreData
import UserNotifications
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Kick off both data loads in parallel at startup so the UI has
    // geofence boundaries and dog locations ready as soon as possible.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    print("Notification permission error: \(error)")
                    return
                }
                print(granted ? "User Notification Permission granted" : "Permission denied")
                
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        return true
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
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
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("got here")
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        
        let lastToken = UserDefaults.standard.string(forKey: "apns_token")
        guard token != lastToken else { return } // no change, skip
        
        UserDefaults.standard.set(token, forKey: "apns_token")
        APNTokenClass.shared.add(token: token) { success in
            print(success ? "Token saved" : "Token save failed")
        }
        
    }
}

