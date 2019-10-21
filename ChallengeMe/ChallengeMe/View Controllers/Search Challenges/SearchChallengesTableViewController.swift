//
//  SearchChallengesTableViewController.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/9/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import UIKit

class SearchChallengesTableViewController: UITableViewController {
    // MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - Properties
    var searchResults: [Challenge] = []
    var selectedChallenge: Challenge?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
    }
    
    // MARK: - Custom Methods
    func updateViews() {
        tableView.tableFooterView = UIView()
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        tabBarController?.tabBar.barTintColor = .tabBar
    }

    // MARK: - Table view data source
    
    // Number of rows in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text == "" {
            return ChallengeController.shared.challenges.count
        }
        return searchResults.count
    }

    // Cell for row at
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "challengeCell", for: indexPath) as? SearchChallengesTableViewCell else { return UITableViewCell() }
        if searchBar.text == "" {
            let challenge = ChallengeController.shared.challenges[indexPath.row]
            cell.challenge = challenge
        } else {
            let challenge = searchResults[indexPath.row]
            cell.challenge = challenge
        }
    
        return cell
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChallengeDetailVC" {
            guard let indexPath = tableView.indexPathForSelectedRow,
                let destinationVC = segue.destination as? ChallengeDetailViewController else { return }
            var challenge: Challenge
            if searchBar.text == "" {
                challenge = ChallengeController.shared.challenges[indexPath.row]
            } else {
                challenge = searchResults[indexPath.row]
            }
            destinationVC.challenge = challenge
        }
    }
}

// MARK: - SearchBar Delegate
extension SearchChallengesTableViewController: UISearchBarDelegate {
    
    // Will update the table view for the text in the search bar.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsCancelButton = true
        let searchTerm = searchText.lowercased()
        guard !searchTerm.isEmpty else { return }
        var results = [Challenge]()
        for challenge in ChallengeController.shared.challenges {
            if challenge.title.lowercased().contains(searchTerm) {
                results.append(challenge)
                continue
            }
            for tag in challenge.tags {
                if tag.lowercased().contains(searchTerm) {
                    results.append(challenge)
                    break
                }
            }
        }
        searchResults = results
        tableView.reloadData()
    }

    // Empties the search bar when user cancels search
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchResults = []
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
}

