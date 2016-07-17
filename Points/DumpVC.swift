//
//  DumpVC.swift
//  Points
//
//  Created by Glen Hinkle on 7/15/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit
import YSMessagePack
import MPMessagePack

class DumpVC: UIViewController {
    var dump: Dump?
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var competitorsCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let dump = dump else {
            return
        }
        
        do {
            let decompressed = try BZipCompression.decompressedDataWithData(dump.data)
            //let thing = try decompressed.unpack()
            //let thing = try MPMessagePackReader.readData(decompressed)
            //print(try decompressed.arrayOfDataAndTypesUnpacked())
            //let json = try decompressed.itemsUnpacked().flatMap {
            //    try NSJSONSerialization.JSONObjectWithData($0, options: []) as? JSONObject
            //}
            
            //guard let json = try NSJSONSerialization.JSONObjectWithData(unpacked, options: []) as? [JSONObject] else {
            //    return
            //}
            //
            dateLabel.text = dump.date.toString
            versionLabel.text = "\(dump.version)"
            //competitorsCountLabel.text = "\(json.count)"
        }
        catch {
            print(error)
        }
    }
    
}