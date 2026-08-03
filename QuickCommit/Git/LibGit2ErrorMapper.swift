import Foundation

enum LibGit2ErrorMapper {
    static func map(_ error: Error) -> RepositoryError {
        _ = error
        return .gitOperationFailed
    }

    static func map(code: Int32) -> RepositoryError {
        switch code {
        // libgit2's public error enum is not imported by the package module on all
        // Xcode toolchains, so keep the documented stable values local here.
        case -3: return .invalidRepository       // GIT_ENOTFOUND
        case -14: return .repositoryLocked       // GIT_ELOCKED
        case -13: return .conflictedRepository   // GIT_ECONFLICT
        default: return .gitOperationFailed
        }
    }
}
