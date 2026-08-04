# GitHub release guide

GitHub is the first planned distribution channel for Quick Commit. The app is free and open source under the [MIT License](../../LICENSE), and the first public release can be published as a downloadable macOS archive before the Mac App Store submission is complete.

The copyright holder for the project is Brave New Design LLC. Keep that holder name consistent in release metadata, app-store materials, and future copyright notices.

## Release asset

Upload an archive with this stable asset name:

```text
QuickCommit.zip
```

The archive should contain:

```text
Quick Commit.app
```

The README links to the latest release and expects that asset at:

```text
../../releases/latest/download/QuickCommit.zip
```

Keep the release version, marketing version, and archive name aligned. Publish a checksum alongside the archive, for example `SHA256SUMS.txt`, so users can verify the download.

## Qualification before publishing

- Build the Release configuration from `QuickCommit.xcodeproj`.
- Verify the app bundle has the expected identifier, version, menu-bar behavior, and App Sandbox entitlements.
- Test the exported app—not only the Xcode DerivedData copy—with a disposable repository.
- Verify add, relaunch, monitoring, fallback commit, settings, quit, and invalid-folder flows.
- Confirm no repository contents, generated subjects, credentials, or private logs are included in the release artifact.
- If Apple Intelligence is available on the qualification Mac, record source and latency through privacy-safe telemetry. The app must still work when it is unavailable.
- Create release notes that identify known limitations and clearly state that the App Store release is still pending.

## Signing and Gatekeeper

The preferred public distribution is a Developer ID-signed and notarized app. Signing and notarization require the maintainer’s Apple developer credentials and are intentionally not automated in this repository yet.

If an early development archive is unsigned, label it clearly as a development build and explain that macOS may display a Gatekeeper warning. Do not tell users to disable Gatekeeper globally. A signed and notarized archive should replace it for the first general-user release.

## Versioning

Use a new Git tag for each public release, for example:

```text
v1.0.0
```

The release title should match the tag. Do not reuse a release asset for a different build. Update the README’s release notes or download guidance when the distribution process changes.

## App Store status

The Mac App Store is a separate release channel. App Store submission, review, privacy metadata, signing, export compliance, screenshots, support information, and final legal branding remain TBD until explicitly approved and prepared. The MIT License permits you to sell your own official signed build through the App Store; App Store pricing and distribution are separate commercial decisions.
