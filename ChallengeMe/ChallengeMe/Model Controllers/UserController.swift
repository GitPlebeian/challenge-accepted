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
    
    // MARK: - Helper
    
    // Makes sure that every challenge is pointing to the same place in memeory and if not, it will swap values and make sure every challenge is pointing to the same place in memory
    func assignCreatedChallenges() {
        guard let currentUser = currentUser else {return}
        for challenge in ChallengeController.shared.challenges {
            for createdChallenge in currentUser.createdChallenges {
                if challenge == createdChallenge {
                    let indexOfCreatedChallenge = currentUser.createdChallenges.firstIndex(of: createdChallenge)!
                    currentUser.createdChallenges[indexOfCreatedChallenge] = challenge
                }
            }
        }
    }
    
    // MARK: - CRUD
    
    // Creates user for first login
    func createCurrentUser(username: String, profilePhoto: UIImage?, completion: @escaping (Bool) -> Void) {
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false)
                return
            }
            
            guard let recordID = recordID else {completion(false); return}
            let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
            
            let newUser: User
            if let profilePhoto = profilePhoto {
                newUser = User(username: username, appleUserReference: reference, profilePhoto: profilePhoto)
            } else {
                newUser = User(username: username, appleUserReference: reference, profilePhoto: UIImage(named: "defaultProfileImage"))
            }
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
                    self.getCreatedChallenges()
                    completion(true)
                }
            })
        }
    }
    
    // Fetches current user
    func fetchCurrentUser(completion: @escaping (Bool, Bool) -> Void) {
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false, false)
                return
            }
            
            guard let recordID = recordID else {completion(false, false); return}
            let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)

            let predicate = NSPredicate(format: "%K == %@", UserKeys.appleUserReferenceKey, reference)
            let query = CKQuery(recordType: UserKeys.typeKey, predicate: predicate)
            self.publicDB.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error {
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    completion(false, false)
                    return
                }
                if let record = records?.first, let user = User(record: record) {
                    self.currentUser = user
                    self.getCreatedChallenges()
                    completion(true, true)
                } else {
                    completion(true, false)
                }
            }
        }
    }
    
    // Fetches saved Challenges
    func fetchSavedChallenge(completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser else {return}
        let reference = CKRecord.Reference(recordID: currentUser.recordID, action: .none)
        let predicate = NSPredicate(format: "%K CONTAINS %@", argumentArray: [ChallengeConstants.usersWhoSavedReferencesKey, reference])
        let query = CKQuery(recordType: ChallengeConstants.recordTypeKey, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false)
                return
            }
            guard let records = records else {return}
            let challenges = records.compactMap({Challenge(record: $0)})
            // Assigns saved challenges to user
            currentUser.savedChallenges = challenges
            completion(true)
            return
        }
    }
    
    // Updates User for whatever has changed
    func updateUser(completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser else {return}
        let modificationOp = CKModifyRecordsOperation(recordsToSave: [CKRecord(user: currentUser)], recordIDsToDelete: nil)
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
    
    // Deletes User and thus deletes all their created challenges
    func deleteUser(user: User, completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser else { return }
        let recordID = currentUser.recordID
        publicDB.delete(withRecordID: recordID) { (success, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                 completion(false)
                 return
            }
            self.currentUser = nil
            completion(true)
        }
    }
    
    // Gets created challenges
    func getCreatedChallenges() {
        guard let currentUser = currentUser else {return}
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [ChallengeConstants.authorReferenceKey, currentUser.recordID])
        let query = CKQuery(recordType: ChallengeConstants.recordTypeKey, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (challengeRecords, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
            
            guard let challengeRecords = challengeRecords else {
                return
            }
            let createdChallenges = challengeRecords.compactMap({Challenge(record: $0)})
            currentUser.createdChallenges = createdChallenges
        }
    }
    
    // Deletes created Challenge and modifies user.
    func deleteCreatedChallenge(challenge: Challenge, completion: @escaping (Bool) -> Void) {
        var completedOneOperation = false
        var errorOccurred = false
        var createdChallengeReferenceOptional: CKRecord.Reference?
        
        guard let currentUser = currentUser
        else {
            completion(false)
            return
        }
        var index = 0
        // Removes created challange reference from user
        for reference in currentUser.createdChallengesReferences {
            if reference.recordID == challenge.recordID {
                currentUser.createdChallengesReferences.remove(at: index)
                createdChallengeReferenceOptional = reference
            }
            index += 1
        }
        
        guard let createdChallengeReference = createdChallengeReferenceOptional else {
            completion(false)
            return
        }
        
        let modificationOp = CKModifyRecordsOperation(recordsToSave: [CKRecord(user: currentUser)], recordIDsToDelete: nil)
        modificationOp.savePolicy = .changedKeys
        modificationOp.queuePriority = .veryHigh
        modificationOp.qualityOfService = .default
        modificationOp.modifyRecordsCompletionBlock = { (_, _, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                if errorOccurred == false {
                    errorOccurred = true
                    currentUser.createdChallengesReferences.append(createdChallengeReference)
                    completion(false)
                    return
                } else {
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                }
            }
            // If one modification completed true and this request completed as true. Them the function will complete successfully
            if completedOneOperation == true {
                if let indexToDeleteCreatedChallenge = currentUser.createdChallenges.firstIndex(of: challenge) {
                    currentUser.createdChallenges.remove(at: indexToDeleteCreatedChallenge)
                }
                if let indexToDeleteSavedChallenge = currentUser.savedChallenges.firstIndex(of: challenge) {
                    currentUser.savedChallenges.remove(at: indexToDeleteSavedChallenge)
                }
                completion(true)
                return
            } else {
                completedOneOperation = true
            }
        }
        publicDB.add(modificationOp)
        
        // Deletes the challenge record from CloudKit
        ChallengeController.shared.deleteChallenge(challenge: challenge) { (success) in
            if success {
                if completedOneOperation == true {
                    if let indexToDeleteCreatedChallenge = currentUser.createdChallenges.firstIndex(of: challenge) {
                        currentUser.createdChallenges.remove(at: indexToDeleteCreatedChallenge)
                    }
                    if let indexToDeleteSavedChallenge = currentUser.savedChallenges.firstIndex(of: challenge) {
                        currentUser.savedChallenges.remove(at: indexToDeleteSavedChallenge)
                    }
                    completion(true)
                    return
                } else {
                    completedOneOperation = true
                }
            } else {
                if errorOccurred == false {
                    errorOccurred = true
                    currentUser.createdChallengesReferences.append(createdChallengeReference)
                    completion(false)
                    return
                }
            }
        }
    }
}
