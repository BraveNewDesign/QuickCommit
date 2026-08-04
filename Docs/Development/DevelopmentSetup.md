# Development Setup

- macOS 26.0 or newer
- Xcode 27 or newer with the macOS SDK
- Deployment target: macOS 26.0
- Swift Package Manager dependency: `libgit2` 1.9.2, product `libgit2`
- App Sandbox enabled with user-selected file read/write and app-scoped bookmarks

Build with the `QuickCommit` scheme in Xcode or with `xcodebuild -project QuickCommit.xcodeproj -scheme QuickCommit -configuration Debug build`. Run unit tests with `xcodebuild test -project QuickCommit.xcodeproj -scheme QuickCommit -destination 'platform=macOS'`.

The specification lives in `Docs/Specifications/`, plans in `Docs/ImplementationPlans/`, and durable technical decisions in `Docs/Architecture/`.

Do not disable App Sandbox to make repository access easier. Solve sandbox problems with correct user selection, security-scoped bookmark handling, and balanced access calls.

The v1 implementation includes repository selection and validation, security-scoped bookmark persistence, change monitoring, direct libgit2 inspection and checkpointing, settings persistence, launch-at-login wiring, deterministic commit-message fallback, and optional Apple Foundation Models generation. The model controls only the commit subject; malformed, low-quality, unavailable, or failed output falls back locally.

For normal verification, run:

```text
./script/build_and_run.sh --verify
```

The script builds into `.build/DerivedData` and runs the focused unit-test suite. The DEBUG-only runtime harness can expose the menu-bar content in an ordinary window for accessibility testing:

```text
open -n "/path/to/QuickCommit.app" --args QuickCommitUITestWindow
```

Use a disposable repository for runtime commits. Capture only privacy-safe model telemetry with `./script/build_and_run.sh --telemetry`; repository contents and generated subjects are never written to logs. Apple Intelligence source and latency remain a runtime qualification item on an Apple-Intelligence-enabled Mac.

The app uses the SwiftPM-compatible libgit2 package directly. It does not use SwiftGitX, the Git CLI, or shell wrappers.
