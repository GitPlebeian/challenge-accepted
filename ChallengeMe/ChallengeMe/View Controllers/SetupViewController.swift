//
//  SetupViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/8/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import Photos
import SystemConfiguration

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
    var userImage: UIImage?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        updateViews()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadUser()
    }
    
    // MARK: - Actions
    
    @IBAction func uploadPhotoButtonTapped(_ sender: Any) {
        presentImagePicker()
    }

    // Attemps to create a new user based on their input
    @IBAction func saveUsernameButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text, username.isEmpty == false else {return}
        var onlySpaces = true
        for character in username {
            if character != " " {
                onlySpaces = false
            }
        }
        if onlySpaces == true {
            presentBasicAlert(title: "Username", message: "You cannot only have spaces")
            return
        }
        if username.count > 20 {
            presentBasicAlert(title: "Username", message: "Username can't be over 20 character")
            return
        }
        UserController.shared.createCurrentUser(username: username, profilePhoto: userImage) { (success) in
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
    
    // Attempts to load the user from the database
    @IBAction func refreshButtonTapped(_ sender: Any) {
        refreshButton.isHidden = true
        loadingDataActivityIndicator.isHidden = false
        loadUser()
    }
    
    // MARK: - Custom Functions
    
    // Checks internet connection
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        return ret
    }
    
    // Presents basic alert with a button that does nothing
    func presentBasicAlert(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    // Is the user signed in to iCloud?
    func connectedToICloud() -> Bool{
        if FileManager.default.ubiquityIdentityToken == nil {
            return false
        } else {
            return true
        }
    }
    
    // Updates ui on view did load
    func updateViews() {
        usernameTextField.layer.cornerRadius = usernameTextField.frame.height / 2
        refreshButton.layer.cornerRadius = refreshButton.frame.height / 2
        saveUsernameButton.layer.cornerRadius = saveUsernameButton.frame.height / 2
        loadingDataActivityIndicator.startAnimating()
        profilePhotoImageView.isHidden = true
        uploadPhotoButton.isHidden = true
        navigationController?.navigationBar.barTintColor = .black
        tabBarController?.tabBar.barTintColor = .tabBar
    }
    
    // Fetches the user for icloud id
    func loadUser() {
        
        if isConnectedToNetwork() == false{
             self.loadingDataActivityIndicator.isHidden = true
            presentErrorAlertForFetch(title: "Internet", message: "Your device has a bad internet connection. Please try again later")
            return
        } else if connectedToICloud() == false {
            presentErrorForICloudConnection(title: "iCloud", message: "This app uses your iCloud account to see challenges on the map. Please sign in to iCloud to enable this feature.")
            return
        }
        var badConnection = false
        var goodConnection = false
        var secondsPassed: Double = 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            secondsPassed += 1
            if goodConnection {
                timer.invalidate()
            } else if secondsPassed >= 5 {
                self.loadingDataActivityIndicator.isHidden = true
                self.presentErrorAlertForFetch(title: "Internet", message: "Your device has a bad internet connection. Please try again later")
                badConnection = true
                timer.invalidate()
            }
        }
        
        UserController.shared.fetchCurrentUser { (networkSuccess, userExists) in
            goodConnection = true
            if badConnection == true {
                return
            }
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
    
    // Presents error alert for icloud connection
    func presentErrorForICloudConnection(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            let mainTabBarStoryboard = UIStoryboard(name: "TabBar", bundle: nil)
            let viewController = mainTabBarStoryboard.instantiateViewController(withIdentifier: "mainTabBar")
            viewController.modalPresentationStyle = .fullScreen
            self.present(viewController, animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
    
    // Presents an error when the fetch cannot reach the database
    func presentErrorAlertForFetch(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            self.refreshButton.isHidden = false
        }
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    // Presents an error alert for when the user tries to create a user.
    func presentErrorAlertForSaveUser(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: title, style: .default) { (_) in
            self.refreshButton.isHidden = false
            self.setUserStackView.isHidden = true
        }
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    // Presents error alert for image picker
    func presentErrorAlertForImagePicker(error: Error?) {
        guard let error = error else { return }
        let alert = UIAlertController(title: "Error", message: "There was an error, and we were unable to complete this action. If this continues to happen, please email challengeacceptedhelp@gmail.com . \(error.localizedDescription)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    // Presents image picker
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
    
    // Requests access to the users photo library
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
    
    // Requests camera authorization
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
    // Sets the selected image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            delegate?.photoSelected(image: selectedImage)
            self.profilePhotoImageView.image = selectedImage
            profilePhotoImageView.isHidden = false
            uploadPhotoButton.isHidden = true
            userImage = selectedImage
        }
        dismiss(animated: true)
    }
    
    // Dismisses the image picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

extension SetupViewController: UITextFieldDelegate {
    
    // Gets rid of keyboard when return button is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        usernameTextField.resignFirstResponder()
        return true
    }
}
