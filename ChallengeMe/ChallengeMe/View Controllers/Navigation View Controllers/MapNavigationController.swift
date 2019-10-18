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
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .darkContent
//    }
    
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
