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
import FTLinearActivityIndicator

class MainMapViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var centerOnUserButton: UIButton!
    @IBOutlet weak var searchThisAreaButton: UIButton!
    @IBOutlet weak var createChallengeButton: UIButton!
    @IBOutlet weak var mainMapGestureRecognizer: MKMapView!
    @IBOutlet weak var numberOfChallengesLabel: UILabel!
    @IBOutlet weak var activityIndicator: FTLinearActivityIndicator!
    
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
        mainMapGestureRecognizer.delegate = self
        // Will remove annotation after challenge was deleted.
        NotificationCenter.default.addObserver(self, selector: #selector(removeAnnotationForChallengeDeletion(notification:)), name: NSNotification.Name(NotificationNameKeys.deletedChallengeKey), object: nil)
        activityIndicator.startAnimating()
    }
    
    // MARK: - Actions
    
    @IBAction func createChallengeButtonTapped(_ sender: Any) {
        let createChallengeStoryboard = UIStoryboard(name: "CreateChallenge", bundle: nil)
        guard let viewController = createChallengeStoryboard.instantiateViewController(withIdentifier: "createChallengeViewController") as? CreateChallengeViewController else {return}
        viewController.saveChallengeDelegate = self
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func searchThisAreaButtonTapped(_ sender: Any) {
        if waitingForSearch == false {
            disableSearchThisAreaButton()
        } else {
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.numberOfChallengesLabel.alpha = 0
        }) { (_) in
            self.numberOfChallengesLabel.isHidden = true
        }
        if let searchArea = currentSearchArea {
            map.removeOverlay(searchArea)
        }
        var cordinateArray: [CLLocationCoordinate2D] = []
        let latitude = map.centerCoordinate.latitude
        let longitude = map.centerCoordinate.longitude
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude + ChallengeController.shared.searchAreaMeasurement, longitude: longitude - ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
            
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude + ChallengeController.shared.searchAreaMeasurement, longitude: longitude + ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
            
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude - ChallengeController.shared.searchAreaMeasurement, longitude: longitude + ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
            
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude - ChallengeController.shared.searchAreaMeasurement, longitude: longitude - ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
            
        cordinateArray.append(CLLocationCoordinate2D(latitude: latitude + ChallengeController.shared.searchAreaMeasurement, longitude: longitude - ChallengeController.shared.getLongitudeMeasurementForLatitude(latitude: latitude)))
        
        let line = MKPolyline(coordinates: cordinateArray, count: 5)
        currentSearchArea = line
        map.addOverlay(line)
        self.activityIndicator.startAnimating()
        map.removeAnnotations(currentAnnotations)
        ChallengeController.shared.fetchChallenges(longitude: map.centerCoordinate.longitude, latitude: map.centerCoordinate.latitude) { (success) in
            DispatchQueue.main.async {
                let feedback = UINotificationFeedbackGenerator()
                self.activityIndicator.stopAnimating()
                self.waitingForSearch = false
                self.enableSearchThisAreaButton()
                self.currentAnnotations.removeAll(keepingCapacity: false)
                if success {
                    feedback.notificationOccurred(.success)
                    for challenge in ChallengeController.shared.challenges {
                        let coordinate = CLLocationCoordinate2D(latitude: challenge.latitude, longitude: challenge.longitude)
                        let annotation = MKPointAnnotation()
                        annotation.title = challenge.title
                        annotation.coordinate = coordinate
                        var subtitle = ""
                        for tag in challenge.tags {
                            if tag == challenge.tags.last! {
                                subtitle += tag
                            } else {
                                subtitle += tag + " "
                            }
                        }
                        annotation.subtitle = subtitle
                        self.currentAnnotations.append(annotation)
                    }
                    self.map.addAnnotations(self.currentAnnotations)
                    self.animateNumberOfChallenges()
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
    
    @objc func removeAnnotationForChallengeDeletion(notification: NSNotification) {
        DispatchQueue.main.async {
            var index = 0
            for annotation in self.currentAnnotations {
                guard let challenge = notification.userInfo!["challenge"] as? Challenge else {return}
                if annotation.coordinate.latitude == challenge.latitude &&
                    annotation.coordinate.longitude == challenge.longitude {
                    self.currentAnnotations.remove(at: index)
                    self.map.removeAnnotation(annotation)
                }
                index += 1
            }
        }
    }
    
    func disableSearchThisAreaButton() {
        searchThisAreaButton.isEnabled = false
        waitingForSearch = true
        UIView.animate(withDuration: 0.1) {
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
        createChallengeButton.layer.cornerRadius = createChallengeButton.frame.height / 2
        numberOfChallengesLabel.clipsToBounds = true
        numberOfChallengesLabel.layer.cornerRadius = numberOfChallengesLabel.frame.height / 2
        numberOfChallengesLabel.isHidden = true
        numberOfChallengesLabel.alpha = 0
        map.mapType = .standard
        title = "Accepted Challenges"
//        navigationController?.navigationBar.barTintColor = .black
        tabBarController?.tabBar.barTintColor = .tabBar
    }
    
    func animateNumberOfChallenges() {
        numberOfChallengesLabel.isHidden = false
        if currentAnnotations.count == 1 {
            numberOfChallengesLabel.text = "\(currentAnnotations.count) Challenge"
        } else if currentAnnotations.count > 1 {
            numberOfChallengesLabel.text = "\(currentAnnotations.count) Challenges"
        } else {
            numberOfChallengesLabel.text = "No Challenges Found"
        }
        UIView.animate(withDuration: 0.1, animations: {
            self.numberOfChallengesLabel.alpha = 1
        }) { (_) in
            var seconds = 0.0
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
                seconds += 0.5
                if self.waitingForSearch == true {
                    timer.invalidate()
                } else if seconds >= 4 {
                    timer.invalidate()
                    UIView.animate(withDuration: 0.2, animations: {
                        self.numberOfChallengesLabel.alpha = 0
                    }) { (_) in
                        self.numberOfChallengesLabel.isHidden = true
                    }
                }
            }
        }
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
                if success {
                    self.waitingForSearch = false
                    self.enableSearchThisAreaButton()
                    self.currentAnnotations.removeAll(keepingCapacity: false)
                    for challenge in ChallengeController.shared.challenges {
                        let annotation = MKPointAnnotation()
                        annotation.title = challenge.title
                        var subtitle = ""
                        for tag in challenge.tags {
                            if tag == challenge.tags.last! {
                                subtitle += tag
                            } else {
                                subtitle += tag + " "
                            }
                        }
                        annotation.subtitle = subtitle
                        let coordinate = CLLocationCoordinate2D(latitude: challenge.latitude, longitude: challenge.longitude)
                        annotation.coordinate = coordinate
                        self.currentAnnotations.append(annotation)
                    }
                    self.map.addAnnotations(self.currentAnnotations)
                    self.animateNumberOfChallenges()
                    // FIXME: - Uncomment
//                    self.activityIndicator.stopAnimating()
                } else {
                    self.presentBasicError(title: "Error", message: "We couldn't get Challenges from the database")
                }
            }
        }
    }
    
//    func checkLocationAuthorization() {
//        switch  CLLocationManager.authorizationStatus() {
//        case .authorizedWhenInUse: break
//        case .notDetermined: locationManager.requestWhenInUseAuthorization()
//        case .restricted:
//            break
//        case .denied:
//            break
//        case .authorizedAlways:
//            break
//        @unknown default:
//            break
//        }
//    }
}

extension MainMapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
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

        var view: MKAnnotationView
        let identifier = "marker"
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            print(annotation.coordinate)
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        view.canShowCallout = true
        view.calloutOffset = CGPoint(x: 0, y: -3)
        view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        view.rightCalloutAccessoryView?.tintColor = .black
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let challengeDetailVC = UIStoryboard(name: "ChallengeDetail", bundle: nil).instantiateViewController(withIdentifier: "challengeDetail") as? ChallengeDetailViewController else { return }
        
        for challenge in ChallengeController.shared.challenges {
            if challenge.latitude == view.annotation?.coordinate.latitude && challenge.longitude == view.annotation?.coordinate.longitude {
                challengeDetailVC.challenge = challenge
            }
        }
        
        challengeDetailVC.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(challengeDetailVC, animated: true)
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

extension MainMapViewController: SaveChallengeSuccessDelegate {
    func saveChallengeSuccess(challenge: Challenge?) {
        if let challenge = challenge {
            let annotation = MKPointAnnotation()
            annotation.title = challenge.title
            var subtitle = ""
            for tag in challenge.tags {
                if tag == challenge.tags.last! {
                    subtitle += tag
                } else {
                    subtitle += tag + " "
                }
            }
            annotation.subtitle = subtitle
            let coordinate = CLLocationCoordinate2D(latitude: challenge.latitude, longitude: challenge.longitude)
            annotation.coordinate = coordinate
            currentAnnotations.append(annotation)
            map.addAnnotation(annotation)
            animateNumberOfChallenges()
        } else {
            
        }
    }
}
