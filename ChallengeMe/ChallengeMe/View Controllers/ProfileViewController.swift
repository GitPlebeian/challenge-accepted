//
//  FriendsViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/2/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet var challengeHistoryButton: UIView!
    @IBOutlet weak var createdChallengesButton: UIButton!
    @IBOutlet weak var profileImageVIew: UIImageView!
    
    // MARK: - Properties
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    
    // MARK: - Actions
    
    @IBAction func challengeHistoryButtonTapped(_ sender: Any) {
        let challengeHistoryStoryboard = UIStoryboard(name: "ChallengeHistory", bundle: nil)
        let viewController = challengeHistoryStoryboard.instantiateViewController(withIdentifier: "challengeHistory")
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    @IBAction func createdChallengesButtonTapped(_ sender: Any) {
        let createdChallengesStoryboard = UIStoryboard(name: "CreatedChallenges", bundle: nil)
        let viewController = createdChallengesStoryboard.instantiateViewController(withIdentifier: "createdChallenges")
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Custom Functions
    
    func updateViews() {
        challengeHistoryButton.layer.cornerRadius = challengeHistoryButton.frame.height / 2
        createdChallengesButton.layer.cornerRadius = createdChallengesButton.frame.height / 2
        profileImageVIew.layer.cornerRadius = profileImageVIew.frame.height / 2
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
