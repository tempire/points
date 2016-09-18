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

enum SegueIdentifier {
    case partner
}

enum CompetitionSort {
    case divisionName
    case date
    case placement
    
    var descriptors: String {
        
        switch self {
            
        case .divisionName:
            return "divisionNameDisplayOrder"
            
        case .date:
            return "year"
            
        case .placement:
            return "_result"
        }
    }
    
    var ascending: Bool {
        
        switch self {
            
        case .divisionName:
            return true
            
        case .date:
            return false
            
        case .placement:
            return true
        }
    }
}


private enum RowType {
    case main
    case detail
}

private struct RowSource {
    var competition: Competition
    var result: WSDC.Competition.Result
    var divisionName: WSDC.DivisionName
    var eventName: String
    var eventDate: Date
    var eventDateDescription: String
    var eventLocation: String?
    var role: WSDC.Competition.Role
    var points: String
    var partnerName: String?
    var partnerRole: WSDC.Competition.Role?
    var type: RowType
}

class DancerVC: UIViewController {
    var dancer: Dancer!
    var cellHeights = [CGFloat]()
    
    var sort = CompetitionSort.divisionName {
        didSet {
            updateHeaderScrollView()
            initializeRowSource()
            tableView.reloadDataWithDissolve()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    typealias Headers = [(title: String, subTitle: String)]
    
    fileprivate var rowSource: [RowSource] = []
    
    var peek: Bool = false
    
    var dancerNameLabelHeight = CGFloat(0)
    var dancerNameLabelTransitionInProgress = false
    var suspendScrollingHeaderHighlighting = false
    
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
    
    @IBOutlet weak var favoriteButton: UIButton! {
        didSet {
            favoriteButton.tintColor = .white
            favoriteButton.imageView?.image = UIImage(asset: dancer.favorite ? .Glyphicons_50_Star : .Glyphicons_49_Star_Empty)
        }
    }
    
    @IBOutlet weak var wsdcIdLabel: UILabel! {
        didSet {
            wsdcIdLabel.text = "\(dancer.id)"
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
        view.backgroundColor = .lightGray
        view.scrollsToTop = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.scrollsToTop = true
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.allowsSelection = true
            tableView.estimatedRowHeight = 130
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.delegate = self
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
        
        updateHeaderScrollView()
        initializeRowSource()
    }
    
    func initializeRowSource() {
        
        rowSource = dancer.competitions.map {
            
            RowSource(
                competition: $0,
                result: $0.result,
                divisionName: $0.divisionName,
                eventName: $0.eventYear.event.name,
                eventDate: $0.eventYear.date,
                eventDateDescription: $0.eventYear.shortDateString,
                eventLocation: $0.eventYear.event.location,
                role: $0.role,
                points: String($0.points),
                partnerName: $0.partnerCompetition?.dancer.first?.name,
                partnerRole: $0.partnerCompetition?.role,
                type: .main
            )
        }
        
        switch sort {
            
        case .divisionName:
            rowSource.sort { a, b in
                return a.divisionName.displayOrder < b.divisionName.displayOrder
            }
            
        case .date:
            rowSource.sort { a, b in
                return !(a.eventDate >= b.eventDate)
            }
            
        case .placement:
            rowSource.sort { a, b in
                a.result.displayOrder < b.result.displayOrder
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setBackgroundColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
    
    func setBackgroundColor() {
        view.backgroundColor = peek ? .clear : .darkGray
        peek = false
    }
    
    func updateHeaderScrollView() {
        
        divisionScrollView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        divisionScrollView.constrainEdgesHorizontally(
            upsertHeaderButtons(for: sort)
        )
        
        divisionScrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    // Sort appropriate fields according to sort method
    
    func upsertHeaderButtons(for sort: CompetitionSort) -> [UIButton] {
        
        var headers = Headers()
        
        switch sort {
            
        case .divisionName:
            headers = dancer.divisionNamesInDisplayOrder.map {
                (
                    title: $0.description,
                    subTitle: String(dancer.points(forDivision: $0).values.reduce(0, +))
                )
            }
            
        case .date:
            headers = rowSource
                .reduce([:]) { tmp, comp -> [Int:Int] in
                    var dict = tmp
                    
                    if dict[comp.competition.eventYear.year] == nil {
                        dict[comp.competition.eventYear.year] = 0
                    }
                    
                    dict[comp.competition.eventYear.year]! += 1
                    
                    return dict
                }
                .sorted(by: >)
                .map {
                    let title = String($0.0)
                    let subTitle = String($0.1)
                    return (title: title, subTitle: subTitle)
            }
            
        case .placement:
            headers = rowSource
                .reduce([:]) { tmp, comp -> [WSDC.Competition.Result:Int] in
                    
                    var dict = tmp
                    
                    if dict[comp.competition.result] == nil {
                        dict[comp.competition.result] = 0
                    }
                    
                    dict[comp.competition.result]! += 1
                    
                    return dict
                }
                .sorted { $0.0.displayOrder < $1.0.displayOrder }
                .map { (title: $0.0.description, subTitle: String($0.1)) }
        }
        
        return buttons(for: headers)
    }
    
    // Create, add, and return buttons according to sorted headers
    
    func buttons(for headers: Headers) -> [UIButton] {
        
        return headers.map { header in
            
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            divisionScrollView.addSubview(button)
            
            button.backgroundColor = .lightGray
            
            button.titleEdgeInsets = UIEdgeInsets(top: -16, left: 0, bottom: 0, right: 0)
            button.setTitleColor(.white, for: UIControlState())
            button.addTarget(self, action: #selector(scrollToHeaderLocation(_:)), for: .touchUpInside)
            
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            
            button.setTitle(header.title, for: UIControlState())
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = header.subTitle
            button.addSubview(label)
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -4).isActive = true
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
            
            return button
        }
    }
}

// MARK: Actions

extension DancerVC {

    @IBAction func toggleFavorite(_ sender: UIButton) {
        
        try! Realm().write {
            dancer.favorite = !dancer.favorite
        }

        sender.setImage(UIImage(asset: dancer.favorite ? .Glyphicons_50_Star : .Glyphicons_49_Star_Empty), for: .normal)
    }

    func highlight(button: UIButton) {
        
        UIView.animate(
            withDuration: 0.15,
            animations: {
                
                for case let b as UIButton in self.divisionScrollView.subviews {
                    
                    if b.currentTitle == button.currentTitle {
                        b.backgroundColor = .darkGray
                        b.setTitleColor(.white, for: UIControlState())
                        b.isHighlighted = true
                    }
                    else {
                        b.backgroundColor = .lightGray
                        b.setTitleColor(.white, for: UIControlState())
                        b.isHighlighted = false
                    }
                }
                
                self.divisionScrollView.scrollRectToVisible(button.frame, animated: false)
            }
        )
    }
    
    func scrollToHeaderLocation(_ button: UIButton) {
        var row: Int?
        
        switch sort {
            
        case .divisionName:
            if let divisionName = WSDC.DivisionName(description: button.currentTitle) {
                row = rowSource.index {
                    $0.divisionName == divisionName
                }
            }
            
        case .date:
            if let year = Int(button.currentTitle) {
                row = rowSource.index {
                    $0.eventDate.year() == year
                }
            }
            
        case .placement:
            if let placementDescription = button.currentTitle {
                row = rowSource.index {
                    $0.result.description == placementDescription }
            }
        }
        
        guard let _row = row else {
            MessageBarManager.sharedInstance().showMessage(withTitle: "Sort Error", description: "Could not find rows for \(sort)", type: MessageBarMessageTypeError, duration: 10)
            return
        }
        
        highlight(button: button)
        suspendScrollingHeaderHighlighting = true
        
        self.tableView.scrollToRow(at: IndexPath(row: _row, section: 0), at: .top, animated: true)
    }
}


extension DancerVC: UITableViewDataSource {

    var heightForHeader: CGFloat {
        return tableView(tableView, heightForHeaderInSection: 0)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return divisionScrollView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //let cell = rowSource.count >= indexPath.row && rowSource[indexPath.row].type == .Main
        //    ? tableView.dequeueCell(DancerCompCell.self, for: indexPath)
        //    : tableView.dequeueCell(DancerCompDetailsCell.self, for: indexPath)
        
        let cell = tableView.dequeueCell(DancerCompCell.self, for: indexPath)
        
        let source = rowSource[(indexPath as NSIndexPath).row]
        cell.rowSource = source
        
        cell.selectionStyle = .none
        //let backgroundView = UIView()
        //backgroundView.backgroundColor = cell.backgroundColor
        //cell.selectedBackgroundView = backgroundView
        
        //if let cell = cell as? DancerCompCell {
            cell.resultLabel.text = source.result.description
            cell.divisionNameLabel.text = source.divisionName.description
            cell.eventNameLabel.text = source.eventName
            //cell.eventNameLabel.text = competition.eventYear.event.name
            cell.eventDateLabel.text = source.eventDateDescription
            cell.eventLocationLabel.text = source.eventLocation
            cell.pointsCircleView.backgroundColor = source.role == .Lead ? .lead : .follow
            cell.pointsLabel.text = source.points
            cell.pointsLabel.backgroundColor = cell.pointsCircleView.backgroundColor
            
            cell.partnerRoleView.isHidden = source.partnerName == .none
            cell.partnerRoleView.backgroundColor = source.partnerRole == .Lead ? .lead : .follow
            cell.partnerRoleLabel.text = source.partnerRole?.tinyRaw.uppercased()
            cell.partnerRoleLabel.backgroundColor = cell.partnerRoleView.backgroundColor
            cell.partnerNameLabel.text = source.partnerName
        
            cell.partnerButton.isHidden = source.partnerName == .none
        //}
        
        
        cell.videoScrollView.constrainEdgesHorizontally((0..<3).map { index -> UIImageView in
            
            let url = URL(string: "https://img.youtube.com/vi/qNtcB_ZBZOw/\(index).jpg")!
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 120, height: 90))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cell.videoScrollView.addSubview(imageView)
            
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    ui(.async) {
                        imageView.image = image
                    }
                }
                }) .resume()
            
            return imageView
            }
        )
            
        return cell
    }
    
    /*
    func dancerCompCell(cell: DancerCompCell, competition: Competition) -> DancerCompCell {
        
        cell.resultLabel.text = competition.result.description
        cell.divisionNameLabel.text = competition.divisionName.description
        cell.pointsCircleView.backgroundColor = competition.role == .Lead ? .lead : .follow
        cell.pointsLabel.text = String(competition.points)
        cell.pointsLabel.backgroundColor = cell.pointsCircleView.backgroundColor

        return cell
    }
 
    func dancerCompDetailsCell(cell: DancerCompDetailsCell, competition: Competition) -> DancerCompDetailsCell {

        return cell
    }
    */
}


extension DancerVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? DancerCompCell
        , rowSource[(indexPath as NSIndexPath).row].type == .main else {
            return
        }
        
        tableView.beginUpdates()
        
        cell.detailsGroupViewZeroHeightConstraint.isActive = !cell.detailsGroupViewZeroHeightConstraint.isActive
        
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [],
            animations: {
                cell.layoutIfNeeded()
            },
            completion: { finished in
                tableView.endUpdates()
            }
        )
        
