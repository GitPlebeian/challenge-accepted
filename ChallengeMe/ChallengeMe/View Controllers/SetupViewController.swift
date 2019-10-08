//
//  SetupViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/8/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class SetupViewController: UIViewController {

    @IBOutlet weak var saveUsernameButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var setUserStackView: UIStackView!
    @IBOutlet weak var loadingDataActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateViews()
        loadUser()
    }
    
    // MARK: - Actions
    
    @IBAction func saveUsernameButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text, username.isEmpty == false else {return}
        UserController.shared.createCurrentUser(username: username) { (success) in
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
        
    }
    
    func loadUser() {
        UserController.shared.fetchCurrentUser { (networkSuccess, userExists) in
            DispatchQueue.main.async {
                self.loadingDataActivityIndicator.isHidden = true
                if networkSuccess {
                    if userExists {
                        let mainTabBarStoryboard = UIStoryboard(name: "TabBar", bundle: nil)
                        let viewController = mainTabBarStoryboard.instantiateViewController(withIdentifier: "mainTabBar")
                        viewController.modalPresentationStyle = .fullScreen
                        self.present(viewController, animated: true, completion: nil)
                    } else {
                        self.setUserStackView.isHidden = false
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
