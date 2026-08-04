# Release Checklist

- [ ] Final icon, copyright, support URL, privacy text, category, pricing, and screenshots approved.
- [ ] Debug and Release builds are warning-clean; forbidden Git API/process search is empty.
- [ ] Developer ID archive has hardened runtime, secure timestamp, no `get-task-allow`, notarization, stapling, and Gatekeeper evidence.
- [ ] Mac App Store archive validates and uploads with privacy/export-compliance metadata recorded.
- [ ] Exported app, not DerivedData, passes add, relaunch, monitor, checkpoint, fallback, Settings, and quit flows.
