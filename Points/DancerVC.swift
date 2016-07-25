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
import MessageBarManager

enum CompetitionSort {
    case DivisionName
    case Date
    case Placement
    
    //var descriptors: [SortDescriptor] {
    var descriptors: String {
        
        switch self {
            
        case .DivisionName:
            return "divisionNameDisplayOrder"
            //return SortDescriptor(property: "divisionNameDisplayOrder", ascending: true)
            
        case .Date:
            return "year"
            //return SortDescriptor(property: "year", ascending: false)
            
        case .Placement:
            return "_result"
            //return SortDescriptor(property: "_role", ascending: true)
        }
    }
    
    var ascending: Bool {
        
        switch self {
            
        case .DivisionName:
            return true
            
        case .Date:
            return false
            
        case .Placement:
            return true
        }
    }
}

class DancerVC: UIViewController {
    var dancer: Dancer!
    
    var sort = CompetitionSort.DivisionName {
        didSet {
            print("Set sort to \(sort)")
            //sortButton.setTitle("\(sort)", forState: .Normal)
            updateScrollView()
            tableView.reloadDataWithDissolve()
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
        }
    }
    
    var competitions: Results<Competition> {
        return dancer.competitions.sorted(sort.descriptors, ascending: sort.ascending)
    }
    
    var peek: Bool = false
    
    @IBOutlet weak var rankLabel: UILabel! {
        didSet {
            rankLabel.text = dancer.rank.max.description
        }
    }
    @IBOutlet weak var dancerNameLabel: UILabel! {
        didSet {
            dancerNameLabel.text = dancer.name
        }
    }
    @IBOutlet weak var wsdcIdLabel: UILabel! {
        didSet {
            wsdcIdLabel.text = String(dancer.id)
        }
    }
    
    @IBOutlet weak var backgroundHeaderViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.image = UIImage.createAvatarPlaceholder(userFullName: dancer.name, placeholderSize: CGSize(width: 256, height: 256))
        }
    }
    @IBOutlet weak var sortButton: UIButton!
    
    lazy var divisionScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .lightGrayColor()
        view.scrollsToTop = false
        return view
    }()
    
    //@IBOutlet weak var divisionSummaryView: UIView!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.scrollsToTop = true
            tableView.dataSource = self
            tableView.estimatedRowHeight = 72
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.separatorStyle = .None
            tableView.allowsSelection = false
            
            //tableView.contentInset = UIEdgeInsets(top: 300, left: 0, bottom: 0, right: 0)
            //tableView.contentOffset = CGPoint(x: 0, y: -300)
            
            tableView.delegate = self
            
            /*
            // TableView background
            tableView?.backgroundView = .None
            let view = UIView()
            view.backgroundColor = UIColor.charcoal.dark
            let barView = UIView(frame: CGRect(x: 84, y: 0, width: 2, height: tableView.bounds.height))
            barView.backgroundColor = UIColor.charcoal.light
            view.addSubview(barView)
            
            tableView?.backgroundView = view
 */
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateScrollView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = peek ? .clearColor() : .darkGrayColor()
        peek = false
    }
    
    @IBAction func theThing(sender: UIButton) {
        print("theThing")
    }
    
    func updateScrollView() {
        
        divisionScrollView.subviews.forEach { $0.removeFromSuperview() }
        
        var titles = [String]()
        
        switch sort {
        case .DivisionName:
            titles = dancer.divisionNamesInDisplayOrder.map { $0.description }
            
        case .Date:
            titles = dancer
                .competitions
                .reduce(Set<Int>()) { tmp, comp in
                    var set = tmp
                    set.insert(comp.eventYear.year)
                    return set
                }
                .sort(>)
                .map { String($0) }
            
        case .Placement:
            titles = dancer
                .competitions
                .reduce(Set<WSDC.Competition.Result>()) { tmp, comp in
                    var set = tmp
                    set.insert(comp.result)
                    return set
                }
                .sort { $0.displayOrder < $1.displayOrder }
                .map { $0.description }
        }
        
        let buttons: [UIButton] = titles.map { title in
            
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.clipsToBounds = false
            divisionScrollView.addSubview(button)
            
            button.backgroundColor = .lightGrayColor()
            
            button.titleEdgeInsets = UIEdgeInsets(top: -16, left: 0, bottom: 0, right: 0)
            button.setTitleColor(.whiteColor(), forState: .Normal)
            button.addTarget(self, action: #selector(showDivisionComps(_:)), forControlEvents: .TouchUpInside)
            
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            
            let pointsStackView = UIStackView()
            pointsStackView.translatesAutoresizingMaskIntoConstraints = false
            pointsStackView.userInteractionEnabled = false
            pointsStackView.axis = .Horizontal
            pointsStackView.spacing = 4
            divisionScrollView.addSubview(pointsStackView)
            
            button.setTitle(title, forState: .Normal)
            
            /*
            let rolePoints = dancer.points(forDivision: divisionName)
            
            for role in rolePoints.filter({ $0.1 > 0 }).sort({ $0.1 > $1.1 }).map({ $0.0 }) {
            
                let label = InsetLabel(insets: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
                label.translatesAutoresizingMaskIntoConstraints = false
                label.userInteractionEnabled = false
                label.font = UIFont.systemFontOfSize(13)
                label.textColor = .whiteColor()
                label.backgroundColor = role == .Lead ? .lead  : .follow
                label.clipsToBounds = true
                label.layer.cornerRadius = 4
                label.text = String(rolePoints[role]!)
                pointsStackView.addArrangedSubview(label)
            }
            */
            
            pointsStackView.centerXAnchor.constraintEqualToAnchor(button.centerXAnchor).active = true
            divisionScrollView.bottomAnchor.constraintEqualToAnchor(pointsStackView.bottomAnchor, constant: 6).active = true
            
            return button
        }
        
        
       // divisionScrollView.topAnchor.constraintEqualToAnchor(self.backgroundHeaderView.bottomAnchor).active = true
        
        divisionScrollView.constrainEdgesHorizontally(buttons)
        divisionScrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
}

// MARK: Actions

extension DancerVC {

    func highlight(button button: UIButton) {
        
        UIView.animateWithDuration(
            0.15,
            animations: {
                
                for case let b as UIButton in self.divisionScrollView.subviews {
                    
                    if b.currentTitle == button.currentTitle {
                        b.backgroundColor = .darkGrayColor()
                        b.setTitleColor(.whiteColor(), forState: .Normal)
                    }
                    else {
                        b.backgroundColor = .lightGrayColor()
                        b.setTitleColor(.whiteColor(), forState: .Normal)
                    }
                }
                
                self.divisionScrollView.scrollRectToVisible(button.frame, animated: false)
            }
        )
    }
    
    func showDivisionComps(button: UIButton) {
        var row: Int?
        
        switch sort {
            
        case .DivisionName:
            if let divisionName = WSDC.DivisionName(description: button.currentTitle) {
                row = competitions.indexOf { $0.divisionName == divisionName }
            }
            
        case .Date:
            if let year = Int(button.currentTitle) {
                row = competitions.indexOf { $0.eventYear.year == year }
            }
            
        case .Placement:
            if let placementDescription = button.currentTitle {
                row = competitions.indexOf { $0.result.description == placementDescription }
            }
        }
        
        guard let _row = row else {
            MessageBarManager.sharedInstance().showMessageWithTitle("Sort Error", description: "Could not find rows for \(sort)", type: MessageBarMessageTypeError, duration: 10)
            return
        }
        
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: _row, inSection: 0), atScrollPosition: .Top, animated: true)
    }
}


