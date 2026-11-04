---
preset: "press"
colors:
  primary: "#1C2B4A"
  secondary: "#4F5E7A"
  accent: "#C92F75"
  danger: "#C0392B"
  neutral: "#EAF0FB"
  surface: "#FFFFFF"
  border: "#C5D3EE"
  surface-muted: "#DAE5F8"
  link: "#2A5BB8"
  header: "#3B64C4"
  strip-ink: "#FFFFFF"
dark:
  primary: "#E6ECF7"
  secondary: "#9FB0CC"
  accent: "#F06AA5"
  danger: "#E57368"
  neutral: "#0F1626"
  surface: "#17213A"
  border: "#2C3A5C"
  surface-muted: "#1F2C4A"
  link: "#8FB3F5"
  header: "#2F4A85"
  strip-ink: "#E6ECF7"
rounded:
  sm: "4px"
  md: "8px"
  full: "999px"
spacing:
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "40px"
motion: {}
# Page-level widths: the page, a reading column, the portrait column.
measures:
  page: "980px"
  column: "720px"
  portrait: "240px"
shell:
  bg: "neutral"
  fg: "primary"
  rule: "border"
---

# Scrapbook

Identity for yogurt — the pale-blue boxes of 2004, with one pink spent only
where a person commits to another person. Chosen by three-direction comparison
(verdicts below); the token names are the schema contract, the values remain
the designer's to evolve.

## Overview

yogurt was boxes: a blue bar across the top, a white page, and content in
white panels whose titles sat on a light-blue band. The ground here is a pale
blue (`neutral`) rather than white, so the panels (`surface`) read as cards on
a page the way the originals did without a hairline on every side; the panel
title band is `surface-muted`; the top strip is `header` with `strip-ink` text, light in both appearances
(`shell/shared/chrome.css`, since the design block's `shell` paints the page
ground and the strip with one token), which is the one place the identity is loud. Links are `link`, a blue a
reader of that era recognizes before reading a word. The accent is yogurt's
pink and it is spent on commitment alone — add as friend, leave a scrap, write
a testimonial, join — never on navigation. The dark twin lowers value and keeps
hue: a navy page, lighter panels, the same pink.

## Comparison

Three directions were judged against the brief's início and perfil. The
oracle is the artifact itself — yogurt as it looked from 2004 to 2008 — so the
comparison asks which direction a reader who was there recognizes, not which
canvas is prettier; the storyboard frames in `ir.html` are the drawings.

1. **Scrapbook** (pale-blue page, white panels with blue title bands, blue
   links, pink commitments) — **chosen.** It is the artifact the brief names:
   a reader who was there recognizes the page in the first second, which is
   the whole product. The panel grammar also solves a real problem — a profile
   is a dozen unrelated lists, and bands keep them apart without a second
   color per list.
2. **New yogurt 2009** (white page, lavender gradients, rounded tabs, bigger
   type) — **rejected.** It is the redesign people left during. Gradients and
   lavender fight the one pink, and the page lost the box grammar that made a
   profile scannable.
3. **Feed-era social** (edge-to-edge cards, one column, an algorithmic
   stream) — **rejected.** It is the thing yogurt was not; a clone that reads as
   today's network has removed what it set out to clone.

