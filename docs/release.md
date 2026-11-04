# Release

yogurt's `meta.targets` are `docker` and `cloudflare`; both are built from
the same program, the appliance for a single host and the edge for guests.

## Docker appliance

`sayt release@docker --snapshot` builds `ghcr.io/bonisoft3/yogurt` (or
`${BAYT_DOCKER_REPOSITORY}`): PostgreSQL 18, PostgREST, Caddy and the auth
service under process-compose in one container, Caddy on `PORT` (8080),
`ORIGIN` the public base URL, `PGDATA` the volume that keeps a database
across upgrades, where `_pronto_migrations` runs the pending scripts in order
and skips the seed. The demo network's pictures are files in the image,
served at `/pictures/`. Without `--snapshot` the release tags the checkout and
pushes the image under the tag's basename. As of v0.3.0 the appliance does
not bake: the platform's builder copied postgrest from a path the crud image
no longer has (fixed on the platform's branch), and the bake then copies
every dependency's tree from stages that carry none (on the platform's
pending list). The target stays declared and ships when the platform does.

## Cloudflare

`sayt release@cloudflare --snapshot` builds `dist/cloudflare` in about ten
seconds, a dry run with no tag. Without `--snapshot` it mints
`apps/yogurt/vX.Y.Z` on HEAD with git-cliff (the tag is not pushed), then
publishes the edge with wrangler, which must be logged in on the machine:
the worker, the custom domain route for yogurt.bonisoft3.com, the database
load (the demo network, about forty megabytes, a minute), and the JWT secret
kept in `dist/.jwt-secret` so sessions survive a publish. The edge keeps a
ledger of the migration scripts it ran with their digests; a release whose
emitted scripts differ from the ledger's is refused and rolled back, so pass
`--reset` whenever a migration changed since the last publish, which drops
and reloads the edge's data. The program's migration list must be in the
alphabetical order the scripts run in.

`sayt verify@cloudflare` sweeps every route of the live site and runs the
browser journeys of `tests/verify.ts`: a guest signs in at the door, every
screen is visited at a route built from the demo network's own rows, the
guest strip at phone width is one line, a save says "salvo", and a rating
goes through the chips on a friend made for the run. The journeys write only
rows under guests they mint.

[[../journal.html|Journal]] · [[../ir.html|Application design]]
