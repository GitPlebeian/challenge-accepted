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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        searchBar.delegate = self
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as? SearchChallengesTableViewCell else { return UITableViewCell() }
        let challenge = searchResults[indexPath.row]
        cell.challengeImageView.image = challenge.photo
        cell.challengeTitleLabel.text = challenge.title
        cell.challengeDescriptionLabel.text = challenge.description
        cell.challengeTagsLabel.text = challenge.tags.joined(separator: " ")
        
        return cell
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChallengeDetailVC" {
            guard let indexPath = tableView.indexPathForSelectedRow,
                let destinationVC = segue.destination as? ChallengeDetailViewController else { return }
            let challenge = searchResults[indexPath.row]
            destinationVC.challenge = challenge
        }
    }

}

// MARK: - SearchBar Delegate
extension SearchChallengesTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchTerm = searchText.lowercased()
        guard !searchTerm.isEmpty else { return }
        var results = [Challenge]()
        for challenge in ChallengeController.shared.challenges {
            if challenge.title.lowercased().contains(searchTerm) {
                results.append(challenge)
            }
            for tag in challenge.tags {
                if tag.contains(searchTerm) {
                    results.append(challenge)
                }
            }
        }
        searchResults = results
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }

}

