// Post-release journeys for `sayt verify`: every screen is behind the door, so
// the sweep's default visits never leave the served state; the home journey
// comes in as a guest and reads the demo network's first person, community
// and topic through crud, and each other screen is visited at a concrete
// route built from them, with the row's own text as the witness.
// A journey as pronto's verify runs it (verify/browser-sweep.ts): the screen
// it lands on, the role it signs in as, its path, and what it does there.
type JourneyItem = { screen: string; role?: string; path?: string; run?: (page: any, ctx?: { baseUrl?: string }) => Promise<void> };
import pt from "../messages/pt-BR.json" with { type: "json" };
import en from "../messages/en.json" with { type: "json" };

type Seed = { handle: string; name: string; community: string; communityName: string; topic: string; topicTitle: string };
let seed: Seed;

async function ready(page: any, screen: string) {
  await page.waitForFunction((name: string) => {
    const shell = document.querySelector("#app .shell-screen:not([hidden])");
    if (!shell || shell.hasAttribute("data-served") || shell.hasAttribute("data-entering")) return false;
    const view = shell.querySelector(".screen");
    if (!view || view.getAttribute("data-screen") !== name) return false;
    if (view.getAttribute("data-state") === "network-error") throw new Error("screen reported network-error");
    return view.getAttribute("data-state") !== "loading" && !view.querySelector("[data-hydrating], [data-state='loading']");
  }, screen, { timeout: 45_000 });
}

async function navigate(page: any, base: string, path: string, screen: string) {
  const response = await page.goto(`${base}${path}`, { waitUntil: "domcontentloaded", timeout: 45_000 });
  if (!response || response.status() !== 200) throw new Error(`${screen}: navigation failed`);
  await ready(page, screen);
}

async function readRow(page: any, base: string, query: string, token: string) {
  const response = await page.request.get(`${base}/crud/${query}`, { headers: { Authorization: `Bearer ${token}` } });
  if (!response.ok()) throw new Error(`seed read failed: ${response.status()}`);
  const rows = await response.json();
  if (!rows[0]) throw new Error(`the demo network has no row for ${query}`);
  return rows[0];
}

const home: JourneyItem = {
  screen: "home",
  async run(page, ctx) {
    const base = String(ctx?.baseUrl);
    const response = await page.goto(`${base}/`, { waitUntil: "domcontentloaded" });
    if (!response || response.status() !== 200) throw new Error("home: navigation failed");
    await page.locator(".login-guest").click();
    await ready(page, "home");
    const session = await page.evaluate(() => JSON.parse(sessionStorage.getItem("pronto-token") ?? "null"));
    if (!session?.token || !session.user?.guest) throw new Error("guest sign-in did not establish a session");
    // The oldest member is a demo founder; a guest minted by an earlier journey sorts after every seeded row.
    const person = await readRow(page, base, "app_user?select=handle,display_name&order=created_at,id&limit=1", session.token);
    const topic = await readRow(page, base, "topic?select=id,community_id,title&order=created_at&limit=1", session.token);
    const community = await readRow(page, base, `community?select=name&id=eq.${encodeURIComponent(topic.community_id)}`, session.token);
    seed = { handle: person.handle, name: person.display_name, community: topic.community_id, communityName: community.name, topic: topic.id, topicTitle: topic.title };
  },
};

const pathJourney = (screen: string, path: () => string, witness?: () => string): JourneyItem => ({
  screen,
  async run(page, ctx) {
    if (!seed) throw new Error("home did not resolve the seed");
    await navigate(page, String(ctx?.baseUrl), path(), screen);
    // The letter disc repeats a name in a span hidden from readers; the witness is the visible one.
    if (witness) await page.getByText(witness(), { exact: true }).locator("visible=true").first().waitFor({ state: "visible", timeout: 45_000 });
  },
});
const enc = encodeURIComponent;

