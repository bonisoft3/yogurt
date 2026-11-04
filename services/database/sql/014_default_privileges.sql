-- 002 grants app_user and service DML on every table created in this schema
-- from then on. The app's own tables want it; nothing created afterwards does
-- — the auth service builds its passkey table here at first start, and the
-- standing default would hand every signed-in reader DML on it.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON TABLES FROM app_user, service;

COMMIT;
