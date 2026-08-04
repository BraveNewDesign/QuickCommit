import Foundation

nonisolated struct AppSettings: Codable, Equatable, Sendable {
    var launchAtLogin = false
    var useAppleIntelligence = true
    var showCleanRepositories = true
    var commitIdentity: CommitIdentity?
}

nonisolated struct PersistedAppState: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2
    var schemaVersion = Self.currentSchemaVersion
    var repositories: [RepositoryRecord] = []
    var settings = AppSettings()
}
