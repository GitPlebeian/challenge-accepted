//
//  ChallengeDetailViewController.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/8/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit
import MessageUI

class ChallengeDetailViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var challengeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var acceptChallengeButton: UIButton!
    @IBOutlet weak var challengeDescription: UILabel!
    @IBOutlet weak var showOnMapButton: UIButton!
    
    // MARK: - Properties
    var challenge: Challenge? {
        didSet {
            updateSaveButtonForChallenge()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadViews()
        
        // Changes Save button to "Unsave"
        NotificationCenter.default.addObserver(self, selector: #selector(enableSaveChallengeButtonForSave), name: NSNotification.Name(NotificationNameKeys.enableSaveChallengeButtonForSaveKey), object: nil)
        // Changes save button to "Save"
        NotificationCenter.default.addObserver(self, selector: #selector(enableSaveChallengeButtonForUnsave), name: NSNotification.Name(NotificationNameKeys.enableSaveChallengeButtonForUnsaveKey), object: nil)
        // Disables save button while network is waiting
        NotificationCenter.default.addObserver(self, selector: #selector(disableSaveChallengeButton), name: NSNotification.Name(NotificationNameKeys.disableSaveChallengeButtonKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(popViewControllerIfChallengeDeleted(notification:)), name: NSNotification.Name(NotificationNameKeys.deletedChallengeKey), object: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func showOnMapButtonTapped(_ sender: Any) {
        guard let challenge = challenge else {return}
        
        let challengeDetailMapStoryboard = UIStoryboard(name: "ChallengeDetailMap", bundle: nil)
        guard let challengeDetailMapViewController = challengeDetailMapStoryboard.instantiateViewController(withIdentifier: "challengeDetailMap") as? ChallengeDetailMapViewController else {return}
        challengeDetailMapViewController.challenge = challenge
        
        challengeDetailMapViewController.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(challengeDetailMapViewController, animated: true)
    }
    
    @IBAction func saveChallengeButtonTapped(_ sender: Any) {
        guard let challenge = challenge else {return}
        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        ChallengeController.shared.toggleSavedChallenge(challenge: challenge) { (success) in
            DispatchQueue.main.async {
                if success {
                    feedback.notificationOccurred(.success)
                } else {
                    feedback.notificationOccurred(.error)
                }
            }
        }
//        UserController.shared.addSavedChallenge(challenge: challenge) { (success) in
//            DispatchQueue.main.async {
//                if success {
//                    feedback.notificationOccurred(.success)
//                } else {
//                    feedback.notificationOccurred(.error)
//                }
//            }
//        }
    }
    
    @IBAction func reportingButtonTapped(_ sender: Any) {
        presentReportAlert()
    }
    
    // MARK: - Custom Methods
    
    func updateSaveButtonForChallenge() {
        loadViewIfNeeded()
        guard let challenge = challenge else {return}
        if ChallengeController.shared.didUserSaveChallenge(challenge: challenge) {
            self.acceptChallengeButton.setTitle("Unsave", for: .normal)
        } else {
            self.acceptChallengeButton.setTitle("Save", for: .normal)
        }
    }
    
    @objc func popViewControllerIfChallengeDeleted(notification: NSNotification) {
        DispatchQueue.main.async {
            guard let challenge = self.challenge,
            let notificationChallenge = notification.userInfo!["challenge"]! as? Challenge else {return}
            if notificationChallenge == challenge {
                self.navigationController?.popViewController(animated: false)
            }
        }
    }
    
    @objc func enableSaveChallengeButtonForUnsave(notification: NSNotification) {
        DispatchQueue.main.async {
            guard let challenge = self.challenge,
            let notificationChallenge = notification.userInfo!["challenge"]! as? Challenge else {return}
            if notificationChallenge == challenge {
                self.acceptChallengeButton.isEnabled = true
                self.acceptChallengeButton.setTitle("Save", for: .normal)
                self.acceptChallengeButton.isHidden = false
            }
        }
    }
    
    @objc func enableSaveChallengeButtonForSave(notification: NSNotification) {
        DispatchQueue.main.async {
            guard let challenge = self.challenge,
            let notificationChallenge = notification.userInfo!["challenge"]! as? Challenge else {return}
            if notificationChallenge == challenge {
                self.acceptChallengeButton.isEnabled = true
                self.acceptChallengeButton.setTitle("Unsave", for: .normal)
                self.acceptChallengeButton.isHidden = false
            }
        }
    }
    
    @objc func disableSaveChallengeButton(notification: NSNotification) {
        DispatchQueue.main.async {
            guard let challenge = self.challenge,
            let notificationChallenge = notification.userInfo!["challenge"]! as? Challenge else {return}
            if notificationChallenge == challenge {
                self.acceptChallengeButton.isEnabled = false
            }
        }
    }
    
//    func updateSaveChallengeButtonLabel() {
//        guard let currentUser = UserController.shared.currentUser,
//        let challenge = challenge else {return}
//
//        for savedChallenge in currentUser.completedChallenges {
//            if savedChallenge == challenge {
//                acceptChallengeButton.titleLabel?.text = "Save Challenge"
//            }
//        }
//    }
    
    func loadViews() {
        guard let challenge = challenge else { return }
        challengeImageView.image = challenge.photo
        titleLabel.text = challenge.title
        tagsLabel.text = challenge.tags.joined(separator: " ")
        challengeDescription.text = challenge.description
        title = challenge.title
    }
    
    func presentReportAlert() {
        let alert = UIAlertController(title: "Report", message: "Would you like to report this challenge?", preferredStyle: .actionSheet)
        let report = UIAlertAction(title: "Report", style: .destructive) { (sendEmail) in
            self.showMailComposer()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(report)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    func presentErrorAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: "There was an error sending your email. \(error.localizedDescription)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    func presentEmailAlert() {
        let alert = UIAlertController(title: "Error", message: "Unable to access Mail. Please email challengeacceptedhelp@gmail.com.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    func showMailComposer() {
        guard let challenge = challenge else { return }
        let recordID = challenge.recordID
        
        guard MFMailComposeViewController.canSendMail() else { presentEmailAlert(); return }
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["challengeacceptedhelp@gmail.com"])
        composer.setSubject("Report Challenge")
        composer.setMessageBody("Thank you for reporting inappropriate content. \n PLEASE DO NOT REMOVE: \(recordID) \n We'll look into this.", isHTML: false)
        present(composer, animated: true)
    }
}

// MARK: - Mail Delegate

extension ChallengeDetailViewController: MFMailComposeViewControllerDelegate {
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
        @unknown default:
            print("Unknown switch at \(#function)")
        }
        controller.dismiss(animated: true)
    }
}
