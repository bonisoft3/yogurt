// The machine rung: hand-compiled hop 2 from ir.html (pinned below). Nobody
// reviews this file; review happens at brief.md and ir.html. Every object's
// `ir` field back-references the ir.html element id it realizes.
@extern(embed)

package yogurt

import "list"
import "github.com/bonisoft3/pronto"

_designMd:   _ @embed(file="DESIGN.md", type=text)
_catalogues: _ @embed(glob="messages/*.json")
_pictures:   _ @embed(file="assets/manifest.json")

code: pronto.#App & {
	meta: name:        "yogurt"
	meta: description: "A social network the way 2004 remembers it: profiles, scraps, testimonials, friends, fans and communities with forums."
	meta: ir: sha256: ""
	meta: targets: ["docker", "cloudflare"]

	// The edge release lives at this host; the Worker takes it as a custom domain (publish-edge).
	meta: domain: "yogurt.bonisoft3.com"
	meta: i18n: {
		default: "pt-BR"
		locales: {
			"pt-BR": path: "pt-br"
			en: path:      "en"
		}
		catalogues: _catalogues
	}

	// The terminal owns the door (passkey or guest) and gates every screen;
	// the strip names the reader by the display name they chose, read live,
	// and leads to their own page (ir decision-auth-door).
	capabilities: auth: {
		required: true
		service:  "/auth"
		self: {
			route: "profile"
			name: {table: "app_user", column: "display_name"}
		}
		// A guest keeps a strip — their name, sign out, and the offer of a
		// passkey that keeps this identity (ir decision-terminal-chrome).
		promote: true
	}
	// No blob plane: a reader's picture is a link they paste (decision 14), and the
	// demo network's pictures are the app's own static files (decision 30).
	capabilities: blobs: false
	capabilities: resources: pictures: {
		kind:   "img"
		source: "https:"
		note:   "people and communities supply picture links; their hosts receive the image requests"
	}

	// Assembly SQL beyond the schema vocabulary: owner-write arms over the
	// public tables, the me row and its trigger, the request and testimonial
	// mirrors, the forum guards and the demo network (ir decision-public-read-owner-writes,
	// decision-me-row, decision-friendship-mirror, decision-pending-private,
	// decision-demo-network).
	state: rawMigrations: [
		{name: "011_owner_writes.sql", src: "services/database/sql/011_owner_writes.sql"},
		{name: "012_me_readonly.sql", src: "services/database/sql/012_me_readonly.sql"},
		{name: "013_me_provision.sql", src: "services/database/sql/013_me_provision.sql"},
		{name: "014_default_privileges.sql", src: "services/database/sql/014_default_privileges.sql"},
		{name: "015_mirrors.sql", src: "services/database/sql/015_mirrors.sql"},
		{name: "017_forum_guards.sql", src: "services/database/sql/017_forum_guards.sql"},
		{name: "020_demo_network.sql", src: "services/database/sql/020_demo_network.sql"},
		{name: "021_testimonial_guard.sql", src: "services/database/sql/021_testimonial_guard.sql"},
		{name: "022_forum_ownership.sql", src: "services/database/sql/022_forum_ownership.sql"},
		{name: "023_karma_smiley.sql", src: "services/database/sql/023_karma_smiley.sql"},
		{name: "024_feed.sql", src: "services/database/sql/024_feed.sql"},
		{name: "025_feed_inbox.sql", src: "services/database/sql/025_feed_inbox.sql"},
	]

	surface: design: (pronto.#DesignMd & {text: _designMd}).design

	state: entities: {
		AppUser: {
			id: "0x92e9617a3499ddef"
			table:      "app_user"
			durability: "server"
			// Everyone reads a profile; the owner alone writes it, through 011.
			access: {scope: "public"}
			fields: [
				// No default: the auth service supplies the id.
				{ordinal: 1, name: "id", type: "uuid", pk: true},
				// Server-generated, never typed; 011's column grant excludes it.
				{ordinal: 2, name: "handle", type: "string", unique: true, cel: "this.size() > 0"},
				{ordinal: 3, name: "display_name", type: "string", required: false, cel: "this.size() <= 60"},
				{ordinal: 4, name: "photo_url", type: "string", required: false, cel: "this.matches('^(https://|/pictures/[0-9a-f]{64}\\.(jpg|png|webp)$)') && this.size() <= 2048"},
				{ordinal: 5, name: "about", type: "string", required: false, cel: "this.size() <= 1000"},
				// A message key, so the reader's locale chooses the word.
				{ordinal: 6, name: "relationship", type: "string", default: "'rel_unsaid'", cel: "this in ['rel_unsaid', 'rel_single', 'rel_dating', 'rel_married', 'rel_open', 'rel_complicated']"},
				{ordinal: 7, name: "city", type: "string", required: false, cel: "this.size() <= 80"},
				{ordinal: 8, name: "country", type: "string", required: false, cel: "this.size() <= 60"},
				{ordinal: 9, name: "birthday", type: "date", required: false},
				{ordinal: 10, name: "passions", type: "string", required: false, cel: "this.size() <= 300"},
				{ordinal: 11, name: "music", type: "string", required: false, cel: "this.size() <= 300"},
				{ordinal: 12, name: "movies", type: "string", required: false, cel: "this.size() <= 300"},
				{ordinal: 13, name: "books", type: "string", required: false, cel: "this.size() <= 300"},
				{ordinal: 14, name: "created_at", type: "timestamp", default: "now()"},
				// What the strip's search matches on: the name and the username in one
				// column, so one ilike serves it on the server and on a posed fixture
				// alike; named so the local matcher does NOT fold accents, which the
				// server's ilike does not either (ir decision-search).
				{ordinal: 15, name: "search_text", type: "string", generated: "coalesce(display_name, '') || ' ' || handle"},
			]
		}
		Me: {
			id: "0xc9deaa990cf202e7"
			table:      "me"
			durability: "live"
			// One row, mine, provisioned by the 013 trigger inside the auth
			// service's own insert; its mere visibility is the ownership probe
			// (ir decision-me-row).
			access: {scope: "private", owner: "id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, ref: "app_user"},
				{ordinal: 2, name: "handle", type: "string", cel: "this.size() > 0"},
			]
		}
		FriendRequestSent: {
			id: "0xaaa2f719850c2eec"
			table:      "friend_request_sent"
			durability: "live"
			uniques: [{name: "uq_friend_request_sent_pair", cols: ["from_id", "to_id"]}]
			// The asker's half of a request. Private, so the sync path carries it to
			// the asker alone; 015 mirrors it into the addressee's inbox
			// (ir decision-pending-private).
			access: {scope: "private", owner: "from_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "from_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 3, name: "to_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.from_id != this.to_id"}
			indexes: [{on: "to_id"}]
		}
		FriendRequest: {
			id: "0xbd0cefd7711f6892"
			table:      "friend_request"
			durability: "live"
			uniques: [{name: "uq_friend_request_pair", cols: ["from_id", "to_id"]}]
			// The addressee's half, written only by the 015 mirror (011 revokes the
			// browser INSERT); setting `accepted` mints both friendship edges and
			// removes both halves (ir decision-friendship-mirror).
			access: {scope: "private", owner: "to_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true},
				{ordinal: 2, name: "from_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "to_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "accepted", type: "bool", default: "false"},
				{ordinal: 5, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.from_id != this.to_id"}
			indexes: [{on: "from_id"}]
		}
		Friendship: {
			id: "0xb39adcf3dbce73fd"
			table:      "friendship"
			durability: "live"
			uniques: [{name: "uq_friendship_pair", cols: ["user_id", "friend_id"]}]
			// A friends list is public, as it was. Two rows per friendship, one
			// per direction, so a list is one filter and never an OR.
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "user_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "friend_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.user_id != this.friend_id"}
			indexes: [{on: "friend_id"}]
		}
		Scrap: {
			id: "0x86e0ef84144f0a17"
			table:      "scrap"
			durability: "server"
			// Scrapbooks were public; that is half of what made them yogurt.
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				// Whose page it was left on.
				{ordinal: 2, name: "owner_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "author_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 4, name: "body", type: "string", cel: "this.trim().size() > 0 && this.size() <= 1000"},
				{ordinal: 5, name: "created_at", type: "timestamp", default: "now()"},
			]
			indexes: [{on: "owner_id"}, {on: "created_at"}]
		}
		TestimonialDraft: {
			id: "0xe64974d71dfe174c"
			table:      "testimonial_draft"
			uniques: [{name: "uq_testimonial_draft_pair", cols: ["author_id", "subject_id"]}]
			// Live, as the request halves are: the subject's pending copy is a
			// trigger's row, and the writer's page shows the approval the moment
			// it lands (ir decision-testimonials).
			durability: "live"
			// What one person wrote about another, before the subject has said
			// yes: private to its writer, mirrored by 015 into the subject's
			// pending list (ir decision-pending-private).
			access: {scope: "private", owner: "author_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "subject_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "author_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 4, name: "body", type: "string", cel: "this.trim().size() > 0 && this.size() <= 1500"},
				{ordinal: 5, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.subject_id != this.author_id"}
			indexes: [{on: "subject_id"}]
		}
		TestimonialPending: {
			id: "0x9682bb96df74eb95"
			table:      "testimonial_pending"
			// Live: a draft arrives on the subject's open page without a reload.
			durability: "live"
			// The subject's half: written only by the 015 mirror; the subject's
			// one write is `approved`, which publishes it, and a delete discards.
			access: {scope: "private", owner: "subject_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true},
				{ordinal: 2, name: "subject_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "author_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "body", type: "string", cel: "this.trim().size() > 0 && this.size() <= 1500"},
				{ordinal: 5, name: "approved", type: "bool", default: "false"},
				{ordinal: 6, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.subject_id != this.author_id"}
			indexes: [{on: "author_id"}]
		}
		Testimonial: {
			id: "0xa8502ee901bda55c"
			table:      "testimonial"
			uniques: [{name: "uq_testimonial_pair", cols: ["author_id", "subject_id"]}]
			// Live: the publish trigger mints the row, and both parties' open
			// pages must show it; a server-durable region re-reads only after
			// this client's own write.
			durability: "live"
			// Approved testimonials, and nothing else: every row arrives through
			// the 015 publish trigger, so a public row is an approved one by
			// construction; author or subject may remove it (011).
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true},
				{ordinal: 2, name: "subject_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "author_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "body", type: "string", cel: "this.trim().size() > 0 && this.size() <= 1500"},
				{ordinal: 5, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.subject_id != this.author_id"}
			indexes: [{on: "subject_id"}]
		}
		Fan: {
			id: "0x839fe523fab878af"
			table:      "fan"
			durability: "server"
			uniques: [{name: "uq_fan_pair", cols: ["fan_id", "idol_id"]}]
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "fan_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 3, name: "idol_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.fan_id != this.idol_id"}
			indexes: [{on: "idol_id"}]
		}
		Karma: {
			id: "0xc854cd2195559e5b"
			table:      "karma"
			durability: "server"
			uniques: [{name: "uq_karma_pair", cols: ["rater_id", "rated_id"]}]
			// Who rated whom is nobody's business but the rater's; the
			// smileys everyone sees are KarmaSmiley, kept by 023's trigger.
			access: {scope: "private", owner: "rater_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "rater_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 3, name: "rated_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "trust", type: "int32", cel: "this >= 0 && this <= 3"},
				{ordinal: 5, name: "cool", type: "int32", cel: "this >= 0 && this <= 3"},
				{ordinal: 6, name: "sexy", type: "int32", cel: "this >= 0 && this <= 3"},
				{ordinal: 7, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.rater_id != this.rated_id"}
			indexes: [{on: "rated_id"}]
		}
		KarmaSmiley: {
			id: "0xa609e50ebc12a3a8"
			table:      "karma_smiley"
			// Live, not server: its rows are born of a trigger, and a server
			// region re-reads only after its own client's write, so a rating
			// would not move the smileys without a reload (ir decision-karma).
			durability: "live"
			// The smileys everyone sees: one row per rated person, kept by 023's
			// trigger on karma as the cluster, never a browser; a browser only
			// reads it. id is the rated person's id. The *_key columns name the
			// message a screen draws for each level (the {msg[col]} idiom).
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true},
				{ordinal: 2, name: "rated_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "trust", type: "int32", cel: "this >= 0 && this <= 3"},
				{ordinal: 4, name: "cool", type: "int32", cel: "this >= 0 && this <= 3"},
				{ordinal: 5, name: "sexy", type: "int32", cel: "this >= 0 && this <= 3"},
				{ordinal: 6, name: "raters", type: "int32", cel: "this >= 3"},
				{ordinal: 7, name: "trust_key", type: "string", generated: "'trust_' || trust::text"},
				{ordinal: 8, name: "cool_key", type: "string", generated: "'cool_' || cool::text"},
				{ordinal: 9, name: "sexy_key", type: "string", generated: "'sexy_' || sexy::text"},
				{ordinal: 10, name: "updated_at", type: "timestamp", default: "now()"},
			]
			uniques: [{name: "uq_karma_smiley_rated", cols: ["rated_id"]}]
		}
		Feed: {
			id: "0x8641a6706a08c29e"
			table:      "feed"
			durability: "server"
			// What a person did, as the cluster writes it: 024's triggers add a row
			// for a scrap left, a testimonial published and a community joined, and
			// remove it with its source. The log nobody reads: 025 takes the
			// reader's select away and fans each row out into FeedItem, the inbox
			// the screens read (ir decision-news). Nothing a browser holds writes here.
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "at", type: "timestamp"},
				{ordinal: 3, name: "actor_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "kind", type: "string", cel: "this in ['scrap', 'testimonial', 'membership']"},
				{ordinal: 5, name: "kind_key", type: "string", generated: "'feed_' || kind"},
				{ordinal: 6, name: "about_user_id", type: "uuid", ref: "app_user", required: false},
				{ordinal: 7, name: "about_community_id", type: "uuid", ref: "community", required: false},
				{ordinal: 8, name: "excerpt", type: "string", required: false},
				{ordinal: 9, name: "source_id", type: "uuid"},
			]
			// A source id is the client's to choose on three tables, so the pair is
			// unique per kind; source_id alone let a draft minted with a scrap's id
			// never be approved (sprint 5 architect).
			uniques: [{name: "uq_feed_source", cols: ["kind", "source_id"]}]
			indexes: [{on: "actor_id"}]
		}
		FeedItem: {
			id: "0xdfb645e37c351c71"
			table:      "feed_item"
			durability: "server"
			// The inbox: one row per reader and doing, fanned out from Feed by
			// 025's triggers as a doing lands and as a friendship forms, removed
			// with the doing and with the friendship. Private under the reader's
			// own scope, which is the visibility the edge honours, where a
			// reader-relative policy on a public table read nothing (ir
			// decision-news, sprint 5 wrap). Nothing a browser holds writes here.
			access: {scope: "private", owner: "reader_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "reader_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "at", type: "timestamp"},
				{ordinal: 4, name: "actor_id", type: "uuid", ref: "app_user"},
				{ordinal: 5, name: "kind", type: "string", cel: "this in ['scrap', 'testimonial', 'membership']"},
				{ordinal: 6, name: "kind_key", type: "string", generated: "'feed_' || kind"},
				{ordinal: 7, name: "about_user_id", type: "uuid", ref: "app_user", required: false},
				{ordinal: 8, name: "about_community_id", type: "uuid", ref: "community", required: false},
				{ordinal: 9, name: "excerpt", type: "string", required: false},
				{ordinal: 10, name: "source_id", type: "uuid"},
			]
			uniques: [{name: "uq_feed_item", cols: ["reader_id", "kind", "source_id"]}]
			indexes: [{on: "reader_id"}, {on: "actor_id"}]
		}
		Community: {
			id: "0xbba29239871da5e8"
			table:      "community"
			durability: "server"
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "name", type: "string", cel: "this.trim().size() > 0 && this.size() <= 80"},
				{ordinal: 3, name: "description", type: "string", required: false, cel: "this.size() <= 1000"},
				// A message key, so the category reads in the reader's locale.
				{ordinal: 4, name: "category", type: "string", cel: "this in ['cat_humor', 'cat_music', 'cat_movies', 'cat_food', 'cat_tech', 'cat_sports', 'cat_travel', 'cat_cities', 'cat_school', 'cat_other']"},
				{ordinal: 5, name: "owner_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 6, name: "photo_url", type: "string", required: false, cel: "this.matches('^(https://|/pictures/[0-9a-f]{64}\\.(jpg|png|webp)$)') && this.size() <= 2048"},
				{ordinal: 7, name: "created_at", type: "timestamp", default: "now()"},
			]
			indexes: [{on: "category"}]
		}
		Membership: {
			id: "0xcabe3837ceaa14d4"
			table:      "membership"
			durability: "server"
			uniques: [{name: "uq_membership_pair", cols: ["community_id", "user_id"]}]
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "community_id", type: "uuid", ref: "community"},
				{ordinal: 3, name: "user_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 4, name: "created_at", type: "timestamp", default: "now()"},
			]
			indexes: [{on: "user_id"}]
		}
		// The search box as a row: one tab row, mine alone, whose q the results
		// region reads (ir decision-communities-screen).
		Search: {
			id: "0x9a29e939361b5a78"
			// The strip's search row: one tab row, mine alone, as the directory's.
			table:      "search"
			durability: "tab"
			fields: [
				{ordinal: 1, name: "id", type: "string", pk: true, cel: "this.size() <= 12"},
				{ordinal: 2, name: "q", type: "string", cel: "this.size() <= 80"},
			]
		}
		CommunitySearch: {
			id: "0x92992c6283823258"
			table:      "community_search"
			durability: "tab"
			fields: [
				{ordinal: 1, name: "id", type: "string", pk: true, cel: "this.size() <= 12"},
				{ordinal: 2, name: "q", type: "string", cel: "this.size() <= 80"},
			]
		}
		Topic: {
			id: "0xb6b6625bfd193b5a"
			table:      "topic"
			durability: "server"
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "community_id", type: "uuid", ref: "community"},
				{ordinal: 3, name: "author_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 4, name: "title", type: "string", cel: "this.trim().size() > 0 && this.size() <= 120"},
				{ordinal: 5, name: "body", type: "string", cel: "this.trim().size() > 0 && this.size() <= 4000"},
				{ordinal: 6, name: "created_at", type: "timestamp", default: "now()"},
			]
			indexes: [{on: "community_id"}]
		}
		Post: {
			id: "0x8027cea7fd8ad2b1"
			table:      "post"
			durability: "server"
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "topic_id", type: "uuid", ref: "topic"},
				{ordinal: 3, name: "author_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 4, name: "body", type: "string", cel: "this.trim().size() > 0 && this.size() <= 4000"},
				{ordinal: 5, name: "created_at", type: "timestamp", default: "now()"},
			]
			indexes: [{on: "topic_id"}]
		}
	}
	// Parents before children: a `ref` emits REFERENCES and Postgres needs the
	// target table first.
	state: entityOrder: ["AppUser", "Me", "FriendRequestSent", "FriendRequest", "Friendship", "Scrap", "TestimonialDraft", "TestimonialPending", "Testimonial", "Fan", "Karma", "KarmaSmiley", "Community", "Membership", "Feed", "FeedItem", "Topic", "Post", "CommunitySearch", "Search"]

	// No reduce anywhere yet: every surface is a read or a form.
	surface: handlers: {}

	surface: screens: {
		home: {
			title: "início"
			label: "nav_home"
			route: "/"
			ssr:   "spa"
			forms: [
				{
					id:     "accept-request-home"
					entity: "FriendRequest"
					action: "update"
					flow:   "accept-request-home"
					fields: [{name: "accepted", control: "hidden", value: "true"}]
				},
				{
					id:     "decline-request-home"
					entity: "FriendRequest"
					action: "delete"
					flow:   "decline-request-home"
					fields: []
				},
				{
					// "ser fã" under a tile: fan_id defaults to auth_uid(); the unique
					// pair refuses a second time and the invariant refuses myself.
					id:     "be-fan-home"
					entity: "Fan"
					action: "create"
					flow:   "be-fan-home"
					fields: [{name: "idol_id", control: "hidden", value: "{id}"}]
				},
			]
			states: ["loading", "fresh", "populated", "validation-error", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				first_load: {states: ["loading", "fresh"], accepts: ["accept-door", "accept-signin-home", "accept-people", "accept-demo-network", "accept-fresh-guest-panels", "accept-guest-strip-phone"]}
				driven: {states: ["loading", "fresh"], accepts: ["accept-driver"]}
				network: {states: ["loading", "populated"], accepts: ["accept-network-scraps", "accept-communities-rail", "accept-photos", "accept-plural-counts", "accept-faces-shipped"]}
				answer: {states: ["populated", "populated"], accepts: ["accept-pending-home", "accept-live-accept"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
				pending_count: {states: ["loading", "populated"], accepts: ["accept-pending-count"]}
				edit_link: {states: ["loading", "populated"], accepts: ["accept-edit-profile"]}
				fan_tile: {states: ["populated", "populated"], accepts: ["accept-fan-tile"]}
				fan_refused: {states: ["populated", "validation-error"], accepts: ["accept-fan-tile"]}
				my_fans: {states: ["loading", "populated"], accepts: ["accept-my-fans"]}
				news: {states: ["loading", "populated"], accepts: ["accept-news"]}
				news_you: {states: ["populated", "populated"], accepts: ["accept-news-you"]}
				tile_arms: {states: ["populated", "populated"], accepts: ["accept-tile-arms"]}
			}
		}
		profile: {
			title: "perfil"
			slug:  "slug_profile"
			route: "/perfil/:handle"
			ssr:   "spa"
			forms: [
				{
					// Inherits FriendRequestSent's row invariant, so one's own page
					// refuses (ir test-no-self-request); from_id defaults auth_uid().
					id:     "ask-friend"
					entity: "FriendRequestSent"
					action: "create"
					flow:   "ask-friend"
					fields: [{name: "to_id", control: "hidden", value: "{id}"}]
				},
				{
					// A filtered delete over my own private rows: RLS narrows, the
					// 015 mirror removes the addressee's half.
					id:     "withdraw-request"
					entity: "FriendRequestSent"
					action: "delete"
					filter: "to_id=eq.{id}"
					flow:   "withdraw-request"
					fields: []
				},
				{
					// Row-scoped, inside the inbox row: the addressee's one write.
					id:     "accept-request"
					entity: "FriendRequest"
					action: "update"
					flow:   "accept-request"
					fields: [{name: "accepted", control: "hidden", value: "true"}]
				},
				{
					id:     "decline-request"
					entity: "FriendRequest"
					action: "delete"
					flow:   "decline-request"
					fields: []
				},
				{
					// Row-scoped in my friendship probe: deletes my half, the 015 unmirror
					// takes theirs. A delete filtered on the person's id would resolve
					// against the public table and land on another friend's row.
					id:     "unfriend"
					entity: "Friendship"
					action: "delete"
					flow:   "unfriend"
					fields: []
				},
				{
					id:     "be-fan"
					entity: "Fan"
					action: "create"
					flow:   "be-fan"
					fields: [{name: "idol_id", control: "hidden", value: "{id}"}]
				},
				{
					// Row-scoped in my fan probe, for the same reason as unfriend.
					id:     "unfan"
					entity: "Fan"
					action: "delete"
					flow:   "unfan"
					fields: []
				},
				{
					// My rating of a friend, the first time: rater_id defaults to
					// auth_uid(); each level is a row of four radios (the control
					// vocabulary has no radio; select is its nearest word); the pair is
					// unique and the 021-style CHECK refuses myself.
					id:     "rate"
					entity: "Karma"
					action: "create"
					flow:   "rate"
					fields: [
						{name: "rated_id", control: "hidden", value: "{friend_id}"},
						{name: "trust", control: "select", required: true, options: ["karma_level_0", "karma_level_1", "karma_level_2", "karma_level_3"]},
						{name: "cool", control: "select", required: true, options: ["karma_level_0", "karma_level_1", "karma_level_2", "karma_level_3"]},
						{name: "sexy", control: "select", required: true, options: ["karma_level_0", "karma_level_1", "karma_level_2", "karma_level_3"]},
					]
				},
				{
					// Row-scoped in my own karma row for this friend; 023 lets the rater
					// change the three levels and nothing else.
					id:     "rate-again"
					entity: "Karma"
					action: "update"
					flow:   "rate-again"
					fields: [
						{name: "trust", control: "select", required: true, options: ["karma_level_0", "karma_level_1", "karma_level_2", "karma_level_3"]},
						{name: "cool", control: "select", required: true, options: ["karma_level_0", "karma_level_1", "karma_level_2", "karma_level_3"]},
						{name: "sexy", control: "select", required: true, options: ["karma_level_0", "karma_level_1", "karma_level_2", "karma_level_3"]},
					]
				},
				{
					// Row-scoped in my own karma row; one tap, since the levels are
					// re-enterable; the 023 trigger drops or recounts the smileys.
					id:     "unrate"
					entity: "Karma"
					action: "delete"
					flow:   "unrate"
					fields: []
				},
			]
			states: ["loading", "populated", "requested", "pending", "friends", "rated", "own-profile", "validation-error", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			// A reader bounces between two people.
			keep: 2
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-profile-page", "accept-photos", "accept-plural-counts"]}
				ask: {states: ["populated", "requested"], accepts: ["accept-add-friend"]}
				withdraw: {states: ["requested", "populated"], accepts: ["accept-add-friend"]}
				revisit_requested: {states: ["loading", "requested"], accepts: ["accept-add-friend"]}
				answer: {states: ["loading", "pending", "friends"], accepts: ["accept-answer-request", "accept-friends-state", "accept-live-accept"]}
				see_friends: {states: ["populated", "populated"], accepts: ["accept-friends-screen"]}
				decline: {states: ["pending", "populated"], accepts: ["accept-answer-request"]}
				unfriend: {states: ["friends", "populated"], accepts: ["accept-friends-state"]}
				smileys: {states: ["loading", "populated"], accepts: ["accept-smileys"]}
				rate: {states: ["friends", "rated"], accepts: ["accept-rate-friend", "accept-karma-rows"]}
				revisit_rated: {states: ["loading", "rated"], accepts: ["accept-rate-friend"]}
				rate_again: {states: ["rated", "rated"], accepts: ["accept-rate-friend", "accept-karma-rows"]}
				rate_refused: {states: ["friends", "validation-error"], accepts: ["accept-rate-friend"]}
				unrate: {states: ["rated", "friends"], accepts: ["accept-rate-friend"]}
				communities: {states: ["loading", "populated"], accepts: ["accept-profile-communities"]}
				own_edit: {states: ["loading", "own-profile"], accepts: ["accept-edit-profile"]}
				testimonials: {states: ["loading", "populated"], accepts: ["accept-testimonials-teaser"]}
				fan: {states: ["populated", "populated"], accepts: ["accept-be-fan"]}
				own_page: {states: ["loading", "own-profile"], accepts: ["accept-own-page", "accept-profile-unknown"]}
				refused: {states: ["populated", "validation-error"], accepts: ["accept-add-friend"]}
				unknown_handle: {states: ["loading", "empty"], accepts: ["accept-profile-unknown"]}
				teaser: {states: ["loading", "populated"], accepts: ["accept-scrap-teaser"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		scrapbook: {
			title: "recados"
			slug:  "slug_scrapbook"
			route: "/recados/:handle"
			ssr:   "spa"
			forms: [
				{
					// author_id defaults to auth_uid() and 011 grants no other value.
					id:     "leave-scrap"
					entity: "Scrap"
					action: "create"
					flow:   "leave-scrap"
					fields: [
						{name: "owner_id", control: "hidden", value: "{id}"},
						{name: "body", control: "textarea", required: true, maxLength: 1000},
					]
				},
				{
					// Row-scoped in the scrap's own row; 011 lets the writer or the
					// page's owner delete, and the row draws the control for them alone.
					id:     "delete-scrap"
					entity: "Scrap"
					action: "delete"
					flow:   "delete-scrap"
					fields: []
				},
			]
			states: ["loading", "populated", "blank", "empty", "validation-error", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-scrapbook", "accept-photos"]}
				leave: {states: ["populated", "populated"], accepts: ["accept-leave-scrap"]}
				first_scrap: {states: ["loading", "blank", "populated"], accepts: ["accept-leave-scrap"]}
				delete: {states: ["populated", "populated"], accepts: ["accept-delete-scrap"]}
				refused: {states: ["populated", "validation-error"], accepts: ["accept-leave-scrap"]}
				unknown_handle: {states: ["loading", "empty"], accepts: ["accept-profile-unknown"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		communities: {
			title: "comunidades"
			label: "nav_communities"
			slug:  "slug_communities"
			route: "/comunidades"
			ssr:   "spa"
			forms: [
				{
					id:     "search-communities"
					entity: "CommunitySearch"
					action: "upsert"
					flow:   "search-communities"
					fields: [
						{name: "id", control: "hidden", value: "the"},
						{name: "q", control: "text", maxLength: 80},
					]
				},
				{
					// owner_id defaults to auth_uid(); 011 grants no other value.
					id:     "create-community"
					entity: "Community"
					action: "create"
					flow:   "create-community"
					fields: [
						{name: "name", control: "text", required: true, maxLength: 80},
						{name: "category", control: "select", required: true, options: ["cat_humor", "cat_music", "cat_movies", "cat_food", "cat_tech", "cat_sports", "cat_travel", "cat_cities", "cat_school", "cat_other"]},
						{name: "description", control: "textarea", maxLength: 1000},
					]
				},
			]
			states: ["loading", "populated", "searching", "search-none", "validation-error", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				browse: {states: ["loading", "populated"], accepts: ["accept-communities-browse", "accept-photos"]}
				search: {states: ["populated", "searching"], accepts: ["accept-community-search"]}
				search_none: {states: ["searching", "search-none"], accepts: ["accept-community-search"]}
				create: {states: ["populated", "populated"], accepts: ["accept-create-community", "accept-creator-member"]}
				refused: {states: ["populated", "validation-error"], accepts: ["accept-create-community"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		community: {
			title: "comunidade"
			slug:  "slug_community"
			route: "/comunidade/:id"
			ssr:   "spa"
			forms: [
				{
					// user_id defaults to auth_uid(); 011 grants no other value.
					id:     "join-community"
					entity: "Membership"
					action: "create"
					flow:   "join-community"
					fields: [{name: "community_id", control: "hidden", value: "{id}"}]
				},
				{
					// Row-scoped in my membership probe's row; 011 lets me delete mine.
					id:     "leave-community"
					entity: "Membership"
					action: "delete"
					flow:   "leave-community"
					fields: []
				},
				{
					// Row-scoped in the community's own row; 011 lets its owner update
					// these columns and nobody else.
					id:     "edit-community"
					entity: "Community"
					action: "update"
					flow:   "edit-community"
					fields: [
						{name: "description", control: "textarea", maxLength: 1000},
						{name: "photo_url", control: "text", maxLength: 2048},
					]
				},
				{
					// author_id defaults to auth_uid(); the 017 guard refuses a non-member.
					id:     "new-topic"
					entity: "Topic"
					action: "create"
					flow:   "new-topic"
					fields: [
						{name: "community_id", control: "hidden", value: "{id}"},
						{name: "title", control: "text", required: true, maxLength: 120},
						{name: "body", control: "textarea", required: true, maxLength: 4000},
					]
				},
				{
					// "ser fã" under a tile: fan_id defaults to auth_uid(); the unique
					// pair refuses a second time and the invariant refuses myself.
					id:     "be-fan-community"
					entity: "Fan"
					action: "create"
					flow:   "be-fan-community"
					fields: [{name: "idol_id", control: "hidden", value: "{user_id}"}]
				},
			]
			states: ["loading", "populated", "member", "owner", "validation-error", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			keep: 2
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-community-page", "accept-photos"]}
				join: {states: ["populated", "member"], accepts: ["accept-join-leave"]}
				revisit_member: {states: ["loading", "member"], accepts: ["accept-join-leave"]}
				leave: {states: ["member", "populated"], accepts: ["accept-join-leave"]}
				as_owner: {states: ["loading", "owner"], accepts: ["accept-edit-community"]}
				edit: {states: ["owner", "owner"], accepts: ["accept-edit-community", "accept-saved-line"]}
				edit_refused: {states: ["owner", "validation-error"], accepts: ["accept-edit-community-refused"]}
				members: {states: ["populated", "populated"], accepts: ["accept-members-page"]}
				fan_tile: {states: ["populated", "populated"], accepts: ["accept-fan-tile"]}
				fan_refused: {states: ["populated", "validation-error"], accepts: ["accept-fan-tile"]}
				post: {states: ["member", "member"], accepts: ["accept-forum-topics"]}
				refused: {states: ["member", "validation-error"], accepts: ["accept-forum-topics"]}
				unknown_id: {states: ["loading", "empty"], accepts: ["accept-community-unknown"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		topic: {
			title: "tópico"
			// The route carries the community too, so the membership probe can read
			// through the me row on the route's params alone; only the first
			// segment translates, through the community's own slug.
			slug:  "slug_community"
			route: "/comunidade/:community/topico/:id"
			ssr:   "spa"
			forms: [
				{
					// author_id defaults to auth_uid(); the 017 guard refuses a non-member.
					id:     "reply"
					entity: "Post"
					action: "create"
					flow:   "reply"
					fields: [
						{name: "topic_id", control: "hidden", value: "{id}"},
						{name: "body", control: "textarea", required: true, maxLength: 4000},
					]
				},
				{
					// Row-scoped in the reply's own row; 011 lets its writer delete.
					id:     "delete-reply"
					entity: "Post"
					action: "delete"
					flow:   "delete-reply"
					fields: []
				},
				{
					// Row-scoped in the topic's own row; 022 lets its opener delete
					// while nobody has replied, and refuses otherwise.
					id:     "delete-topic"
					entity: "Topic"
					action: "delete"
					flow:   "delete-topic"
					fields: []
				},
			]
			states: ["loading", "populated", "member", "opener", "deleting", "validation-error", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			keep: 2
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-topic-page"]}
				outsider: {states: ["loading", "populated"], accepts: ["accept-reply-outsider"]}
				as_member: {states: ["loading", "member"], accepts: ["accept-reply"]}
				reply: {states: ["member", "member"], accepts: ["accept-reply"]}
				refused: {states: ["member", "validation-error"], accepts: ["accept-reply", "accept-reply-outsider"]}
				delete: {states: ["member", "deleting", "member"], accepts: ["accept-delete-reply"]}
				as_opener: {states: ["loading", "opener"], accepts: ["accept-delete-topic"]}
				delete_topic: {states: ["opener", "empty"], accepts: ["accept-delete-topic"]}
				unknown_id: {states: ["loading", "empty"], accepts: ["accept-topic-unknown"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		testimonials: {
			title: "depoimentos"
			slug:  "slug_testimonials"
			route: "/depoimentos/:handle"
			ssr:   "spa"
			forms: [
				{
					// author_id defaults to auth_uid(); 021 refuses a non-friend, a
					// second one about the same person, and 015 mirrors the pending copy.
					id:     "write-testimonial"
					entity: "TestimonialDraft"
					action: "create"
					flow:   "write-testimonial"
					fields: [
						{name: "subject_id", control: "hidden", value: "{id}"},
						{name: "body", control: "textarea", required: true, maxLength: 1500},
					]
				},
				{
					// Row-scoped in the writer's own waiting row; 015 removes the mirror.
					id:     "withdraw-testimonial"
					entity: "TestimonialDraft"
					action: "delete"
					flow:   "withdraw-testimonial"
					fields: []
				},
				{
					// The subject's one write: approved, which 015 publishes.
					id:     "approve-testimonial"
					entity: "TestimonialPending"
					action: "update"
					flow:   "approve-testimonial"
					fields: [{name: "approved", control: "checkbox", value: "true"}]
				},
				{
					// Row-scoped in the pending row; 015 removes the writer's half.
					id:     "discard-testimonial"
					entity: "TestimonialPending"
					action: "delete"
					flow:   "discard-testimonial"
					fields: []
				},
				{
					// Row-scoped in the approved row; 011 lets writer or subject.
					id:     "delete-testimonial"
					entity: "Testimonial"
					action: "delete"
					flow:   "delete-testimonial"
					fields: []
				},
			]
			states: ["loading", "populated", "friend", "awaiting", "own-page", "validation-error", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			keep: 2
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-testimonials-page"]}
				as_friend: {states: ["loading", "friend"], accepts: ["accept-write-testimonial"]}
				write: {states: ["friend", "awaiting"], accepts: ["accept-write-testimonial"]}
				withdraw: {states: ["awaiting", "friend"], accepts: ["accept-withdraw-testimonial"]}
				refused: {states: ["friend", "validation-error"], accepts: ["accept-write-refused"]}
				arrival: {states: ["loading", "own-page"], accepts: ["accept-approve-testimonial"]}
				approve: {states: ["own-page", "own-page"], accepts: ["accept-approve-testimonial"]}
				discard: {states: ["own-page", "own-page"], accepts: ["accept-discard-testimonial"]}
				delete: {states: ["own-page", "own-page"], accepts: ["accept-delete-testimonial"]}
				unknown_handle: {states: ["loading", "empty"], accepts: ["accept-profile-unknown"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		edit: {
			title: "editar perfil"
			slug:  "slug_edit"
			route: "/editar-perfil"
			ssr:   "spa"
			// Reached from início's card and the own-profile sentence, not from the strip.
			strip: false
			forms: [
				{
					// Row-scoped in my own app_user row, read through the me row;
					// 011 grants exactly these columns on one's own row.
					id:     "edit-profile"
					entity: "AppUser"
					action: "update"
					flow:   "edit-profile"
					fields: [
						{name: "display_name", control: "text", maxLength: 60},
						{name: "photo_url", control: "text", maxLength: 2048},
						{name: "about", control: "textarea", maxLength: 1000},
						{name: "relationship", control: "select", required: true, options: ["rel_unsaid", "rel_single", "rel_dating", "rel_married", "rel_open", "rel_complicated"]},
						{name: "city", control: "text", maxLength: 80},
						{name: "country", control: "text", maxLength: 60},
						{name: "birthday", control: "date"},
						{name: "passions", control: "text", maxLength: 300},
						{name: "music", control: "text", maxLength: 300},
						{name: "movies", control: "text", maxLength: 300},
						{name: "books", control: "text", maxLength: 300},
					]
				},
			]
			states: ["loading", "populated", "validation-error", "populated-dark"]
			// The markup names editing-text on every optional control: a cleared
			// control submits null, so an optional column stays unset and the
			// https rule never sees ""; generate derives the adapter list.
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-edit-profile"]}
				save: {states: ["populated", "populated"], accepts: ["accept-edit-profile", "accept-saved-line"]}
				refused: {states: ["populated", "validation-error"], accepts: ["accept-edit-refused"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		members: {
			title: "membros"
			slug:  "slug_members"
			route: "/membros/:id"
			ssr:   "spa"
			forms: [
				{
					// "ser fã" under a tile: fan_id defaults to auth_uid(); the unique
					// pair refuses a second time and the invariant refuses myself.
					id:     "be-fan-members"
					entity: "Fan"
					action: "create"
					flow:   "be-fan-members"
					fields: [{name: "idol_id", control: "hidden", value: "{user_id}"}]
				},
			]
			states: ["loading", "populated", "validation-error", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-members-page", "accept-photos"]}
				fan_tile: {states: ["populated", "populated"], accepts: ["accept-fan-tile"]}
				fan_refused: {states: ["populated", "validation-error"], accepts: ["accept-fan-tile"]}
				unknown_id: {states: ["loading", "empty"], accepts: ["accept-members-unknown"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		search: {
			title: "buscar"
			label: "nav_search"
			slug:  "slug_search"
			route: "/buscar"
			ssr:   "spa"
			forms: [
				{
					id:     "search"
					entity: "Search"
					action: "upsert"
					flow:   "do-search"
					fields: [
						{name: "id", control: "hidden", value: "the"},
						{name: "q", control: "text", maxLength: 80},
					]
				},
				{
					// "ser fã" under a tile: fan_id defaults to auth_uid(); the unique
					// pair refuses a second time and the invariant refuses myself.
					id:     "be-fan-search"
					entity: "Fan"
					action: "create"
					flow:   "be-fan-search"
					fields: [{name: "idol_id", control: "hidden", value: "{id}"}]
				},
			]
			states: ["loading", "populated", "searching", "search-none", "validation-error", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-search-blank"]}
				search: {states: ["populated", "searching"], accepts: ["accept-search-people", "accept-search-communities", "accept-search-case", "accept-photos"]}
				search_none: {states: ["searching", "search-none"], accepts: ["accept-search-none"]}
				fan_tile: {states: ["searching", "searching"], accepts: ["accept-fan-tile"]}
				fan_refused: {states: ["searching", "validation-error"], accepts: ["accept-fan-tile"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		friends: {
			title: "amigos"
			slug:  "slug_friends"
			route: "/amigos/:handle"
			ssr:   "spa"
			forms: [
				{
					// "ser fã" under a tile: fan_id defaults to auth_uid(); the unique
					// pair refuses a second time and the invariant refuses myself.
					id:     "be-fan-friends"
					entity: "Fan"
					action: "create"
					flow:   "be-fan-friends"
					fields: [{name: "idol_id", control: "hidden", value: "{friend_id}"}]
				},
			]
			states: ["loading", "populated", "validation-error", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-friends-screen", "accept-photos"]}
				fan_tile: {states: ["populated", "populated"], accepts: ["accept-fan-tile"]}
				fan_refused: {states: ["populated", "validation-error"], accepts: ["accept-fan-tile"]}
				unknown_handle: {states: ["loading", "empty"], accepts: ["accept-profile-unknown"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		credits: {
			title: "créditos"
			slug:  "slug_credits"
			route: "/creditos"
			ssr:   "spa"
			// Reached from the directory's foot; not in the strip. Static: the
			// pictures' authors and licenses, as the manifest records them.
			strip: false
			forms: []
			states: ["populated", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				visit: {states: ["populated", "populated"], accepts: ["accept-credits"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		news: {
			title: "novidades"
			slug:  "slug_news"
			route: "/novidades"
			ssr:   "spa"
			// Reached from início's panel; not in the strip.
			strip: false
			forms: []
			states: ["loading", "populated", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-news-page"]}
				no_friends: {states: ["loading", "empty"], accepts: ["accept-news-page"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		fans: {
			title: "fãs"
			slug:  "slug_fans"
			route: "/fas/:handle"
			ssr:   "spa"
			// Reached from the count on a profile and on início's card; not in the strip.
			strip: false
			forms: [
				{
					// "ser fã" under a tile: fan_id defaults to auth_uid(); the unique
					// pair refuses a second time and the invariant refuses myself.
					id:     "be-fan-fans"
					entity: "Fan"
					action: "create"
					flow:   "be-fan-fans"
					fields: [{name: "idol_id", control: "hidden", value: "{fan_id}"}]
				},
			]
			states: ["loading", "populated", "validation-error", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/yogurt.css"]
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-fans-screen", "accept-photos"]}
				fan_tile: {states: ["populated", "populated"], accepts: ["accept-fan-tile"]}
				fan_refused: {states: ["populated", "validation-error"], accepts: ["accept-fan-tile"]}
				unknown_handle: {states: ["loading", "empty"], accepts: ["accept-profile-unknown"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
	}

	surface: flows: {
		// data-of "auth" in the ir: the door is terminal chrome. Ends in a read:
		// home's own card under the fresh token.
		"sign-in": {of: "auth", entity: "AppUser", action: "navigate"}
		"ask-friend":       {of: "profile", entity: "FriendRequestSent", action: "create"}
		"withdraw-request": {of: "profile", entity: "FriendRequestSent", action: "delete"}
		"accept-request":   {of: "profile", entity: "FriendRequest", action: "update"}
		"decline-request":  {of: "profile", entity: "FriendRequest", action: "delete"}
		"unfriend":         {of: "profile", entity: "Friendship", action: "delete"}
		"be-fan":           {of: "profile", entity: "Fan", action: "create"}
		"unfan":            {of: "profile", entity: "Fan", action: "delete"}
		"rate":             {of: "profile", entity: "Karma", action: "create"}
		"rate-again":       {of: "profile", entity: "Karma", action: "update"}
		"unrate":           {of: "profile", entity: "Karma", action: "delete"}
		"be-fan-home":      {of: "home", entity: "Fan", action: "create"}
		"be-fan-search":    {of: "search", entity: "Fan", action: "create"}
		"be-fan-friends":   {of: "friends", entity: "Fan", action: "create"}
		"be-fan-fans":      {of: "fans", entity: "Fan", action: "create"}
		"be-fan-community": {of: "community", entity: "Fan", action: "create"}
		"be-fan-members":   {of: "members", entity: "Fan", action: "create"}
		"accept-request-home":  {of: "home", entity: "FriendRequest", action: "update"}
		"decline-request-home": {of: "home", entity: "FriendRequest", action: "delete"}
		"write-testimonial":    {of: "testimonials", entity: "TestimonialDraft", action: "create"}
		"withdraw-testimonial": {of: "testimonials", entity: "TestimonialDraft", action: "delete"}
		"approve-testimonial":  {of: "testimonials", entity: "TestimonialPending", action: "update"}
		"discard-testimonial":  {of: "testimonials", entity: "TestimonialPending", action: "delete"}
		"delete-testimonial":   {of: "testimonials", entity: "Testimonial", action: "delete"}
		"reply":            {of: "topic", entity: "Post", action: "create"}
		"delete-reply":     {of: "topic", entity: "Post", action: "delete"}
		"delete-topic":     {of: "topic", entity: "Topic", action: "delete"}
		"edit-profile":     {of: "edit", entity: "AppUser", action: "update"}
		"edit-community":   {of: "community", entity: "Community", action: "update"}
		"join-community":   {of: "community", entity: "Membership", action: "create"}
		"leave-community":  {of: "community", entity: "Membership", action: "delete"}
		"new-topic":        {of: "community", entity: "Topic", action: "create"}
		"do-search":         {of: "search", entity: "Search", action: "upsert"}
		"search-communities": {of: "communities", entity: "CommunitySearch", action: "upsert"}
		"create-community":   {of: "communities", entity: "Community", action: "create"}
		"leave-scrap":      {of: "scrapbook", entity: "Scrap", action: "create"}
		"delete-scrap":     {of: "scrapbook", entity: "Scrap", action: "delete"}
	}

	meta: tests: {
		"test-signin-home": {
			of:    "auth"
			says:  "A passkey or guest click yields a token whose bearer the network can name; the auth service inserts AppUser (id, handle) and the 013 trigger provisions Me in the same transaction, so início draws the reader's own card on its first paint; a passkey holder is named in the strip beside sign out, a guest offered a passkey there."
			given: {gesture: "guest"}
			when:  "signin"
			then:  "output.handle.size() > 0 && output.role == 'app_user' && output.me.id == output.user_id"
		}
		"test-me-scoped": {
			of:    "Me"
			says:  "The me read returns exactly one row under its own token and nothing under anybody else's, which is what lets an empty probe region mean 'not mine'; every browser write against it is refused because 012 drops the arms owned emits."
			given: {user_id: "aa000000-0000-4000-8000-000000000001", other_id: "aa000000-0000-4000-8000-000000000002"}
			when:  "query"
			then:  "output.mine.size() == 1 && output.mine[0].id == input.user_id && output.as_other_filtered_on_mine == []"
		}
		"test-people-order": {
			of:    "home"
			says:  "The people rail reads everyone, oldest member first, so the demo network's founders lead; the reader's own row is in the read and the Me probe inside their tile is what hides it, so the hidden claim is a DOM check (no visible tile carries the reader's handle), not a query clause."
			given: {people_seeded: 14}
			when:  "query"
			then:  "output.rows.size() >= input.people_seeded && range(output.rows.size() - 1).all(i, output.rows[i].created_at <= output.rows[i + 1].created_at) && output.visible_tiles.all(t, t.handle != output.reader.handle)"
		}
		"test-profile-page": {
			of:    "profile"
			says:  "A profile is one person's header, their about and interests, and exactly their friends: the friendship read is one filter on user_id, because the 015 mirror keeps two rows per pair."
			given: {handle: "mariana-costa", friends_seeded: 5, neighbour: "aline-barros", neighbour_friends_seeded: 3}
			when:  "query"
			then:  "output.header.size() == 1 && output.header[0].handle == input.handle && output.friends.size() == input.friends_seeded && output.friends.all(f, f.user_id == output.header[0].id) && output.neighbour_friends.size() == input.neighbour_friends_seeded"
		}
		"test-profile-unknown": {
			of:    "profile"
			says:  "A handle nobody carries resolves the header to the empty collection without erroring, and the screen says so instead of drawing a blank card."
			given: {handle: "ninguem"}
			when:  "query"
			then:  "output.header == [] && error == null"
		}
		"test-friendship-mirror": {
			of:    "Friendship"
			says:  "Accepting a request yields exactly two edges, one per direction, and removes both halves of the request in the same transaction; a browser insert into friendship is refused because no arm exists for it."
			given: {from_id: "aa000000-0000-4000-8000-000000000001", to_id: "aa000000-0000-4000-8000-000000000014"}
			when:  "update"
			then:  "output.edges_before == [] && output.edges.size() == 2 && output.edges.exists(e, e.user_id == input.from_id && e.friend_id == input.to_id) && output.edges.exists(e, e.user_id == input.to_id && e.friend_id == input.from_id) && output.sent == [] && output.inbox == [] && output.browser_insert.kind == 'rls_denied' && output.edges_after_one_delete == []"
		}
		"test-pending-private": {
			of:    "FriendRequest"
			says:  "A pending request and an unapproved testimonial reach exactly their two parties and nobody else, on the sync path as on the CRUD path: a third guest's shape over friend_request, friend_request_sent, testimonial_draft or testimonial_pending carries no row, because every such row is private to one party and the public testimonial table holds approved rows alone."
			given: {third: "aa000000-0000-4000-8000-000000000099"}
			when:  "sync"
			then:  "output.friend_request == [] && output.friend_request_sent == [] && output.testimonial_pending == [] && output.testimonial_draft == [] && output.testimonial.all(t, t.subject_id != input.third || true)"
		}
		"test-no-self-request": {
			of:    "FriendRequestSent"
			says:  "Asking to befriend oneself is refused at the table CHECK, so the control on one's own page cannot produce a row even if it is reached."
			given: {from_id: "aa000000-0000-4000-8000-000000000001", to_id: "aa000000-0000-4000-8000-000000000001"}
			when:  "create"
			then:  "error.kind == 'check_violation' && output == null"
		}
		"test-demo-network": {
			of:    "AppUser"
			says:  "A fresh database already holds a living network: fourteen people, every one of them with friends, communities with members and forum topics, scraps and approved testimonials between them — so a guest's first screen is never empty."
			given: {}
			when:  "query"
			then:  "output.people.size() >= 14 && output.people.all(p, output.friendships.exists(f, f.user_id == p.id)) && output.communities.size() >= 10 && output.scraps.size() >= 30"
		}
		"test-network-scraps": {
			of:    "home"
			says:  "The network's latest scraps are the newest eight across every page, newest first, each carrying its writer's and its page owner's handle through two embeds on the one table that has two foreign keys to app_user."
			given: {seeded: 47, cap: 8}
			when:  "query"
			then:  "output.size() == input.cap && range(output.size() - 1).all(i, output[i].created_at >= output[i + 1].created_at) && output.all(s, s.author.handle.size() > 0 && s.owner.handle.size() > 0 && s.author.handle != s.owner.handle)"
		}
		"test-communities-rail": {
			of:    "home"
			says:  "Every community is listed, oldest first, with its category word in the reader's language and a member count equal to an independent read of membership grouped by community; the count is a projection over rows the reader can see, so it is exact without a sink."
			given: {communities_seeded: 12, first: "Eu odeio acordar cedo", first_members: 8, counts_read: "/crud/membership?select=community_id grouped by community_id"}
			when:  "query"
			then:  "output.rail.size() == input.communities_seeded && output.rail[0].name == input.first && output.rail[0].members == input.first_members && range(output.rail.size() - 1).all(i, output.rail[i].created_at <= output.rail[i + 1].created_at) && output.rail.all(c, c.category_label.size() > 0 && c.members == output.counts[c.id])"
		}
		"test-fresh-guest-panels": {
			of:    "home"
			says:  "A fresh guest's own friends and communities regions resolve to the empty collection and draw exactly the shipped sentence, each naming where to start, while the network panels beside them are full; a seeded member's same regions are full and carry no sentence, so a filter that returned nothing for everyone would fail on the member. The terminal's state is populated for both; `fresh` is the storyboard's name for the guest's frame and must not render as the populated frame does."
			given: {guest: "fresh", member: "mariana-costa", member_friends: 5, member_communities: 6, friends_message: "my_friends_empty", communities_message: "my_communities_empty"}
			when:  "query"
			then:  "output.guest.my_friends == [] && output.guest.my_communities == [] && output.guest.my_friends_copy == output.messages[input.friends_message] && output.guest.my_communities_copy == output.messages[input.communities_message] && output.guest.network_scraps.size() > 0 && output.member.my_friends.size() == input.member_friends && output.member.my_communities.size() == input.member_communities && output.member.my_friends_copy == '' && output.frames.fresh != output.frames.populated"
		}
		"test-photo-states": {
			of:    "home"
			says:  "A face and a letter are the two states of one box: a person whose photo_url is a link binds it into the face's img, a person with none (the fresh guest) binds the binder's transparent pixel, a data: src that fetches nothing, and the disc shows exactly when the src is that pixel, with their handle's first letter; the two states are decided by the bound value, so a broken image can never be the second state."
			given: {with_photo: "mariana-costa", without_photo: "a fresh guest", community_with_photo: "Eu amo pizza", community_without_photo: "Eu falo sozinho"}
			when:  "query"
			then:  "output.with_photo.src_is_pixel == false && output.with_photo.disc_visible == false && output.without_photo.src_is_pixel == true && output.without_photo.disc_visible == true && output.without_photo.disc_text.startsWith(output.without_photo.handle[0:1]) && output.community_with_photo.src_is_pixel == false && output.community_with_photo.disc_visible == false && output.community_without_photo.src_is_pixel == true && output.community_without_photo.disc_visible == true"
		}
		"test-door": {
			of:    "auth"
			says:  "The gate is the terminal's markup dressed by the app: the intro names the app, the headline asks the question and the line says who is inside, in the page's language; both roads are offered, and one tap on the guest control yields a session and lands on início."
			given: {lang: "pt-BR"}
			when:  "signin"
			then:  "output.intro_name == 'yogurt' && output.headline == 'quem você conhece?' && output.line.size() > 0 && output.passkey_control_present == true && output.guest_click_lands == 'home' && output.session.user.guest == true"
		}
		"test-ask-friend": {
			of:    "FriendRequestSent"
			says:  "Asking inserts one private row taking its asker from the token; the 015 mirror writes the addressee's half in the same transaction, so the asker's probe fills at once and the addressee's inbox holds the request; asking twice is refused by the pair's unique, asking a friend or crossing a request already waiting the other way by the 015 guard, and withdrawing deletes both halves."
			given: {from_id: "aa000000-0000-4000-8000-000000000001", to_id: "aa000000-0000-4000-8000-000000000014"}
			when:  "create"
			then:  "output.sent.size() == 1 && output.sent[0].from_id == input.from_id && output.inbox.size() == 1 && output.inbox[0].id == output.sent[0].id && output.again.kind == 'unique_violation' && output.after_withdraw.sent == [] && output.after_withdraw.inbox == [] && output.to_friend.kind == 'check_violation' && output.crossing.kind == 'check_violation'"
		}
		"test-decline-request": {
			of:    "FriendRequest"
			says:  "Declining is the addressee deleting their half; the 015 mirror removes the asker's, so the asker's control returns to 'add as friend' without anyone being told why; a third person can neither see nor delete either half."
			given: {from_id: "aa000000-0000-4000-8000-000000000001", to_id: "aa000000-0000-4000-8000-000000000014", third: "aa000000-0000-4000-8000-000000000002"}
			when:  "delete"
			then:  "output.inbox == [] && output.sent == [] && output.third_read == [] && output.third_delete.kind == 'rls_denied'"
		}
		"test-fan-toggle": {
			of:    "Fan"
			says:  "Being a fan is one public row taking its fan from the token; the idol's count is a projection over the public rows and moves for the writer on the spot and for everyone else on their next read, Fan being server-durable until the fãs turn makes it live; a second row for the pair is refused by the unique, oneself as idol by the CHECK, and the row-scoped delete removes mine alone; the count before is read, not assumed, so the demo network may change."
			given: {fan_id: "aa000000-0000-4000-8000-000000000001", idol_id: "aa000000-0000-4000-8000-000000000011"}
			when:  "create"
			then:  "output.row.fan_id == input.fan_id && output.idol_count == output.idol_fans_before + 1 && output.again.kind == 'unique_violation' && output.self.kind == 'check_violation' && output.after_delete.idol_count == output.idol_fans_before"
		}
		"test-profile-arms": {
			of:    "profile"
			says:  "Exactly one friend arm is visible for every relation the reader can have with a person — none (add), asked (request sent), asked by (accept/decline), friends (undo) — and none at all on the reader's own page; the relation is read through the reader's own me row because friendship and fan rows are public, so a probe on the person's id alone would answer for everybody."
			given: {reader: "aa000000-0000-4000-8000-000000000001", none: "andre-carvalho", requested: "gustavo-ramos", pending: "aline-barros", friend: "rafael-lima", own: "mariana-costa"}
			when:  "query"
			then:  "output.none.visible_arms == ['ask-friend', 'be-fan'] && output.requested.visible_arms == ['withdraw-request', 'be-fan'] && output.pending.visible_arms == ['accept-request', 'decline-request', 'be-fan'] && output.friend.visible_arms == ['unfriend', 'unfan'] && output.friend.friends_count == output.none.friends_count + 1 && output.own.visible_arms == [] && output.own.note.size() > 0"
		}
		"test-scrapbook-order": {
			of:    "Scrap"
			says:  "A person's scrapbook is every public scrap whose owner is that person, newest first, each carrying when it was left and its writer's handle through the author embed, which is the writer's and not the owner's: in the demo network the two never coincide, so an embed on the wrong key would show the owner on every row; the count the profile shows is the same rows counted."
			given: {owner: "aa000000-0000-4000-8000-000000000001", owner_scraps: 5}
			when:  "query"
			then:  "output.rows.size() == input.owner_scraps && output.count == output.rows.size() && output.rows.all(s, s.owner_id == input.owner && s.author.handle.size() > 0 && s.author.handle != output.owner_handle && s.created_at.size() > 0) && range(output.rows.size() - 1).all(i, output.rows[i].created_at >= output.rows[i + 1].created_at)"
		}
		"test-leave-scrap": {
			of:    "Scrap"
			says:  "Leaving a scrap inserts one public row whose writer is the token's bearer and whose owner is the page, and the page's next read has it first; a blank body, a body of spaces alone or an over-long one is refused by the row CHECK, a forged writer by RLS, and nothing else about the row is the client's to say."
			given: {author: "aa000000-0000-4000-8000-000000000001", owner: "aa000000-0000-4000-8000-000000000002", body: "Saudade dos nossos sábados!"}
			when:  "create"
			then:  "output.row.author_id == input.author && output.row.owner_id == input.owner && output.row.body == input.body && output.after_count == output.before_count + 1 && output.after_rows[0].id == output.row.id && output.blank.kind == 'check_violation' && output.spaces.kind == 'check_violation' && output.long.kind == 'check_violation' && output.forged.kind == 'rls_denied'"
		}
		"test-delete-scrap": {
			of:    "Scrap"
			says:  "A scrap is deleted by its writer or by the owner of the page it is on, and by nobody else: the 011 policy is the OR of the two, so a third person's delete matches no policy and removes nothing; and the control is drawn for the same two readers alone, because each row's two Me probes are empty for everyone else."
			given: {author: "aa000000-0000-4000-8000-000000000001", owner: "aa000000-0000-4000-8000-000000000002", third: "aa000000-0000-4000-8000-000000000003"}
			when:  "delete"
			then:  "output.by_author.control_visible && output.by_author.gone && output.by_owner.control_visible && output.by_owner.gone && !output.by_third.control_visible && output.by_third.kind == 'rls_denied' && !output.by_third.gone"
		}
		"test-scrap-teaser": {
			of:    "profile"
			says:  "The profile's scraps panel is the scrapbook's newest three, in the scrapbook's order, with a count of all of them in the band's link and the foot's link to the box; a person with none gets the panel's own sentence and the same foot link, never a blank."
			given: {cap: 3, full: "mariana-costa", none: "dusk-cove-94"}
			when:  "query"
			then:  "output.full.teaser.size() == (output.full.total < input.cap ? output.full.total : input.cap) && output.full.link_count == output.full.total && output.full.leave_link.size() > 0 && range(output.full.teaser.size() - 1).all(i, output.full.teaser[i].created_at >= output.full.teaser[i + 1].created_at) && output.none.teaser.size() == 0 && output.none.empty_text.size() > 0 && output.none.leave_link.size() > 0"
		}
		"test-live-accept": {
			of:    "Friendship"
			says:  "An accept is seen by both parties without a reload: the request halves and the friendship are live, so the addressee's accept (their own write) empties their inbox and the trigger-born friendship rows reach both readers through the sync shape; each profile's arms move to friends and each friends count moves by one, on the page that was already open; a decline reaches the asker the same way, their control back to add as friend with no sentence, as the original allowed; a reverse pair that predates the guard is cleared by the accept, both halves."
			given: {asker: "aa000000-0000-4000-8000-000000000001", addressee: "aa000000-0000-4000-8000-000000000002"}
			when:  "update"
			then:  "output.addressee.before.visible_arms == ['accept-request', 'decline-request', 'be-fan'] && output.addressee.after.visible_arms == ['unfriend', 'unfan'] && !output.addressee.after.reloaded && output.asker.after.visible_arms == ['unfriend', 'unfan'] && !output.asker.after.reloaded && output.addressee.after.friends_count == output.addressee.before.friends_count + 1 && output.asker.after.friends_count == output.asker.before.friends_count + 1 && output.declined.asker.visible_arms == ['ask-friend', 'be-fan'] && !output.declined.asker.reloaded && output.declined.asker.note == '' && output.reverse_pair.after_accept.sent == [] && output.reverse_pair.after_accept.inbox == []"
		}
		"test-home-pending": {
			of:    "home"
			says:  "Início lists every request addressed to the reader — the private inbox half, mine alone — newest first with the asker's name, and each row's accept or decline removes it on the spot; a reader with none gets the panel's own sentence."
			given: {reader: "aa000000-0000-4000-8000-000000000002"}
			when:  "query"
			then:  "output.pending.size() == output.inbox_count && output.pending.all(r, r.from.handle.size() > 0 && r.to_id == input.reader) && output.after_accept.pending.size() == output.pending.size() - 1 && output.after_accept.friends_count == output.friends_count + 1 && output.after_decline.pending.size() == output.after_accept.pending.size() - 1 && output.none.empty_text.size() > 0"
		}
		"test-friends-screen": {
			of:    "friends"
			says:  "A person's friends page is every friendship row whose user is that person, each with the friend through the embed; the profile's amigos panel is the newest twelve of the same rows with the full count in its link; a handle nobody carries is the same sentence as the profile's."
			given: {person: "aa000000-0000-4000-8000-000000000001", cap: 12}
			when:  "query"
			then:  "output.rows.size() == output.count && output.rows.all(f, f.user_id == input.person && f.friend.handle.size() > 0) && output.profile.tiles.size() == (output.count < input.cap ? output.count : input.cap) && output.profile.link_count == output.count && output.unknown.empty_text.size() > 0"
		}
		"test-communities-browse": {
			of:    "Community"
			says:  "The comunidades page is ten category sections in one fixed order, each a public read filtered on its category word, so every community appears exactly once under its own category with its member count and its picture or its letter, and a category with no community draws no section; a directory with no community says so."
			given: {order: ["cat_humor", "cat_music", "cat_movies", "cat_food", "cat_tech", "cat_sports", "cat_travel", "cat_cities", "cat_school", "cat_other"]}
			when:  "query"
			then:  "output.drawn_total == output.total && output.sections.all(s, s.rows.size() > 0 && s.rows.all(c, c.category == s.category && c.members == c.membership_rows)) && output.sections.size() == output.categories_with_rows && output.order == input.order && output.sections.all(s, s.rows.all(c, c.has_picture ? c.photo_visible : c.disc_visible)) && output.empty_directory.sentence.size() > 0"
		}
		"test-community-search": {
			of:    "CommunitySearch"
			says:  "A search is one tab row, mine alone, whose q the results region reads as a case-folded contains on the name (ASCII case; accents are not folded, so the fixture carries none); a blank q draws no results panel at all, and a q that matches nothing gets the panel's own sentence."
			given: {q: "PIZZA"}
			when:  "upsert"
			then:  "output.hits.size() == output.expected && output.hits.all(c, c.name.lowerAscii().contains(input.q.lowerAscii())) && output.none.hits.size() == 0 && output.none.empty_text.size() > 0 && output.blank.panel_hidden"
		}
		"test-create-community": {
			of:    "Community"
			says:  "Creating inserts one public row whose owner is the token's bearer, with a name, one of the ten category words and a description; it is drawn under its category on the next read; a blank name or a word outside the ten is refused by the row CHECK, a forged owner by RLS; a second community with the same name is accepted, as the original accepted its thousand clones."
			given: {owner: "aa000000-0000-4000-8000-000000000001", name: "Eu amo pão de queijo", category: "cat_food"}
			when:  "create"
			then:  "output.row.owner_id == input.owner && output.row.category == input.category && output.row.name == input.name && output.in_section && output.after_count == output.before_count + 1 && output.blank_name.kind == 'check_violation' && output.bad_category.kind == 'check_violation' && output.forged_owner.kind == 'rls_denied' && output.duplicate_name.row.name == input.name"
		}
		"test-community-page": {
			of:    "Community"
			says:  "A community's page is its public row by the route's id with the owner read on their own key and the members counted over the public membership rows, the newest twelve of them drawn; an id nobody carries is the region's own sentence with the way back to the directory; every community name on início and the directory is a link here carrying the row's id."
			given: {id: "cc000000-0000-4000-8000-000000000001", name: "Eu odeio acordar cedo", cap: 12}
			when:  "query"
			then:  "output.page.name == input.name && output.page.category == output.row.category && output.page.owner_handle == output.owner.handle && output.page.member_count == output.membership_rows && output.members.size() == (output.membership_rows < input.cap ? output.membership_rows : input.cap) && output.unknown.empty_text.size() > 0 && output.unknown.back_route == 'communities' && output.links.all(l, l.route == 'community' && l.id == output.row.id)"
		}
		"test-join-leave": {
			of:    "Membership"
			says:  "Joining inserts one public membership row taking its user from the token; the count moves and my membership probe, read through my me row, flips the arm to leave, on this visit and the next; leaving is one tap, since rejoining is free; joining twice is refused by the pair's unique; leaving is a row-scoped delete of my own row and the arm flips back; a forged user is refused by RLS."
			given: {user: "aa000000-0000-4000-8000-000000000001", community: "cc000000-0000-4000-8000-000000000012"}
			when:  "create"
			then:  "output.joined.row.user_id == input.user && output.joined.row.community_id == input.community && output.joined.count == output.before_count + 1 && output.joined.visible_arms == ['leave-community'] && output.revisit.visible_arms == ['leave-community'] && output.again.kind == 'unique_violation' && output.left.taps == 1 && output.left.count == output.before_count && output.left.visible_arms == ['join-community'] && output.forged.kind == 'rls_denied'"
		}
		"test-forum-topics": {
			of:    "Topic"
			says:  "The forum is the community's topics newest first, each with its opener through the author embed and its replies counted over the public posts; a member's new topic lands first on the next read and the form is drawn for members alone; a non-member sees no form and the note, and the 017 guard refuses their insert as a CHECK would; a blank title and a blank body are each refused by the row CHECK."
			given: {community: "cc000000-0000-4000-8000-000000000001", member: "aa000000-0000-4000-8000-000000000001", outsider: "aa000000-0000-4000-8000-000000000014", title: "Alguém mais acorda às 11?"}
			when:  "create"
			then:  "output.topics.size() == output.topic_rows && range(output.topics.size() - 1).all(i, output.topics[i].created_at >= output.topics[i + 1].created_at) && output.topics.all(t, t.author.handle.size() > 0 && t.replies == t.post_rows) && output.member.posted.title == input.title && output.member.after[0].id == output.member.posted.id && output.member.form_visible && output.outsider.kind == 'check_violation' && !output.outsider.form_visible && output.outsider.note.size() > 0 && output.blank_title.kind == 'check_violation' && output.blank_body.kind == 'check_violation'"
		}
		"test-topic-page": {
			of:    "Topic"
			says:  "A topic's page is its public row by the route's id with its opener through the author embed, and its replies are the public posts on it oldest first, each with its writer through the embed, as many as the forum counted; an id nobody carries is the region's own sentence with the way back to the community; every topic title on a community's forum is a link here carrying the community's id and the topic's."
			given: {id: "dd000000-0000-4000-8000-000000000001"}
			when:  "query"
			then:  "output.page.title == output.row.title && output.page.opener_handle == output.author.handle && output.page.body == output.row.body && output.replies.size() == output.post_rows && range(output.replies.size() - 1).all(i, output.replies[i].created_at <= output.replies[i + 1].created_at) && output.replies.all(r, r.author.handle.size() > 0) && output.unknown.empty_text.size() > 0 && output.unknown.back_route == 'community' && output.links.all(l, l.route == 'topic' && l.id == output.row.id && l.community == output.row.community_id)"
		}
		"test-reply": {
			of:    "Post"
			says:  "A reply inserts one public row whose writer is the token's bearer and whose topic is the page; it lands last on the next read and the count moves; the box is drawn for members of the topic's community alone, read through the me row on the route's community, while the 017 guard refuses a non-member's insert as a CHECK would; a blank body or spaces alone are refused by the row CHECK, each refusal drawn under the box with the text kept; the outsider's forced insert saves nothing."
			given: {topic: "dd000000-0000-4000-8000-000000000001", member: "aa000000-0000-4000-8000-000000000001", outsider: "aa000000-0000-4000-8000-000000000014", body: "Meio-dia, e com orgulho.", spaces: "   "}
			when:  "create"
			then:  "output.member.posted.body == input.body && output.member.after[output.member.after.size() - 1].id == output.member.posted.id && output.member.count == output.before_count + 1 && output.member.form_visible && output.outsider.kind == 'check_violation' && output.outsider.saved == 0 && !output.outsider.form_visible && output.outsider.note.size() > 0 && output.blank.kind == 'check_violation' && output.blank.sentence_visible && output.spaces.kind == 'check_violation' && output.spaces.sentence_visible && output.spaces.kept == input.spaces"
		}
		"test-delete-reply": {
			of:    "Post"
			says:  "A reply is deleted by its writer alone, in two taps, the first of which deletes nothing; the control is drawn for the writer alone by a Me probe on author_id in the reply's row, and the 011 policy refuses anyone else."
			given: {author: "aa000000-0000-4000-8000-000000000001", other: "aa000000-0000-4000-8000-000000000003"}
			when:  "delete"
			then:  "output.by_author.control_visible && output.by_author.armed.count == output.by_author.count && output.by_author.gone && !output.by_other.control_visible && output.by_other.kind == 'rls_denied' && !output.by_other.gone"
		}
		"test-testimonials-page": {
			of:    "Testimonial"
			says:  "A person's depoimentos page is the public rows whose subject is the route's person, newest first, each writer read on their own key, as many as the band counts; the profile's panel teases the newest three with the count in a link to the page; a handle nobody carries is the same sentence as the profile's."
			given: {handle: "mariana-costa"}
			when:  "query"
			then:  "output.page.rows.size() == output.count && range(output.page.rows.size() - 1).all(i, output.page.rows[i].created_at >= output.page.rows[i + 1].created_at) && output.page.rows.all(r, r.author.handle.size() > 0 && r.subject_id == output.person.id) && output.teaser.size() == min(3, output.count) && output.teaser_link.route == 'testimonials' && output.teaser_link.count == output.count && output.unknown.empty_text.size() > 0"
		}
		"test-write-testimonial": {
			of:    "TestimonialDraft"
			says:  "A friend's write inserts one private draft whose writer is the token's bearer and whose subject is the page, and the 015 mirror gives the subject a pending copy with the same id; the public table does not move; the writer's page shows the draft under esperando aprovação with the box, drawn for friends alone through my friendship rows each probed on the page's person; the 021 guard refuses a non-friend and a second one about a person with an approved one as a CHECK would, the unique pair refuses a second draft, the invariant refuses oneself, and a blank body is refused by the row CHECK; the box is hidden for a writer whose approved one is on the page."
			given: {subject: "aa000000-0000-4000-8000-000000000001", friend: "aa000000-0000-4000-8000-000000000005", stranger: "aa000000-0000-4000-8000-000000000014", body: "A Mari me ensinou a gostar de segunda-feira."}
			when:  "create"
			then:  "output.friend.draft.subject_id == input.subject && output.friend.draft.author_id == input.friend && output.friend.pending_for_subject.id == output.friend.draft.id && output.friend.public_rows == output.public_before && output.friend.waiting_visible && output.friend.form_visible && output.stranger.kind == 'check_violation' && !output.stranger.form_visible && output.stranger.note.size() > 0 && output.blank.kind == 'check_violation' && output.blank.sentence_visible && output.second.kind == 'check_violation' && output.self.kind == 'check_violation' && output.done.kind == 'check_violation' && !output.done.form_visible && output.done.note.size() > 0 && output.twice.kind == 'unique_violation'"
		}
		"test-approve-testimonial": {
			of:    "TestimonialPending"
			says:  "A pending copy reaches the subject's open page without a reload; setting approved publishes the public row with the same id and removes both halves, and the public row reaches both parties' open pages live; a discard removes both halves and publishes nothing; the first tap of either arms and changes nothing."
			given: {pending: "de000000-0000-4000-8000-000000000018", subject: "aa000000-0000-4000-8000-000000000001", writer: "aa000000-0000-4000-8000-000000000013"}
			when:  "update"
			then:  "output.arrival.subject_saw_pending_live && output.approve.public.id == output.approve.pending.id && output.approve.draft_gone && output.approve.pending_gone && output.approve.subject_sees_public_live && output.approve.writer_sees_public_live && output.discard.public_rows == output.discard.public_before && output.discard.draft_gone && output.discard.pending_gone && output.armed.count == output.before_count"
		}
		"test-delete-testimonial": {
			of:    "Testimonial"
			says:  "An approved testimonial is deleted by its writer or its subject alone, in two taps; the control is drawn for those two by two Me probes in the row, and the 011 policy refuses anyone else."
			given: {testimonial: "de000000-0000-4000-8000-000000000001", author: "aa000000-0000-4000-8000-000000000002", subject: "aa000000-0000-4000-8000-000000000001", third: "aa000000-0000-4000-8000-000000000003"}
			when:  "delete"
			then:  "output.by_author.control_visible && output.by_author.gone && output.by_subject.control_visible && output.by_subject.gone && !output.by_third.control_visible && output.by_third.kind == 'rls_denied' && !output.by_third.gone"
		}
		"test-profile-communities": {
			of:    "Membership"
			says:  "A profile's comunidades panel is the person's memberships newest first, at most twelve, each the community's name as a link to its page by id with its picture or letter, and the band's count is all of them."
			given: {handle: "mariana-costa"}
			when:  "query"
			then:  "output.panel.size() == min(12, output.count) && range(output.panel.size() - 1).all(i, output.panel[i].created_at >= output.panel[i + 1].created_at) && output.panel.all(t, t.link.route == 'community' && t.link.id == t.community_id && t.name.size() > 0) && output.count_shown == output.count"
		}
		"test-pending-count": {
			of:    "TestimonialPending"
			says:  "Início's line counts the reader's own pending copies, is absent when none waits, links to the reader's own depoimentos page, and moves when a draft arrives, the table being live."
			given: {reader: "aa000000-0000-4000-8000-000000000001"}
			when:  "query"
			then:  "output.line.count == output.pending_rows && (output.pending_rows > 0 ? output.line.visible : !output.line.visible) && output.line.route == 'testimonials' && output.line.handle == output.me.handle && output.line.moved_live"
		}
		"test-edit-profile": {
			of:    "AppUser"
			says:  "The edit page reads my own row through the me row and fills every control from it; saving updates that row alone, within the columns 011 grants, and the profile and the strip show the new values on their next read; another person's row is refused by RLS, a photo link that is not https or a name over sixty characters by the row CHECK, each refusal painting its sentence; a cleared birthday saves as null."
			given: {me: "aa000000-0000-4000-8000-000000000001", other: "aa000000-0000-4000-8000-000000000002", display_name: "Mari Costa", about: "Designer de dia, DJ de sala de estar à noite.", relationship: "rel_single", birthday: "1986-03-14"}
			when:  "update"
			then:  "output.saved.row.id == output.me.id && output.saved.row.display_name == input.display_name && output.saved.row.about == input.about && output.saved.row.relationship == input.relationship && output.saved.row.birthday == input.birthday && output.saved.profile_shows && output.saved.strip_name == input.display_name && output.prefilled.all(f, f.value == f.column_value) && output.other.kind == 'rls_denied' && output.bad_photo.kind == 'check_violation' && output.bad_photo.sentence_visible && output.long_name.kind == 'check_violation' && output.blank_birthday.row.birthday == null && output.links.card == '/editar-perfil' && output.links.own_profile == '/editar-perfil'"
		}
		"test-edit-community": {
			of:    "Community"
			says:  "The community page draws the edit form for its owner alone, a Me probe on owner_id, filled from the row; saving updates description and photo link in place and the page shows them on its next read; a member's hand-made update is refused by RLS and a photo link that is not https by the row CHECK, each refusal painting its sentence."
			given: {community: "cc000000-0000-4000-8000-000000000001", owner: "aa000000-0000-4000-8000-000000000001", member: "aa000000-0000-4000-8000-000000000003", description: "Se fosse pra gente acordar cedo, o sol nasceria às dez. Ponto.", photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Alarm_clock.jpg/240px-Alarm_clock.jpg"}
			when:  "update"
			then:  "output.owner.form_visible && output.owner.saved.description == input.description && output.owner.saved.photo_url == input.photo_url && output.owner.page_shows && !output.member.form_visible && output.member.kind == 'rls_denied' && output.bad_photo.kind == 'check_violation' && output.bad_photo.sentence_visible"
		}
		"test-members-page": {
			of:    "Membership"
			says:  "A community's members page is every membership of it, newest first, each the person's tile linking to their profile, as many as the band counts; the page's count and the band's link on the community page lead here; an id nobody carries is the region's own sentence with the way back."
			given: {community: "cc000000-0000-4000-8000-000000000001"}
			when:  "query"
			then:  "output.page.tiles.size() == output.count && output.page.tiles.all(t, t.link.route == 'profile' && t.handle.size() > 0) && range(output.page.tiles.size() - 1).all(i, output.page.tiles[i].created_at >= output.page.tiles[i + 1].created_at) && output.band_link.route == 'members' && output.band_link.id == input.community && output.count_link.route == 'members' && output.unknown.empty_text.size() > 0 && output.unknown.back_route == 'community'"
		}
		"test-search": {
			of:    "Search"
			says:  "The strip's search is one tab row, mine alone, whose q two nested lists read as a case-folded contains: people on search_text, the generated column that is the display name and the handle in one, communities on the name, each hit a link to its page; a blank q draws no panel at all; a q that matches nothing gets each panel's own sentence."
			given: {q: "CA"}
			when:  "upsert"
			then:  "output.people.size() == output.expected_people && output.people.all(p, p.display_name.lowerAscii().contains(input.q.lowerAscii()) || p.handle.lowerAscii().contains(input.q.lowerAscii())) && output.people.all(p, p.link.route == 'profile' && p.link.handle == p.handle) && output.communities.size() == output.expected_communities && output.communities.all(c, c.name.lowerAscii().contains(input.q.lowerAscii()) && c.link.route == 'community' && c.link.id == c.id) && output.none.people.size() == 0 && output.none.communities.size() == 0 && output.none.people_text.size() > 0 && output.none.communities_text.size() > 0 && output.blank.panels_hidden && output.strip.has_search"
		}
		"test-dual-appearance": {
			of:    "home"
			says:  "Every token the design block declares carries a light and a dark value under the same name in the emitted design.css, and no authored screen or shared stylesheet writes a hex, so switching the device appearance re-resolves tokens with no state change and no reload; the driver reads the emitted and authored files, never a fixture."
			given: {design: "shell/design.css", authored: ["shell/screens/home.css", "shell/screens/profile.css", "shell/screens/scrapbook.css", "shell/screens/friends.css", "shell/screens/communities.css", "shell/screens/community.css", "shell/screens/topic.css", "shell/screens/testimonials.css", "shell/screens/edit.css", "shell/screens/members.css", "shell/screens/search.css", "shell/shared/yogurt.css", "shell/shared/chrome.css"]}
			when:  "read"
			then:  "output.tokens.size() > 0 && output.tokens.all(t, t.light != '' && t.dark != '') && output.authored.all(css, !css.matches('#[0-9a-fA-F]{3,8}'))"
		}
	}

	meta: decisions: {
		"decision-auth-door": {}
		"decision-public-read-owner-writes": {}
		"decision-me-row": {}
		"decision-probe-empty": {}
		"decision-friendship-mirror": {}
		"decision-pending-private": {}
		"decision-inert-first-turn": {}
		"decision-pictures-by-link": {}
		"decision-door-split": {}
		"decision-relation-through-me": {}
		"decision-scrapbook": {}
		"decision-live-relations": {}
		"decision-communities-screen": {}
		"decision-community-page": {}
		"decision-topic-page": {}
		"decision-testimonials": {}
		"decision-edits-and-members": {}
		"decision-search": {}
		"decision-debts": {}
		"decision-fans": {}
		"decision-karma": {}
		"decision-news": {}
		"decision-polish": {}
		"decision-faces-shipped": {}
		"decision-driver": {}
		"decision-forum-membership": {}
		"decision-demo-network": {}
		"decision-message-keys-as-values": {}
		"decision-design-identity": {}
		"decision-terminal-chrome": {}
		"decision-escape-hatches": {}
	}
}

terminal: (pronto.#DefaultTerminal & {"code": code}).out
// The demo network's pictures (decision 30): the files assets/manifest.json
// names, content-addressed under pictures/, served as statics at
// /pictures/<file> by caddy on the local stack and the docker release and by
// the edge bundle's assets; no bucket, no seed, no blob plane. The manifest is
// the one list: the seed, the credits screen and the pictures test read it.
_pictureStatics: [for _, v in _pictures {file: "pictures/\(v.file)", target: "/srv/pictures/\(v.file)"}]
cluster:  (pronto.#DefaultCluster & {"code": code, statics: list.Concat([terminal.surface.statics, _pictureStatics])}).out
loop:     (pronto.#DefaultLoop & {"code": code, "cluster": cluster, "terminal": terminal}).out
build:    (pronto.#DefaultBuild & {"code": code, "loop": loop, "cluster": cluster, "terminal": terminal}).out
out:      pronto.#emit & {"code": code, "cluster": cluster, "terminal": terminal, "loop": loop, "build": build}

// The ledger's clauses a photograph cannot judge, over screens mounted on
// posed rows (ir decision-driver).
loop: surface: checks: "screens": {
	verb: "test"
	cmds: [
		"\(pronto.#Harness.rule); deno test \(pronto.#Harness.flags) --no-check --allow-env --allow-read tests/screens.test.ts",
	]
	note: "the caps of three, twelve, twenty and twenty-four, the plural counts, the tap-to-set karma rows and the saved stamp, over posed rows"
}

loop: surface: checks: "catalogues": {
	verb: "test"
	cmds: [
		"deno test --config tests/deno.json --lock tests/deno.lock --frozen --allow-read tests/catalogues.test.ts",
	]
	note: "no message left in the other language; every count message has its plural arms"
}

// The clauses no walk reaches, through the cluster with several guest
// sessions, against the runner's own stack (ir decision-driver).
build: checks: "ledger": {
	priority: 1
	cmds: [
		"\(pronto.#Harness.check); deno test \(pronto.#Harness.flags) --allow-env --allow-read --allow-net --unsafely-ignore-certificate-errors=caddy tests/ledger.ts",
	]
	note: "forged writes refused or filtered, an outsider's reply, a replied topic's delete and its race with the reply, the friend rule on testimonials and ratings, the three-rater mean and its drop on an unfriend, the creator's membership, the edit form's refusals"
}

loop: surface: checks: "pictures": {
	verb: "test"
	cmds: [
		"deno test --config tests/deno.json --lock tests/deno.lock --frozen --allow-read tests/pictures.test.ts",
	]
	note: "the demo network's pictures: every /pictures/ path the seed names is a file under pictures/ named by its own sha256, and every such file is named by the seed or the manifest"
}
