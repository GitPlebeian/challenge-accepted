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
    static let messagesReferencesKey = "MessagesReferences"
    static let completedChallengesReferencesKey = "CompletedChallengesReferences"
    static let createdChallengesReferencesKey = "CreatedChallengesReferences"
    static let friendsReferencesKey = "FriendsReferences"
    static let photoAssetKey = "PhotoAsset"
    static let appleUserReferenceKey = "AppleUserReference"
    static let typeKey = "User"
}

class User {
    
    let username: String
    var messages: [Message]
    var messagesReferences: [CKRecord.Reference]
    var completedChallenges: [Challenge]
    var completedChallengesReferences: [CKRecord.Reference]
    var createdChallenges: [Challenge]
    var createdChallengesReferences: [CKRecord.Reference]
    var friends: [User]
    var friendsReferences: [CKRecord.Reference]
    var appleUserReference: CKRecord.Reference
    var recordID: CKRecord.ID
    var photoData: Data?
    var profilePhoto: UIImage? {
        get {
            guard let photoData = self.photoData else { return nil }
            return UIImage(data: photoData)
        } set {
            if let newValue = newValue {
                self.photoData = newValue.jpegData(compressionQuality: 0.5)
            } else {
                self.photoData = UIImage(named: "d")!.jpegData(compressionQuality: 0.5)
            }
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
   
    init(username: String, messages: [Message] = [], messagesReferences: [CKRecord.Reference] = [],
         completedChallenges: [Challenge] = [], completedChallengesReferences: [CKRecord.Reference] = [],
         createdChallenges: [Challenge] = [], createdChallengesReferences: [CKRecord.Reference] = [],
         friends: [User] = [], friendsReferences: [CKRecord.Reference] = [],
         appleUserReference: CKRecord.Reference,
         recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString), profilePhoto: UIImage?) {
        
        self.username = username
        self.messages = messages
        self.messagesReferences = messagesReferences
        self.completedChallenges = completedChallenges
        self.completedChallengesReferences = completedChallengesReferences
        self.createdChallenges = createdChallenges
        self.createdChallengesReferences = createdChallengesReferences
        self.friends = friends
        self.friendsReferences = friendsReferences
        self.appleUserReference = appleUserReference
        self.recordID = recordID
        self.profilePhoto = profilePhoto
    }
}

extension User {
    // Initialize User from iCloud
    convenience init?(record: CKRecord) {
        guard let username = record[UserKeys.usernameKey] as? String,
            let messagesReferences = record[UserKeys.messagesReferencesKey] as? [CKRecord.Reference],
            let completedChallengesReferences = record[UserKeys.completedChallengesReferencesKey] as? [CKRecord.Reference],
            let createdChallengesReferences = record[UserKeys.createdChallengesReferencesKey] as? [CKRecord.Reference],
            let friendsReferences = record[UserKeys.friendsReferencesKey] as? [CKRecord.Reference],
            let appleUserReference = record[UserKeys.appleUserReferenceKey] as? CKRecord.Reference,
            let imageAsset = record[UserKeys.photoAssetKey] as? CKAsset,
            let imageAssetURL = imageAsset.fileURL else { return nil }
        do {
            let data = try Data(contentsOf: imageAssetURL)
            guard let image = UIImage(data: data) else { return nil }
            self.init(username: username, messages: [],
            messagesReferences: messagesReferences, completedChallenges: [],
            completedChallengesReferences: completedChallengesReferences,
            createdChallenges: [], createdChallengesReferences: createdChallengesReferences,
            friends: [], friendsReferences: friendsReferences,
            appleUserReference: appleUserReference,
            recordID: record.recordID, profilePhoto: image)
        } catch {
            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            return nil
        }
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}

extension CKRecord {
    // save User to iCloud
    convenience init(user: User) {
        self.init(recordType: UserKeys.typeKey, recordID: user.recordID)
        self.setValue(user.username, forKey: UserKeys.usernameKey)
        self.setValue(user.messagesReferences, forKey: UserKeys.messagesReferencesKey)
        self.setValue(user.completedChallengesReferences, forKey: UserKeys.completedChallengesReferencesKey)
        self.setValue(user.createdChallengesReferences, forKey: UserKeys.createdChallengesReferencesKey)
        self.setValue(user.friendsReferences, forKey: UserKeys.friendsReferencesKey)
        self.setValue(user.appleUserReference, forKey: UserKeys.appleUserReferenceKey)
        self.setValue(user.photoAsset, forKey: UserKeys.photoAssetKey)
    }
}