        // If no next row, show detail
        // If next row is main, show detail
        // If next row is detail, hide it
        
        //if indexPath.nextRow.row >= rowSource.count || rowSource[indexPath.nextRow.row].type == .Main {
        //    
        //    var source = rowSource[indexPath.row]
        //    source.type = .Detail
        //    
        //    rowSource.insert(source, atIndex: indexPath.nextRow.row)
        //    tableView.insertRowsAtIndexPaths([indexPath.nextRow], withRowAnimation: .Automatic)
        //}
        //else {
        //    rowSource.removeAtIndex(indexPath.nextRow.row)
        //    tableView.deleteRowsAtIndexPaths([indexPath.nextRow], withRowAnimation: .Automatic)
        //}
        
        
        
        //let detailsCellIndexPath = self.detailsCellIndexPath(forIndexPath: indexPath)
        
        //cellHeights[detailsCellIndexPath.row] = cellHeights[detailsCellIndexPath.row] == 0 ? cellHeights[indexPath.row] : 0
        //detailsCellVisible[detailsCellIndexPath.row] = !detailsCellVisible[detailsCellIndexPath.row]
        
        //tableView.reloadRowsAtIndexPaths([detailsCellIndexPath], withRowAnimation: .Automatic)
    }
}


// MARK: Table Cell utility methods

