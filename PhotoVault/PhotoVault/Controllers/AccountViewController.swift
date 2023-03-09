
import UIKit

//MARK: - Enums

private enum UserData: CaseIterable {
    case name
    case password
    case confirm
}

//MARK: - private extensions

private extension String {
    static let warningTextUsernameIsTaken = "Username is taken"
    static let warningTextUsernameMustContain = "Username must contain 4+ characters"
    static let account = "ACCOUNT"
    static let change = "Change"
    static let create = "Create"
    static let space = " "
    static let empty = ""
}

final class AccountViewController: UIViewController {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var userdataView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameWarningLabel: UILabel!
    @IBOutlet weak var usernameCheckmarkImageView: UIImageView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordWarningLabel: UILabel!
    @IBOutlet weak var passwordCheckmarkImageView: UIImageView!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var confirmWarningLabel: UILabel!
    @IBOutlet weak var confirmCheckmarkImageView: UIImageView!
    
    //MARK: - var/let
    
    static let identifier = "AccountViewController"
    var authorized = false
    private var existingUsers = [User]()
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }
    
    //MARK: - IBActions
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createButtonPressed(_ sender: UIButton) {
        addUser()
    }
    
    @IBAction func swipeDetected(_ recognizer: UISwipeGestureRecognizer) {
        view.endEditing(true)
    }
    
    //MARK: - flow funcs
    
    private func configureSubviews() {
        if let users = StorageManager.shared.loadExistingUsers() {
            existingUsers = users
        }
        addSwipeRecognizer()
        userdataView.bordered()
        userdataView.rounded()
        usernameTextField.bordered(forTextField: true)
        usernameTextField.rounded(forTextField: true)
        passwordTextField.bordered(forTextField: true)
        passwordTextField.rounded(forTextField: true)
        confirmTextField.bordered(forTextField: true)
        confirmTextField.rounded(forTextField: true)
        
        if authorized {
            titleLabel.text = .change.uppercased() + .space + .account
            createButton.setTitle(.change, for: .normal)
        } else {
            titleLabel.text = .create.uppercased() + .space + .account
            createButton.setTitle(.create, for: .normal)
        }
    }
    
    private func addUser() {
        UserData.allCases.forEach { userData in
            checkUserData(userData)
        }
        if checkCheckmarks() {
            saveUser()
            if authorized {
                navigationController?.popViewController(animated: true)
            } else {
                pushPhotovaultController()
            }
        }
    }
    
    private func saveUser() {
        guard let username = usernameTextField.text,
              let password = passwordTextField.text else {return}
        
        let user = User()
        user.name = username
        user.password = password
        
        if authorized {
            guard let authorizedUser = StorageManager.shared.loadUser() else { return }
            
            existingUsers = existingUsers.filter { $0.name != authorizedUser.name }
            user.photos = authorizedUser.photos
            StorageManager.shared.saveUser(user)
            StorageManager.shared.saveUserInExistingUsers(user, in: existingUsers)
        } else {
            StorageManager.shared.saveUser(user)
            StorageManager.shared.saveUserInExistingUsers(user, in: existingUsers)
        }
    }
    
    private func checkUserData(_ userData: UserData) {
        guard let username = usernameTextField.text,
              let password = passwordTextField.text,
              let confirm = confirmTextField.text else {return}
        
        switch userData {
        case .name:
            let minCountChars = 3
            if username.count > minCountChars {
                if existingUsers.filter({ $0.name == username }).isEmpty {
                    usernameWarningLabel.isHidden = true
                    usernameCheckmarkImageView.isHidden = false
                } else {
                    usernameWarningLabel.text = .warningTextUsernameIsTaken
                    usernameWarningLabel.isHidden = false
                    usernameCheckmarkImageView.isHidden = true
                }
            } else {
                usernameWarningLabel.text = .warningTextUsernameMustContain
                usernameWarningLabel.isHidden = false
                usernameCheckmarkImageView.isHidden = true
            }
        case .password:
            let minCountChars = 5
            if password.count > minCountChars {
                passwordWarningLabel.isHidden = true
                passwordCheckmarkImageView.isHidden = false
            } else {
                passwordWarningLabel.isHidden = false
                passwordCheckmarkImageView.isHidden = true
            }
        case .confirm:
            if passwordWarningLabel.isHidden == false {
                confirmWarningLabel.isHidden = true
                return
            }
            if password != confirm {
                confirmWarningLabel.isHidden = false
                confirmCheckmarkImageView.isHidden = true
            } else {
                confirmWarningLabel.isHidden = true
                confirmCheckmarkImageView.isHidden = false
            }
        }
    }
    
    private func checkCheckmarks() -> Bool {
        if !confirmCheckmarkImageView.isHidden,
           !passwordCheckmarkImageView.isHidden,
           !usernameCheckmarkImageView.isHidden {
            return true
        }
        return false
    }
    
    private func pushPhotovaultController() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: PhotovaultViewController.identifier) as? PhotovaultViewController else { return }
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func addSwipeRecognizer() {
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDetected))
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)
    }
}

//MARK: - Extensions

extension AccountViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        string == string.replacingOccurrences(of: String.space, with: String.empty)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case usernameTextField:
            checkUserData(.name)
        case passwordTextField:
            checkUserData(.password)
        default:
            checkUserData(.confirm)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        usernameWarningLabel.isHidden = true
        passwordWarningLabel.isHidden = true
        confirmWarningLabel.isHidden = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text,
           text == .empty {
            textField.text = nil
        }
        textField.resignFirstResponder()
        return true
    }
}


