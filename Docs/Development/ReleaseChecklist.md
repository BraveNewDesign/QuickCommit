# Release Checklist

- [ ] Final icon, copyright, support URL, privacy text, category, pricing, and screenshots approved.
- [ ] Debug and Release builds are warning-clean; forbidden Git API/process search is empty.
- [ ] Developer ID archive has hardened runtime, secure timestamp, no `get-task-allow`, notarization, stapling, and Gatekeeper evidence.
- [ ] Mac App Store archive validates and uploads with privacy/export-compliance metadata recorded.
- [ ] Exported app, not DerivedData, passes add, relaunch, monitor, checkpoint, fallback, Settings, and quit flows.
- [ ] Disposable-repository runtime matrix records invalid-folder rejection, missing identity, in-progress operation rejection, external-change refresh, generated-file warning, fallback commit, and clean-repository filtering.
- [ ] Apple-Intelligence-enabled runtime records availability, generation source, latency, output-quality score, and fallback behavior through privacy-safe telemetry; no repository content or subject is logged.
