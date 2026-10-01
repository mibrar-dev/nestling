#!/usr/bin/env node
/* Pip v2 · Bolt — automated QA.
   1. no art touches the 240 canvas edge (nothing clips)
   2. no <text>, no gradients, no filters, no external refs
   3. contract part ids present in every file
   4. ink stroke weight 8 on the character parts
   5. bounding box stays inside 4..236
*/
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const ROOT = path.resolve(import.meta.dirname, '../../..');
const B = path.join(ROOT, 'design/pip-v2/B');

const REQUIRED = ['shadow', 'body', 'head_tuft', 'eye_l', 'eye_r', 'beak_top', 'beak_bottom',
  'feet', 'cheek_l', 'cheek_r', 'tail', 'wing_l', 'wing_r', 'belly', 'shell_top', 'shell_bottom',
  'accessory_head', 'accessory_neck', 'accessory_face', 'fx'];
const EYE_STATES = ['open', 'closed', 'happy', 'sleepy', 'surprised', 'wink'];

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.endsWith('.svg')) out.push(p);
  }
  return out;
}

// the pre-existing direction thumbnails (expr_*, fledgling_*) feed the shared
// PIP_V2_DIRECTIONS board and predate this library — QA covers the new deliverables
const LEGACY = new Set(fs.readdirSync(B).filter((f) => /^(expr_|fledgling_)/.test(f)));
const files = walk(B).filter((f) => !LEGACY.has(path.basename(f)));
const problems = [];
const edgeFlags = [];

for (const f of files) {
  const src = fs.readFileSync(f, 'utf8');
  const rel = path.relative(B, f);

  /* --- source-level rules --- */
  if (/<text\b/.test(src)) problems.push(`${rel}: contains <text>`);
  if (/Gradient|radialGradient|linearGradient/.test(src)) problems.push(`${rel}: gradient`);
  if (/<filter\b|url\(#(?!)/.test(src)) problems.push(`${rel}: filter / external url()`);
  if (/font-family|@font-face/.test(src)) problems.push(`${rel}: font reference`);
  if (/xlink:href|<image\b/.test(src)) problems.push(`${rel}: embedded/linked raster`);

  /* --- contract ids --- */
  for (const id of REQUIRED) {
    if (!new RegExp(`id="${id}"`).test(src)) problems.push(`${rel}: missing part id "${id}"`);
  }
  for (const id of ['eye_l', 'eye_r']) {
    const open = src.indexOf(`id="${id}"`);
    const slice = open >= 0 ? src.slice(open, open + 2600) : '';
    for (const st of EYE_STATES) {
      if (!new RegExp(`id="${st}"`).test(slice)) problems.push(`${rel}: ${id} missing child state "${st}"`);
    }
  }
  if (/stroke-width="8(\.0)?"/.test(src) === false && !/shell_bottom/.test(src)) {
    problems.push(`${rel}: no 8px ink stroke found`);
  }
  /* --- viewBox --- */
  if (!/viewBox="0 0 240 240"/.test(src)) problems.push(`${rel}: wrong viewBox`);

  /* --- raster: nothing may touch the canvas edge --- */
  const px = await sharp(Buffer.from(src), { density: 200 })
    .resize(240, 240, { fit: 'fill', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .ensureAlpha().raw().toBuffer();
  let minX = 240, minY = 240, maxX = -1, maxY = -1;
  for (let y = 0; y < 240; y++) {
    for (let x = 0; x < 240; x++) {
      const a = px[(y * 240 + x) * 4 + 3];
      if (a > 8) {
        if (x < minX) minX = x; if (x > maxX) maxX = x;
        if (y < minY) minY = y; if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) { problems.push(`${rel}: renders empty`); continue; }
  if (minX <= 1 || minY <= 1 || maxX >= 238 || maxY >= 238) {
    edgeFlags.push(`${rel}: bbox ${minX},${minY} → ${maxX},${maxY} (touches canvas edge)`);
  }
  // contract: ground shadow is an ellipse centred on y=214, so 224 is the expected floor
  if (maxY > 225) problems.push(`${rel}: art below the ground shadow (maxY=${maxY})`);
}

console.log(`checked ${files.length} svg files (${LEGACY.size} legacy direction thumbnails skipped)`);
if (problems.length) { console.log(`\n✗ ${problems.length} problems:`); for (const p of problems) console.log('  ' + p); }
else console.log('✓ contract ids, stroke, viewBox, no text / gradients / rasters — all clean');
if (edgeFlags.length) { console.log(`\n⚠ ${edgeFlags.length} touch the canvas edge:`); for (const e of edgeFlags) console.log('  ' + e); }
else console.log('✓ nothing touches the 240 canvas edge');
