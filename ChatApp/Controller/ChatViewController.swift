import UIKit
import MessageKit
import InputBarAccessoryView


//using sender type to determine which side message be? sender right - reciever left
struct Sender: SenderType{
   public var photoURL: String
   public var senderId: String //unique sender ID
   public var displayName: String //name of sender
}

struct Message: MessageType{
   public var sender: SenderType //sender or reciever
   public var messageId: String  //unique message id
   public var sentDate: Date
   public var kind: MessageKind // kind of message, text, video or voice ..
    
}
extension MessageKind{
    var messageKindString: String{
        switch self {
        case .text(let string):
            return "text"
        case .attributedText(let nSAttributedString):
            return "attributed_text"
        case .photo(let mediaItem):
            return "photo"
        case .video(let mediaItem):
            return "video"
        case .location(let locationItem):
            return "location"
        case .emoji(let string):
            return "emoji"
        case .audio(let audioItem):
            return "audio"
        case .contact(let contactItem):
            return "contact"
        case .linkPreview(let linkItem):
            return "link_preview"
        case .custom(let optional):
            return "custom"
        }
        
    }
    
}




class ChatViewController: MessagesViewController , MessagesDataSource , MessagesLayoutDelegate , MessagesDisplayDelegate, InputBarAccessoryViewDelegate{
   
    public static let dateFormatter: DateFormatter = {
        let formattre = DateFormatter()
        formattre.dateStyle = .medium
        formattre.timeStyle = .long
        formattre.locale = .current
        return formattre
    }()
    
    
   public var isNewConversation = false
    public let otherUserEmail: String
    private let conversationId: String?

    
    private var messages = [Message]()

    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
       
        // Do any additional setup after loading the view.
    }
    
    init(with email: String, id: String?){
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
     


    }
    
    private func listenForMessages(id:String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                print("success in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messages = messages

                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()

                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
    
    
    let otherUser = Sender(photoURL: "", senderId: "other", displayName: "Shuaa")
    //other user side of messages
    
    
    

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }

    }
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }

        fatalError("Self Sender is nil, email should be cached")
//        return Sender(photoURL: "", senderId: "12", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        //section is to determine which side messages be
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        //number of messages
        return messages.count
    }

    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: "", with: "").isEmpty,
        let selfSender = self.selfSender ,
         let messageId = createMessageId() else{
            return
        }
        //send Message
        if isNewConversation {
            // create convo in database
            let mmessage = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: mmessage, completion: {  success in
                if success{
                    print("message sent")
                }
                else{
                    print("failed ot send")
                    
                }
          
            
            })

            //                if success {
//                    print("message sent")
//                    self?.isNewConversation = false
//                    let newConversationId = "conversation_\(mmessage.messageId)"
//                    self?.conversationId = newConversationId
//                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
//                    self?.messageInputBar.inputTextView.text = nil
//                }
//                else {
//                    print("faield ot send")
//                }
//            })
        }
        else {
//            guard let conversationId = conversationId, let name = self.title else {
//                return
//            }
//
//            // append to existing conversation data
//            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: mmessage, completion: { [weak self] success in
//                if success {
//                    self?.messageInputBar.inputTextView.text = nil
//                    print("message sent")
//                }
//                else {
//                    print("failed to send")
//                }
//            })
        }
          func createMessageId() -> String? {
            // date, otherUesrEmail, senderEmail, randomInt
            
            guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                      return nil
                  }
              
              
            let dateString = Self.dateFormatter.string(from: Date())
            let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
            //
         let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
            //
        print("created message id: \(newIdentifier)")
            //
            return newIdentifier
        }
        
        
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        return
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        return
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) {
        return
    }
    
}
