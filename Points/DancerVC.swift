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
import MGSwipeTableCell

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
    var cellHeights = [CGFloat]()
    
    var sort = CompetitionSort.DivisionName {
        didSet {
            updateHeaderScrollView()
            tableView.reloadDataWithDissolve()
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
        }
    }
    
    var competitions: Results<Competition> {
        return dancer.competitions.sorted(sort.descriptors, ascending: sort.ascending)
    }
    
    var peek: Bool = false
    
    var dancerNameLabelHeight = CGFloat(0)
    var dancerNameLabelTransitionInProgress = false
    
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
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.scrollsToTop = true
            tableView.dataSource = self
            tableView.separatorStyle = .None
            tableView.allowsSelection = true
            tableView.estimatedRowHeight = 115
            tableView.delegate = self
            tableView.backgroundColor = UIColor.charcoal.dark
            
            let backgroundView = UIView()
            tableView.backgroundView = .None
            tableView.backgroundView = backgroundView
            backgroundView.backgroundColor = UIColor.charcoal.dark
            
            let barView = UIView()
            barView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.addSubview(barView)
            barView.backgroundColor = UIColor.charcoal.light
            barView.widthAnchor.constraintEqualToConstant(2).active = true
            barView.topAnchor.constraintEqualToAnchor(backgroundView.topAnchor).active = true
            barView.bottomAnchor.constraintEqualToAnchor(backgroundView.bottomAnchor).active = true
            barView.leftAnchor.constraintEqualToAnchor(backgroundView.leftAnchor, constant: 84).active = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeCellHeights()
        updateHeaderScrollView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setBackgroundColor()
        tableView.reloadData()
        //scrollViewDidScroll(tableView)
    }
    
    func initializeCellHeights() {
        let count = competitions.count * 2
        (0..<count).forEach { index in
            cellHeights.append(index % 2 == 0 ? UITableViewAutomaticDimension : 0)
        }
    }
    
    func setBackgroundColor() {
        view.backgroundColor = peek ? .clearColor() : .darkGrayColor()
        peek = false
    }
    
    func updateHeaderScrollView() {
        
        divisionScrollView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        var headers: [(title: String, subTitle: String)] = []
        
        switch sort {
            
        case .DivisionName:
            headers = dancer.divisionNamesInDisplayOrder.map {
                (
                    title: $0.description,
                    subTitle: String(dancer.points(forDivision: $0).values.reduce(0, combine: +))
                )
            }
            
        case .Date:
            headers = dancer
                .competitions
                .reduce([:]) { tmp, comp -> [Int:Int] in
                    var dict = tmp
                    
                    print("COMPNAME: \(comp.eventYear.event.name), EVENTYEAR: \(comp.eventYear.year), PARTNER: \(comp.partnerCompetition?.dancer.first?.name ?? "")")
                    
                    print(dict)
                    
                    if dict[comp.eventYear.year] == nil {
                        dict[comp.eventYear.year] = 0
                    }
                    
                    dict[comp.eventYear.year]! += 1
                    
                    return dict
                }
                .sort(>)
                .map {
                    let title = String($0.0)
                    let subTitle = String($0.1)
                    return (title: title, subTitle: subTitle)
            }
            
        case .Placement:
            headers = dancer
                .competitions
                .reduce([:]) { tmp, comp -> [WSDC.Competition.Result:Int] in
                    
                    var dict = tmp
                    
                    if dict[comp.result] == nil {
                        dict[comp.result] = 0
                    }
                    
                    dict[comp.result]! += 1
                    
                    return dict
                }
                .sort { $0.0.displayOrder < $1.0.displayOrder }
                .map { (title: $0.0.description, subTitle: String($0.1)) }
        }
        
        let buttons: [UIButton] = headers.map { header in
            
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            divisionScrollView.addSubview(button)
            
            button.backgroundColor = .lightGrayColor()
            
            button.titleEdgeInsets = UIEdgeInsets(top: -16, left: 0, bottom: 0, right: 0)
            button.setTitleColor(.whiteColor(), forState: .Normal)
            button.addTarget(self, action: #selector(showDivisionComps(_:)), forControlEvents: .TouchUpInside)
            
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            
            button.setTitle(header.title, forState: .Normal)
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = header.subTitle
            button.addSubview(label)
            label.bottomAnchor.constraintEqualToAnchor(button.bottomAnchor, constant: -4).active = true
            label.centerXAnchor.constraintEqualToAnchor(button.centerXAnchor).active = true
            
            return button
        }
        
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
                        b.highlighted = true
                    }
                    else {
                        b.backgroundColor = .lightGrayColor()
                        b.setTitleColor(.whiteColor(), forState: .Normal)
                        b.highlighted = false
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
        return competitions.count * 2
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
        //return UITableViewAutomaticDimension
        //return 115
        //if indexPath.row % 2 == 0 || detailsCellVisible[indexPath.row] {
        ////if isMainCell(indexPath) || isVisibleDetailsCell(indexPath) {
        //    return 72 //return UITableViewAutomaticDimension
        //}
        //
        //return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = isMainCell(indexPath)
            ? tableView.dequeueCell(DancerCompCell.self, for: indexPath)
            : tableView.dequeueCell(DancerCompDetailsCell.self, for: indexPath)
        
        //isMainCell(indexPath)
        //    ? dancerCompCell(cell as! DancerCompCell, competition: competition(forIndexPath: indexPath), indexPath: indexPath)
        //    : dancerCompDetailsCell(cell as! DancerCompDetailsCell, competition: competition(forIndexPath: indexPath), indexPath: indexPath)
        
        //cell.contentView.setNeedsLayout()
        //cell.contentView.layoutIfNeeded()
        
        return cell
    }
    
    func dancerCompCell(cell: DancerCompCell, competition: Competition, indexPath: NSIndexPath) -> DancerCompCell {
    
        cell.competition = competition
        //cell.resultLabel.text = "main"
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
        
        // Swipe
        
        var buttons = [
            MGSwipeButton(.Event, backgroundColor: .darkGrayColor()),
            MGSwipeButton(.Competition, backgroundColor: .darkGrayColor())
        ]
        
        if competition.partnerCompetition != .None {
            buttons = [MGSwipeButton(.Partner, backgroundColor: view.tintColor)] + buttons
        }
        
        cell.rightButtons = buttons.map { button in
            button.centerIconOverText()
            button.setEdgeInsets(UIEdgeInsetsZero)
            return button
        }
        
        cell.rightSwipeSettings.transition = .Drag
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        cell.delegate = self
        
        return cell
    }
    
    func dancerCompDetailsCell(cell: DancerCompDetailsCell, competition: Competition, indexPath: NSIndexPath) -> DancerCompDetailsCell {
        
        //cell.competition = competition
        cell.resultLabel.text = "details" //competition.result.description
        //cell.divisionNameLabel.text = competition.divisionName.description
        //cell.eventNameLabel.text = competition.eventYear.event.name
        //cell.eventDateLabel.text = competition.eventYear.date.shortMonthToString() + "\n" + String(competition.eventYear.date.year())
        //cell.eventLocationLabel.text = competition.eventYear.event.location
        //cell.pointsLabel.text = String(competition.points)
        //cell.pointsCircleView.backgroundColor = competition.role == .Lead ? .lead : .follow
        //
        //cell.partnerRoleView.hidden = competition.partnerCompetition == .None
        //
        //cell.partnerRoleView.backgroundColor = competition.partnerCompetition?.role.color
        //cell.partnerRoleLabel.text = competition.partnerCompetition?.role.tinyRaw.uppercaseString
        //cell.partnerNameLabel.text = competition.partnerCompetition?.dancer.first?.name
        
        return cell
        
        // Swipe
        
        var buttons = [
            MGSwipeButton(.Event, backgroundColor: .darkGrayColor()),
            MGSwipeButton(.Competition, backgroundColor: .darkGrayColor())
        ]
        
        if competition.partnerCompetition != .None {
            buttons = [MGSwipeButton(.Partner, backgroundColor: view.tintColor)] + buttons
        }
        
        cell.rightButtons = buttons.map { button in
            button.centerIconOverText()
            button.setEdgeInsets(UIEdgeInsetsZero)
            return button
        }
        
        cell.rightSwipeSettings.transition = .Drag
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        cell.delegate = self
        
        return cell
    }
}


