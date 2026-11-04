---
pronto: alpha
name: yogurt
business: b2c social network, free, friends-of-friends; the product the web had before the feed
stage: mvp
team: studio
cluster: mecha
terminal: omnishell
loop: sayt
build: bayt
---

# yogurt

A social network the way 2004 remembers it. People have a profile with a
photo, who they are and what they love; friends leave public **scraps** on
each other's pages and write **testimonials** the subject approves before
anyone sees them; everyone can be a **fan** of somebody, and friends rate each other
trustworthy, cool and sexy; and **communities** — "Eu odeio acordar cedo", "Eu
amo pizza" — gather people around a joke or a passion, each with a forum of
topics and replies. The site is in Portuguese first, because that is where it
lived. It runs today at https://yogurt.bonisoft3.com, with the demo network
inside.

## Data

People, with a handle the site mints, a name, a picture, where they live, their
relationship status and four lines of interests, all of which they edit
themselves. Friend requests that become friendships when accepted. Scraps left
on a person's page by anyone signed in. Testimonials written by a friend about
a person, one per friend, shown once the subject says yes. Fans, and private
trustworthy/cool/sexy ratings between friends. Three rows the site keeps
itself from the others: a creator's membership, the smileys everyone sees
from three raters up, and what each person did that is public, read by
their friends. Communities with a name, a description and a
category, owned by whoever made them; memberships; forum topics and their
replies.

A fresh yogurt is never empty: it comes with a living network of fifteen
fictional people who are already friends, members, scrappers and fans of one
another, with communities and forum threads to walk into.

## Screens

- **Início** — the reader's own card (photo, name, counts of friends, fans and
  communities, their own smileys, the links to their profile and their form,
  how many testimonials await their word), their pending friend requests,
  their friends, fans and communities, what their friends did lately, the
  network's newest scraps, people to meet and the oldest communities.
- **Perfil** — a person's page: photo, name, where they live, relationship,
  about and interests, their counts and the smileys everyone sees, the
  controls to befriend and be a fan, a friend's private rating, a teaser of
  their scrapbook and of their testimonials, their friends and their
  communities; on one's own page, the way to the form.
- **Recados** — a person's scrapbook, newest first, with the box to leave one.
- **Depoimentos** — a person's testimonials; a friend writes one, the subject
  sees the ones waiting and approves or refuses each.
- **Amigos** — a person's full friends list; **Fãs** — their full fan list,
  behind the count; "ser fã" sits under every person tile.
- **Comunidades** — browse by category or search, and start a new one.
- **Comunidade** — a community's page: description, members, join or leave in
  one tap, its forum of topics; the owner edits it there.
- **Membros** — a community's full member list.
- **Tópico** — one forum thread and its replies; a member replies, and the
  opener deletes a thread nobody has answered.
- **Editar perfil** — the reader's own form.
- **Buscar** — people and communities by name, from the strip.

## Behavior

Coming in is one gesture at the terminal's door — a passkey or a guest click —
and the site names the reader by the name they choose. Everything a person does
about somebody else — a scrap, a testimonial, a request, a fan, a rating, a
reply — belongs to them and is refused to everybody else; what a person sees
about themselves that others cannot is their pending requests, their unapproved
testimonials and their own ratings. Everything else is public, as it was. An
undo takes two taps where getting back needs someone else's yes or destroys
writing, and one tap where the reader can redo it alone.

![[acceptance.md]]

## Sprints

One turn is one engineer-week; four turns and a wrap are a sprint. Each
sprint's wrap is an entry in the journal.

- **Sprint 1** (turns 1–4, done): the model, início, faces and the door, the
  profile with its arms.
- **Sprint 2** (turns 5–8, done): the scrapbook, friend requests live on both
  sides, the directory, the community page.
- **Sprint 3** (turns 9–12, done): the thread page, testimonials, the reader's
  own form with the owner's and the members page, the strip's search. The
  first Cloudflare release went out in turn 10.
- **Sprint 4** (turns 13–16, done): the debts paid in the mechanisms that
  owed them, the fans' page with "ser fã" under every person tile, the private
  rating with the cluster's smileys, and what your friends did lately on
  início. The second Cloudflare release went out at the sprint's opening,
  with `verify` against it.
- **Sprint 5**, one slice per turn:
  1. **Polish** (turn 17, done): "ver mais" past the twenty novidades, since
     a testimonial approved late sits under newer doings; "para você" when a
     doing is about the reader; the tile arms level when a name wraps, at the
     control height; the smileys readable; no empty interests panel; no
     "responder" on one's own scrap; the scrapbook frames' times as the
     format draws them.
  2. **Data** (done, turn 18): the demo network's faces and community
     pictures as the app's own files, content-addressed and served on every
     target, with their credits; a fifteenth person with a story, so a
     fresh yogurt reads as a place.
  3. **The driver** (done, turn 19): the acceptance ledger's unreachable
     clauses as an integrate check with five guest sessions (the forged
     writes, the races, the three-rater mean), the caps and plurals as screen
     tests over posed rows, the phone strip and the saved word as browser
     journeys in verify, the catalogues held to one text, and tap-to-set
     karma rows with their tests beside them. A "saved" word that does not
     depend on the tapped button keeping focus waits on the terminal's stamp,
     on the pending list, not on this app.
  4. **Shipping** (done, turn 20): README and docs, the third Cloudflare
     release (v0.3.0) with `verify` green against it, and the twentieth
     turn's wrap. The docker appliance was tried and does not bake: the
     platform's crud image moved its binary (fixed on a branch of its own)
     and the dependency tree copy from a scratch stage (on the platform's
     pending list); the target stays declared, and ships when the platform
     does.
  **After twenty turns**, what is open: the forged-write clauses as release
  journeys, since the ledger driver never meets the edge's crud; forward
  migrations with the loop check that freezes published scripts. Then the passkey half of sign-in, which
  waits for a virtual authenticator in the walk; the "você é fã" flash under
  a tile on a fresh tap; the edge's first draw after a write by another
  session, which can miss the row for seconds where the live update itself
  arrives on an open page; the panels that are not live by decision (a
  friend's scrap, a doing, a reply show on the next read, a request and an
  acceptance on the spot), which the brief should name panel by panel; a
  pasted picture link that does not resolve, which draws the browser's
  broken glyph where the letter should fall through; the door's three
  voices for an English browser (the dressed copy is Portuguese in CSS);
  and the docker appliance.
  The architecture the wrap recorded rides with the slices: the feed as a
  fan-out inbox under each reader's scope, which is both the edge's
  visibility and the scale answer (an index by actor and time does not
  bound a sparse reader's read, measured at two hundred thousand rows); the
  karma residual, accepted as the design's; forward migrations as the only
  way a published script moves, with a loop check that freezes the raw
  scripts behind the latest release tag; the forum's tables made live, or
  not; an entity order the compiler derives.

## Out of scope

Photo albums and uploads (pictures are links), private messages, notifications,
"who visited my profile", polls, moderation tools, a handle rename, and the
door, which is the platform's and comes first.
