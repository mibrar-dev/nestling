#!/usr/bin/env node
/* ==========================================================================
   Pip v2 · Bolt — board renderer (node + sharp)
     BOARD_moods.png     rows = stages, cols = moods, peak pose;
                          each tile split light/dark + a 48px lilac chip
     BOARD_sequences.png happy / eating / sleepy / surprised / proud sequences (fledgling)
     BOARD_custom.png    skins × accessories grid
   ========================================================================== */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';
import { svg, SKINS, STAGES, INK } from './rig.mjs';
import { allPoses } from './poses.mjs';
import { svgWithAccessory } from './accessories.mjs';
import { evolveSvg, EVOLVE_PAIRS } from './evolve.mjs';
import { PEAK } from './idle.mjs';

const ROOT = path.resolve(import.meta.dirname, '../../..');
const OUT = path.join(ROOT, 'design/pip-v2/B');
const POSES = path.join(OUT, 'poses');

const LIGHT = '#FBF7F0', DARK = '#15131F', CHIP = '#7C6CF2';
const INKHEX = '#1E1B3A';
const POSES_BY = {};
for (const p of allPoses()) POSES_BY[`${p.stage}_${p.mood}_${p.n}`] = p;

/* ---------- tiny SVG→png with an optional split background ---------- */
async function render(svgText, size, { split = false } = {}) {
  const art = await sharp(Buffer.from(svgText), { density: 260 })
    .resize(size, size, { fit: 'fill', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png().toBuffer();
  if (!split) return art;
  const h = Math.round(size / 2);
  return sharp({
    create: { width: size, height: size, channels: 4, background: LIGHT },
  })
    .composite([
      { input: { create: { width: size, height: h, channels: 4, background: DARK } }, left: 0, top: h },
      { input: art, left: 0, top: 0 },
    ]).png().toBuffer();
}
async function chip(svgText, px = 48) {
  const art = await sharp(Buffer.from(svgText), { density: 260 })
    .resize(px - 8, px - 8, { fit: 'fill', background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
  return sharp({ create: { width: px, height: px, channels: 4, background: CHIP } })
    .composite([{ input: art, left: 4, top: 4 }]).png().toBuffer();
}

/* ---------- text / chrome via SVG (rendered by sharp) ---------- */
const FONT = 'Menlo,DejaVu Sans Mono,monospace';
function label(text, w, h, { size = 13, fill = INKHEX, bg = null, bold = false, anchor = 'start' } = {}) {
  const bgc = bg ? `<rect width="${w}" height="${h}" fill="${bg}"/>` : '';
  const ax = anchor === 'middle' ? `x="${w / 2}" text-anchor="middle"` : `x="${6}"`;
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${bgc}`
    + `<text ${ax} y="${Math.round(h / 2 + size * 0.35)}" font-family="${FONT}" font-size="${size}"`
    + `${bold ? ' font-weight="700"' : ''} fill="${fill}">${String(text).replace(/[<>&]/g, '')}</text></svg>`);
}
const blank = (w, h, bg) => sharp({ create: { width: w, height: h, channels: 4, background: bg } }).png().toBuffer();

async function compose(width, height, layers, file) {
  await sharp({ create: { width, height, channels: 4, background: '#FFFFFF' } })
    .composite(layers).png().toFile(file);
  console.log('board', path.basename(file), `${width}x${height}`);
}

/* ══════════════════════ BOARD 1 · MOODS ══════════════════════ */
async function boardMoods() {
  const MOODS = ['idle', 'blink', 'happy', 'eating', 'sleepy', 'surprised', 'proud'];
  const TILE = 210, GAP = 8, LABW = 150, HEAD = 116, LABEL = 22;
  const rows = [1, 2, 3, 4];
  const W = LABW + MOODS.length * (TILE + GAP) + GAP;
  const H = HEAD + rows.length * (TILE + LABEL + GAP) + 8;
  const L = [];

  L.push({ input: await blank(W, HEAD, INKHEX), left: 0, top: 0 });
  L.push({ input: label('PIP v2 · B · BOLT — mood board', W, 40, { size: 26, fill: '#FFFFFF', bg: null, bold: true }), left: 0, top: 8 });
  L.push({ input: label('peak key pose per mood · every tile split light / dark · lilac chip = 48 px proof', W, 24, { size: 14, fill: '#C9C4DC' }), left: 0, top: 48 });

  // column headers
  MOODS.forEach((m, c) => {
    const x = LABW + GAP + c * (TILE + GAP);
    L.push({ input: label(m.toUpperCase(), TILE, 24, { size: 14, fill: INKHEX, bg: '#EDE8F8', bold: true, anchor: 'middle' }), left: x, top: HEAD - 30 });
  });

  for (let r = 0; r < rows.length; r++) {
    const stage = rows[r];
    const y = HEAD + r * (TILE + LABEL + GAP);
    // row label
    L.push({ input: await blank(LABW, TILE, '#F3EEE5'), left: 0, top: y });
    L.push({ input: label(`STAGE ${stage}`, LABW, 30, { size: 17, fill: INKHEX, bold: true }), left: 0, top: y + 12 });
    L.push({ input: label(STAGES[stage].name.toUpperCase(), LABW, 22, { size: 13, fill: '#5A5A80' }), left: 0, top: y + 40 });
    L.push({ input: label('full-body acting,', LABW, 20, { size: 11, fill: '#8A86A8' }), left: 0, top: y + 66 });
    L.push({ input: label('one clear idea', LABW, 20, { size: 11, fill: '#8A86A8' }), left: 0, top: y + 82 });

    for (let c = 0; c < MOODS.length; c++) {
      const mood = MOODS[c];
      const frame = PEAK[stage][mood];
      const key = `${stage}_${mood}_${frame}`;
      const p = POSES_BY[key];
      const svgText = svg(p);
      const x = LABW + GAP + c * (TILE + GAP);
      L.push({ input: await render(svgText, TILE, { split: true }), left: x, top: y });
      L.push({ input: await chip(svgText), left: x + 5, top: y + 5 });
      L.push({ input: label(`s${stage} ${mood} f${frame}`, TILE, LABEL, { size: 10, fill: '#6B6790', bg: '#EDE8F8' }), left: x, top: y + TILE });
    }
  }
  L.push({ input: label('every mood must be identifiable at 48 px without labels · no gradients · one soft highlight · 8 px ink', W, 26, { size: 12, fill: '#6E6A8A' }), left: 0, top: H - 26 });
  await compose(W, H, L, path.join(OUT, 'BOARD_moods.png'));
}

/* ══════════════════════ BOARD 2 · SEQUENCES ══════════════════════ */
async function boardSequences() {
  const SEQS = [
    { mood: 'happy', label: 'HAPPY', beats: 'anticipation squash → jump ≥18 px, wings up, sparkles → land squash' },
    { mood: 'eating', label: 'EATING', beats: 'seed in → 3 pecks, beak opens/closes, cheek puff, crumbs → satisfied' },
    { mood: 'sleepy', label: 'SLEEPY', beats: 'lids droop → head nods/droops → deep breathing, Zzz rising' },
    { mood: 'surprised', label: 'SURPRISED', beats: 'jolt → jump-back, wide eyes, beak “o”, wings flare, “!”' },
    { mood: 'proud', label: 'PROUD', beats: 'chest out, chin up → wing on hip, wink, chest sparkle' },
  ];
  const FR = 5;
  const TILE = 190, GAP = 8, LABEL = 22, HEAD = 100, ROWL = 128;
  const W = ROWL + FR * (TILE + GAP) + GAP;
  const H = HEAD + SEQS.length * (TILE + LABEL + GAP) + 8;
  const L = [];
  L.push({ input: await blank(W, HEAD, INKHEX), left: 0, top: 0 });
  L.push({ input: label('PIP v2 · B · BOLT — pose sequences (stage 3 fledgling)', W, 40, { size: 26, fill: '#FFFFFF', bold: true }), left: 0, top: 8 });
  L.push({ input: label('anticipation → peak → settle · light/dark split per tile · 48 px chip · contract beats under each row', W, 24, { size: 14, fill: '#C9C4DC' }), left: 0, top: 48 });

  for (let r = 0; r < SEQS.length; r++) {
    const s = SEQS[r];
    const y = HEAD + r * (TILE + LABEL + GAP);
    const frames = [];
    for (let f = 1; f <= FR; f++) { const p = POSES_BY[`3_${s.mood}_${f}`]; if (p) frames.push(p); }
    L.push({ input: await blank(ROWL, TILE, '#F3EEE5'), left: 0, top: y });
    L.push({ input: label(s.label, ROWL, 28, { size: 17, fill: INKHEX, bold: true }), left: 0, top: y + 10 });
    // wrap beats text
    const words = s.beats.split(' '); let line = ''; let ly = y + 40;
    for (const w of words) {
      if ((line + w).length > 20) { L.push({ input: label(line, ROWL, 18, { size: 10.5, fill: '#6B6790' }), left: 0, top: ly }); ly += 15; line = w + ' '; }
      else line += w + ' ';
    }
    if (line.trim()) L.push({ input: label(line.trim(), ROWL, 18, { size: 10.5, fill: '#6B6790' }), left: 0, top: ly });

    for (let i = 0; i < frames.length; i++) {
      const p = frames[i];
      const svgText = svg(p);
      const x = ROWL + GAP + i * (TILE + GAP);
      L.push({ input: await render(svgText, TILE, { split: true }), left: x, top: y });
      L.push({ input: await chip(svgText), left: x + 5, top: y + 5 });
      L.push({ input: label(`f${p.n} · ${p.note ?? ''}`, TILE, LABEL, { size: 10, fill: '#6B6790', bg: '#EDE8F8' }), left: x, top: y + TILE });
    }
  }
  L.push({ input: label('frames are named s3_{mood}_{n}.svg · Rive-ready groups, one shared rig', W, 26, { size: 12, fill: '#6E6A8A' }), left: 0, top: H - 26 });
  await compose(W, H, L, path.join(OUT, 'BOARD_sequences.png'));
}

/* ══════════════════════ BOARD 3 · CUSTOM ══════════════════════ */
async function boardCustom() {
  const skins = Object.keys(SKINS);
  const accs = ['none', 'bow', 'cap', 'scarf', 'glasses'];
  const CELL = 168, GAP = 8, LABEL = 20, HEAD = 104, COLL = 104;
  const W = COLL + skins.length * (CELL + GAP) + GAP;
  const rowsN = accs.length * 4;
  const H = HEAD + rowsN * (CELL + LABEL + GAP) + 8;
  const L = [];
  L.push({ input: await blank(W, HEAD, INKHEX), left: 0, top: 0 });
  L.push({ input: label('PIP v2 · B · BOLT — customisation (skin × accessory × stage)', W, 40, { size: 26, fill: '#FFFFFF', bold: true }), left: 0, top: 8 });
  L.push({ input: label('4 launch skins × 5 accessory states fitted on every stage · idle pose · light/dark split · 48 px chip', W, 24, { size: 14, fill: '#C9C4DC' }), left: 0, top: 48 });

  for (let c = 0; c < skins.length; c++) {
    const sk = skins[c];
    const x = COLL + GAP + c * (CELL + GAP);
    L.push({ input: label(sk.toUpperCase(), CELL, 24, { size: 14, fill: INKHEX, bg: '#EDE8F8', bold: true, anchor: 'middle' }), left: x, top: HEAD - 30 });
    L.push({ input: await blank(CELL, 6, SKINS[sk].body), left: x, top: HEAD - 4 });
  }

  let y = HEAD;
  for (const acc of accs) {
    for (const stage of [1, 2, 3, 4]) {
      L.push({ input: await blank(COLL, CELL, '#F3EEE5'), left: 0, top: y });
      L.push({ input: label(acc === 'none' ? 'NONE' : acc.toUpperCase(), COLL, 24, { size: 14, fill: INKHEX, bold: true }), left: 0, top: y + CELL / 2 - 26 });
      L.push({ input: label(`stage ${stage}`, COLL, 20, { size: 11, fill: '#6B6790' }), left: 0, top: y + CELL / 2 - 2 });
      for (let c = 0; c < skins.length; c++) {
        const sk = skins[c];
        const svgText = svgWithAccessory(acc, stage, sk, POSES_BY[`${stage}_idle_1`]);
        const x = COLL + GAP + c * (CELL + GAP);
        L.push({ input: await render(svgText, CELL, { split: true }), left: x, top: y });
        L.push({ input: await chip(svgText), left: x + 5, top: y + 5 });
        L.push({ input: label(`s${stage} ${sk} ${acc}`, CELL, LABEL, { size: 9, fill: '#6B6790', bg: '#EDE8F8' }), left: x, top: y + CELL });
      }
      y += CELL + LABEL + GAP;
    }
  }
  L.push({ input: label('skins recolour body / belly / wing; beak + feet stay peach; ink stays ink · accessories reuse the same rig', W, 26, { size: 12, fill: '#6E6A8A' }), left: 0, top: H - 26 });
  await compose(W, H, L, path.join(OUT, 'BOARD_custom.png'));
}

/* ══════════════════════ BOARD 4 · EVOLVE (bonus) ══════════════════════ */
async function boardEvolve() {
  const CELL = 180, GAP = 8, LABEL = 20, HEAD = 104, ROWL = 108;
  const W = ROWL + 4 * (CELL + GAP) + GAP;
  const H = HEAD + EVOLVE_PAIRS.length * (CELL + LABEL + GAP) + 8;
  const L = [];
  L.push({ input: await blank(W, HEAD, INKHEX), left: 0, top: 0 });
  L.push({ input: label('PIP v2 · B · BOLT — evolve sequences (glow → pop → new stage)', W, 40, { size: 26, fill: '#FFFFFF', bold: true }), left: 0, top: 8 });
  L.push({ input: label('s1→s2 · s2→s3 · s3→s4 · glow gathers → shell bursts → next stage pops in', W, 24, { size: 14, fill: '#C9C4DC' }), left: 0, top: 48 });
  let y = HEAD;
  for (const pair of EVOLVE_PAIRS) {
    L.push({ input: await blank(ROWL, CELL, '#F3EEE5'), left: 0, top: y });
    L.push({ input: label(`${pair.replace('-', ' → ')}`, ROWL, 26, { size: 16, fill: INKHEX, bold: true }), left: 0, top: y + CELL / 2 - 30 });
    for (let f = 1; f <= 4; f++) {
      const svgText = evolveSvg(pair, f);
      const x = ROWL + GAP + (f - 1) * (CELL + GAP);
      L.push({ input: await render(svgText, CELL, { split: true }), left: x, top: y });
      L.push({ input: await chip(svgText), left: x + 5, top: y + 5 });
      L.push({ input: label(`frame ${f}`, CELL, LABEL, { size: 10, fill: '#6B6790', bg: '#EDE8F8' }), left: x, top: y + CELL });
    }
    y += CELL + LABEL + GAP;
  }
  L.push({ input: label('flat ring glow + spin + shell-chip burst; no gradients', W, 26, { size: 12, fill: '#6E6A8A' }), left: 0, top: H - 26 });
  await compose(W, H, L, path.join(OUT, 'BOARD_evolve.png'));
}

console.log('rendering boards with sharp…');
await boardMoods();
await boardSequences();
await boardCustom();
await boardEvolve();
void POSES;
