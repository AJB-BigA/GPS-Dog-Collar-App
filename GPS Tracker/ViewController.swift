//
//  ViewController.swift
//  GPS Tracker
//
//  Created by Austin Baker on 10/11/2025.
//

import UIKit
import MapKit

/// Main view controller — displays a satellite map with dog collar locations, a scrollable
/// collection view of dog status cards, and geofence drawing controls.
class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var geoFenceDropDown:UIButton!
    @IBOutlet weak var AppNameLabel: UILabel!
    @IBOutlet weak var startDraw:UIButton!
    
    // MARK: - Properties
    
    /// Manages the user's own GPS location for the blue dot on the map.
    private let locationManager = CLLocationManager()
    
    /// When `true`, the collection view shows Save / Cancel / Reset buttons instead of dog cards.
    var drawMode = false
    /// Titles for the three draw-mode action buttons.
    var drawButtonNames = ["Save", "Cancel", "Reset"]
    
    /// Repeating timer that polls the API to refresh collar locations.
    var timer:Timer?
    
    /// Coordinates tapped by the user while drawing a geofence boundary (cleared on save or reset).
    var currentPoints: [CLLocationCoordinate2D] = []
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        
        //load geoFence Data and present once its loaded
        GeoFenceManager.shared.load { [weak self] success in
             guard let self = self, success else { return }
             self.mapView.addOverlays(GeoFenceManager.shared.polygons)
             self.addPolygonsBack()
         }
        LocationUpdateManager.shared.load_all{
            [weak self] success in
                 guard let self = self, success else { return }
            self.collectionView.reloadData()
        }
        // Enable Auto Layout for all storyboard outlets
        mapView.translatesAutoresizingMaskIntoConstraints = false
        startDraw.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        geoFenceDropDown.translatesAutoresizingMaskIntoConstraints = false
        AppNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Style the toolbar buttons with rounded borders
        startDraw.layer.borderColor = UIColor.systemRed.cgColor
        startDraw.layer.borderWidth = 1
        startDraw.layer.cornerRadius = 10
        geoFenceDropDown.layer.borderColor = UIColor.systemBlue.cgColor
        geoFenceDropDown.layer.cornerRadius = 10
        geoFenceDropDown.layer.borderWidth = 1
        
        NSLayoutConstraint.activate([
            AppNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            AppNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            AppNameLabel.widthAnchor.constraint(equalToConstant: 150),
            AppNameLabel.heightAnchor.constraint(equalToConstant: 40),
            
            startDraw.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            startDraw.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            startDraw.widthAnchor.constraint(equalToConstant: 50),
            startDraw.heightAnchor.constraint(equalToConstant: 40),
            
            geoFenceDropDown.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor, constant: 10),
            geoFenceDropDown.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            geoFenceDropDown.widthAnchor.constraint(equalToConstant: 50),
            geoFenceDropDown.heightAnchor.constraint(equalToConstant: 40),
            
            collectionView.topAnchor.constraint(equalTo: startDraw.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 90),
            
            mapView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 5),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7)
            
            
        ])
        // Configure the map with satellite imagery and rounded corners
        mapView.mapType = .hybrid
        mapView.layer.cornerRadius = 16
        mapView.layer.masksToBounds = true
        
        // Request location permission and start tracking the user's position
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        // Perform the initial data fetch and wire up the collection view
        updateData()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Poll the API every 45 seconds to keep collar locations fresh
        timer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: true){[weak self] _ in
            self?.updateTimer()
        }
    }
    @objc func refreshMap() {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(GeoFenceManager.shared.polygons)
        addPolygonsBack()
    }
    
    // MARK: - Data Refresh
    
    /// Called by the repeating timer — refreshes collar location data and reloads the collection view.
    func updateTimer(){
        self.updateData()
        self.collectionView.reloadData()
    }
    
    // MARK: - Geofence Drawing
    
    /// Converts a tap on the map into a coordinate and appends it to the in-progress geofence boundary.
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        currentPoints.append(coordinate)
        redrawCurrentLine()
    }
    
    /// Clears any existing temporary polylines and redraws the boundary line through all current points.
    func redrawCurrentLine() {
        let tempLines = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(tempLines)
        
        guard currentPoints.count > 1 else { return }
        
        let polyline = MKPolyline(coordinates: currentPoints, count: currentPoints.count)
        mapView.addOverlay(polyline)
    }
    
    /// Enters draw mode — attaches a tap gesture to the map so the user can tap points for a new geofence.
    @IBAction func startDrawingGeoFence(_ sender:Any){
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        self.mapView.addGestureRecognizer(tap)
        drawMode = true
        self.collectionView.reloadData()
    }
    
    
    // MARK: - MKMapViewDelegate
    
    /// Returns the appropriate renderer for map overlays — blue lines for in-progress geofences,
    /// red filled polygons for saved geofences.
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
    
    
    // MARK: - CLLocationManagerDelegate
    
    /// Forwards authorization status changes to the shared handler.
    func locationManager(_ manager: CLLocationManager) {
        handleAuthChange(manager.authorizationStatus)
    }
    
    /// Reacts to location permission changes — enables tracking when authorised, or shows a
    /// Settings prompt when the user has denied access.
    private func handleAuthChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            let alert = UIAlertController(
                title: "Location Access Required",
                message: "This app needs your location to track your dog's GPS collar. Please enable location access in Settings.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        case .notDetermined:
            // Still waiting for the system prompt decision
            break
        @unknown default:
            break
        }
    }
    /// Centers the map on the user's latest GPS position with a tight zoom level.
    func locationUpdate(_ manager:CLLocationManager, didUpdateLocation locations:[CLLocation]){
        guard let loc = locations.last else {return}
        
        let region = MKCoordinateRegion(
            center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
    }
    /// Responds to authorisation changes and begins receiving location updates when permitted.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    /// Fetches the latest GPS location from the API for every registered collar.
    func updateData(){
        for id in LocationUpdateManager.shared.dogs_ids{
            LocationUpdateManager.shared.load_data(d_id: id){success in print(success ? "updated data" : "failed to update")
            }
            guard let lat = LocationUpdateManager.shared.dogs_data[id]?.lat,
                  let lng = LocationUpdateManager.shared.dogs_data[id]?.lng else {return}
            let pin = MKPointAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            pin.title = id
            mapView.addAnnotation(pin)
          
        }
    }
        
        // MARK: - UICollectionViewDataSource & FlowLayout
        
        /// Returns the number of items: 3 action buttons in draw mode, or one card per dog otherwise.
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            switch drawMode{
            case true: return 3
                
            case false : return LocationUpdateManager.shared.dogs_data.count
            }
        }
        /// Returns smaller cells for draw-mode buttons, larger cells for dog status cards.
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            switch drawMode {
            case true:
                return CGSize(width: 100, height: 50) // Size for buttons
            case false:
                return CGSize(width: 150, height: 100) // Size for dog cells
            }
        }
        
        /// Dequeues and configures the appropriate cell — a draw-mode button (`inCell2`) or a
        /// dog status card (`inCell`) showing name, battery, and connection status.
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
                let id = LocationUpdateManager.shared.dogs_ids[indexPath.row]
                
                if let data = LocationUpdateManager.shared.dogs_data[id]{
                    cell.dog_name.text = id
                    cell.batter_percentage.text = "\(data.bat)%"
                    cell.status.text = data.status ? "Connected To Wifi" : "Using Sim Data"
                }
                return cell
            }
        }
    }

