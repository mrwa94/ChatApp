//
//  ChatUser.swift
//  ChatApp
//
//  Created by Ayman alsubhi on 06/03/1444 AH.
//

import Foundation
import FirebaseAuth



struct ChatAppUser {
    
    let firstName: String
    let emailAddress: String
    let profilePictureUrl: String?

    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

    var profilePictureFileName: String {
        //afraz9-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
    
    static var currentId : String {
        
        return Auth.auth().currentUser!.uid
    }
}
