//
//  SceneDelegate.swift
//  GPS Tracker
//
//  Created by Austin Baker on 10/11/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    // Called when the scene is about to connect to the app. The storyboard
    // automatically attaches the window, so no manual setup is needed here.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    // Called when the system releases the scene (e.g. user swipes it away in
    // the app switcher). Free any resources that can be recreated on reconnect.
    func sceneDidDisconnect(_ scene: UIScene) {}

    // Called when the scene becomes the frontmost, interactive scene.
    // Resume any tasks that were paused while the scene was inactive.
    func sceneDidBecomeActive(_ scene: UIScene) {}

    // Called just before the scene loses focus (e.g. incoming phone call).
    // Pause time-sensitive work or UI updates here.
    func sceneWillResignActive(_ scene: UIScene) {}

    // Called as the scene moves from background to foreground.
    // Undo any UI changes made when entering the background.
    func sceneWillEnterForeground(_ scene: UIScene) {}

    // Called when the scene moves to the background.
    // Persist any unsaved data and release shared resources here.
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

