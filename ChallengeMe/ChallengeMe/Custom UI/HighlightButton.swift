//
//  HighlightButton.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/17/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class HighlightButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setFont(to: FontKeys.subheader2)
        setupUI()
    }
    
    func setFont(to fontName: String) {
        self.titleLabel?.font = UIFont(name: fontName, size: 24)
    }
    
    func setupUI() {
        backgroundColor = .highlight
        setTitleColor(.buttonText, for: .normal)
        addCircularCorners(self)
        addShadow(self)
    }
}
