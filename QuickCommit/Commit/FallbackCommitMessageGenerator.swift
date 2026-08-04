import Foundation

struct FallbackCommitMessageGenerator: CommitMessageGenerating {
    nonisolated init() {}
    func message(for context: CommitChangeContext) async throws -> GeneratedCommitMessage {
        let subject: String
        let meaningfulPaths = context.paths.filter { !CommitChangeContext.isLikelyGeneratedPath($0) }
        let pathDescription = Self.pathDescription(meaningfulPaths, totalCount: context.changedFileCount)
        let suffix = pathDescription.isEmpty ? "" : " \(pathDescription)"
        if context.renamedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Rename\(suffix)" }
        else if context.untrackedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Add\(suffix)" }
        else if context.deletedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Remove\(suffix)" }
        else if context.changedFileCount == 1 { subject = "Update\(suffix)" }
        else { subject = meaningfulPaths.isEmpty ? "Update repository metadata" : "Update\(suffix)" }
        return GeneratedCommitMessage(subject: subject, source: .fallback, fallbackReason: nil)
    }

    private static func pathDescription(_ paths: [String], totalCount: Int) -> String {
        let names = paths.prefix(2).map { URL(fileURLWithPath: $0).lastPathComponent }
        switch names.count {
        case 0:
            return ""
        case 1 where totalCount <= 1:
            return names[0]
        case 1:
            return "\(names[0]) and \(max(1, totalCount - 1)) more"
        default:
            let remaining = max(0, totalCount - names.count)
            return remaining == 0
                ? names.joined(separator: " and ")
                : "\(names[0]), \(names[1]), and \(remaining) more"
        }
    }
}
