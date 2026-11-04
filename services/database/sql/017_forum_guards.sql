-- A forum is its members' (ir decision-forum-membership): a topic or a reply
-- from someone outside the community is refused at the row, with the code the
-- screen already reads as a refusal. SECURITY DEFINER so the membership read
-- is not the writer's own RLS view. Idempotent.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

CREATE OR REPLACE FUNCTION topic_member_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM membership WHERE community_id = NEW.community_id AND user_id = NEW.author_id) THEN
    RAISE EXCEPTION 'only members post in a community''s forum' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS topic_member_guard ON topic;
CREATE TRIGGER topic_member_guard BEFORE INSERT ON topic
  FOR EACH ROW EXECUTE FUNCTION topic_member_guard();

CREATE OR REPLACE FUNCTION post_member_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM topic t JOIN membership m ON m.community_id = t.community_id
    WHERE t.id = NEW.topic_id AND m.user_id = NEW.author_id
  ) THEN
    RAISE EXCEPTION 'only members post in a community''s forum' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS post_member_guard ON post;
CREATE TRIGGER post_member_guard BEFORE INSERT ON post
  FOR EACH ROW EXECUTE FUNCTION post_member_guard();

COMMIT;
