//
//  ProfileViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/2/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var createdChallengesTableView: UITableView!
    @IBOutlet weak var profileImageVIew: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    // MARK: - Properties
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        createdChallengesTableView.delegate = self
        createdChallengesTableView.dataSource = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createdChallengesTableView.reloadData()
        updateProfileInfo()
    }

    // MARK: - Custom Functions
    func updateViews() {
        guard let currentUser = UserController.shared.currentUser else { return }
        profileImageVIew.layer.cornerRadius = profileImageVIew.frame.height / 2
        nameLabel.text = currentUser.username
        profileImageVIew.image = currentUser.profilePhoto
    }
    
    func updateProfileInfo() {
        guard let currentUser = UserController.shared.currentUser else { return }
        profileImageVIew.image = currentUser.profilePhoto
        nameLabel.text = currentUser.username
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChallengeDetailVC" {
            guard let indexPath = createdChallengesTableView.indexPathForSelectedRow,
                let destinationVC = segue.destination as? ChallengeDetailViewController else { return }
            let challenge = UserController.shared.currentUser?.createdChallenges[indexPath.row]
            destinationVC.challenge = challenge
        }
    }
}

// MARK: - TableView Delegate and DataSource
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserController.shared.currentUser?.createdChallenges.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "challengeCell", for: indexPath) as? CreatedChallengesTableViewCell,
            let challenge = UserController.shared.currentUser?.createdChallenges[indexPath.row] else { return UITableViewCell() }
        cell.challenge = challenge
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let currentUser = UserController.shared.currentUser else { return }
            let challenge = currentUser.createdChallenges[indexPath.row]
            UserController.shared.deleteCreatedChallenge(challenge: challenge) { (success) in
                DispatchQueue.main.async {
                    if success {
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        let challengeDictionary: [String: Challenge] = ["challenge": challenge]
                        NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.deletedChallengeKey), object: nil, userInfo: challengeDictionary)
                    }
                }
            }
        }
    }
}
