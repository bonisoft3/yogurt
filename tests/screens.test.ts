// The ledger's clauses a photograph cannot judge and the demo network cannot
// reach, over the emitted screens: the plural counts and the search cap on
// screens mounted over posed rows, the saved stamp on the edit form, and, on
// the shells themselves, the caps every capped region asks for and the shape
// of the tap-to-set karma rows. Início, the profile and the fans page cannot
// be mounted here: the harness's select grammar refuses an embed hinted by its
// foreign key column (the feed's actor, the fan probe's idol), so their caps
// are read off the markup and their rows are exercised by tests/ledger.ts.
import { assert, mountApp, type Row, textOf, writes } from "@bonisoft3/omnishell/test/screen-harness.ts";
import { parseHTML } from "npm:linkedom@0.18.4";

const APP = new URL("../", import.meta.url);
const SEED = 20261031;
const EPOCH = "2026-10-31T12:00:00.000Z";

const ME = "u-me";
const person = (id: string, handle: string, name: string, over: Row = {}): Row => ({
  id,
  handle,
  display_name: name,
  photo_url: null,
  about: "",
  relationship: "rel_unsaid",
  city: "",
  country: "",
  birthday: null,
  passions: "",
  music: "",
  movies: "",
  books: "",
  created_at: "2026-01-01T00:00:00.000000Z",
  search_text: `${handle} ${name}`.toLowerCase(),
  txid: "1",
  ...over,
});
const at = (n: number) => `2026-03-${String(1 + (n % 28)).padStart(2, "0")}T09:${String(n % 60).padStart(2, "0")}:00.000000Z`;
const many = (n: number, make: (i: number) => Row): Row[] => Array.from({ length: n }, (_, i) => make(i + 1));
const people = (n: number) => many(n, (i) => person(`u-p${i}`, `pessoa-${i}`, `Pessoa ${i}`, { created_at: at(i) }));

// Every table the app syncs, empty, so a screen's regions all find their table.
const world = (over: Record<string, Row[]> = {}): Record<string, Row[]> => ({
  app_user: [person(ME, "me", "Eu Mesmo")],
  me: [{ id: ME, handle: "me", txid: "1" }],
  friend_request_sent: [],
  friend_request: [],
  friendship: [],
  scrap: [],
  testimonial_draft: [],
  testimonial_pending: [],
  testimonial: [],
  fan: [],
  karma: [],
  karma_smiley: [],
  feed_item: [],
  community: [],
  membership: [],
  search: [],
  community_search: [],
  topic: [],
  post: [],
  ...over,
});
const mount = (screen: string, tables: Record<string, Row[]>, params: Record<string, string> = {}) =>
  mountApp({ appDir: APP, screen, seed: SEED, epoch: EPOCH, params, tables, cluster: { me: ME } });
const test = (name: string, fn: () => Promise<void>) => Deno.test({ name, sanitizeOps: false, sanitizeResources: false, fn });
const shell = async (screen: string) => parseHTML(await Deno.readTextFile(new URL(`../shell/screens/${screen}.html`, import.meta.url))).document;
/** Every match in the document and inside every <template>, however deep: a
 * region's rows live in templates a plain query does not enter. */
const deep = (root: { querySelectorAll(s: string): Iterable<Element> }, selector: string): Element[] => {
  const out = [...root.querySelectorAll(selector)];
  for (const t of root.querySelectorAll("template")) out.push(...deep((t as HTMLTemplateElement).content as unknown as typeof root, selector));
  return out;
};
/** A region's drawn text, without the template it draws from. */
const drawn = (el: Element) => (([...el.childNodes].find((n) => (n as Element).localName !== "template")?.textContent) ?? "").trim();

// accept-plural-counts
test("a count of one reads in the singular and zero keeps the plural", async () => {
  const community = (i: number): Row => ({ id: `c-${i}`, name: `Comunidade ${i}`, description: "", category: "cat_humor", owner_id: ME, photo_url: null, created_at: at(i), txid: "1" });
  const m = await mount("communities", world({
    community: [community(0), community(1), community(2)],
    membership: [
      { id: "m-1", community_id: "c-1", user_id: ME, created_at: at(1), txid: "1" },
      { id: "m-2a", community_id: "c-2", user_id: ME, created_at: at(2), txid: "1" },
      { id: "m-2b", community_id: "c-2", user_id: "u-p1", created_at: at(3), txid: "1" },
    ],
  }));
  await m.settle();
  // The fake store draws the count projection once per counted row where the
  // shipped store collapses it to one; the text each carries is the count's.
  const counts = Object.fromEntries(m.all(".row.community").map((row) => [textOf(row.querySelector(".row-name")!), drawn(row.querySelector(".members .tally")!)]));
  assert(counts["Comunidade 0"] === "0 membros", `zero reads ${JSON.stringify(counts["Comunidade 0"])}`);
  assert(counts["Comunidade 1"] === "1 membro", `one reads ${JSON.stringify(counts["Comunidade 1"])}`);
  assert(counts["Comunidade 2"] === "2 membros", `two reads ${JSON.stringify(counts["Comunidade 2"])}`);
  await m.stop();
});

