
import UIKit

final class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    
    static let identifier = "PhotoCollectionViewCell"
    
    func configure(with image: UIImage) {
        photoImageView.image = image
    }
}