extension DancerVC: UITableViewDataSource {
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return divisionScrollView
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return competitions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DancerCell.self, for: indexPath)
        let competition = competitions[indexPath.row]
        
        cell.competition = competition
        cell.resultLabel.text = competition.result.description
        cell.divisionNameLabel.text = competition.divisionName.description
        cell.eventNameLabel.text = competition.eventYear.event.name
        cell.eventDateLabel.text = competition.eventYear.date.shortMonthToString() + "\n" + String(competition.eventYear.date.year())
        cell.eventLocationLabel.text = competition.eventYear.event.location
        cell.pointsLabel.text = String(competition.points)
        cell.pointsCircleView.backgroundColor = competition.role == .Lead ? .lead : .follow
        
        cell.partnerRoleView.hidden = competition.partnerCompetition == .None
        
        cell.partnerRoleView.backgroundColor = competition.partnerCompetition?.role.color
        cell.partnerRoleLabel.text = competition.partnerCompetition?.role.tinyRaw.uppercaseString
        cell.partnerNameLabel.text = competition.partnerCompetition?.dancer.first?.name
        
        return cell
    }
}

extension DancerVC: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        //cell.contentView.layer.masksToBounds = false
        //cell.contentView.layer.shadowColor = UIColor.blackColor().CGColor
        //cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        //cell.contentView.layer.shadowPath = UIBezierPath(rect: cell.bounds).CGPath
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


// Scrollview delegate

extension DancerVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // Header button highlighting
        
        var title: String?
        
        var competition: Competition?
        
        if scrollView.contentOffset.y + 1 >= scrollView.contentSize.height - scrollView.frame.size.height {
            competition = competitions.last
        }
        else if let row = tableView.indexPathsForVisibleRows?.first?.row where competitions.count >= row {
            competition = competitions[row]
        }
        
        
        switch sort {
            
        case .DivisionName:
            title = competition?.divisionName.description
            
        case .Placement:
            title = competition?.result.description
            
        case .Date:
            title = String(competition?.year)
        }
        
        for case let button as UIButton in divisionScrollView.subviews where button.currentTitle == title {
            highlight(button: button)
            backgroundHeaderViewHeightConstraint.constant = max(56, 300 - tableView.contentOffset.y)
            view.setNeedsLayout()
            return
        }
        
    }
}


// MARK: Actions

extension DancerVC {
    @IBAction func sort(sender: UIButton) {
        
        switch sort {
            
        case .DivisionName:
            sort = .Date
            
        case .Date:
            sort = .Placement
            
        case .Placement:
            sort = .DivisionName
        }
    }
}

class DancerCell: UITableViewCell {
    weak var competition: Competition!
    
    @IBOutlet weak var pointsCircleView: UIView!
        {
        didSet {
            pointsCircleView.layer.borderColor = UIColor.charcoal.light.CGColor
        }
    }
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var divisionNameLabel: UILabel!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var eventDateLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var partnerContentView: UIView!
    @IBOutlet weak var partnerRoleView: UIView!
    @IBOutlet weak var partnerRoleLabel: UILabel!
    @IBOutlet weak var partnerNameLabel: UILabel!
    
    @IBAction func showEventLocation(sender: UIButton) {
        Maps.openAtAddress(competition.eventYear.event.location)
    }
}