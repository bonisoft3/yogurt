-- 023 — the smileys everyone sees (ir decision-karma): one karma_smiley row
-- per rated person, the rounded mean of every rater's trust, cool and sexy
-- and how many rated, kept by a trigger on karma. A definer, because karma
-- is private to each rater and the mean is over all of them; nothing a
-- browser can read names a rater, and the row exists from three raters up. The browser role reads the table and
-- writes nothing to it; 002's standing grants are taken back here. Every
-- person rated before this script gets their row once. The seed rates
-- before this guard exists; a guest rates only a friend. Idempotent.
SET lock_timeout = '5s';
SET statement_timeout = '60s';
BEGIN;

REVOKE INSERT, UPDATE, DELETE ON karma_smiley FROM app_user, anon;
ALTER TABLE karma_smiley DROP CONSTRAINT IF EXISTS karma_smiley_id_is_rated;
-- NOT VALID is squawk's ask (a validation scans under lock); validated
-- after the commit, in its own transaction, on a table of a dozen rows.
ALTER TABLE karma_smiley ADD CONSTRAINT karma_smiley_id_is_rated CHECK (id = rated_id) NOT VALID;
-- 002's standing INSERT and UPDATE are table-wide; the rater writes the
-- rated person and the three levels, then changes the levels and nothing
-- else (011's shape), and 006's policy is restated with its check.
REVOKE INSERT, UPDATE ON karma FROM app_user;
GRANT INSERT (id, rated_id, trust, cool, sexy) ON karma TO app_user;
GRANT UPDATE (trust, cool, sexy) ON karma TO app_user;
DROP POLICY IF EXISTS karma_app_user_update ON karma;
CREATE POLICY karma_app_user_update ON karma FOR UPDATE TO app_user
  USING (rater_id = auth_uid()) WITH CHECK (rater_id = auth_uid());

-- A rating is a friend's: the brief says so and only the screen said so.
-- Friendship rows are public, so the guard runs as the caller.
CREATE OR REPLACE FUNCTION karma_friend_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM friendship WHERE user_id = NEW.rater_id AND friend_id = NEW.rated_id) THEN
    RAISE EXCEPTION 'only a friend rates' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS guard_karma_friend ON karma;
CREATE TRIGGER guard_karma_friend BEFORE INSERT ON karma
  FOR EACH ROW EXECUTE FUNCTION karma_friend_guard();

CREATE OR REPLACE FUNCTION karma_smiley_refresh(r uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  -- Two raters committing together each recompute; the lock serializes the
  -- recomputation per rated person so the second sees the first's row.
  PERFORM pg_advisory_xact_lock(hashtext(r::text));
  INSERT INTO karma_smiley (id, rated_id, trust, cool, sexy, raters, updated_at)
    SELECT r, r, round(avg(trust))::int, round(avg(cool))::int, round(avg(sexy))::int, count(*)::int, now()
    FROM karma WHERE rated_id = r
    -- From three raters up: with one, the public mean is that friend's exact
    -- vote, with two, a rater can solve for the other (ir decision-karma).
    HAVING count(*) >= 3
  ON CONFLICT (id) DO UPDATE
    SET trust = EXCLUDED.trust, cool = EXCLUDED.cool, sexy = EXCLUDED.sexy,
        raters = EXCLUDED.raters, updated_at = EXCLUDED.updated_at;
  DELETE FROM karma_smiley WHERE id = r AND (SELECT count(*) FROM karma WHERE rated_id = r) < 3;
END;
$$;

CREATE OR REPLACE FUNCTION karma_smiley_trigger() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM karma_smiley_refresh(OLD.rated_id);
    RETURN NULL;
  END IF;
  PERFORM karma_smiley_refresh(NEW.rated_id);
  IF TG_OP = 'UPDATE' AND OLD.rated_id <> NEW.rated_id THEN
    PERFORM karma_smiley_refresh(OLD.rated_id);
  END IF;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS keep_karma_smiley ON karma;
CREATE TRIGGER keep_karma_smiley AFTER INSERT OR UPDATE OR DELETE ON karma
  FOR EACH ROW EXECUTE FUNCTION karma_smiley_trigger();

-- The refresh is the trigger's to call, not a browser's: PostgREST would
-- publish it at /rpc and EXECUTE goes to PUBLIC by default, which would let
-- anyone force a rewrite and a live push for any id. The default is taken
-- back for every function from here on.
REVOKE EXECUTE ON FUNCTION karma_smiley_refresh(uuid), karma_smiley_trigger(), karma_friend_guard() FROM PUBLIC, app_user, anon;
-- Global, not IN SCHEMA: PUBLIC's EXECUTE default is global, and a per-schema
-- default can only undo a per-schema grant.
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- A rating is a friend's, and leaves with the friendship: the unmirror in
-- 015 drops both edges, and this drops the pair's ratings with them. A
-- definer, since karma is private to each rater.
CREATE OR REPLACE FUNCTION karma_unfriend() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM karma WHERE rater_id = OLD.user_id AND rated_id = OLD.friend_id;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS unfriend_karma ON friendship;
CREATE TRIGGER unfriend_karma AFTER DELETE ON friendship
  FOR EACH ROW EXECUTE FUNCTION karma_unfriend();
REVOKE EXECUTE ON FUNCTION karma_unfriend() FROM PUBLIC, app_user, anon;

SELECT karma_smiley_refresh(rated_id) FROM (SELECT DISTINCT rated_id FROM karma) AS rated;

COMMIT;

ALTER TABLE karma_smiley VALIDATE CONSTRAINT karma_smiley_id_is_rated;
