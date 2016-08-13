//
//  ImportVC.swift
//  Points
//
//  Created by Glen Hinkle on 7/20/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit
import MessageBarManager
import M13ProgressSuite
import CloudKit

class ImportVC: UIViewController {
    var progress = NSProgress()
    var dump: Dump?
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var downloadingProgressView: M13ProgressViewPie!
    @IBOutlet weak var importingProgressView: M13ProgressViewPie!
    @IBOutlet weak var fictionProgressView: M13ProgressViewPie!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progress = NSProgress()
        
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        
        progress.addObserver(self,
                                  forKeyPath: "fractionCompleted",
                                  options: [.Initial, .New, .Old],
                                  context: nil
        )
        
        preferredContentSize = CGSize(width: 300, height: 300)
        
        if let dump = dump {
            //importDump()
        }
        
        getDumpFromCloudKit()
    }
    
    func importDump() {
    
        dispatch(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), .Async) {
            do {
                let realm = try! Realm()
                
                guard let dump = realm.objects(Dump).sorted("date", ascending: true).last else {
                    return
                }
                
                try Points.importData(dump.data, into: realm, with: self.progress)
                
                self.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: nil)
                
                ui(.Sync) {
                    
                    self.progressView.setProgress(1, animated: true)
                    
                    ui(.Async) {
                        //self.presentingViewController?.dismissViewControllerAnimated(true, completion: .None)
                        self.dismissViewControllerAnimated(true, completion: .None)
                    }
                    
                    //self.progressView.performAction(M13ProgressViewActionSuccess, animated: true)
                }
            }
            catch let error as NSError {
                ui(.Async) {
                    MessageBarManager.sharedInstance().showMessageWithTitle("Import Points", description: error.localizedDescription, type: MessageBarMessageTypeError)
                }
            }
        }
    }
    
    func getDumpFromCloudKit() {
        
        let query = CKQuery.latest(.Dumps)
        let op = CKQueryOperation(query: query)
        op.desiredKeys = ["id", "date"]
        op.resultsLimit = 1
        op.recordFetchedBlock = { record in
            
            self.progress.totalUnitCount = 1
            
            let op = CKFetchRecordsOperation(recordIDs: [record.recordID])
            op.perRecordProgressBlock = { recordID, progress in
                print("DUMP DOWNLOAD PROGRESS: \(progress)")
                self.progress.completedUnitCount = Int64(progress)
            }
            
            op.perRecordCompletionBlock = { record, recordID, error in
                if let error = error {
                    print(error)
                }
                
                guard let record = record else {
                    return
                }
                
                do {
                    let dump = try Dump(ckRecord: record)
                    try dump.data.writeToDumps(path: "\(dump.date).txt.bz2")
                    
                    let realm = try! Realm()
                    try realm.write {
                        realm.add(dump, update: true)
                    }
                    
                    self.importDump()
                }
                catch {
                    print(error)
                }
                
            }
            
            CKContainer.defaultContainer().publicCloudDatabase.addOperation(op)
        }
        
        op.completionBlock = {
            
        }
        op.queryCompletionBlock = { cursor, error in
            
            if let error = error {
                ui(.Async) {
                    MessageBarManager.sharedInstance().showMessageWithTitle("Fetch Dump", description: error.localizedDescription, type: MessageBarMessageTypeError)
                }
                print(error)
                return
            }
        }
        
        CKContainer.defaultContainer().publicCloudDatabase.addOperation(op)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        switch keyPath {
            
        case "fractionCompleted"?:
            
            if let progress = object as? NSProgress {
                print("fraction: \(progress.fractionCompleted)")
                ui(.Async) {
                    self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                    //progressView.setProgress(CGFloat(progress.fractionCompleted), animated: true)
                }
            }
            
        default:
            break
        }
    }
    
}