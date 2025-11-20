//
//  GeoFence Popup.swift
//  GPS Tracker
//
//  Created by Austin Baker on 19/11/2025.
//

import Foundation
import UIKit

class PopUpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
  
    
    @IBOutlet weak var geoFence:UITableView!
    
    
    override func viewDidLoad() {
        geoFence.delegate = self
        geoFence.dataSource = self
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellW", for: indexPath) as! geoFenceInCell
        cell.geoFenceName.text = "Around house"
        return cell
    }
    
}

class geoFenceInCell:UITableViewCell {
    @IBOutlet weak var toggle:UISwitch!
    @IBOutlet weak var geoFenceName:UILabel!
    @IBOutlet weak var deleteButton:UIButton!
}