extension DancerVC {
    func isMainCell(_ indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).row % 2 == 0
    }
    
    func detailsCellIndexPath(forIndexPath indexPath: IndexPath) -> IndexPath {
        return (indexPath as NSIndexPath).row % 2 == 0 ? indexPath.nextRow : indexPath
    }
}


extension DancerVC: MGSwipeTableCellDelegate {
   
    func swipeTableCellWillBeginSwiping(_ cell: MGSwipeTableCell) {
        //for case let button as MGSwipeButton in cell.rightButtons {
        //}
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        
        guard let indexPath = tableView.indexPath(for: cell) else {
            return false
        }
        
        switch MGSwipeButton.SwipeButton(index) {
            
        case .none:
            break
            
        case .partner?:
            if let dancer = rowSource[(indexPath as NSIndexPath).row].competition.partnerCompetition?.dancer.first {
                let vc = Storyboard.Main.viewController(DancerVC.self)
                vc.dancer = dancer
                navigationController?.pushViewController(vc, animated: true)
            }

        case .competition?:
            break
            
        case .event?:
            break
        }
        
        return false
    }
}


// Segue 

extension DancerVC {
    
    fileprivate func rowSourceForCell(containingView view: UIView?) -> RowSource? {
        return view?.superviewMatching(DancerCompCell.self)?.rowSource
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {

        guard let cell = sender as? UIView,
            let identifier = UIStoryboardSegue.SegueIdentifier(identifier) else {
                return false
        }
        
        switch identifier {
            
        case .partner:
            if let source = rowSourceForCell(containingView: cell),
                let _ = source.competition.partnerCompetition?.dancer.first {
                return true
            }

        case .division:
            if let source = rowSourceForCell(containingView: cell),
                let _ = source.competition.eventYear.divisions[source.competition.divisionName] {
                return true
            }
            
        case .firstPartner, .secondPartner, .dancer, .importer:
            break
        }
        
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let cell = sender as? UIView,
            let identifier = segue.identifierType else {
                return
        }
        
        switch identifier {
            
        case .partner:
            if let vc = segue.destination as? DancerVC,
                let source = rowSourceForCell(containingView: cell),
                let dancer = source.competition.partnerCompetition?.dancer.first {
                vc.dancer = dancer
            }
            
        case .division:
            if let vc = segue.destination as? CompetitionVC,
                let source = rowSourceForCell(containingView: cell) {
                vc.division = source.competition.eventYear.divisions[source.competition.divisionName]
            }
            
        case .firstPartner, .secondPartner, .dancer, .importer:
            break
        }
    }
}


// Open from spotlight

extension DancerVC {
   
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        guard activity.activityType == CSSearchableItemActionType else {
            return
        }
        
