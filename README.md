# Quick Commit

Quick Commit is a free, open-source macOS menu-bar utility for making a small Git checkpoint with one click.

It is focused on one simple idea: when a working tree has changes, creating a useful commit should be quick, local, and private. Quick Commit uses Apple Intelligence on device, when available, to suggest a concise commit subject from the change context. If Apple Intelligence is unavailable or produces an unsuitable result, the app uses a deterministic local fallback.

## Download

Download the latest macOS app from the [GitHub Releases page](../../releases/latest).

The direct download link will be published here when the first release asset is uploaded:

> [Download Quick Commit for macOS](../../releases/latest/download/QuickCommit.zip)

The App Store release is planned but not yet available. The GitHub release is the immediate distribution channel while App Store review and release preparation are pending.

## Install

1. Download `QuickCommit.zip` from the latest GitHub release.
2. Unzip it and move `Quick Commit.app` to `/Applications` or another folder you control.
3. Launch the app. It appears in the macOS menu bar.
4. Choose **Add Repository…** and select an existing Git repository.
5. When the repository has changes, choose **Commit**.

Only add repositories you trust. Quick Commit asks macOS for access to the folder you select and stores an app-scoped security bookmark so it can continue monitoring that repository.

For each release, the GitHub release page will include the app archive and a checksum when available. Download release assets only from this repository's official Releases page.

## Privacy and Apple Intelligence

- Apple Intelligence is optional and runs through Apple’s on-device Foundation Models APIs.
- The model is used only to suggest the commit subject.
- The prompt is bounded to relevant change context such as counts, normalized relative paths, and a limited patch.
- Repository contents, secrets, and source code are not sent to an external AI service.
- The app does not use a network AI API and does not invoke the Git command-line tool.
- Model output is checked for one-line format, length, imperative style, useful specificity, and generated-file noise.
- Failed, unavailable, or low-quality model output falls back to a local message generator.

Apple Intelligence availability depends on the Mac, operating-system configuration, language, and current Apple platform support. Quick Commit remains usable without it.

## What Quick Commit does

- Validates and monitors user-selected Git repositories.
- Uses libgit2 in process to inspect, stage, and create a checkpoint commit.
- Uses the repository Git identity by default, with an optional app-level identity override.
- Preserves safety around existing index changes and reports recoverable failures.
- Keeps the v1 workflow deliberately small: inspect changes, generate a subject, and commit.

## What it does not do

Quick Commit does not push, fetch, merge, rebase, switch branches, reset, clean, or delete repository data. It does not provide a GitHub client, remote management, an AI chat interface, or an external AI service.

## Requirements

- macOS 26 or newer
- An existing Git repository
- Apple Intelligence is optional; the local fallback works without it

## Build from source

Open `QuickCommit.xcodeproj` in Xcode 27 or newer, select the `QuickCommit` scheme, and build it for macOS. From the repository root, the supported verification command is:

```text
./script/build_and_run.sh --verify
```

The project uses the direct libgit2 package and requires App Sandbox entitlements for user-selected file access and app-scoped bookmarks. Production code must not use `/usr/bin/git` or spawn a Git process.

See [development setup](Docs/Development/DevelopmentSetup.md), [privacy and AI architecture](Docs/Architecture/PrivacyAndAI.md), and the [GitHub release guide](Docs/Development/GitHubRelease.md) for more detail.

## Contributing

Bug reports, documentation improvements, test fixtures, and focused pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before making changes.

## License

Quick Commit is released under the [MIT License](LICENSE). You may use, modify, distribute, and sell copies of the source software, provided the copyright and license notice are retained. The MIT License does not grant permission to use the Quick Commit name, logo, icons, or other branding to imply that a fork is the official project.

Copyright © 2026 Brave New Design LLC.

## Project status

This project is under active development. GitHub distribution is planned as the first public release channel. The Mac App Store release is planned separately and remains **TBD**.
