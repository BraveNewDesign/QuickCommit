# Architecture Overview

The intended flow is:

```text
SwiftUI UI → domain/coordinator → repository access → Git service
                                      ↘ monitoring
                                      ↘ persistence
                                      ↘ Foundation Models
```

UI must not call libgit2 directly or manage security-scoped bookmarks directly. Foundation Model output may only influence a commit-message subject; it must never select Git operations.

The v1 implementation should use in-process libgit2 through the isolated Git adapter, FSEvents as the primary repository change signal, security-scoped bookmarks for persisted user-selected access, and `SMAppService.mainApp` for launch-at-login.
