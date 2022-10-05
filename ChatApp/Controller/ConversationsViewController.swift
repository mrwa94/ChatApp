import UIKit
import FirebaseAuth
import FirebaseCore
import MessageKit
import JGProgressHUD


class ConversationsViewController: UIViewController , UITableViewDelegate , UITableViewDataSource{
    
    
    //variables
    @IBOutlet weak var tableView: UITableView!
    private var conversations = [Conversation]()

 
    override func viewDidLoad() {
            super.viewDidLoad()
        
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier:"ConversationTableViewCell")
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        

        }
    //actions
    @IBAction func newConAction(_ sender: UIButton) {
        var nextVC = NewConversationViewController()
        nextVC.completion = {[weak self] result in
            self?.createNewConversation(result: result)
        }
        
        let navVC = UINavigationController(rootViewController: nextVC)
        present(navVC, animated: true)
    }
    
    private func startListeningForCOnversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
//
//        if let observer = loginObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
//
        print("starting conversation fetch...")

        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print("successfully got conversation models")
                guard !conversations.isEmpty else {
                    //self?.tableView.isHidden = true
                   // self?.noConversationsLabel.isHidden = false
                    return
                }
                //self?.noConversationsLabel.isHidden = true
                //self?.tableView.isHidden = false
                self?.conversations = conversations

                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
               // self?.tableView.isHidden = true
               // self?.noConversationsLabel.isHidden = false
                print("failed to get convos: \(error)")
            }
        })
    }
    
    private func createNewConversation(result: [String: String]){
        guard let name = result["name"], let email = result["email"] else{
            return
        }
        
        let vc = ChatViewController(with: email, id: nil)
        vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationTableViewCell", for: indexPath) as! ConversationTableViewCell
        
            let model = conversations[indexPath.row]
            cell.userNameLabel.text = model.name
            cell.userMessageLabel.text = model.latestMessage.text

            cell.userImageView.layer.cornerRadius = cell.userImageView.frame.size.width/2
            cell.userImageView.clipsToBounds = true
            
            let path = "images/\(model.otherUserEmail)_profile_picture.png"
            StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                switch result {
                case .success(let url):

                    DispatchQueue.main.async {
                      //  cell.userImageView. sd_setImage(with: url, completed: nil)
                    }
                case .failure(let error):
                    print("failed to get image url: \(error)")
                }
            })
            
            return cell
        }
    
    //number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  conversations.count
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]

        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
                vc.navigationItem.largeTitleDisplayMode = .never
                navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
        startListeningForCOnversations()
   
    }
    
    private func validateAuth(){
            // current user is set automatically when you log a user in
        if Auth.auth().currentUser == nil {
            let vc = storyboard?.instantiateViewController(withIdentifier: "loginID") as! LoginViewController
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
        }
    
}
struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
