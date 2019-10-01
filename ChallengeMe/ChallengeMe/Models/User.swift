//
//  User.swift
//  ChallengeMe
//
//  Created by Jackson Tubbs on 10/1/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import Foundation
import UIKit.UIImage
import CloudKit


struct UserKeys {
    
    static let usernameKey = "Username"
    static let completedChallengesKey = "Completed Challenges"
    static let createdChallengesKey = "Created Challenges"
    static let appleUserReferenceKey = "Apple User Reference"
    static let photoAssetKey = "Photo Asset"
    static let typeKey = "User"
    
}

class User {
    
    let username: String
    var completedChallenges: [Challenge]
    var createdChallenges: [Challenge]
    var appleUserReference: CKRecord.Reference
    var ckRecordID: CKRecord.ID
    var photoData: Data?
    var profilePhoto: UIImage? {
        get {
            guard let photoData = self.photoData else { return nil }
            return UIImage(data: photoData)
        } set {
            self.photoData = newValue?.jpegData(compressionQuality: 0.5)
        }
    }
    var photoAsset: CKAsset? {
        get {
            let tempDirectory = NSTemporaryDirectory()
            let tempDirectoryURL = URL(fileURLWithPath: tempDirectory)
            let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            do {
                try photoData?.write(to: fileURL)
            } catch {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
            return CKAsset(fileURL: fileURL)
        }
    }
   
    init(username: String, completedChallenges: [Challenge], createdChallenges: [Challenge], appleUserReference: CKRecord.Reference, ckRecordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString), profilePhoto: UIImage?) {
        
        self.username = username
        self.completedChallenges = completedChallenges
        self.createdChallenges = createdChallenges
        self.appleUserReference = appleUserReference
        self.ckRecordID = ckRecordID
        self.profilePhoto = profilePhoto
    }
    
    // Initialize User from iCloud
    init?(record: CKRecord) {
        guard let username = record[UserKeys.usernameKey] as? String,
            let completedChallenges = record[UserKeys.completedChallengesKey] as? [Challenge],
            let createdChallenges = record[UserKeys.createdChallengesKey] as? [Challenge],
            let appleUserReference = record[UserKeys.appleUserReferenceKey] as? CKRecord.Reference,
            let imageAsset = record[UserKeys.photoAssetKey] as? CKAsset else { return nil }
        
        self.username = username
        self.completedChallenges = completedChallenges
        self.createdChallenges = createdChallenges
        self.appleUserReference = appleUserReference
        self.ckRecordID = record.recordID
        do {
            guard let imageURL = imageAsset.fileURL else { return }
            self.photoData = try Data(contentsOf: imageURL)
        } catch {
            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
        }
    }
}

extension CKRecord {
    convenience init(user: User) {
        self.init(recordType: UserKeys.typeKey, recordID: user.ckRecordID)
        self.setValue(user.username, forKey: UserKeys.usernameKey)
        setValue(user.completedChallenges, forKey: UserKeys.completedChallengesKey)
        setValue(user.createdChallenges, forKey: UserKeys.createdChallengesKey)
        setValue(user.appleUserReference, forKey: UserKeys.appleUserReferenceKey)
        setValue(user.photoAsset, forKey: UserKeys.photoAssetKey)
    }
}
