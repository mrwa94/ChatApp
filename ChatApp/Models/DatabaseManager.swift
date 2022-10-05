//
//  DatabaseManager.swift
//  ChatApp
//
//  Created by Ayman alsubhi on 06/03/1444 AH.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import SwiftUI
import MessageKit

final class DatabaseManager {
    
    static let shared = DatabaseManager()
   
    // reference the database below
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
    
    
    
    public typealias UploadPictureCompletion = (Result<String,Error>)->Void
    private let storage = Storage.storage().reference()
    // create a simple write function
    
    public enum StorageErrors:Error{
        case filedToUpload
        case faildToGetDownloadUrl
    }
    

}
// MARK: - account management
extension DatabaseManager {
    
    // have a completion handler because the function to get data out of the database is asynchrounous so we need a completion block
    
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("images/\(fileName)").putData(data,metadata: nil){metadata,error in
            guard error == nil else {
                print("the upload dosn't work ")
                completion(.failure(StorageErrors.filedToUpload))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url , error == nil else {
                              print("Failed to get download url")
                              completion(.failure(StorageErrors.faildToGetDownloadUrl))
                              return
                          }
                          
                          let urlString = url.absoluteString
                          
                          print("download url returned: \(urlString)")
                          
                          completion(.success(urlString))
                      }
           
        }
    }
    public func userExists(with email:String, completion: @escaping ((Bool) -> Void)) {
  
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            
            guard snapshot.value as? String != nil else {
                // otherwise... let's create the account
                completion(false)
                return
            }
            
            
            completion(true) // the caller knows the email exists already
        }
    }
    
    /// Insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName
        ], withCompletionBlock: { [weak self] error, _ in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                print("failed ot write to database")
                completion(false)
                return
            }
            strongSelf.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " ,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)

                    strongSelf.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }

                        completion(true)
                    })
                }
                else {
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " ,
                            "email": user.safeEmail
                        ]
                    ]

                    strongSelf.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }

                        completion(true)
                    })
                }
            })
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch

        public var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "This means blah failed"
            }
        }
    }

    func createUser(user: ChatAppUser,completion: @escaping(Bool)->Void){
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName
            
        ]) {error, reference in
            guard error == nil else{
                return
            }
            //--
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var useersDic = snapshot.value as? [[String: String]]{
                    let newElement = [
                        "name": user.firstName + "_" ,
                        "email": user.safeEmail]
                    useersDic.append(newElement)
                    self.database.child("Users").setValue(useersDic)

                completion(true)
                    
                }
            else {
                var UserDic: [[String: String]] = [[
                "name": user.firstName + "_" ,
                "email": user.safeEmail
               ]
               ]
                self.database.child("users").setValue(UserDic)
                //--
                completion(true)        }
    }
}
    }
    //--
    public func getAllUsers(completion: @escaping (Result<[[String: String]],Error>)->Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot  in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DataBeaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    public enum DataBeaseError: Error {
        case failedToFetch
    }
    //--
}


extension DatabaseManager {

    /// Creates a new conversation with target user emamil and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentNamme = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
                let ref = database.child("\(safeEmail)")
                ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
                    guard var userNode = snapshot.value as? [String: Any] else {
                        completion(false)
                        print("user not found")
                        return
                    }
                    
                    let messageDate = firstMessage.sentDate
                    let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
                    var message = ""
                    switch firstMessage.kind {
                    case .text(let messageText):
                        message = messageText
                    case .attributedText(_):
                        break
                    case .photo(_):
                        break
                    case .video(_):
                        break
                    case .location(_):
                        break
                    case .emoji(_):
                        break
                    case .audio(_):
                        break
                    case .contact(_):
                        break
                    case .custom(_), .linkPreview(_):
                        break
                    }
        
                    let conversationId = "conversation_\(firstMessage.messageId)"
        
        
        
                    let recipient_newConversationData: [String: Any] = [
                        "id": conversationId,
                        "other_user_email": safeEmail,
                        "name": currentNamme,
                        "latest_message": [
                            "date": dateString,
                            "message": message,
                            "is_read": false
                        ]
                    ]
                    // Update recipient conversaiton entry
        
