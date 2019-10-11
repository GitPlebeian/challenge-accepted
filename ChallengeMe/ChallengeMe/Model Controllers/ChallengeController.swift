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
    let searchAreaMeasurement = 1.0
    
    // MARK: - Helper
    
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
    
    // MARK: - CRUD
    
    // Add User Who Saved
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
                currentUser.completedChallenges.append(challenge)
                completion(true)
                return
            }
        }
        publicDB.add(modificationOp)
    }
    
    // Remove user who saved
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
                if let indexToRemoveChallengeFromUser = currentUser.completedChallenges.firstIndex(of: challenge) {
                    currentUser.completedChallenges.remove(at: indexToRemoveChallengeFromUser)
                }
                completion(true)
                return
            }
        }
        publicDB.add(modificationOp)
    }
    
    // Create Challenge
    func createChallenge(title: String, description: String, longitude: Double, latitude: Double, tags: [String], photo: UIImage, completion: @escaping (Bool) -> Void) {
        guard let currentUser = UserController.shared.currentUser else {return}
        let authorReference = CKRecord.Reference(recordID: currentUser.recordID, action: .deleteSelf)
        
        let challenge = Challenge(title: title, description: description, latitude: latitude, longitude: longitude, tags: tags, authorReference: authorReference, photo: photo)
        let challengeRecord = CKRecord(challenge: challenge)
        publicDB.save(challengeRecord) { (record, error) in
            if let error = error {
                print("Error at: \(#function) Error: \(error)\nLocalized Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let record = record, let challenge = Challenge(record: record) else {
                completion(false)
                return
            }
            self.challenges.append(challenge)
            let challengeReference = CKRecord.Reference(recordID: challenge.recordID, action: .none)
            currentUser.createdChallengesReferences.append(challengeReference)
            UserController.shared.updateUser { (success) in
                DispatchQueue.main.async {
                    if success {
                        currentUser.createdChallenges.append(challenge)
                        completion(true)
                        return
                    } else {
                        if let indexToRemove = currentUser.createdChallengesReferences.firstIndex(of: challengeReference) {
                            currentUser.createdChallengesReferences.remove(at: indexToRemove)
                        }
                        completion(false)
                        return
                    }
                }
            }
        }
    }
    
    // Fetch Challenges
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
            completion(true)
        }
    }
    
    // Delete Challenges
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
