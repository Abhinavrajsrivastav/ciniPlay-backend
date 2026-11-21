# CinePlay Backend

Java 21 · Spring Boot 3.5 · Maven · PostgreSQL + Flyway. Modular monolith.

## Status (Phase 1 – foundation)
| Area | State |
|---|---|
| Maven project, Java 21, package skeleton for 9 modules | Created |
| Global exception handling, response envelope, JSON 401/403, CORS | Implemented |
| Flyway `V1` full schema (13 tables) | Written |
| Docker Compose (Postgres, Redis, Kafka KRaft) + Dockerfile | Written |
| OpenAPI (Swagger UI), Actuator, Prometheus endpoint | Configured |
| Auth, users, movies, rooms, WebSocket, chat, Redis use, Kafka use | **Not implemented** (later phases) |
| Compilation / startup / tests | **Not yet verified.** Run the commands below and send me any errors |

## Run
```bash
cp .env.example .env           # optional; defaults work locally
docker compose up -d           # postgres, redis, kafka
mvn spring-boot:run            # http://localhost:8080
mvn test                       # needs Docker (Testcontainers)
```
Check: http://localhost:8080/actuator/health → `{"status":"UP"}`, Swagger UI at `/swagger-ui.html`.
Any other URL returns a JSON 401 for now, since auth is not built yet.
Requires JDK 21 and Maven 3.9+.

See `docs/` for architecture, API contract, ER diagram, WebSocket design and roadmap.
