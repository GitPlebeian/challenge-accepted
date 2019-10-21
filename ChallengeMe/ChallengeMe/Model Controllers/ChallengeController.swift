//
//  ChallengeController.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/1/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class ChallengeController {
    
    static let shared = ChallengeController()
    
    var challenges: [Challenge] = []
    let publicDB = CKContainer.default().publicCloudDatabase
    let searchAreaMeasurement = 0.2
    
    // MARK: - Helper
    
    // Called to help the search this area predicate make a square search area
    func getLongitudeMeasurementForLatitude(latitude: Double) -> Double {
        var latitude = latitude
        if latitude < 0 {
            latitude *= -1
        }
        if latitude < 10 {
            return searchAreaMeasurement
        } else if latitude < 20 {
            return searchAreaMeasurement + 0.01
        } else if latitude < 30 {
            return searchAreaMeasurement + 0.02
        } else if latitude < 40 {
            return searchAreaMeasurement + 0.04
        } else if latitude < 45 {
            return searchAreaMeasurement + 0.06
        } else if latitude < 50 {
            return searchAreaMeasurement + 0.08
        } else if latitude < 55 {
            return searchAreaMeasurement + 0.11
        } else if latitude < 60 {
            return searchAreaMeasurement + 0.16
        } else if latitude < 65 {
            return searchAreaMeasurement + 0.19
        } else if latitude < 70 {
            return searchAreaMeasurement + 0.23
        } else if latitude < 75 {
            return searchAreaMeasurement + 0.3
        } else if latitude < 80 {
            return searchAreaMeasurement + 0.4
        } else {
            return searchAreaMeasurement + 0.6
        }
    }
    
    
    // Checks if user has saved the challenge
    func didUserSaveChallenge(challenge: Challenge) -> Bool {
        guard let user = UserController.shared.currentUser else {return false}
        for userWhoSaved in challenge.usersWhoSavedReferences {
            if userWhoSaved.recordID == user.recordID {
                return true
            }
        }
        return false
    }
    
    // MARK: - CRUD
    
    // Adds a user to the challenge. The addition tells the challenge that it has been saved by a user
    func toggleSavedChallenge(challenge: Challenge, completion: @escaping (Bool, Bool) -> Void) {
        
        let challengeDictionary: [String: Challenge] = ["challenge": challenge]
        // Checks to see if the challenge has been deleted
        let predicate = NSPredicate(format: "recordID == %@", challenge.recordID)
        let query = CKQuery(recordType: ChallengeConstants.recordTypeKey, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false, false)
                return
            }
            guard let records = records else {
                completion(false, false)
                return
            }
            if records.count == 0 {
                NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.deletedChallengeKey), object: nil, userInfo: challengeDictionary)
                completion(true, true)
                return
            }
            guard let currentUser = UserController.shared.currentUser else {return}
            // Notification Center is used to diable the save button while the network is updating the record.
            NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.disableSaveChallengeButtonKey), object: nil, userInfo: challengeDictionary)
            var userExists = false
            for reference in challenge.usersWhoSavedReferences {
                if reference.recordID == currentUser.recordID {
                    userExists = true
                }
            }
            // UN-saves the challenge if the user has already saved
            if userExists {
                self.userUnSavedChallenge(challenge: challenge) { (success) in
                    if success {
                        let challengeDataDict:[String: Challenge] = ["challenge": challenge]
                        // Notifications enable the save/unsave button after the challenge has been updated
                        NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.updatedSavedChallengeKey), object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.enableSaveChallengeButtonForUnsaveKey), object: nil, userInfo: challengeDataDict)
                        completion(true, false)
                        return
                    } else {
                        completion(false, false)
                        return
                    }
                }
            } else {
                // Saves the challenge if the user has not saved
                self.userSavedChallenge(challenge: challenge) { (success) in
                    if success {
                        let challengeDataDict:[String: Challenge] = ["challenge": challenge]
                        // Notifications enable the save/unsave button after the challenge has been updated
                        NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.updatedSavedChallengeKey), object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name(NotificationNameKeys.enableSaveChallengeButtonForSaveKey), object: nil, userInfo: challengeDataDict)
                        completion(true, false)
                        return
                    } else {
                        completion(false, false)
                        return
                    }
                }
            }
        }
    }
    
    // Saves challenge for user
    func userSavedChallenge(challenge: Challenge,completion: @escaping (Bool) -> Void) {
        guard let currentUser = UserController.shared.currentUser else {return}
        let reference = CKRecord.Reference(recordID: currentUser.recordID, action: .none)
        challenge.usersWhoSavedReferences.append(reference)
        let modificationOp = CKModifyRecordsOperation(recordsToSave: [CKRecord(challenge: challenge)], recordIDsToDelete: nil)
        modificationOp.savePolicy = .changedKeys
        modificationOp.queuePriority = .veryHigh
        modificationOp.qualityOfService = .default
        modificationOp.modifyRecordsCompletionBlock = { (_, _, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                if let indexOfUsersWhoSavedReferenceToRemove = challenge.usersWhoSavedReferences.firstIndex(of: reference) {
                    challenge.usersWhoSavedReferences.remove(at: indexOfUsersWhoSavedReferenceToRemove)
                }
                completion(false)
                return
            } else {
                currentUser.savedChallenges.append(challenge)
                completion(true)
                return
            }
        }
        publicDB.add(modificationOp)
    }
    
    // Removes saved challenge for user
    func userUnSavedChallenge(challenge: Challenge, completion: @escaping (Bool) -> Void) {
        guard let currentUser = UserController.shared.currentUser else {return}
        var userWhoSavedReferenceToRemoveOptional: CKRecord.Reference?
        
        var index = 0
        for reference in challenge.usersWhoSavedReferences {
            if reference.recordID == currentUser.recordID {
                userWhoSavedReferenceToRemoveOptional = reference
                challenge.usersWhoSavedReferences.remove(at: index)
            }
            index += 1
        }
        guard let userWhoSavedReferenceToRemove = userWhoSavedReferenceToRemoveOptional else {return}
        let modificationOp = CKModifyRecordsOperation(recordsToSave: [CKRecord(challenge: challenge)], recordIDsToDelete: nil)
        modificationOp.savePolicy = .changedKeys
        modificationOp.queuePriority = .veryHigh
        modificationOp.qualityOfService = .default
        modificationOp.modifyRecordsCompletionBlock = { (_, _, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                challenge.usersWhoSavedReferences.append(userWhoSavedReferenceToRemove)
                completion(false)
                return
            } else {
                if let indexToRemoveChallengeFromUser = currentUser.savedChallenges.firstIndex(of: challenge) {
                    currentUser.savedChallenges.remove(at: indexToRemoveChallengeFromUser)
                }
                completion(true)
                return
            }
        }
        publicDB.add(modificationOp)
    }
    
    // Creates Challenge
    func createChallenge(title: String, description: String, longitude: Double, latitude: Double, tags: [String], photo: UIImage, completion: @escaping (Challenge?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else {
            completion(nil)
            return
        }
        let authorReference = CKRecord.Reference(recordID: currentUser.recordID, action: .deleteSelf)
        
        let challenge = Challenge(title: title, description: description, latitude: latitude, longitude: longitude, tags: tags, authorReference: authorReference, photo: photo)
        let challengeRecord = CKRecord(challenge: challenge)
        publicDB.save(challengeRecord) { (record, error) in
            if let error = error {
                print("Error at: \(#function) Error: \(error)\nLocalized Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let record = record, let challenge = Challenge(record: record) else {
                completion(nil)
                return
            }
            self.challenges.append(challenge)
            let challengeReference = CKRecord.Reference(recordID: challenge.recordID, action: .none)
            currentUser.createdChallengesReferences.append(challengeReference)
            UserController.shared.updateUser { (success) in
                DispatchQueue.main.async {
                    if success {
                        currentUser.createdChallenges.append(challenge)
                        completion(challenge)
                        return
                    } else {
                        if let indexToRemove = currentUser.createdChallengesReferences.firstIndex(of: challengeReference) {
                            currentUser.createdChallengesReferences.remove(at: indexToRemove)
                        }
                        completion(nil)
                        return
                    }
                }
            }
        }
    }
    
    // Fetches Challenges based on a search area.
    func fetchChallenges(longitude: Double, latitude: Double, completion: @escaping (Bool) -> Void) {
        let predicate = NSPredicate(format: "(%K <= %@) && (%K >= %@) && (%K <= %@) && (%K >= %@)", argumentArray: [
            ChallengeConstants.longitudeKey, longitude + getLongitudeMeasurementForLatitude(latitude: latitude),
            ChallengeConstants.longitudeKey, longitude - getLongitudeMeasurementForLatitude(latitude: latitude),
            ChallengeConstants.latitudeKey, latitude + searchAreaMeasurement,
            ChallengeConstants.latitudeKey, latitude - searchAreaMeasurement])
        let query = CKQuery(recordType: ChallengeConstants.recordTypeKey, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error at: \(#function) Error: \(error)\nLocalized Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let records = records else {
                completion(false)
                return
            }
            let challenges = records.compactMap({Challenge(record: $0)})
            self.challenges = challenges
            UserController.shared.assignCreatedChallenges()
            completion(true)
        }
    }
    
    // Deletes Challenge
    func deleteChallenge(challenge: Challenge, completion: @escaping (Bool) -> Void) {
        let challengeRecordID = challenge.recordID
        publicDB.delete(withRecordID: challengeRecordID) { (_, error) in
            if let error = error {
                print("Error at: \(#function) Error: \(error)\nLocalized Error: \(error.localizedDescription)")
                completion(false)
                return
            } else {
                if let challengeIndex = self.challenges.firstIndex(of: challenge) {
                    self.challenges.remove(at: challengeIndex)
                }
                completion(true)
            }
        }
    }
}
