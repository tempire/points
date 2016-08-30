//
//  ViewController.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import UIKit
import CloudKit
//import LzmaSDK_ObjC
//import MPMessagePack
//import YSMessagePack

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
        guard let url = NSBundle.mainBundle().URLForResource("acompetitors", withExtension: "data", subdirectory: .None),
            data = NSData(contentsOfURL: url) else {
                return
        }
        */
        
        let documentsDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let compressed = NSData(contentsOfFile: "\(documentsDir)/competitors.messagepack.bzip2")
        
        /*
        //let reader = MPMessagePackReader(data: data)
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [[String:AnyObject]]
            let packed = pack(items: json.map{$0})
            print(packed.length)
            try packed.writeToFile(documentsDir + "/messagepacked.data", options: [])
            
            //let obj = try reader.readObject()
            //print(obj)
        }
        catch {
            print(error)
        }
 
        //let reader = LzmaSDKObjCWriter
        */
        
        /*
        
        let container = CKContainer.defaultContainer()
        let publicDatabase = container.publicCloudDatabase
        
        container.requestApplicationPermission(.UserDiscoverability) { status, error in
            container.discoverAllContactUserInfosWithCompletionHandler { userInfo, error in
                
        let date = NSDate()
        
        let record = CKRecord(.Dumps, id: date.toString)
        record["id"] = 0
        record["dump"] = compressed
        record["timestamp"] = date
        //record["count"] = competitorCount
        
        publicDatabase.saveRecord(record) { record, error in
            print(date.timeIntervalSinceDate(date))
            print(record)
            print(error)
        }
            }
        }
        
        return;
        
 
        let op = CKSubscription(.Competitors, predicate: NSPredicate.all, subscriptionID: .Competitors, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        
        op.notificationInfo = CKNotificationInfo()
        op.notificationInfo?.alertBody = "Competitor Thing"
        op.notificationInfo?.shouldBadge = true
        op.notificationInfo?.shouldSendContentAvailable = true
        
        publicDatabase.saveSubscription(op) { subscription, error in
            
        }
        
 */
        /*
         container.fetchUserRecordIDWithCompletionHandler { recordID, error in
         publicDatabase.fetchRecordWithID(recordID!) { record, error in
         
         }
         }
         
         publicDatabase.deleteRecordWithID(CKRecordID(recordName: "_facdec1a146ff3ff4a702897f1371f4f")) { recordID, error in
         
         }
        
        WebService.load(WebService.competitor(11049)) { result in
            
            switch result {
                
            case .Success(let competitor):
                
                let record = CKRecord(.Competitors, name: "\(competitor.id)")
                record["id"] = competitor.id
                record["wsdcId"] = competitor.wsdcId
                record.setObject(competitor.firstName, forKey: "firstName")
                record.setObject(competitor.lastName, forKey: "lastName")
                
                publicDatabase.saveRecord(record) { record, error in
                    print(record)
                    print(error)
                }
                
            case .Error(let error):
                print("Error: \(error)")
            }
        }
        */
    }
     */
}

