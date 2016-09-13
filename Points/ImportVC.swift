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
    var progress = Progress()
    var dump: Dump?
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var downloadingProgressView: M13ProgressViewPie!
    @IBOutlet weak var importingProgressView: M13ProgressViewPie!
    @IBOutlet weak var fictionProgressView: M13ProgressViewPie!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progress = Progress()
        
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        
        progress.addObserver(self,
                                  forKeyPath: "fractionCompleted",
                                  options: [.initial, .new, .old],
                                  context: nil
        )
        
        preferredContentSize = CGSize(width: 300, height: 300)
        
        //if let dump = dump {
        //    //importDump()
        //}
        
        getDumpFromCloudKit()
    }
    
    func importDump() {
    
        dispatch(DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive), .async) {
            do {
                let realm = try! Realm()
                
                guard let dump = realm.allObjects(ofType: Dump.self).sorted(onProperty: "date", ascending: true).last else {
                    return
                }
                
                try Points.importData(dump.data, into: realm, with: self.progress)
                
                self.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: nil)
                
                ui(.sync) {
                    
                    self.progressView.setProgress(1, animated: true)
                    
                    ui(.async) {
                        //self.presentingViewController?.dismissViewControllerAnimated(true, completion: .None)
                        self.dismiss(animated: true, completion: .none)
                    }
                    
                    //self.progressView.performAction(M13ProgressViewActionSuccess, animated: true)
                }
            }
            catch let error as NSError {
                ui(.async) {
                    MessageBarManager.sharedInstance().showMessage(withTitle: "Import Points", description: error.localizedDescription, type: MessageBarMessageTypeError)
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
            
            CKContainer.default().publicCloudDatabase.add(op)
        }
        
        op.completionBlock = {
            
        }
        
        op.queryCompletionBlock = { cursor, error in
            
            if let error = error {
                
                ui(.async) {
                    MessageBarManager.sharedInstance().showMessage(withTitle: "Fetch Dump", description: error.localizedDescription, type: MessageBarMessageTypeError)
                    self.dismiss(animated: true, completion: .none)
                }
                
                print(error)
                
                return
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(op)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
            
        case "fractionCompleted"?:
            
            if let progress = object as? Progress {
                
                print("fraction: \(progress.fractionCompleted)")
                
                ui(.async) {
                    self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                    //progressView.setProgress(CGFloat(progress.fractionCompleted), animated: true)
                }
            }
            
        default:
            break
        }
    }
    
}
