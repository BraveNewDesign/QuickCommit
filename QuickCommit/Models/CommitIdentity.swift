import Foundation

nonisolated struct CommitIdentity: Codable, Equatable, Sendable {
    var name: String
    var email: String

    var isUsable: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
