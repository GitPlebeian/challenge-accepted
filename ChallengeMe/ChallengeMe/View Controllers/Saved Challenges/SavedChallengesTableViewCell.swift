//
//  SavedChallengesTableViewCell.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/7/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class SavedChallengesTableViewCell: UITableViewCell {
        @IBOutlet weak var challengeImageView: UIImageView!
        @IBOutlet weak var challengeTitleLabel: UILabel!
        @IBOutlet weak var challengeDescriptionLabel: UILabel!
        @IBOutlet weak var challengeTagsLabel: UILabel!
    
    
    var challenge: Challenge? {
        didSet {
            challengeImageView.image = challenge?.photo
            challengeTitleLabel.text = challenge?.title
            challengeDescriptionLabel.text = challenge?.description
            challengeTagsLabel.text = challenge?.tags.joined(separator: " ")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}