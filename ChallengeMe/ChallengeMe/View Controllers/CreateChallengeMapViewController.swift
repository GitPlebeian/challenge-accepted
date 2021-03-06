//
//  CreateChallengeMapViewController.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/7/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol CreateChallengeMapDelegate: class {
    func didTap(at coordinates: CLLocationCoordinate2D)
}

class CreateChallengeMapViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var selectLocationMapView: MKMapView!
    @IBOutlet var mapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - Properties
    var challengeTitle: String?
    weak var delegate: CreateChallengeMapDelegate?
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 5000
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        centerMapOnUser()
    }
    
    // MARK: - Actions
    @IBAction func tappedOnMap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: selectLocationMapView)
        let coordinates = selectLocationMapView.convert(location, toCoordinateFrom: selectLocationMapView)
        delegate?.didTap(at: coordinates)
        
        let newChallenge = MKPointAnnotation()
        newChallenge.title = challengeTitle ?? ""
        newChallenge.coordinate = coordinates
        selectLocationMapView.addAnnotation(newChallenge)
    }
    @IBAction func confirmLocationButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    // MARK: - Custom Methods
    func centerMapOnUser() {
           if let location = locationManager.location?.coordinate {
               selectLocationMapView.showsUserLocation = true
               let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
               selectLocationMapView.setRegion(region, animated: true)
           }
       }
    
    
}
