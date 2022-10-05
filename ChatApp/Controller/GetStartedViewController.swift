//
//  GetStartedViewController.swift
//  ChatApp
//
//  Created by Ayman alsubhi on 06/03/1444 AH.
//

import UIKit

class GetStartedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func funcgoToSignUp(_ sender: Any) {
        
        let startVC = storyboard?.instantiateViewController(withIdentifier: "loginID") as! LoginViewController
        startVC.modalPresentationStyle = .fullScreen
        present(startVC, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
