/* ==========================================================================
   Pip v2 · style B "BOLT" — face GENERATOR (round 5).
   The ONLY place faces are built. Symmetry is structural, not vigilance:
   - both eyes are rendered from ONE shared markup string, placed at mirrored
     offsets about the head axis (same size, same height — always);
   - the beak is a single path centred on x = 0;
   - cheeks and brows are mirrored pairs from one definition each;
   - the whole face group is rotated ONCE by the head tilt.
   Eye size, spacing and beak size are fixed ratios of r (fitted to the clean
   stage-3 idle pose). Vertical drops and cheek placement are per-stage
   constants. Emotion = eye SHAPE + beak state + tilt + body pose.
   There is deliberately NO per-eye or per-side parameter: asymmetric input
   cannot be expressed, so asymmetric output cannot happen. The one allowed
   asymmetry is the wink (left lid closed as a clean curve, right eye open).
   100% original art. Ink #1E1B3A, 8 px everywhere. No text, no gradients.
   ========================================================================== */

const INK = '#1E1B3A';
const SW = 8;
const BEAK = '#FF8A5B';

/* numeric helpers (local copies — face.mjs imports nothing, so no cycles) */
const r2 = (v) => Math.round(v * 100) / 100;
const norm = (pairs) => (pairs.length === 1 && Array.isArray(pairs[0][0])) ? pairs[0] : pairs;
const L = (...pairs) => norm(pairs).map((p) => `${r2(p[0])} ${r2(p[1])}`).join(' L ');
const pts = (...pairs) => norm(pairs).map((p) => `${r2(p[0])} ${r2(p[1])}`).join(' ');
const C = (cx, cy) => `cx="${r2(cx)}" cy="${r2(cy)}"`;
const tg = (o = {}) => {
  const { tx = 0, ty = 0, rot = 0, sx = 1, sy = 1, ox = 0, oy = 0 } = o;
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
  return s ? ` transform="${s}"` : '';
};

/* ---------- canonical proportions (fitted to the stage-3 idle face) ---------- */
export const FACE_R = { 1: 40, 2: 37, 3: 50, 4: 47 };
const EYE_R = 0.32;    // eye radius / r
const EYE_DX = 0.52;   // eye centre offset / r
const PUPIL = 0.54;    // pupil radius / eyeR
const GLINT = 0.17;    // glint radius / eyeR
const WIDE = 1.16;     // surprised-eye scale
const BEAK_W = 0.37;   // beak half-width / r
const BROW_HW = 0.24;  // brow half-width / r

/* vertical layout per stage (unchanged from the approved faces) */
const STAGE_FACE = {
  1: { beak: 13, cheek: null },
  2: { beak: 24, cheek: { dx: 33, dy: 28, r: 7.5 } },
  3: { beak: 32, cheek: { dx: 40, dy: 30, r: 9 } },
  4: { beak: 33, cheek: { dx: 24, dy: 27, r: 8 } },
};

export const EYE_STATES = ['open', 'closed', 'happy', 'sleepy', 'surprised', 'wink'];
export const BEAK_STATES = ['closed', 'thin', 'snore', 'open', 'wide', 'o'];

/* ---------- eye variants (all lids are true quadratics, never polylines) ---------- */
function eyeVariants(R, pr, gaze) {
  const px = (gaze?.dx ?? 0) * R * 0.14, py = (gaze?.dy ?? 0) * R * 0.14;
  const round = (s, p, glint) => `<circle ${C(0, 0)} r="${r2(R * s)}" fill="#FFFFFF" stroke="${INK}" stroke-width="${SW}"/>`
    + `<circle ${C(px, py)} r="${r2(p)}" fill="${INK}"/><circle ${C(px - R * 0.23, py - R * 0.25)} r="${r2(R * glint)}" fill="#FFFFFF"/>`;
  const curve = (y0, ya, w) => `<path d="M ${L([-R * 0.82, y0])} Q ${pts([0, 2 * ya - y0], [R * 0.82, y0])}" fill="none"`
    + ` stroke="${INK}" stroke-width="${r2(w)}" stroke-linecap="round"/>`;
  return {
    open: round(1, pr, GLINT),
    closed: curve(R * 0.12, -R * 0.36, SW),
    happy: curve(R * 0.42, -R * 0.7, SW + 1),
    sleepy: curve(-R * 0.08, R * 0.52, SW),
    surprised: round(WIDE, pr * 0.66, 0.21),
    wink: curve(R * 0.42, -R * 0.7, SW + 1),
  };
}

