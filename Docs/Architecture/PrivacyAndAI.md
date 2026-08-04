# Privacy and on-device AI

Apple Foundation Models is used only through `SystemLanguageModel.default`. The app checks availability before each request, creates a new single-turn session, sends bounded change counts plus normalized relative paths and a bounded patch, and asks for a one-line subject. Paths and patch text are explicitly untrusted prompt data and are delimited as change data. No network entitlement or external AI service is used.

Generated subjects and repository contents are never logged. The privacy-safe telemetry records only the source (`appleIntelligence` or `fallback`), changed-file counts, character counts, likely-generated-file counts, latency, and quality score. Generated output is validated for one-line format, length, imperative style, useful specificity, and generated-file focus. Unavailable, refused, invalid, rate-limited, timed-out, or otherwise failed requests use the deterministic local generator.
