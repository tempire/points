//
//  AdminVC.swift
//  Points
//
//  Created by Glen Hinkle on 7/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import CloudKit

var context = 0

class AdminVC: UIViewController {
    var wsdcGetOperation: WSDCGetOperation?
    var dumps: Results<Dump>?
    
    @IBOutlet weak var progressView: UIProgressView! {
        didSet {
            progressView.progress = 0
        }
    }
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressDetailLabel: UILabel!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    @IBAction func cancel(sender: UIButton) {
        guard let op = wsdcGetOperation else {
            return
        }
        
        op.state = .Cancelled
    }
    
    @IBAction func toggleWSDCGet(sender: UIButton) {
        
        guard let op = wsdcGetOperation else {
            startOp()
            cancelButton.hidden = false
            sender.setImage(UIImage(asset: .Glyphicons_175_Pause), forState: .Normal)
            return
        }
        
        if op.queue.suspended {
            // paused, set play
            
            cancelButton.hidden = true
            op.queue.suspended = false
            sender.setImage(UIImage(asset: .Glyphicons_175_Pause), forState: .Normal)
        }
            
        else {
            // playing, set paused
            
            cancelButton.hidden = false
            op.queue.suspended = true
            sender.setImage(UIImage(asset: .Glyphicons_174_Play), forState: .Normal)
        }
    }
    
    @IBAction func saveToCloudKit(sender: UIButton) {
        
    }
    
    var token: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let documentsDir = NSSearchPathForDirectoriesInDomains(
            NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask,
            true).first!
        
        /*
        do {
            let data = NSData(contentsOfFile: "\(documentsDir)/competitors.json")!
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [JSONObject]
            let competitors = try json.map { try WSDC.Competitor(json: $0) }
            
            let op = WSDCTransformOperation(competitors: competitors)
            NSOperationQueue().addOperation(op)
        }
        catch {
            print(error)
        }
 */
        
        navigationController?.delegate = self
        
        do {
            let realm = try Realm()
            dumps = realm.objects(Dump).sorted("date", ascending: false)
            
            token = dumps!.addNotificationBlock { changes in
                self.tableView?.reloadData()
            }
        }
        catch {
            print(error)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        guard let row = tableView.indexPathForSelectedRow?.row, dump = dumps?[row] else {
            return
        }
        
        switch segue.destinationViewController {
            
        case let vc as DumpVC:
            vc.dump = dump
            
        default:
            break
        }
    }
   
    func startOp() {
        
        let progress = NSProgress()
        
        progress.addObserver(self,
                             forKeyPath: "fractionCompleted",
                             options: [.Initial, .New, .Old],
                             context: &context
        )
        
        let op = WSDCGetOperation(maxConcurrentCount: 10, delegate: self, progress: progress)
        NSOperationQueue().addOperation(op)
        wsdcGetOperation = op
    }

}

extension AdminVC: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        navigationController.setNavigationBarHidden(viewController == self, animated: animated)
    }
}

extension AdminVC: WSDCGetOperationDelegate {
    
    func didCompleteCompetitorIdsRetrieval(operation: WSDCGetOperation, competitorIds: [Int]) {
        print("Retrieved \(competitorIds.count) ids")
    }
    
    func didCompleteCompetitorsRetrieval(operation: WSDCGetOperation, competitors: [WSDC.Competitor]) {
        print("Retrieved \(competitors.count) competitors")
        
        let documentsDir = NSSearchPathForDirectoriesInDomains(
            NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask,
            true).first!
        
        let folder = "\(documentsDir)/data/\(NSDate().toString)"
        
        do {
            try NSFileManager().createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: .None)
            
            var date = NSDate()
            let data = try WSDC.pack(competitors)
            print("SERIALIZATION TIME: \(NSDate().timeIntervalSinceDate(date))")
            
            data.writeToFile("\(folder)/serialized.data", atomically: true)
            
            date = NSDate()
            try Points.setup(data)
            print("DESERIALIZATION TIME: \(NSDate().timeIntervalSinceDate(date))")
        }
        catch {
            print(error)
        }
        
        /*
        operation.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &context)
        
        do {
            let realm = try Realm()
            let dump = try Dump(id: NSUUID(), date: NSDate(), version: 0, competitors: competitors)
            
            try realm.write {
                realm.add(dump, update: true)
            }
            
            CKContainer.defaultContainer().publicCloudDatabase.saveRecord(CKRecord.createDump(dump)) { record, error in
                if let error = error {
                    print(error)
                    return
                }
                
                print(record)
            }
        }
        catch {
            print(error)
        }
 */
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        switch keyPath {
            
        case "fractionCompleted"?:
            if let progress = object as? NSProgress {
                
                print("Seconds remaining: \(progress.userInfo[NSProgressThroughputKey])")
                ui(.Async) {
                    self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                    self.progressLabel.text = progress.localizedDescription
                    self.progressDetailLabel.text = progress.localizedAdditionalDescription
                }
            }
            
        default:
            break
        }
    }
}


extension AdminVC: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dumps?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DumpCell", forIndexPath: indexPath)
        
        guard let dump = dumps?[indexPath.row] else {
            return cell
        }
        
        cell.textLabel?.text = dump.date.toString
        cell.detailTextLabel?.text = "\(dump.data.length)"
        
        return cell
    }
}

extension AdminVC: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //
    }
}