        let realm = try! Realm()
        
        if let value = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let dancerId = Int(value),
            let dancer = realm.allObjects(ofType: Dancer.self).filter(using: "id == %d", dancerId).first {
            self.dancer = dancer
        }
    }
}


// Scrollview delegate

extension DancerVC: UIScrollViewDelegate {
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        suspendScrollingHeaderHighlighting = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y > 0-50 && tableView.contentOffset.y < 500 { // (300-56) {
            backgroundHeaderViewHeightConstraint.constant = max(max(dancerNameLabel.bounds.height, 56), 300 - self.tableView.contentOffset.y)
        }
        
        if suspendScrollingHeaderHighlighting {
            return
        }

        let pointImmediatelyBelowTableViewHeader = CGPoint(
            x: 5,
            y: tableView.contentOffset.y + heightForHeader
        )
        
        let title = rowTitle(
            firstVisibleRow(
                scrollView: scrollView,
                indexPath: tableView.indexPathForRow(at: pointImmediatelyBelowTableViewHeader)
            )
        )
        
        for case let button as UIButton in divisionScrollView.subviews where button.currentTitle == title {
            highlight(button: button)
            return
        }
    }
    
    func cellTitleIsVisible(_ rect: CGRect) -> Bool {
        return rect.origin.y < 97
    }
    
    func cellTitleIsHidden(_ rect: CGRect) -> Bool {
        return rect.origin.y > 105
    }
    
    fileprivate func rowTitle(_ source: RowSource?) -> String? {
        
        switch sort {
            
        case .divisionName:
            return source?.divisionName.description
            
        case .placement:
            return source?.result.description
            
        case .date:
            return String(source?.eventDate.year())
        }
    }
    
    fileprivate func row(forIndexPath indexPath: IndexPath) -> RowSource {
        return rowSource[(indexPath as NSIndexPath).row]
        //return rowSource[Int(floor(Float(indexPath.row / 2)))]
    }
    
    fileprivate func firstVisibleRow(scrollView: UIScrollView, indexPath tmp: IndexPath?) -> RowSource? {
        
        guard let indexPath = tmp else {
            return .none
        }
        
        let cellRectWithinTableView = tableView.convert(tableView.rectForRow(at: indexPath), to: tableView.superview)
        
        if scrollView.scrolledAboveContentView {
            return rowSource.first
        }
            
        else if scrollView.atBottomOfContentView {
            return rowSource.last
        }
            
        else if cellTitleIsHidden(cellRectWithinTableView) {
            return row(forIndexPath: indexPath)
        }
            
        else if cellTitleIsVisible(cellRectWithinTableView) {
            return row(forIndexPath: indexPath.nextRow)
        }
        
        return .none
    }
}

