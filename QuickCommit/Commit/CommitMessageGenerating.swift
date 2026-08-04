import Foundation

protocol CommitMessageGenerating: Sendable {
    func message(for context: CommitChangeContext) async throws -> GeneratedCommitMessage
}

struct CommitMessageQuality: Equatable, Sendable {
    let score: Int
    let issues: [Issue]

    enum Issue: Equatable, Sendable {
        case empty
        case tooLong
        case containsNewline
        case terminalPunctuation
        case generic
        case mentionsGeneratedFile
    }

    var isAcceptable: Bool { score >= 75 && issues.isEmpty }
}

enum CommitMessageQualityEvaluator {
    static func evaluate(_ subject: String, for context: CommitChangeContext) -> CommitMessageQuality {
        let value = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        var issues: [CommitMessageQuality.Issue] = []
        var score = 100

        if value.isEmpty { issues.append(.empty); score -= 100 }
        if value.count > 72 { issues.append(.tooLong); score -= 30 }
        if value.contains("\n") || value.contains("\r") { issues.append(.containsNewline); score -= 40 }
        if value.last.map({ ".!?;:".contains($0) }) == true { issues.append(.terminalPunctuation); score -= 10 }
        if Self.genericSubjects.contains(value.lowercased()) { issues.append(.generic); score -= 40 }
        if context.likelyGeneratedPaths.contains(where: { path in
            let name = URL(fileURLWithPath: path).lastPathComponent.lowercased()
            return value.lowercased().contains(name)
        }) {
            issues.append(.mentionsGeneratedFile)
            score -= 40
        }

        return CommitMessageQuality(score: max(0, score), issues: issues)
    }

    private static let genericSubjects: Set<String> = [
        "update project files",
        "update files",
        "update one file",
        "add new file",
        "add 1 new file",
        "make changes",
        "miscellaneous changes"
    ]
}

extension CommitMessageGenerating {
    func subject(for context: CommitChangeContext) async -> String {
        (try? await message(for: context).subject) ?? "Update project files"
    }
}
