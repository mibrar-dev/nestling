/* ==========================================================================
   Pip v2 · Bolt — evolve sequence key frames
   s1→s2, s2→s3, s3→s4.  Glow + spin + pop, next stage lands with a ring burst.
   Frames keep the contract part ids so they can be tweened frame-to-frame.
   ========================================================================== */
import { INK, SW, svg, STAGES } from './rig.mjs';

const r2 = (v) => Math.round(v * 100) / 100;
const C = (x, y) => `cx="${r2(x)}" cy="${r2(y)}"`;

const sparkle = (s, fill = '#FFFFFF', sw = 3.4) =>
  `<path d="M ${r2(0)} ${r2(-s)} Q ${r2(s * 0.17)} ${r2(-s * 0.17)} ${r2(s)} 0 Q ${r2(s * 0.17)} ${r2(s * 0.17)} 0 ${r2(s)} Q ${r2(-s * 0.17)} ${r2(s * 0.17)} ${r2(-s)} 0 Q ${r2(-s * 0.17)} ${r2(-s * 0.17)} 0 ${r2(-s)} Z" fill="${fill}" stroke="${INK}" stroke-width="${r2(sw)}" stroke-linejoin="round"/>`;

/** flat ring = the evolve glow; concentric outlines, never a gradient */
function glowRings(cx, cy, r1, r2v, op) {
  // keep the burst inside the 240 canvas: a ring may not cross the ground line
  const lim = Math.max(10, Math.min(cy - 12, 208 - cy));
  const k = Math.min(1, lim / Math.max(r1, r2v));
  const a = r1 * k, b = r2v * k;
  return `<g opacity="${op}" fill="none" stroke="#FFFFFF" stroke-linecap="round">`
    + `<circle ${C(cx, cy)} r="${r2(a)}" stroke-width="9"/>`
    + `<circle ${C(cx, cy)} r="${r2(b)}" stroke-width="5"/></g>`
    + `<circle ${C(cx, cy)} r="${r2((a + b) / 2)}" fill="#FFFFFF" opacity="${op * 0.55}"/>`;
}

/* squash + fade proxy for the outgoing stage, scale-in for the incoming stage */
function scaled(svgText, s, alpha = 1, rot = 0) {
  return svgText
    .replace('<svg ', `<svg opacity="${r2(alpha)}" `)
    .replace('<g id="shadow"', `<g transform="rotate(${r2(rot)} 120 130)"`)
    .replace(/<g id="body"/, `<g transform="translate(120 190) scale(${r2(s)}) translate(-120 -190)"`)
    .replace(/<g id="body"/, `<g id="body"`); // no-op guard
}

/** simple clean wrap: reuse the real art, but scale/rotate it as one unit */
function wrapStage(stage, { s = 1, sy = null, rot = 0, alpha = 1, dy = 0, skin = 'sunny' } = {}, idlePose = {}) {
  const base = svg({ stage, mood: 'idle', n: 1, skin, ...idlePose });
  const body = base
    .replace(/^<svg[^>]*>\n/, '')
    .replace(/\n<\/svg>\n?$/, '')
    .split('\n');
  const idx = body.findIndex((l) => l.includes('id="shadow"'));
  const head = body.slice(0, idx).join('\n');
  // skip the nested shadow: the evolve frame draws one ground shadow of its own,
  // otherwise scaling would push a second ellipse below the canvas
  const rest = body.slice(idx + 1).join('\n');
  const sc = sy ?? s;
  // pivot on the ground line so a growing pose stays planted instead of sinking
  const tr = `transform="translate(120 214) rotate(${r2(rot)}) scale(${r2(s)} ${r2(sc)}) translate(-120 -214) translate(0 ${r2(dy)})"`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" width="240" height="240" role="img" aria-label="evolve frame">\n`
    + head + `\n<g opacity="${r2(alpha)}">\n<g${tr ? ' ' + tr : ''}>\n` + rest + `\n</g>\n</g>\n</svg>\n`;
}

