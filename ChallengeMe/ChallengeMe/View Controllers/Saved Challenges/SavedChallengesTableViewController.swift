//
//  SavedChallengesTableViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/7/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class SavedChallengesTableViewController: UITableViewController {
    // MARK: - Properties
    var challenge: Challenge?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        NotificationCenter.default.addObserver(self, selector: #selector(userUpdatedSavedChallenge), name: NSNotification.Name(NotificationNameKeys.updatedSavedChallengeKey), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        
    }
    
    // MARK: - Actions
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        UserController.shared.fetchSavedChallenge { (success) in
            DispatchQueue.main.async {
                if success {
                    feedback.notificationOccurred(.success)
                    self.tableView.reloadData()
                } else {
                    feedback.notificationOccurred(.error)
                    self.presentBasicAlert(title: "Error", message: "Could not get save challenges, please try again later")
                }
            }
        }
    }
    
    // MARK: - Custom Functions
    func updateViews() {
        title = "Accepted Challenges"
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]

        tabBarController?.tabBar.barTintColor = .tabBar
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .background
    }
    
    
    @objc func userUpdatedSavedChallenge() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func presentBasicAlert(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    // MARK: - TableView Delegate and DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserController.shared.currentUser?.savedChallenges.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "challengeCell", for: indexPath) as? SavedChallengesTableViewCell,
            let challenge = UserController.shared.currentUser?.savedChallenges[indexPath.row] else { return UITableViewCell() }
        cell.challenge = challenge
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let currentUser = UserController.shared.currentUser else { return }
            let challenge = currentUser.savedChallenges[indexPath.row]
            let feedback = UINotificationFeedbackGenerator()
            feedback.prepare()
            ChallengeController.shared.userUnSavedChallenge(challenge: challenge) { (success) in
                DispatchQueue.main.async {
                    if success {
                        feedback.notificationOccurred(.success)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        let challengeDataDict:[String: Challenge] = ["challenge": challenge]
                        NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.updatedSavedChallengeKey), object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.enableSaveChallengeButtonForUnsaveKey), object: nil, userInfo: challengeDataDict)
                    } else {
                        feedback.notificationOccurred(.error)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChallengeDetailVC" {
            guard let indexPath = tableView.indexPathForSelectedRow,
                let destinationVC = segue.destination as? ChallengeDetailViewController else { return }
            let challenge = UserController.shared.currentUser?.savedChallenges[indexPath.row]
            destinationVC.challenge = challenge
        }
    }
}
