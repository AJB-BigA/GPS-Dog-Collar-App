//
//  ViewController.swift
//  GPS Tracker
//
//  Created by Austin Baker on 10/11/2025.
//

import UIKit
import MapKit

struct dogData{
    let bat: Double
    let status: Bool
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var geoFenceDropDown:UIButton!
    @IBOutlet weak var AppNameLabel: UILabel!
    @IBOutlet weak var startDraw:UIButton!
    
    //used to draw points for geofencing
    var drawingPoints: [CLLocationCoordinate2D] = []
    
    //used for personal location
    private let locationManager = CLLocationManager()
    
    //used to store the amount of dogs available
    var itemCount: Int = 0
    
    //when to draw button is clickec
    var drawMode = false
    var drawButtonNames = ["Save", "Cancel", "Reset"]
    
    //api server update stuff
    let api = update_server_info()
    var timer:Timer?
    
    //holds the dogs ids for string and to ask the database for different things
    var dogs_ids:[String] = []
    
    var dogs_data:[String : dogData] = [:]
    
    //holds the points for each dog made
    var dogAnnotations: [String: MKPointAnnotation] = [:]
    
    var currentPoints: [CLLocationCoordinate2D] = []
    
    var exclusionZones: [MKPolygon] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        startDraw.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        geoFenceDropDown.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startDraw.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            startDraw.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            startDraw.widthAnchor.constraint(equalToConstant: 150),
            startDraw.heightAnchor.constraint(equalToConstant: 20),
            
            geoFenceDropDown.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor, constant: 10),
            geoFenceDropDown.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            geoFenceDropDown.widthAnchor.constraint(equalToConstant: 150),
            geoFenceDropDown.heightAnchor.constraint(equalToConstant: 44),
            
            collectionView.topAnchor.constraint(equalTo: startDraw.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 90),

            mapView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 50),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.60)
             

         ])
        mapView.mapType = .hybrid
        mapView.layer.cornerRadius = 16
        mapView.layer.masksToBounds = true
        //ask user for permission to use this info
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        loadIds()
        loadRowCount()
        updateData()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        timer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: true){[weak self] _ in
            self?.updateTimer()
        }
    }
    
    func updateTimer(){
        self.updateData()
        self.collectionView.reloadData()
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
    func updateData(){
        for id in dogs_ids{
            api.update_locations(d_id: id){[weak self] location in
                guard let self = self,
                      let id = location?.device_id,
                      let lat = location?.lat,
                      let lng = location?.lng
                else {return}
                let dd = dogData(
                        bat : location?.bat ?? 0.0,
                        status: location?.status ?? true)
                
                dogs_data[id] = dd
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
                    self.collectionView.reloadData()
                }
            }
        }
       
    }
    
    func loadRowCount(){
        api.get_rows { [weak self] count in
            guard let self = self else { return }
            self.itemCount = count
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch drawMode {
        case true:
            return CGSize(width: 100, height: 50) // Size for buttons
        case false:
            return CGSize(width: 150, height: 100) // Size for dog cells
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch drawMode{
        case true:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as! inCell2
            cell.setInt(i: indexPath.row)
            cell.button.setTitle(drawButtonNames[indexPath.row], for: .normal)
            cell.delegate = self
            
            return cell
            
        case false:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! inCell
            let id = dogs_ids[indexPath.row]
            
            if let data = dogs_data[id]{
                cell.dog_name.text = id
                cell.batter_percentage.text = "\(data.bat)%"
                cell.status.text = data.status ? "Connected To Wifi" : "Using Sim Data"
            }

            return cell
        }
    }
}
extension ViewController:buttonControl{
    func stopDrawingGeoFence(){
        self.mapView.delegate = nil
        drawMode = false
        currentPoints.removeAll()
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
        currentPoints.removeAll()
        mapView.removeOverlays(mapView.overlays)
    }
}

class inCell:UICollectionViewCell{
    @IBOutlet weak var dog_name: UILabel!
    @IBOutlet weak var  batter_percentage: UILabel!
    @IBOutlet weak var status: UILabel!
    
    override func awakeFromNib(){
        super.awakeFromNib()
        dog_name.translatesAutoresizingMaskIntoConstraints = false
        batter_percentage.translatesAutoresizingMaskIntoConstraints = false
        status.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
        dog_name.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        dog_name.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
        dog_name.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        
        batter_percentage.topAnchor.constraint(equalTo: dog_name.bottomAnchor, constant: 4),
        batter_percentage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
        batter_percentage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        
        status.topAnchor.constraint(equalTo: batter_percentage.bottomAnchor, constant: 4),
        status.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
        status.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        status.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)])
    
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
        }
    }

protocol buttonControl:AnyObject{
    func finishZoneTapped()
    func clearZonesTapped()
    func stopDrawingGeoFence()
}

class inCell2:UICollectionViewCell{
    weak var delegate: buttonControl?
    @IBOutlet weak var button: UIButton!
    
    override func awakeFromNib(){
        super.awakeFromNib()
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
    }
    var num = Int()
    
    func setInt(i:Int){
        num = i
    }
    
    @IBAction func didClick(_ sender: Any){
        switch num{
        case 0:
            delegate?.finishZoneTapped()
        case 1:
            delegate?.stopDrawingGeoFence()
        case 2:
            delegate?.clearZonesTapped()
        default:
            return
        }
        
    }
    
}
