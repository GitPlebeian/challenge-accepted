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

protocol PhotoSelectedDelegate: class {
    // needed to get back the image from photo library or camera
    func photoSelected(image: UIImage)
}

class CreateChallengeViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tagsTextField: UITextField!
    
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var selectLocationButton: UIButton!
    @IBOutlet weak var createChallengeButton: UIButton!
    
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var uploadImageButton: UIButton!
    
    @IBOutlet weak var selectedImage: UIImageView!
    
    let locationManager = CLLocationManager()
    var timer = false
    var countDown = false
    var challengeLocation: CLLocationCoordinate2D?
    
    weak var delegate: PhotoSelectedDelegate?
    
    // MARK: - Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    
    // MARK: - Actions
    @IBAction func useCurrentLocationButtonTapped(_ sender: Any) {
        guard let location = locationManager.location?.coordinate else { return }
        challengeLocation = location
    }
    @IBAction func selectLocationButtonTapped(_ sender: Any) {
        guard let mapVC = UIStoryboard(name: "CreateChallenge", bundle: nil).instantiateViewController(identifier: "CreateChallengeMap") as? CreateChallengeMapViewController else { return }
        mapVC.delegate = self
        mapVC.modalPresentationStyle = .fullScreen
        present(mapVC, animated: true)
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
        let feedback = UINotificationFeedbackGenerator()
        guard let title = titleTextField.text,
            title.isEmpty == false,
            let description = descriptionTextView.text,
        description.isEmpty == false,
            let challengeImage = selectedImage.image,
            let tagString = tagsTextField.text,
            tagString.isEmpty == false else {
                feedback.notificationOccurred(.error)
                return
        }
        var hashtags: [String] {
                   return tagString
                       .split(separator: " ") // divide into 'substrings'
                       .map { String($0) } // turn back into 'strings'
//                       .filter { $0.hasPrefix("#") } // only keep #strings
               }
        
        if challengeLocation == nil {
            guard let currentLocation = locationManager.location?.coordinate else { return }
            ChallengeController.shared.createChallenge(title: title, description: description, longitude: currentLocation.longitude, latitude: currentLocation.latitude, tags: hashtags, photo: challengeImage) { (success) in
                DispatchQueue.main.async {
                    if success {
                        feedback.notificationOccurred(.success)
                        print("A challenge was saved")
                    } else {
                        print("There was an error saving challenge")
                        feedback.notificationOccurred(.error)
                    }
                }
            }
        } else {
            guard let selectedLocation = challengeLocation else { return }
            ChallengeController.shared.createChallenge(title: title, description: description, longitude: selectedLocation.longitude, latitude: selectedLocation.latitude, tags: hashtags, photo: challengeImage) { (success) in
                DispatchQueue.main.async {
                    if success {
                        feedback.notificationOccurred(.success)
                        print("A challenge was saved")
                    } else {
                        print("There was an error saving challenge")
                        feedback.notificationOccurred(.error)
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Methods
    func updateViews() {
        self.title = "Create Challenge"
        selectedImage.isHidden = false
        currentLocationButton.layer.cornerRadius = currentLocationButton.frame.height / 2
        selectLocationButton.layer.cornerRadius = selectLocationButton.frame.height / 2
        createChallengeButton.layer.cornerRadius = createChallengeButton.frame.height / 2
        
        uploadImageButton.layer.cornerRadius = 16
        takePictureButton.layer.cornerRadius = 16
        titleTextField.layer.cornerRadius = 6
        descriptionTextView.layer.cornerRadius = 6
        tagsTextField.layer.cornerRadius = 6
        
        titleTextField.layer.borderColor = UIColor.black.cgColor
        titleTextField.layer.borderWidth = 1
        descriptionTextView.layer.borderColor = UIColor.black.cgColor
        descriptionTextView.layer.borderWidth = 1
        tagsTextField.layer.borderColor = UIColor.black.cgColor
        tagsTextField.layer.borderWidth = 1
        
        descriptionTextView.backgroundColor = .white
        titleTextField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        tagsTextField.attributedPlaceholder = NSAttributedString(string: "Tags: Seperate With Spaces", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    
    fileprivate func presentPhotoPickerController() {
        DispatchQueue.main.async {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true)
        }
    }
    
    func presentCamera() {
        DispatchQueue.main.async {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true)
        }
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
    
    fileprivate func requestCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.presentCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    self.presentCamera()
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
            delegate?.photoSelected(image: selectedImage)
            self.selectedImage.image = selectedImage
            self.selectedImage.isHidden = false
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
