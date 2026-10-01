/* ==========================================================================
   Pip v2 · style B "BOLT" — character rig
   100% original art. Flat bold shapes, one soft highlight, no gradients.
   Contract: docs/pip-v2/PIP_V2_CONTRACT.md
   Canvas 240x240, ground baseline y=214, ink #1E1B3A, stroke weight 8.
   ========================================================================== */

export const INK = '#1E1B3A';
export const SW = 8;
export const BEAK = '#FF8A5B';

import { buildFace, FACE_R, STAGE_FACE } from './face.mjs';

export const SKINS = {
  sunny: { body: '#FFD93D', belly: '#FFF1B8', wing: '#E9AE00', tail: '#C08700', accent: '#C98A3C', shell: '#FFF7E4' },
  berry: { body: '#FF9EBB', belly: '#FFE1EA', wing: '#E0688F', tail: '#B84E74', accent: '#B0416A', shell: '#FFEFF4' },
  sky:   { body: '#8EC9FF', belly: '#E2F1FF', wing: '#5A9FE0', tail: '#3C7FC4', accent: '#2E6FA8', shell: '#EEF6FF' },
  mint:  { body: '#8EE3B5', belly: '#DDF8E8', wing: '#46BE90', tail: '#2E9A72', accent: '#1F8A63', shell: '#EDFAF2' },
};

/* ---------- numeric helpers ---------- */
const r2 = (v) => Math.round(v * 100) / 100;
const norm = (pairs) => (pairs.length === 1 && Array.isArray(pairs[0][0])) ? pairs[0] : pairs;
/** polyline: "x y L x y L ..." (also accepts one array of pairs) */
const L = (...pairs) => norm(pairs).map((p) => `${r2(p[0])} ${r2(p[1])}`).join(' L ');
/** bare coordinate list for C/S/Q control points: "x y x y x y" */
const pts = (...pairs) => norm(pairs).map((p) => `${r2(p[0])} ${r2(p[1])}`).join(' ');
const C = (cx, cy) => `cx="${r2(cx)}" cy="${r2(cy)}"`;
/** a single point as "x y" — interpolating an array directly would emit "x,y" */
const one = (p) => `${r2(p[0])} ${r2(p[1])}`;

/** compact SVG transform: translate, then rotate/scale about (ox,oy) */
export function xf({ tx = 0, ty = 0, rot = 0, sx = 1, sy = 1, ox = 0, oy = 0 } = {}) {
  const tr = tx || ty, sc = sx !== 1 || sy !== 1;
  if (!tr && !sc && !rot) return '';
  let s = '';
  if (tr) s += `translate(${r2(tx)} ${r2(ty)})`;
  if (rot || sc) {
    s += `translate(${r2(ox)} ${r2(oy)})`;
    if (rot) s += `rotate(${r2(rot)})`;
    if (sc) s += `scale(${r2(sx)} ${r2(sy)})`;
    s += `translate(${r2(-ox)} ${r2(-oy)})`;
  }
  return s;
}
const T = (o) => xf(o);
const tg = (o) => { const s = xf(o); return s ? ` transform="${s}"` : ''; };

/* ---------- stage bases ---------- */
export const STAGES = {
  1: {
    key: 'egg', name: 'egg', label: 'stage 1 · egg',
    body: { cx: 120, cy: 158, rx: 59, ry: 56 },
    face: { eyeDX: 19, eyeDY: -18, eyeR: 14, pupilR: 7.6, beakDY: -5, beakW: 13, cheekDX: 0, cheekDY: 0, cheekR: 0 },
    crackY: 176,
    has: { body: 0, belly: 0, hl: 0, tail: 0, wings: 0, feet: 0, cup: 0, hat: 0, tuft: 0 },
  },
  2: {
    key: 'hatchling', name: 'hatchling', label: 'stage 2 · hatchling',
    body: { cx: 120, cy: 142, rx: 46, ry: 48 },
    face: { eyeDX: 20, eyeDY: -11, eyeR: 11.8, pupilR: 6.4, beakDY: 13, beakW: 13.5, cheekDX: 33, cheekDY: 17, cheekR: 7.5 },
    has: { body: 1, belly: 1, hl: 1, tail: 0, wings: 1, feet: 0, cup: 1, hat: 1, tuft: 1 },
  },
  3: {
    key: 'fledgling', name: 'fledgling', label: 'stage 3 · fledgling',
    body: { cx: 120, cy: 136, rx: 50, ry: 56 },
    face: { eyeDX: 26, eyeDY: -14, eyeR: 16, pupilR: 8.6, beakDY: 18, beakW: 18.5, cheekDX: 40, cheekDY: 16, cheekR: 9 },
    has: { body: 1, belly: 1, hl: 1, tail: 0, wings: 1, feet: 1, cup: 0, hat: 0, tuft: 1 },
  },
  4: {
    key: 'songbird', name: 'songbird', label: 'stage 4 · songbird',
    body: { cx: 120, cy: 136, rx: 50, ry: 64 },
    // head mass + neck + slim chest, so the grown-up silhouette reads at 48 px
    head: { cy: 100, r: 40 },
    neck: { top: 116, bot: 140, halfTop: 26, halfBot: 38 },
    chest: { cy: 166, rx: 50, ry: 25 },
    face: { eyeDX: 23, eyeDY: -14, eyeR: 15, pupilR: 8, beakDY: 19, beakW: 20, cheekDX: 24, cheekDY: 13, cheekR: 8 },
    has: { body: 1, belly: 1, hl: 1, tail: 1, wings: 1, feet: 1, cup: 0, hat: 0, tuft: 1 }, tuftScale: 1.12, wingRest: 26,
  },
};

