import Foundation
import CoreGraphics

struct WindowInfo: Identifiable, Equatable {
    let id: UUID = UUID()
    let windowNumber: Int
    let ownerPID: pid_t
    let ownerName: String
    let title: String
    let bundleIdentifier: String?
    
    var displayTitle: String {
        title.trimmingCharacters(in: .whitespaces).isEmpty ? ownerName : title
    }
    
    static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
        lhs.windowNumber == rhs.windowNumber && lhs.ownerPID == rhs.ownerPID
    }
}
