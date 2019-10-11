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
    
    // MARK: - Properties
    var challenge: Challenge? {
        didSet {
            print("set")
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadViews()
    }
    
    // MARK: - Actions
    @IBAction func saveChallengeButtonTapped(_ sender: Any) {
        guard let challenge = challenge else {return}
        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        ChallengeController.shared.userSavedChallenge(challenge: challenge) { (success) in
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
        let yes = UIAlertAction(title: "Yes", style: .destructive) { (sendEmail) in
            self.showMailComposer()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(yes)
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
        let alert = UIAlertController(title: "Error", message: "Unable to access Mail", preferredStyle: .alert)
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
        composer.setToRecipients(["email"])
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
        }
        controller.dismiss(animated: true)
    }
}
