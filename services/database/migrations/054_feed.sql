-- 024 — novidades (ir decision-news): one feed row per thing a person did
-- that is public, written by the cluster as it happens and removed with its
-- source, read by friends alone. The scrap and the testimonial triggers are
-- definers (a testimonial is published by 015's definer, whose insert fires
-- this one; the scrap's writer may read scraps anyway); the membership one
-- too, for one shape. The policy 006 emitted for a public table is restated
-- as reader-relative here; 002's standing grants are taken back. Every
-- public row from before this script gets its feed row once, in its own
-- time, the source's own created_at on every path: a testimonial's is the
-- day it was written, as its profile shows, never the moment of approval,
-- which only the subject's pending row holds and no public table shows. A
-- scrap's excerpt is eighty characters, a pointer beside the full row the
-- network panel shows; a testimonial's is a hundred and forty. Idempotent.
SET lock_timeout = '5s';
SET statement_timeout = '60s';
BEGIN;

REVOKE INSERT, UPDATE, DELETE ON feed FROM app_user, anon;
-- The shape per kind, and the order the panel reads in.
ALTER TABLE feed DROP CONSTRAINT IF EXISTS feed_kind_shape;
ALTER TABLE feed ADD CONSTRAINT feed_kind_shape CHECK (
  (kind = 'membership') = (about_community_id IS NOT NULL)
  AND (kind = 'membership') = (about_user_id IS NULL)
  AND (kind = 'membership') = (excerpt IS NULL)) NOT VALID;
DROP POLICY IF EXISTS feed_app_user_select ON feed;
CREATE POLICY feed_app_user_select ON feed FOR SELECT TO app_user
  USING (EXISTS (SELECT 1 FROM friendship f WHERE f.user_id = auth_uid() AND f.friend_id = feed.actor_id));

CREATE OR REPLACE FUNCTION feed_scrap() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO feed (at, actor_id, kind, about_user_id, excerpt, source_id)
    VALUES (NEW.created_at, NEW.author_id, 'scrap', NEW.owner_id, CASE WHEN char_length(NEW.body) > 80 THEN left(NEW.body, 79) || '…' ELSE NEW.body END, NEW.id);
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS feed_scrap ON scrap;
CREATE TRIGGER feed_scrap AFTER INSERT ON scrap FOR EACH ROW EXECUTE FUNCTION feed_scrap();

CREATE OR REPLACE FUNCTION feed_testimonial() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO feed (at, actor_id, kind, about_user_id, excerpt, source_id)
    VALUES (NEW.created_at, NEW.author_id, 'testimonial', NEW.subject_id, CASE WHEN char_length(NEW.body) > 140 THEN left(NEW.body, 139) || '…' ELSE NEW.body END, NEW.id);
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS feed_testimonial ON testimonial;
CREATE TRIGGER feed_testimonial AFTER INSERT ON testimonial FOR EACH ROW EXECUTE FUNCTION feed_testimonial();

CREATE OR REPLACE FUNCTION feed_membership() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO feed (at, actor_id, kind, about_community_id, source_id)
    VALUES (NEW.created_at, NEW.user_id, 'membership', NEW.community_id, NEW.id);
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS feed_membership ON membership;
CREATE TRIGGER feed_membership AFTER INSERT ON membership FOR EACH ROW EXECUTE FUNCTION feed_membership();

-- The row leaves with its source: a deleted scrap or testimonial, a leave.
CREATE OR REPLACE FUNCTION feed_forget() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM feed WHERE source_id = OLD.id AND kind = TG_ARGV[0];
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS feed_forget_scrap ON scrap;
CREATE TRIGGER feed_forget_scrap AFTER DELETE ON scrap FOR EACH ROW EXECUTE FUNCTION feed_forget('scrap');
DROP TRIGGER IF EXISTS feed_forget_testimonial ON testimonial;
CREATE TRIGGER feed_forget_testimonial AFTER DELETE ON testimonial FOR EACH ROW EXECUTE FUNCTION feed_forget('testimonial');
DROP TRIGGER IF EXISTS feed_forget_membership ON membership;
CREATE TRIGGER feed_forget_membership AFTER DELETE ON membership FOR EACH ROW EXECUTE FUNCTION feed_forget('membership');

REVOKE EXECUTE ON FUNCTION feed_scrap(), feed_testimonial(), feed_membership(), feed_forget() FROM PUBLIC, app_user, anon;

INSERT INTO feed (at, actor_id, kind, about_user_id, excerpt, source_id)
  SELECT s.created_at, s.author_id, 'scrap', s.owner_id, CASE WHEN char_length(s.body) > 80 THEN left(s.body, 79) || '…' ELSE s.body END, s.id FROM scrap s
  ON CONFLICT (kind, source_id) DO NOTHING;
INSERT INTO feed (at, actor_id, kind, about_user_id, excerpt, source_id)
  SELECT t.created_at, t.author_id, 'testimonial', t.subject_id, CASE WHEN char_length(t.body) > 140 THEN left(t.body, 139) || '…' ELSE t.body END, t.id FROM testimonial t
  ON CONFLICT (kind, source_id) DO NOTHING;
INSERT INTO feed (at, actor_id, kind, about_community_id, source_id)
  SELECT m.created_at, m.user_id, 'membership', m.community_id, m.id FROM membership m
  ON CONFLICT (kind, source_id) DO NOTHING;

-- The panel's order. Built plainly: the edge applies a script whole, inside
-- one transaction, where CONCURRENTLY cannot run, and the feed is a few
-- hundred rows when this index is first built.
-- squawk-ignore require-concurrent-index-creation
CREATE INDEX IF NOT EXISTS idx_feed_at ON feed (at DESC, id DESC);

COMMIT;

ALTER TABLE feed VALIDATE CONSTRAINT feed_kind_shape;
