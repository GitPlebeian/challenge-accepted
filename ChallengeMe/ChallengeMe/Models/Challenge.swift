//
//  Challenge.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/1/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import Foundation
import CloudKit

struct ChallengeConstants {
    static let recordTypeKey = "Challenge"
    fileprivate static let titleKey = "title"
    fileprivate static let longitudeKey = "logitude"
    fileprivate static let latitudeKey = "latitude"
    fileprivate static let descriptionKey = "descriptionKey"
    fileprivate static let measurementKey = "measurement"
}

class Challenge {
    
    var title: String
    var description: String
    var measurement: String
    let latitude: Double
    let longitude: Double
    let recordID: CKRecord.ID
    
    init(title: String, description: String, measurement: String, latitude: Double, longitude: Double, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.title = title
        self.description = description
        self.measurement = measurement
        self.latitude = latitude
        self.longitude = longitude
        self.recordID = recordID
    }
}

extension Challenge {
    convenience init? (record: CKRecord) {
        guard let title = record[ChallengeConstants.titleKey] as? String,
            let description = record[ChallengeConstants.descriptionKey] as? String,
            let measurement = record[ChallengeConstants.measurementKey] as? String,
            let latitude = record[ChallengeConstants.latitudeKey] as? Double,
            let longitude = record[ChallengeConstants.longitudeKey] as? Double else {return nil}
        
        self.init(title: title, description: description, measurement: measurement, latitude: latitude, longitude: longitude, recordID: record.recordID)
    }
}

extension CKRecord {
    convenience init(challenge: Challenge) {
        self.init(recordType: ChallengeConstants.recordTypeKey, recordID: challenge.recordID)
        self.setValue(challenge.title, forKey: ChallengeConstants.titleKey)
        self.setValue(challenge.description, forKey: ChallengeConstants.descriptionKey)
        self.setValue(challenge.measurement, forKey: ChallengeConstants.measurementKey)
        self.setValue(challenge.longitude, forKey: ChallengeConstants.longitudeKey)
        self.setValue(challenge.latitude, forKey: ChallengeConstants.latitudeKey)
    }
}

extension Challenge: Equatable {
    static func ==(lhs: Challenge, rhs: Challenge) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