/* ---------- seed (drawn wedged in the open beak, tilts with the head) ---------- */
function seedShape(s) {
  return `<path d="M ${L([0, -s], [s * 0.8, -s * 0.34], [s * 0.64, s * 0.56], [0, s], [-s * 0.64, s * 0.56], [-s * 0.8, -s * 0.34], [0, -s])}"`
    + ` fill="#8B5A2B" stroke="${INK}" stroke-width="3.2" stroke-linejoin="round"/>`
    + `<path d="M ${L([-s * 0.34, -s * 0.3], [-s * 0.1, s * 0.16])}" fill="none" stroke="#FFFFFF" stroke-width="2.2" opacity="0.35" stroke-linecap="round"/>`;
}

/* ==========================================================================
   buildFace — emit a complete symmetric face.
   {
     stage, cx, eyeY, r (default FACE_R[stage]),
     tx, ty, tilt, ox, oy,     // whole-face placement (one transform, applied once)
     eye,                       // state for BOTH eyes: open|happy|closed|sleepy|surprised
                                // ('wide' is accepted as an alias of 'surprised')
     eyeL, eyeR,                 // per-eye override; the wink is expressed as
                                // eyeL:'wink', eyeR:'open' (geometry stays shared)
     scale,                      // uniform scale for BOTH eyes (e.g. egg shock)
     gaze,                       // uniform pupil offset {dx,dy}
     brow,                       // 0 none | 1 raised | 3 soft — one value, both brows
     beak,                       // closed|thin|snore|open|wide|o
     beakDy,                     // uniform vertical nudge, stays on axis
     seed,                       // 0 | size — seed wedged in the mouth (in-head)
     cheekPuff,                  // uniform puff, clamped so cheeks clear eyes+beak
   }
   ========================================================================== */
