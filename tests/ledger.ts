// The acceptance ledger's clauses no walk can reach, driven through the cluster
// with several guest sessions: the forged writes (a stranger's delete, a
// non-owner's update, an outsider's reply, a delete of a replied topic and its
// race with the reply), the friend rule on testimonials and ratings, the
// three-rater mean and its drop on an unfriend, the creator's membership, and
// the edit form's refusals. Each claim names the acceptance id it decides.
// Runs at integrate against the runner's own stack (APP_URL), or at a launched
// one when run by hand; it only adds rows under guests it creates.

import { assert, assertEquals } from "jsr:@std/assert@1";
import { baseUrl } from "../../../plugins/omnishell/base-url.ts";

const base = await baseUrl(Deno.args[0] ?? ".");

type Session = { token: string; id: string; headers: Record<string, string> };
const guest = async (): Promise<Session> => {
  const r = await fetch(`${base}/auth/guest`, { method: "POST", headers: { "content-type": "application/json" }, body: "{}" });
  assert(r.ok, `guest sign-in: ${r.status}`);
  const token = (await r.json()).token as string;
  const id = JSON.parse(atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))).sub as string;
  return { token, id, headers: { Authorization: `Bearer ${token}`, "content-type": "application/json", Prefer: "return=representation" } };
};

type Reply = { status: number; rows: Record<string, unknown>[]; message?: string };
const call = async (s: Session, method: string, path: string, body?: unknown): Promise<Reply> => {
  const r = await fetch(`${base}/crud/${path}`, { method, headers: s.headers, body: body === undefined ? undefined : JSON.stringify(body) });
  const text = await r.text();
  const json = text === "" ? [] : JSON.parse(text);
  return { status: r.status, rows: Array.isArray(json) ? json : [], message: Array.isArray(json) ? undefined : json.message };
};
const ok = async (s: Session, method: string, path: string, body?: unknown, what = path) => {
  const r = await call(s, method, path, body);
  assert(r.status >= 200 && r.status < 300, `${what}: ${r.status} ${r.message ?? ""}`);
  return r.rows;
};
/** A write the database refuses outright: 400 for a trigger's RAISE or a CHECK
 * (PostgREST's answer to 23514), 409 for a foreign key; `rule` is a word of the
 * message the refusing rule raises, so a refusal by another rule is caught. */
const refused = async (s: Session, method: string, path: string, body: unknown, what: string, rule?: string, status = 400) => {
  const r = await call(s, method, path, body);
  assert(r.status === status, `${what}: expected ${status}, got ${r.status} ${r.message ?? JSON.stringify(r.rows)}`);
  if (rule !== undefined) assert((r.message ?? "").includes(rule), `${what}: refused by another rule: ${r.message}`);
  return r.message ?? "";
};
/** A write the policy filters to nothing: the request succeeds and touches no row. */
const filtered = async (s: Session, method: string, path: string, body: unknown, what: string) => {
  const r = await call(s, method, path, body);
  assert(r.status < 300 && r.rows.length === 0, `${what}: expected no row touched, got ${r.status} ${JSON.stringify(r.rows)}`);
};

const befriend = async (asker: Session, other: Session) => {
  const [sent] = await ok(asker, "POST", "friend_request_sent", { to_id: other.id }, "friend request");
  await ok(other, "PATCH", `friend_request?id=eq.${sent.id}`, { accepted: true }, "accept");
  const [pair] = await ok(asker, "GET", `friendship?user_id=eq.${asker.id}&friend_id=eq.${other.id}`);
  assert(pair, "accepting a request makes the two friends");
};