/* ── the three transitions, 4 key frames each ── */
const SEQ = {
  '1-2': [
    { n: 1, note: 'glow gathers', from: { stage: 1 }, fromOpt: { s: 1, sy: 0.94 }, fx: [{ ring: [120, 130, 30, 62, 0.55] }, { sp: [120, 130, 10] }] },
    { n: 2, note: 'crack split + pop', from: { stage: 1 }, fromOpt: { s: 1.05, sy: 1.08, alpha: 0.9 }, fx: [{ ring: [120, 130, 46, 84, 0.7] }, { sp: [120, 130, 15] }] },
    { n: 3, note: 'shell bursts outward', to: { stage: 2 }, toOpt: { s: 0.42, rot: -10, alpha: 0.9 }, fx: [{ ring: [120, 130, 62, 100, 0.8] }, { sp: [120, 130, 20] }, { chips: 1 }] },
    { n: 4, note: 'hatchling pops in', to: { stage: 2 }, toOpt: { s: 1, dy: 0 }, fx: [{ ring: [120, 130, 40, 86, 0.5] }, { sp: [120, 128, 13] }, { sp: [70, 74, 9] }, { sp: [172, 66, 8] }] },
  ],
  '2-3': [
    { n: 1, note: 'cup glows', from: { stage: 2 }, fromOpt: { s: 1, sy: 0.96 }, fx: [{ ring: [120, 150, 34, 66, 0.55] }, { sp: [120, 150, 10] }] },
    { n: 2, note: 'squash + spin up', from: { stage: 2 }, fromOpt: { s: 1.06, sy: 0.86, rot: -8, dy: 2 }, fx: [{ ring: [120, 130, 50, 90, 0.7] }, { sp: [120, 130, 16] }] },
    { n: 3, note: 'stretch tall, shell flies', to: { stage: 3 }, toOpt: { s: 0.34, sy: 0.62, rot: 8, alpha: 0.92 }, fx: [{ ring: [120, 130, 66, 104, 0.8] }, { sp: [120, 130, 21] }, { chips: 1 }] },
    { n: 4, note: 'fledgling pops in', to: { stage: 3 }, toOpt: { s: 1.04 }, fx: [{ ring: [120, 132, 44, 92, 0.5] }, { sp: [120, 130, 14] }, { sp: [66, 70, 10] }, { sp: [176, 62, 9] }] },
  ],
  '3-4': [
    { n: 1, note: 'chest sparkles', from: { stage: 3 }, fromOpt: { s: 1, sy: 0.96 }, fx: [{ ring: [120, 150, 34, 66, 0.55] }, { sp: [104, 158, 9] }, { sp: [136, 152, 8] }] },
    { n: 2, note: 'stretch + spin', from: { stage: 3 }, fromOpt: { s: 0.9, sy: 1.16, rot: -10, dy: -6 }, fx: [{ ring: [120, 130, 52, 92, 0.7] }, { sp: [120, 130, 17] }] },
    { n: 3, note: 'wings burst open', to: { stage: 4 }, toOpt: { s: 0.46, rot: 10, alpha: 0.92 }, fx: [{ ring: [120, 130, 68, 108, 0.8] }, { sp: [120, 130, 22] }, { chips: 1 }] },
    { n: 4, note: 'songbird pops in', to: { stage: 4 }, toOpt: { s: 1.04 }, fx: [{ ring: [120, 132, 48, 96, 0.5] }, { sp: [120, 128, 15] }, { sp: [58, 66, 11] }, { sp: [184, 58, 10] }] },
  ],
};

const chipShapes = (n = 7) => {
  const pts = [[62, 96], [178, 88], [48, 150], [196, 146], [86, 54], [156, 48], [120, 30]];
  return pts.slice(0, n).map(([x, y], i) =>
    `<path d="M ${x - 7} ${y - 5} L ${x + 7} ${y - 7} L ${x + 6} ${y + 6} L ${x - 6} ${y + 7} Z" fill="#FFF6E6" stroke="${INK}" stroke-width="5" stroke-linejoin="round"${i % 2 ? ' transform="rotate(24 ' + x + ' ' + y + ')"' : ''}/>`).join('');
};

export function evolveSvg(pair, frame) {
  const seq = SEQ[pair];
  const f = seq[frame - 1];
  let body = '';
  if (f.from) body += wrapStage(f.from.stage, f.fromOpt);
  if (f.to) body += wrapStage(f.to.stage, f.toOpt);
  const fx = (f.fx || []).map((x) => {
    if (x.ring) return glowRings(x.ring[0], x.ring[1], x.ring[2], x.ring[3], x.ring[4]);
    if (x.sp) return sparkle(x.sp[2], '#FFFFFF', 3.6);
    if (x.chips) return chipShapes();
    return '';
  });
  // fx items carry coordinates in a parallel tuple; rebuild with positions
  const fx2 = (f.fx || []).map((x) => {
    if (x.ring) return glowRings(x.ring[0], x.ring[1], x.ring[2], x.ring[3], x.ring[4]);
    if (x.sp) return `<g transform="translate(${x.sp[0]} ${x.sp[1]})">${sparkle(x.sp[2], '#FFFFFF', 3.6)}</g>`;
    if (x.chips) return chipShapes();
    return '';
  });
  void fx;
  const label = `Pip v2 B Bolt · evolve ${pair} frame ${f.n} · ${f.note}`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" width="240" height="240" role="img" aria-label="${label}">\n`
    + `<g id="shadow"><ellipse ${C(120, 214)} rx="${r2(46 + (f.to ? 8 : 0))}" ry="10" fill="${INK}" opacity="0.1"/></g>\n`
    + body
    + `<g id="fx">${fx2.join('')}</g>\n</svg>\n`;
}

export const EVOLVE_PAIRS = Object.keys(SEQ);
export { SEQ as EVOLVE_SEQ };
export { STAGES };
