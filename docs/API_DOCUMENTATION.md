# API contract (proposed, v1)
Base: `/api/v1`. Auth: `Authorization: Bearer <accessToken>`. **Only the envelope and error handling exist today; endpoints below are the plan.**

Success: `{ "success": true, "message": "...", "data": {...}, "timestamp": "..." }`
Error: `{ "success": false, "message": "...", "errorCode": "ROOM_CAPACITY_EXCEEDED", "fieldErrors": {...}?, "timestamp": "..." }`
Pages: `data = { content: [], page, size, totalElements, totalPages }`

| Area | Endpoints |
|---|---|
| Auth | POST `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout` |
| Users | GET/PUT `/users/me`, PUT `/users/me/password`, GET `/users/me/history`, GET/PUT/DELETE `/users/me/favourites[/{movieId}]` |
| Movies | GET `/movies` (page, size, sort, genre), `/movies/{id}`, `/movies/search?q=`, `/movies/trending`, `/movies/popular`, `/movies/recent`; ADMIN: POST, PUT, DELETE |
| Streaming | GET `/movies/{id}/stream` → `{ protocol, url, qualities[], subtitles[], expiresAt }` |
| Rooms | POST `/rooms`, GET `/rooms` (public), GET `/rooms/{id}`, GET `/rooms/by-code/{code}`, POST `/rooms/{id}/join`, `/leave`, `/close`, GET `/rooms/{id}/members`, GET `/rooms/{id}/playback` |
| Chat | GET `/rooms/{id}/messages?page=&size=` |

## Differences from the current frontend contract (`docs/INTEGRATION.md`)
1. **Envelope**: the frontend reads raw bodies; backend wraps in `data`. Fix once in the Axios response interceptor (`res.data = res.data.data`).
2. **Tokens**: frontend expects `{ user, token }`; backend returns `{ user, accessToken, refreshToken }`. The frontend needs a refresh interceptor and logout call.
3. **Rooms**: frontend `isPublic` → backend `visibility`; frontend `hostName` comes from a host summary; backend adds `inviteCode`, `status`, `participantCount`, `expiresAt`. Frontend `GET /rooms/{id}` in mock mode is keyed by short id; backend uses UUID plus `inviteCode`.
4. **Movies**: frontend `videoUrl` is replaced by the `/stream` endpoint; `poster`/`backdrop` → `posterUrl`/`backdropUrl`.
5. **Realtime**: frontend `RealtimeService` maps to STOMP (see `WEBSOCKET_DESIGN.md`); the mock's `participants` event maps to presence events.
