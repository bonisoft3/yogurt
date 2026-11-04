-- 025 — the inbox (ir decision-news, sprint 5 wrap): one feed_item row per
-- reader and doing, fanned out from feed, the log 024 keeps. The edge serves
-- a public table's GET without a subject, so 024's reader-relative policy on
-- feed read nothing there; a row a reader may see must carry that reader's
-- scope, which feed_item's owner column does. A doing is fanned out to the
-- actor's friends as it lands; a friendship fans the new friend's hundred
-- newest doings into the reader's inbox, both directions, since the accept
-- trigger writes both rows; a doing leaves every inbox with its source, a
-- friendship's end takes the leaving friend's rows out of the reader's inbox.
-- The log itself is the cluster's alone now. Every existing pair gets its
-- rows once. Idempotent.
SET lock_timeout = '5s';
SET statement_timeout = '60s';
BEGIN;

REVOKE SELECT ON feed FROM app_user, anon;
DROP POLICY IF EXISTS feed_app_user_select ON feed;
REVOKE INSERT, UPDATE, DELETE ON feed_item FROM app_user, anon;

CREATE OR REPLACE FUNCTION feed_fanout() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO feed_item (reader_id, at, actor_id, kind, about_user_id, about_community_id, excerpt, source_id)
    SELECT f.user_id, NEW.at, NEW.actor_id, NEW.kind, NEW.about_user_id, NEW.about_community_id, NEW.excerpt, NEW.source_id
    FROM friendship f WHERE f.friend_id = NEW.actor_id
  ON CONFLICT (reader_id, kind, source_id) DO NOTHING;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS feed_fanout ON feed;
CREATE TRIGGER feed_fanout AFTER INSERT ON feed FOR EACH ROW EXECUTE FUNCTION feed_fanout();

CREATE OR REPLACE FUNCTION feed_item_forget() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM feed_item WHERE kind = OLD.kind AND source_id = OLD.source_id;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS feed_item_forget ON feed;
CREATE TRIGGER feed_item_forget AFTER DELETE ON feed FOR EACH ROW EXECUTE FUNCTION feed_item_forget();

-- A new friendship: the reader (user_id) receives the friend's newest hundred.
CREATE OR REPLACE FUNCTION feed_item_befriend() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO feed_item (reader_id, at, actor_id, kind, about_user_id, about_community_id, excerpt, source_id)
    SELECT NEW.user_id, d.at, d.actor_id, d.kind, d.about_user_id, d.about_community_id, d.excerpt, d.source_id
    FROM feed d WHERE d.actor_id = NEW.friend_id
    ORDER BY d.at DESC, d.id DESC LIMIT 100
  ON CONFLICT (reader_id, kind, source_id) DO NOTHING;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS feed_item_befriend ON friendship;
CREATE TRIGGER feed_item_befriend AFTER INSERT ON friendship FOR EACH ROW EXECUTE FUNCTION feed_item_befriend();

CREATE OR REPLACE FUNCTION feed_item_unfriend() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM feed_item WHERE reader_id = OLD.user_id AND actor_id = OLD.friend_id;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS feed_item_unfriend ON friendship;
CREATE TRIGGER feed_item_unfriend AFTER DELETE ON friendship FOR EACH ROW EXECUTE FUNCTION feed_item_unfriend();

REVOKE EXECUTE ON FUNCTION feed_fanout(), feed_item_forget(), feed_item_befriend(), feed_item_unfriend() FROM PUBLIC, app_user, anon;

INSERT INTO feed_item (reader_id, at, actor_id, kind, about_user_id, about_community_id, excerpt, source_id)
  SELECT f.user_id, d.at, d.actor_id, d.kind, d.about_user_id, d.about_community_id, d.excerpt, d.source_id
  FROM feed d JOIN friendship f ON f.friend_id = d.actor_id
  ON CONFLICT (reader_id, kind, source_id) DO NOTHING;

-- The panel's order, per reader. Built plainly: the edge applies a script
-- whole, inside one transaction, where CONCURRENTLY cannot run.
-- squawk-ignore require-concurrent-index-creation
CREATE INDEX IF NOT EXISTS idx_feed_item_reader_at ON feed_item (reader_id, at DESC, id DESC);

COMMIT;
