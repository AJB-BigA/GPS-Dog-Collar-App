//
//  File.swift
//  GPS Tracker
//
//  Created by Austin Baker on 19/11/2025.
//

import Foundation
import UIKit
import MapKit

class GeoFenceViewController : UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var cancelButton: UIView!
    
    var currentPoints: [CLLocationCoordinate2D] = []
    
    var exclusionZones: [MKPolygon] = []
    
    private let locationManager = CLLocationManager()
    override func viewDidLoad() {
        
        mapView.mapType = .hybrid
        //ask user for permission to use this info
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.layer.cornerRadius = 16
        mapView.layer.masksToBounds = true
        mapView.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tap)
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

    // Call this when user presses “Finish zone”
    @IBAction func finishZoneTapped(_ sender: Any) {
        guard currentPoints.count > 2 else { return }  // need at least triangle

        let polygon = MKPolygon(coordinates: currentPoints, count: currentPoints.count)
        exclusionZones.append(polygon)

        // Clear temporary line
        let tempLines = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(tempLines)

        mapView.addOverlay(polygon)
        currentPoints.removeAll()
    }

    // Optional: button to clear everything
    @IBAction func clearZonesTapped(_ sender: Any) {
        currentPoints.removeAll()
        exclusionZones.removeAll()
        mapView.removeOverlays(mapView.overlays)
    }
    
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
            center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.005))
        mapView.setRegion(region, animated: true)
    }
    
    //saves the users update prefrence
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    
    // MARK: - MKMapViewDelegate
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
}
