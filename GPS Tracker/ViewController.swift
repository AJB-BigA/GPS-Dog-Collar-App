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
    @IBOutlet weak var geoFenceDropDown:UIButton!
    @IBOutlet weak var startDraw:UIButton!
    
    //used to draw points for geofencing
    var drawingPoints: [CLLocationCoordinate2D] = []
    
    //used for personal location
    private let locationManager = CLLocationManager()
    
    //used to store the amount of dogs available
    var itemCount: Int = 0
    
    //when to draw button is clickec
    var drawMode = false
    var drawButtonNames = ["Save", "Cancel", "Clear"]
    
    //api server update stuff
    let api = update_server_info()
    var timer:Timer?
    
    //holds the dogs ids for string and to ask the database for different things
    var dogs_ids:[String] = []
    
    //holds the points for each dog made
    var dogAnnotations: [String: MKPointAnnotation] = [:]
    
    var currentPoints: [CLLocationCoordinate2D] = []
    
    var exclusionZones: [MKPolygon] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.mapType = .hybrid
        mapView.layer.cornerRadius = 16
        mapView.layer.masksToBounds = true
        //ask user for permission to use this info
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true){[weak self] _ in
            self?.updateLocation()
        }
        loadIds()
        loadRowCount()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        currentPoints.append(coordinate)
        redrawCurrentLine()
    }
    
    func redrawCurrentLine() {
        // Remove any temporary polylines
        let tempLines = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(tempLines)
        
        guard currentPoints.count > 1 else { return }
        
        let polyline = MKPolyline(coordinates: currentPoints, count: currentPoints.count)
        mapView.addOverlay(polyline)
    }
    
    @IBAction func startDrawingGeoFence(_ sender:Any){
        self.mapView.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        self.mapView.addGestureRecognizer(tap)
        drawMode = true
        self.collectionView.reloadData()
    }
    
    
    //draw lines
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 3
            renderer.strokeColor = UIColor.systemBlue
            return renderer
        }
        
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.systemRed
            renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.2)
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
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
        switch drawMode{
        case true: return 3
            
        case false : return itemCount
            
        }
  
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch drawMode{
        case true:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as! inCell2
            cell.setInt(i: indexPath.row)
            cell.button.titleLabel?.text = drawButtonNames[indexPath.row]
            return cell
            
        case false:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! inCell
            cell.dog_name.text = dogs_ids[indexPath.row]
            cell.batter_percentage.text = String("Nill")
            cell.status.text = "idk bro"
            return cell
        }
    }
}
extension ViewController:buttonControl{
    func stopDrawingGeoFence(){
        self.mapView.delegate = nil
        drawMode = false
        collectionView.reloadData()
    }
    func finishZoneTapped() {
        guard currentPoints.count > 2 else { return }  // need at least triangle
        
        let polygon = MKPolygon(coordinates: currentPoints, count: currentPoints.count)
        exclusionZones.append(polygon)
        
        // Clear temporary line
        let tempLines = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(tempLines)
        
        mapView.addOverlay(polygon)
        currentPoints.removeAll()
        stopDrawingGeoFence()
    }
    
    func clearZonesTapped() {
        currentPoints.removeAll()
        exclusionZones.removeAll()
        mapView.removeOverlays(mapView.overlays)
    }
}

class inCell:UICollectionViewCell{
    @IBOutlet weak var dog_name: UILabel!
    @IBOutlet weak var  batter_percentage: UILabel!
    @IBOutlet weak var status: UILabel!
}

protocol buttonControl:AnyObject{
    func finishZoneTapped()
    func clearZonesTapped()
    func stopDrawingGeoFence()
}

class inCell2:UICollectionViewCell{
    weak var delegate: buttonControl?
    @IBOutlet weak var button: UIButton!
    
    var num = Int()
    
    func setInt(i:Int){
        num = i
    }
    
    @IBAction func didClick(_ sender: Any){
        switch num{
        case 0:
            delegate?.finishZoneTapped()
        case 1:
            delegate?.clearZonesTapped()
        case 2:
            delegate?.stopDrawingGeoFence()
        default:
            return
        }
        
    }
    
}
