//
//  GeoFence Popup.swift
//  GPS Tracker
//
//  Created by Austin Baker on 19/11/2025.
//

import Foundation
import UIKit

/// Modal popup that lists all saved geofences with a toggle and delete option per row.
class PopUpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var geoFence:UITableView!
    override func viewDidLoad() {
        geoFence.delegate = self
        geoFence.dataSource = self
    }
    
    // Always returns at least 1 row so an empty-state message can be shown when
    // no fences have been saved yet.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (GeoFenceManager.shared.fences.count < 1){
            return 1;
        }
        else{
            return GeoFenceManager.shared.fences.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellW", for: indexPath) as! geoFenceInCell
        
        // Empty state: no fences saved yet.
        if (GeoFenceManager.shared.fences.count < 1){
            cell.geoFenceName.text = "No data currently available"
            return cell
        }
        cell.geoFenceName.text = GeoFenceManager.shared.fences[indexPath.row].name
        
        // Wire up the delete button to show a confirmation alert before removing the fence.
        cell.onDelete = {[weak self] in
            let alert = UIAlertController(title: "Remove Boundary", message: "Are you sure you want to delete this boundary?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive){_ in
                GeoFenceManager.shared.delete(id: GeoFenceManager.shared.fences[indexPath.row].id)
                {success in print(success ? "deleted successfully" : "failed to delete")}
                GeoFenceManager.shared.load{ [weak self] success in
                    guard let self = self, success else {return}
                    self.geoFence.reloadData()
                    NotificationCenter.default.post(name: .geoFenceChanged, object:nil)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self?.present(alert, animated: true)
            
        }
        return cell
    }
}

class geoFenceInCell:UITableViewCell {
    @IBOutlet weak var geoFenceName:UILabel!
    @IBOutlet weak var deleteButton:UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        geoFenceName.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        // Prevent the label from stretching over the button
        geoFenceName.setContentHuggingPriority(.defaultLow, for: .horizontal)
        deleteButton.setContentHuggingPriority(.required, for: .horizontal)
        deleteButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        deleteButton.addTarget(self, action: #selector(deleteFence), for: .touchUpInside)

        NSLayoutConstraint.activate([
            geoFenceName.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            geoFenceName.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            geoFenceName.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -8),

            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -13),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    var onDelete: (()->Void)?
    
    @objc func deleteFence(){
        onDelete?()
        
    }
}
