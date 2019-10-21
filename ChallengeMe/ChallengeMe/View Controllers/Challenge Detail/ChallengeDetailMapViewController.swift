//
//  ChallengeDetailMapViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/16/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ChallengeDetailMapViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var getDirectionsButton: UIButton!
    
    // MARK: - Properties
    
    var challenge: Challenge? {
        didSet {
            updateMapForChallenge()
        }
    }
    let regionInMeters: Double = 10000
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    
    // MARK: - Actions
    
    // Goes to the maps app for directions to the challenge
    @IBAction func getDirectionsButtonTapped(_ sender: Any) {
        guard let challenge = challenge else {return}
        let coordinate = CLLocationCoordinate2D(latitude: challenge.latitude, longitude: challenge.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    // MARK: - Custom Functions
    
    // Centers map on top of the challenge
    func updateMapForChallenge() {
        loadViewIfNeeded()
        guard let challenge = challenge else {return}
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: challenge.latitude, longitude: challenge.longitude)
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        map.setRegion(region, animated: true)
    }
    
    func updateViews() {
        getDirectionsButton.layer.cornerRadius = getDirectionsButton.frame.height / 2
    }
}

extension ChallengeDetailMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView
        let identifier = "marker"
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        view.image = UIImage(named: "challengeAnnotationIcon")
        view.canShowCallout = true
        view.calloutOffset = CGPoint(x: 0, y: -3)
        view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        view.rightCalloutAccessoryView?.tintColor = .black
        return view
    }
}
