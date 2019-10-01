//
//  ViewController.swift
//  locationTesting
//
//  Created by Jackson Tubbs on 9/30/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var mainMapView: MKMapView!
    
    // MARK: - Properties
    
    let regionInMeters: Double = 1000
    let locationManager = CLLocationManager()
    @IBOutlet var mapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainMapView.delegate = self
        mapGestureRecognizer.delegate = self
        checkLocationServices()
    }
    
    // MARK: - Actions
    
    @IBAction func tappedOnMap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: mainMapView)
        let coordinate = mainMapView.convert(location, toCoordinateFrom: mainMapView)
        
        let longdon = MKPointAnnotation()
        longdon.title = "Bois"
        longdon.coordinate = coordinate
        mainMapView.addAnnotation(longdon)
    }
    
    // MARK: - Custom Funcitons
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // Error handling
        }
    }
    
    func updateMapView() {
        if let location = locationManager.location?.coordinate {
            mainMapView.showsUserLocation = true
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mainMapView.setRegion(region, animated: true)
//            mainMapView.userLocation.title = ""
            
            let longdon = MKPointAnnotation()
            longdon.title = "Bois"
            longdon.coordinate = CLLocationCoordinate2D(latitude: location.latitude + 0.005 , longitude: location.longitude)
            mainMapView.addAnnotation(longdon)
        }
    }

    func checkLocationAuthorization() {
        switch  CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse: updateMapView()
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .denied:
            break
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        let identifier = "marker"
        var view: MKAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: 0, y: 3)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let placemark = MKPlacemark(coordinate: view.annotation!.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    
}
