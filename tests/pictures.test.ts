// The demo network's pictures: the seed names only files that exist under
// pictures/, each named by its own sha256; and no file under pictures/ is
// unnamed by the seed or the manifest, so nothing ships that nothing uses.
import { assert, assertEquals } from "jsr:@std/assert@1";

const here = new URL("..", import.meta.url);
const read = (rel: string) => Deno.readTextFile(new URL(rel, here));

async function sha256Hex(bytes: Uint8Array<ArrayBuffer>): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.test("pictures: every seeded path is a file named by its sha256", async () => {
  const seed = await read("services/database/sql/020_demo_network.sql");
  const named = [...seed.matchAll(/'\/pictures\/([0-9a-f]{64}\.(?:jpg|png|webp))'/g)].map((m) => m[1]);
  assert(named.length >= 25, `the seed names ${named.length} pictures`);
  for (const file of new Set(named)) {
    const bytes = await Deno.readFile(new URL(`pictures/${file}`, here));
    assertEquals(await sha256Hex(bytes as Uint8Array<ArrayBuffer>), file.slice(0, 64), `${file} is named by its sha256`);
  }
});

Deno.test("pictures: every file under pictures/ is named by the seed and the manifest", async () => {
  const seed = await read("services/database/sql/020_demo_network.sql");
  const manifest = JSON.parse(await read("assets/manifest.json")) as Record<string, { file: string; sha256: string; source: string; license: string }>;
  const files = new Set<string>();
  for await (const entry of Deno.readDir(new URL("pictures/", here))) if (entry.isFile) files.add(entry.name);
  for (const file of files) {
    assert(seed.includes(`/pictures/${file}`), `${file} is unnamed by the seed`);
    assert(Object.values(manifest).some((v) => v.file === file), `${file} is unnamed by the manifest`);
  }
  for (const v of Object.values(manifest)) {
    assert(files.has(v.file), `the manifest names ${v.file}, which is not under pictures/`);
    assertEquals(v.file.slice(0, 64), v.sha256);
    assert(v.license.length > 0 && v.source.startsWith("https://"), `${v.file} carries its source and license`);
  }
});

Deno.test("pictures: the two copies of the seed agree", async () => {
  assertEquals(await read("services/database/migrations/020_demo_network.sql"), await read("services/database/sql/020_demo_network.sql"));
});

Deno.test("pictures: the credits screen and both catalogues name every Commons author, license and page", async () => {
  const manifest = JSON.parse(await read("assets/manifest.json")) as Record<string, { file: string; source: string; license: string; author?: string; page?: string; deed?: string }>;
  const credits = await read("shell/screens/credits.html");
  const catalogues = await Promise.all(["messages/pt-BR.json", "messages/en.json"].map((f) => read(f).then((t) => JSON.parse(t) as Record<string, string>)));
  const commons = Object.values(manifest).filter((v) => v.source.includes("wikimedia"));
  assert(commons.length >= 10);
  for (const v of commons) {
    assert(v.author && v.page && v.deed, `${v.file} carries its author, page and deed`);
    assert(credits.includes(`href="${v.page.replaceAll("&", "&amp;")}"`), `the credits link ${v.page}`);
    assert(credits.includes(`href="${v.deed}"`), `the credits link the deed ${v.deed}`);
    for (const c of catalogues) {
      assert(Object.values(c).some((s) => s.includes(v.author!)), `a catalogue names ${v.author}`);
      assert(Object.values(c).some((s) => s === v.license), `a catalogue names ${v.license}`);
    }
  }
});

// The ladder's pages embed images under ir/ and journal/; a release serves only
// what the program lists, so every image a page embeds is a listed document.
Deno.test("the ladder serves every image the ir and the journal embed", async () => {
  const served = new Set<string>();
  for (const m of (await Deno.readTextFile(new URL("../bayt.json", import.meta.url))).matchAll(/"\/srv\/docs\/([^"]+)"/g)) served.add(m[1]);
  for (const page of ["ir.html", "journal.html"]) {
    const html = await Deno.readTextFile(new URL(`../${page}`, import.meta.url));
    const missing = [...new Set([...html.matchAll(/src="((?:ir|journal)\/[^"]+)"/g)].map((m) => m[1]))].filter((f) => !served.has(f));
    if (missing.length > 0) throw new Error(`${page} embeds images the ladder does not serve: ${missing.join(", ")}`);
  }
});
