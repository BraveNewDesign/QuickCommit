# Quick Commit runtime and commit-message tracker

## Current findings

| ID | Finding | Status | Evidence / next step |
| --- | --- | --- | --- |
| RT-001 | Menu-bar-only UI was not inspectable through Computer Use. | Resolved | DEBUG launch argument `QuickCommitUITestWindow` opens a retained AppKit `NSWindow`; verify through the accessibility tree before UI actions. |
| RT-002 | Clean repositories can be hidden and restored from Settings. | Verified | Disposable runtime repository flow confirmed the visible list changes; restore the preference after tests. |
| RT-003 | Generated files can dominate a fallback subject. | Improving | `.DS_Store` is surfaced as an advisory warning and excluded from deterministic fallback subjects. Add regression cases for other machine-created paths. |
| RT-004 | `Add file: name` is operational rather than descriptive. | Verified | Fallback now emits `Add name`; quality evaluation rejects the old operational form. |
| RT-005 | Count-only subjects such as `Update 3 files` are too vague. | Verified | Quality evaluation rejects count-only subjects; fallback summarizes representative paths instead. |
| RT-006 | Apple Intelligence generation has not been proven on an Apple-Intelligence-enabled runtime. | Open | Run the DEBUG harness on a compatible device, capture availability, latency, source, and quality score without logging repository contents. |
| RT-007 | A transient “could not checkpoint this repository” message appeared while toggling clean-repository visibility. | Fixed; runtime verified | The DEBUG harness reproduced the stale message. After the lifecycle fix and rebuild, toggling clean-repository visibility cleared it from the main window while preserving the repository list. |
| RT-008 | Disposable end-to-end commit produced `Update README.md`, which is safe but does not reveal whether Apple Intelligence or fallback generated it. | Verified fallback path; Apple-enabled proof pending | With “Use Apple Intelligence” enabled, the disposable commit produced `Update README.md`; system log telemetry recorded `source=fallback changedFiles=1 likelyGeneratedFiles=0` without subjects or diffs. This runtime did not expose Apple Intelligence availability, so compatible-device proof remains open. |
| RT-009 | Missing Git identity was previously surfaced as a generic libgit2 failure. | Verified | Empty repository-local identity now resolves to `nil`; focused test passes and the coordinator can present the identity-specific error. |
| RT-010 | Checkpointing during an in-progress merge/rebase/cherry-pick must be refused. | Verified | `.git/MERGE_HEAD` fixture maps to `.repositoryOperationInProgress(.merge)` in focused tests. |
| RT-011 | Scheme-wide UI-test runner exits before establishing its connection on this host. | Environment blocked | All `ModelScaffoldTests` pass; the DEBUG AppKit window was exercised manually through Computer Use. Repeat exported-app UI tests on a host where the UI-test runner bootstraps successfully. |

## Message-quality evaluation matrix

Every prompt or evaluator change should be run against representative local diffs covering:

- one new source or documentation file;
- one modified behavior with a meaningful patch;
- a mixed change with generated files present;
- deletion and rename;
- configuration-only changes;
- a diff containing instruction-like text that must remain untrusted data;
- empty, unavailable, timed-out, and malformed model responses.

Quality gates are deterministic and privacy-safe: imperative form, sentence case, one line, no terminal punctuation, 72-character maximum, non-generic wording, no generated-file focus, and evidence grounded in the supplied paths or patch. Model output remains advisory and falls back locally when a gate fails.

## Guidance applied

- Apple Foundation Models: check availability, use a fresh single-turn session, bound context, use guided structured output, and retain a deterministic fallback.
- OpenAI evaluation guidance: compare prompt revisions on the same representative cases, change one instruction group at a time, and track quality, latency, and fallback rate rather than relying on a single good example.
