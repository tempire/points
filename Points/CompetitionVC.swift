//
//  CompetitionVC.swift
//  Points
//
//  Created by Glen Hinkle on 9/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

private struct RowSource {
    var type: WSDC.Competition.Result
    var partners: [Competition]
}

class CompetitionVC: UIViewController {
    
    fileprivate var rowSource: [RowSource] = []
    
    var division: EventYear.Division! {
        didSet {
            print("---")
            
            division.placements.enumerated().forEach { index, placement in
                //print("INDEX: \(index), RESULT: \(placement.result), PARTNER COUNT: \(placement.partners.count), PARTNERS: \(placement.partners.first?.dancer.first?.name) - \(placement.partners.last?.dancer.first?.name)")
                rowSource.append(RowSource(type: placement.result, partners: placement.partners))
            }
            
            division.finalists.enumerated().forEach { index, finalist in
                //print("INDEX: \(index), RESULT: \(finalist.result)")
                rowSource.append(RowSource(type: finalist.result, partners: [finalist]))
            }
            
            rowSource.enumerated().forEach { index, source in
                //print("INDEX: \(index), RESULT: \(source.type), PARTNER COUNT: \(source.partners.count), PARTNERS: \(soure.partners.first?.dancer.first?.name) - \(source.partners.last?.dancer.first?.name)")
            }
            
            print("---")
        }
    }
    
    var peek: Bool = false
    var suspendScrollingHeaderHighlighting = false
    
    @IBOutlet weak var conventionDateLabel: UILabel!
    @IBOutlet weak var conventionNameLabel: UILabel!
    @IBOutlet weak var divisionNameLabel: UILabel!
    @IBOutlet weak var competitionTypeLabel: UILabel!

    @IBOutlet weak var backgroundHeaderViewHeightConstraint: NSLayoutConstraint!
    
    lazy var headerScrollView: UIScrollView = {
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
}

extension CompetitionVC: UITableViewDataSource {
    
    var heightForHeader: CGFloat {
        return tableView(tableView, heightForHeaderInSection: 0)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerScrollView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueCell(CompetitionCell.self, for: indexPath)
        
        let source = rowSource[indexPath.row]
        cell.rowSource = source
        
        print("INDEXPATH: \(indexPath.row), NAME: \(source.partners.first?.dancer.first?.name), RESULT: \(source.partners.first?.result)")

        cell.selectionStyle = .none
        
        cell.placementLabel.text = source.partners.first?.result.description
        
        cell.firstPartnerLabel.text = source.partners.first?.dancer.first?.name
        cell.firstPartnerRoleLabel.text = source.partners.first?.role.tinyRaw.uppercased()
        cell.firstPartnerPointsLabel.text = "\(source.partners.first?.points ?? 0)"
        
        if source.partners.count <= 1 {
            cell.secondPartnerGroupViewHeightConstraint.constant = 0
        }
        else {
            cell.secondPartnerGroupViewHeightConstraint.constant = 60
            cell.secondPartnerLabel.text = source.partners.last?.dancer.first?.name
            cell.secondPartnerRoleLabel.text = source.partners.last?.role.tinyRaw.uppercased()
            cell.secondPartnerPointsLabel.text = "\(source.partners.last?.points ?? 0)"
        }
        
        cell.detailsGroupViewZeroHeightConstraint.constant = 0
        
        /*
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
        */
        
        return cell
    }
}

extension CompetitionVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        guard let cell = tableView.cellForRow(at: indexPath) as? DancerCompCell,
            rowSource[(indexPath as NSIndexPath).row].type == .main else {
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
        */
    }
}

// Segue

extension CompetitionVC {
    
    fileprivate func rowSourceForCell(containingView view: UIView?) -> RowSource? {
        return view?.superviewMatching(CompetitionCell.self)?.rowSource
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return UIStoryboardSegue.SegueIdentifier(identifier) != .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let cell = sender as? UIView,
            let identifier = segue.identifierType else {
                return
        }
        
        
        switch identifier {
            
        case .firstPartner, .secondPartner:
            if let vc = segue.destination as? DancerVC,
                let source = rowSourceForCell(containingView: cell) {
                vc.dancer = identifier == .firstPartner
                    ? source.partners.first?.dancer.first
                    : source.partners.last?.dancer.first
            }
            
        case .division, .partner:
            break
        }
    }
}


// Scrollview delegate

extension CompetitionVC: UIScrollViewDelegate {
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        suspendScrollingHeaderHighlighting = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y > 0-50 && tableView.contentOffset.y < 500 { // (300-56) {
            backgroundHeaderViewHeightConstraint.constant = max(max(conventionNameLabel.bounds.height, 56), 300 - self.tableView.contentOffset.y)
        }
        
        /*
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
        
        for case let button as UIButton in headerScrollView.subviews where button.currentTitle == title {
            highlight(button: button)
            return
        }
         */
    }
    
    /*
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
    */
}

class CompetitionCell: UITableViewCell {
    
    fileprivate var rowSource: RowSource!
    
    @IBOutlet weak var placementLabel: UILabel!
    
    @IBOutlet weak var firstParterButton: UIButton!
    @IBOutlet weak var firstPartnerRoleCircleView: UIView!
    @IBOutlet weak var firstPartnerRoleLabel: UILabel!
    @IBOutlet weak var firstPartnerLabel: UILabel!
    @IBOutlet weak var firstPartnerPointsCircleView: UIView!
    @IBOutlet weak var firstPartnerPointsLabel: UILabel!
    
    @IBOutlet weak var secondPartnerButton: UIButton!
    @IBOutlet weak var secondPartnerRoleCircleView: UIView!
    @IBOutlet weak var secondPartnerRoleLabel: UILabel!
    @IBOutlet weak var secondPartnerLabel: UILabel!
    @IBOutlet weak var secondPartnerPointsCircleView: UIView!
    @IBOutlet weak var secondPartnerPointsLabel: UILabel!
    
    @IBOutlet weak var secondPartnerGroupViewHeightConstraint: NSLayoutConstraint!
    
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
}
