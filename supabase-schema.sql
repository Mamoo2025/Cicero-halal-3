-- ╔══════════════════════════════════════════════════════════════╗
-- ║  CICERO HALAL — Schema commenti & segnalazioni private       ║
-- ║  Da eseguire una sola volta nel SQL Editor di Supabase        ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ────────────────────────────────────────────────────────────────
-- COMMENTS (pubblici, sugli spot)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comments (
  id          BIGSERIAL PRIMARY KEY,
  place_id    BIGINT NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  author      TEXT,
  body        TEXT NOT NULL CHECK (length(body) BETWEEN 1 AND 2000),
  rating      SMALLINT CHECK (rating BETWEEN 1 AND 5),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS comments_place_id_idx   ON comments(place_id);
CREATE INDEX IF NOT EXISTS comments_created_at_idx ON comments(created_at DESC);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- chiunque può leggere i commenti
DROP POLICY IF EXISTS "anon read comments" ON comments;
CREATE POLICY "anon read comments"
  ON comments FOR SELECT
  TO anon, authenticated
  USING (true);

-- chiunque può inserire un commento (con limiti)
DROP POLICY IF EXISTS "anon insert comments" ON comments;
CREATE POLICY "anon insert comments"
  ON comments FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    length(body) BETWEEN 1 AND 2000
    AND (author IS NULL OR length(author) <= 40)
  );

-- ────────────────────────────────────────────────────────────────
-- REPORTS (private — visibili solo al gestore via Supabase dashboard)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id             BIGSERIAL PRIMARY KEY,
  place_id       BIGINT REFERENCES places(id)   ON DELETE CASCADE,
  comment_id     BIGINT REFERENCES comments(id) ON DELETE CASCADE,
  reason         TEXT NOT NULL CHECK (length(reason) BETWEEN 1 AND 60),
  description    TEXT       CHECK (description    IS NULL OR length(description)    <= 2000),
  contact_email  TEXT       CHECK (contact_email  IS NULL OR length(contact_email)  <= 200),
  status         TEXT DEFAULT 'open',
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT report_has_target CHECK (place_id IS NOT NULL OR comment_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS reports_status_idx     ON reports(status);
CREATE INDEX IF NOT EXISTS reports_created_at_idx ON reports(created_at DESC);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- anon può SOLO inserire — NIENTE SELECT/UPDATE/DELETE.
-- Per leggere le segnalazioni vai su Supabase Dashboard → Table Editor → reports
-- (il dashboard usa la service_role, bypassa RLS).
DROP POLICY IF EXISTS "anon insert reports" ON reports;
CREATE POLICY "anon insert reports"
  ON reports FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);
