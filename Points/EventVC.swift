//
//  EventVC.swift
//  Points
//
//  Created by Glen Hinkle on 9/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

private struct RowSource {
    
}

class EventVC: UIViewController {

    fileprivate var rowSource: [RowSource] = []
    
    var eventYear: EventYear? {
        didSet {
            rowSource = []
        }
    }
    var peek: Bool = false
    
    @IBOutlet weak var backgroundHeaderViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var eventDateLabel: UILabel!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    
    
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

extension EventVC: UITableViewDataSource {
    
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
        
        let cell = tableView.dequeueCell(EventCell.self, for: indexPath)

        cell.selectionStyle = .none
        
        let source = rowSource[indexPath.row]
        cell.rowSource = source
        
        return cell
    }
}


// Segue

extension EventVC {
    
    fileprivate func rowSourceForCell(containingView view: UIView?) -> RowSource? {
        return view?.superviewMatching(EventCell.self)?.rowSource
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
            
        case .division:
            if let vc = segue.destination as? CompetitionVC,
                let source = rowSourceForCell(containingView: cell) {
//                vc.division =
            }
            
        case .firstPartner, .secondPartner, .partner, .dancer, .importer, .event:
            break
        }
    }
}


// Scrollview delegate

extension EventVC: UITableViewDelegate, UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y > 0-50 && tableView.contentOffset.y < 500 { // (300-56) {
            backgroundHeaderViewHeightConstraint.constant = max(max(eventNameLabel.bounds.height, 56), 300 - self.tableView.contentOffset.y)
        }
    }
}


class EventCell: UITableViewCell {
    
    fileprivate var rowSource: RowSource!
}
