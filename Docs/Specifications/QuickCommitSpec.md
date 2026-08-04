# Quick Commit v1 Specification

Quick Commit is a sandboxed macOS 26+ menu-bar utility that creates one Git checkpoint from the currently changed working tree with one click and no Git command-line process.

## Product contract

On first launch the user adds a working Git repository through `NSOpenPanel`. Quick Commit validates it, stores a security-scoped bookmark, observes it, and shows a clean or changed row. A changed row offers `Commit`; a clean row shows a disabled `Checkpoint` action. Only one checkpoint may run globally. The flow is inspect, resolve identity, prepare/stage, generate a subject, commit, recover on failure, and refresh once.

The repository Git identity is the default. A Settings override wins only when both trimmed name and email are usable. Apple Intelligence is on-device only, optional, bounded to change counts and normalized relative paths, and may influence only the subject. A deterministic local subject is always available.

## Safety and non-goals

Quick Commit never sends repository contents, diffs, secrets, or paths to an external service; never invokes Git CLI; and never performs reset, clean, checkout, merge, rebase, force push, remote operations, or destructive cleanup. It rejects bare, conflicted, clean, locked, and in-progress repositories.

If staging or generation fails, the exact prior index is restored only when the index still matches Quick Commit's staged fingerprint. If another process changed the index, recovery stops and reports that the external state was left untouched.

## Release channels

v1 targets both Developer ID distribution and Mac App Store distribution. Signing, notarization, upload, legal branding, support metadata, and final App Store content require explicit release approval and credentials.
