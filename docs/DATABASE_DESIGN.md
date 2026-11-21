# Database design
- UUID primary keys for externally visible entities; identity `BIGINT` for high-volume append tables (`chat_messages`, `playback_events`) for index locality.
- `TIMESTAMPTZ` everywhere, stored in UTC.
- **Indexes**: case-insensitive unique email; trigram index for title search; `(room_id, id DESC)` for chat pagination (keyset, no deep OFFSET); partial indexes for public open rooms and active members; `(user_id, last_watched_at DESC)` for history.
- **Constraints doing real work**: `chk_room_capacity`, `UNIQUE(room_id, seq)`, `UNIQUE(room_id, client_event_id)`, `PRIMARY KEY(room_id, user_id)`.
- **Refresh tokens**: only SHA-256 hashes stored; `family_id` lets us revoke the whole chain if a rotated token is reused.
- **Denormalised counter** `participant_count` trades a small consistency risk for O(1) capacity checks; it is only changed inside the join/leave transaction, and a CHECK guards it.
- Not yet created: outbox table (Phase 6), audit columns via Spring Data auditing (Phase 2+).
