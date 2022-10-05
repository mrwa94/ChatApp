//
//  ProfileViewController.swift
//  ChatApp
//
//  Created by Ayman alsubhi on 06/03/1444 AH.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    //image
    @IBOutlet weak var profileImage: UIImageView!
    
    //label
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    
    
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        emailLabel.text = UserDefaults.standard.string(forKey: "email")
        userName.text = UserDefaults.standard.string(forKey: "name")
        
        

    }
    
    @IBAction func logOutButton(_ sender: Any) {
        logOut()
    }
    
  
    func logOut(){
        do {
            
            try Auth.auth().signOut()
            print("Successful LogOut ..")
            
            // go to login view
            let signVC = storyboard?.instantiateViewController(withIdentifier: "loginID") as! LoginViewController
            signVC.modalPresentationStyle = .fullScreen
            present(signVC, animated: true, completion: nil)
            
        }catch {
            print("Faield LogOut .. ")
        }
        
    }
    

}