Deno.test({
  name: "the ledger's clauses no walk reaches, through the cluster",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn(t) {
  const a = await guest();
  const b = await guest();
  const c = await guest();
  const d = await guest();
  const stranger = await guest();

  // accept-delete-scrap: the writer and the page's owner delete; nobody else can.
  await t.step("accept-delete-scrap", async () => {
    const [scrap] = await ok(b, "POST", "scrap", { owner_id: a.id, body: "um recado para o ledger" }, "leave scrap");
    await filtered(stranger, "DELETE", `scrap?id=eq.${scrap.id}`, undefined, "a stranger's delete of a scrap");
    assertEquals((await ok(a, "GET", `scrap?id=eq.${scrap.id}`)).length, 1, "the scrap survived the stranger");
    const owned = await ok(a, "DELETE", `scrap?id=eq.${scrap.id}`, undefined, "the owner sweeps it");
    assertEquals(owned.length, 1, "the page's owner deletes a scrap left for them");
    const [second] = await ok(b, "POST", "scrap", { owner_id: a.id, body: "outro recado" }, "leave another");
    assertEquals((await ok(b, "DELETE", `scrap?id=eq.${second.id}`)).length, 1, "the writer takes their own scrap back");
  });

  // accept-create-community, accept-creator-member, accept-edit-community-refused
  const [community] = await ok(a, "POST", "community", { name: `ledger ${a.id.slice(0, 8)}`, category: "cat_humor", description: "a community the driver opened" }, "create community");
  await t.step("accept-create-community, accept-creator-member, accept-edit-community-refused", async () => {
    const members = await ok(a, "GET", `membership?community_id=eq.${community.id}`);
    assertEquals(members.length, 1, "the creator is the first member");
    assertEquals(members[0].user_id, a.id);
    await filtered(b, "PATCH", `community?id=eq.${community.id}`, { description: "forged" }, "a non-owner's update of a community");
    const [again] = await ok(a, "GET", `community?id=eq.${community.id}`);
    assertEquals(again.description, "a community the driver opened", "the description is the owner's");
    await refused(a, "POST", "community", { name: "", category: "cat_humor", description: "x" }, "a blank name", "community_name_check");
    await refused(a, "POST", "community", { name: "sem categoria", category: "cat_nope", description: "x" }, "an unknown category", "community_category_check");
  });

  // accept-reply-outsider, accept-forum-topics: a non-member's forced reply or topic.
  await ok(b, "POST", "membership", { community_id: community.id }, "b joins");
  const [topic] = await ok(a, "POST", "topic", { community_id: community.id, title: "um tópico", body: "para o ledger" }, "open topic");
  await t.step("accept-reply-outsider, accept-forum-topics, accept-reply", async () => {
    await refused(stranger, "POST", "post", { topic_id: topic.id, body: "de fora" }, "an outsider's reply", "member");
    await refused(stranger, "POST", "topic", { community_id: community.id, title: "de fora", body: "x" }, "an outsider's topic", "member");
    await refused(b, "POST", "topic", { community_id: community.id, title: "  ", body: "x" }, "a blank title", "topic_title_check");
    await refused(b, "POST", "post", { topic_id: topic.id, body: "   " }, "a blank reply", "post_body_check");
  });

  // accept-delete-topic: the opener deletes an unreplied topic; a replied one stays,
  // and a forced delete, even one racing the reply, never takes a reply with it.
  await t.step("accept-delete-topic", async () => {
    const [quiet] = await ok(a, "POST", "topic", { community_id: community.id, title: "quieto", body: "ninguém respondeu" }, "quiet topic");
    assertEquals((await ok(a, "DELETE", `topic?id=eq.${quiet.id}`)).length, 1, "the opener deletes a topic nobody answered");
    await filtered(b, "DELETE", `topic?id=eq.${topic.id}`, undefined, "a member who did not open the topic");
    await ok(b, "POST", "post", { topic_id: topic.id, body: "uma resposta" }, "b replies");
    await refused(a, "DELETE", `topic?id=eq.${topic.id}`, undefined, "a forced delete of a replied topic", "stays");

    // Ten rounds fire both at once, in either order, a smoke over the window;
    // ten more give one side a head start, so each order's outcome is asserted:
    // a reply that landed first refuses the delete, a delete that landed first
    // fails the reply. The proof of the window itself is at the SQL tier
    // (ir decision-driver).
    const rounds = 20;
    const outcomes = { replied: 0, erased: 0 };
    const pause = (ms: number) => new Promise((r) => setTimeout(r, ms));
    for (let i = 0; i < rounds; i++) {
      const [t] = await ok(a, "POST", "topic", { community_id: community.id, title: `corrida ${i}`, body: "x" }, "race topic");
      const reply$ = () => call(b, "POST", "post", { topic_id: t.id, body: `resposta ${i}` });
      const erase$ = () => call(a, "DELETE", `topic?id=eq.${t.id}`);
      const replyFirst = i % 2 === 0;
      const staggered = i >= rounds / 2;
      const first = replyFirst ? reply$() : erase$();
      if (staggered) await pause(40);
      const second = replyFirst ? erase$() : reply$();
      const [reply, erase] = replyFirst ? await Promise.all([first, second]) : (await Promise.all([first, second])).reverse() as [Reply, Reply];
      const gone = (await ok(a, "GET", `topic?id=eq.${t.id}`)).length === 0;
      const replied = reply.status === 201;
      assert(!(replied && gone), `round ${i}: the reply landed (${reply.status}) and the topic is gone (${erase.status}): a delete took a reply with it`);
      // A reply that lost is refused by 017 (400, the topic gone before its guard) or by the foreign key (409, the delete still open).
      assert(replied || gone, `round ${i}: neither the reply (${reply.status}) nor the delete (${erase.status}) went through`);
      if (!replied) assert(reply.status === 400 || reply.status === 409, `round ${i}: the losing reply answered ${reply.status}`);
      if (replied) assert(erase.status >= 400 || erase.rows.length === 0, `round ${i}: the delete reported success beside a landed reply`);
      if (staggered) assert(replied === replyFirst, `round ${i}: with a head start the ${replyFirst ? "reply" : "delete"} should have won`);
      outcomes[replied ? "replied" : "erased"]++;
    }
    console.log(`race: ${outcomes.replied} replies landed, ${outcomes.erased} deletes won`);
  });

  // accept-write-refused, accept-write-testimonial, accept-approve-testimonial
  await t.step("accept-write-refused, accept-write-testimonial, accept-approve-testimonial", async () => {
    await refused(stranger, "POST", "testimonial_draft", { subject_id: a.id, body: "de um estranho" }, "a non-friend's testimonial", "only a friend");
    await befriend(b, a);
    await refused(b, "POST", "testimonial_draft", { subject_id: a.id, body: "   " }, "a blank testimonial", "body_check");
    const [draft] = await ok(b, "POST", "testimonial_draft", { subject_id: a.id, body: "um amigo de verdade" }, "write testimonial");
    assertEquals((await ok(a, "GET", `testimonial_pending?id=eq.${draft.id}`)).length, 1, "the subject sees it waiting");
    assertEquals((await ok(a, "GET", `testimonial?id=eq.${draft.id}`)).length, 0, "nothing is published before approval");
    await filtered(c, "PATCH", `testimonial_pending?id=eq.${draft.id}`, { approved: true }, "a third person's approval");
    await ok(a, "PATCH", `testimonial_pending?id=eq.${draft.id}`, { approved: true }, "approve");
    assertEquals((await ok(c, "GET", `testimonial?id=eq.${draft.id}`)).length, 1, "the approved one is public");
    assertEquals((await ok(a, "GET", `testimonial_pending?id=eq.${draft.id}`)).length, 0, "the waiting row left with the approval");
    assertEquals((await ok(b, "GET", `testimonial_draft?id=eq.${draft.id}`)).length, 0, "the writer's draft left with the approval");
    await refused(b, "POST", "testimonial_draft", { subject_id: a.id, body: "um segundo" }, "a second testimonial by the same friend", "one testimonial per person");
    await filtered(c, "DELETE", `testimonial?id=eq.${draft.id}`, undefined, "a third person's delete of a testimonial");
    assertEquals((await ok(b, "DELETE", `testimonial?id=eq.${draft.id}`)).length, 1, "the writer deletes their testimonial");
  });

  // accept-smileys, accept-rate-friend: only friends rate; the smileys
  // appear at three raters as the rounded mean and leave when a rater unfriends.
  await t.step("accept-smileys, accept-rate-friend", async () => {
    await refused(stranger, "POST", "karma", { rated_id: a.id, trust: 1, cool: 1, sexy: 1 }, "a non-friend's rating", "only a friend rates");
    await befriend(c, a);
    await befriend(d, a);
    // Nobody is their own friend, so 023's guard answers before the row's CHECK does.
    await refused(a, "POST", "karma", { rated_id: a.id, trust: 3, cool: 3, sexy: 3 }, "rating oneself", "only a friend rates");
    await refused(b, "POST", "karma", { rated_id: a.id, trust: 4, cool: 0, sexy: 0 }, "a level above three", "karma_trust_check");
    await ok(b, "POST", "karma", { rated_id: a.id, trust: 3, cool: 1, sexy: 0 }, "b rates");
    await ok(c, "POST", "karma", { rated_id: a.id, trust: 2, cool: 1, sexy: 1 }, "c rates");
    assertEquals((await ok(stranger, "GET", `karma_smiley?rated_id=eq.${a.id}`)).length, 0, "two raters draw no smileys");
    const [dRating] = await ok(d, "POST", "karma", { rated_id: a.id, trust: 2, cool: 2, sexy: 3 }, "d rates");
    const [smiley] = await ok(stranger, "GET", `karma_smiley?rated_id=eq.${a.id}`);
    assert(smiley, "three raters draw the smileys");
    // means 7/3=2.33, 4/3=1.33, 4/3=1.33
    assertEquals([smiley.trust, smiley.cool, smiley.sexy, smiley.raters], [2, 1, 1, 3], "the rounded mean of the three private rows");
    assertEquals((await ok(stranger, "GET", `karma?rated_id=eq.${a.id}`)).length, 0, "a private row is nobody else's");
    await filtered(stranger, "PATCH", `karma?id=eq.${dRating.id}`, { trust: 0 }, "a stranger's update of a rating");
    await ok(d, "PATCH", `karma?id=eq.${dRating.id}`, { sexy: 0 }, "d rates again");
    const [moved] = await ok(stranger, "GET", `karma_smiley?rated_id=eq.${a.id}`);
    assertEquals(moved.sexy, 0, "the smileys move with a changed rating (1/3 rounds to 0)");
    assertEquals((await ok(d, "DELETE", `friendship?user_id=eq.${d.id}&friend_id=eq.${a.id}`)).length, 1, "d unfriends");
    assertEquals((await ok(d, "GET", `karma?rated_id=eq.${a.id}`)).length, 0, "the rating left with the friendship");
    assertEquals((await ok(stranger, "GET", `karma_smiley?rated_id=eq.${a.id}`)).length, 0, "below three raters the smileys leave");
  });

  // accept-edit-refused: the picture rule, the name's length, anybody else's row.
  await t.step("accept-edit-refused", async () => {
    await refused(a, "PATCH", `app_user?id=eq.${a.id}`, { photo_url: "http://example.com/x.jpg" }, "a photo link that is not https", "photo_url_check");
    await refused(a, "PATCH", `app_user?id=eq.${a.id}`, { display_name: "x".repeat(61) }, "a name over sixty characters", "display_name_check");
    await filtered(a, "PATCH", `app_user?id=eq.${b.id}`, { display_name: "forjado" }, "a write at anyone else's row");
    const [own] = await ok(a, "PATCH", `app_user?id=eq.${a.id}`, { display_name: "Ledger Driver", photo_url: "https://example.com/x.jpg" }, "own edit");
    assertEquals(own.display_name, "Ledger Driver");
  });

  // accept-news: twenty-one doings by a friend reach the friend's inbox and
  // nobody else's, in início's own order; the log is the cluster's alone. The
  // cap of twenty is the shell's attribute (tests/screens.test.ts).
  await t.step("accept-news", async () => {
    for (let i = 0; i < 21; i++) await ok(b, "POST", "scrap", { owner_id: c.id, body: `recado ${i}` }, "b leaves a scrap");
    const inbox = await ok(a, "GET", `feed_item?actor_id=eq.${b.id}&kind=eq.scrap&order=at.desc,id.desc`);
    assert(inbox.length >= 21, `b's friend holds b's ${inbox.length} scraps`);
    assertEquals(inbox[0].excerpt, "recado 20", "newest first");
    assertEquals((await ok(b, "GET", `feed_item?actor_id=eq.${b.id}`)).length, 0, "a doing is for friends, not for its own actor");
    assertEquals((await ok(stranger, "GET", `feed_item?actor_id=eq.${b.id}`)).length, 0, "a stranger's inbox holds none of it");
    const log = await call(a, "GET", `feed?actor_id=eq.${b.id}`);
    assert(log.status >= 400 || log.rows.length === 0, `the log is nobody's to read: ${log.status} ${log.rows.length}`);
    // A new friend receives the doings already done; an unfriend takes them away.
    const late = await guest();
    await befriend(late, b);
    assertEquals((await ok(late, "GET", `feed_item?actor_id=eq.${b.id}&kind=eq.scrap`)).length, 21, "a new friend's inbox holds the friend's doings");
    assertEquals((await ok(late, "DELETE", `friendship?user_id=eq.${late.id}&friend_id=eq.${b.id}`)).length, 1, "late unfriends");
    assertEquals((await ok(late, "GET", `feed_item?actor_id=eq.${b.id}`)).length, 0, "the doings left with the friendship");
  });

  // accept-be-fan: one fan row per pair, never of oneself.
  await t.step("accept-be-fan", async () => {
    await refused(a, "POST", "fan", { idol_id: a.id }, "a fan of oneself", "fan_check");
    await ok(b, "POST", "fan", { idol_id: a.id }, "b is a fan");
    await refused(b, "POST", "fan", { idol_id: a.id }, "a second fan row for the pair", "uq_fan", 409);
  });
  },
});