extension DancerVC: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        isMainCell(indexPath)
            ? dancerCompCell(cell as! DancerCompCell, competition: competition(forIndexPath: indexPath), indexPath: indexPath)
            : dancerCompDetailsCell(cell as! DancerCompDetailsCell, competition: competition(forIndexPath: indexPath), indexPath: indexPath)
        
        //cell.contentView.layer.masksToBounds = false
        //cell.contentView.layer.shadowColor = UIColor.blackColor().CGColor
        //cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        //cell.contentView.layer.shadowPath = UIBezierPath(rect: cell.bounds).CGPath
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard isMainCell(indexPath) else {
            return
        }
        
        let detailsCellIndexPath = self.detailsCellIndexPath(forIndexPath: indexPath)
        
        cellHeights[detailsCellIndexPath.row] = cellHeights[detailsCellIndexPath.row] == 0 ? UITableViewAutomaticDimension : 0
        //detailsCellVisible[detailsCellIndexPath.row] = !detailsCellVisible[detailsCellIndexPath.row]
        
        tableView.reloadRowsAtIndexPaths([detailsCellIndexPath], withRowAnimation: .Automatic)
    }
}


// MARK: Table Cell utility methods

extension DancerVC {
    func isMainCell(indexPath: NSIndexPath) -> Bool {
        return indexPath.row % 2 == 0
    }
    