/* ---------- shape primitives ---------- */

/** tall pear body outline (widest a little below centre) */
function pearPath(cx, cy, rx, ry) {
  const M = `M ${L([cx, cy - ry])}`;
  return M
    + ` C ${pts([cx + rx * 0.99, cy - ry], [cx + rx, cy - ry * 0.34], [cx + rx, cy + ry * 0.12])}`
    + ` C ${pts([cx + rx, cy + ry * 0.86], [cx + rx * 0.63, cy + ry], [cx, cy + ry])}`
    + ` C ${pts([cx - rx * 0.63, cy + ry], [cx - rx, cy + ry * 0.86], [cx - rx, cy + ry * 0.12])}`
    + ` C ${pts([cx - rx, cy - ry * 0.34], [cx - rx * 0.99, cy - ry], [cx, cy - ry])} Z`;
}

/** songbird: head mass + neck + slim chest, one closed outline (review C1) */
function songbirdPath(S) {
  const { cx } = S.body, hd = S.head, nk = S.neck, ch = S.chest;
  const top = hd.cy - hd.r, bot = ch.cy + ch.ry;
  const hr = hd.r * 0.78;
  return `M ${L([cx, top])}`
    + ` C ${pts([cx + hr, top], [cx + hd.r, hd.cy - hd.r * 0.45], [cx + hd.r, hd.cy])}`
    + ` C ${pts([cx + hd.r, hd.cy + hd.r * 0.45], [cx + nk.halfTop + 8, nk.top], [cx + nk.halfTop, nk.top + 6])}`
    + ` C ${pts([cx + nk.halfTop + 1, nk.top + 16], [cx + nk.halfBot - 4, nk.bot - 10], [cx + ch.rx, ch.cy - ch.ry * 0.62])}`
    + ` C ${pts([cx + ch.rx, ch.cy + ch.ry * 0.28], [cx + ch.rx * 0.6, bot], [cx, bot])}`
    + ` C ${pts([cx - ch.rx * 0.6, bot], [cx - ch.rx, ch.cy + ch.ry * 0.28], [cx - ch.rx, ch.cy - ch.ry * 0.62])}`
    + ` C ${pts([cx - nk.halfBot + 4, nk.bot - 10], [cx - nk.halfTop - 1, nk.top + 16], [cx - nk.halfTop, nk.top + 6])}`
    + ` C ${pts([cx - nk.halfTop - 8, nk.top], [cx - hd.r, hd.cy + hd.r * 0.45], [cx - hd.r, hd.cy])}`
    + ` C ${pts([cx - hd.r, hd.cy - hd.r * 0.45], [cx - hr, top], [cx, top])} Z`;
}

/** three swept crest feathers, longest in the middle — never a crown (review B1).
    Separate blades with real gaps between them and clearly unequal lengths; the
    outlines stay open at the base so the fill melts into the head (no seam). */
/** ONE bold swept-back crest: three lobes fused at the base, middle tallest and
    curving back, like a cardinal / cockatiel crest (review round 3, B1).
    A single closed silhouette — one readable shape at 48 px, never a crown.
    The outline stays open at the base so the fill melts into the head (no seam).
    `lean` shifts the tips sideways for acting (positive = flop right). */
function crestPath(lean = 0.25) {
  const lx = lean * 10;
  return `M ${L([-19, 10])}`
    + ` C ${pts([-25, -4], [-27, -12], [-24, -19])}`
    + ` Q ${pts([-22, -26], [-15, -25])}`
    + ` C ${pts([-13, -24], [-12, -22], [-12, -19])}`
    + ` C ${pts([-11, -30], [-7, -42], [3 + lx, -46])}`
    + ` Q ${pts([7 + lx, -48], [10 + lx, -44])}`
    + ` C ${pts([12 + lx, -40], [11, -34], [9, -27])}`
    + ` C ${pts([10, -31], [15, -33], [18, -31])}`
    + ` Q ${pts([23, -28], [21, -21])}`
    + ` C ${pts([20, -11], [19, -1], [18, 10])}`;
}

