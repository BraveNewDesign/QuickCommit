import Foundation

nonisolated struct CommitChangeContext: Equatable, Sendable {
    var changedFileCount: Int
    var stagedFileCount: Int
    var unstagedFileCount: Int
    var modifiedFileCount: Int
    var untrackedFileCount: Int
    var deletedFileCount: Int
    var renamedFileCount: Int
    var typeChangedFileCount: Int
    var hasConflicts: Bool
    var repositoryOperation: RepositoryOperationState
    var paths: [String]
    var diffText: String

    init(changedFileCount: Int, modifiedFileCount: Int, untrackedFileCount: Int, deletedFileCount: Int, hasConflicts: Bool, paths: [String], stagedFileCount: Int = 0, unstagedFileCount: Int = 0, renamedFileCount: Int = 0, typeChangedFileCount: Int = 0, repositoryOperation: RepositoryOperationState = .idle, diffText: String = "") {
        self.changedFileCount = changedFileCount; self.stagedFileCount = stagedFileCount; self.unstagedFileCount = unstagedFileCount; self.modifiedFileCount = modifiedFileCount; self.untrackedFileCount = untrackedFileCount; self.deletedFileCount = deletedFileCount; self.renamedFileCount = renamedFileCount; self.typeChangedFileCount = typeChangedFileCount; self.hasConflicts = hasConflicts; self.repositoryOperation = repositoryOperation; self.paths = paths; self.diffText = diffText
    }

    nonisolated var isClean: Bool { changedFileCount == 0 }

    nonisolated var likelyGeneratedPaths: [String] {
        paths.filter(Self.isLikelyGeneratedPath)
    }

    nonisolated static func isLikelyGeneratedPath(_ path: String) -> Bool {
        let name = URL(fileURLWithPath: path).lastPathComponent.lowercased()
        return name == ".ds_store" || name == "thumbs.db" || name == ".localized" || name.hasSuffix(".swp") || name.hasSuffix("~") || name == "desktop.ini"
    }

    nonisolated static let empty = Self(changedFileCount: 0, modifiedFileCount: 0, untrackedFileCount: 0, deletedFileCount: 0, hasConflicts: false, paths: [], stagedFileCount: 0, unstagedFileCount: 0, renamedFileCount: 0, typeChangedFileCount: 0, repositoryOperation: .idle)
}

enum RepositoryOperationState: String, Codable, Equatable, Sendable {
    case idle
    case merge
    case revert
    case cherryPick
    case rebase
    case bisect
    case mailbox
}
