
import UIKit

private enum SegmentIndex: Int {
    case allPhotos = 0
    case likedPhotos = 1
    case addPhoto = 2
}

private extension CGFloat {
    static let inset = 2.0
    static let numberOfItemsInRow = 5.0
}

final class PhotovaultViewController: UIViewController {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    //MARK: - var/let
    
    static let identifier = "PhotovaultViewController"
    private var user = User()
    
    //MARK: - lifecycle funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }
    
    //MARK: - IBActions
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        changeValueInSegmentedControl()
    }

    @IBAction func accountButtonPressed(_ sender: UIButton) {
        pushAccountConttroller()
    }
    
    //MARK: - flow funcs
    
    private func configureSubviews() {
        if let user = StorageManager.shared.loadUser() {
            self.user = user
        }
        userLabel.text = user.name
        photoCollectionView.backgroundColor = .white
        photoCollectionView.contentInset = UIEdgeInsets(
            top: .zero,
            left: .inset,
            bottom: .zero,
            right: .inset)
    }
    
    private func pushPhotoControllerToAddPhoto() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: PhotoViewController.identifier) as? PhotoViewController else { return }
        
        if let photos = user.photos {
            controller.index = photos.count - 1
        } else {
            controller.index = 0
        }
        controller.addingPhoto = true
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushPhotoControllerToViewPhoto(at index: Int) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: PhotoViewController.identifier) as? PhotoViewController,
              let photos = user.photos else { return }
        
        if segmentedControl.selectedSegmentIndex == SegmentIndex.allPhotos.rawValue {
            controller.index = index
        }
        if segmentedControl.selectedSegmentIndex == SegmentIndex.likedPhotos.rawValue {
            photos.enumerated().forEach { indexPhoto,photo in
                if photo.name == photos.filter({ $0.isLiked == true })[index].name {
                    controller.index = indexPhoto
                }
            }
        }
        controller.addingPhoto = false
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func pushAccountConttroller() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: AccountViewController.identifier) as? AccountViewController else { return }
        controller.authorized = true
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func getPhotoForCollectionViewCell(with index: Int) -> UIImage {
        guard let photos = user.photos else { return UIImage() }
        
        var image = UIImage()
        if segmentedControl.selectedSegmentIndex == SegmentIndex.allPhotos.rawValue {
            if let photo = StorageManager.shared.loadImage(fileName: photos[index].name) {
                image = photo
            }
        }
        if segmentedControl.selectedSegmentIndex == SegmentIndex.likedPhotos.rawValue {
            if let photo = StorageManager.shared.loadImage(fileName: photos.filter { $0.isLiked == true }[index].name) {
                image = photo
            }
        }
        return image
    }
    
    private func getNumberOfItemsInSections() -> Int {
        guard let photos = user.photos else { return Int() }
        
        var numberOfItem = Int()
        if segmentedControl.selectedSegmentIndex == SegmentIndex.allPhotos.rawValue {
            numberOfItem = photos.count
        }
        if segmentedControl.selectedSegmentIndex == SegmentIndex.likedPhotos.rawValue {
            numberOfItem = photos.filter { $0.isLiked == true }.count
        }
        return numberOfItem
    }
    
    private func changeValueInSegmentedControl() {
        if segmentedControl.selectedSegmentIndex == SegmentIndex.addPhoto.rawValue {
            pushPhotoControllerToAddPhoto()
        } else {
            photoCollectionView.reloadData()
        }
    }
}

//MARK: - Extensions UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension PhotovaultViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        getNumberOfItemsInSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
        
        cell.configure(with: getPhotoForCollectionViewCell(with: indexPath.item))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        .inset
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .inset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let overallInset = (.numberOfItemsInRow + 1) * .inset
        let side = (photoCollectionView.frame.width - overallInset) / .numberOfItemsInRow
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pushPhotoControllerToViewPhoto(at: indexPath.item)
    }
}

//MARK: - Extensions PhotoViewControllerDelegate

extension PhotovaultViewController: PhotoViewControllerDelegate {
    func photoViewControllerClosed() {
        if let user = StorageManager.shared.loadUser() {
            self.user = user
        }
        segmentedControl.selectedSegmentIndex = SegmentIndex.allPhotos.rawValue
        photoCollectionView.reloadData()
    }
}
