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
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var fetchButton: UIButton!
    @IBOutlet var mapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - Properties
    
    let regionInMeters: Double = 1000
    let locationManager = CLLocationManager()
    var currentAnnotations: [MKAnnotation] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        mapGestureRecognizer.delegate = self
        checkLocationServices()
        updateViews()
    }
    
    // MARK: - Actions
    
    @IBAction func tappedOnMap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: map)
        let coordinate = map.convert(location, toCoordinateFrom: map)
        
        let longdon = MKPointAnnotation()
        longdon.title = "Challenge"
        longdon.coordinate = coordinate
        ChallengeController.shared.createChallenge(title: "Challenge", description: "Challenge Descrioptions", measurement: "Time", longitude: coordinate.longitude, latitude: coordinate.latitude, photo: UIImage(named: "d")!) { (challenge) in
            DispatchQueue.main.async {
                if let challenge = challenge {
                    self.map.addAnnotation(longdon)
                    self.currentAnnotations.append(longdon)
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                }
            }
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        let feedback = UIImpactFeedbackGenerator()
        feedback.impactOccurred()
        
        
    }
    @IBAction func fetchButtonTapped(_ sender: Any) {
        let feedback = UIImpactFeedbackGenerator()
        feedback.impactOccurred()
        map.removeAnnotations(self.currentAnnotations)
        ChallengeController.shared.fetchChallenges(longitude: map.centerCoordinate.longitude, latitude: map.centerCoordinate.latitude) { (success) in
            DispatchQueue.main.async {
                let feedback = UINotificationFeedbackGenerator()
                print("\(ChallengeController.shared.challenges.count)")
                if success {
                    feedback.notificationOccurred(.success)
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
                }
                
            }
        }
    }
    // MARK: - Custom Funcitons
    
    func updateViews() {
        saveButton.layer.cornerRadius = saveButton.frame.height / 2
        fetchButton.layer.cornerRadius = fetchButton.frame.height / 2
    }
    
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
            map.showsUserLocation = true
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
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

extension MainMapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
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

extension MainMapViewController: UIGestureRecognizerDelegate {
    
}
