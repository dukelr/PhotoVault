
import UIKit

//MARK: - Enums

private enum Direction {
    case previous
    case next
}

private enum AlertActionTitle: String {
    case camera = "Camera"
    case photoLibrary = "Photo Library"
    case ok = "OK"
    case remove = "Remove"
    case cancel = "Cancel"
}

//MARK: - Extensions

private extension UIImage {
    static let isLiked = UIImage(systemName: "heart.fill")
    static let noLiked = UIImage(systemName: "heart")
}

private extension UIColor {
    static let likeColor = UIColor(named: "like")
}

private extension TimeInterval {
    static let duration = 0.3
}

//MARK: - Protocols

protocol PhotoViewControllerDelegate: AnyObject {
    func photoViewControllerClosed()
}

final class PhotoViewController: UIViewController {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var fullScreenPhotoImageView: UIImageView!
    @IBOutlet weak var fullScreenPhotoImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var photoImageView: UIImageView!
    
    //MARK: - var/let
    
    static let identifier = "PhotoViewController"
    weak var delegate: PhotoViewControllerDelegate?
    var addingPhoto = Bool()
    var index = Int()
    private var user = User()
    private var existingUsers = [User]()
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - IBActions
    
    @IBAction func previousButtonPressed(_ sender: UIButton) {
        showPhoto(.previous)
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        showPhoto(.next)
    }
    
    @IBAction func removeButtonPressed(_ sender: UIButton) {
        showAlert()
    }
    
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        likePhoto()
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        showImagePicker()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        delegate?.photoViewControllerClosed()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapDetected(_ recognizer: UITapGestureRecognizer) {
        makePhotoInFullScreen()
    }
    
    @IBAction func keyboardShowed(_ notification: NSNotification) {
        showKeyboard(notification)
    }
    
    
    //MARK: - flow funcs
    
    private func setupSubviews() {
        guard let user = StorageManager.shared.loadUser(),
              let users = StorageManager.shared.loadExistingUsers() else { return }
        
        self.user = user
        self.existingUsers = users
        
        if addingPhoto {
            showImagePicker()
        }
        if let photos = user.photos {
            photoImageView.image = StorageManager.shared.loadImage(fileName: photos[index].name)
            commentLabel.text = photos[index].comment
            
            if photos[index].isLiked {
                likeButton.setBackgroundImage(.isLiked, for: .normal)
                likeButton.tintColor = .likeColor
            } else {
                likeButton.setBackgroundImage(.noLiked, for: .normal)
                likeButton.tintColor = .darkGray
            }
        }
        commentTextField.rounded(forTextField: true)
        commentTextField.bordered(forTextField: true)
        registerForKeyboardNotifications()
        addGestureRecognizers()
        fullScreenPhotoImageViewHeightConstraint.constant = view.frame.width
        view.layoutIfNeeded()
    }
    
    private func addGestureRecognizers() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        tap.numberOfTapsRequired = 2
        photoImageView.addGestureRecognizer(tap)
        
