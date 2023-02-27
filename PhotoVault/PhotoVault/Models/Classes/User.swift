
import Foundation

final class User: Codable {
    
    var name: String?
    var password: String?
    var photos: [Photo]?
}