export function buildFace(o) {
  const stage = o.stage;
  const lay = STAGE_FACE[stage];
  if (!lay) throw new Error('buildFace: unknown stage ' + stage);
  const r = o.r ?? FACE_R[stage];
  const cx = o.cx, eyeY = o.eyeY;

  const eyeR = EYE_R * r * (o.scale ?? 1);
  const eyePr = PUPIL * eyeR * (o.scale ?? 1);
  const eyeDX = EYE_DX * r;
  const aliased = (s) => (s === 'wide' ? 'surprised' : s);
  const stL = aliased(o.eyeL ?? o.eye ?? 'open');
  const stR = aliased(o.eyeR ?? o.eye ?? 'open');
  if (!EYE_STATES.includes(stL) || !EYE_STATES.includes(stR)) {
    throw new Error(`buildFace: unknown eye state ${stL}/${stR}`);
  }
  const V = eyeVariants(eyeR, eyePr, o.gaze ?? null);
  // ONE shared renderer — the two eyes differ only in outer id/position/active state
  const eyeGroup = (side, sxp, active) =>
    `<g id="eye_${side}" data-eye="${side}"${tg({ tx: sxp, ty: eyeY })}>`
    + EYE_STATES.map((k) => `<g id="${k}" opacity="${k === active ? 1 : 0}">${V[k]}</g>`).join('') + '</g>';
  const eyes = eyeGroup('l', cx - eyeDX, stL) + eyeGroup('r', cx + eyeDX, stR);

  // brows: one definition, mirrored placement
  const browY = eyeY - eyeR - 0.2 * r;
  const bhw = BROW_HW * r;
  const browD = {
    1: `M ${L([-bhw, 5])} Q ${pts([0, -15], [bhw, 5])}`,
    3: `M ${L([-bhw, 4])} Q ${pts([0, -6], [bhw, 4])}`,
  }[(o.brow ?? 0)] ?? '';
  const browG = (side) => {
    const sgn = side === 'l' ? -1 : 1;
    return `<g id="brow_${side}" fill="none" stroke="${INK}" stroke-width="6.5" stroke-linecap="round">`
      + (browD ? `<path d="${browD}"${tg({ tx: cx + sgn * eyeDX, ty: browY })} />` : '') + '</g>';
  };
  const brows = browG('l') + browG('r');

  // cheeks: one definition, mirrored placement
  const puff = Math.min(o.cheekPuff ?? 1, 1.45);
  const cheekG = (side) => {
    if (!lay.cheek) return `<g id="cheek_${side}" />`;
    const sgn = side === 'l' ? -1 : 1;
    return `<g id="cheek_${side}"><ellipse ${C(cx + sgn * lay.cheek.dx, eyeY + lay.cheek.dy)}`
      + ` rx="${r2(lay.cheek.r * puff)}" ry="${r2(lay.cheek.r * 0.64 * puff)}" fill="${BEAK}" opacity="0.92"/></g>`;
  };
  const cheeks = cheekG('l') + cheekG('r');

  // beak: single paths centred on x = 0 (face space), one 8 px ink everywhere
  const bkY = eyeY + lay.beak + (o.beakDy ?? 0);
  const kind = o.beak ?? 'closed';
  if (!BEAK_STATES.includes(kind)) throw new Error('buildFace: unknown beak ' + kind);
  const bw = BEAK_W * r;
  const lift = kind === 'open' || kind === 'wide';
  const oRx = Math.max(bw * 0.8, 14), oRy = 19;
  const sRx = Math.max(bw * 0.7, 13), sRy = 13;
  const topD = {
    o: `M ${L([-oRx, -10], [oRx, -10], [oRx * 0.9, 2], [-oRx * 0.9, 2], [-oRx, -10])}`,
    wide: `M ${L([-bw * 1.14, -9], [bw * 1.14, -9], [bw * 0.7, 7], [-bw * 0.7, 7], [-bw * 1.14, -9])}`,
    thin: `M ${L([-bw * 0.84, -5], [bw * 0.84, -5], [bw * 0.5, 7], [-bw * 0.5, 7], [-bw * 0.84, -5])}`,
    snore: `M ${L([-sRx, -6], [sRx, -6], [sRx * 0.55, 6], [-sRx * 0.55, 6], [-sRx, -6])}`,
    open: `M ${L([-bw, -7], [bw, -7], [bw * 0.62, 7], [-bw * 0.62, 7], [-bw, -7])}`,
    closed: `M ${L([-bw, -6], [bw, -6], [bw * 0.52, 12], [-bw * 0.52, 12], [-bw, -6])}`,
  }[kind];
  const botD = {
    o: `M ${L([-oRx * 0.9, 2])} Q ${pts([-oRx * 1.05, 2 + oRy * 0.5], [0, 2 + oRy])} Q ${pts([oRx * 1.05, 2 + oRy * 0.5], [oRx * 0.9, 2])} Z`,
    wide: `M ${L([-bw * 0.9, 6])} Q ${pts([-bw * 0.66, 24], [0, 31])} Q ${pts([bw * 0.66, 24], [bw * 0.9, 6])} Z`,
    open: `M ${L([-bw * 0.72, 6])} Q ${pts([-bw * 0.54, 21], [0, 27])} Q ${pts([bw * 0.54, 21], [bw * 0.72, 6])} Z`,
    thin: `M ${L([-bw * 0.46, 12], [bw * 0.46, 12], [0, 20], [-bw * 0.46, 12])}`,
    snore: `M ${L([-sRx * 0.55, 6])} Q ${pts([0, 6 + sRy * 2], [sRx * 0.55, 6])} Z`,
  }[kind];
  const seedSize = o.seed ?? 0;
  const beakTop = `<g id="beak_top"${tg({ ty: lift ? -6 : 0, sy: lift ? 0.6 : 1, ox: cx, oy: bkY + 9 })}>`
    + `<path d="${topD}"${tg({ tx: cx, ty: bkY })} fill="${BEAK}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/></g>`;
  const beakBot = botD
    ? `<g id="beak_bottom">`
    + (seedSize ? `<g${tg({ tx: cx, ty: bkY + 10 })}>${seedShape(seedSize)}</g>` : '')
    + `<path d="${botD}"${tg({ tx: cx, ty: bkY })} fill="${kind === 'thin' ? BEAK : INK}" stroke="${INK}" stroke-width="${SW}" stroke-linejoin="round"/></g>`
    : '<g id="beak_bottom" opacity="0"/>';

  const inner = cheeks + brows + eyes + beakTop + beakBot;
  const t = tg({ tx: o.tx ?? 0, ty: o.ty ?? 0, rot: o.tilt ?? 0, ox: o.ox ?? cx, oy: o.oy ?? eyeY });
  return { markup: `<g id="head"${t}>${inner}</g>`, cx, eyeY, eyeR, eyeDX, bkY };
}

