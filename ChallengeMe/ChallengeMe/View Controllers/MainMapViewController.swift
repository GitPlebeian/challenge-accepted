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
    @IBOutlet weak var createChallengeButton: UIButton!
    
    // MARK: - Properties
    
    let regionInMeters: Double = 5000
    let locationManager = CLLocationManager()
    var currentAnnotations: [MKAnnotation] = []
    var waitingForSearch = true
    var currentSearchArea: MKPolyline?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        checkLocationServices()
        updateViews()
    }
    
    // MARK: - Actions
    
    @IBAction func createChallengeButtonTapped(_ sender: Any) {
        let createChallengeStoryboard = UIStoryboard(name: "CreateChallenge", bundle: nil)
        let viewController = createChallengeStoryboard.instantiateViewController(withIdentifier: "createChallengeNavigationController")
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func searchThisAreaButtonTapped(_ sender: Any) {
        if waitingForSearch == false {
            disableSearchThisAreaButton()
        } else {
            return
        }
        
        if let searchArea = currentSearchArea {
            map.removeOverlay(searchArea)
        }
        var cordinateArray: [CLLocationCoordinate2D] = []
        let latitude = map.centerCoordinate.latitude
        let longitude = map.centerCoordinate.longitude
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude + ChallengeController.shared.searchAreaMeasurement, longitude: map.centerCoordinate.longitude - ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
            
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude + ChallengeController.shared.searchAreaMeasurement, longitude: map.centerCoordinate.longitude + ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
            
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude - ChallengeController.shared.searchAreaMeasurement, longitude: map.centerCoordinate.longitude + ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
            
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude - ChallengeController.shared.searchAreaMeasurement, longitude: map.centerCoordinate.longitude - ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
            
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude + ChallengeController.shared.searchAreaMeasurement, longitude: map.centerCoordinate.longitude - ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
        
        let line = MKPolyline(coordinates: cordinateArray, count: 5)
        currentSearchArea = line
        map.addOverlay(line)
        
        map.removeAnnotations(self.currentAnnotations)
        ChallengeController.shared.fetchChallenges(longitude: map.centerCoordinate.longitude, latitude: map.centerCoordinate.latitude) { (success) in
            DispatchQueue.main.async {
                let feedback = UINotificationFeedbackGenerator()
                if success {
                    feedback.notificationOccurred(.success)
                    self.waitingForSearch = false
                    self.enableSearchThisAreaButton()
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
    
    func disableSearchThisAreaButton() {
        searchThisAreaButton.isEnabled = false
        UIView.animate(withDuration: 0.2) {
            self.searchThisAreaButton.alpha = 0.5
        }
    }
    
    func enableSearchThisAreaButton() {
        searchThisAreaButton.isEnabled = true
        UIView.animate(withDuration: 0.2) {
            self.searchThisAreaButton.alpha = 1
        }
    }
    
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
            updateMapViewForLoad()
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
        disableSearchThisAreaButton()
        map.removeAnnotations(self.currentAnnotations)
        ChallengeController.shared.fetchChallenges(longitude: locationToLoad.longitude, latitude: locationToLoad.latitude) { (success) in
            DispatchQueue.main.async {
                print("\(ChallengeController.shared.challenges.count)")
                if success {
                    self.waitingForSearch = false
                    self.enableSearchThisAreaButton()
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
        let challengeDetailStoryboard = UIStoryboard(name: "ChallengeDetail", bundle: nil)
        let viewController = challengeDetailStoryboard.instantiateViewController(withIdentifier: "challengeDetail")
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(viewController, animated: true)
//        let placemark = MKPlacemark(coordinate: view.annotation!.coordinate)
//        let mapItem = MKMapItem(placemark: placemark)
//        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
//        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let overlay = overlay as? MKPolyline else {return MKOverlayRenderer()}
        let polyLineRender = MKPolylineRenderer(polyline: overlay)
        polyLineRender.strokeColor = .blue
        polyLineRender.lineWidth = 1
        return polyLineRender
    }
}

