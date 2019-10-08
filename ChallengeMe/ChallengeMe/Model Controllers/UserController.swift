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
    func createCurrentUser(username: String, profilePhoto: UIImage?, appleUserReference: CKRecord.Reference, completion: @escaping (Bool) -> Void) {
        let message = Message(toUser: CKRecord.ID(recordName: "d"), fromUser: CKRecord.ID(recordName: "d"), challenge: CKRecord.ID(recordName: "d"))
        let challenge = Challenge(title: "Challenge Title", description: "Description", measurement: "Measure", latitude: 180, longitude: 60, tags: ["boi","BoiTAg"], photo: UIImage(named: "d")!)
        let user = User(username: "Boi", appleUserReference: CKRecord.Reference(recordID: CKRecord.ID(recordName: "dickcheese"), action: .none), profilePhoto: nil)
        
        let newUser = User(username: "Name", messages: [message], messagesReferences: [appleUserReference], completedChallenges: [challenge], completedChallengesReferences: [appleUserReference], createdChallenges: [challenge], createdChallengesReferences: [appleUserReference], friends: [user], friendsReferences: [appleUserReference], appleUserReference: appleUserReference, profilePhoto: UIImage(named: "d"))
        
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
    func fetchCurrentUser(completion: @escaping (Bool) -> Void) {
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false)
                return
            }
            
            guard let recordID = recordID else {completion(false); return}
            let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)

            let predicate = NSPredicate(format: "%K == %@", UserKeys.appleUserReferenceKey, reference)
            let query = CKQuery(recordType: UserKeys.typeKey, predicate: predicate)
            self.publicDB.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error {
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    completion(false)
                    self.createCurrentUser(username: "bob", profilePhoto: nil, appleUserReference: reference) { (success) in
                        if success {
                            print("BoiBOIBOI")
                        }
                    }
                    return
                }
                if let record = records?.first {
                    let foundUser = User(record: record)
                    self.currentUser = foundUser
                    completion(true)
                } else {
                    self.createCurrentUser(username: "bob", profilePhoto: nil, appleUserReference: reference) { (success) in
                        if success {
                            print("BoiBOIBOI")
                        }
                    }
                }
            }
//            NSPredicate(format: "(%K <= %@) && (%K >= %@) && (%K <= %@) && (%K >= %@)", argumentArray: [
//            ChallengeConstants.longitudeKey, longitude + getLo
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
