# Quick Commit v1 Implementation Plan

## Completion tracker

| Gate | Scope | Status | Evidence |
| --- | --- | --- | --- |
| 0 | Specification and durable architecture | Complete | Spec, architecture, and development docs updated |
| 1 | Serialized, recoverable libgit2 transaction | Implemented; runtime qualification pending | Actor boundary, error capture, index fingerprint recovery, missing-identity and in-progress-operation tests |
| 2 | Bookmarks, persistence, monitoring | Implemented; exported-app runtime qualification pending | Balanced leases, stale renewal path, schema migration, removal cleanup, disposable repository runtime coverage |
| 3 | Foundation Models and deterministic fallback | Implemented; compatible-device source capture pending | Availability check, bounded prompt, fresh session, timeout, output-quality evaluation, privacy-safe telemetry, fallback |
| 4 | Store, menu-bar UI, Settings | Implemented; exported-app runtime qualification pending | DEBUG AppKit harness, global busy state, clean action disabled, actionable errors, launch-at-login wiring, bundle About data |
| 5 | Automated/runtime verification | In progress | Focused unit tests and disposable runtime flows pass; full matrix, Apple Intelligence-enabled runtime, and exported-app evidence remain |
| 6 | Package and release qualification | Approval-gated | No credentials, final branding, or external submission performed |

## Acceptance boundary

Local verification must include temporary repositories created through libgit2, focused unit tests, Debug/Release builds, `git diff --check`, static forbidden-operation search, entitlement inspection, and exported-app runtime checks where accessibility and signing allow. Environment-blocked UI, live model, notarization, and App Store evidence must be reported as blocked rather than passed.
