//
//  Challenge.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/1/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

struct ChallengeConstants {
    static let recordTypeKey = "Challenge"
    fileprivate static let titleKey = "title"
    fileprivate static let descriptionKey = "descriptionKey"
    fileprivate static let measurementKey = "measurement"
    fileprivate static let timestampKey = "timestamp"
    static let longitudeKey = "logitude"
    static let latitudeKey = "latitude"
    fileprivate static let photoKey = "photo"
}

class Challenge {
    
    var title: String
    var description: String
    var measurement: String
    var timestamp: Date
    let latitude: Double
    let longitude: Double
    let recordID: CKRecord.ID
    var photoData: Data?
    var photo: UIImage? {
        get {
            guard let photoData = photoData else {return nil}
            return UIImage(data: photoData)
        }
        set {
            photoData = newValue?.jpegData(compressionQuality: 0.5)
        }
    }
    var imageAsset: CKAsset? {
        get {
            let tempDirectory = NSTemporaryDirectory()
            let tempDirecotryURL = URL(fileURLWithPath: tempDirectory)
            let fileURL = tempDirecotryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            do {
                try photoData?.write(to: fileURL)
            } catch let error {
                print("Error writing to temp url \(error) \(error.localizedDescription)")
            }
            return CKAsset(fileURL: fileURL)
        }
    }
    
    init(title: String, description: String, measurement: String, timestamp: Date = Date(), latitude: Double, longitude: Double, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString), photo: UIImage) {
        self.title = title
        self.description = description
        self.measurement = measurement
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.recordID = recordID
        self.photo = photo
    }
}

// Initialize Challenge from record
extension Challenge {
    convenience init? (record: CKRecord) {
        guard let title = record[ChallengeConstants.titleKey] as? String,
            let description = record[ChallengeConstants.descriptionKey] as? String,
            let measurement = record[ChallengeConstants.measurementKey] as? String,
            let timestamp = record[ChallengeConstants.timestampKey] as? Date,
            let latitude = record[ChallengeConstants.latitudeKey] as? Double,
            let longitude = record[ChallengeConstants.longitudeKey] as? Double,
            let imageAsset = record[ChallengeConstants.photoKey] as? CKAsset,
            let imageFileURL = imageAsset.fileURL else {return nil}
        do {
            let data = try Data(contentsOf: imageFileURL)
            guard let image = UIImage(data: data) else {return nil}
            self.init(title: title, description: description, measurement: measurement, timestamp: timestamp, latitude: latitude, longitude: longitude, recordID: record.recordID, photo: image)
        } catch {
            print("Error at \(#function) \(error) \(error.localizedDescription)")
            return nil
        }
    }
}

// Initialize CKRecord with challenge data
extension CKRecord {
    convenience init(challenge: Challenge) {
        self.init(recordType: ChallengeConstants.recordTypeKey, recordID: challenge.recordID)
        self.setValue(challenge.title, forKey: ChallengeConstants.titleKey)
        self.setValue(challenge.description, forKey: ChallengeConstants.descriptionKey)
        self.setValue(challenge.measurement, forKey: ChallengeConstants.measurementKey)
        self.setValue(challenge.longitude, forKey: ChallengeConstants.longitudeKey)
        self.setValue(challenge.latitude, forKey: ChallengeConstants.latitudeKey)
        self.setValue(challenge.timestamp, forKey: ChallengeConstants.timestampKey)
        self.setValue(challenge.imageAsset, forKey: ChallengeConstants.photoKey)
    }
}

extension Challenge: Equatable {
    static func ==(lhs: Challenge, rhs: Challenge) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
