
import UIKit

extension UIView {
    
    func rounded(forTextField: Bool = false) {
        let radius = CGFloat(15)
        if forTextField {
            layer.cornerRadius = radius / 3
            return
        }
        layer.cornerRadius = radius
    }
    
    func bordered(forTextField: Bool = false) {
        let width = CGFloat(1)
        if forTextField {
            layer.borderWidth = width / 2
            return
        }
        layer.borderWidth = width
    }
}
