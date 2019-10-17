//
//  SetupViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/8/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import Photos

class SetupViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var uploadPhotoButton: UIButton!
    @IBOutlet weak var saveUsernameButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var setUserStackView: UIStackView!
    @IBOutlet weak var loadingDataActivityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    weak var delegate: PhotoSelectedDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        updateViews()
        loadUser()
    }
    
    // MARK: - Actions
    @IBAction func uploadPhotoButtonTapped(_ sender: Any) {
        presentImagePicker()
    }
    
    @IBAction func saveUsernameButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text, username.isEmpty == false else {return}
        UserController.shared.createCurrentUser(username: username, profilePhoto: profilePhotoImageView.image) { (success) in
            DispatchQueue.main.async {
                if success {
                    let mainTabBarStoryboard = UIStoryboard(name: "TabBar", bundle: nil)
                    let viewController = mainTabBarStoryboard.instantiateViewController(withIdentifier: "mainTabBar")
                    viewController.modalPresentationStyle = .fullScreen
                    self.present(viewController, animated: true, completion: nil)
                } else {
                    self.presentErrorAlertForSaveUser(title: "Database", message: "We couldn't connect to the database. Please try again in a bit")
                }
            }
        }
    }
    @IBAction func refreshButtonTapped(_ sender: Any) {
        refreshButton.isHidden = true
        loadingDataActivityIndicator.isHidden = false
        loadUser()
    }
    
    // MARK: - Custom Functions
    
    func updateViews() {
        usernameTextField.layer.cornerRadius = usernameTextField.frame.height / 2
        refreshButton.layer.cornerRadius = refreshButton.frame.height / 2
        saveUsernameButton.layer.cornerRadius = saveUsernameButton.frame.height / 2
        loadingDataActivityIndicator.startAnimating()
        profilePhotoImageView.isHidden = true
        uploadPhotoButton.isHidden = true
    }
    
    func loadUser() {
        UserController.shared.fetchCurrentUser { (networkSuccess, userExists) in
            DispatchQueue.main.async {
                self.loadingDataActivityIndicator.isHidden = true
                self.setUserStackView.isHidden = true
                self.uploadPhotoButton.isHidden = true
                self.profilePhotoImageView.isHidden = true
                if networkSuccess {
                    if userExists {
                        let mainTabBarStoryboard = UIStoryboard(name: "TabBar", bundle: nil)
                        let viewController = mainTabBarStoryboard.instantiateViewController(withIdentifier: "mainTabBar")
                        viewController.modalPresentationStyle = .fullScreen
                        self.present(viewController, animated: true, completion: nil)
                    } else {
                        self.setUserStackView.isHidden = false
                        self.uploadPhotoButton.isHidden = false
                    }
                } else {
                    self.presentErrorAlertForFetch(title: "Database", message: "We couldn't connect to the database. Please try again in a bit")
                }
            }
        }
    }
    
    func presentErrorAlertForFetch(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: title, style: .default) { (_) in
            self.refreshButton.isHidden = false
        }
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    func presentErrorAlertForSaveUser(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: title, style: .default) { (_) in
            self.refreshButton.isHidden = false
            self.setUserStackView.isHidden = true
        }
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    func presentErrorAlertForImagePicker(error: Error?) {
        guard let error = error else { return }
        let alert = UIAlertController(title: "Error", message: "There was an error, and we were unable to complete this action. If this continues to happen, please email challengeacceptedhelp@gmail.com . \(error.localizedDescription)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    func presentImagePicker() {
        let alertController = UIAlertController(title: "Choose a photo", message: nil, preferredStyle: .actionSheet)
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let camera = UIAlertAction(title: "Camera", style: .default) { (_) in
            imagePicker.sourceType = .camera
            self.requestCameraAuthorization(imagePicker: imagePicker)
        }
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (_) in
            imagePicker.sourceType = .photoLibrary
            self.requestPhotoLibraryAuthorization(imagePicker: imagePicker)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            imagePicker.dismiss(animated: true)
        }
        
        alertController.addAction(camera)
        alertController.addAction(photoLibrary)
        alertController.addAction(cancel)
        self.present(alertController, animated: true)
    }
    
    fileprivate func requestPhotoLibraryAuthorization(imagePicker: UIImagePickerController) {
        // request authorization to access photos
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    self.present(imagePicker, animated: true)
                }
            case .notDetermined:
                if status == PHAuthorizationStatus.authorized {
                    DispatchQueue.main.async {
                        self.present(imagePicker, animated: true)
                    }
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
    
    fileprivate func requestCameraAuthorization(imagePicker: UIImagePickerController) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.present(imagePicker, animated: true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.present(imagePicker, animated: true)
                    }
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
            print("Unknown Switch")
        }
    }

}

// Mark: - Image Picker Delegate
extension SetupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            delegate?.photoSelected(image: selectedImage)
            self.profilePhotoImageView.image = selectedImage
            profilePhotoImageView.isHidden = false
            uploadPhotoButton.isHidden = true
            UserController.shared.currentUser?.profilePhoto = selectedImage
            UserController.shared.updateUser { (success) in
                if success {
                    print("User successfully updated profile photo")
                } else {
                    self.presentErrorAlertForImagePicker(error: nil)
                }
            }
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
