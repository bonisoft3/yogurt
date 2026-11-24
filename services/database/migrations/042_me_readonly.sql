-- me is read-only to browsers (ir decision-me-row). Access is private on id,
-- so 006 emits the owner quartet; the three write arms go, because nothing
-- should write this table from a browser and a person deleting their own row
-- would lock themselves out of their own page. The SELECT arm stays: the row's
-- mere visibility is how every screen asks "is this mine?". Narrowing, so safe.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

DROP POLICY IF EXISTS me_app_user_insert ON me;
DROP POLICY IF EXISTS me_app_user_update ON me;
DROP POLICY IF EXISTS me_app_user_delete ON me;

COMMIT;
