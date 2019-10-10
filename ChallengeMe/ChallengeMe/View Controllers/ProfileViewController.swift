//
//  ProfileViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/2/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import MessageUI

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
    @IBAction func supportButtonTapped(_ sender: Any) {
        showMailComposer()
    }
    @IBAction func privacyPolicyButtonTapped(_ sender: Any) {
        if let url = URL(string: "website") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Custom Functions
    func updateViews() {
        profileImageVIew.layer.cornerRadius = profileImageVIew.frame.height / 2
        nameLabel.text = UserController.shared.currentUser?.username
    }
    
    func showMailComposer() {
        guard MFMailComposeViewController.canSendMail() else { presentEmailAlert(); return }  // add alert if false
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["email"])
        composer.setSubject("Support/Feedback")
        composer.setMessageBody("Thank you for reaching out. We welcome any feedback to help make our app better, and offer support with any issues you may run into!", isHTML: false)
        present(composer, animated: true)
    }
    
    func presentEmailAlert() {
           let alert = UIAlertController(title: "Error", message: "Unable to access Mail", preferredStyle: .alert)
           let ok = UIAlertAction(title: "OK", style: .cancel)
           alert.addAction(ok)
           present(alert, animated: true)
    }
    
    func presentErrorAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: "There was an error sending your email. \(error.localizedDescription)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(ok)
        present(alert, animated: true)
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

// MARK: - Mail Delegate
extension ProfileViewController: MFMailComposeViewControllerDelegate {
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
