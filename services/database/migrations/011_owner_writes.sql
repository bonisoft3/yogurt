-- Owner writes over the public tables, and the column levers over every
-- insert-armed one (ir decision-public-read-owner-writes). #Access has no
-- "everyone reads, the owner writes" mode: public emits a SELECT arm and the
-- service catch-all and nothing else, so every form insert would be refused
-- as declared. The arms arrive here, additively, and the declared mode stays
-- the one the browser mirror believes. A row policy gates rows, never
-- columns, and 002 grants DML table-wide: the REVOKE/GRANT pairs keep
-- `created_at` the server's on every insert (a forged future stamp would pin a
-- scrap above everything forever) and keep each private half's one writable
-- column to the one word its owner may say. Idempotent.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

DROP POLICY IF EXISTS app_user_app_user_update ON app_user;
CREATE POLICY app_user_app_user_update ON app_user FOR UPDATE TO app_user
  USING (id = auth_uid()) WITH CHECK (id = auth_uid());
REVOKE UPDATE ON app_user FROM app_user;
GRANT UPDATE (display_name, photo_url, about, relationship, city, country, birthday, passions, music, movies, books)
  ON app_user TO app_user;

-- The asker's half is theirs to write (the emitted private quartet); the
-- addressee's half is the 015 mirror's alone, and its one word is accepted.
-- The sent half is written once and withdrawn by a delete: an UPDATE would
-- re-point a waiting request past the 015 guard and split the mirrored halves.
REVOKE INSERT, UPDATE ON friend_request_sent FROM app_user;
GRANT INSERT (id, to_id) ON friend_request_sent TO app_user;
REVOKE INSERT, UPDATE ON friend_request FROM app_user;
GRANT UPDATE (accepted) ON friend_request TO app_user;

-- No INSERT arm on friendship: every edge is the 015 trigger's. Either side
-- may end it from their own row; the trigger takes the mirror with it.
DROP POLICY IF EXISTS friendship_app_user_delete ON friendship;
CREATE POLICY friendship_app_user_delete ON friendship FOR DELETE TO app_user
  USING (user_id = auth_uid());

DROP POLICY IF EXISTS scrap_app_user_insert ON scrap;
CREATE POLICY scrap_app_user_insert ON scrap FOR INSERT TO app_user
  WITH CHECK (author_id = auth_uid());
-- The page's owner may sweep anything off it; the writer may take theirs back.
DROP POLICY IF EXISTS scrap_app_user_delete ON scrap;
CREATE POLICY scrap_app_user_delete ON scrap FOR DELETE TO app_user
  USING (author_id = auth_uid() OR owner_id = auth_uid());
REVOKE INSERT ON scrap FROM app_user;
GRANT INSERT (id, owner_id, author_id, body) ON scrap TO app_user;

-- The draft is its writer's (emitted quartet); the pending half is the
-- mirror's, its one word approved; the public row is the publish trigger's,
-- and author or subject may take it down.
-- A draft is written once: an UPDATE after the subject's pending copy exists
-- would let them approve text the writer no longer shows.
REVOKE INSERT, UPDATE ON testimonial_draft FROM app_user;
GRANT INSERT (id, subject_id, body) ON testimonial_draft TO app_user;
REVOKE INSERT, UPDATE ON testimonial_pending FROM app_user;
GRANT UPDATE (approved) ON testimonial_pending TO app_user;
REVOKE INSERT, UPDATE ON testimonial FROM app_user;
DROP POLICY IF EXISTS testimonial_app_user_delete ON testimonial;
CREATE POLICY testimonial_app_user_delete ON testimonial FOR DELETE TO app_user
  USING (author_id = auth_uid() OR subject_id = auth_uid());

DROP POLICY IF EXISTS fan_app_user_insert ON fan;
CREATE POLICY fan_app_user_insert ON fan FOR INSERT TO app_user
  WITH CHECK (fan_id = auth_uid());
DROP POLICY IF EXISTS fan_app_user_delete ON fan;
CREATE POLICY fan_app_user_delete ON fan FOR DELETE TO app_user
  USING (fan_id = auth_uid());
REVOKE INSERT ON fan FROM app_user;
GRANT INSERT (id, fan_id, idol_id) ON fan TO app_user;

DROP POLICY IF EXISTS community_app_user_insert ON community;
CREATE POLICY community_app_user_insert ON community FOR INSERT TO app_user
  WITH CHECK (owner_id = auth_uid());
DROP POLICY IF EXISTS community_app_user_update ON community;
CREATE POLICY community_app_user_update ON community FOR UPDATE TO app_user
  USING (owner_id = auth_uid()) WITH CHECK (owner_id = auth_uid());
-- No DELETE arm on community: a delete would cascade through every member's
-- topics and posts, and nothing deletes a community until moderation exists
-- (ir decision-community-page).
DROP POLICY IF EXISTS community_app_user_delete ON community;
REVOKE INSERT, UPDATE ON community FROM app_user;
GRANT INSERT (id, name, description, category, owner_id, photo_url) ON community TO app_user;
GRANT UPDATE (name, description, category, photo_url) ON community TO app_user;

DROP POLICY IF EXISTS membership_app_user_insert ON membership;
CREATE POLICY membership_app_user_insert ON membership FOR INSERT TO app_user
  WITH CHECK (user_id = auth_uid());
DROP POLICY IF EXISTS membership_app_user_delete ON membership;
CREATE POLICY membership_app_user_delete ON membership FOR DELETE TO app_user
  USING (user_id = auth_uid());
REVOKE INSERT ON membership FROM app_user;
GRANT INSERT (id, community_id, user_id) ON membership TO app_user;

-- A topic or a reply is its author's; 017 additionally asks that the author
-- be a member (ir decision-forum-membership).
DROP POLICY IF EXISTS topic_app_user_insert ON topic;
CREATE POLICY topic_app_user_insert ON topic FOR INSERT TO app_user
  WITH CHECK (author_id = auth_uid());
-- No DELETE arm on topic: a delete would cascade through every member's
-- replies, which are theirs, not the opener's; the opener deletes a topic
-- that has no replies through the guard a later turn adds, and nothing else
-- deletes one until moderation exists (ir decision-topic-page).
DROP POLICY IF EXISTS topic_app_user_delete ON topic;
REVOKE INSERT ON topic FROM app_user;
GRANT INSERT (id, community_id, author_id, title, body) ON topic TO app_user;
DROP POLICY IF EXISTS post_app_user_insert ON post;
CREATE POLICY post_app_user_insert ON post FOR INSERT TO app_user
  WITH CHECK (author_id = auth_uid());
DROP POLICY IF EXISTS post_app_user_delete ON post;
CREATE POLICY post_app_user_delete ON post FOR DELETE TO app_user
  USING (author_id = auth_uid());
REVOKE INSERT ON post FROM app_user;
GRANT INSERT (id, topic_id, author_id, body) ON post TO app_user;

COMMIT;