        let fullScreenTap = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        fullScreenTap.numberOfTapsRequired = 2
        fullScreenPhotoImageView.addGestureRecognizer(fullScreenTap)
    }
    
    private func makePhotoInFullScreen() {
        fullScreenPhotoImageView.image = photoImageView.image
        fullScreenPhotoImageView.isHidden = false
        scrollView.isHidden = true
        
        if fullScreenPhotoImageViewHeightConstraint.constant == view.frame.height {
            fullScreenPhotoImageViewHeightConstraint.constant = view.frame.width
        } else {
            fullScreenPhotoImageViewHeightConstraint.constant = view.frame.height
        }
        UIView.animate(withDuration: .duration) { [weak self] in
            guard let self = self else { return }

            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            if self.fullScreenPhotoImageViewHeightConstraint.constant == self.view.frame.width {
                self.scrollView.isHidden = false
                self.fullScreenPhotoImageView.isHidden = true
            }
        }
    }
    
    private func createPhoto() -> UIImageView {
        let photo = UIImageView(frame: photoImageView.frame)
        photo.frame.origin.x = photoImageView.frame.width
        photo.frame.size = photoImageView.frame.size
        photo.contentMode = photoImageView.contentMode
        photo.clipsToBounds = true
        view.addSubview(photo)
        return photo
    }
    
    private func showPhoto(_ direction: Direction) {
        guard let photos = user.photos else { return }
        
        let photo = createPhoto()
        getIndexForPhoto(direction)
        
        switch direction {
        case .previous:
            photo.frame.origin.x = photoImageView.frame.origin.x
            photo.image = photoImageView.image
            photoImageView.image = StorageManager.shared.loadImage(fileName: photos[index].name)
        case .next:
            photo.image = StorageManager.shared.loadImage(fileName: photos[index].name)
        }
        animatePhoto(photo)
        updatePhoto()
    }
    
    private func getIndexForPhoto(_ direction: Direction) {
        guard let photos = user.photos else { return }

        switch direction {
        case .previous:
            if index > 0 {
                index -= 1
            } else {
                index = photos.count - 1
            }
        case .next:
            if index < photos.count - 1 {
                index += 1
            } else {
                index = 0
            }
        }
    }
    
    private func animatePhoto(_ imageView: UIImageView) {
        guard let photos = user.photos else { return }
        
        UIView.animate(withDuration: .duration) { [weak self] in
            guard let self = self else { return }

            imageView.frame.origin.x -= self.photoImageView.frame.width
        } completion: { [weak self] _ in
            guard let self = self else { return }

            self.photoImageView.image = StorageManager.shared.loadImage(fileName: photos[self.index].name)
            imageView.removeFromSuperview()
        }
    }
    
    private func likePhoto() {
        guard let photos = user.photos else { return }
        
        if likeButton.currentBackgroundImage == .noLiked {
            likeButton.setBackgroundImage(.isLiked, for: .normal)
            likeButton.tintColor = .likeColor
            photos[index].isLiked = true
        } else {
            likeButton.setBackgroundImage(.noLiked, for: .normal)
            likeButton.tintColor = .darkGray
            photos[index].isLiked = false
        }
        user.photos = photos
        StorageManager.shared.saveUser(user)
        StorageManager.shared.saveUserInExistingUsers(user, in: existingUsers)
    }
    private func addComment() {
        guard let photos = user.photos,
              let comment = commentTextField.text else { return }
        
        commentLabel.text = comment
        photos[index].comment = comment
        user.photos = photos
        StorageManager.shared.saveUser(user)
        StorageManager.shared.saveUserInExistingUsers(user, in: existingUsers)
        commentTextField.text = nil
        commentTextField.placeholder = "Edit comment"
    }
    
    private func updatePhoto() {
        guard let photos = user.photos else { return }
        if photos[index].isLiked == true {
            likeButton.setBackgroundImage(.isLiked, for: .normal)
            likeButton.tintColor = .likeColor
        } else {
            likeButton.setBackgroundImage(.noLiked, for: .normal)
            likeButton.tintColor = .darkGray
        }
        commentLabel.text = photos[index].comment
        if commentLabel.text == nil {
            commentTextField.placeholder = "Add a comment"
        } else {
            commentTextField.placeholder = "Edit comment"
        }
    }
    
    private func removePhoto() {
        guard let photos = user.photos else { return }
        let filteredPhotos = photos.filter { $0.name != photos[index].name }
        
        if filteredPhotos.isEmpty {
            photoImageView.image = .none
            user.photos = nil
            showAlert()
        } else {
            if index > 0 {
                index -= 1
            } else {
                index = filteredPhotos.count - 1
            }
            user.photos = filteredPhotos
            photoImageView.image = StorageManager.shared.loadImage(fileName: filteredPhotos[index].name)
            updatePhoto()
        }
        StorageManager.shared.saveUser(user)
        StorageManager.shared.saveUserInExistingUsers(user, in: existingUsers)
    }
    
    private func showAlert() {
        let alert = UIAlertController(
            title: user.name,
            message: "Do you want remove this photo?",
            preferredStyle: .alert
        )
        if user.photos == nil {
            alert.message = "You don't have photos"
            alert.addAction(
                UIAlertAction(
                    title: AlertActionTitle.ok.rawValue,
                    style: .default
                ) { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.navigationController?.popViewController(animated: true)
                }
            )
        } else {
            alert.addAction(
                UIAlertAction(
                    title: AlertActionTitle.remove.rawValue,
                    style: .destructive
                ) { [weak self] _ in
                    guard let self = self else { return }

                    self.removePhoto()
                }
            )
            alert.addAction(
                UIAlertAction(
                    title: AlertActionTitle.cancel.rawValue,
                    style: .cancel
                )
            )
        }
        present(alert, animated: true)
    }
    
    private func showImagePicker() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(
            UIAlertAction(
                title: AlertActionTitle.camera.rawValue,
                style: .default
            ) { _ in
                //                picker.sourceType = .camera
                //                present(picker, animated: true)
            }
        )
        alert.addAction(
            UIAlertAction(
                title: AlertActionTitle.photoLibrary.rawValue,
                style: .default
            ) { [weak self] _ in
                guard let self = self else { return }

                picker.sourceType = .photoLibrary
                self.present(picker, animated: true)
            }
        )
        alert.addAction(
            UIAlertAction(
                title: AlertActionTitle.cancel.rawValue,
                style: .cancel
            ) { [weak self ]_ in
                guard let self = self else { return }

                if self.photoImageView.image == nil {
                    self.delegate?.photoViewControllerClosed()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        )
        present(alert, animated: true)
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardShowed),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardShowed),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func showKeyboard(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
              let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollViewBottomConstraint.constant = .zero
        } else {
            let offset = 10.0
            scrollViewBottomConstraint.constant = keyboardScreenEndFrame.height + offset
        }

        UIView.animate(withDuration: animationDuration) { [weak self] in
            guard let self = self else { return }

            self.view.layoutIfNeeded()
        }
    }
}

//MARK: - Extensions

extension PhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var image = UIImage()
        
        if let chooseImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            image = chooseImage
        }
        if let chooseImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            image = chooseImage
        }
        guard let name = StorageManager.shared.saveImage(image) else { return }
        
        if let photos = user.photos {
            var newPhotos = photos
            newPhotos.append(Photo(name: name, isLiked: false))
            user.photos = newPhotos
            index = newPhotos.count - 1
        } else {
            user.photos = [Photo(name: name, isLiked: false)]
            index = 0
        }
        photoImageView.image = image
        commentLabel.text = nil
        likeButton.setBackgroundImage(.noLiked, for: .normal)
        likeButton.tintColor = .darkGray
        
        StorageManager.shared.saveUser(user)
        StorageManager.shared.saveUserInExistingUsers(user, in: existingUsers)
        dismiss(animated: true)
    }
}

extension PhotoViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text,
           text != "" {
            addComment()
        }
        textField.resignFirstResponder()
        return true
    }
}
