# WebSocket / STOMP design (planned, Phase 5)
**Endpoint** `/ws`. **Auth**: JWT in the STOMP `CONNECT` header, validated by a `ChannelInterceptor`; the user principal is attached to the session. Every `SUBSCRIBE`/`SEND` re-checks room membership.

| Direction | Destination | Purpose |
|---|---|---|
| client→server | `/app/rooms/{id}/playback` | PLAY / PAUSE / SEEK request |
| client→server | `/app/rooms/{id}/chat` | chat message |
| server→room | `/topic/rooms/{id}/playback` | authoritative state events |
| server→room | `/topic/rooms/{id}/chat` | chat + system messages (JOIN/LEAVE) |
| server→room | `/topic/rooms/{id}/lifecycle` | ROOM_CLOSED |
| server→user | `/user/queue/rooms/{id}/state` | PLAYBACK_SYNC on join/reconnect |

**Playback state**: `{ roomId, movieId, positionMs, playing, serverTimeMs, seq, updatedBy, updatedAt }`.
**Rules**
1. Client sends `{ type, positionMs, clientEventId }`; it never sends an authoritative time.
2. Server checks membership, then permission (host, or `allow_member_control`), then validates the event.
3. Duplicate `clientEventId` → ignored (idempotent, backed by a unique constraint).
4. Server assigns `seq = seq + 1` in one transaction and broadcasts. Clients drop events with `seq <= lastApplied`; a gap triggers a request for `PLAYBACK_SYNC`.
5. Reconnect/join: client fetches `GET /rooms/{id}/playback` or receives `PLAYBACK_SYNC`.
6. While playing, clients compute `expectedPosition = positionMs + (estimatedServerNow - serverTimeMs)` and correct drift.

**Limits**: this synchronises state and timing, not video frames; each client's buffering and network jitter still vary. Single-instance first; multi-instance needs Redis pub/sub or a broker relay (Phase 6).
