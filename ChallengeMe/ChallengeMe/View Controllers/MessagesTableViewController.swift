//
//  MessagesTableViewController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/4/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class MessagesTableViewController: UITableViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MessageController.shared.messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as? SavedChallengesTableViewCell else { return UITableViewCell() }
        let message = MessageController.shared.messages[indexPath.row]
//        cell.fromUserImage = need parsed messages from CKReference
//        cell.fromUserNameLabel =
        return cell
    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "messagesDetailVCSegue" {
            guard let indexPath = tableView.indexPathForSelectedRow,
            let destinationVC = segue.destination as? MessageDetailViewController else { return }
            let message = MessageController.shared.messages[indexPath.row]
            destinationVC.message = message
        }
    }
    

}
