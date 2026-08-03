# Development Setup

- macOS 26.0 or newer
- Xcode 27 or newer with the macOS SDK
- Deployment target: macOS 26.0
- Swift Package Manager dependency: `libgit2` 1.9.2, product `libgit2`
- App Sandbox enabled with user-selected file read/write and app-scoped bookmarks

Build with the `QuickCommit` scheme in Xcode or with `xcodebuild -project QuickCommit.xcodeproj -scheme QuickCommit -configuration Debug build`. Run unit tests with `xcodebuild test -project QuickCommit.xcodeproj -scheme QuickCommit -destination 'platform=macOS'`.

The specification lives in `Docs/Specifications/`, plans in `Docs/ImplementationPlans/`, and durable technical decisions in `Docs/Architecture/`.

Do not disable App Sandbox to make repository access easier. Solve sandbox problems with correct user selection, security-scoped bookmark handling, and balanced access calls.

Current limitations: repository selection, bookmark persistence, monitoring, Git operations, Foundation Models requests, settings persistence, and launch-at-login behavior are intentionally scaffold-only.

The app uses the SwiftPM-compatible libgit2 package directly. It does not use SwiftGitX, the Git CLI, or shell wrappers.
