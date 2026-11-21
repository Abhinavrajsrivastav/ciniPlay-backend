CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ===== Identity =====
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         VARCHAR(255) NOT NULL,
  display_name  VARCHAR(80)  NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  avatar_url    TEXT,
  status        VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','DISABLED','LOCKED')),
  preferences   JSONB        NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_users_email_lower ON users (lower(email));

CREATE TABLE roles (id SMALLINT PRIMARY KEY, name VARCHAR(30) NOT NULL UNIQUE);
INSERT INTO roles (id, name) VALUES (1, 'USER'), (2, 'ADMIN');

CREATE TABLE user_roles (
  user_id UUID     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id SMALLINT NOT NULL REFERENCES roles(id),
  PRIMARY KEY (user_id, role_id)
);

-- Only the SHA-256 hash of a refresh token is stored. family_id enables reuse detection on rotation.
CREATE TABLE refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  CHAR(64)    NOT NULL UNIQUE,
  family_id   UUID        NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked_at  TIMESTAMPTZ,
  replaced_by UUID,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_user   ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_family ON refresh_tokens (family_id);

-- ===== Catalogue =====
CREATE TABLE genres (id SMALLSERIAL PRIMARY KEY, name VARCHAR(50) NOT NULL UNIQUE);

CREATE TABLE movies (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title            VARCHAR(200) NOT NULL,
  description      TEXT,
  release_year     SMALLINT,
  duration_minutes SMALLINT CHECK (duration_minutes > 0),
  rating           NUMERIC(3,1) CHECK (rating BETWEEN 0 AND 10),
  poster_url       TEXT,
  backdrop_url     TEXT,
  cast_members     TEXT[] NOT NULL DEFAULT '{}',
  view_count       BIGINT NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_movies_title_trgm ON movies USING gin (lower(title) gin_trgm_ops);
CREATE INDEX idx_movies_created_at ON movies (created_at DESC);
CREATE INDEX idx_movies_view_count ON movies (view_count DESC);

CREATE TABLE movie_genres (
  movie_id UUID     NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
  genre_id SMALLINT NOT NULL REFERENCES genres(id),
  PRIMARY KEY (movie_id, genre_id)
);
CREATE INDEX idx_movie_genres_genre ON movie_genres (genre_id);

-- ===== Streaming metadata (files live in object storage, never in Postgres) =====
CREATE TABLE video_sources (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  movie_id   UUID NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
  protocol   VARCHAR(10) NOT NULL CHECK (protocol IN ('HLS','MP4')),
  quality    VARCHAR(10) NOT NULL,           -- e.g. 1080p, 720p, AUTO
  storage_key TEXT NOT NULL,                 -- S3 key or sample URL
  UNIQUE (movie_id, protocol, quality)
);
CREATE TABLE subtitle_tracks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  movie_id    UUID NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
  language    VARCHAR(10) NOT NULL,
  storage_key TEXT NOT NULL,
  UNIQUE (movie_id, language)
);

-- ===== Watch rooms =====
-- participant_count is a denormalised counter updated by one atomic conditional UPDATE (see CONCURRENCY notes).
CREATE TABLE watch_rooms (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_code          VARCHAR(12) NOT NULL UNIQUE,
  name                 VARCHAR(100) NOT NULL,
  movie_id             UUID NOT NULL REFERENCES movies(id),
  host_id              UUID NOT NULL REFERENCES users(id),
  visibility           VARCHAR(10) NOT NULL DEFAULT 'PUBLIC' CHECK (visibility IN ('PUBLIC','PRIVATE')),
  status               VARCHAR(10) NOT NULL DEFAULT 'CREATED' CHECK (status IN ('CREATED','ACTIVE','CLOSED','EXPIRED')),
  max_participants     SMALLINT NOT NULL DEFAULT 10 CHECK (max_participants BETWEEN 2 AND 100),
  participant_count    INT NOT NULL DEFAULT 0,
  allow_member_control BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at           TIMESTAMPTZ NOT NULL,
  closed_at            TIMESTAMPTZ,
  version              BIGINT NOT NULL DEFAULT 0,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_room_capacity CHECK (participant_count >= 0 AND participant_count <= max_participants)
);
CREATE INDEX idx_rooms_host ON watch_rooms (host_id);
CREATE INDEX idx_rooms_public_open ON watch_rooms (created_at DESC) WHERE visibility = 'PUBLIC' AND status IN ('CREATED','ACTIVE');

-- PK (room_id, user_id) makes join idempotent; a re-join clears left_at.
CREATE TABLE room_members (
  room_id   UUID NOT NULL REFERENCES watch_rooms(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES users(id),
  role      VARCHAR(10) NOT NULL CHECK (role IN ('HOST','MEMBER')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  left_at   TIMESTAMPTZ,
  PRIMARY KEY (room_id, user_id)
);
CREATE INDEX idx_room_members_user   ON room_members (user_id);
CREATE INDEX idx_room_members_active ON room_members (room_id) WHERE left_at IS NULL;

CREATE TABLE chat_messages (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id    UUID NOT NULL REFERENCES watch_rooms(id) ON DELETE CASCADE,
  sender_id  UUID REFERENCES users(id),              -- NULL for system messages
  type       VARCHAR(10) NOT NULL DEFAULT 'CHAT' CHECK (type IN ('CHAT','SYSTEM')),
  content    VARCHAR(1000) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_chat_room_id_desc ON chat_messages (room_id, id DESC);

-- Append-only log. seq is assigned by the server per room.
CREATE TABLE playback_events (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id         UUID NOT NULL REFERENCES watch_rooms(id) ON DELETE CASCADE,
  seq             BIGINT NOT NULL,
  event_type      VARCHAR(10) NOT NULL CHECK (event_type IN ('PLAY','PAUSE','SEEK')),
  position_ms     BIGINT NOT NULL CHECK (position_ms >= 0),
  playing         BOOLEAN NOT NULL,
  actor_id        UUID NOT NULL REFERENCES users(id),
  client_event_id UUID NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (room_id, seq),
  UNIQUE (room_id, client_event_id)                    -- duplicate-event protection
);

-- ===== User activity =====
CREATE TABLE watch_history (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  movie_id         UUID NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
  position_seconds INT NOT NULL DEFAULT 0,
  completed        BOOLEAN NOT NULL DEFAULT FALSE,
  last_watched_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, movie_id)
);
CREATE INDEX idx_history_user_recent ON watch_history (user_id, last_watched_at DESC);

CREATE TABLE user_favourites (
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  movie_id   UUID NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, movie_id)
);
