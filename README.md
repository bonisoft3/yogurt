# yogurt

An orkut, as pronto builds one: profiles with a picture and four lines of
interests, scraps left on each other's pages, testimonials the subject
approves, friends asked and answered, fans, the three smileys everyone sees,
communities with forums, and a feed of what one's friends did. Fifteen people
already live there, so a fresh yogurt reads as a place. The copy is pt-BR
first, with an English catalogue beside it, and every screen has its dark
twin.

It exercises the server-durable social shape: public tables with additive
owner-write policies, a Me row provisioned by a trigger, probes that decide
what a reader may do, mirrors that turn a request into a friendship and a
draft into a testimonial, and derived rows the cluster alone writes (the
smileys from three or more private ratings, the feed from a scrap, a
published testimonial or a membership). The boundaries that matter are
ownership, visibility, the friend rule, a replied topic's delete racing the
reply, and whether a count on a page is the count in the table.

Three instruments decide what a walk cannot: `tests/ledger.ts`, a build check
that runs at integrate against the runner's own stack with five guest
sessions; `tests/screens.test.ts` and `tests/catalogues.test.ts`, over
screens mounted on posed rows and over the two catalogues; and
`tests/verify.ts`, the browser journeys every release is verified with.

The [[ir.html|application design]] describes the implemented behavior, the
[[DESIGN.md|visual design]] the authored presentation, [[acceptance.md]] what
done looks like one check a line, [[brief.md]] where the work stands, and the
[[journal.html|journal]] each turn's evidence.

## Running it

`sayt <verb>` from the app's directory: `setup` mints the
local certificate, `generate && lint` compiles the program and gates the
spec, `build && test` runs the batteries, `integrate` runs the replay, the
visual gate and the ledger in containers, `launch` publishes the door at
https://localhost:20475. Launch wipes the database. Stop the launch stack
before `integrate`.

## Releasing it

`meta.targets` is `docker` and `cloudflare`. `release@docker --snapshot`
is meant to build the single-container appliance (PostgreSQL, PostgREST,
Caddy, the auth service under process-compose; `PORT`, `ORIGIN`, `PGDATA`
as knobs; the pictures served from `/pictures/`), and does not bake yet: the
platform's appliance has two breakers, recorded in [[docs/release]].
`release@cloudflare --snapshot` builds
`dist/cloudflare`; without `--snapshot` it tags the release, publishes the
edge at https://yogurt.bonisoft3.com and loads the demo network, and
`--reset` is required whenever an emitted migration changed since the last
publish. `verify@cloudflare` sweeps every route and runs the journeys against
the live site. See [[docs/release|the release doc]] for what each target needs.
