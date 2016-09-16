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
            
            division.placements.forEach { placement in
                rowSource.append(RowSource(type: placement.result, partners: placement.partners))
            }
            
            division.finalists.forEach { finalist in
                rowSource.append(RowSource(type: finalist.result, partners: [finalist]))
            }
        }
    }
    
    var peek: Bool = false

    @IBOutlet weak var conventionDateLabel: UILabel!
    @IBOutlet weak var conventionNameLabel: UILabel!
    @IBOutlet weak var divisionNameLabel: UILabel!
    @IBOutlet weak var competitionTypeLabel: UILabel!

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
        
        //let cell = rowSource.count >= indexPath.row && rowSource[indexPath.row].type == .Main
        //    ? tableView.dequeueCell(DancerCompCell.self, for: indexPath)
        //    : tableView.dequeueCell(DancerCompDetailsCell.self, for: indexPath)
        
        let cell = tableView.dequeueCell(CompetitionCell.self, for: indexPath)
        
        let source = rowSource[indexPath.row]
        
        cell.placementLabel.text = source.partners.first?.result.description
        
        cell.firstPartnerLabel.text = source.partners.first?.dancer.first?.name
        cell.firstPartnerRoleLabel.text = source.partners.first?.role.tinyRaw
        cell.firstPartnerPointsLabel.text = "\(source.partners.first?.points ?? 0)"
        
        print("RESULT: \(source.partners.first?.result.description)")
        print("NAMES: \(source.partners.flatMap { $0.dancer.first?.name })")
        print("COUNT: \(source.partners.count)")
        if source.partners.count <= 1 {
            cell.secondPartnerGroupViewHeightConstraint.constant = 0
        }
        else {
            cell.secondPartnerLabel.text = source.partners.last?.dancer.first?.name
            cell.secondPartnerRoleLabel.text = source.partners.last?.role.tinyRaw
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
