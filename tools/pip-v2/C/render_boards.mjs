#!/usr/bin/env node
// Storybook C boards — node + sharp. 100% original art tiles.
import fs from "node:fs";
import path from "node:path";
import sharp from "sharp";

const ROOT = "/Users/ibrar/Desktop/infinora.noworkspace/nestling-pip-v2";
const C = path.join(ROOT, "design/pip-v2/C");
const LIGHT = { r: 251, g: 247, b: 240 };
const DARK = { r: 21, g: 19, b: 31 };
const LILAC = { r: 124, g: 108, b: 242 };
const INK = { r: 30, g: 27, b: 58 };

async function raster(svgPath, size) {
  const buf = await sharp(svgPath, { density: 300 }).resize(size, size, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
  return buf;
}

async function splitTile(svgPath, T) {
  // base: left half light, right half dark
  const left = await sharp({ create: { width: T / 2, height: T, channels: 4, background: { ...LIGHT, alpha: 1 } } }).png().toBuffer();
  const right = await sharp({ create: { width: T - T / 2, height: T, channels: 4, background: { ...DARK, alpha: 1 } } }).png().toBuffer();
  const base = await sharp({ create: { width: T, height: T, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{ input: left, left: 0, top: 0 }, { input: right, left: T / 2, top: 0 }]).png().toBuffer();
  const art = await raster(svgPath, T);
  // 48px inset on lilac chip 56px bottom-right
  const small = await raster(svgPath, 48);
  const chip = await sharp({ create: { width: 58, height: 58, channels: 4, background: { ...LILAC, alpha: 1 } } }).png().toBuffer();
  const chipWith = await sharp(chip).composite([{ input: small, left: 5, top: 5 }]).png().toBuffer();
  const tile = await sharp(base).composite([
    { input: art, left: 0, top: 0 },
    { input: chipWith, left: T - 62, top: T - 62 },
  ]).png().toBuffer();
  return tile;
}

async function label(text, w, h = 44, fg = "#FBF7F0", bg = "#1E1B3A", size = 24) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><rect width="${w}" height="${h}" fill="${bg}"/><text x="12" y="${h / 2 + size * 0.35}" font-family="Arial,Helvetica,sans-serif" font-size="${size}" font-weight="bold" fill="${fg}">${text}</text></svg>`;
  return sharp(Buffer.from(svg)).png().toBuffer();
}

async function board_moods() {
  const T = 240, LH = 150, TOP = 120;
  const moods = [
    ["idle", "s_idle_2"], ["blink", "s_blink_2"], ["happy", "s_happy_2"], ["eating", "s_eating_2"],
    ["sleepy", "s_sleepy_2"], ["surprised", "s_surprised_2"], ["proud", "s_proud_2"],
  ];
  const W = LH + moods.length * (T + 8) + 8, H = TOP + 4 * (T + 44) + 44;
  const canvas = await sharp({ create: { width: W, height: H, channels: 4, background: { ...LIGHT, alpha: 1 } } }).png().toBuffer();
  const comps = [];
  comps.push({ input: await label("PIP V2 C · STORYBOOK — moods (peak pose · split light/dark + 48px chip)", W, TOP, "#FBF7F0", "#1E1B3A", 26), left: 0, top: 0 });
  for (let j = 0; j < moods.length; j++) {
    const x = LH + 8 + j * (T + 8);
    comps.push({ input: await label(moods[j][0], T, 40, "#1E1B3A", "#FBF7F0", 26), left: x, top: TOP - 44 });
  }
  const stageNames = ["ST1 egg", "ST2 hatch", "ST3 fledg", "ST4 song"];
  for (let s = 1; s <= 4; s++) {
    const y = TOP + (s - 1) * (T + 44);
    comps.push({ input: await label(stageNames[s - 1], LH - 16, T, "#1E1B3A", s % 2 ? "#F3EEE5" : "#FBF7F0", 26), left: 8, top: y });
    for (let j = 0; j < moods.length; j++) {
      const key = moods[j][1].replace("s_", `s${s}_`);
      const p = path.join(C, "poses", `${key}.svg`);
      const tile = await splitTile(p, T);
      comps.push({ input: tile, left: LH + 8 + j * (T + 8), top: y });
    }
  }
  comps.push({ input: await label("split tile = light #FBF7F0 / dark #15131F · lilac chip = 48px proof · stroke 5 · no text/gradients in art", W, 44, "#6E6A8A", "#FBF7F0", 20), left: 0, top: H - 44 });
  const out = path.join(C, "BOARD_moods.png");
  await sharp(canvas).composite(comps).png().toFile(out);
  console.log("wrote", out);
}

async function board_sequences() {
  const T = 220;
  const rows = [
    ["happy", ["s3_happy_1", "s3_happy_2", "s3_happy_3"]],
    ["eating", ["s3_eating_1", "s3_eating_2", "s3_eating_3"]],
    ["sleepy", ["s3_sleepy_1", "s3_sleepy_2", "s3_sleepy_3"]],
    ["surprised", ["s3_surprised_1", "s3_surprised_2", "s3_surprised_3"]],
    ["proud", ["s3_proud_1", "s3_proud_2", "s3_proud_3"]],
  ];
  const LH = 170, TOP = 120;
  const W = LH + 3 * (T + 8) + 8, H = TOP + rows.length * (T + 44) + 44;
  const canvas = await sharp({ create: { width: W, height: H, channels: 4, background: { ...LIGHT, alpha: 1 } } }).png().toBuffer();
  const comps = [{ input: await label("PIP V2 C · STORYBOOK — fledgling sequences", W, TOP, "#FBF7F0", "#1E1B3A", 26), left: 0, top: 0 }];
  for (let i = 0; i < rows.length; i++) {
    const y = TOP + i * (T + 44);
    comps.push({ input: await label(rows[i][0], LH - 16, T, "#1E1B3A", i % 2 ? "#F3EEE5" : "#FBF7F0", 26), left: 8, top: y });
    for (let j = 0; j < 3; j++) {
      const tile = await splitTile(path.join(C, "poses", `${rows[i][1][j]}.svg`), T);
      comps.push({ input: tile, left: LH + 8 + j * (T + 8), top: y });
    }
  }
  comps.push({ input: await label("fledgling s3 · happy jump / eating peck / sleepy Zzz / surprised ! / proud wink", W, 44, "#6E6A8A", "#FBF7F0", 20), left: 0, top: H - 44 });
  const out = path.join(C, "BOARD_sequences.png");
  await sharp(canvas).composite(comps).png().toFile(out);
  console.log("wrote", out);
}

async function board_custom() {
  const T = 220, LH = 150, TOP = 120, STRIP_T = 150, GAP = 10;
  const skins = ["sunny", "berry", "sky", "mint"];
  const accs = ["bow", "cap", "scarf", "glasses"];
  // grid A: skins (idle+happy) then grid B: accessories per stage? Spec: skins × accessories grid.
  // 4 rows (skins) × 4 cols (accessories) on stage-3 idle base, tinted per skin.
  const W = Math.max(LH + 4 * (T + 8), 9 * (STRIP_T + GAP)) + 28;
  const stripCols = 8; // 4 idle + 4 happy skins
  const evoCols = 9;   // 9 evolve frames
  const H = TOP + 4 * (T + 44) + 8 + 44 + (STRIP_T + 30) + 12 + (STRIP_T + 30) + 12;
  const canvas = await sharp({ create: { width: W, height: H, channels: 4, background: { ...LIGHT, alpha: 1 } } }).png().toBuffer();
  const comps = [{ input: await label("PIP V2 C · STORYBOOK — skins × accessories (stage-3 idle base)", W, TOP, "#FBF7F0", "#1E1B3A", 26), left: 0, top: 0 }];
  for (let j = 0; j < 4; j++) comps.push({ input: await label(accs[j], T, 40, "#1E1B3A", "#FBF7F0", 26), left: LH + 8 + j * (T + 8), top: TOP - 44 });
  // need combined skin+accessory renders: generate on the fly from poses? use gen combos via sharp tint? No — re-render via python helper would be ideal.
  // Instead: check pre-rendered combo files; if missing, fall back to accessory tile.
  for (let i = 0; i < 4; i++) {
    const y = TOP + i * (T + 44);
    comps.push({ input: await label(skins[i], LH - 16, T, "#1E1B3A", i % 2 ? "#F3EEE5" : "#FBF7F0", 26), left: 8, top: y });
    for (let j = 0; j < 4; j++) {
      const combo = path.join(ROOT, "tools/pip-v2/C/work_combos", `_combo_s3_${skins[i]}_${accs[j]}.svg`);
      const fb = path.join(C, "accessories", `s3_idle_${accs[j]}.svg`);
      const src = fs.existsSync(combo) ? combo : fb;
      const tile = await splitTile(src, T);
      comps.push({ input: tile, left: LH + 8 + j * (T + 8), top: y });
    }
  }
  // bottom: skins row, then evolve row — each with its own label, no overlap
  const skinStrip = ["skins/s3_idle_sunny.svg","skins/s3_idle_berry.svg","skins/s3_idle_sky.svg","skins/s3_idle_mint.svg",
    "skins/s3_happy_sunny.svg","skins/s3_happy_berry.svg","skins/s3_happy_sky.svg","skins/s3_happy_mint.svg"];
  const evos = ["evolve/s1s2_1.svg","evolve/s1s2_2.svg","evolve/s1s2_3.svg",
    "evolve/s2s3_1.svg","evolve/s2s3_2.svg","evolve/s2s3_3.svg",
    "evolve/s3s4_1.svg","evolve/s3s4_2.svg","evolve/s3s4_3.svg"];
  let yy = TOP + 4 * (T + 44) + 8;
  comps.push({ input: await label("skins: idle / happy (sunny berry sky mint)", W, 40, "#FBF7F0", "#1E1B3A", 22), left: 0, top: yy });
  yy += 40 + 6;
  for (let k = 0; k < skinStrip.length; k++) {
    const t = await splitTile(path.join(C, skinStrip[k]), STRIP_T);
    comps.push({ input: t, left: 8 + k * (STRIP_T + GAP), top: yy });
  }
  yy += STRIP_T + 30 + 12;
  comps.push({ input: await label("evolve: s1→s2 · s2→s3 · s3→s4 (glow / pop / appear)", W, 40, "#FBF7F0", "#1E1B3A", 22), left: 0, top: yy });
  yy += 40 + 6;
  for (let k = 0; k < evos.length; k++) {
    const t = await splitTile(path.join(C, evos[k]), STRIP_T);
    comps.push({ input: t, left: 8 + k * (STRIP_T + GAP), top: yy });
  }
  const out = path.join(C, "BOARD_custom.png");
  await sharp(canvas).composite(comps).png().toFile(out);
  console.log("wrote", out);
}

await board_moods();
await board_sequences();
await board_custom();
