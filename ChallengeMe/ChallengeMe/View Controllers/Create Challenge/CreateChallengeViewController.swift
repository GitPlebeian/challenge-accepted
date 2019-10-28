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
        descriptionTextView.delegate = self
    }
    
    // MARK: - Actions
    
    // Segues to the select location map view controller
    @IBAction func selectLocationButtonTapped(_ sender: Any) {
        guard let mapVC = UIStoryboard(name: "CreateChallenge", bundle: nil).instantiateViewController(identifier: "CreateChallengeMap") as? CreateChallengeMapViewController else { return }
        mapVC.delegate = self
        if let title = titleTextField.text {
            mapVC.challengeTitle = title
        }
        navigationController?.pushViewController(mapVC, animated: true)
    }
    
    // Attempts to present image selector
    @IBAction func uploadImageButtonTapped(_ sender: Any) {
        // checks to see if there are any photos in the photo library to access
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            requestPhotoLibraryAuthorization()
        }
    }
    
    // Attempts to take a picture after authorizaiton is granted.
    @IBAction func takePictureButtonTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            requestCameraAuthorization()
        }
    }
    
    // Attempts to create a challenge if the user filled out all of the fields.
    @IBAction func createChallengeButtonTapped(_ sender: Any) {
        let feedback = UINotificationFeedbackGenerator()
        guard let title = titleTextField.text, title.isEmpty == false else {
            presentBasicAlert(title: "Title", message: "Please fill out the title")
            feedback.notificationOccurred(.error)
            return
        }
        guard let description = descriptionTextView.text, description.isEmpty == false else {
            presentBasicAlert(title: "Description", message: "Please fill out the description")
            feedback.notificationOccurred(.error)
            return
        }
        guard let challengeImage = selectedImage.image else {
            presentBasicAlert(title: "Image", message: "Please select an image")
            feedback.notificationOccurred(.error)
            return
        }
        guard let tagString = tagsTextField.text, tagString.isEmpty == false else {
            feedback.notificationOccurred(.error)
            presentBasicAlert(title: "Tags", message: "Please fill out the challenge tags")
            return
        }
        guard let challengeLocation = challengeLocation else {
            feedback.notificationOccurred(.error)
            presentBasicAlert(title: "Location", message: "Please select a location")
            return
        }
        
        var onlySpaces = true
        for character in title {
            if character != " " {
                onlySpaces = false
            }
        }
        if onlySpaces == true {
            presentBasicAlert(title: "Title", message: "Title cannot contain only spaces")
            return
        }
        onlySpaces = true
        for character in tagString {
            if character != " " {
                onlySpaces = false
            }
        }
        if onlySpaces == true {
            presentBasicAlert(title: "Tags", message: "Tags cannot contain only spaces")
            return
        }
        
        onlySpaces = true
        for character in description {
            if character != " " {
                onlySpaces = false
            }
        }
        if onlySpaces == true {
            presentBasicAlert(title: "Description", message: "Description cannot contain only spaces")
            return
        }
        
        var hashtags: [String] {
            return tagString
                .split(separator: " ") // divide into 'substrings'
                .map { String($0) } // turn back into 'strings'
        }
        
        if connectedToICloud() == false {
            presentBasicAlert(title: "ICloud", message: "You must have ICloud drive enabled to save challenges")
            return
        }
        
        feedback.prepare()
        ChallengeController.shared.createChallenge(title: title, description: description, longitude: challengeLocation.longitude, latitude: challengeLocation.latitude, tags: hashtags, photo: challengeImage) { (challenge) in
            self.createChallengeCompletion(challenge: challenge, feedback: feedback)
        }
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Custom Methods
    
    // checks icloud connection
    func connectedToICloud() -> Bool{
        if FileManager.default.ubiquityIdentityToken == nil {
            return false
        } else {
            return true
        }
    }
    
    // Presents alert with an ok button that does nothing
    func presentBasicAlert(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    // Adds the tool bar to the keyboard.
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
    
    // Handles if the creation of a challenge was successful
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
    
    // Updates ui on view did load
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
    
    // Tells user they they did not fill out all of the fields
    func presentEmptyFieldsAlert() {
        let alert = UIAlertController(title: "Uh-Oh!", message: "Looks like you forgot something. Please ensure all fields are completed", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    // Presents photo picker controller
    fileprivate func presentPhotoPickerController() {
        DispatchQueue.main.async {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true)
        }
    }
    
    // Presents Camera
    func presentCamera() {
        DispatchQueue.main.async {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true)
        }
    }
    
    // request authorization to access photos
    fileprivate func requestPhotoLibraryAuthorization() {
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
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
    }
    
    // Requests camera authorization
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
    
    // Sets the location of where the challenge should be created
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
    
    // Dismisses the picture image selection view
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

extension CreateChallengeViewController: UITextFieldDelegate, UITextViewDelegate {
    
    // Gets rid of keyboard when return button is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Sets max length for tags and title field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= 50
    }
    
    // Sets max length for description
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= 150
    }
}