// The three lines only a laid-out page can judge (acceptance: accept-guest-strip-phone,
// accept-saved-line, accept-plural-counts), on the guest the home journey signed in:
// the strip at phone width is one line that scrolls, the edit form says "salvo"
// under its button after a save, and the guest's own card keeps the plural at zero.
const phoneStrip: JourneyItem = {
  screen: "home",
  async run(page, ctx) {
    if (!seed) throw new Error("home did not resolve the seed");
    await page.setViewportSize({ width: 390, height: 844 });
    const base = String(ctx?.baseUrl);
    try {
      await navigate(page, base, "/", "home");
      const strip = await page.evaluate(() => {
        const nav = document.querySelector("body > nav");
        if (!nav) throw new Error("no strip");
        const items = [...nav.querySelectorAll("a, button")].filter((el) => el.getClientRects().length > 0);
        // One line: every control's box crosses the first control's vertical band.
        const first = items[0].getBoundingClientRect();
        const offLine = items.filter((el) => { const b = el.getBoundingClientRect(); return b.bottom <= first.top || b.top >= first.bottom; }).length;
        const line = parseFloat(getComputedStyle(nav).lineHeight) || 24;
        return { items: items.length, offLine, height: nav.getBoundingClientRect().height, line };
      });
      if (strip.items < 3) throw new Error(`the guest strip has ${strip.items} controls`);
      if (strip.offLine > 0) throw new Error(`${strip.offLine} of the guest strip's controls sit on a second line at 390px`);
      if (strip.height > strip.line * 2.5) throw new Error(`the guest strip is ${strip.height}px tall for a ${strip.line}px line`);
      // The browser's locale picks the catalogue; the card's count reads the
      // singular at one and the plural otherwise, against the row count itself.
      const me = await page.evaluate(() => JSON.parse(sessionStorage.getItem("pronto-token") ?? "null"));
      const friends = await (await page.request.get(`${base}/crud/friendship?select=id&user_id=eq.${me.user.id}`, { headers: { Authorization: `Bearer ${me.token}` } })).json();
      const n = friends.length;
      const forms = n === 0 ? [pt.friends_zero, en.friends_zero] : n === 1 ? ["1 amigo", "1 friend"] : [`${n} amigos`, `${n} friends`];
      const tally = page.locator(".screen[data-screen=\"home\"] .counts .tally").first();
      await tally.waitFor({ state: "visible", timeout: 45_000 });
      const read = (await tally.innerText()).trim();
      if (!forms.includes(read)) throw new Error(`with ${n} friends the card's count reads ${JSON.stringify(read)}`);
    } finally {
      await page.setViewportSize({ width: 1280, height: 800 });
    }
  },
};

const savedWord: JourneyItem = {
  screen: "edit",
  async run(page, ctx) {
    if (!seed) throw new Error("home did not resolve the seed");
    await navigate(page, String(ctx?.baseUrl), "/editar-perfil", "edit");
    const name = page.locator("form.edit-form input[name=\"display_name\"]");
    await name.waitFor({ state: "visible", timeout: 45_000 });
    await name.fill("Verificadora");
    const saved = page.locator("form.edit-form .saved");
    if (await saved.isVisible()) throw new Error("the saved line shows before any save");
    await page.locator("form.edit-form button[type=\"submit\"]").click();
    // Hidden by visibility until the screen stamps success with the button still focused.
    await saved.waitFor({ state: "visible", timeout: 10_000 });
    const word = (await saved.innerText()).trim();
    if (word !== pt.saved_line && word !== en.saved_line) throw new Error(`the saved line reads ${JSON.stringify(word)}`);
  },
};

// accept-karma-rows, accept-rate-friend: a second guest, minted over the API,
// befriends the browser's guest; the browser then rates them through the chips,
// the first time with "avaliar", then with one tap on a level that is the save.
const karmaRows: JourneyItem = {
  screen: "profile",
  async run(page, ctx) {
    if (!seed) throw new Error("home did not resolve the seed");
    const base = String(ctx?.baseUrl);
    // The sweep may hand this journey a page of its own: sign in as a guest when the home journey's session is not here.
    await page.goto(`${base}/`, { waitUntil: "domcontentloaded" });
    let me = await page.evaluate(() => JSON.parse(sessionStorage.getItem("pronto-token") ?? "null"));
    if (!me?.token) {
      await page.locator(".login-guest").click();
      await ready(page, "home");
      me = await page.evaluate(() => JSON.parse(sessionStorage.getItem("pronto-token") ?? "null"));
    }
    if (!me?.token) throw new Error("no guest session for the rating journey");
    const other = await (await page.request.post(`${base}/auth/guest`, { headers: { "content-type": "application/json" }, data: "{}" })).json();
    const otherId = JSON.parse(atob(other.token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))).sub;
    const crud = async (token: string, method: string, path: string, body?: unknown) => {
      const r = await page.request.fetch(`${base}/crud/${path}`, { method, headers: { Authorization: `Bearer ${token}`, "content-type": "application/json", Prefer: "return=representation" }, data: body === undefined ? undefined : JSON.stringify(body) });
      if (!r.ok()) throw new Error(`${method} ${path}: ${r.status()} ${await r.text()}`);
      return r.json();
    };
    const [sent] = await crud(me.token, "POST", "friend_request_sent", { to_id: otherId });
    await crud(other.token, "PATCH", `friend_request?id=eq.${sent.id}`, { accepted: true });
    const [friend] = await crud(me.token, "GET", `app_user?select=handle&id=eq.${otherId}`);
    await navigate(page, base, `/perfil/${enc(friend.handle)}`, "profile");
    // The edge's live tables learn a row written by another session on a later
    // load, seconds after the write; the friend row is what draws the form.
    // One form per friend row; the friend's own is the visible one.
    const first = page.locator("form.karma-new").locator("visible=true");
    for (let attempt = 0; attempt < 10; attempt++) {
      if (await first.isVisible()) break;
      await page.waitForTimeout(4_000);
      await page.reload({ waitUntil: "domcontentloaded" });
      await ready(page, "profile");
    }
    await first.waitFor({ state: "visible", timeout: 45_000 });
    const width = await first.evaluate((el: Element) => el.getBoundingClientRect().width);
    if (width < 120) throw new Error(`the first-rating form is ${width}px wide`);
    for (const [level, value] of [["trust", "3"], ["cool", "2"], ["sexy", "1"]]) await first.locator(`.level:has(input[name="${level}"][value="${value}"])`).click();
    await first.locator("button[type=\"submit\"]").click();
    const again = page.locator(".karma-mine form[data-form=\"rate-again\"]").locator("visible=true");
    await again.waitFor({ state: "visible", timeout: 45_000 });
    const chosen = () => again.locator("input[type=\"radio\"]:checked").evaluateAll((els: Element[]) => els.map((e: Element) => `${(e as HTMLInputElement).name}=${(e as HTMLInputElement).value}`).join(","));
    if (await chosen() !== "trust=3,cool=2,sexy=1") throw new Error(`after the first rating the chips read ${await chosen()}`);
    await again.locator(".level:has(input[name=\"cool\"][value=\"0\"])").click();
    await again.locator(".saved").waitFor({ state: "visible", timeout: 10_000 });
    const [row] = await crud(me.token, "GET", `karma?select=trust,cool,sexy&rated_id=eq.${otherId}`);
    if (!row || row.cool !== 0 || row.trust !== 3) throw new Error(`the tap wrote ${JSON.stringify(row)}`);
  },
};

