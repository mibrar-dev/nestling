#!/usr/bin/env node
// Mochi board renderer (sharp). Run: node render.mjs
import sharp from "sharp";
import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";

const ROOT = "/Users/ibrar/Desktop/infinora.noworkspace/nestling-pip-v2";
const A = path.join(ROOT, "design/pip-v2/A");
const LIGHT = "#FBF7F0", DARK = "#15131F", LILAC = "#7C6CF2", INK = "#1E1B3A";

const art = (p, size) => sharp(path.join(A, p)).resize(size, size).png().toBuffer();
const tmpArt = (p, size) => sharp(p).resize(size, size).png().toBuffer();

function labelOverlay(w, h, texts) {
  // texts: [x, y, size, weight, color, anchor, str]
  const t = texts.map(([x, y, s, wt, c, an, str]) =>
    `<text x="${x}" y="${y}" font-family="Arial, Helvetica, sans-serif" font-size="${s}" font-weight="${wt}" fill="${c}" text-anchor="${an}">${str}</text>`).join("");
  return Buffer.from(`<svg width="${w}" height="${h}" xmlns="http://www.w3.org/2000/svg">${t}</svg>`);
}

function splitTileBase(t) {
  // left half light, right half dark
  return Buffer.from(`<svg width="${t}" height="${t}" xmlns="http://www.w3.org/2000/svg">` +
    `<rect width="${t / 2}" height="${t}" fill="${LIGHT}"/><rect x="${t / 2}" width="${t / 2}" height="${t}" fill="${DARK}"/></svg>`);
}

async function tileWithInset(svgPath, T, artSize, chip = true, tmp = false) {
  const base = sharp(splitTileBase(T)).png().toBuffer();
  const fg = await (tmp ? tmpArt(svgPath, artSize) : art(svgPath, artSize));
  const off = Math.round((T - artSize) / 2);
  const comp = [{ input: fg, left: off, top: off }];
  let out = sharp(await base).composite(comp).png().toBuffer();
  if (chip) {
    const C = 60, small = await (tmp ? tmpArt(svgPath, 48) : art(svgPath, 48));
    const dot = await sharp({ create: { width: C, height: C, channels: 4, background: LILAC } }).png().toBuffer();
    const dotWith = await sharp(dot).composite([{ input: small, left: 6, top: 6 }]).png().toBuffer();
    out = sharp(await out).composite([{ input: dotWith, left: T - C - 6, top: T - C - 6 }]).png().toBuffer();
  }
  return out;
}

// ---------- BOARD_moods ----------
async function boardMoods() {
  const moods = [["idle", 1], ["blink", 2], ["happy", 2], ["eating", 2], ["sleepy", 2], ["surprised", 2], ["proud", 2]];
  const names = ["idle", "blink", "happy", "eating", "sleepy", "wow", "proud"];
  const stages = [1, 2, 3, 4];
  const stageNames = ["S1 egg", "S2 hatch", "S3 fledgling", "S4 songbird"];
  const T = 230, GAP = 14, LW = 170, TOP = 122, ROWH = T + 8;
  const W = LW + GAP + moods.length * (T + GAP) + GAP;
  const H = TOP + stages.length * (ROWH + GAP) + 44;
  const base = await sharp({ create: { width: W, height: H, channels: 4, background: LIGHT } }).png().toBuffer();
  const comp = [];
  for (let c = 0; c < moods.length; c++) {
    const [m, n] = moods[c];
    for (let r = 0; r < stages.length; r++) {
      const left = LW + GAP + c * (T + GAP), top = TOP + r * (ROWH + GAP);
      const buf = await tileWithInset(`poses/s${stages[r]}_${m}_${n}.svg`, T, 200);
      comp.push({ input: buf, left, top });
    }
  }
  const texts = [
    [24, 40, 34, "bold", INK, "start", "MOCHI A — moods x stages (peak poses)"],
    [24, 82, 20, "normal", "#4A4668", "start", "tiles split light/dark - lilac chip = 48px proof - stroke 6"],
    ...names.map((n, c) => [LW + GAP + c * (T + GAP) + T / 2, TOP - 14, 22, "bold", INK, "middle", n]),
    ...stageNames.map((n, r) => [LW - 16, TOP + r * (ROWH + GAP) + T / 2, 22, "bold", INK, "end", n]),
    [24, H - 14, 17, "normal", "#6E6A8A", "start", "100% original art - Rive-ready contract ids - no text in art"],
  ];
  comp.push({ input: labelOverlay(W, H, texts), left: 0, top: 0 });
  const out = path.join(A, "BOARD_moods.png");
  await sharp(base).composite(comp).png().toFile(out);
  console.log("wrote", out);
}

