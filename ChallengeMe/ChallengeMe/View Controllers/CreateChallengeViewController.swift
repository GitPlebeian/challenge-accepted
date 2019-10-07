//
//  CreateChallengeViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/2/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import Photos
import CoreLocation
import AVFoundation

class CreateChallengeViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var selectLocationButton: UIButton!
    @IBOutlet weak var measurementTextField: UITextField!
    @IBOutlet weak var timerSwitch: UISwitch!
    @IBOutlet weak var countingUpButton: UIButton!
    @IBOutlet weak var countingUpLabel: UILabel!
    @IBOutlet weak var countingDownButton: UIButton!
    @IBOutlet weak var countingDownLabel: UILabel!
    @IBOutlet weak var hoursTextField: UITextField!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var minutesTextField: UITextField!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var secondsTextField: UITextField!
    @IBOutlet weak var secondsLabel: UILabel!
    @IBOutlet weak var createChallengeButton: UIButton!
    
    let locationManager = CLLocationManager()
    var timer = false
    var countDown = false
    var challengeLocation: CLLocationCoordinate2D?
    var challengeImage: UIImage?
    let captureSession = AVCaptureSession()
    
    // MARK: - Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        loadViews()
        
    }
    
    // MARK: - Actions
    @IBAction func useCurrentLocationButtonTapped(_ sender: Any) {
        guard let location = locationManager.location?.coordinate else { return }
        challengeLocation = location
    }
    @IBAction func selectLocationButtonTapped(_ sender: Any) {
        guard let mapVC = UIStoryboard(name: "CreateChallenge", bundle: nil).instantiateViewController(identifier: "CreateChallengeMapViewController") as? CreateChallengeMapViewController else { return }
        mapVC.delegate = self
        mapVC.modalPresentationStyle = .fullScreen
        present(mapVC, animated: true)
    }
    @IBAction func timerSwitchToggled(_ sender: Any) {
        timer.toggle()
        toggleTimerView()
    }
    @IBAction func countingUpButtonTapped(_ sender: Any) {
        countDown.toggle()
        toggleCountDownView()
    }
    @IBAction func countingDownButtonTapped(_ sender: Any) {
        countDown.toggle()
        toggleCountDownView()
    }
    @IBAction func uploadImageButtonTapped(_ sender: Any) {
        // checks to see if there are any photos in the photo library to access
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            requestPhotoLibraryAuthorization()
        }
    }
    @IBAction func takePictureButtonTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            requestCameraAuthorization()
        }
    }
    @IBAction func createChallengeButtonTapped(_ sender: Any) {
        guard let title = titleTextField.text,
            let description = descriptionTextView.text,
            let location = challengeLocation,
            let measurement = measurementTextField.text,
            let challengeImage = challengeImage,
            let tagString = tagsTextField.text else { return }
        
        var hashtags: [String] {
            return tagString
            .split(separator: " ") // divide into 'substrings'
                .map { String($0) } // turn back into 'strings'
                .filter { $0.hasPrefix("#") } // only keep #strings
        }
        
        ChallengeController.shared.createChallenge(title: title, description: description, measurement: measurement, longitude: location.longitude, latitude: location.latitude, tags: hashtags, photo: challengeImage) { (success) in
            if success {
                print("A challenge was saved")
            } else {
                print("There was an error saving challenge")
            }
            
        }
    }
    
    // MARK: - Custom Methods
    func loadViews() {
        timerSwitch.setOn(false, animated: true)
        toggleTimerView()
        toggleCountDownView()
    }
    
    func toggleTimerView() {
        UIView.animate(withDuration: 0.2) {
            if self.timerSwitch.isOn == true {
                self.countingUpButton.isHidden = false
                self.countingDownButton.isHidden = false
                self.countingUpLabel.isHidden = false
                self.countingDownLabel.isHidden = false
                
            } else {
                self.countingUpButton.isHidden = true
                self.countingDownButton.isHidden = true
                self.countingUpLabel.isHidden = true
                self.countingDownLabel.isHidden = true
                self.hoursTextField.isHidden = true
                self.hoursLabel.isHidden = true
                self.minutesTextField.isHidden = true
                self.minutesLabel.isHidden = true
                self.secondsTextField.isHidden = true
                self.secondsLabel.isHidden = true
            }
        }
    }
    
    func toggleCountDownView() {
            UIView.animate(withDuration: 0.2) {
                if self.countDown == true {
                    self.hoursTextField.isHidden = false
                    self.hoursLabel.isHidden = false
                    self.minutesTextField.isHidden = false
                    self.minutesLabel.isHidden = false
                    self.secondsTextField.isHidden = false
                    self.secondsLabel.isHidden = false
                } else {
                    self.hoursTextField.isHidden = true
                    self.hoursLabel.isHidden = true
                    self.minutesTextField.isHidden = true
                    self.minutesLabel.isHidden = true
                    self.secondsTextField.isHidden = true
                    self.secondsLabel.isHidden = true
                }
            }
    }
    
    fileprivate func presentPhotoPickerController() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true)
    }
    
    fileprivate func requestPhotoLibraryAuthorization() {
           // request authorization to access photos
           PHPhotoLibrary.requestAuthorization { (status) in
               switch status {
               case .authorized:
                   self.presentPhotoPickerController()
               case .notDetermined:
                   if status == PHAuthorizationStatus.authorized {
                       self.presentPhotoPickerController()
                   }
               case .restricted:
                   let alert = UIAlertController(title: "Photo Library Restricted", message: "Photo Library access is restricted and cannot be accessed", preferredStyle: .alert)
                   let okay = UIAlertAction(title: "Ok", style: .default)
                   alert.addAction(okay)
                   self.present(alert, animated: true)
               case .denied:
                   let alert = UIAlertController(title: "Photo Library Denied", message: "Photo Library access was previously denied.  Please update your Settings.", preferredStyle: .alert)
                   let settings = UIAlertAction(title: "Settings", style: .default) { (action) in
                       DispatchQueue.main.async {
                           if let url = URL(string: UIApplication.openSettingsURLString) {
                               UIApplication.shared.open(url, options: [:])
                           }
                       }
                   }
                   let cancel = UIAlertAction(title: "Cancel", style: .cancel)
                   alert.addAction(settings)
                   alert.addAction(cancel)
                   self.present(alert, animated: true)
               }
           }
       }
    
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    fileprivate func requestCameraAuthorization() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.setupCaptureSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { (granted) in
                    if granted {
                        self.setupCaptureSession()
                    }
                }
            case .restricted:
                let alert = UIAlertController(title: "Camera Restricted", message: "Camera access is restricted and cannot be accessed", preferredStyle: .alert)
                let okay = UIAlertAction(title: "Ok", style: .default)
                alert.addAction(okay)
                self.present(alert, animated: true)
            case .denied:
                let alert = UIAlertController(title: "Camera Denied", message: "Camera access was previously denied.  Please update your Settings.", preferredStyle: .alert)
                let settings = UIAlertAction(title: "Settings", style: .default) { (action) in
                    DispatchQueue.main.async {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:])
                        }
                    }
                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel)
                alert.addAction(settings)
                alert.addAction(cancel)
                self.present(alert, animated: true)
            }
        }
}

extension CreateChallengeViewController: CreateChallengeMapDelegate {
    
    func didTap(at coordinates: CLLocationCoordinate2D) {
        challengeLocation = coordinates
    }
}

extension CreateChallengeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.challengeImage = selectedImage
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