    func detailsCellIndexPath(forIndexPath indexPath: NSIndexPath) -> NSIndexPath {
        return indexPath.row % 2 == 0 ? indexPath.nextRow : indexPath
    }
}


extension DancerVC: MGSwipeTableCellDelegate {
   
    func swipeTableCellWillBeginSwiping(cell: MGSwipeTableCell) {
        //for case let button as MGSwipeButton in cell.rightButtons {
        //}
    }
    
    func swipeTableCell(cell: MGSwipeTableCell, tappedButtonAtIndex index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        
        guard let indexPath = tableView.indexPathForCell(cell) else {
            return false
        }
        
        switch MGSwipeButton.SwipeButton(index) {
            
        case .None:
            break
            
        case .Partner?:
            if let dancer = competition(forIndexPath: indexPath).partnerCompetition?.dancer.first {
                let vc = Storyboard.Main.viewController(DancerVC)
                vc.dancer = dancer
                navigationController?.pushViewController(vc, animated: true)
            }

        case .Competition?:
            break
            
        case .Event?:
            break
        }
        
        return false
    }
}


// Segue 

extension DancerVC {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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

private var times = 0

extension DancerVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if tableView.contentOffset.y > 0-50 && tableView.contentOffset.y < 500 { // (300-56) {
            backgroundHeaderViewHeightConstraint.constant = max(max(dancerNameLabel.bounds.height, 56), 300 - self.tableView.contentOffset.y)
        }
        
        let pointImmediatelyBelowTableViewHeader = CGPoint(
            x: 5,
            y: tableView.contentOffset.y + tableView(tableView, heightForHeaderInSection: 0)
        )
        
        let title = rowTitle(
            activeCompetition(
                scrollView: scrollView,
                indexPath: tableView.indexPathForRowAtPoint(pointImmediatelyBelowTableViewHeader)
            )
        )
        
        for case let button as UIButton in divisionScrollView.subviews where button.currentTitle == title {
            highlight(button: button)
            return
        }
    }
    
    func cellTitleIsVisible(rect: CGRect) -> Bool {
        return rect.origin.y < 97
    }
    
    func cellTitleIsHidden(rect: CGRect) -> Bool {
        return rect.origin.y > 105
    }
    
    func rowTitle(competition: Competition?) -> String? {
        
        switch sort {
            
        case .DivisionName:
            return competition?.divisionName.description
            
        case .Placement:
            return competition?.result.description
            
        case .Date:
            return String(competition?.year)
        }
    }
    
    func competition(forIndexPath indexPath: NSIndexPath) -> Competition {
        return competitions[Int(floor(Float(indexPath.row / 2)))]
    }
    
    func activeCompetition(scrollView scrollView: UIScrollView, indexPath tmp: NSIndexPath?) -> Competition? {
        
        guard let indexPath = tmp else {
            return .None
        }
        
        let cellRectWithinTableView = tableView.convertRect(tableView.rectForRowAtIndexPath(indexPath), toView: tableView.superview)
        
        if scrollView.scrolledAboveContentView {
            return competitions.first
        }
            
        else if scrollView.atBottomOfContentView {
            return competitions.last
        }
            
        else if cellTitleIsHidden(cellRectWithinTableView) {
            return competition(forIndexPath: indexPath)
        }
            
        else if cellTitleIsVisible(cellRectWithinTableView) {
            return competition(forIndexPath: indexPath.nextRow)
        }
        
        return .None
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

class DancerCompCell: MGSwipeTableCell {

    weak var competition: Competition!
    
    @IBOutlet weak var pointsCircleView: UIView! {
        didSet {
            //pointsCircleView.layer.borderColor = UIColor.charcoal.light.CGColor
            //pointsCircleView.layer.shouldRasterize = true
            //pointsCircleView.layer.cornerRadius = 18
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

class DancerCompDetailsCell: MGSwipeTableCell {

    weak var competition: Competition!
    
    @IBOutlet weak var pointsCircleView: UIView! {
        didSet {
            //pointsCircleView.layer.borderColor = UIColor.charcoal.light.CGColor
            //pointsCircleView.layer.shouldRasterize = true
            //pointsCircleView.layer.cornerRadius = 18
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