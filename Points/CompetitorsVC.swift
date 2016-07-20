//
//  CompetitorsVC.swift
//  Points
//
//  Created by Glen Hinkle on 7/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import MessageBarManager

class CompetitorsVC: UIViewController {
    var token: NotificationToken?
    
    var results: Results<Dancer>! {
        didSet {
            tableView?.reloadDataWithDissolve()
        }
    }
    
    var highlightedIndexPath: NSIndexPath?
    
    var filterString: String? {
        didSet {
            let objects = try! Realm().objects(Dancer)
            
            var predicate = NSPredicate.all
            
            if let filterString = filterString, int = Int(filterString) {
                predicate = NSPredicate(format: "id = %d", int)
            }
            else if let filterString = filterString {
                predicate = NSPredicate(format: "name CONTAINS[c] %@ OR _maxRank BEGINSWITH %@", filterString, filterString)
            }
            
            results = objects.filter(predicate)
        }
    }
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        results = try! Realm().objects(Dancer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
        tableView?.reloadData()
        
        if self.results.count == 0 {
            self.performSegueWithVC(ImportVC.self, sender: self)
        }
    }
}

extension CompetitorsVC {
    @IBAction func search(sender: UITextField) {
        filterString = sender.text
    }
}

extension CompetitorsVC: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(CompetitorsCell.self, for: indexPath)
        let dancer = results[indexPath.row]
        
        cell.nameLabel.text = dancer.name
        cell.rankLabel.text = dancer.rank.max.description
        
        return cell
    }
    
    override func previewActionItems() -> [UIPreviewActionItem] {
        return [
            UIPreviewAction(title: "Bookmark", style: .Selected, handler: { action, vc in
            }),
            
            UIPreviewAction(title: "Cancel", style: .Default, handler: { action, vc in
            })
        ]
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.destinationViewController {
            
        case let vc as DancerVC:
            guard let cell = sender as? CompetitorsCell,
                indexPath = tableView.indexPathForCell(cell) else {
                    return
            }

            vc.dancer = results[indexPath.row]
            
        case let vc as ImportVC:
            vc.modalPresentationStyle = .Custom
            vc.transitioningDelegate = self
            
        default:
            break
        }
        
        //tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
    }
    
}

extension CompetitorsVC: UIViewControllerTransitioningDelegate {
    
    internal func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        
        return ModalPresentationController(presentedViewController: presented, presentingViewController: presenting)
        //return presented == self
        //    ? ModalPresentationController(presentedViewController: presented, presentingViewController: presenting)
        //    : .None
    }
    
    internal func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return ModalAnimationController(presenting: true)
        //return presented == self
        //    ? ModalAnimationController(presenting: true)
        //    : .None
    }
    
    internal func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed == self
            ? ModalAnimationController(presenting: false)
            : .None
    }
}

class CompetitorsCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var rankLabel: UILabel!
}