import Foundation

enum CommitProgress: Equatable, Sendable {
    case staging
    case generatingMessage
    case committing

    var label: String {
        switch self {
        case .staging: return "Staging…"
        case .generatingMessage: return "Generating message…"
        case .committing: return "Committing…"
        }
    }
}
