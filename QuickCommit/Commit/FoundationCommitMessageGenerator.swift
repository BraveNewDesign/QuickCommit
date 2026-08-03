import Foundation

struct FoundationCommitMessageGenerator: CommitMessageGenerating {
    func subject(for context: CommitChangeContext) async -> String {
        // Foundation Models is optional at runtime. Until the framework reports an
        // available on-device model, use the deterministic local generator.
        let fallback = await FallbackCommitMessageGenerator().subject(for: context)
        return Self.validated(fallback) ?? "Update project files"
    }

    static func validated(_ output: String) -> String? {
        let value = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains("\n"), value.count <= 120 else { return nil }
        return value
    }
}
