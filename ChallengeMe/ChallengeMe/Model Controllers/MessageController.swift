//
//  MessageController.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/7/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import Foundation
import CloudKit

class MessageController {
    
    static let shared = MessageController()
    var messages: [Message] = []
    let publicDB = CKContainer.default().publicCloudDatabase
    
    
    // MARK: - CRUD
    
    // Create Message
    func createMessage(toUser: CKRecord.ID, fromUser: CKRecord.ID, challenge: CKRecord.ID, completion: @escaping (Bool) -> Void) {
        let message = Message(toUser: toUser, fromUser: fromUser, challenge: challenge)
        let messageRecord = CKRecord(message: message)
        publicDB.save(messageRecord) { (record, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                completion(false)
                return
            }
            guard let record = record,
                let message = Message(record: record) else { completion(false); return }
            self.messages.append(message)
            completion(true)
        }
    }
    
    // Fetch Messages
    func fetchMessages(completion: @escaping (Bool) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: MessageKeys.typeKey, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                 completion(false)
                 return
            }
            if let messages = records?.compactMap({ Message(record: $0) }) {
                self.messages = messages
                completion(true)
            }
        }
    }
    
    // Delete Message
    func deleteMessage(user: User, message: Message, completion: @escaping (Bool) -> Void ) {
        let messageRecordID = message.recordID
        guard let messageIndex = user.messages.firstIndex(of: message) else { completion(false); return }
        messages.remove(at: messageIndex)
        publicDB.delete(withRecordID: messageRecordID) { (_, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                 completion(false)
                 return
            }
            completion(true)
        }
    }
    
    // MARK: - Subscriptions
    
    // Remote Notification Subscription
    func subscribeToRemoteNotifications(completion: @escaping (Error?) -> Void) {
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: MessageKeys.typeKey, predicate: predicate, options: [.firesOnRecordCreation])
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Oh snap, someone just challenged you to a workout! Go show 'em how it's done!"
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
