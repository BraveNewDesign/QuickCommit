# Git Transaction Safety

`LibGit2Service` is an actor. Every repository, index, status list, signature, and libgit2 runtime lease is scoped to that actor operation and freed on every path. Failures capture `git_error_last()` immediately.

Preparation snapshots the index bytes and fingerprint, stages all worktree changes through libgit2, and records the staged fingerprint. Commit rechecks the fingerprint. Rollback writes the prior index only if the staged fingerprint still matches; an external mutation produces `indexChangedExternally` and leaves the external index unchanged.

Monitoring refreshes must not be treated as a second Git transaction. The store owns one global busy state and refreshes after completion.
