//
//  CreateChallengeViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/2/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class CreateChallengeViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var selectLocationButton: UIButton!
    @IBOutlet weak var measurementTextField: UITextField!
    @IBOutlet weak var countingUpButton: UIButton!
    @IBOutlet weak var countingDownButton: UIButton!
    @IBOutlet weak var hoursTextField: UITextField!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var minutesTextField: UITextField!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var secondsTextField: UITextField!
    @IBOutlet weak var secondsLabel: UILabel!
    @IBOutlet weak var createChallengeButton: UIButton!
    
    // MARK: - Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    @IBAction func useCurrentLocationButtonTapped(_ sender: Any) {
    }
    @IBAction func selectLocationButtonTapped(_ sender: Any) {
    }
    @IBAction func timerSwitchToggled(_ sender: Any) {
    }
    @IBAction func countingUpButtonTapped(_ sender: Any) {
    }
    @IBAction func countingDownButtonTapped(_ sender: Any) {
    }
    @IBAction func uploadImageButtonTapped(_ sender: Any) {
    }
    @IBAction func takePictureButtonTapped(_ sender: Any) {
    }
    @IBAction func createChallengeButtonTapped(_ sender: Any) {
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
