# Contributing to Quick Commit

Thanks for helping improve Quick Commit. The project is intentionally focused on a small, private, one-click Git checkpoint workflow.

## Before opening a change

- Read `AGENTS.md` and the current specification in `Docs/Specifications/QuickCommitSpec.md`.
- Keep product scope narrow unless the specification is intentionally updated.
- Preserve unrelated working-tree changes.
- Do not add Git CLI calls, remote operations, destructive Git commands, or external AI services.
- Do not send repository contents or secrets to external services.

## Development

Requirements are macOS 26 or newer and Xcode 27 or newer. Build and run the `QuickCommit` scheme in Xcode, or use:

```text
./script/build_and_run.sh --verify
```

Use temporary repositories for integration tests. Do not test by committing changes in a developer's real repository. When testing the menu-bar UI, the DEBUG-only `QuickCommitUITestWindow` launch argument exposes the menu-bar content in an ordinary window for accessibility testing.

## Pull requests

Please include:

- a short description of the user-visible behavior;
- tests or runtime evidence for behavior changes;
- any sandbox, signing, or Apple Intelligence availability limitations;
- documentation updates for durable architectural or release decisions.

Do not include credentials, private repository contents, generated build products, or personal logs in an issue or pull request.
