-- The reader's own row, provisioned inside the auth service's own insert (ir
-- decision-me-row): a trigger rather than a pipeline because the row must
-- exist on the first paint after a one-click guest sign-in, and a CDC round
-- trip is seconds. AFTER INSERT because me.id REFERENCES app_user(id).
-- SECURITY DEFINER because 012 leaves me with no browser write arm. Idempotent:
-- initdb replays this on every fresh volume.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

CREATE OR REPLACE FUNCTION me_provision() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO me (id, handle) VALUES (NEW.id, NEW.handle) ON CONFLICT DO NOTHING;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS provision_me ON app_user;
CREATE TRIGGER provision_me
  AFTER INSERT ON app_user
  FOR EACH ROW EXECUTE FUNCTION me_provision();

COMMIT;
