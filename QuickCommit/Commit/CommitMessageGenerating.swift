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
        case nonImperative
        case overlyOperational
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
        let normalized = value.lowercased()
        if Self.genericSubjects.contains(normalized) || Self.isCountOnlySubject(normalized) {
            issues.append(.generic)
            score -= 40
        }
        if let firstWord = normalized.split(separator: " ").first,
           !Self.imperativeVerbs.contains(String(firstWord)) {
            issues.append(.nonImperative)
            score -= 20
        }
        if Self.isOverlyOperationalSubject(normalized) {
            issues.append(.overlyOperational)
            score -= 20
        }
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

    private static let imperativeVerbs: Set<String> = [
        "add", "adjust", "allow", "block", "build", "change", "configure", "create", "delete", "disable", "document", "enable", "expose", "fix", "handle", "improve", "introduce", "migrate", "move", "prevent", "refactor", "refine", "remove", "rename", "replace", "restore", "simplify", "split", "support", "update", "use"
    ]

    private static func isCountOnlySubject(_ value: String) -> Bool {
        value.range(of: #"^(add|change|modify|remove|update) (the )?\d+ files?$"#, options: .regularExpression) != nil
    }

    private static func isOverlyOperationalSubject(_ value: String) -> Bool {
        value.range(of: #"^(add|change|modify|remove|update) file:.*$"#, options: .regularExpression) != nil
    }
}

extension CommitMessageGenerating {
    func subject(for context: CommitChangeContext) async -> String {
        (try? await message(for: context).subject) ?? "Update project files"
    }
}
