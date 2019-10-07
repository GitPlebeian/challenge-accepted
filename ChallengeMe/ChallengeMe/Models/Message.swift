//
//  Message.swift
//  ChallengeMe
//
//  Created by Michael Moore on 10/7/19.
//  Copyright © 2019 Jax Tubbs. All rights reserved.
//

import Foundation
import CloudKit

struct MessageKeys {
    static let toUserKey = "To User"
    static let fromUserKey = "From User"
    static let challengeKey = "Challenge"
    static let typeKey = "Message"
}

class Message {
    
    let toUser: CKRecord.ID
    let fromUser: CKRecord.ID
    let challenge: CKRecord.ID
    let recordID: CKRecord.ID
    
    init(toUser: CKRecord.ID, fromUser: CKRecord.ID, challenge: CKRecord.ID, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.toUser = toUser
        self.fromUser = fromUser
        self.challenge = challenge
        self.recordID = recordID
    }
}

extension Message {
    convenience init?(record: CKRecord) {
        guard let toUser = record[MessageKeys.toUserKey] as? CKRecord.ID,
            let fromUser = record[MessageKeys.fromUserKey] as? CKRecord.ID,
            let challenge = record[MessageKeys.challengeKey] as? CKRecord.ID else { return nil }
        
        self.init(toUser: toUser, fromUser: fromUser, challenge: challenge, recordID: record.recordID)
    }
}

extension CKRecord {
    convenience init(message: Message) {
        self.init(recordType: MessageKeys.typeKey, recordID: message.recordID)
        setValue(message.toUser, forKey: MessageKeys.toUserKey)
        setValue(message.fromUser, forKey: MessageKeys.fromUserKey)
        setValue(message.challenge, forKey: MessageKeys.challengeKey)
    }
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
