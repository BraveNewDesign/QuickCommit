struct CommitChangeContext: Equatable, Sendable {
    var changedFileCount: Int
    var modifiedFileCount: Int
    var untrackedFileCount: Int
    var deletedFileCount: Int
    var hasConflicts: Bool
    var paths: [String]

    static let empty = Self(changedFileCount: 0, modifiedFileCount: 0, untrackedFileCount: 0, deletedFileCount: 0, hasConflicts: false, paths: [])
}
