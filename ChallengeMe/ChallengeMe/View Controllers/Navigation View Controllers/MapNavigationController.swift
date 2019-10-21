//
//  mapNaviagtionControllerViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/9/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class MapNavigationController: UINavigationController {

    // MARK: - Properties
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        
        tabBarController?.tabBar.unselectedItemTintColor = .white
        tabBarController?.tabBar.barTintColor = .tabBar
    }
    
}
