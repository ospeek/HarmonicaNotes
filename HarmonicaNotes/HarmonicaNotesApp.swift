//
//  HarmonicaNotesApp.swift
//  HarmonicaNotes
//
//  Created by Onno Speekenbrink on 2025-06-29.
//

import SwiftUI
import UIKit

@main
struct HarmonicaNotesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .landscape
    }
}
