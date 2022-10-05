//
//  RegisterViewController.swift
//  ChatApp
//
//  Created by Ayman alsubhi on 05/03/1444 AH.
//
import FirebaseCore
import FirebaseAuth
import ProgressHUD
import FirebaseStorage
import Gallery
import JGProgressHUD




protocol signDelegate: AnyObject {
    
    func emailField (email: String)
    func passwordField(password: String)
    
    
}

class RegisterViewController: UIViewController {
    

    
    
   //vars
    
    var gallery = GalleryController()
    var profileImage : Data?
    var currentUser : ChatAppUser?
    let storge = Storage.storage().reference()
    
    
    
    @IBOutlet weak var fillNameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var passwordTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func selectImageButton(_ sender: Any) {
        
        selectProfileImage()
    }
    
    @IBAction func signupButtonpress(_ sender: Any) {
        
        regesterUsers()
        
        
    }
    
    func regesterUsers(){
        
        // Check if all inputs not empty.
        
      guard  let firstname = fillNameTF.text ,
        let email = emailTF.text ,
        let password = passwordTF.text ,
            !email.isEmpty ,
            !password.isEmpty ,
             !firstname.isEmpty ,
             password.count >= 6
        
         else {
            ProgressHUD.showError("Please enter all information to create a new account.")
           return
          }
                 
        //Regester user in firebase
        
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    
                    //dispatch queue
                    
                    //if user Exist throw Error
                    guard !exists else {
                        // user already exists
                        ProgressHUD.showError("Looks like a user account for that email address already exists.")
                        return
                    }

                     Auth.auth().createUser(withEmail: email, password: password, completion: { authResult, error in
                        guard authResult != nil, error == nil else {
                            print("Error creating user")
                            return
                        }

                       

                         let chatUser = ChatAppUser(firstName: firstname, emailAddress: email, profilePictureUrl: "" )
                        
                         
                         DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        
                             UserDefaults.standard.setValue(email, forKey: "email")
                             UserDefaults.standard.setValue( firstname, forKey: "name")

                            if success {
                                
                                // upload image
                                
                                
                         
                            }
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                
                                guard let image = strongSelf.profileImageView ,
                                      let data = image as? Data else {
                                                            return
                                                    }
                                let filename = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage maanger error: \(error)")
                                    }
                                })
                            
                        })

                         self?.goToApp()
                         print("Successfull regester")
                    })
                })
                
            
   }

    
    func goToApp(){
        
        let contrller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "tabBarID") as! UITabBarController
        contrller.modalPresentationStyle = .fullScreen
        present(contrller, animated: true, completion: nil)
    }
    
    
    //select image
    
    
    func selectProfileImage() {
        
        self.gallery = GalleryController()
        self.gallery.delegate = self
        Config.tabsToShow = [.imageTab , .cameraTab]
        Config.Camera.imageLimit = 1
        Config.initialTab = .cameraTab
        present(gallery, animated: true, completion: nil)
        
    }
    
    
    func uploadImageToFirebase(image: UIImage) {
            
            guard let image = image.pngData() else {
                return
            }
            let fileName = randomString(length: 20)
        StorageManager.shared.uploadProfilePicture(with: image, fileName: fileName, completion: { result in
                switch result {
                case .success(_) :
                    do{
                        let imageUrl = try result.get()
                        UserDefaults.standard.set(imageUrl, forKey: "profileImageUrl")
                       // UserDefaults.standard.set(imageUrl, forKey: "profileImageUrl")
                       // self.userInfoValdiate["profileImage"] = imageUrl
                        
                    } catch {
                        print("error")
                    }
                    break
                case .failure(_):
                    print("error")
                }
            }
                                                   
       ) }
    
    
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }

    
    
    
    
    
    @IBAction func toLoginButton(_ sender: Any) {
        
        let signVC = storyboard?.instantiateViewController(withIdentifier: "signUpVC") as! LoginViewController
        signVC.modalPresentationStyle = .fullScreen
        present(signVC, animated: true, completion: nil)
    }
    
    
    
    
    
    
}


extension RegisterViewController : GalleryControllerDelegate {
    
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        
        let fristName = fillNameTF.text
        let email = emailTF.text
       // let password = passwordTF.text
        let chatUser  = ChatAppUser(firstName: fristName!, emailAddress: email! , profilePictureUrl: "")

        if images.count > 0 {
            images.first?.resolve(completion: {  avatarImage in
                if avatarImage != nil {
                    self.profileImageView.image = avatarImage?.circleMask
           } else {
                    ProgressHUD.showFailed("Cloud not select image!")
                    
                }
                
            })
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
}