// MARK: - Draw Mode Button Actions
// Handles Save / Cancel / Reset actions triggered from the draw-mode collection view cells.
extension ViewController:buttonControl{
    /// Exits draw mode, removes the map tap gesture, and discards any in-progress points.
    func stopDrawingGeoFence(){
        drawMode = false
        collectionView.reloadData()
        clearZonesTapped()
    }
    
    /// Presents an alert to name the geofence, then saves the polygon to the server via `GeoFenceManager`.
    /// On success, clears the temporary polyline and re-renders all saved geofences.
    func finishZoneTapped() {
        let alert = UIAlertController(title: "Enter Geofence Name", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in textField.placeholder = "Boundary Name" }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let name = alert.textFields?.first?.text ?? "Unknown"
            guard self.currentPoints.count > 2 else { return }
            
            GeoFenceManager.shared.add(name: name, points: self.currentPoints) { success in
                guard success else {
                    print("Failed to save fence")
                    return
                }
                DispatchQueue.main.async {
                    let tempLines = self.mapView.overlays.filter { $0 is MKPolyline }
                    self.mapView.removeOverlays(tempLines)
                    
                    self.currentPoints.removeAll()
                    self.drawMode = false
                    self.addPolygonsBack()
                    self.collectionView.reloadData()
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.clearZonesTapped()
        })
        
        present(alert, animated: true)
    }
    
    /// Removes the in-progress polyline from the map and clears all collected tap points.
    func clearZonesTapped() {
        let tempLines = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(tempLines)
        currentPoints.removeAll()
        
    }
    /// Re-adds all saved geofence polygons as map overlays (called after a save or cancel).
    func addPolygonsBack(){
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(GeoFenceManager.shared.polygons)
    }
}

// MARK: - Dog Status Cell

/// Collection view cell that displays a single dog's name, battery percentage, and connection status.
class inCell:UICollectionViewCell{
    @IBOutlet weak var dog_name: UILabel!
    @IBOutlet weak var  batter_percentage: UILabel!
    @IBOutlet weak var status: UILabel!
    
    /// Lays out labels vertically and applies a rounded card style with a subtle shadow.
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

/// Delegate protocol for the three draw-mode action buttons (Save / Cancel / Reset).
protocol buttonControl:AnyObject{
    func finishZoneTapped()
    func clearZonesTapped()
    func stopDrawingGeoFence()
}

// MARK: - Draw Mode Button Cell

/// Collection view cell containing a single action button used during geofence drawing
/// (Save, Cancel, or Reset). Delegates tap actions back to the view controller via `buttonControl`.
class inCell2:UICollectionViewCell{
    weak var delegate: buttonControl?
    @IBOutlet weak var button: UIButton!
    
    /// Styles the cell with a rounded background and centres the button label.
    override func awakeFromNib(){
        super.awakeFromNib()
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        button.titleLabel?.textAlignment = .center

    }
    /// Index that maps this cell to a draw-mode action (0 = Save, 1 = Cancel, 2 = Reset).
    var num = Int()
    
    /// Stores the button index so `didClick` can dispatch the correct action.
    func setInt(i:Int){
        num = i
    }
    
    /// Dispatches the tap to the appropriate delegate method based on the button index.
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
