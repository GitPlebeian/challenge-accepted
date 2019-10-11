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
    }

    // MARK: - Custom Functions
    func updateViews() {
        profileImageVIew.layer.cornerRadius = profileImageVIew.frame.height / 2
        nameLabel.text = UserController.shared.currentUser?.username
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
        cell.challengeImageView.image = challenge.photo
        cell.challengeTitleLabel.text = challenge.title
        cell.challengeDescriptionLabel.text = challenge.description
        cell.challengeTagsLabel.text = challenge.tags.joined(separator: " ")
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let currentUser = UserController.shared.currentUser else { return }
            let challenge = currentUser.createdChallenges[indexPath.row]
            ChallengeController.shared.deleteChallenge(challenge: challenge) { (success) in
                if success {
                    print("Deleted completed challenge")
                } else {
                    print("Was unable to delete completed challenge")
                }
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
