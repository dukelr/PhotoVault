
import UIKit

final class SignInViewController: UIViewController {

    //MARK: - IBOutlets
    
    @IBOutlet weak var signInView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameWarningLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordWarningLabel: UILabel!
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    //MARK: - IBActions
    
    @IBAction func signInButtonPressed(_ sender: UIButton) {
        checkUser()
    }
    
    @IBAction func createButtonPressed(_ sender: UIButton) {
        pushAccountController()
    }
    
    @IBAction func swipeDetected(_ recognizer: UISwipeGestureRecognizer) {
        view.endEditing(true)
    }
    
    //MARK: - flow funcs
    
    private func setupSubviews() {
        addSwipeRecognizer()
        signInView.bordered()
        signInView.rounded()
        usernameTextField.bordered(forTextField: true)
        usernameTextField.rounded(forTextField: true)
        passwordTextField.bordered(forTextField: true)
        passwordTextField.rounded(forTextField: true)
    }

    private func checkUser() {
        guard let username = usernameTextField.text,
              let password = passwordTextField.text else { return }
        
        let existingUsers = StorageManager.shared.loadExistingUsers()
        let user = User()
        user.name = username
        user.password = password
        user.photos = existingUsers?.filter { $0.name == user.name && $0.password == user.password }.first?.photos
        
        if existingUsers?.filter({ $0.name == user.name && $0.password == user.password }).count == .zero {
            if existingUsers?.filter({ $0.name == username }).count == .zero {
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
        
        usernameTextField.text = nil
        passwordTextField.text = nil
        usernameWarningLabel.isHidden = true
        passwordWarningLabel.isHidden = true
        view.endEditing(true)
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        usernameWarningLabel.isHidden = true
        passwordWarningLabel.isHidden = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
