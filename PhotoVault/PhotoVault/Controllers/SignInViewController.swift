
import UIKit

final class SignInViewController: UIViewController {

    //MARK: - IBOutlets
    
    @IBOutlet weak var signInView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameWarningLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordWarningLabel: UILabel!
    
    //MARK: - var/let
    
    private var existingUsers = User.getUsersArray()
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }
    
    //MARK: - IBActions
    
    @IBAction func signInButtonPressed(_ sender: UIButton) {
        checkUser()
    }
    
    @IBAction func createButtonPressed(_ sender: UIButton) {
        pushAccountController()
    }
    
    @IBAction func swipeDetected(_ recognizer: UISwipeGestureRecognizer) {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    //MARK: - flow funcs
    
    private func configureSubviews() {
        if let users = StorageManager.shared.loadExistingUsers() {
            existingUsers = users
        }
        let borderWidthForTextField = 0.5
        let roundRadiusForTextField = 4.0
        addSwipeRecognizer()
        signInView.bordered()
        signInView.rounded()
        usernameTextField.bordered(width: borderWidthForTextField)
        usernameTextField.rounded(radius: roundRadiusForTextField)
        passwordTextField.bordered(width: borderWidthForTextField)
        passwordTextField.rounded(radius: roundRadiusForTextField)
    }

    private func checkUser() {
        guard let username = usernameTextField.text,
              let password = passwordTextField.text else { return }
        
        let user = User()
        user.name = username
        user.password = password
        user.photos = existingUsers.filter { $0.name == user.name && $0.password == user.password }.first?.photos
        
        if existingUsers.filter({ $0.name == user.name && $0.password == user.password }).count == 0 {
            if existingUsers.filter({ $0.name == username }).count == 0 {
                usernameWarningLabel.isHidden = false
                passwordWarningLabel.isHidden = true
            } else {
                usernameWarningLabel.isHidden = true
                passwordWarningLabel.isHidden = false
            }
        } else {
            usernameWarningLabel.isHidden = true
            passwordWarningLabel.isHidden = true
            usernameTextField.text = nil
            passwordTextField.text = nil
            view.endEditing(true)
            StorageManager.shared.saveUser(user)
            pushPhotovaultController()
        }
    }
    
    private func pushPhotovaultController() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: PhotovaultViewController.identifier) as? PhotovaultViewController else { return }
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushAccountController() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: AccountViewController.identifier) as? AccountViewController else { return }
        controller.authorized = false
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func addSwipeRecognizer() {
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeDetected))
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)
    }
}

//MARK: - Extensions

extension SignInViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        string == string.replacingOccurrences(of: " ", with: "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
