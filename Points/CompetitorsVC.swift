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
    
    var interactivePopTransition: UIPercentDrivenInteractiveTransition?
    
    var token: NotificationToken?
    var token2: NotificationToken?
    
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
            tableView.keyboardDismissMode = .Interactive
            //tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
            tableView.estimatedRowHeight = 66
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.separatorStyle = .None
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()
        
        results = realm.objects(Dancer)
        
        token = results.addNotificationBlock { note in
            self.tableView?.reloadData()
        }
        
        navigationController?.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    
        if self.results.count == 0 {
            self.performSegueWithVC(ImportVC.self, sender: self)
        }
    }
    
    deinit {
        print("-DEINIT \(self.dynamicType)")
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
        
        //cell.avatarImageView.image = UIImage.createAvatarPlaceholder(userFullName: dancer.name, placeholderSize: CGSize(width: 44, height: 44))
        cell.avatarPlaceholderView.backgroundColor = .lightGrayColor()
        cell.avatarInitialsLabel.text = dancer.name.firstLetters
        cell.nameLabel.text = dancer.name
        cell.rankLabel.text = dancer.rank.max.description
        
        let points = dancer.points(forDivision: dancer.rank.max)
        cell.divisionLeadPointsLabel.hidden = points[.Lead] == 0
        cell.divisionLeadPointsLabel.text = String(points[.Lead]!)
        cell.divisionFollowPointsLabel.hidden = points[.Follow] == 0
        cell.divisionFollowPointsLabel.text = String(points[.Follow]!)
        
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
            vc.peek = segue.identifier == "peek"
            print("SETTING PEEK TO \(vc.peek)")
            
            //tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)

        case let vc as ImportVC:
            vc.modalPresentationStyle = .Custom
            vc.transitioningDelegate = self
            
        default:
            break
        }
    }
    
}

extension CompetitorsVC: UIViewControllerTransitioningDelegate {
    
    internal func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        
        return ModalPresentationController(presentedViewController: presented, presentingViewController: presenting)
    }
    
    internal func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return .None
    }
    
    internal func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return .None
    }
}

extension CompetitorsVC: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleNVCPopPanGesture(_:)))
        navigationController.view.addGestureRecognizer(pan)
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == UINavigationControllerOperation.Pop {
            return PopTransitionController()
        }
        
        return .None
    }
    
    func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        return interactivePopTransition
    }
}

// Navigation Controller pop pan gesture

extension CompetitorsVC {
    
    func handleNVCPopPanGesture(recognizer: UIPanGestureRecognizer) {
        let coords = recognizer.translationInView(view)
        let progress = coords.x / (view.bounds.size.width * 1)
        let direction: TransitionDirection = coords.x < 0 ? .Left : .Right
        let axis: TransitionAxis = fabs(coords.x) > fabs(coords.y) ? .Horizontal : .Vertical
        
        switch recognizer.state {
        case .Began:
            if direction == .Right {
                interactivePopTransition = UIPercentDrivenInteractiveTransition()
                navigationController?.popViewControllerAnimated(true)
            }
            
        case .Changed:
            interactivePopTransition?.updateInteractiveTransition(progress)
            
        case .Ended, .Cancelled:
            let containerView = view
            
            if axis == .Vertical {
                interactivePopTransition?.cancelInteractiveTransition()
                interactivePopTransition = .None
                return
            }
            
            let exceededVelocityThreshold = recognizer.velocityInView(containerView).x > 250
            
            if exceededVelocityThreshold || progress > 0.5 {
                interactivePopTransition?.finishInteractiveTransition()
            }
            else {
                interactivePopTransition?.cancelInteractiveTransition()
            }
            interactivePopTransition = .None
            
        default:
            break
        }
    }
}

class CompetitorsCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarPlaceholderView: UIView! {
        didSet {
            avatarPlaceholderView.layer.cornerRadius = 44 / 2
            avatarPlaceholderView.clipsToBounds = true
        }
    }
    @IBOutlet weak var avatarInitialsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var divisionLeadPointsLabel: InsetLabel! {
        didSet {
            divisionLeadPointsLabel.insets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        }
    }
    @IBOutlet weak var divisionFollowPointsLabel: InsetLabel! {
        didSet {
            divisionFollowPointsLabel.insets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        }
    }
}