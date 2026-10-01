/* ==========================================================================
   Pip v2 · Bolt — accessories (contract: bow / cap / scarf / glasses / none)
   Each fits all 4 stages. Groups: accessory_head, accessory_neck, accessory_face.
   ========================================================================== */
import { INK, SW, xf, STAGES, buildParts } from './rig.mjs';
import { FACE_R } from './face.mjs';

const L = (...pairs) => (pairs.length === 1 && Array.isArray(pairs[0][0]) ? pairs[0] : pairs)
  .map((p) => `${Math.round(p[0] * 100) / 100} ${Math.round(p[1] * 100) / 100}`).join(' L ');
const pts = (...pairs) => (pairs.length === 1 && Array.isArray(pairs[0][0]) ? pairs[0] : pairs)
  .map((p) => `${Math.round(p[0] * 100) / 100} ${Math.round(p[1] * 100) / 100}`).join(' ');
const C = (x, y) => `cx="${x}" cy="${y}"`;
const T = (o) => { const s = xf(o); return s ? ` transform="${s}"` : ''; };

const ACC_COL = { a: '#FF5C7A', b: '#FF8A5B', c: '#4E6BE8', d: '#2FB98A' };

/* ── BOW · perches on the tuft, tilted, with two loops + a knot + tails ── */
function bow(bx, by, ry, s, col) {
  const x = bx + 12 * s, y = by - ry + 2 * s;
  return `<g${T({ tx: x, ty: y, rot: -16, sx: s, sy: s })}>`
    + `<path d="M 0 0 C -14 -14 -30 -10 -26 0 C -30 10 -14 14 0 0 Z" fill="${col}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<path d="M 0 0 C 14 -14 30 -10 26 0 C 30 10 14 14 0 0 Z" fill="${col}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<path d="M -4 8 C -12 16 -14 22 -10 26 L -2 20 L 4 27 L 5 9 Z" fill="${col}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<path d="M 4 8 C 12 15 14 21 10 25 L 3 20 L -2 27 L -5 9 Z" fill="${col}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<circle ${C(0, 1)} r="6.5" fill="${ACC_COL.b}" stroke="${INK}" stroke-width="${SW}"/></g>`;
}

/* ── CAP · flat cap with a peak, sits on the crown over the tuft ── */
function cap(bx, by, ry, s, col) {
  const y = by - ry + 12 * s, x = bx - 2 * s;
  return `<g${T({ tx: x, ty: y, rot: -7, sx: s, sy: s })}>`
    + `<path d="M -32 2 C -32 -20 -14 -26 4 -25 C 21 -24 30 -16 30 -4 L 30 2 Z" fill="${col}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<path d="M -34 2 L 40 6 C 44 7 44 14 38 15 L -32 11 C -37 10 -38 3 -34 2 Z" fill="${ACC_COL.d}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<circle ${C(4, -25)} r="4.5" fill="${ACC_COL.b}" stroke="${INK}" stroke-width="4"/></g>`;
}

/* ── SCARF · wraps the neck, knot + two hanging ends ── */
function scarf(bx, by, ry, s, col) {
  const y = by + ry * 0.56, x = bx;
  return `<g${T({ tx: x, ty: y, sx: s, sy: s })}>`
    + `<path d="M -33 -3 C -18 -13 18 -13 33 -3 C 36 4 33 11 26 11 C 8 5 -8 5 -26 11 C -33 11 -36 4 -33 -3 Z" fill="${col}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<path d="M 8 9 L 20 9 L 17 34 L 4 34 Z" fill="${col}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<path d="M -20 9 L -9 9 L -12 30 L -25 29 Z" fill="${col}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<path d="M -12 -4 L -8 4 M -2 -6 L 2 4 M 8 -6 L 12 3" fill="none" stroke="${INK}" stroke-width="3.6" stroke-linecap="round" opacity="0.45"/>`
    + `</g>`;
}