**Contract:** the token *names* above are the schema contract (the program
reads `colors`, `dark`, `rounded`, `spacing`, `motion` and `shell` from this
file's frontmatter and restates none of them). Both appearances carry the same
token names — appearance is a token resolution, never a state
(accept-dual-appearance) — and the dark twin lowers value rather than shifting
hue (ir decision-design-identity).

## Colors

- **Primary / Secondary:** ink and metadata, both appearances. Secondary is
  for what the site says about a person — counts, dates, labels — never for
  what the person wrote.
- **Link:** every link into another page. A blue underline is how 2004 said
  "you can go there".
- **Header / Strip-ink:** the terminal's strip and its text, and nothing else;
  the ink is light in both appearances because the strip stays blue in both.
- **Accent:** commitment — add as friend, accept, leave a scrap, write a
  testimonial, be a fan, rate, join, reply, create a community — and the
  wordmark, the one place the name is said; never navigation.
- **Danger:** destruction and refusal — remove a friend, discard a
  testimonial, delete a scrap, a refused form.
- **Surface-muted:** panel title bands, chips and skeletons.
- **Border:** the panel outline and the rule under a band.

## Type

One family, system sans, as the original had: the identity is in the boxes,
not in the type. Five roles: a page title at `--type-title`, a panel band and
a person's name at `--type-subtitle` weight 700, body at `--type-body`,
metadata at `--type-caption`, chips at `--type-label`.

## Geometry

`rounded.sm` on controls and panel corners, `rounded.md` on a profile
picture, `rounded.full` on a chip. Panels pad `spacing.md`; the page gutters
are `spacing.lg`; panels sit `spacing.md` apart.

## Components

- **Panel:** fill `surface`, border `border`, `rounded.sm`; its band fills
  `surface-muted`, text `primary` weight 700, padded `spacing.sm` `spacing.md`.
- **Person tile:** a picture `rounded.md` over a name in `link`, the handle
  under it in `secondary`.
- **Primary button:** fill `accent`, text `surface`, `rounded.sm`.
- **Outline button:** fill `surface`, text `secondary`, border `border`.
- **Chip:** fill `surface-muted`, text `secondary`, `rounded.full`.
- **Text input:** fill `surface`, text `primary`, border `border`, `rounded.sm`.
- **Level chip:** an outline button holding a radio; chosen, fill `accent`,
  text `surface`. Four to a row, one row a smiley (Tap to set).

## Do's and Don'ts

- Do keep every list of people the same tile wherever it appears.
- Do give every panel a band with a title and, where it has one, a count.
- Do keep the pink for commitment; a blue link is how a reader moves.
- Don't tint a panel; the band carries the title, the panel carries the rows.
- Don't animate longer than 300ms.

## Frames before code

Every new panel or control is drawn in the storyboard before it is built, in
four states at least: populated, empty (the panel's own sentence), its dark
twin, and refused where it carries a form. Three turns of sprint 2 shipped a
panel the prose promised and no frame drew — the teaser, the requests panel,
the join refusal — and each was found by a seat after the fact. A frame is
the cheapest review there is.

## Undo in two taps, or one

An undo takes two taps — a summary that arms it, a red button that commits —
when getting back needs someone else's yes (unfriend) or when writing is
destroyed (apagar). It takes one tap when the reader can redo it alone
(deixar de ser fã, cancelar pedido, sair da comunidade, since rejoining is
free; undoing a rating is one tap, since the three levels are the reader's to
enter again). Refusing is not undoing: a declined request destroys nothing and the
asker may ask again, so "recusar" on a request is one tap, while "recusar…"
on a testimonial destroys the writer's text and takes two. The armed state
is a `details` element and is ephemeral by construction.

## Tap to set

A value the reader owns and can re-enter freely is set by a tap, not by a
form: the karma levels are a row of four chips a smiley, the chosen one
filled in `accent`, and the update form has no button, so the tap is the
save and the saved line stamps under the row. The first rating keeps
"avaliar", since it is three choices before one row exists and a tap on the
first would write nothing. A chip is a label over an off-screen radio: the
keyboard still walks the group, the focus ring sits on the chip, and the
terminal's buttonless-form rule turns a change into the write, so an arrow
key walking a group writes at every step, which is what tap-to-set means
and costs one small row each. Selects are
for lists too long to lay out (a category, a relationship); four levels are
not.

## The door

The terminal's gate, styled as a split, the way roda's is: the left 55% in
`header` blue, the right the pale ground. On the blue side the letter mark
and the wordmark in pink at the top, then the question — *quem você
conhece?* — at 44px and 600 in `strip-ink`, and a line under it on what
yogurt is and who is already inside; those words are the page's own, one set
per language, since no catalogue reaches the gate. On the ground side the
form, 380px: a small-capitals *entrar*, a line, the passkey pill in `accent`
at 56px, and the guest as a text link in `secondary`. On a phone the blue
panel stacks over the form. Dark: the same split over the dark `header` and
`neutral`.

## Pictures

A person's picture is a link they supply (`photo_url`); the demo network's own are the app's static files under `pictures/`, content-addressed, one shape on every target. Either is shown `rounded.md`
at 72px on a tile and 160px on their page; a person with none wears their
letter disc, so a face and a letter are the two states of one box and never
a broken image. A community's picture is the same at 56px, square.
