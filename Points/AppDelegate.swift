//
//  AppDelegate.swift
//  Points
//
//  Created by Glen Hinkle on 7/10/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import UIKit
import CloudKit

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
        
        return true
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
                
                let op = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: [id])
                CKContainer.defaultContainer().addOperation(op)
            }
            
            op.completionBlock = {
                
            }
            
            op.fetchNotificationChangesCompletionBlock = { token, error in
                
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

