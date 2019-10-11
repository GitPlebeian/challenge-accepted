//
//  SettingsViewController.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/11/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import MessageUI
import Photos

class SettingsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var currentUserNameLabel: UILabel!
    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var editNameButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    
    // MARK: - Properties
    weak var delegate: PhotoSelectedDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Actions
    @IBAction func editProfilePhotoButtonTapped(_ sender: Any) {
        presentImagePicker()
    }
    @IBAction func editNameButtonTapped(_ sender: Any) {
        editNameButton.isHidden = true
        currentUserNameLabel.isHidden = true
        saveButton.isHidden = false
        nameTextField.isHidden = false
    }
    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let newName = nameTextField.text else { return }
        currentUserNameLabel.text = newName
        editNameButton.isHidden = false
        currentUserNameLabel.isHidden = false
        saveButton.isHidden = true
        nameTextField.isHidden = true
        UserController.shared.currentUser?.username = newName
        UserController.shared.updateUser { (success) in
            if success {
                print("User was successfully updated")
            } else {
                self.presentErrorAlert(error: nil)
            }
        }
    }
    @IBAction func deleteAccountButtonTapped(_ sender: Any) {
        presentDeleteAlert()
    }
    @IBAction func supportButtonTapped(_ sender: Any) {
        showMailComposer()
    }
    @IBAction func privacyPolicyButtonTapped(_ sender: Any) {
        if let url = URL(string: "website") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Custom Methods
    func showMailComposer() {
        guard MFMailComposeViewController.canSendMail() else { presentEmailAlert(); return }
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["email"])
        composer.setSubject("Support/Feedback")
        composer.setMessageBody("Thank you for reaching out. We welcome any feedback to help make our app better, and offer support with any issues you may run into!", isHTML: false)
        present(composer, animated: true)
    }
    
    func presentDeleteAlert() {
        guard let currentUser = UserController.shared.currentUser else { return }
        let alert = UIAlertController(title: "Delete Account?", message: "Are you sure you'd like to delete your account?", preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "Delete", style: .destructive) { (delete) in
            UserController.shared.deleteUser(user: currentUser) { (success) in
                if success {
                    print("User was successfully removed")
                } else {
                    self.presentErrorAlert(error: nil)
                }
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(delete)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    func presentEmailAlert() {
           let alert = UIAlertController(title: "Error", message: "Unable to access Mail. Please email ... with a description of the issue you experienced.", preferredStyle: .alert)
           let ok = UIAlertAction(title: "OK", style: .cancel)
           alert.addAction(ok)
           present(alert, animated: true)
    }
    
    func presentErrorAlert(error: Error?) {
        guard let error = error else { return }
        let alert = UIAlertController(title: "Error", message: "There was an error, and we were unable to complete this action. If this continues to happen, please email ... . \(error.localizedDescription)", preferredStyle: .alert)
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
            self.dismiss(animated: true)
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
                self.present(imagePicker, animated: true)
            case .notDetermined:
                if status == PHAuthorizationStatus.authorized {
                    self.present(imagePicker, animated: true)
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
    
    fileprivate func requestCameraAuthorization(imagePicker: UIImagePickerController) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.present(imagePicker, animated: true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    self.present(imagePicker, animated: true)
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

    // MARK: - Mail Delegate
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            presentErrorAlert(error: error)
            controller.dismiss(animated: true)
            return
        }
        
        switch result {
        case .cancelled:
            break
        case .failed:
            if let error = error {
                presentErrorAlert(error: error)
            }
        case .saved:
            break
        case .sent:
            break
        }
        controller.dismiss(animated: true)
    }
}

    // Mark: - Image Picker Delegate
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            delegate?.photoSelected(image: selectedImage)
            self.profilePhotoImageView.image = selectedImage
            UserController.shared.currentUser?.profilePhoto = selectedImage
            UserController.shared.updateUser { (success) in
                if success {
                    print("User successfully updated profile photo")
                } else {
                    self.presentErrorAlert(error: nil)
                }
            }
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
