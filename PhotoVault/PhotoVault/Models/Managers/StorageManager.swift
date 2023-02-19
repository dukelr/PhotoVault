
import UIKit
import Foundation

private extension String {
    static let userKey = "user"
    static let usersKey = "users"
}

final class StorageManager {
    
    static let shared = StorageManager()
    
    private init() {}
    
    func saveUser(_ user: User) {
        UserDefaults.standard.set(encodable: user, forKey: .userKey)
    }
    
    func saveUserInExistingUsers(_ user: User, in users: [User]) {
        let existingUsers = users
        var filteredUsers = existingUsers.filter { $0.name != user.name }
        filteredUsers.append(user)
        UserDefaults.standard.set(encodable: filteredUsers, forKey: .usersKey)
    }
    
    func loadUser() -> User? {
        UserDefaults.standard.value(User.self, forKey: .userKey)
    }
    
    func loadExistingUsers() -> [User]? {
        UserDefaults.standard.value([User].self, forKey: .usersKey)
    }
    
    func saveImage(_ image: UIImage) -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileName = UUID().uuidString
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed old image")
            } catch let error {
                print("couldn't remove file at path", error)
            }
        }
        do {
            try data.write(to: fileURL)
            return fileName
        } catch let error {
            print("error saving file with error", error)
            return nil
        }
    }
    
    func loadImage(fileName: String) -> UIImage? {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let imageUrl = documentsDirectory.appendingPathComponent(fileName)
            let image = UIImage(contentsOfFile: imageUrl.path)
            return image
        }
        return nil
    }
}
