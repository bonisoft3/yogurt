-- 022 — what the forum's writers own (ir decision-debts): a community's
-- creator is its first member, minted on the create path so no screen has to
-- remember; the opener deletes their own topic while nobody has replied, since
-- the replies are their writers' and a delete would cascade through them.
-- The creator's trigger runs as the caller: the owner is auth_uid() at create
-- time and 011 admits the membership. The guard runs as the caller too, the
-- doctrine's default: a reply is public, so the caller sees every one.
-- Communities from before this script get their owner's row here, once. The guard stays a trigger and never moves into the DELETE
-- policy: a trigger runs after the topic row is locked, so a reply committing
-- first is seen and refuses the delete, where a policy's NOT EXISTS is read
-- before the lock and would cascade that reply away. A reply is a reply,
-- the opener's own included. Idempotent.
SET lock_timeout = '5s';
SET statement_timeout = '60s';
BEGIN;

CREATE OR REPLACE FUNCTION community_creator_member() RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO membership (community_id, user_id) VALUES (NEW.id, NEW.owner_id)
    ON CONFLICT (community_id, user_id) DO NOTHING;
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS creator_member ON community;
CREATE TRIGGER creator_member AFTER INSERT ON community
  FOR EACH ROW EXECUTE FUNCTION community_creator_member();
INSERT INTO membership (community_id, user_id)
  SELECT id, owner_id FROM community
  ON CONFLICT (community_id, user_id) DO NOTHING;

-- VOLATILE (the default), and it has to stay so: the row is locked before a
-- BEFORE ROW trigger fires, and a volatile function takes its snapshot after
-- the lock, so under READ COMMITTED the EXISTS below sees a reply whose
-- transaction held the topic's key until it committed. STABLE would reuse the
-- statement's snapshot, taken before the lock, and a reply racing the delete
-- would be cascaded away. The same guard as a DELETE policy reads before the
-- lock and loses the race the same way.
CREATE OR REPLACE FUNCTION topic_delete_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  -- A cascade (a community or a person leaving) fires this one level deeper
  -- than a direct delete and keeps 005's meaning; only the opener's own
  -- delete is guarded.
  IF pg_trigger_depth() > 1 THEN
    RETURN OLD;
  END IF;
  IF EXISTS (SELECT 1 FROM post WHERE topic_id = OLD.id) THEN
    RAISE EXCEPTION 'a topic with replies stays' USING ERRCODE = 'check_violation';
  END IF;
  RETURN OLD;
END;
$$;
DROP TRIGGER IF EXISTS guard_topic_delete ON topic;
CREATE TRIGGER guard_topic_delete BEFORE DELETE ON topic
  FOR EACH ROW EXECUTE FUNCTION topic_delete_guard();

DROP POLICY IF EXISTS topic_app_user_delete ON topic;
CREATE POLICY topic_app_user_delete ON topic FOR DELETE TO app_user
  USING (author_id = auth_uid());

COMMIT;
