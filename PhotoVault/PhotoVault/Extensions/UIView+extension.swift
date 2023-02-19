
import UIKit
import Foundation

extension UIView {
    
    func rounded(radius: CGFloat = 15) {
        layer.cornerRadius = radius
    }
    
    func bordered(width: CGFloat = 1) {
        layer.borderWidth = width
    }
}