// Side swipe not used anymore
//let buttons: [MGSwipeButton] = [
//    MGSwipeButton.SwipeButton.Event.button,
//    MGSwipeButton.SwipeButton.Competition.button,
//    MGSwipeButton.SwipeButton.Partner.button,
//    ]
//    .map { button in
//        button.centerIconOverText()
//        button.setEdgeInsets(UIEdgeInsetsZero)
//        return button
//}

// MARK: Actions

extension DancerVC {
    @IBAction func sort(_ sender: UIButton) {
        
        switch sort {
            
        case .divisionName:
            sort = .date
            
        case .date:
            sort = .placement
            
        case .placement:
            sort = .divisionName
        }
    }
}

class DancerCompCell: MGSwipeTableCell {

    fileprivate var rowSource: RowSource!
    
    @IBOutlet weak var pointsCircleView: UIView! {
        didSet {
            pointsCircleView.layer.cornerRadius = 18
        }
    }
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var divisionNameLabel: UILabel!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var eventDateLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var partnerContentView: UIView!
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var partnerRoleView: UIView!
    @IBOutlet weak var partnerRoleLabel: UILabel! {
        didSet {
            partnerRoleLabel.layer.cornerRadius = 4
            partnerRoleLabel.layer.masksToBounds = true
        }
    }
    
    @IBOutlet var detailsGroupViewZeroHeightConstraint: NSLayoutConstraint! {
        didSet {
            detailsGroupViewZeroHeightConstraint.isActive = true
        }
    }
    
    // Options
    @IBOutlet weak var partnerButton: UIButton! {
        didSet {
            partnerButton.centerImage()
        }
    }
    
    @IBOutlet weak var competitorsButton: UIButton! {
        didSet {
            competitorsButton.centerImage()
        }
    }
    
    // Music
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet weak var spotifyButton: UIButton!
    @IBOutlet weak var appleMusicButton: UIButton!
    
    // Video
    @IBOutlet weak var videoScrollView: UIScrollView!
    
    @IBAction func showEventLocation(_ sender: UIButton) {
        //Maps.openAtAddress(competition.eventYear.event.location)
    }
    
    @IBAction func showPartner(_ sender: UIButton) {
        
    }
}

class DancerCompDetailsCell: MGSwipeTableCell {

    fileprivate var rowSource: RowSource!
    
    @IBOutlet weak var pointsCircleView: UIView! {
        didSet {
            pointsCircleView.layer.cornerRadius = 18
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
    
    @IBAction func showEventLocation(_ sender: UIButton) {
        //Maps.openAtAddress(competition.eventYear.event.location)
    }
}
