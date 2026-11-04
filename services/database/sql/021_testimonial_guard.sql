-- A testimonial is a friend's word, one per person, as the original had it:
-- the draft insert is refused unless a friendship row runs from writer to
-- subject, and refused when the writer already has one about this person,
-- drafted or published (ir decision-testimonials). ERRCODE check_violation so
-- the client reads it as the row CHECK it stands in for. SECURITY INVOKER on
-- purpose: friendship and testimonial are public reads and the writer's own
-- drafts are theirs under RLS, and a definer here would answer a stranger's
-- hand-made insert with a sentence that reveals a private draft. The unique
-- pairs on both tables hold the one-per-person rule under concurrency; this
-- guard holds the friend rule and the cross-table half. Idempotent.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

CREATE OR REPLACE FUNCTION testimonial_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM friendship WHERE user_id = NEW.author_id AND friend_id = NEW.subject_id) THEN
    RAISE EXCEPTION 'only a friend writes a testimonial' USING ERRCODE = 'check_violation';
  END IF;
  IF EXISTS (SELECT 1 FROM testimonial WHERE author_id = NEW.author_id AND subject_id = NEW.subject_id) THEN
    RAISE EXCEPTION 'one testimonial per person' USING ERRCODE = 'check_violation';
  END IF;
  -- The client may choose the draft's id; one already published would make
  -- the approval's insert a no-op and the approval publish nothing.
  IF EXISTS (SELECT 1 FROM testimonial WHERE id = NEW.id) THEN
    RAISE EXCEPTION 'that id is already a testimonial' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS guard_testimonial ON testimonial_draft;
CREATE TRIGGER guard_testimonial BEFORE INSERT ON testimonial_draft
  FOR EACH ROW EXECUTE FUNCTION testimonial_guard();

COMMIT;
