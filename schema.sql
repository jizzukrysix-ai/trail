-- Vaultgram schema (SQLite / Cloudflare D1).
-- The Worker also applies this idempotently on first request, so this file is
-- documentation and an optional way to pre-provision a remote database:
--   wrangler d1 execute vaultgram --remote --file=./schema.sql

CREATE TABLE IF NOT EXISTS folders (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  emoji       TEXT,
  accent      TEXT,
  cover       TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS files (
  id          TEXT PRIMARY KEY,
  folder_id   TEXT,
  name        TEXT NOT NULL,
  description TEXT,
  mime        TEXT NOT NULL DEFAULT 'application/octet-stream',
  size        INTEGER NOT NULL DEFAULT 0,
  r2_key      TEXT,
  inline_text TEXT,
  thumb       TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  downloads   INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS files_folder_idx ON files (folder_id);

CREATE TABLE IF NOT EXISTS users (
  id         TEXT PRIMARY KEY,
  tg_id      TEXT UNIQUE,
  first_name TEXT NOT NULL,
  last_name  TEXT,
  username   TEXT,
  photo_url  TEXT,
  created_at INTEGER NOT NULL,
  last_seen  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  last_seen  INTEGER NOT NULL
);

-- One row per completed rewarded ad. Slots are 1..adsRequired, and the unique
-- index makes a slot impossible to claim twice for the same file + user.
CREATE TABLE IF NOT EXISTS ad_events (
  id         TEXT PRIMARY KEY,
  file_id    TEXT NOT NULL,
  user_id    TEXT NOT NULL,
  slot       INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS ad_events_unique ON ad_events (file_id, user_id, slot);

CREATE TABLE IF NOT EXISTS unlocks (
  file_id    TEXT NOT NULL,
  user_id    TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (file_id, user_id)
);

CREATE TABLE IF NOT EXISTS login_attempts (
  ip TEXT NOT NULL,
  ts INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
