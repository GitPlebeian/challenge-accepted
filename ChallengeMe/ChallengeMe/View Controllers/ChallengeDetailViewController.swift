//
//  ChallengeDetailViewController.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/8/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class ChallengeDetailViewController: UIViewController {

    @IBOutlet weak var challengeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var acceptChallengeButton: UIButton!
    @IBOutlet weak var challengeDescription: UILabel!
    
    var challenge: Challenge?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadViews()
    }
    
    @IBAction func acceptChallengeButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func loadViews() {
        guard let challenge = challenge else { return }
        challengeImageView.image = challenge.photo
        titleLabel.text = challenge.title
        tagsLabel.text = challenge.tags.joined(separator: " ")
        challengeDescription.text = challenge.description
        title = challenge.title
    }
}
