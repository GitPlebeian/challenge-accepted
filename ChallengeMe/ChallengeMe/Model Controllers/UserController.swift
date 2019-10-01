//
//  UserController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/1/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import Foundation
import UIKit.UIImage
import CloudKit

class UserController {
    
    static let shared = UserController()
    var currentUser: User?
    let publicDB = CKContainer.default().publicCloudDatabase
    
    func createUser(username: String, profilePhoto: UIImage, completion: @escaping (Bool) -> Void) {
        
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false)
                return
            }
            guard let recordID = recordID else { completion(false); return }
            let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
            let newUser = User(username: username, appleUserReference: reference, profilePhoto: profilePhoto)
            let userRecord = CKRecord(user: newUser)
            
            self.publicDB.save(userRecord, completionHandler:  { (record, error) in
                if let error = error {
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                     completion(false)
                     return
                }
                if let record = record {
                    let savedUser = User(record: record)
                    self.currentUser = savedUser
                    completion(true)
                }
            })
        }
    }
    
    func fetchUser(completion: @escaping (Bool) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: UserKeys.typeKey, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                 completion(false)
                 return
            }
            if let record = records?.first {
                let foundUser = User(record: record)
                self.currentUser = foundUser
                completion(true)
            }
        }
    }
}