// accept-news, accept-news-page: a second guest, minted over the API, befriends
// the browser's guest and leaves a scrap; the doing is read on início and on
// the page. First among the journeys after the door, because the edge went
// green three times with novidades empty for every reader.
const feed: JourneyItem = {
  screen: "news",
  async run(page, ctx) {
    if (!seed) throw new Error("home did not resolve the seed");
    const base = String(ctx?.baseUrl);
    await page.goto(`${base}/`, { waitUntil: "domcontentloaded" });
    let me = await page.evaluate(() => JSON.parse(sessionStorage.getItem("pronto-token") ?? "null"));
    if (!me?.token) {
      await page.locator(".login-guest").click();
      await ready(page, "home");
      me = await page.evaluate(() => JSON.parse(sessionStorage.getItem("pronto-token") ?? "null"));
    }
    if (!me?.token) throw new Error("no guest session for the feed journey");
    const other = await (await page.request.post(`${base}/auth/guest`, { headers: { "content-type": "application/json" }, data: "{}" })).json();
    const otherId = JSON.parse(atob(other.token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))).sub;
    const crud = async (token: string, method: string, path: string, body?: unknown) => {
      const r = await page.request.fetch(`${base}/crud/${path}`, { method, headers: { Authorization: `Bearer ${token}`, "content-type": "application/json", Prefer: "return=representation" }, data: body === undefined ? undefined : JSON.stringify(body) });
      if (!r.ok()) throw new Error(`${method} ${path}: ${r.status()} ${await r.text()}`);
      return r.json();
    };
    const [sent] = await crud(me.token, "POST", "friend_request_sent", { to_id: otherId });
    await crud(other.token, "PATCH", `friend_request?id=eq.${sent.id}`, { accepted: true });
    const words = `recado da jornada ${Date.now()}`;
    await crud(other.token, "POST", "scrap", { owner_id: me.user.id, body: words });
    const [row] = await crud(me.token, "GET", `feed_item?select=excerpt&actor_id=eq.${otherId}&kind=eq.scrap`);
    if (!row || row.excerpt !== words) throw new Error(`the inbox over the API holds ${JSON.stringify(row)}`);
    for (const [path, screen] of [["/", "home"], ["/novidades", "news"]] as [string, string][]) {
      await navigate(page, base, path, screen);
      const line = page.locator(`.screen[data-screen="${screen}"] .row.news .news-body`, { hasText: words });
      for (let attempt = 0; attempt < 10 && !(await line.first().isVisible()); attempt++) {
        await page.waitForTimeout(4_000);
        await page.reload({ waitUntil: "domcontentloaded" });
        await ready(page, screen);
      }
      await line.first().waitFor({ state: "visible", timeout: 45_000 });
    }
  },
};

export const journeys = [
  home,
  feed,
  pathJourney("communities", () => "/comunidades", () => seed.communityName),
  savedWord,
  pathJourney("search", () => "/buscar"),
  pathJourney("profile", () => `/perfil/${enc(seed.handle)}`, () => seed.name),
  pathJourney("scrapbook", () => `/recados/${enc(seed.handle)}`),
  pathJourney("testimonials", () => `/depoimentos/${enc(seed.handle)}`),
  pathJourney("friends", () => `/amigos/${enc(seed.handle)}`),
  pathJourney("community", () => `/comunidade/${enc(seed.community)}`, () => seed.communityName),
  pathJourney("members", () => `/membros/${enc(seed.community)}`),
  pathJourney("topic", () => `/comunidade/${enc(seed.community)}/topico/${enc(seed.topic)}`, () => seed.topicTitle),
  phoneStrip,
  karmaRows,
];
