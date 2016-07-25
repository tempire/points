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
import MessageBarManager

var context = 0

class AdminVC: UIViewController {
    var wsdcGetOperation: WSDCGetOperation?
    var dumps: Results<Dump>!
    
    @IBOutlet weak var progressView: UIProgressView! {
        didSet {
            progressView.progress = 0
        }
    }
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressDetailLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    
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
        
        op.cancel()
        print(op.state)
        //op.state = .Cancelled
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
        
        navigationController?.delegate = self
        
        do {
            let realm = try Realm()
            dumps = realm.objects(Dump).sorted("date", ascending: false)
            
            token = dumps.addNotificationBlock { changes in
                self.tableView?.reloadData()
            }
        }
        catch let error as NSError {
            ui(.Async) {
                MessageBarManager.sharedInstance().showMessageWithTitle("Show", description: error.localizedDescription, type: MessageBarMessageTypeError, duration: 60)
            }
            
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
        
        progress.cancellationHandler = {
            progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &context)
            self.wsdcGetOperation?.cancel()
        }

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
    
    func errorReported(operation: WSDCGetOperation, error: NSError, requeuing: Bool) {
        ui(.Async) {
            MessageBarManager.sharedInstance().showMessageWithTitle("Sync", description: error.localizedDescription, type: requeuing ? MessageBarMessageTypeInfo : MessageBarMessageTypeError, duration: 60)
        }
        
        print(error)
        print(error.localizedDescription)
        
        if !requeuing {
            operation.cancel()
        }
    }
    
    func shouldRequeueAfterError(operation: WSDCGetOperation, error: NSError, competitorId: Int) -> Bool {
        return true
    }
    
    func didCancelOperation(operation: WSDCGetOperation, competitors: [WSDC.Competitor]) {
        
        var message = "Cancelled when \(operation.progress.localizedDescription)"
        
        if let error = operation.errors.last {
            message += " \(error.localizedDescription)"
        }
        
        ui(.Async) {
            UIView.transitionWithView(self.view,
                                      duration: 0.3,
                                      options: .TransitionCrossDissolve,
                                      animations: {
                                        self.cancelButton.hidden = true
                                        self.progressLabel.text = message
                                        self.playButton.setImage(UIImage(asset: .Glyphicons_174_Play), forState: .Normal) },
                                      completion: { finished in
                                        self.wsdcGetOperation = .None }
            )
        }
        
        ui(.Async, afterDelay: 10) {
            
            if self.wsdcGetOperation != .None {
                return
            }
            
            UIView.transitionWithView(self.view,
                                      duration: 0.3,
                                      options: .TransitionCrossDissolve,
                                      animations: {
                                        self.progressLabel.text = .None
                                        self.progressDetailLabel.text = .None },
                                      completion: { finished in }
            )
        }
    }
    
    func didCompleteCompetitorIdsRetrieval(operation: WSDCGetOperation, competitorIds: [Int], completion: Void->Void){
        progressLabel.text = "Retrieved \(competitorIds.count) ids"
        
        delay(2, dispatch: .Async, queue: dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            completion()
        }
    }
    
    func didCompleteCompetitorsRetrieval(operation: WSDCGetOperation, competitors: [WSDC.Competitor]) {
        //
    }
    
    func didPackRetrievedData(operation: WSDCGetOperation, data: NSData) {
        do {
            operation.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &context)
            
            // Write to database
            let realm = try Realm()
            let dump = try Dump(id: NSUUID(), date: NSDate(), version: 0, data: data)
            
            try realm.write {
                realm.add(dump, update: true)
            }
            
            // Save to cloudkit
            CKContainer.defaultContainer().publicCloudDatabase.saveRecord(CKRecord.createDump(dump)) { record, error in
                if let error = error {
                    
                    ui(.Async) {
                        MessageBarManager.sharedInstance().showMessageWithTitle("CloudKit Save", description: error.localizedDescription, type: MessageBarMessageTypeError, duration: 60)
                    }
                    
                    print(error)
                }
            }
        }
        catch let error as NSError {
            MessageBarManager.sharedInstance().showMessageWithTitle("Load", description: error.localizedDescription, type: MessageBarMessageTypeError, duration: 60)
            
            print(error)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        switch keyPath {
            
        case "fractionCompleted"?:
            if let progress = object as? NSProgress {
                
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

