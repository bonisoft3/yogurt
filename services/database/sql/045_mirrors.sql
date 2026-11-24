-- Pending state is two private rows, one per party, kept equal by triggers
-- (ir decision-pending-private): Electric reads the WAL and never evaluates
-- RLS, so a row only one party may see has to be a row only that party's
-- scope carries. The asker writes friend_request_sent and the mirror writes
-- friend_request for the addressee; the writer writes testimonial_draft and
-- the mirror writes testimonial_pending for the subject. Setting `accepted`
-- mints both friendship edges (ir decision-friendship-mirror); setting
-- `approved` publishes the public testimonial row, and a conflict there
-- refuses the approval rather than losing the text. Deleting either half
-- removes the other. SECURITY DEFINER because the mirror row is never the
-- writer's own under RLS; the delete mirrors terminate because the second
-- pass finds nothing. Idempotent.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

CREATE OR REPLACE FUNCTION friend_request_mirror() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO friend_request (id, from_id, to_id, created_at)
    VALUES (NEW.id, NEW.from_id, NEW.to_id, NEW.created_at)
    ON CONFLICT DO NOTHING;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS mirror_friend_request ON friend_request_sent;
CREATE TRIGGER mirror_friend_request AFTER INSERT ON friend_request_sent
  FOR EACH ROW EXECUTE FUNCTION friend_request_mirror();

-- The pair unique is ordered, so nothing else stops a request to a friend or
-- a request crossing one already waiting the other way; both are refused as
-- a CHECK would be, so the asker's control paints its refusal line.
CREATE OR REPLACE FUNCTION friend_request_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM friendship WHERE user_id = NEW.from_id AND friend_id = NEW.to_id) THEN
    RAISE EXCEPTION 'already friends' USING ERRCODE = 'check_violation';
  END IF;
  IF EXISTS (SELECT 1 FROM friend_request_sent WHERE from_id = NEW.to_id AND to_id = NEW.from_id) THEN
    RAISE EXCEPTION 'a request the other way is waiting' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS guard_friend_request ON friend_request_sent;
CREATE TRIGGER guard_friend_request BEFORE INSERT ON friend_request_sent
  FOR EACH ROW EXECUTE FUNCTION friend_request_guard();

CREATE OR REPLACE FUNCTION friend_request_accept() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NEW.accepted AND NOT OLD.accepted THEN
    INSERT INTO friendship (user_id, friend_id) VALUES (NEW.from_id, NEW.to_id), (NEW.to_id, NEW.from_id)
      ON CONFLICT DO NOTHING;
    DELETE FROM friend_request_sent WHERE id = NEW.id
      OR (from_id = NEW.to_id AND to_id = NEW.from_id);
    DELETE FROM friend_request WHERE id = NEW.id
      OR (from_id = NEW.to_id AND to_id = NEW.from_id);
  END IF;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS accept_friend_request ON friend_request;
CREATE TRIGGER accept_friend_request AFTER UPDATE OF accepted ON friend_request
  FOR EACH ROW EXECUTE FUNCTION friend_request_accept();

CREATE OR REPLACE FUNCTION friend_request_withdraw() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM friend_request WHERE id = OLD.id;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS withdraw_friend_request ON friend_request_sent;
CREATE TRIGGER withdraw_friend_request AFTER DELETE ON friend_request_sent
  FOR EACH ROW EXECUTE FUNCTION friend_request_withdraw();

CREATE OR REPLACE FUNCTION friend_request_decline() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM friend_request_sent WHERE id = OLD.id;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS decline_friend_request ON friend_request;
CREATE TRIGGER decline_friend_request AFTER DELETE ON friend_request
  FOR EACH ROW EXECUTE FUNCTION friend_request_decline();

CREATE OR REPLACE FUNCTION friendship_unmirror() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM friendship WHERE user_id = OLD.friend_id AND friend_id = OLD.user_id;
  -- A testimonial is a friend's word: an unfriend takes the unapproved ones
  -- with it, both ways; the withdraw mirror takes each pending half.
  DELETE FROM testimonial_draft WHERE (author_id = OLD.user_id AND subject_id = OLD.friend_id)
     OR (author_id = OLD.friend_id AND subject_id = OLD.user_id);
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS unmirror_friendship ON friendship;
CREATE TRIGGER unmirror_friendship AFTER DELETE ON friendship
  FOR EACH ROW EXECUTE FUNCTION friendship_unmirror();

CREATE OR REPLACE FUNCTION testimonial_mirror() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO testimonial_pending (id, subject_id, author_id, body, created_at)
    VALUES (NEW.id, NEW.subject_id, NEW.author_id, NEW.body, NEW.created_at);
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS mirror_testimonial ON testimonial_draft;
CREATE TRIGGER mirror_testimonial AFTER INSERT ON testimonial_draft
  FOR EACH ROW EXECUTE FUNCTION testimonial_mirror();

CREATE OR REPLACE FUNCTION testimonial_publish() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NEW.approved AND NOT OLD.approved THEN
    INSERT INTO testimonial (id, subject_id, author_id, body, created_at)
      VALUES (NEW.id, NEW.subject_id, NEW.author_id, NEW.body, NEW.created_at);
    DELETE FROM testimonial_draft WHERE id = NEW.id;
    DELETE FROM testimonial_pending WHERE id = NEW.id;
  END IF;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS publish_testimonial ON testimonial_pending;
CREATE TRIGGER publish_testimonial AFTER UPDATE OF approved ON testimonial_pending
  FOR EACH ROW EXECUTE FUNCTION testimonial_publish();

CREATE OR REPLACE FUNCTION testimonial_withdraw() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM testimonial_pending WHERE id = OLD.id;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS withdraw_testimonial ON testimonial_draft;
CREATE TRIGGER withdraw_testimonial AFTER DELETE ON testimonial_draft
  FOR EACH ROW EXECUTE FUNCTION testimonial_withdraw();

CREATE OR REPLACE FUNCTION testimonial_discard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  DELETE FROM testimonial_draft WHERE id = OLD.id;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS discard_testimonial ON testimonial_pending;
CREATE TRIGGER discard_testimonial AFTER DELETE ON testimonial_pending
  FOR EACH ROW EXECUTE FUNCTION testimonial_discard();

COMMIT;
