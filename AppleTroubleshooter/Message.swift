import Foundation
import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let role: Role
    let text: String
    let image: UIImage?
    let timestamp = Date()

    enum Role {
        case user
        case assistant
    }

    init(role: Role, text: String, image: UIImage? = nil) {
        self.role = role
        self.text = text
        self.image = image
    }
}
