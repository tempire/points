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
    var lead: Competition
    var follow: Competition
    var media: [Media]
    var songs: [Media]
    var videos: [Media]
}

class CompetitionVC: UIViewController {
    
    fileprivate var rowSource: [RowSource] = []
    
    var eventYear: EventYear {
        didSet {
            var pairs = [(lead: Competition, follow: Competition)]()
            
            eventYear.competitions.forEach { competition in
                
            }
        }
    }
    
    var peek: Bool = false

    @IBOutlet weak var conventionDateLabel: UILabel!
    @IBOutlet weak var conventionNameLabel: UILabel!
    @IBOutlet weak var divisionNameLabel: UILabel!
    @IBOutlet weak var competitionTypeLabel: UILabel!

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
}

extension CompetitionVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
    }
}

class CompetitionCell: UITableViewCell {
    @IBOutlet weak var placementLabel: UILabel!
    
    @IBOutlet weak var firstPartnerRoleCircleView: UIView!
    @IBOutlet weak var firstPartnerRoleLabel: UILabel!
    @IBOutlet weak var firstPartnerLabel: UILabel!
    @IBOutlet weak var firstPartnerPointsCircleView: UIView!
    @IBOutlet weak var firstPartnerPointsLabel: UILabel!
    
    @IBOutlet weak var secondPartnerRoleCircleView: UIView!
    @IBOutlet weak var secondPartnerRoleLabel: UILabel!
    @IBOutlet weak var secondPartnerLabel: UILabel!
    @IBOutlet weak var secondPartnerPointsCircleView: UIView!
    @IBOutlet weak var secondPartnerPointsLabel: UILabel!
    
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
