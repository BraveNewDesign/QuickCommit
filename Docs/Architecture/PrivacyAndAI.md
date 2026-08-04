# Privacy and on-device AI

Apple Foundation Models is used only through `SystemLanguageModel.default`. The app checks availability before each request, creates a new single-turn session, sends only bounded counts and normalized relative paths, and asks for a one-line subject. Paths are explicitly untrusted prompt data. No network entitlement or external AI service is used. Generated output is validated and never logged; unavailable, refused, invalid, rate-limited, timed-out, or otherwise failed requests use the deterministic local generator.