// ---------- BOARD_sequences (fledgling) ----------
async function boardSeq() {
  const rows = [
    ["happy", [1, 2, 3], ["squash", "JUMP +18", "land"]],
    ["eating", [1, 2, 3], ["berry drops", "peck", "crunch"]],
    ["sleepy", [1, 2, 3], ["droop", "eyes shut", "deep Zzz"]],
    ["surprised", [1, 2, 3], ["lean", "FLARE + !", "settle"]],
    ["proud", [1, 2], ["chest out", "wink"]],
  ];
  const T = 220, GAP = 14, LW = 180, TOP = 122, ROWH = T + 36;
  const W = LW + GAP + 3 * (T + GAP) + GAP;
  const H = TOP + rows.length * (ROWH + GAP) + 44;
  const base = await sharp({ create: { width: W, height: H, channels: 4, background: LIGHT } }).png().toBuffer();
  // build tiles first (async), then labels
  const tiles = [];
  rows.forEach(([m, ns], r) => {
    const top = TOP + r * (ROWH + GAP);
    ns.forEach((n, c) => {
      const left = LW + GAP + c * (T + GAP);
      tiles.push(tileWithInset(`poses/s3_${m}_${n}.svg`, T, 192).then((buf) => ({ input: buf, left, top })));
    });
  });
  const done = await Promise.all(tiles);
  const texts = [
    [24, 40, 34, "bold", INK, "start", "MOCHI A — fledgling sequences"],
    [24, 82, 20, "normal", "#4A4668", "start", "anticipation -> peak -> settle - left to right"],
    ...rows.map(([m, ns, caps], r) => [LW - 16, TOP + r * (ROWH + GAP) + T / 2, 24, "bold", INK, "end", m]),
  ];
  // captions under each frame
  rows.forEach(([m, ns, caps], r) => {
    const top = TOP + r * (ROWH + GAP);
    caps.forEach((cap, c) => {
      const left = LW + GAP + c * (T + GAP) + T / 2;
      texts.push([left, top + T + 26, 18, "normal", "#4A4668", "middle", `${c + 1}. ${cap}`]);
    });
  });
  const out = path.join(A, "BOARD_sequences.png");
  await sharp(base).composite([...done, { input: labelOverlay(W, H, texts), left: 0, top: 0 }]).png().toFile(out);
  console.log("wrote", out);
}

