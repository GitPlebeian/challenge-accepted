//
//  ChallengeLabel.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/17/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class ChallengeLabel: UILabel {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateFont(fontName: FontKeys.cochin, size: 18)
        self.textColor = .text
    }
    
    func updateFont(fontName: String, size: CGFloat) {
        self.font = UIFont(name: fontName, size: size)
    }
}

class HeaderChallengeLabel: ChallengeLabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        updateFont(fontName: FontKeys.header, size: 28)
    }
}

class SubheaderChallengeLabel: ChallengeLabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        updateFont(fontName: FontKeys.subheader1, size: 24)
    }
}