                    self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                        if var conversatoins = snapshot.value as? [[String: Any]] {
                            // append
                            conversatoins.append(recipient_newConversationData)
                            self?.database.child("\(otherUserEmail)/conversations").setValue(conversatoins)
                        }
                        else {
                            // create
                            self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                        }
                    })
                    
        
                    let newConversationData: [String: Any] = ["id": conversationId,
                                                              "other_user_email": otherUserEmail,
                                                              "name": name,
                                                              "latest_message":[
                                                                "Date": dateString,
                                                                "message": message,
                                                                "is_read": false
                                                                
                                                                
                                                              ]
                    ]
                    
        //            // Update current user conversation entry
                    if var conversations = userNode["conversations"] as? [[String: Any]] {
                        //                // conversation array exists for current user
                        //                // you should append
                        //
                        conversations.append(newConversationData)
                        userNode["conversations"] = conversations
                        ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            self?.finishCreatingConversation(name:name,
                                                             conversationID: conversationId,
                                                             firstMessage: firstMessage,
                                                             completion: completion)
                        })
                    }
                    else {
        //                // conversation array does NOT exist
        //                // create it
                      
                        userNode["conversations"] = [
                            newConversationData
                        ]
        
                        ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            self?.finishCreatingConversation(name: name,
                                                             conversationID: conversationId,
                                                             firstMessage: firstMessage,
                                                             completion: completion)
                        })
                    }
                })
    }
    
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {


        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)

        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_), .photo(_), .video(_), .location(_), .emoji(_), .audio(_), .contact(_),.custom(_), .linkPreview(_):
            break
        }

        guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }

        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmmail)

        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
            
        ]
//
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]

        print("adding convo: \(conversationID)")

        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result< [Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }

            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else {
                        return nil
                }

                let latestMmessageObject = LatestMessage(date: date,
                                                         text: message,
                                                         isRead: isRead)
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMmessageObject)
            })
//
            completion(.success(conversations))
        })
    }
    
//
    /// Gets all mmessages for a given conversatino
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }

            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageID = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let type = dictionary["type"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateString)else {
                        return nil
                }
//                var kind: MessageKind?
//                if type == "photo" {
//                    // photo
//                    guard let imageUrl = URL(string: content),
//                    let placeHolder = UIImage(systemName: "plus") else {
//                        return nil
//                    }
//                    let media = Media(url: imageUrl,
//                                      image: nil,
//                                      placeholderImage: placeHolder,
//                                      size: CGSize(width: 300, height: 300))
//                    kind = .photo(media)
//                }
//                else if type == "video" {
//                    // photo
//                    guard let videoUrl = URL(string: content),
//                        let placeHolder = UIImage(named: "video_placeholder") else {
//                            return nil
//                    }
//
//                    let media = Media(url: videoUrl,
//                                      image: nil,
//                                      placeholderImage: placeHolder,
//                                      size: CGSize(width: 300, height: 300))
//                    kind = .video(media)
//                }
//                else if type == "location" {
//                    let locationComponents = content.components(separatedBy: ",")
//                    guard let longitude = Double(locationComponents[0]),
//                        let latitude = Double(locationComponents[1]) else {
//                        return nil
//                    }
//                    print("Rendering location; long=\(longitude) | lat=\(latitude)")
//                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
//                                            size: CGSize(width: 300, height: 300))
//                    kind = .location(location)
//                }
//                else {
//                    kind = .text(content)
//                }
//
//                guard let finalKind = kind else {
//                    return nil
//                }
//
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
//
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: .text(content))
            })
