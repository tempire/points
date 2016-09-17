//
//  AppDelegate.swift
//  Points
//
//  Created by Glen Hinkle on 7/10/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import UIKit
import RealmSwift
import CloudKit
import CoreSpotlight

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: .none)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        //if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject:AnyObject] {
        //    self.application(application, didReceiveRemoteNotification: remoteNotification)
        //}

        try! configureRealm()
        
        URLSession.shared.configuration.timeoutIntervalForResource = 600
        URLSession.shared.configuration.timeoutIntervalForRequest = 300
        
        Points.addSubscriptionForNewPoints { subscription, error in
            print(error)
        }
        
        completeUI(.none)

        return true
    }
    
    func configureRealm() throws {
        
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                
                switch oldSchemaVersion {
                    
                case 0, 1, 2: // Previously unspecified version == 0
                    break
                    
                default:
                    break
                }
            }
        )
        
        let realm = try Realm()
        print("Realm Schema initialized")
    }
    

    
    func completeUI(_ completion: ((Void)->Void)?) {
        ui(.async) {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = Storyboard.Main.viewController(TabBarController.self)
            self.window?.makeKeyAndVisible()
            completion?()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: APNS
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print(userInfo)
        
        completionHandler(.noData)
        
        return;
        
        //print("RECEVIED REMOTE NOTIFICATION")
        //completionHandler(.NoData)
    
        if let userInfo = userInfo as? [String:NSObject],
            let queryNotification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification {
            
            // Store this elsewhere so that fetchNotificationChangesCompletionBlock can retrieve the most recent record id
            let recordID = queryNotification.recordID
            
            let op = CKFetchNotificationChangesOperation(previousServerChangeToken: .none)
            
            op.notificationChangedBlock = { notification in
                
                guard let notification = notification as? CKQueryNotification, let id = notification.notificationID else {
                    return
                }
                
                switch notification.queryNotificationReason {
                case .recordCreated:
                    guard let recordId = notification.recordID else {
                        return
                    }
                    
                    CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordId) { record, error in
                        if let data = record?["data"] as? Data, let _ = record?["date"] as? Date {
                    
                            do {
                                // Write to database
                                let realm = try Realm()
                                let dump = try Dump(id: UUID(), date: Date(), version: 0, data: data)
                                
                                try realm.write {
                                    realm.add(dump, update: true)
                                }
                            }
                            catch let error as NSError {
                                print(error)
                            }
                        }
                    }
                    
                    print("created")
                    
                case .recordUpdated:
                    print("updated")
                    
                case .recordDeleted:
                    print("deleted")
                }
                
                print("MORE COMING: \(op.moreComing)")
                
                // Do not mark read before it's retrieved, do this in fetchNotificationChangesCompletionBlock
                let op = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: [id])
                CKContainer.default().add(op)
            }
            
            op.completionBlock = {
                
            }
            
            op.fetchNotificationChangesCompletionBlock = { token, error in
                // Retrieve most recent record id for dumps
                // And only after retrieved, do you mark the notification id as read with CKMarkNotificationsReadOperation
                
            }
            
            CKContainer.default().add(op)
            
            print("RECORDID: \(recordID)")
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("DEVICETOKEN: \(deviceToken)")
        let token = "\(deviceToken)"
            .trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
            .replacingOccurrences(of: " ", with: "")

        print("TOKEN: \(token)")
    }

    private func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        //
    }
}


// MARK: Open from spotlight

extension AppDelegate {
    
    @objc(application:continueUserActivity:restorationHandler:) func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        
        if let tabVC = window?.rootViewController as? TabBarController,
            let navVC = tabVC.selectedViewController as? UINavigationController,
            let vc = navVC.viewControllers.last as? DancerVC , userActivity.activityType == CSSearchableItemActionType {
            vc.restoreUserActivityState(userActivity)
        }
    
        return true
    }
}
