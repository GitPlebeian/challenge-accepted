//
//  CreateChallengeMapViewController.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/7/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import MapKit

protocol CreateChallengeMapDelegate: class {
    func didTap(at coordinates: CLLocationCoordinate2D)
}

class CreateChallengeMapViewController: UIViewController {
    
    @IBOutlet weak var selectLocationMapView: MKMapView!
    @IBOutlet var mapGestureRecognizer: UITapGestureRecognizer!
    
    weak var delegate: CreateChallengeMapDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tappedOnMap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: selectLocationMapView)
        let coordinates = selectLocationMapView.convert(location, toCoordinateFrom: selectLocationMapView)
        delegate?.didTap(at: coordinates)
    }
    @IBAction func confirmLocationButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    
}
