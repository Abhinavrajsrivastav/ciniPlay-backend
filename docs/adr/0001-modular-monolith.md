# ADR 0001: Start as a modular monolith
**Status** Accepted. **Context** Solo project, evolving domain, goal to learn extraction. **Decision** Single Spring Boot app, module-per-package, one database, no cross-module table access. **Consequences** Simple local dev and transactions; must police boundaries; extraction later via events (Kafka) and API contracts.
