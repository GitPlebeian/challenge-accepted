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
import MapKit

protocol PhotoSelectedDelegate: class {
    // needed to get back the image from photo library or camera
    func photoSelected(image: UIImage)
}

protocol SaveChallengeSuccessDelegate: class {
    func saveChallengeSuccess(challenge: Challenge?)
}

class CreateChallengeViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tagsTextField: UITextField!

    @IBOutlet weak var selectLocationButton: UIButton!
    @IBOutlet weak var createChallengeButton: UIButton!
    
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var uploadImageButton: UIButton!
    
    @IBOutlet weak var selectedImage: UIImageView!
    
    // MARK: - Properties
    let locationManager = CLLocationManager()
    var timer = false
    var countDown = false
    var challengeLocation: CLLocationCoordinate2D? {
        didSet {
            selectLocationButton.setTitle("Change Location", for: .normal)
        }
    }
    
    weak var delegate: PhotoSelectedDelegate?
    weak var saveChallengeDelegate: SaveChallengeSuccessDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        createToolBar()
        titleTextField.delegate = self
        tagsTextField.delegate = self
    }
    
    // MARK: - Actions

    @IBAction func selectLocationButtonTapped(_ sender: Any) {
        guard let mapVC = UIStoryboard(name: "CreateChallenge", bundle: nil).instantiateViewController(identifier: "CreateChallengeMap") as? CreateChallengeMapViewController else { return }
        mapVC.delegate = self
        if let title = titleTextField.text {
            mapVC.challengeTitle = title
        }
//        mapVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(mapVC, animated: true)
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
            tagString.isEmpty == false,
            tagString != " ",
            challengeLocation != nil else {
                feedback.notificationOccurred(.error)
                presentEmptyFieldsAlert()
                return
        }
        var hashtags: [String] {
                   return tagString
                       .split(separator: " ") // divide into 'substrings'
                       .map { String($0) } // turn back into 'strings'
               }
        feedback.prepare()
            guard let selectedLocation = challengeLocation else { return }
            ChallengeController.shared.createChallenge(title: title, description: description, longitude: selectedLocation.longitude, latitude: selectedLocation.latitude, tags: hashtags, photo: challengeImage) { (challenge) in
                self.createChallengeCompletion(challenge: challenge, feedback: feedback)
            }
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Custom Methods
    func createToolBar() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissKeyboard))
        toolBar.setItems([flexibleSpace, doneButton], animated: true)
        titleTextField.inputAccessoryView = toolBar
        descriptionTextView.inputAccessoryView = toolBar
        tagsTextField.inputAccessoryView = toolBar
    }
    
    @objc func dismissKeyboard() {
              view.endEditing(true)
    }
    
    func createChallengeCompletion(challenge: Challenge?, feedback: UINotificationFeedbackGenerator) {
        DispatchQueue.main.async {
            guard let saveChallengeDelegate = self.saveChallengeDelegate else {return}
            if let challenge = challenge {
                saveChallengeDelegate.saveChallengeSuccess(challenge: challenge)
                feedback.notificationOccurred(.success)
            } else {
                saveChallengeDelegate.saveChallengeSuccess(challenge: nil)
                feedback.notificationOccurred(.error)
            }
        }
    }
    
    func updateViews() {
        self.title = "Create Challenge"
        selectedImage.isHidden = false
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
        
        descriptionTextView.backgroundColor = .background
        titleTextField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        tagsTextField.attributedPlaceholder = NSAttributedString(string: "Tags: Seperate With Spaces", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        
        tabBarController?.tabBar.barTintColor = .tabBar
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        view.backgroundColor = .background
        
    }
    
    func presentEmptyFieldsAlert() {
        let alert = UIAlertController(title: "Uh-Oh!", message: "Looks like you forgot something. Please ensure all fields are completed", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .cancel)
        alert.addAction(ok)
        present(alert, animated: true)
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
            @unknown default:
                print("Unknown switch at \(#function)")
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
        @unknown default:
            print("Unknown switch at \(#function)")
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

extension CreateChallengeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = textField.text ?? ""

        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }

        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        // make sure the result is under 16 characters
        return updatedText.count <= 20
    }

    // Use this if you have a UITextView
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = textView.text ?? ""

        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }

        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)

        // make sure the result is under 16 characters
        return updatedText.count <= 150
    }
}