/** egg outline sampled clockwise, index 0 = bottom, mid = top */
function eggRing(cx, cy, rx, ry, n = 128) {
  const pts = [];
  for (let i = 0; i <= n; i++) {
    const t = (i / n) * Math.PI * 2;
    const f = 1 - 0.19 * ((1 - Math.cos(t)) / 2);
    pts.push([cx + rx * Math.sin(t) * f, cy - ry * Math.cos(t)]);
  }
  return pts;
}
/** both x values where a closed ring crosses a horizontal line */
function ringEdgesAt(pts, y) {
  const xs = [];
  for (let i = 0; i < pts.length - 1; i++) {
    const a = pts[i], b = pts[i + 1];
    if ((a[1] - y) * (b[1] - y) <= 0 && a[1] !== b[1]) {
      xs.push(a[0] + (b[0] - a[0]) * ((y - a[1]) / (b[1] - a[1])));
    }
  }
  xs.sort((u, v) => u - v);
  return xs.length >= 2 ? [xs[0], xs[xs.length - 1]] : [pts[0][0], pts[0][0]];
}

/** bold wing paddle, two feather scallops on the outer (-x) edge */
/** one smooth wing paddle — a single bold shape, no feather scallops (round 3, B2).
    Origin at the shoulder (top-inner corner); the tip hangs down-out. */
function wingPath(w, h) {
  const a = w / 2, b = h / 2;
  return `M ${L([a * 0.52, -b])}`
    + ` C ${pts([-a * 0.3, -b], [-a * 1.18, -b * 0.52], [-a * 1.14, b * 0.08])}`
    + ` C ${pts([-a * 1.1, b * 0.62], [-a * 0.4, b], [a * 0.14, b * 0.84])}`
    + ` C ${pts([a * 0.56, b * 0.68], [a * 0.62, -b * 0.3], [a * 0.52, -b])} Z`;
}

/** tail feather blade, origin at its top centre */
function featherPath(w, h) {
  const a = w / 2;
  return `M ${L([-a * 0.44, 0])}`
    + ` C ${pts([-a * 0.62, -h * 0.18], [-a, h * 0.5], [-a * 0.5, h * 0.9])}`
    + ` Q ${pts([0, h * 1.05], [a * 0.5, h * 0.9])}`
    + ` C ${pts([a, h * 0.5], [a * 0.62, -h * 0.18], [a * 0.44, 0])}`
    + ` Q ${pts([0, -h * 0.14], [-a * 0.44, 0])} Z`;
}

/** chunky foot, origin at the ankle; two toe bumps with a notch between */
function footPath(w, h) {
  const a = w / 2, hh = h / 2;
  return `M ${L([-a * 0.66, -hh])}`
    + ` Q ${pts([-a, -hh], [-a, -hh * 0.2])}`
    + ` L ${L([-a, hh * 0.26])}`
    + ` Q ${pts([-a, hh], [-a * 0.5, hh])}`
    + ` L ${L([-a * 0.29, hh])}`
    + ` Q ${pts([0, hh * 0.6], [a * 0.29, hh])}`
    + ` L ${L([a * 0.5, hh])}`
    + ` Q ${pts([a, hh], [a, hh * 0.26])}`
    + ` L ${L([a, -hh * 0.2])}`
    + ` Q ${pts([a, -hh], [a * 0.66, -hh])} Z`;
}

/* ---------- fx primitives (no text: Z / ! are drawn as shapes) ---------- */
const sparkle = (s, fill = '#FFFFFF', sw = 3.4) =>
  `<path d="M ${L([0, -s])} Q ${pts([s * 0.14, -s * 0.14], [s, 0])} Q ${pts([s * 0.14, s * 0.14], [0, s])}`
  + ` Q ${pts([-s * 0.14, s * 0.14], [-s, 0])} Q ${pts([-s * 0.14, -s * 0.14], [0, -s])} Z"`
  + ` fill="${fill}" stroke="${INK}" stroke-width="${r2(sw)}" stroke-linejoin="round"/>`;
const zShape = (s, sw, col = INK) =>
  `<path d="M ${L([-s * 0.4, -s * 0.52], [s * 0.42, -s * 0.52], [-s * 0.4, s * 0.52], [s * 0.42, s * 0.52])}"`
  + ` fill="none" stroke="${col}" stroke-width="${r2(sw)}" stroke-linejoin="round" stroke-linecap="round"/>`;
