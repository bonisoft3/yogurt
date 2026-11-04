// The two catalogues as one text: the terminal's i18n check holds the keys and
// the placeholders; this holds what it cannot — a value left untranslated and a
// count message missing a plural arm.
import { assert } from "jsr:@std/assert@1";

const read = async (locale: string) => JSON.parse(await Deno.readTextFile(new URL(`../messages/${locale}.json`, import.meta.url))) as Record<string, string>;
const pt = await read("pt-BR");
const en = await read("en");

// Words both languages spell the same, and glyph strings.
const SHARED = new Set(["brand_name", "cat_humor", "sexy_label"]);
const glyphs = (s: string) => !/[a-z]/i.test(s);
const proper = (k: string) => /^credit_(title|author|license)_\d+$/.test(k);

Deno.test("no message is left in the other language", () => {
  const same = Object.keys(pt).filter((k) => pt[k] === en[k] && !SHARED.has(k) && !glyphs(pt[k]) && !proper(k));
  assert(same.length === 0, `identical in both catalogues: ${same.join(", ")}`);
});

Deno.test("every count message has a singular, a Portuguese many and an other arm", () => {
  const counts = Object.keys(pt).filter((k) => /plural/.test(pt[k]));
  assert(counts.length >= 4, `the catalogue carries ${counts.length} plural messages`);
  for (const k of counts) {
    for (const arm of ["one {", "many {", "other {"]) assert(pt[k].includes(arm), `${k} lacks the ${arm.trim()} arm in pt-BR: ${pt[k]}`);
    for (const arm of ["one {", "other {"]) assert(en[k].includes(arm), `${k} lacks the ${arm.trim()} arm in en: ${en[k]}`);
    assert(/plural/.test(en[k]), `${k} is a plural in pt-BR and a plain string in en`);
  }
});
