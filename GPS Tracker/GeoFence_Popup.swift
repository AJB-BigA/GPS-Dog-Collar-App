//
//  GeoFence Popup.swift
//  GPS Tracker
//
//  Created by Austin Baker on 19/11/2025.
//

import Foundation
import UIKit

class PopUpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    //api server update stuff
    let api = update_server_info()
    
    @IBOutlet weak var geoFence:UITableView!
    var names:[String] = [];
    override func viewDidLoad() {
        geoFence.delegate = self
        geoFence.dataSource = self
    }
    
    func loadData(){
        api.get_geoFence_names{[weak self] name in
            guard let self = self else {return}
            self.names.append(name)
            DispatchQueue.main.async {
                self.geoFence.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (names.count < 1){
            return 1;
        }
        else{
            return names.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (names.count < 1){
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellW", for: indexPath) as! geoFenceInCell
            cell.geoFenceName.text = "No Data currently avalible"
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellW", for: indexPath) as! geoFenceInCell
            cell.geoFenceName.text = names[indexPath.row]
            return cell
        }
    }
}

class geoFenceInCell:UITableViewCell {
    @IBOutlet weak var toggle:UISwitch!
    @IBOutlet weak var geoFenceName:UILabel!
    @IBOutlet weak var deleteButton:UIButton!
}
