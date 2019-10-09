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
        title = "Accepted Challenges"
    }
    
    // MARK: - TableView Delegate and DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserController.shared.currentUser?.completedChallenges.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "challengeCell", for: indexPath) as? SavedChallengesTableViewCell,
            let challenge = UserController.shared.currentUser?.completedChallenges[indexPath.row] else { return UITableViewCell() }
        cell.challengeImageView.image = challenge.photo
        cell.challengeTitleLabel.text = challenge.title
        cell.challengeDescriptionLabel.text = challenge.description
        cell.challengeTagsLabel.text = challenge.tags.joined(separator: " ")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let currentUser = UserController.shared.currentUser else { return }
            let challenge = currentUser.completedChallenges[indexPath.row]
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
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChallengeDetailVC" {
            guard let indexPath = tableView.indexPathForSelectedRow,
                let destinationVC = segue.destination as? ChallengeDetailViewController else { return }
            let challenge = UserController.shared.currentUser?.completedChallenges[indexPath.row]
            destinationVC.challenge = challenge
        }
    }
}
