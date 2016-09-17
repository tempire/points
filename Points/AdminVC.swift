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
    
    @IBAction func cancel(_ sender: UIButton) {
        guard let op = wsdcGetOperation else {
            return
        }
        
        op.cancel()
        print(op.state)
        //op.state = .Cancelled
    }
    
    @IBAction func toggleWSDCGet(_ sender: UIButton) {
        
        guard let op = wsdcGetOperation else {
            startOp()
            cancelButton.isHidden = false
            sender.setImage(UIImage(asset: .Glyphicons_175_Pause), for: UIControlState())
            return
        }
        
        if op.queue.isSuspended {
            // paused, set play
            
            cancelButton.isHidden = true
            op.queue.isSuspended = false
            sender.setImage(UIImage(asset: .Glyphicons_175_Pause), for: UIControlState())
        }
            
        else {
            // playing, set paused
            
            cancelButton.isHidden = false
            op.queue.isSuspended = true
            sender.setImage(UIImage(asset: .Glyphicons_174_Play), for: UIControlState())
        }
    }
    
    @IBAction func saveToCloudKit(_ sender: UIButton) {
        
    }
    
    var token: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        
        do {
            let realm = try Realm()
            dumps = realm.allObjects(ofType: Dump.self).sorted(onProperty: "date", ascending: false)
            
            token = dumps.addNotificationBlock { changes in
                self.tableView?.reloadData()
            }
        }
        catch let error as NSError {
            ui(.async) {
                MessageBarManager.sharedInstance().showMessage(withTitle: "Show", description: error.localizedDescription, type: MessageBarMessageTypeError, duration: 60)
            }
            
            print(error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let row = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row, let dump = dumps?[row] else {
            return
        }
        
        switch segue.destination {
            
        case let vc as DumpVC:
            vc.dump = dump
            
        default:
            break
        }
    }
   
    func startOp() {
        
        let progress = Progress()
        
        progress.cancellationHandler = {
            progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &context)
            self.wsdcGetOperation?.cancel()
        }

        progress.addObserver(self,
                             forKeyPath: "fractionCompleted",
                             options: [.initial, .new, .old],
                             context: &context
        )
        
        let op = WSDCGetOperation(maxConcurrentCount: 10, delegate: self, progress: progress)
        OperationQueue().addOperation(op)
        wsdcGetOperation = op
        
    }

}

extension AdminVC: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.setNavigationBarHidden(viewController == self, animated: animated)
    }
}

extension AdminVC: WSDCGetOperationDelegate {
    
    func errorReported(_ operation: WSDCGetOperation, error: NSError, requeuing: Bool) {
        ui(.async) {
            MessageBarManager.sharedInstance().showMessage(withTitle: "Sync", description: error.localizedDescription, type: requeuing ? MessageBarMessageTypeInfo : MessageBarMessageTypeError, duration: 60)
        }
        
        print(error)
        print(error.localizedDescription)
        
        if !requeuing {
            operation.cancel()
        }
    }
    
    func shouldRequeueAfterError(_ operation: WSDCGetOperation, error: NSError, competitorId: Int) -> Bool {
        return true
    }
    
    func didCancelOperation(_ operation: WSDCGetOperation, competitors: [WSDC.Competitor]) {
        
        var message = "Cancelled when \(operation.progress.localizedDescription)"
        
        if let error = operation.errors.last {
            message += " \(error.localizedDescription)"
        }
        
        ui(.async) {
            UIView.transition(with: self.view,
                                      duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        self.cancelButton.isHidden = true
                                        self.progressLabel.text = message
                                        self.playButton.setImage(UIImage(asset: .Glyphicons_174_Play), for: UIControlState()) },
                                      completion: { finished in
                                        self.wsdcGetOperation = .none }
            )
        }
        
        ui(.async, afterDelay: 10) {
            
            if self.wsdcGetOperation != .none {
                return
            }
            
            UIView.transition(with: self.view,
                                      duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        self.progressLabel.text = .none
                                        self.progressDetailLabel.text = .none },
                                      completion: { finished in }
            )
        }
    }

    func didCompleteCompetitorIdsRetrieval(_ operation: WSDCGetOperation, competitorIds: [Int], completion: @escaping (Void) -> Void) {
        progressLabel.text = "Retrieved \(competitorIds.count) ids"

        delay(2, dispatch: .async, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)) {
            completion()
        }
    }
    
    /*
    func didCompleteCompetitorIdsRetrieval(_ operation: WSDCGetOperation, competitorIds: [Int], completion: @escaping (Void)->Void){
        progressLabel.text = "Retrieved \(competitorIds.count) ids"
        
        delay(2, dispatch: .async, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)) {
            completion()
        }
    }
    */
    
    func didCompleteCompetitorsRetrieval(_ operation: WSDCGetOperation, competitors: [WSDC.Competitor]) {
        //
    }
    
    func didPackRetrievedData(_ operation: WSDCGetOperation, data: Data) {
        do {
            operation.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &context)
            
            // Write to database
            let realm = try Realm()
            let dump = try Dump(id: UUID(), date: Date(), version: 0, data: data)
            
            try realm.write {
                realm.deleteAllObjects()
                realm.add(dump, update: true)
                
                ui(.async) {
                    let vc = Storyboard.Main.viewController(ImportVC.self)
                    vc.dump = dump
                    self.present(vc, animated: true, completion: .none)
                }
            }
            
            // Save to cloudkit
            CKContainer.default().publicCloudDatabase.save(CKRecord.createDump(dump), completionHandler: { record, error in
                if let error = error {
                    
                    ui(.async) {
                        MessageBarManager.sharedInstance().showMessage(withTitle: "CloudKit Save", description: error.localizedDescription, type: MessageBarMessageTypeError, duration: 60)
                    }
                    
                    print(error)
                }
            }) 
        }
        catch let error as NSError {
            MessageBarManager.sharedInstance().showMessage(withTitle: "Load", description: error.localizedDescription, type: MessageBarMessageTypeError, duration: 60)
            
            print(error)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
            
        case "fractionCompleted"?:
            if let progress = object as? Progress {
                
                ui(.async) {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dumps?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DumpCell", for: indexPath)
        
        guard let dump = dumps?[indexPath.row] else {
            return cell
        }
        
        cell.textLabel?.text = dump.date.toString
        cell.detailTextLabel?.text = "\(dump.data.count)"
        
        return cell
    }
}

extension AdminVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
    }
}