// accept-search-case: the first twenty-four, by name
test("a search draws the first twenty-four people whose name or username contains the words, by name", async () => {
  const m = await mount("search", world({
    app_user: [person(ME, "me", "Eu"), ...people(26)],
    search: [{ id: "the", q: "PESSOA", txid: "1" }],
  }));
  await m.settle();
  const names = m.texts(".tiles[data-live=\"app_user\"] .tile .name");
  assert(names.length === 24, `the people panel drew ${names.length} tiles for 26 matches`);
  assert(names[0] === "Pessoa 1" && names[1] === "Pessoa 10", `by name: ${names.slice(0, 2).join(", ")}`);
  await m.stop();
});

// accept-communities-rail, accept-news, accept-friends-screen, accept-testimonials-teaser,
// accept-profile-communities, accept-members-page, accept-search-case, accept-news-page:
// the caps the ledger states, as each region asks for them; where the ledger
// names no number (the profile's communities) the number is the brief's.
test("every capped region asks the store for exactly the cap the ledger states", async () => {
  const caps: Record<string, Record<string, number>> = {
    home: { friendship: 9, fan: 9, app_user: 14, feed_item: 20, scrap: 8, community: 12 },
    profile: { membership: 12, scrap: 3, testimonial: 3, friendship: 12 },
    community: { membership: 12 },
    members: {},
    search: { app_user: 24, community: 24 },
    news: { feed_item: 100 },
    communities: { community: 20 },
  };
  for (const [screen, want] of Object.entries(caps)) {
    const doc = await shell(screen);
    const found: Record<string, number> = {};
    for (const el of deep(doc, "[data-live][data-filter*='limit=']")) {
      const n = Number(/limit=(\d+)/.exec(el.getAttribute("data-filter")!)![1]);
      // limit=1 is a probe's shape, not a cap.
      if (n === 1) continue;
      const table = el.getAttribute("data-live")!;
      assert(found[table] === undefined || found[table] === n, `${screen} caps ${table} twice, at ${found[table]} and ${n}`);
      found[table] = n;
    }
    const sorted = (o: Record<string, number>) => JSON.stringify(Object.entries(o).sort());
    assert(sorted(found) === sorted(want), `${screen} asks ${JSON.stringify(found)}, the ledger states ${JSON.stringify(want)}`);
  }
});

// accept-karma-rows: the shape of the rows, which the terminal's change-submit turns into a save
test("each smiley is a row of four required levels; the update form has no button, the first rating keeps its", async () => {
  const doc = await shell("profile");
  const [again] = deep(doc, "form[data-form=\"rate-again\"]");
  const [first] = deep(doc, "form[data-form=\"rate\"]");
  assert(again && first, "both karma forms are in the shell");
  for (const [form, bound] of [[again, true], [first, false]] as [Element, boolean][]) {
    assert(form.querySelectorAll("button, [type=\"submit\"]").length === (bound ? 0 : 1), `${form.getAttribute("data-form")} ${bound ? "has a button, so a tap would not save" : "lacks the avaliar button"}`);
    for (const level of ["trust", "cool", "sexy"]) {
      const radios = [...form.querySelectorAll(`input[type="radio"][name="${level}"]`)];
      assert(radios.map((r) => r.getAttribute("value")).join("") === "0123", `${form.getAttribute("data-form")} ${level} offers ${radios.length} levels`);
      assert(radios.every((r) => r.hasAttribute("required")), `${level} is required`);
      assert(radios.every((r) => (r.getAttribute("data-value") === `{${level}}`) === bound), `${form.getAttribute("data-form")} ${level} ${bound ? "binds the row's level" : "starts unchosen"}`);
      assert(radios.every((r) => r.closest("label")?.querySelector("[data-text]")), `${level}: every level is a labelled chip`);
    }
    assert(form.querySelectorAll("select").length === 0, "no select remains in a karma form");
  }
});

// accept-saved-line: the screen stamps success for the saved word's window
test("a save stamps the screen with success for the saved line, then settles back", async () => {
  const m = await mount("edit", world());
  await m.settle();
  const form = m.one("form.edit-form");
  m.set(m.one("input[name=\"display_name\"]"), "value", "Eu Mesma");
  m.fire(form, "submit");
  await m.quiet();
  assert(m.screen.getAttribute("data-state") === "success", `right after the save the screen is in ${JSON.stringify(m.screen.getAttribute("data-state"))}`);
  await m.settle();
  assert(m.screen.getAttribute("data-state") !== "success", "the stamp is a window, not a resting state");
  const saved = writes(m).filter((c) => c.table === "app_user");
  assert(saved.length === 1 && saved[0].row?.display_name === "Eu Mesma", `the save wrote my row: ${JSON.stringify(saved)}`);
  await m.stop();
});
