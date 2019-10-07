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
    
    // Create Challenge
    func createChallenge(title: String, description: String, measurement: String, longitude: Double, latitude: Double, tags: [String], photo: UIImage, completion: @escaping (Bool) -> Void) {
        let challenge = Challenge(title: title, description: description, measurement: measurement, latitude: latitude, longitude: longitude, tags: tags, photo: photo)
        let challengeRecord = CKRecord(challenge: challenge)
        publicDB.save(challengeRecord) { (record, error) in
            if let error = error {
                print("Error at: \(#function) Error: \(error)\nLocalized Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let record = record,let challenge = Challenge(record: record) else {
                completion(false)
                return
            }
            self.challenges.append(challenge)
            completion(true)
        }
    }
    
    // Fetch Challenges
    func fetchChallenges(longitude: Double, latitude: Double, completion: @escaping (Bool) -> Void) {
        let predicate = NSPredicate(value: true)
        let predicate2 = NSPredicate(format: "(%K <= %@) && (%K >= %@) && (%K <= %@) && (%K >= %@)", argumentArray: [
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
    func deleteChallenges(user: User, challenge: Challenge, completion: @escaping (Bool) -> Void) {
        guard let indexOfChallengeToDeleteUser = user.completedChallenges.firstIndex(of: challenge) else {
            completion(false)
            return
        }
        let challengeRecordID = challenge.recordID
        publicDB.delete(withRecordID: challengeRecordID) { (_, error) in
            if let error = error {
                print("Error at: \(#function) Error: \(error)\nLocalized Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            user.createdChallenges.remove(at: indexOfChallengeToDeleteUser)
            if let indexOfChallengeToDeleteFromSourceOfTruth = self.challenges.firstIndex(of: challenge) {
                self.challenges.remove(at: indexOfChallengeToDeleteFromSourceOfTruth)
            }
        }
    }
    
    // MARK: - Subscriptions
    
    // Remote Notification Subscription
    func subscribeToRemoteNotifications(completion: @escaping (Error?) -> Void) {
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: ChallengeConstants.recordTypeKey, predicate: predicate, options: [.firesOnRecordCreation])
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Hey! Someone !"
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        subscription.notificationInfo = notificationInfo
        
        publicDB.save(subscription) { (_, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                 completion(error)
                 return
            }
            completion(nil)
        }
    }
}
