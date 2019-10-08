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
    
    // MARK: - CRUD
    // create
    func createUser(username: String, profilePhoto: UIImage?, completion: @escaping (Bool) -> Void) {
        let newUser = User(username: username, profilePhoto: profilePhoto)
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
    
    // read
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
    
    // update
    func updateUser(user: User, profilePhoto: UIImage, completion: @escaping (Bool) -> Void) {
        user.profilePhoto = profilePhoto
        
        let modificationOp = CKModifyRecordsOperation(recordsToSave: [CKRecord(user: user)], recordIDsToDelete: nil)
        modificationOp.savePolicy = .changedKeys
        modificationOp.queuePriority = .veryHigh
        modificationOp.qualityOfService = .default
        modificationOp.modifyRecordsCompletionBlock = { (_, _, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false)
                return
            }
            completion(true)
        }
        publicDB.add(modificationOp)
    }
    
    // delete
    func deleteUser(user: User, completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser else { return }
        let recordID = currentUser.recordID
        publicDB.delete(withRecordID: recordID) { (success, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                 completion(false)
                 return
            }
            completion(true)
        }
    }
    
    
}
