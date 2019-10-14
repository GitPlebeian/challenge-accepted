//
//  ActionButton.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/14/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class ActionButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setFont(to: FontKeys.subheader2)
        setupUI()
    }
    
    func setFont(to fontName: String) {
        self.titleLabel?.font = UIFont(name: fontName, size: 24)
    }
    
    func setupUI() {
        backgroundColor = .actionRed
        setTitleColor(.white, for: .normal)
        addCornerRadius(self)
        addShadow(self)
    }
}
