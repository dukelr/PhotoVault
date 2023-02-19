
import Foundation

final class Photo: Codable {
    
    var name: String
    var comment: String?
    var isLiked: Bool
    
    init(name: String, isLiked: Bool) {
        self.name = name
        self.isLiked = isLiked
    }
}
