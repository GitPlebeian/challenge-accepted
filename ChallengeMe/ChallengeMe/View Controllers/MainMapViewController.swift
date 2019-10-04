//
//  MainMapViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/2/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MainMapViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var centerOnUserButton: UIButton!
    @IBOutlet weak var searchThisAreaButton: UIButton!
    
    // MARK: - Properties
    
    let regionInMeters: Double = 5000
    let locationManager = CLLocationManager()
    var currentAnnotations: [MKAnnotation] = []
    var waitingForSearch = true
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        checkLocationServices()
        updateViews()
    }
    
    // MARK: - Actions
    
    
    @IBAction func searchThisAreaButtonTapped(_ sender: Any) {
        if waitingForSearch == false {
            
        } else {
            
        }
        map.removeAnnotations(self.currentAnnotations)
        ChallengeController.shared.fetchChallenges(longitude: map.centerCoordinate.longitude, latitude: map.centerCoordinate.latitude) { (success) in
            DispatchQueue.main.async {
                let feedback = UINotificationFeedbackGenerator()
                if success {
                    feedback.notificationOccurred(.success)
                    self.waitingForSearch = false
                    self.currentAnnotations.removeAll(keepingCapacity: false)
                    for challenge in ChallengeController.shared.challenges {
                        let annotation = MKPointAnnotation()
                        annotation.title = challenge.title
                        let coordinate = CLLocationCoordinate2D(latitude: challenge.latitude, longitude: challenge.longitude)
                        annotation.coordinate = coordinate
                        self.currentAnnotations.append(annotation)
                    }
                    self.map.addAnnotations(self.currentAnnotations)
                } else {
                    feedback.notificationOccurred(.error)
                    self.presentBasicError(title: "Error", message: "We couldn't get Challenges from the database")
                }
            }
        }
    }
    
    @IBAction func centerOnUserButtonTapped(_ sender: Any) {
        centerMapOnUser()
    }
    
    // MARK: - Custom Funcitons
    
    func presentBasicError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    func centerMapOnUser() {
        if let location = locationManager.location?.coordinate {
            map.showsUserLocation = true
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
        }
    }
    
    func updateViews() {
        centerOnUserButton.layer.cornerRadius = centerOnUserButton.frame.height / 2
        searchThisAreaButton.layer.cornerRadius = searchThisAreaButton.frame.height / 2
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
//            checkLocationAuthorization()
        } else {
            // Error handling
        }
    }
    
    func updateMapViewForLoad() {
        var locationToLoad: CLLocationCoordinate2D
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        } else if let location = locationManager.location?.coordinate {
            map.showsUserLocation = true
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
            locationToLoad = location
        } else {
            locationToLoad = map.centerCoordinate
        }
        map.removeAnnotations(self.currentAnnotations)
        ChallengeController.shared.fetchChallenges(longitude: locationToLoad.longitude, latitude: locationToLoad.latitude) { (success) in
            DispatchQueue.main.async {
                print("\(ChallengeController.shared.challenges.count)")
                if success {
                    self.waitingForSearch = false
                    self.currentAnnotations.removeAll(keepingCapacity: false)
                    for challenge in ChallengeController.shared.challenges {
                        let annotation = MKPointAnnotation()
                        annotation.title = challenge.title
                        let coordinate = CLLocationCoordinate2D(latitude: challenge.latitude, longitude: challenge.longitude)
                        annotation.coordinate = coordinate
                        self.currentAnnotations.append(annotation)
                    }
                    self.map.addAnnotations(self.currentAnnotations)
                } else {
                    self.presentBasicError(title: "Error", message: "We couldn't get Challenges from the database")
                }
            }
        }
    }
    
    func checkLocationAuthorization() {
        switch  CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse: break
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

extension MainMapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did UPDATE locations")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateMapViewForLoad()
    }
}

extension MainMapViewController: MKMapViewDelegate {
    
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