// ---------- BOARD_evolve (s1 -> s2 -> s3 -> s4) ----------
async function boardEvolve() {
  const rows = [
    ["s1 -> s2", ["poses/s1_happy_2.svg", "evolve/evolve_s1_to_s2_1.svg", "evolve/evolve_s1_to_s2_2.svg"]],
    ["s2 -> s3", ["poses/s2_happy_2.svg", "evolve/evolve_s2_to_s3_1.svg", "evolve/evolve_s2_to_s3_2.svg"]],
    ["s3 -> s4", ["poses/s3_happy_2.svg", "evolve/evolve_s3_to_s4_1.svg", "evolve/evolve_s3_to_s4_2.svg"]],
  ];
  const caps = ["stage N peak", "glow charge", "stage N+1 reveal"];
  const T = 230, GAP = 14, LW = 150, TOP = 122, ROWH = T + 36;
  const W = LW + GAP + 3 * (T + GAP) + GAP;
  const H = TOP + rows.length * (ROWH + GAP) + 44;
  const base = await sharp({ create: { width: W, height: H, channels: 4, background: LIGHT } }).png().toBuffer();
  const jobs = [];
  rows.forEach(([label, files], r) => {
    const top = TOP + r * (ROWH + GAP);
    files.forEach((f, c) => {
      const left = LW + GAP + c * (T + GAP);
      jobs.push(tileWithInset(f, T, 200).then((buf) => ({ input: buf, left, top })));
    });
  });
  const done = await Promise.all(jobs);
  const texts = [
    [24, 40, 34, "bold", INK, "start", "MOCHI A — evolve sequence"],
    [24, 82, 20, "normal", "#4A4668", "start", "peak pose -> glow + spin/pop -> next stage appears"],
    ...rows.map(([label], r) => [LW - 16, TOP + r * (ROWH + GAP) + T / 2, 24, "bold", INK, "end", label]),
    ...caps.map((c, i) => [LW + GAP + i * (T + GAP) + T / 2, TOP - 14, 22, "bold", INK, "middle", c]),
  ];
  rows.forEach(([label, files], r) => {
    const top = TOP + r * (ROWH + GAP);
    caps.forEach((cap, c) => {
      texts.push([LW + GAP + c * (T + GAP) + T / 2, top + T + 26, 18, "normal", "#4A4668", "middle", `${c + 1}. ${cap}`]);
    });
  });
  const out = path.join(A, "BOARD_evolve.png");
  await sharp(base).composite([...done, { input: labelOverlay(W, H, texts), left: 0, top: 0 }]).png().toFile(out);
  console.log("wrote", out);
}

// ---------- BOARD_custom (skins x accessories, s3 idle) ----------
async function boardCustom() {
  // generate combos to tmp
  const tmp = "/tmp/mochi_custom";
  fs.mkdirSync(tmp, { recursive: true });
  execSync(`python3 generate_custom.py "${tmp}"`, { cwd: path.dirname(new URL(import.meta.url).pathname) });
  const skinsL = ["sunny", "berry", "sky", "mint"];
  const accs = ["none", "bow", "cap", "scarf", "glasses"];
  const T = 200, GAP = 14, LW = 130, TOP = 122;
  const W = LW + GAP + accs.length * (T + GAP) + GAP;
  const H = TOP + skinsL.length * (T + 8 + GAP) + 44;
  const base = await sharp({ create: { width: W, height: H, channels: 4, background: LIGHT } }).png().toBuffer();
  const jobs = [];
  skinsL.forEach((sk, r) => {
    const top = TOP + r * (T + 8 + GAP);
    accs.forEach((ac, c) => {
      const left = LW + GAP + c * (T + GAP);
      jobs.push(tileWithInset(path.join(tmp, `s3_idle_${sk}_${ac}.svg`), T, 172, true, true).then((buf) => ({ input: buf, left, top })));
    });
  });
  const done = await Promise.all(jobs);
  const texts = [
    [24, 40, 34, "bold", INK, "start", "MOCHI A — skins x accessories (fledgling idle)"],
    [24, 82, 20, "normal", "#4A4668", "start", "beak/feet stay peach - ink stays ink"],
    ...accs.map((a, c) => [LW + GAP + c * (T + GAP) + T / 2, TOP - 14, 22, "bold", INK, "middle", a]),
    ...skinsL.map((s, r) => [LW - 16, TOP + r * (T + 8 + GAP) + T / 2, 22, "bold", INK, "end", s]),
  ];
  const out = path.join(A, "BOARD_custom.png");
  await sharp(base).composite([...done, { input: labelOverlay(W, H, texts), left: 0, top: 0 }]).png().toFile(out);
  console.log("wrote", out);
}

await boardMoods();
await boardSeq();
await boardCustom();
await boardEvolve();
