//
//  ViewController.swift
//  GPS Tracker
//
//  Created by Austin Baker on 10/11/2025.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var test_label:UILabel!
    @IBOutlet weak var collectionView:UICollectionView!
    
    private let locationManager = CLLocationManager()
    var itemCount: Int = 0
    let api = update_server_info()
    var timer:Timer?
    
    var dogs_ids:[String] = []
    var dogAnnotations: [String: MKPointAnnotation] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ask user for permission to use this info
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        //mapView.showsUserLocation = true
        //mapView.userTrackingMode = .follow
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true){[weak self] _ in
            self?.updateLocation()
        }
        loadIds()
        loadRowCount()
        collectionView.delegate = self
        collectionView.dataSource = self
      
    }
    
    //handels the location of the user
    func locationManager(_ manager: CLLocationManager) {
        handleAuthChange(manager.authorizationStatus)
    }
    private func handleAuthChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            //todo add code that sends promps the user to accept this setting as app required location
            break
        case .notDetermined:
            // Still waiting for the system prompt decision
            break
        @unknown default:
            break
        }
    }
    //updates the users loction
    func locationUpdate(_ manager:CLLocationManager, didUpdateLocation locations:[CLLocation]){
        guard let loc = locations.last else {return}
        
        let region = MKCoordinateRegion(
            center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
    }
    //saves the users update prefrence
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    //updates the collars location
    func updateLocation(){
        for id in dogs_ids{
            api.update_locations(d_id: id){[weak self] location in
                guard let self = self,
                      let id = location?.device_id,
                      let lat = location?.lat,
                      let lng = location?.lng
                else {return}
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                
                DispatchQueue.main.async {
                    if let annotation = self.dogAnnotations[id]{
                        annotation.coordinate = coord
                    }else{
                        
                        let annotion = MKPointAnnotation()
                        annotion.coordinate = coord
                        annotion.title = id
                        self.mapView.addAnnotation(annotion)
                        self.dogAnnotations[id] = annotion
                    }
                }
            }
        }
    }
    
    func loadRowCount(){
        api.get_rows { [weak self] count in
                   guard let self = self else { return }
                   self.itemCount = count
                    print(count)
                   DispatchQueue.main.async {
                       self.collectionView.reloadData()
                   }
               }
    }
    
    func loadIds(){
        api.get_id{[weak self] ids in
            guard let self = self, let ids = ids else {return}
            DispatchQueue.main.async {
                self.dogs_ids.append(contentsOf: ids)
            }
        }
        print(dogs_ids)
    }
    //loads the dogs info into a tables
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! inCell
        cell.dog_name.text = dogs_ids[indexPath.row]
        cell.batter_percentage.text = String("Nill")
        cell.status.text = "idk bro"
        return cell
    }
}

class inCell:UICollectionViewCell{
    @IBOutlet weak var dog_name: UILabel!
    @IBOutlet weak var  batter_percentage: UILabel!
    @IBOutlet weak var status: UILabel!
}

