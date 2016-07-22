//
//  DancerVC.swift
//  Points
//
//  Created by Glen Hinkle on 7/19/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import CoreSpotlight

class DancerVC: UIViewController {
    var dancer: Dancer! {
        didSet {
            updateScrollView()
        }
    }
    
    var peek: Bool = false
    
    var results = [Competition]() {
        didSet {
            tableView?.reloadDataWithDissolve()
        }
    }
    
    override func viewDidLayoutSubviews() {
        wrapperView.clipsToBounds = false
        wrapperView.layer.masksToBounds = false
        wrapperView.layer.shadowColor = UIColor.blackColor().CGColor
        wrapperView.layer.shadowRadius = 6
        wrapperView.layer.shadowOpacity = 0.8
        wrapperView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        wrapperView.layer.shadowPath = UIBezierPath(rect: wrapperView.bounds).CGPath
        subWrapperView.frame = wrapperView.bounds
    }
    
    @IBOutlet weak var wrapperView: UIView! {
        didSet {
        }
    }
    
    @IBOutlet weak var subWrapperView: UIView! {
        didSet {
            subWrapperView.layer.cornerRadius = 6
            subWrapperView.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var divisionScrollView: UIScrollView!
    @IBOutlet weak var divisionSummaryView: UIView!
    @IBOutlet weak var divisionSummaryLabel: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.estimatedRowHeight = 72
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.separatorStyle = .None
            
            tableView.backgroundView = .None
            
            let view = UIView()
            view.backgroundColor = .darkGrayColor()
            
            let barView = UIView(frame: CGRect(x: 16, y: 0, width: 2, height: tableView.bounds.height))
            barView.backgroundColor = .whiteColor()
            view.addSubview(barView)
            
            tableView.backgroundView = view
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateScrollView()
    }
    
    override func viewWillAppear(animated: Bool) {
        print("VIEWWILLAPPEAR: \(peek)")
        view.backgroundColor = peek ? .clearColor() : .darkGrayColor()
        peek = false
        super.viewWillAppear(animated)
    }
    
    func updateScrollView() {
        guard let divisionScrollView = divisionScrollView else {
            return
        }
        
        var buttons = [UIButton]()
        
        divisionScrollView.subviews.forEach { $0.removeFromSuperview() }
        
        for (index, divisionName) in dancer.divisionNamesInDisplayOrder.enumerate() {
            let button = UIButton()
            
            button.setTitle(divisionName.description, forState: .Normal)
            button.addTarget(self, action: #selector(showDivisionComps(_:)), forControlEvents: .TouchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            divisionScrollView.addSubview(button)
            
            button.topAnchor.constraintEqualToAnchor(divisionScrollView.topAnchor).active = true
            button.bottomAnchor.constraintEqualToAnchor(divisionScrollView.bottomAnchor).active = true
            
            if index == 0 {
                button.leadingAnchor.constraintEqualToAnchor(divisionScrollView.leadingAnchor, constant: 16).active = true
            }
            else {
                button.leadingAnchor.constraintEqualToAnchor(buttons.last!.trailingAnchor, constant: 16).active = true
            }
            
            if index == dancer.divisionNamesInDisplayOrder.count - 1 {
                button.trailingAnchor.constraintEqualToAnchor(divisionScrollView.trailingAnchor).active = true
            }
            
            buttons.append(button)
        }
        
        if let button = buttons.first {
            showDivisionComps(button)
        }
    }
}

// MARK: Actions

extension DancerVC {

    func showDivisionComps(button: UIButton) {
        guard let divisionName = WSDC.DivisionName(description: button.currentTitle) else {
            return
        }
        
        for button in divisionScrollView.subviews.flatMap({ $0 as? UIButton }) {
            button.setTitleColor(.lightGrayColor(), forState: .Normal)
        }
        
        results = dancer.competitions.filter { $0.divisionName == divisionName }
        
        let divisionPoints = results.reduce(Int()) { aggregator, comp in
            return aggregator + comp.points
        }
        
        UIView.transitionWithView(divisionSummaryView,
                                  duration: 0.3,
                                  options: .TransitionCrossDissolve,
                                  animations: {
                                    self.divisionSummaryLabel.text = String(divisionPoints) + " " + divisionName.description + " points" },
                                  completion: { finished in }
        )
        
        button.setTitleColor(.whiteColor(), forState: .Normal)
    }
}


extension DancerVC: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DancerCell.self, for: indexPath)
        let competition = results[indexPath.row]
        
        cell.competition = competition
        cell.nameLabel.text = competition.result.description
        cell.eventNameLabel.text = competition.eventYear.event.name
        cell.eventDateLabel.text = competition.eventYear.date.toString(format: .WSDCEventMonth)
        cell.eventLocationButton.setTitle(competition.eventYear.event.location, forState: .Normal)
        cell.pointsLabel.text = String(competition.points)
        
        return cell
    }
}

extension DancerVC: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        cell.contentView.layer.masksToBounds = false
        cell.contentView.layer.shadowColor = UIColor.blackColor().CGColor
        cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        cell.contentView.layer.shadowPath = UIBezierPath(rect: cell.bounds).CGPath
    }
}

// Open from spotlight

extension DancerVC {
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        guard activity.activityType == CSSearchableItemActionType else {
            return
        }
        
        let realm = try! Realm()
        
        if let value = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            dancerId = Int(value),
            dancer = realm.objects(Dancer).filter("id = %d", dancerId).first {
            self.dancer = dancer
        }
    }
}

class DancerCell: UITableViewCell {
    weak var competition: Competition!
    
    @IBOutlet weak var leftCenterCircleView: UIView! {
        didSet {
            leftCenterCircleView.layer.cornerRadius = leftCenterCircleView.bounds.width / 2
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationButton: UIButton!
    @IBOutlet weak var eventDateLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
    @IBAction func showEventLocation(sender: UIButton) {
        Maps.openAtAddress(competition.eventYear.event.location)
    }
}