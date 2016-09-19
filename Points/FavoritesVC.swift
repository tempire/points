//
//  FavoritesVC.swift
//  Points
//
//  Created by Glen Hinkle on 9/17/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

private struct RowSource {
    var dancer: Dancer
}

class FavoritesVC: UIViewController {

    var interactivePopTransition: UIPercentDrivenInteractiveTransition?
    
    fileprivate var rowSource: [RowSource] = []
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.scrollsToTop = true
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.allowsSelection = true
            tableView.estimatedRowHeight = 130
            tableView.rowHeight = UITableViewAutomaticDimension
            //tableView.delegate = self
            tableView.backgroundColor = UIColor.charcoal.dark
            
            let backgroundView = UIView()
            tableView.backgroundView = .none
            tableView.backgroundView = backgroundView
            backgroundView.backgroundColor = UIColor.charcoal.dark
            
            let barView = UIView()
            barView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.addSubview(barView)
            barView.backgroundColor = UIColor.charcoal.light
            barView.widthAnchor.constraint(equalToConstant: 2).isActive = true
            barView.topAnchor.constraint(equalTo: backgroundView.topAnchor).isActive = true
            barView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor).isActive = true
            barView.leftAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 84).isActive = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initializeRowSource()
    }
    
    func initializeRowSource() {
        do {
            rowSource = try Realm().allObjects(ofType: Dancer.self).filter(using: "favorite == true").map { dancer in
                
                RowSource(
                    dancer: dancer
                )
            }
            
            tableView.reloadData()
        }
        catch let error as NSError {
            print(error)
        }
    }
}

extension FavoritesVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueCell(FavoritesCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.delegate = self
        
        let dancer = rowSource[indexPath.row].dancer
        
        cell.favoritesButton.setImage(UIImage(asset: dancer.favorite ? .Glyphicons_50_Star : .Glyphicons_49_Star_Empty), for: .normal)
        
        cell.avatarPlaceholderView.backgroundColor = .lightGray
        cell.avatarInitialsLabel.text = dancer.name.firstLetters
        cell.nameLabel.text = dancer.name
        cell.rankLabel.text = dancer.rank.max.description
        cell.wsdcIdLabel.text = "\(dancer.id)"
        
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
        
        guard let identifier = segue.identifierType else {
            return
        }

        switch identifier {
            
        case .dancer:
            guard let vc = segue.destination as? DancerVC,
                let cell = sender as? FavoritesCell,
                let indexPath = tableView.indexPath(for: cell) else {
                    return
            }
            
            vc.dancer = rowSource[indexPath.row].dancer
            vc.peek = segue.identifier == "peek"
            
            tableView.deselectRow(at: indexPath, animated: true)

        case .partner, .firstPartner, .secondPartner, .division, .importer, .event:
            break
        }
    }
}


extension FavoritesVC: FavoritesCellDelegate {

    func didToggleFavorite(cell: UITableViewCell) {
        
        guard let row = tableView.indexPath(for: cell)?.row,
            let cell = cell as? FavoritesCell else {
                return
        }
        
        let source = rowSource[row]
        
        do {
            try Realm().write {
                source.dancer.favorite = !source.dancer.favorite
            }
        }
        catch let error as NSError {
            print(error)
        }
        
        cell.favoritesButton.setImage(UIImage(asset: source.dancer.favorite ? .Glyphicons_50_Star : .Glyphicons_49_Star_Empty), for: .normal)
    }
}

extension FavoritesVC: UIViewControllerTransitioningDelegate {
    
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

extension FavoritesVC: UINavigationControllerDelegate {
    
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

extension FavoritesVC {
    
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

protocol FavoritesCellDelegate: class {
    func didToggleFavorite(cell: UITableViewCell)
}

class FavoritesCell: UITableViewCell {
    
    weak var delegate: FavoritesCellDelegate?
    
    @IBOutlet weak var favoritesButton: UIButton!
    
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
    @IBOutlet weak var wsdcIdLabel: UILabel!
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
    
    @IBAction func toggleFavorite(_ sender: UIButton) {
        delegate?.didToggleFavorite(cell: self)
    }
}
