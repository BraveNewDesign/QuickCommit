import Foundation

nonisolated struct RepositoryRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var displayName: String
    var bookmarkData: Data
    var order: Int

    init(id: UUID = UUID(), displayName: String, bookmarkData: Data = Data(), order: Int = 0) {
        self.id = id
        self.displayName = displayName
        self.bookmarkData = bookmarkData
        self.order = order
    }
}