//
            completion(.success(messages))
        })
    }

        
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, mmessage: Message, completion: @escaping (Bool) -> Void) {
        
        
        //حذفت name: String, من التعريف
        
        // add new message to messages
        // update sender latest message
        // update recipient latest message
//        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
//            completion(false)
//            return
//        }
//
//        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
//
//        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
//            guard let strongSelf = self else {
//                return
//            }
//
//            guard var currentMessages = snapshot.value as? [[String: Any]] else {
//                completion(false)
//                return
//            }
//
//            let messageDate = newMessage.sentDate
//            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
//
//            var message = ""
//            switch newMessage.kind {
//            case .text(let messageText):
//                message = messageText
//            case .attributedText(_):
//                break
//            case .photo(let mediaItem):
//                if let targetUrlString = mediaItem.url?.absoluteString {
//                    message = targetUrlString
//                }
//                break
//            case .video(let mediaItem):
//                if let targetUrlString = mediaItem.url?.absoluteString {
//                    message = targetUrlString
//                }
//                break
//            case .location(let locationData):
//                let location = locationData.location
//                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
//                break
//            case .emoji(_):
//                break
//            case .audio(_):
//                break
//            case .contact(_):
//                break
//            case .custom(_), .linkPreview(_):
//                break
//            }
//
//            guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
//                completion(false)
//                return
//            }
//
//            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmmail)
//
//            let newMessageEntry: [String: Any] = [
//                "id": newMessage.messageId,
//                "type": newMessage.kind.messageKindString,
//                "content": message,
//                "date": dateString,
//                "sender_email": currentUserEmail,
//                "is_read": false,
//                "name": name
//            ]
//
//            currentMessages.append(newMessageEntry)
//
//            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
//                guard error == nil else {
//                    completion(false)
//                    return
//                }
//
//                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
//                    var databaseEntryConversations = [[String: Any]]()
//                    let updatedValue: [String: Any] = [
//                        "date": dateString,
//                        "is_read": false,
//                        "message": message
//                    ]
//
//                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
//                        var targetConversation: [String: Any]?
//                        var position = 0
//
//                        for conversationDictionary in currentUserConversations {
//                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
//                                targetConversation = conversationDictionary
//                                break
//                            }
//                            position += 1
//                        }
//
//                        if var targetConversation = targetConversation {
//                            targetConversation["latest_message"] = updatedValue
//                            currentUserConversations[position] = targetConversation
//                            databaseEntryConversations = currentUserConversations
//                        }
//                        else {
//                            let newConversationData: [String: Any] = [
//                                "id": conversation,
//                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
//                                "name": name,
//                                "latest_message": updatedValue
//                            ]
//                            currentUserConversations.append(newConversationData)
//                            databaseEntryConversations = currentUserConversations
//                        }
//                    }
//                    else {
//                        let newConversationData: [String: Any] = [
//                            "id": conversation,
//                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
//                            "name": name,
//                            "latest_message": updatedValue
//                        ]
//                        databaseEntryConversations = [
//                            newConversationData
//                        ]
//                    }
//
//                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
//                        guard error == nil else {
//                            completion(false)
//                            return
//                        }
//
//
//                        // Update latest message for recipient user
//
//                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
//                            let updatedValue: [String: Any] = [
//                                "date": dateString,
//                                "is_read": false,
//                                "message": message
//                            ]
//                            var databaseEntryConversations = [[String: Any]]()
//
//                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
//                                return
//                            }
//
//                            if var otherUserConversations = snapshot.value as? [[String: Any]] {
//                                var targetConversation: [String: Any]?
//                                var position = 0
//
//                                for conversationDictionary in otherUserConversations {
//                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
//                                        targetConversation = conversationDictionary
//                                        break
//                                    }
//                                    position += 1
//                                }
//
//                                if var targetConversation = targetConversation {
//                                    targetConversation["latest_message"] = updatedValue
//                                    otherUserConversations[position] = targetConversation
//                                    databaseEntryConversations = otherUserConversations
//                                }
//                                else {
//                                    // failed to find in current colleciton
//                                    let newConversationData: [String: Any] = [
//                                        "id": conversation,
//                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
//                                        "name": currentName,
//                                        "latest_message": updatedValue
//                                    ]
//                                    otherUserConversations.append(newConversationData)
//                                    databaseEntryConversations = otherUserConversations
//                                }
//                            }
//                            else {
//                                // current collection does not exist
//                                let newConversationData: [String: Any] = [
//                                    "id": conversation,
//                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
//                                    "name": currentName,
//                                    "latest_message": updatedValue
//                                ]
//                                databaseEntryConversations = [
//                                    newConversationData
//                                ]
//                            }
//
//                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
//                                guard error == nil else {
//                                    completion(false)
//                                    return
//                                }
//
//                                completion(true)
//                            })
//                        })
//                    })
//                })
//            }
//        })
    }

    
    
    }