/* ── GLASSES · round ink frames over the eyes + bridge + temples ── */
function glasses(bx, by, f, s, stage) {
  // frames follow the generator's canonical eye geometry (face.mjs ratios)
  const d = 0.52 * FACE_R[stage], r = 0.32 * FACE_R[stage] * 1.3;
  const C0 = (x, y) => `cx="${x}" cy="${y}"`;
  const ring = (sgn) => `<circle ${C0(sgn * d, 0)} r="${r}" fill="none" stroke="${INK}" stroke-width="6.5"/>`
    + `<path d="M ${pts([sgn * (d + r), -r * 0.42], [sgn * (d + r + 14), -r * 0.8])}" fill="none" stroke="${INK}" stroke-width="5" stroke-linecap="round"/>`;
  return `<g${T({ tx: bx, ty: by + f.eyeDY, sx: s, sy: s })}>${ring(-1)}${ring(1)}`
    + `<path d="M ${pts([-d + r, -3], [-6, -6], [6, -6], [d - r, -3])}" fill="none" stroke="${INK}" stroke-width="6" stroke-linecap="round"/>`
    + `<path d="M ${pts([-d + r * 0.45, -r * 0.55], [0, -r * 0.85], [d - r * 0.45, -r * 0.55])}" fill="none" stroke="#FFFFFF" stroke-width="3" opacity="0.4" stroke-linecap="round"/></g>`;
}

/** returns {accessory_head, accessory_neck, accessory_face} markup for a stage/skin */
export function accessory(kind, stage, skin, opts = {}) {
  const S = STAGES[stage];
  const B = S.body;
  const dy = opts.bodyDy ?? 0, sx = opts.bodySx ?? 1, sy = opts.bodySy ?? 1;
  const bx = B.cx, by = B.cy + dy, rx = B.rx * sx, ry = B.ry * sy;
  const scale = stage === 1 ? 0.72 : stage === 2 ? 0.84 : stage === 3 ? 1 : 1.06;
  const col = ACC_COL[skin === 'sunny' ? 'a' : skin === 'berry' ? 'c' : skin === 'sky' ? 'd' : 'b'];
  let head = '', neck = '', face = '';
  switch (kind) {
    case 'bow': head = bow(bx, by, ry, scale, col); break;
    case 'cap': head = cap(bx, by, ry, scale, col); break;
    case 'scarf': neck = scarf(bx, by, ry, scale * (stage === 1 ? 0.9 : 1), col); break;
    case 'glasses': face = glasses(bx, by, S.face, scale * (stage === 1 ? 1.05 : 1), stage); break;
    default: break;
  }
  const wrap = (inner) => {
    if (!inner) return '';
    return `<g${T({ sx, sy, ox: bx, oy: by })}>${inner}</g>`;
  };
  return {
    accessory_head: wrap(head), accessory_neck: wrap(neck), accessory_face: wrap(face),
  };
}

/** build a full SVG for stage/accessory idle */
export function svgWithAccessory(kind, stage, skin = 'sunny', idlePose) {
  const p = { ...idlePose, stage, skin };
  const { parts } = buildParts(p);
  const acc = accessory(kind, stage, skin, { bodyDy: p.bodyDy, bodySx: p.bodySx, bodySy: p.bodySy });
  const out = parts.map((s) => s
    .replace(/<g id="accessory_head"\/>|<g id="accessory_head">.*?<\/g>/, `<g id="accessory_head">${acc.accessory_head}</g>`)
    .replace('<g id="accessory_neck"/>', `<g id="accessory_neck">${acc.accessory_neck}</g>`)
    .replace('<g id="accessory_face"/>', `<g id="accessory_face">${acc.accessory_face}</g>`));
  const label = `Pip v2 B Bolt · ${STAGES[stage].key} · idle · accessory ${kind}`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" width="240" height="240" role="img" aria-label="${label}">\n`
    + out.join('\n') + `\n</svg>\n`;
}