const bangShape = (s, col = INK) => {
  const w = s * 0.27;
  return `<g fill="${col}"><rect x="${r2(-w / 2)}" y="${r2(-s * 0.52)}" width="${r2(w)}" height="${r2(s * 0.68)}" rx="${r2(w * 2)}"/>`
    + `<circle ${C(0, s * 0.44)} r="${r2(w * 0.66)}"/></g>`;
};
const heartShape = (s) =>
  `<path d="M ${L([0, s * 0.9])} C ${pts([-s * 1.04, s * 0.16], [-s * 0.62, -s * 0.82], [0, -s * 0.3])}`
  + ` C ${pts([s * 0.62, -s * 0.82], [s * 1.04, s * 0.16], [0, s * 0.9])} Z"`
  + ` fill="#FF7A9C" stroke="${INK}" stroke-width="${r2(Math.max(2.4, s * 0.14))}" stroke-linejoin="round"/>`;
const seedShape = (s) =>
  `<path d="M ${L([0, -s], [s * 0.8, -s * 0.34], [s * 0.64, s * 0.56], [0, s], [-s * 0.64, s * 0.56], [-s * 0.8, -s * 0.34], [0, -s])}"`
  + ` fill="#8B5A2B" stroke="${INK}" stroke-width="3.2" stroke-linejoin="round"/>`
  + `<path d="M ${L([-s * 0.34, -s * 0.3], [-s * 0.1, s * 0.16])}" fill="none" stroke="#FFFFFF" stroke-width="2.2" opacity="0.35" stroke-linecap="round"/>`;
const crumbShape = (s, col = '#C98A3C') =>
  `<path d="M ${L([-s, -s * 0.5], [s * 0.7, -s], [s, s * 0.6], [-s * 0.55, s], [-s, -s * 0.5])}"`
  + ` fill="${col}" stroke="${INK}" stroke-width="2.4" stroke-linejoin="round"/>`;
const dotShape = (s, col = INK) => `<circle ${C(0, 0)} r="${r2(s)}" fill="${col}"/>`;
const motionLine = (len, rot, sw, col = INK) =>
  `<rect x="${r2(-len / 2)}" y="${r2(-sw / 2)}" width="${r2(len)}" height="${r2(sw)}" rx="${r2(sw / 2)}" fill="${col}" transform="rotate(${r2(rot)})"/>`;
const shineSweep = (len, w, rot) =>
  `<rect x="${r2(-len / 2)}" y="${r2(-w / 2)}" width="${r2(len)}" height="${r2(w)}" rx="${r2(w / 2)}" fill="#FFFFFF" opacity="0.9" transform="rotate(${r2(rot)})"/>`;

const FXR = {
  sparkle: (o) => sparkle(o.s ?? 11, o.fill ?? '#FFFFFF', o.sw ?? 3.4),
  dot: (o) => dotShape(o.s ?? 3, o.col ?? INK),
  z: (o) => zShape(o.s ?? 15, o.sw ?? 5, o.col ?? INK),
  bang: (o) => bangShape(o.s ?? 28, o.col ?? INK),
  heart: (o) => heartShape(o.s ?? 12),
  seed: (o) => seedShape(o.s ?? 12),
  crumb: (o) => crumbShape(o.s ?? 4.4, o.col ?? '#C08B4E'),
  motion: (o) => motionLine(o.len ?? 22, o.rot ?? 0, o.sw ?? 6, o.col ?? INK),
  sweep: (o) => shineSweep(o.len ?? 42, o.w ?? 9, o.rot ?? 26),
};
function fxGroup(list) {
  if (!list || !list.length) return '<g id="fx"/>';
  const body = list.map((f, i) => {
    const fn = FXR[f.t];
    if (!fn) throw new Error('unknown fx: ' + f.t);
    return `<g id="fx_${f.t}_${i}"${tg({ tx: f.x, ty: f.y, rot: f.rot })}>${fn(f)}</g>`;
  }).join('');
  return `<g id="fx">${body}</g>`;
}

/** sleepy nightcap — worn via accessory_head on sleepy frames (round 3, like the
    other styles). Deep blue floppy cone, white brim, white pom: three flat
    shapes, 8 px ink, nothing else. */
function nightcap(bx, crownY, s, tilt) {
  return `<g${tg({ tx: bx, ty: crownY, rot: tilt, sx: s, sy: s })}>`
    + `<path d="M ${L([-30, -2])} C ${pts([-28, -26], [-8, -37], [10, -37])}`
    + ` C ${pts([24, -37], [32, -30], [38, -19])}`
    + ` L ${L([28, -11])} C ${pts([23, -18], [17, -22], [9, -22])}`
    + ` C ${pts([-3, -22], [-15, -14], [-17, -2])} Z"`
    + ` fill="#4E6BE8" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/>`
    + `<rect x="-34" y="-8" width="68" height="14" rx="7" fill="#FFFFFF" stroke="${INK}" stroke-width="${SW}"/>`
    + `<circle ${C(41, -16)} r="8.5" fill="#FFFFFF" stroke="${INK}" stroke-width="${SW}"/></g>`;
}

