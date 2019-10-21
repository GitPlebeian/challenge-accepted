//
//  MainTabBarViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/4/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        tabBarController?.tabBar.barTintColor = .tabBar
        // Sets the main view contoller to be the main map view
        selectedIndex = 1
    }
}
