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
    func createCurrentUser(username: String, completion: @escaping (Bool) -> Void) {
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false)
                return
            }
            
            guard let recordID = recordID else {completion(false); return}
            let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
            
            let newUser = User(username: username, appleUserReference: reference, profilePhoto: UIImage(named: "d")!)
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
    
    // read
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
                if let record = records?.first {
                    let foundUser = User(record: record)
                    self.currentUser = foundUser
                    completion(true, true)
                } else {
                    completion(true, false)
                }
            }
//            NSPredicate(format: "(%K <= %@) && (%K >= %@) && (%K <= %@) && (%K >= %@)", argumentArray: [
//            ChallengeConstants.longitudeKey, longitude + getLo
        }
    }
    
    // update
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
    
    // Delete Created Challenge - Removes from all users.
    
    func deleteCreatedChallenge(challenge: Challenge, completion: @escaping (Bool) -> Void) {
        var completedOneOperation = false
        var errorOccurred = false
        var savedChallengeReferenceOptional: CKRecord.Reference?
        var createdChallengeReferenceOptional: CKRecord.Reference?
        
        guard let currentUser = currentUser
        else {
            completion(false)
            return
        }
        var index = 0
        for reference in currentUser.createdChallengesReferences {
            if reference.recordID == challenge.recordID {
                currentUser.createdChallengesReferences.remove(at: index)
                createdChallengeReferenceOptional = reference
            }
            index += 1
        }
        
        index = 0
        for reference in currentUser.completedChallengesReferences {
            if reference.recordID == challenge.recordID {
                currentUser.completedChallengesReferences.remove(at: index)
                savedChallengeReferenceOptional = reference
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
                    if let savedChallengeReference = savedChallengeReferenceOptional {
                        currentUser.completedChallengesReferences.append(savedChallengeReference)
                    }
                    completion(false)
                    return
                } else {
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                }
            }
            if completedOneOperation == true {
                if let indexToDeleteCreatedChallenge = currentUser.createdChallenges.firstIndex(of: challenge) {
                    currentUser.createdChallenges.remove(at: indexToDeleteCreatedChallenge)
                }
                if let indexToDeleteSavedChallenge = currentUser.completedChallenges.firstIndex(of: challenge) {
                    currentUser.completedChallenges.remove(at: indexToDeleteSavedChallenge)
                }
                completion(true)
                return
            } else {
                completedOneOperation = true
            }
        }
        publicDB.add(modificationOp)
        
        ChallengeController.shared.deleteChallenge(challenge: challenge) { (success) in
            if success {
                if completedOneOperation == true {
                    if let indexToDeleteCreatedChallenge = currentUser.createdChallenges.firstIndex(of: challenge) {
                        currentUser.createdChallenges.remove(at: indexToDeleteCreatedChallenge)
                    }
                    if let indexToDeleteSavedChallenge = currentUser.completedChallenges.firstIndex(of: challenge) {
                        currentUser.completedChallenges.remove(at: indexToDeleteSavedChallenge)
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
                    if let savedChallengeReference = savedChallengeReferenceOptional {
                        currentUser.completedChallengesReferences.append(savedChallengeReference)
                    }
                    completion(false)
                    return
                }
            }
        }
    }
    
    // Delete Saved Challenge
    
    func convertRecordToCompletedChallenges() {
        guard let currentUser = currentUser else { return }
        for completedChallengeReference in currentUser.completedChallengesReferences {
            for challenge in ChallengeController.shared.challenges {
                if completedChallengeReference.recordID == challenge.recordID {
                    currentUser.completedChallenges.append(challenge)
                }
            }
        }
    }
    
    func convertRecordToCreatedChallenges() {
        guard let currentUser = currentUser else { return }
        for createdChallengeReference in currentUser.createdChallengesReferences {
            for challenge in ChallengeController.shared.challenges {
                if createdChallengeReference.recordID == challenge.recordID {
                    currentUser.createdChallenges.append(challenge)
                }
            }
        }
    }
}