/* ---------- tiny 2D math for the debug hook ---------- */
const rad = (a) => (a * Math.PI) / 180;
const rotPt = (x, y, a, ox, oy) => {
  const c = Math.cos(rad(a)), s2 = Math.sin(rad(a));
  const dx = x - ox, dy = y - oy;
  return [ox + dx * c - dy * s2, oy + dx * s2 + dy * c];
};

/* ---------- the builder ---------- */
export function buildParts(p) {
  const S = STAGES[p.stage], K = SKINS[p.skin || 'sunny'], F = S.face, B = S.body;
  const sx = p.bodySx ?? 1, sy = p.bodySy ?? 1, dy = p.bodyDy ?? 0, dx = p.bodyDx ?? 0, brot = p.bodyRot ?? 0;
  const bottomY = B.cy + B.ry;
  const bx = B.cx + dx, by = B.cy + dy;
  const fy = S.head ? S.head.cy : by;            // where the face is anchored
  const brx = B.rx * sx, bry = B.ry * sy;
  const bodyX = tg({ rot: brot, sx, sy, ox: B.cx, oy: bottomY });
  const tag = `stage${p.stage}`;

  /* shadow */
  const shRx = (S.has.feet || S.has.cup ? 60 : 57) * (p.shadowSx ?? 1);
  const shadow = `<g id="shadow"><ellipse ${C(B.cx, 214)} rx="${r2(shRx)}" ry="10" fill="${INK}" opacity="0.12"/></g>`;

  /* tail */
  let tail = '<g id="tail" opacity="0"/>';
  if (S.has.tail) {
    const t = p.tail || {};
    const big = p.stage === 4;
    const spread = t.spread ?? (big ? 78 : 40), len = (big ? 56 : 34) * (t.len ?? 1), wdt = (big ? 24 : 20) * (t.w ?? 1);
    const oy = (big ? 186 : 182) + (t.dy ?? 0), rot = t.rot ?? 0;
    // the centre feather is foreshortened on the songbird, so the fan reads as a tail
    const midK = t.mid ?? (big ? 0.46 : 1);
    const f = [{ a: -spread, h: len }, { a: 0, h: len * midK }, { a: spread, h: len }]
      .map((q) => `<path d="${featherPath(wdt, q.h)}"${tg({ tx: bx, ty: oy, rot: rot + q.a })}/>`).join('');
    tail = `<g id="tail" fill="${K.tail ?? K.wing}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round">${f}</g>`;
  }

  /* wings */
  const ww = (p.stage === 4 ? 33 : p.stage === 3 ? 35 : 27) * (p.wingScale ?? 1);
  const wh = (p.stage === 4 ? 70 : p.stage === 3 ? 52 : 35) * (p.wingScale ?? 1);
  const wing = (side) => {
    const sgn = side === 'l' ? -1 : 1, o = p['wing' + (side === 'l' ? 'L' : 'R')] || {};
    const sxw = B.cx + sgn * (S.chest ? S.chest.rx : brx) * (o.ix ?? 0.99) + sgn * (o.dx ?? 0);
    const syw = (S.chest ? S.chest.cy - S.chest.ry * 0.46 : by - bry * 0.14) + (o.dy ?? 0);
    // mirror each wing so the paddle faces outward; the wing pivots about the
    // top of the paddle (the shoulder joint), so raises swing wide and high
    return `<path d="${wingPath(ww, wh)}"${tg({
      tx: sxw, ty: syw, rot: -sgn * (o.rot ?? S.wingRest ?? 0), sx: -sgn * (o.sx ?? 1), sy: o.sy ?? 1,
      ox: 0, oy: -wh * 0.35,
    })}/>`;
  };
  const wingL = S.has.wings
    ? `<g id="wing_l" fill="${K.wing}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round">${p.wingL ? wing('l') : wing('l')}</g>`
    : '<g id="wing_l" opacity="0"/>';
  const wingR = S.has.wings
    ? `<g id="wing_r" fill="${K.wing}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round">${p.wingR ? wing('r') : wing('r')}</g>`
    : '<g id="wing_r" opacity="0"/>';

  /* body / belly / highlight */
  const bodyD = p.stage === 4 ? songbirdPath(S) : pearPath(B.cx, B.cy, B.rx, B.ry);
  const body = S.has.body
    ? `<g id="body"${bodyX}><path d="${bodyD}" fill="${K.body}" stroke="${INK}" stroke-width="${SW}"/></g>`
    : '<g id="body" opacity="0"/>';
  const belCx = B.cx, belCy = S.chest ? S.chest.cy : B.cy + B.ry * 0.3;
  const belRx = (S.chest ? S.chest.rx * 0.66 : B.rx * 0.68) * (p.bellySx ?? 1);
  const belRy = (S.chest ? S.chest.ry * 0.92 : B.ry * 0.52) * (p.bellySy ?? 1);
  const belly = S.has.belly
    ? `<g id="belly"${bodyX}><ellipse ${C(belCx, belCy)} rx="${r2(belRx)}" ry="${r2(belRy)}" fill="${K.belly}"/></g>`
    : '<g id="belly" opacity="0"/>';
  const hcx = (S.head ? S.head.cx0 ?? B.cx : B.cx) - (S.head ? S.head.r : B.rx) * 0.42;
  const hcy = (S.head ? S.head.cy - S.head.r * 0.44 : B.cy - B.ry * 0.62);
  const hl = S.has.hl
    ? `<g id="highlight"${bodyX}><ellipse ${C(hcx, hcy)} rx="${r2((S.head ? S.head.r : B.rx) * 0.32)}" ry="${r2((S.head ? S.head.r : B.rx) * 0.16)}" fill="#FFFFFF" opacity="0.55" transform="rotate(-22 ${r2(hcx)} ${r2(hcy)})"/></g>`
    : '<g id="highlight" opacity="0"/>';

  /* shell pieces */
  let shellTop = '<g id="shell_top" opacity="0"/>', shellBot = '<g id="shell_bottom" opacity="0"/>';
  if (p.stage === 1) {
    const co = Math.max(0, p.crackOpen ?? 0) * 0.5;   // crack width, applied by lifting the crown
    const baseY = 214;                                 // the egg always rests on the ground line
    const ecy = baseY - bry;
    const ring = eggRing(bx, ecy, brx, bry, 132);
    const crackY = ecy + (S.crackY - B.cy) * sy;
    const [exL, exR] = ringEdgesAt(ring, crackY);
    const lx = exL - 3, rxe = exR + 3;
    const zig = [[0, 0], [0.15, -0.5], [0.32, 0.42], [0.5, -0.62], [0.68, 0.42], [0.85, -0.5], [1, 0.08]];
    const zp = zig.map(([u, v]) => [lx + (rxe - lx) * u, crackY + v * 8]);
    const n = ring.length;
    // the ring starts at the crown and runs clockwise: crown → right → base → left.
    // iR / iL are the crack crossings on the right and left flanks.
    let iR = 0;
    while (iR < n && !(ring[iR][1] >= crackY && ring[iR][0] >= bx + 2)) iR++;
    let iL = iR + 1;
    while (iL < iR + n && !(ring[iL % n][1] >= crackY && ring[iL % n][0] <= bx - 2)) iL++;
    const topPts = [], botPts = [];
    for (let i = iL; i >= iR - n; i--) topPts.push(ring[((i % n) + n) % n]); // left crack → crown → right crack
    for (let i = iR; i <= iL; i++) botPts.push(ring[i % n]);                  // right crack → base → left crack
    const spots = [[-32, -30, 6.5], [24, -40, 5.5], [40, -10, 5.5]]
      .map(([a, b, s]) => `<circle ${C(bx + a * sx, ecy + b * sy)} r="${s}" fill="${K.wing}" stroke="none" opacity="0.45"/>`).join('');
    shellTop = `<g id="shell_top"${tg({ ty: -co })} fill="${K.shell}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round">`
      + `<path d="M ${L(topPts)} L ${one(zp[zp.length - 1])} ${L(zp.slice(0, -1).reverse())} Z"/>${spots}`
      + `<ellipse ${C(bx - 31 * sx, ecy - 34 * sy)} rx="13" ry="6.5" fill="#FFFFFF" stroke="none" opacity="0.6" transform="rotate(-24 ${r2(bx - 31 * sx)} ${r2(ecy - 34 * sy)})"/></g>`;
    shellBot = `<g id="shell_bottom"${tg({ ty: co * 0.16 })} fill="${K.shell}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round">`
      + `<path d="M ${L(botPts)} L ${one(zp[0])} ${L(zp.slice(1))} Z"/></g>`;
  } else if (p.stage === 2) {
    const hw = 36, hdome = 25;
    const hat = [[-1, 6], [-0.56, -3], [-0.2, 7], [0.1, 0], [0.44, 7], [0.76, -4], [1, 5]];
    const zp = hat.map(([u, v]) => [bx + u * hw * sx, by - bry + 3 + v * sy]);
    shellTop = `<g id="shell_top"${tg({ rot: p.shellHatRot ?? 6, sx, sy, ox: bx, oy: by - bry })}`
      + ` fill="${K.shell}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round">`
      + `<path d="M ${one(zp[0])} C ${pts([zp[0][0], by - bry - hdome * sy], [zp[zp.length - 1][0], by - bry - hdome * sy], zp[zp.length - 1])}`
      + ` L ${L(zp.slice(0, -1).reverse())} Z"/></g>`;
    const cw = 58, ctop = by + bry * 0.58;
    const czig = [[-1, 0], [-0.72, -0.3], [-0.4, 0.14], [-0.06, -0.22], [0.3, 0.16], [0.62, -0.3], [0.84, 0.06], [1, 0.02]];
    const cp = czig.map(([u, v]) => [bx + u * cw, ctop + v * 21 * sy]);
    shellBot = `<g id="shell_bottom"${tg({ sx, ox: bx, oy: by })} fill="${K.shell}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round">`
      + `<path d="M ${L(cp)}`
      + ` C ${pts([bx + cw * 0.98, by + bry + 16], [bx + cw * 0.54, 214], [bx, 214])}`
      + ` C ${pts([bx - cw * 0.54, 214], [bx - cw * 0.98, by + bry + 16], cp[0])} Z"/>`
      + `<circle ${C(bx - 30, 199)} r="5" fill="${K.wing}" stroke="none" opacity="0.4"/>`
      + `<circle ${C(bx + 33, 202)} r="4.5" fill="${K.wing}" stroke="none" opacity="0.4"/></g>`;
  }

  /* feet */
  let feet = '<g id="feet" opacity="0"/>';
  if (S.has.feet && p.feet !== false) {
    const fy = 204 + (p.feetDy ?? 0), fdx = (p.stage === 4 ? 24 : 22) * (p.feetSx ?? 1);
    const fw = (p.stage === 4 ? 32 : 33) * (p.feetSx ?? 1);
    const f = (side) => {
      const sgn = side === 'l' ? -1 : 1;
      return `<g id="foot_${side}"><path d="${footPath(fw, 22)}"${tg({ tx: bx + sgn * fdx, ty: fy, rot: sgn * 9, sx: sgn })}/></g>`;
    };
    feet = `<g id="feet" fill="${BEAK}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round">${f('l')}${f('r')}</g>`;
  }

  /* head */
  const eyeY0 = fy + F.eyeDY;
  const headLift = p.stage === 1 ? -Math.max(0, p.crackOpen ?? 0) * 0.5 : 0;
  // the shared tilt pivots at the FACE CENTRE, not the neck: the eye midpoint
  // then cannot leave the head axis by construction, while crest/cap/beak —
  // far from the pivot — still swing visibly (round 5 diagnosis fix).
  const htx0 = (p.headDx ?? 0), hty0 = (p.headDy ?? 0) + headLift;
  const pivotX = bx + htx0, pivotY = eyeY0 + hty0;
  // shared head tilt (round 5): ONE angle for crest + face + cap + nightcap
  // about the face centre. The egg never tilts. Clamped to +-2: a rigid
  // rotation tilts the eye line by separation*sin(tilt), so rotation stays
  // where the eyes remain level; all larger acting moves into head position
  // (headDx/headDy) and body pose.
  const tiltRaw = p.stage === 1 ? 0 : (p.headRot ?? 0);
  const tilt = Math.max(-2, Math.min(2, tiltRaw));
  const tiltT = tg({ rot: tilt, ox: pivotX, oy: pivotY });
  const tiltWrap = (inner) => (tilt ? `<g${tiltT}>${inner}</g>` : inner);
  // the head assembly rides the body's squash + lean (stage 2+): the SAME
  // transform the body outline uses, so skull and face stay registered
  // through squash-and-stretch. The egg has no bodyUSTOM — never wrapped.
  const headWrap = (inner) => (p.stage === 1 ? inner : `<g${bodyX}>${tiltWrap(inner)}</g>`);

  // the tuft sits BEHIND the body so its closed base never shows as a seam
  const tuftO = { x: bx, y: S.head ? S.head.cy - S.head.r + 11 : by - bry + 10 };
  const tSx = (p.tuftSpread ?? 1) * (p.tuftScale ?? S.tuftScale ?? 1);
  const tSyRaw = (p.tuftLift ?? 1) * (p.tuftScale ?? S.tuftScale ?? 1);
  // safety: the crest compresses instead of clipping when the body flies high
  const tTop = tuftO.y - 48 * tSyRaw;
  const tSy = tTop < 15 ? Math.max(0.4, (tuftO.y - 15) / (48 * Math.max(tSyRaw, 0.01))) : tSyRaw;
  const tuftInner = S.has.tuft
    ? `<g id="head_tuft"${tg({ sx: tSx, sy: tSy, ox: tuftO.x, oy: tuftO.y })}>`
    + `<path d="${crestPath(0.25 + (p.tuftLean ?? 0) / 12)}"${tg({ tx: tuftO.x, ty: tuftO.y })} fill="${K.body}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/></g>`
    : '<g id="head_tuft" opacity="0"/>';
  const tuft = headWrap(tuftInner);

  /* Face: built ONLY by the face generator (face.mjs) — symmetric by
     construction. Emotion = eye shape + beak state + whole-head tilt.
     The generator draws the face STRAIGHT (tilt 0); the shared head tilt
     below rotates crest + face + cap + nightcap TOGETHER about the neck
     pivot, so the face can never slide inside its head (round 5 fix). */
  const eyeY = eyeY0;
  const head = headWrap(buildFace({
    stage: p.stage, cx: bx, eyeY,
    tx: htx0, ty: hty0, tilt: 0,
    ox: pivotX, oy: pivotY,
    eyeL: p.eyeL, eyeR: p.eyeR, eye: p.eye,
    scale: p.eyeScale, gaze: p.gaze, brow: p.brow,
    beak: p.beak, beakDy: p.beakDy, seed: p.seed, cheekPuff: p.cheekPuff,
  }).markup);


  /* accessories (always emitted, filled in by the accessory generator) */
  const night = p.nightcap
    ? headWrap(nightcap(bx,
      (p.stage === 4 ? S.head.cy - S.head.r + 2 : p.stage === 2 ? by - bry + 10 : by - bry + 1) + (p.headDy ?? 0),
      p.stage === 4 ? 1.1 : p.stage === 2 ? 0.9 : 1.05,
      -8))
    : '';
  const acc = `<g id="accessory_head">${night}</g><g id="accessory_neck"/><g id="accessory_face"/>`;

  let parts;
  const back = p.wingFront
    ? [shadow, tail, wingL, body, belly, hl, shellBot, feet]
    : [shadow, tail, wingL, wingR, body, belly, hl, shellBot, feet];
  // shell_top is always emitted so the artboard structure is identical across stages
  if (p.stage === 2) parts = [...back, headWrap(shellTop), tuft, head];
  else if (p.stage === 1) {
    // the egg: crown shell behind the face, base shell in front → the chick peeks through the crack
    const eggBack = [shadow, shellTop, tail, wingL, wingR, body, belly, hl, feet];
    parts = [...eggBack, tuft, head, shellBot];
  } else parts = [...back, tuft, head, shellTop];

  /* debug hook for qa.mjs (round 5 fix #4): eye centres in world coords +
     the head ellipse they must sit inside. Single source of truth — the same
     numbers that place the art. */
  const edx = 0.52 * FACE_R[p.stage];
  const htx = htx0, hty = hty0;
  const brotEff = p.stage === 1 ? 0 : brot;
  const sqEff = p.stage === 1 ? 1 : sx, syEff = p.stage === 1 ? 1 : sy;
  const toWorld = (lx, ly) => {
    const j = rotPt(lx + htx, ly + hty, tilt, pivotX, pivotY);
    const kx = B.cx + (j[0] - B.cx) * sqEff, ky = bottomY + (j[1] - bottomY) * syEff;
    return rotPt(kx, ky, brotEff, B.cx, bottomY);
  };
  const eyeW = (side) => toWorld(bx + (side === 'l' ? -edx : edx), eyeY);
  const beakWpos = toWorld(bx, eyeY + STAGE_FACE[p.stage].beak + (p.beakDy ?? 0));
  // head ellipse in world coords (body transform applied where one exists)
  const bc = [B.cx, B.cy], bo = [B.cx, bottomY];
  const bsc = [B.cx + (bc[0] - bo[0]) * sx, bo[1] + (bc[1] - bo[1]) * sy];
  const bcc = rotPt(bsc[0], bsc[1], brot, bo[0], bo[1]);
  let headEl;
  if (p.stage === 1) headEl = { cx: bx, cy: 214 - bry, rx: brx, ry: bry };
  else if (p.stage === 4) {
    const sc = rotPt(B.cx, S.head.cy, 0, 0, 0);
    const so = [B.cx, bottomY];
    const ss = [B.cx + (sc[0] - so[0]) * sx, so[1] + (sc[1] - so[1]) * sy];
    const sw = rotPt(ss[0], ss[1], brot, so[0], so[1]);
    headEl = { cx: sw[0], cy: sw[1], rx: S.head.r * sx, ry: S.head.r * sy };
  } else headEl = { cx: bcc[0], cy: bcc[1], rx: brx, ry: bry };
  const debug = { eyeL: eyeW('l'), eyeR: eyeW('r'), beak: beakWpos, head: headEl, tilt };

  return { parts: [...parts, acc, fxGroup(p.fx)], S, K, F, B, bx, by, brx, bry, bodyX, tuft, debug };
}

/* ---------- extra shapes used by accessories / evolve ---------- */

/* ---------- document ---------- */
export function svg(p) {
  const { parts, S } = buildParts(p);
  const label = `Pip v2 B Bolt · ${S.key} · ${p.mood} ${p.n}`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" width="240" height="240" role="img" aria-label="${label}">\n`
    + parts.join('\n') + `\n</svg>\n`;
}

export { pearPath, wingPath, featherPath, footPath, crestPath, songbirdPath, eggRing, ringEdgesAt };
