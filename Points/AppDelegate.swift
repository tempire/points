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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: .None)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject:AnyObject] {
            self.application(application, didReceiveRemoteNotification: remoteNotification)
        }
        
        NSURLSession.sharedSession().configuration.timeoutIntervalForResource = 600
        NSURLSession.sharedSession().configuration.timeoutIntervalForRequest = 300
        
        completeUI(.None)
        

        return true
    }
    
    func configureRealm() throws -> Realm {
        
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                
                switch oldSchemaVersion {
                    
                case 0: // Previously unspecified version == 0
                    break
                    //self.migrateRealmFrom0To1(migration)
                    
                case 1:
                    break
                    //self.migrateRealmFrom1To2(migration)
                    
                default:
                    break
                }
            }
        )
        
        return try Realm()
    }
    

    
    func completeUI(completion: (Void->Void)?) {
        ui(.Async) {
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            self.window?.rootViewController = Storyboard.Main.viewController(TabBarController)
            self.window?.makeKeyAndVisible()
            completion?()
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: APNS
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if let userInfo = userInfo as? [String:NSObject],
            queryNotification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification {
            
            // Store this elsewhere so that fetchNotificationChangesCompletionBlock can retrieve the most recent record id
            let recordID = queryNotification.recordID
            
            let op = CKFetchNotificationChangesOperation(previousServerChangeToken: .None)
            op.notificationChangedBlock = { notification in
                guard let notification = notification as? CKQueryNotification, id = notification.notificationID else {
                    return
                }
                
                switch notification.queryNotificationReason {
                case .RecordCreated:
                    print("created")
                    
                case .RecordUpdated:
                    print("updated")
                    
                case .RecordDeleted:
                    print("deleted")
                }
                
                print(op.moreComing)
                
                // Do not mark read before it's retrieved, do this in fetchNotificationChangesCompletionBlock
                let op = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: [id])
                CKContainer.defaultContainer().addOperation(op)
            }
            
            op.completionBlock = {
                
            }
            
            op.fetchNotificationChangesCompletionBlock = { token, error in
                // Retrieve most recent record id for dumps
                // And only after retrieved, do you mark the notification id as read with CKMarkNotificationsReadOperation
                
            }
            
            CKContainer.defaultContainer().addOperation(op)
            
            print(recordID)
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        //
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        //
    }
}


// MARK: Open from spotlight

extension AppDelegate {
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        
        if let tabVC = window?.rootViewController as? TabBarController,
            navVC = tabVC.selectedViewController as? UINavigationController,
            vc = navVC.viewControllers.last as? DancerVC where userActivity.activityType == CSSearchableItemActionType {
            vc.restoreUserActivityState(userActivity)
        }
    
        return true
    }
}
