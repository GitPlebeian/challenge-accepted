//
//  StyleGuide.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/11/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit



struct FontKeys {
    static let header = "AppleSDGothicNeo-Bold"
    static let subheader1 = "AppleSDGothicNeo-SemiBold"
    static let subheader2 = "AppleSDGothicNeo-Regular"
    static let cochin = "Cochin"
}

extension UIColor {
    static let action = UIColor(named: "action")
    static let highlight = UIColor(named: "highlight")
    static let tabBar = UIColor(named: "tabBar")
    static let navBar = UIColor(named: "navBar")
    static let text = UIColor(named: "text")
    static let buttonText = UIColor(named: "buttonText")
    static let background = UIColor(named: "background")
    static let challenge = UIColor(named: "challenge")
}

extension UIView {
    func addCircularCorners(_ button: UIButton) {
        layer.cornerRadius = button.frame.height / 2
    }
    
    func addCornerRadius(_ radius: CGFloat = 4) {
        layer.cornerRadius = radius
    }
    
    func addShadow(_ button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 2, height: 4)
        button.layer.shadowRadius = 3
    }
}

