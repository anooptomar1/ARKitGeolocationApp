//
//  AppDelegate.swift
//  GeoARDJ
//
//  Created by Mac on 7/25/17.
//  Copyright © 2017 Mac. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import GoogleMaps
import GooglePlaces

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        GMSServices.provideAPIKey("AIzaSyAmRar4lSjMSFTpDvmGP3tXPkRICzKwEyo")
        GMSPlacesClient.provideAPIKey("AIzaSyCAI7Hg9f5IQVoYlStc6U_k0KLzs1Emnck")
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            // Enable or disable features based on authorization.
        }
        center.removeAllPendingNotificationRequests()
        return true
    }
    
    func handleEvent(forRegion region: CLRegion!) {
        print("Geofence triggered!")
        if UIApplication.shared.applicationState == .active {
            window?.rootViewController?.showAlert(withTitle: nil, message: "\(region.identifier)")
        } else {
            let content = UNMutableNotificationContent()
            content.body = region.identifier
            content.sound = UNNotificationSound.default()
            content.categoryIdentifier = "com.litslink.GeoARDJ"
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest.init(identifier: "GeoARDJNotification", content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

