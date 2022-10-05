//
//  LoginViewController.swift
//  ChatApp
//
//  Created by Ayman alsubhi on 05/03/1444 AH.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import ProgressHUD

class LoginViewController: UIViewController {

    //TextField
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    
    //LifeCiycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginButton(_ sender: Any) {
        
        guard let email = emailTF.text , let password = passwordTF.text , !email.isEmpty , !password.isEmpty  else {
            
            ProgressHUD.showError("All Fields is Requerds")
            
            return
            
        }
        
        Auth.auth().signIn(withEmail: emailTF.text!, password: passwordTF.text!, completion:{ result , error in
            
            if let error = error {
                          print("Failed Login ")
                       }
            
                     else {
                         let user = result?.user
                         
                         guard let email = user?.email else{
                                         return
                                     }
                                     
                         UserDefaults.standard.setValue(email, forKey: "email") 
                                     
                          print("logged in user: \(user)")
                           print("success login user:")}
                           self.goToApp()
            
            
        })
        
    }
    
    func goToApp() {
        
        // move to app
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "tabBarID") as! UITabBarController
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        
        
    }
    
    
    
    
    @IBAction func toLoginButton(_ sender: Any) {
        
        let signVC = storyboard?.instantiateViewController(withIdentifier: "signUpVC") as! RegisterViewController
        signVC.modalPresentationStyle = .fullScreen
        present(signVC, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
}
