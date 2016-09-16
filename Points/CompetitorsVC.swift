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
    
    var highlightedIndexPath: IndexPath?
    
    var filterString: String? {
        didSet {
            let objects = try! Realm().allObjects(ofType: Dancer.self)
            
            var predicate = NSPredicate.all
            
            if let filterString = filterString, let int = Int(filterString) {
                predicate = NSPredicate(format: "id = %d", int)
            }
            else if let filterString = filterString {
                predicate = NSPredicate(format: "name CONTAINS[c] %@ OR _maxRank BEGINSWITH %@", filterString, filterString)
            }
            
            results = objects.filter(using: predicate)
        }
    }
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.keyboardDismissMode = .interactive
            //tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
            tableView.estimatedRowHeight = 66
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.separatorStyle = .none
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()
        
        results = realm.allObjects(ofType: Dancer.self)
        
        token = results.addNotificationBlock { note in
            self.tableView?.reloadData()
        }
        
        navigationController?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        if self.results.count == 0 {
            self.performSegueWithVC(ImportVC.self, sender: self)
        }
    }
    
    deinit {
        print("-DEINIT \(type(of: self))")
    }
}

extension CompetitorsVC {
    @IBAction func search(_ sender: UITextField) {
        filterString = sender.text
    }
}

extension CompetitorsVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(CompetitorsCell.self, for: indexPath)
        let dancer = results[indexPath.row]
        
        //cell.avatarImageView.image = UIImage.createAvatarPlaceholder(userFullName: dancer.name, placeholderSize: CGSize(width: 44, height: 44))
        cell.avatarPlaceholderView.backgroundColor = .lightGray
        cell.avatarInitialsLabel.text = dancer.name.firstLetters
        cell.nameLabel.text = dancer.name
        cell.rankLabel.text = dancer.rank.max.description
        
        let points = dancer.points(forDivision: dancer.rank.max)
        cell.divisionLeadPointsLabel.isHidden = points[.Lead] == 0
        cell.divisionLeadPointsLabel.text = "\(points[.Lead]!)"
        cell.divisionFollowPointsLabel.isHidden = points[.Follow] == 0
        cell.divisionFollowPointsLabel.text = "\(points[.Follow]!)"
        
        return cell
    }
    
    override var previewActionItems : [UIPreviewActionItem] {
        return [
            UIPreviewAction(title: "Bookmark", style: .selected, handler: { action, vc in
            }),
            
            UIPreviewAction(title: "Cancel", style: .default, handler: { action, vc in
            })
        ]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.destination {
            
        case let vc as DancerVC:
            guard let cell = sender as? CompetitorsCell,
                let indexPath = tableView.indexPath(for: cell) else {
                    return
            }

            vc.dancer = results[indexPath.row]
            vc.peek = segue.identifier == "peek"
            print("SETTING PEEK TO \(vc.peek)")
            
            //tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
            
            tableView.deselectRow(at: indexPath, animated: true)

        case let vc as ImportVC:
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = self
            
        default:
            break
        }
    }
    
}

extension CompetitorsVC: UIViewControllerTransitioningDelegate {
    
    internal func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        return ModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    internal func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return .none
    }
    
    internal func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return .none
    }
}

extension CompetitorsVC: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleNVCPopPanGesture(_:)))
        navigationController.view.addGestureRecognizer(pan)
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == UINavigationControllerOperation.pop {
            return PopTransitionController()
        }
        
        return .none
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        return interactivePopTransition
    }
}

// Navigation Controller pop pan gesture

extension CompetitorsVC {
    
    func handleNVCPopPanGesture(_ recognizer: UIPanGestureRecognizer) {
        let coords = recognizer.translation(in: view)
        let progress = coords.x / (view.bounds.size.width * 1)
        let direction: TransitionDirection = coords.x < 0 ? .left : .right
        let axis: TransitionAxis = fabs(coords.x) > fabs(coords.y) ? .horizontal : .vertical
        
        switch recognizer.state {
        case .began:
            if direction == .right {
                interactivePopTransition = UIPercentDrivenInteractiveTransition()
                _ = navigationController?.popViewController(animated: true)
            }
            
        case .changed:
            interactivePopTransition?.update(progress)
            
        case .ended, .cancelled:
            let containerView = view
            
            if axis == .vertical {
                interactivePopTransition?.cancel()
                interactivePopTransition = .none
                return
            }
            
            let exceededVelocityThreshold = recognizer.velocity(in: containerView).x > 250
            
            if exceededVelocityThreshold || progress > 0.5 {
                interactivePopTransition?.finish()
            }
            else {
                interactivePopTransition?.cancel()
            }
            interactivePopTransition = .none
            
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
