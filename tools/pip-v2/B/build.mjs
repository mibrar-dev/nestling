#!/usr/bin/env node
/* Pip v2 · Bolt — writes every art file into design/pip-v2/B/ */
import fs from 'node:fs';
import path from 'node:path';
import { svg, SKINS, STAGES } from './rig.mjs';
import { allPoses, MOODS } from './poses.mjs';
import { svgWithAccessory } from './accessories.mjs';
import { evolveSvg, EVOLVE_PAIRS } from './evolve.mjs';
import { IDLE } from './idle.mjs';

const ROOT = path.resolve(import.meta.dirname, '../../..');
const OUT = path.join(ROOT, 'design/pip-v2/B');
const dir = (p) => { fs.mkdirSync(p, { recursive: true }); return p; };
const write = (p, s) => fs.writeFileSync(p, s);

let n = 0;

/* 1 ── pose library */
const posesDir = dir(path.join(OUT, 'poses'));
const all = allPoses();
const counts = {};
for (const p of all) {
  const name = `s${p.stage}_${p.mood}_${p.n}.svg`;
  write(path.join(posesDir, name), svg(p));
  counts[`s${p.stage}`] = (counts[`s${p.stage}`] || 0) + 1;
  n++;
}

/* 2 ── skins: fledgling idle + happy in all four skins */
const skinDir = dir(path.join(OUT, 'skins'));
for (const skin of Object.keys(SKINS)) {
  for (const mood of ['idle', 'happy']) {
    const p = { ...IDLE[3][mood], stage: 3, mood, n: mood === 'idle' ? 2 : 3, skin, note: `skin ${skin}` };
    write(path.join(skinDir, `skin_${skin}_s3_${mood}.svg`), svg(p));
    n++;
  }
}

/* 3 ── accessories on all four stages (idle pose) */
const accDir = dir(path.join(OUT, 'accessories'));
for (const kind of ['bow', 'cap', 'scarf', 'glasses']) {
  for (const stage of [1, 2, 3, 4]) {
    write(path.join(accDir, `acc_${kind}_s${stage}.svg`), svgWithAccessory(kind, stage, 'sunny', IDLE[stage].idle));
    n++;
  }
}
write(path.join(accDir, 'acc_none_s3.svg'), svgWithAccessory('none', 3, 'sunny', IDLE[3].idle)); n++;

/* 4 ── evolve key frames */
const evoDir = dir(path.join(OUT, 'evolve'));
for (const pair of EVOLVE_PAIRS) {
  for (let f = 1; f <= 4; f++) {
    write(path.join(evoDir, `evolve_${pair}_${f}.svg`), evolveSvg(pair, f));
    n++;
  }
}

/* 5 ── master stage sheets (the "on-model" reference) */
const topDir = OUT;
for (const stage of [1, 2, 3, 4]) {
  write(path.join(topDir, `stage_${stage}_${STAGES[stage].key}.svg`), svg(IDLE[stage].idle));
  n++;
}

console.log(`wrote ${n} svg files`);
console.log('  poses:', Object.entries(counts).map(([k, v]) => `${k}=${v}`).join(' '), '=', all.length);
console.log('  skins: 8  accessories: 17  evolve: 12  stage refs: 4');
console.log('  →', OUT);
void MOODS;