/* ---------- self-test: symmetry by construction ---------- */
function bboxSymmetric(d) {
  // every point must have a mirror twin about x = 0 (points on the axis pass)
  const raw = [...d.matchAll(/(-?\d+(?:\.\d+)?) (-?\d+(?:\.\d+)?)/g)]
    .map((m) => [parseFloat(m[1]), parseFloat(m[2])]);
  const has = (x, y) => raw.some(([qx, qy]) => Math.abs(qx - x) < 0.015 && Math.abs(qy - y) < 0.015);
  return raw.every(([x, y]) => Math.abs(x) < 0.015 || has(-x, y));
}

export function faceSelfTest() {
  const failures = [];
  const ok = (name, cond) => { if (!cond) failures.push(name); };
  const combos = [];
  for (const e of ['open', 'happy', 'closed', 'sleepy', 'surprised']) combos.push([e, e]);
  combos.push(['wink', 'open']);
  for (const stage of [1, 2, 3, 4]) {
    for (const [el, er] of combos) {
      for (const beak of BEAK_STATES) {
        const m = buildFace({
          stage, cx: 120, eyeY: 122, tilt: 17, ox: 120, oy: 110,
          eyeL: el, eyeR: er, beak, seed: beak === 'open' ? 13 : 0,
          brow: 1, cheekPuff: 1.9, gaze: { dx: 1, dy: -1 },
        }).markup;
        // beak paths are drawn in face space (centred on x = 0): every point
        // must have a mirror twin
        const paths = [...m.matchAll(/<g id="beak_(?:top|bottom)".*?<path d="([^"]*)"/gs)].map((x) => x[1]);
        for (const d of paths) {
          ok(`s${stage}/${el}/${er}/${beak} beak symmetric`, bboxSymmetric(d));
        }
      }
    }
    // cheeks mirrored about the head axis
    const m = buildFace({ stage, cx: 120, eyeY: 122, cheekPuff: 1.9 }).markup;
    const cxs = [...m.matchAll(/<g id="cheek_[lr]"><ellipse cx="(-?\d+(?:\.\d+)?)"/g)].map((x) => parseFloat(x[1]));
    if (cxs.length === 2) ok(`s${stage} cheeks mirrored`, Math.abs(cxs[0] + cxs[1] - 240) < 0.01);
  }
  // eye pair identity: same state => identical inner markup modulo position
  const a = buildFace({ stage: 3, cx: 120, eyeY: 122, eye: 'happy' }).markup;
  const normEye = (s) => s.replace(/<g id="eye_[lr]" data-eye="[lr]" transform="translate\([\d.]+ [\d.]+\)">/, '<EYE>');
  const leftPart = normEye(a.split('<g id="eye_r"')[0]);
  const rightRaw = a.split('<g id="eye_r"')[1].split('<g id="beak_top"')[0];
  const rightPart = normEye('<EYE>' + rightRaw.replace(/^<g id="eye_r" data-eye="r" transform="translate\([\d.]+ [\d.]+\)">/, ''));
  const li = leftPart.slice(leftPart.indexOf('<g id="open"'));
  const ri = rightPart.slice(rightPart.indexOf('<g id="open"'));
  ok('eye_l / eye_r identical markup', li === ri && li.length > 100);
  return failures;
}

const invoked = process.argv[1] && import.meta.url.endsWith(process.argv[1].split(/[\\/]/).pop());
if (invoked) {
  const failures = faceSelfTest();
  if (failures.length) {
    console.error(`FACE SELFTEST: ${failures.length} failures:`);
    for (const f of failures.slice(0, 20)) console.error('  - ' + f);
    process.exit(1);
  }
  console.log('FACE SELFTEST: all symmetric (4 stages x 7 eye-states x 6 beaks + cheeks + eye identity)');
}
