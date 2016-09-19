//
//  EventsVC.swift
//  Points
//
//  Created by Glen Hinkle on 9/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

private struct RowSource {
    var event: Event
    var yearsString: String
}

class EventsVC: UIViewController {
    
    fileprivate var rowSource = [RowSource]()
    
    @IBAction func editingDidBegin(_ sender: UITextField) {
        
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    @IBAction func editingChanged(_ sender: UITextField) {
        editingDidBegin(sender)
        
        guard let text = sender.text else {
            return
        }
        
        initializeRowSource(with: NSPredicate(format: "name CONTAINS[c] %@ OR location CONTAINS[c] %@ OR yearsString CONTAINS[c] %@",
                                              text, text, text))
        
    }
    
    func initializeRowSource(with predicate: NSPredicate) {

        do {
            rowSource = try Realm().allObjects(ofType: Event.self)
                .filter(using: predicate)
                .map { event in
                RowSource(
                    event: event,
                    yearsString: event.years.map { "\($0.year)" }.joined(separator: ", ")
                )
            }
            
            tableView.reloadDataWithDissolve()
        }
        catch let error as NSError {
            print(error)
        }
    }
    
    var peek: Bool = false

    @IBOutlet weak var backgroundHeaderViewHeightConstraint: NSLayoutConstraint!

    lazy var headerScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .lightGray
        view.scrollsToTop = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    @IBOutlet weak var searchTextField: UITextField!
    
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
        
        initializeRowSource(with: NSPredicate.all)
    }
}


extension EventsVC: UITableViewDataSource {
    
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
        
        let cell = tableView.dequeueCell(EventsCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.delegate = self
        
        let source = rowSource[indexPath.row]
        
        cell.favoriteButton.setImage(UIImage(asset: source.event.favorite ? .Glyphicons_50_Star : .Glyphicons_49_Star_Empty), for: .normal)
        
        cell.eventNameLabel.text = source.event.name
        cell.locationLabel.text = source.event.location
        cell.yearsLabel.text = source.yearsString
      
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
}


extension EventsVC: UITableViewDelegate {
    
}


// Segue

extension EventsVC {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifierType else {
            return
        }
        
        switch identifier {
            
        case .event:
            guard let vc = segue.destination as? EventVC,
                let cell = sender as? EventsCell,
                let indexPath = tableView.indexPath(for: cell) else {
                    return
            }
            
            vc.event = rowSource[indexPath.row].event
            vc.peek = segue.identifier == "peek"
            
            tableView.deselectRow(at: indexPath, animated: true)
            
        case .partner, .firstPartner, .secondPartner, .division, .importer, .dancer:
            break
        }
    }
}


extension EventsVC: FavoritesCellDelegate {
    
    func didToggleFavorite(cell: UITableViewCell) {
        
        guard let row = tableView.indexPath(for: cell)?.row,
            let cell = cell as? EventsCell else {
                return
        }
        
        let source = rowSource[row]
        
        do {
            try Realm().write {
                source.event.favorite = !source.event.favorite
            }
        }
        catch let error as NSError {
            print(error)
        }
        
        cell.favoriteButton.setImage(UIImage(asset: source.event.favorite ? .Glyphicons_50_Star : .Glyphicons_49_Star_Empty), for: .normal)
    }
}

// Scrollview delegate

extension EventsVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if searchTextField.bounds.height < 1000 && tableView.contentOffset.y > 0-50 && tableView.contentOffset.y < 500 { // (300-56) {
            backgroundHeaderViewHeightConstraint.constant = max(max(searchTextField.bounds.height, 56), 300 - self.tableView.contentOffset.y)
        }
    }
}


// Actions

extension EventsVC {
    
}


class EventsCell: UITableViewCell {
    
    weak var delegate: FavoritesCellDelegate?
    
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var yearsLabel: UILabel!
    
    @IBAction func toggleFavorite(_ sender: UIButton) {
        delegate?.didToggleFavorite(cell: self)
    }
}
