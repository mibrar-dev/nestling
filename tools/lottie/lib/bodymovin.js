'use strict';
/**
 * bodymovin.js — a tiny Bodymovin/Lottie JSON writer.
 *
 * Why this exists: Nestling's one-shots are generated, not hand-edited. The
 * Bodymovin format is verbose and extremely easy to get subtly wrong (a keyframe
 * holding the wrong arity renders as a silently broken property in Flutter), so
 * we build it from typed helpers that guarantee the arity of every animated
 * value and refuse expressions outright — Flutter's `lottie` package has no
 * expression engine, so any `x` field would be dead weight at runtime.
 *
 * Supported content types (exactly what flutter lottie 3.6.x parses):
 *   gr st gs fl gf tr sh el rc tm sr mm rd
 */

const FPS = 60;

/* ------------------------------------------------------------------ colour */

/** `#1E1B3A` / `#1e1b3a` → `[0.117, 0.106, 0.227, 1]` (Lottie wants 0..1 floats). */
function hex(color) {
  const s = color.replace('#', '').trim();
  const full =
    s.length === 3
      ? s
          .split('')
          .map((c) => c + c)
          .join('')
      : s;
  const n = parseInt(full, 16);
  return [
    ((n >> 16) & 255) / 255,
    ((n >> 8) & 255) / 255,
    (n & 255) / 255,
    1,
  ];
}

/** Linear blend of two hex colours, returns a Lottie colour array. */
function mix(a, b, t) {
  const ca = hex(a);
  const cb = hex(b);
  return [
    ca[0] + (cb[0] - ca[0]) * t,
    ca[1] + (cb[1] - ca[1]) * t,
    ca[2] + (cb[2] - ca[2]) * t,
    1,
  ];
}

/* ------------------------------------------------------------------ easing */

/**
 * Cubic-bezier control points, as Bodymovin stores them per keyframe.
 * `in` = the outgoing handle of the *previous* keyframe, `out` = the incoming
 * handle of this one. Bodymovin stores them inverted relative to CSS, which is
 * the single most common authoring mistake; these helpers keep the CSS mental
 * model: `cubicBezier(0.34, 1.56, 0.64, 1)` is `--motion-spring`.
 */
function cubicBezier(x1, y1, x2, y2) {
  return {
    i: { x: [x2], y: [y2] },
    o: { x: [x1], y: [y1] },
  };
}

const EASE = {
  /** Standard CSS `ease`. */
  standard: cubicBezier(0.25, 0.1, 0.25, 1),
  /** `ease-out` — decelerating, the default for anything entering the screen. */
  out: cubicBezier(0, 0, 0.58, 1),
  /** `ease-in` — accelerating, for exits. */
  in: cubicBezier(0.42, 0, 1, 1),
  /** `--motion-spring` from tokens.css: 320ms cubic-bezier(.34,1.56,.64,1). */
  spring: cubicBezier(0.34, 1.56, 0.64, 1),
  /** Soft overshoot used for the coin/check pops. */
  pop: cubicBezier(0.2, 1.5, 0.4, 1),
  /**
   * Linear must still emit explicit handles. flutter lottie tolerates a
   * keyframe with no `i`/`o` (`keyframe_parser.dart` falls back to
   * `Curves.linear`), but **lottie-web does not**: its
   * `KeyframedProperty.getValue` calls
   * `BezierFactory.getBezierEasing(keyData.o.x, keyData.o.y, keyData.i.x, keyData.i.y)`
   * with no guard, so a handle-less keyframe throws a TypeError, the throw is
   * swallowed by `renderFrame`'s try/catch, and the layer silently renders
   * nothing. Every non-final keyframe therefore always carries `i`/`o`.
   */
  linear: { i: { x: [1], y: [1] }, o: { x: [0], y: [0] } },
};

/**
 * Chain several easings over one keyframe segment.
 * Bodymovin supports per-segment handles on the *outgoing* keyframe only, so a
 * multi-curve move is expressed as extra keyframes. `segments` is
 * `[[frame, ease], ...]`; the final entry's frame is the end frame.
 */
function segmented(values, segments) {
  const keys = [];
  let prevOut = null;
  for (let i = 0; i < values.length; i += 1) {
    const [value, [frame, ease]] = [values[i], segments[i]];
    const isFirst = i === 0;
    const isLast = i === values.length - 1;
    const key = { t: frame, s: [].concat(value) };
    if (isFirst) {
      key.s = [].concat(value);
    } else if (prevOut) {
      key.o = prevOut.o;
      key.i = prevOut.i;
    }
    if (isLast) {
      // Bodymovin's last keyframe carries no handles.
      delete key.o;
      delete key.i;
    }
    keys.push(key);
    prevOut = ease;
  }
  return keys;
}

/* --------------------------------------------------------------- animatable */

const clone = (v) => JSON.parse(JSON.stringify(v));

/**
 * Trim a value to 2 components when its third is a no-op.
 *
 * Callers write 3-vectors because that is what After Effects does, but for
 * position/anchor the 3rd is always 0 and for scale always 100 — both are the
 * identity, and neither runtime reads them (`offsetParser` / `scaleXYParser`
 * each take two doubles then skip the rest). Doing it here rather than at 30
 * call sites keeps the sources readable and the output small.
 */
function trimZ(v) {
  if (!Array.isArray(v) || v.length < 3) return v;
  if (v.length === 3 && (v[2] === 0 || v[2] === 100)) return [v[0], v[1]];
  return v;
}

/** Wrap a constant value as a non-animated Lottie property. */
function val(v) {
  return { a: 0, k: trimZ(v) };
}

function strip(obj) {
  const out = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined) out[k] = v;
  }
  return out;
}

/**
 * Animated scalar or vector property.
 *
 * @param {number|number[]} value  constant value, or
 * @param {Array} keyframes         `[{ t, v, ease }]` when `value` is null.
 */
function anim(value, keyframes) {
  if (!keyframes) {
    return strip({ a: 0, k: value, ix: 1 });
  }
  const keys = keyframes.map((k, idx) => {
    // Bodymovin stores the *outgoing* bezier handle on the keyframe it starts
    // from, so the handle for segment k → k+1 rides on k. Reading it from
    // kframes[idx + 1] (the intuitive-looking version) silently serialises the
    // authoring `ease` field into the JSON as a literal key and applies the
    // wrong curve — hence `ease` must be destructured off, never spread.
    const { ease, v } = k;
    const isLast = idx === keyframes.length - 1;
    const key = { t: k.t, s: [].concat(trimZ(v)) };
    // Default to linear rather than omitting the handles: see EASE.linear.
    // The final keyframe is handle-less in real exports and both runtimes cope.
    if (isLast) return key;
    const h = ease || EASE.linear;
    key.o = h.o;
    key.i = h.i;
    if (k.hold) key.h = 1;
    return key;
  });
  return strip({ a: 1, k: keys, ix: 1 });
}

/* ------------------------------------------------------------------ shapes */

let _uid = 0;
const uid = () => (_uid += 1);

/**
 * Ellipse / rect geometry is stored as **animatable properties**, not bare
 * arrays: `EllShapePropertyFactory` calls
 * `PropertyFactory.getProp(elem, data.p, …)`, which dereferences `data.k`.
 * A bare `[x, y]` therefore throws
 * `TypeError: Cannot read properties of undefined (reading 'length')` inside
 * `getProp`, lottie-web swallows it in `renderFrame`'s try/catch and emits a
 * content-free `error` event — so the file "loads" and renders nothing.
 * Values here may be a raw array (wrapped as a static property) or an existing
 * property object, which is what lets a shape's size be keyframed.
 */
const geo = (v) => (v && typeof v === 'object' && !Array.isArray(v) ? v : val(v || [0, 0]));

/** `<ellipse>` — `size` and `pos` are [w, h] / [x, y]. */
function ellipse(size, pos) {
  return { ty: 'el', d: 1, s: geo(size), p: geo(pos || [0, 0]), nm: 'el' };
}

/** `<rect>` with optional corner radius. */
function rect(size, pos, radius) {
  return strip({
    ty: 'rc',
    d: 1,
    s: geo(size),
    p: geo(pos || [0, 0]),
    r: typeof radius === 'object' ? radius : val(radius || 0),
    nm: 'rect',
  });
}

/**
 * A closed/open bezier path from SVG-ish commands. Only the subset the
 * illustrations actually use is supported: M, L, Q, C, Z.
 * Tangents are derived the way Bodymovin stores them (relative handles on the
 * vertex), so the emitted JSON is directly comparable with a real export.
 */
function path(cmds, closed = true) {
  const v = [];
  const i = [];
  const o = [];
  let cur = [0, 0];
  let start = [0, 0];

  for (const c of cmds) {
    const cmd = c[0];
    if (cmd === 'M') {
      cur = [c[1], c[2]];
      start = cur;
      v.push(cur);
      i.push([0, 0]);
      o.push([0, 0]);
    } else if (cmd === 'L') {
      v.push([c[1], c[2]]);
      i.push([0, 0]);
      o.push([0, 0]);
      cur = [c[1], c[2]];
    } else if (cmd === 'Q') {
      // Quadratic → cubic with handles at 2/3 and 1/3 of the control offset.
      const [cx, cy, x, y] = [c[1], c[2], c[3], c[4]];
      v.push([x, y]);
      i.push([(cx - x) / 3, (cy - y) / 3]);
      o.push([
        (cx - cur[0]) / 3,
        (cy - cur[1]) / 3,
      ]);
      cur = [x, y];
    } else if (cmd === 'C') {
      const [, c1x, c1y, c2x, c2y, x, y] = c;
      v.push([x, y]);
      i.push([c2x - x, c2y - y]);
      o.push([c1x - cur[0], c1y - cur[1]]);
      cur = [x, y];
    } else if (cmd === 'Z') {
      // Bodymovin closes with `c: true`, not a trailing duplicate vertex: the
      // duplicate would add a zero-length segment that a trim path counts,
      // which is how a stroke ends up measuring twice as long as it draws.
      // Nothing to push — just remember we are back at the start.
      cur = start;
    }
  }

  // If the caller asked for a closed path but the commands did not end with an
  // explicit `Z` and the cursor is not already home, close it explicitly.
  if (closed && (cur[0] !== start[0] || cur[1] !== start[1])) {
    v.push(start);
    i.push([0, 0]);
    o.push([0, 0]);
  }

  return { ty: 'sh', d: 1, ks: strip({ a: 0, k: { c: closed, v, i, o }, ix: 2 }), nm: 'path', hd: false };
}

/**
 * The 4-point sparkle from `sparkles.svg` / `coins_burst.svg`:
 * `m32 30 5 14 14 5-14 5-5 14-5-14-14-5Z`.
 *
 * The source is **8** vertices — 4 points plus 4 waist notches — but the notches
 * sit on the line between two points, so at confetti size (11–19 px) the
 * 4-vertex form is visually identical and costs 40 % less JSON. The 8-vertex
 * version is kept for the hero sparkles in `coin_burst` / `badge_unlock`, where
 * it is drawn at 8–10 px inside a 260 px comp and the waist is clearly read.
 *
 * Closed with `c: true` and **no** trailing `Z` vertex: `Z` in the source SVG
 * is the path-closing operator, not a point, and pushing a duplicate start
 * vertex makes lottie draw a closing chord across the waist (a square).
 */
function sparklePath(r, waist = 0.36) {
  const w = r * waist;
  return path(
    [
      ['M', 0, -r],
      ['L', w, -w],
      ['L', r, 0],
      ['L', w, w],
      ['L', 0, r],
      ['L', -w, w],
      ['L', -r, 0],
      ['L', -w, -w],
    ],
    true,
  );
}

/**
 * Budget-sized sparkle.
 *
 * Measured, twice, and both times the obvious simplification lost:
 *  - a 4-vertex form with the waist in the **bezier handles** is *larger*
 *    than the 8-vertex straight-edge form — a non-zero tangent pair costs more
 *    than four zero-tangent vertices;
 *  - collapsing the waist notches out of the 8-vertex form turns the star into
 *    a plain square, because the notches are what make the edges concave.
 *
 * So vertices are the cheap unit and tangents are the expensive one, and the
 * only real size lever left is the *number* of sparkles. This form exists for
 * that reason: it is the cheapest legible 4-point star, and it is used only
 * where the size budget is genuinely tight.
 */
function sparklePath4(r, waist = 0.36) {
  const w = r * waist;
  return path(
    [
      ['M', 0, -r],
      ['L', w, -w],
      ['L', r, 0],
      ['L', w, w],
      ['L', 0, r],
      ['L', -w, w],
      ['L', -r, 0],
      ['L', -w, -w],
    ],
    true,
  );
}

function fill(color, opacity) {
  return {
    ty: 'fl',
    c: { a: 0, k: typeof color === 'string' ? hex(color) : color, ix: 4 },
    o: typeof opacity === 'object' ? opacity : val(opacity === undefined ? 100 : opacity),
    r: 1,
    bm: 0,
    nm: 'fill',
    hd: false,
  };
}

/**
 * Flatten gradient stops into the run lottie expects.
 *
 * **4 values per stop, and the first one is the POSITION, not the alpha**:
 *
 *     [ offset, r, g, b ]  ×  p
 *
 * lottie-web reads it as `cValues[i*4]` → `stop@offset` and
 * `cValues[i*4+1..3]` → `stop-color`. So writing RGBA — the shape `hex()`
 * returns, and the natural thing to reach for — shifts every channel by one:
 * the colour lands as `(g, b, a)` and a gold-and-white gradient comes out
 * magenta. It renders, so nothing warns; only looking at the frame catches it.
 *
 * The offset is a **0–1 fraction**, not a percentage: lottie-web does
 * `cValues[i*4] + '%'`, having already scaled it by 100
 * (`mult = i % 4 === 0 ? 100 : 255`). Passing 44 emits `stop@4400%`, every
 * stop clamps to the end, and the gradient flattens to a single colour — the
 * shine simply never appears, with no error anywhere.
 *
 * A tail of `p × (position, opacity)` pairs may follow when a stop needs its
 * own opacity; this generator does not use it, and omitting it is correct.
 */
const flatStops = (stops) => {
  const n = stops.length;
  const out = [];
  stops.forEach((s, i) => {
    const c = typeof s.c === 'string' ? hex(s.c) : s.c;
    const at = s.at !== undefined ? s.at : i / (n - 1);
    out.push(at, c[0], c[1], c[2]);
  });
  return out;
};

/**
 * Linear gradient fill (`gf`).
 *
 * `stops` is `[{ c, o }]` in order along the gradient. `startKf`/`endKf` are
 * optional keyframe lists for the gradient's `s` and `e` points, which is how
 * the badge's shine is done: the gradient *line* moves across the disc rather
 * than a shape moving over it, so it is clipped by the disc for free.
 *
 * Both runtimes parse `gf` (flutter lottie: `gradient_fill_parser.dart`).
 */
function gradientFill(stops, opacity, start, end, startKf, endKf) {
  return {
    ty: 'gf',
    o: typeof opacity === 'object' ? opacity : val(opacity === undefined ? 100 : opacity),
    r: 1,
    bm: 0,
    g: {
      p: stops.length,
      // Three levels, and every one of them matters:
      //   g.k          → a colour *property*  { a, k }
      //   g.k.k        → a **keyframe array**  [ { s: [r,g,b,a, r,g,b,a, …] } ]
      //   that `s`     → the flat run of stop values, p × (rgb + alpha)
      //
      // lottie-web's GradientProperty reads `data.k.k[0].s` to decide whether
      // the stops are keyframed, then `data.k.k[0].s.length - p*4` for the
      // trailing opacity stops. Getting any level wrong leaves `data.k.k[0]`
      // undefined, throws inside the SVGGradientFillStyleData constructor, and
      // the **whole layer** silently fails to build — the file loads, reports no
      // error, and renders nothing.
      //
      // flutter lottie's `GradientColor.parse` reads the same `s` array as a flat
      // sequence of doubles, so this shape satisfies both.
      k: {
        a: 0,
        k: [
          {
            t: 0,
            s: flatStops(stops),
            i: { x: [1], y: [1] },
            o: { x: [0], y: [0] },
          },
          { t: 1000, s: flatStops(stops) },
        ],
        ix: 4,
      },
    },
    s: startKf ? anim(null, startKf) : val(start || [0, 0]),
    e: endKf ? anim(null, endKf) : val(end || [200, 200]),
    t: 1,
    nm: 'gf',
    hd: false,
  };
}

function stroke(color, width, opts) {
  const o = opts || {};
  return strip({
    ty: 'st',
    c: { a: 0, k: typeof color === 'string' ? hex(color) : color, ix: 3 },
    o: o.opacity !== undefined ? o.opacity : val(100),
    w: typeof width === 'object' ? width : val(width),
    lc: o.cap === undefined ? 2 : o.cap, // 1 butt, 2 round, 3 square
    lj: o.join === undefined ? 2 : o.join, // 1 miter, 2 round, 3 bevel
    ml: 4,
    bm: 0,
    nm: 'stroke',
    hd: false,
  });
}

/**
 * Trim path. `m: 1` = simultaneously, `m: 2` = individually (what a stroked
 * squiggle wants so each segment draws on in sequence rather than all at once).
 */
function trim(start, end, offset, mode) {
  return strip({
    ty: 'tm',
    s: typeof start === 'object' ? start : val(start),
    e: typeof end === 'object' ? end : val(end),
    o: typeof offset === 'object' ? offset : val(offset || 0),
    m: mode || 1,
    nm: 'trim',
    hd: false,
  });
}

/** Group transform (`tr`) — the only nesting primitive we need. */
function groupTransform(transform) {
  return { ty: 'tr', ...transform, nm: 'tr' };
}

/**
 * A shape group.
 *
 * Callers pass items in **any** order; this sorts them into the only layout
 * lottie-web actually renders, and appends the `tr`:
 *
 *   1. geometry  (`sh`, `el`, `rc`, `sr`)
 *   2. styles     (`fl`, `st`, `gf`, `gs`)
 *   3. transforms (`tr`) and modifiers (`tm`, `rd`, …)
 *
 * Two lottie-web quirks make this worth enforcing mechanically. Both produce a
 * file whose JSON is perfectly valid and which renders **nothing**:
 *
 *   - a style placed *before* the geometry it paints emits a degenerate
 *     `M0 0` path, so `[fill, rect, tr]` draws nothing while `[rect, fill, tr]`
 *     draws correctly;
 *   - a group with no `tr`, or a shape placed flat on the layer instead of in a
 *     group, also renders nothing. The identity `tr` costs ~120 bytes and is
 *     not optional.
 *
 * Both were hit while building this set; each looked like a content bug and
 * was a layout one.
 */
const ITEM_ORDER = (ty) => {
  if (ty === 'sh' || ty === 'el' || ty === 'rc' || ty === 'sr') return 0;
  if (ty === 'fl' || ty === 'st' || ty === 'gf' || ty === 'gs') return 1;
  return 2;
};

function group(items, transform) {
  // Stable sort: equal-rank items keep the caller's relative order, so a
  // front-to-back list of several styles still behaves predictably.
  const list = items.filter(Boolean).slice().sort((a, b) => ITEM_ORDER(a.ty) - ITEM_ORDER(b.ty));

  // Reject a transform in the *items* list. It is a natural mistake — the
  // group's transform is the second argument, but `B.tr({})` inside the array
  // looks harmless — and the result is catastrophic and invisible: the bare
  // transform payload sorts to rank 2 and lands in `it` as an object with no
  // `ty`, and lottie-web then fails to build the *layer*, so the entire
  // composition renders blank. The stray entry is why an otherwise-valid
  // gradient fill also produced nothing.
  const dup = list.findIndex((i) => !i.ty);
  if (dup !== -1) {
    throw new Error(
      `bodymovin.group(): item ${dup} has no "ty" (${JSON.stringify(list[dup]).slice(0, 60)}…). ` +
        'That is almost always B.tr(...) passed inside the items array — the group ' +
        'transform belongs in the second argument.',
    );
  }

  list.push(groupTransform(transform || {}));
  return { ty: 'gr', it: list, nm: 'group', np: list.length };
}

/**
 * Pick a property: animated (`a: 1`, keyframes) when a `*Kf` list is supplied,
 * otherwise a static `a: 0` value. Both paths go through `anim`/`val` so the
 * z-trim and the `ease` → `i`/`o` conversion happen exactly once.
 */
function prop(staticValue, keyframes) {
  return keyframes ? anim(null, keyframes) : val(staticValue);
}

/** Build the `tr` payload for a group with sensible defaults. */
function tr(overrides) {
  const o = overrides || {};
  return strip({
    a: prop(o.anchor || [0, 0], o.anchorKf),
    p: prop(o.position || [0, 0], o.positionKf),
    s: prop(o.scale || [100, 100], o.scaleKf),
    r: o.rotation !== undefined ? (typeof o.rotation === 'object' ? o.rotation : val(o.rotation)) : val(0),
    o: prop(o.opacity === undefined ? 100 : o.opacity, o.opacityKf),
    sk: val(o.skew === undefined ? 0 : o.skew),
    sa: val(0),
  });
}

/* ------------------------------------------------------------------- layer */

/**
 * Shape layer (`ty: 4`).
 *
 * @param {string} name
 * @param {Array}  shapes  content items, **front-most first** (Lottie draws
 *                         the last item in the array first).
 * @param {object} ks      layer transform; see `layerTransform()`.
 * @param {object} extra   `ip`, `op`, `ind`, `parent`.
 *
 * `ip` and `op` are the layer's in/out points, and they are how a one-shot
 * "finishes": when a layer's `op` is reached it stops drawing. Every layer
 * that has left the screen sets `op` to the frame it finished on, so the
 * composition's last frame is genuinely empty for the assets that end by
 * leaving (`coin_burst`, `confetti`) rather than by fading out.
 */
function shapeLayer(name, shapes, ks, extra) {
  const e = extra || {};
  return strip({
    ddd: 0,
    // `ind` is mandatory. lottie-web builds its element array by pushing onto
    // `ind`, so a layer without one produces a hole in `renderer.elements` and
    // every layer then fails `prepareFrame is not a function` — the whole
    // composition renders nothing, for a reason that has nothing to do with
    // the layer's own content. Default to 1 so a caller that forgets it still
    // gets a valid file.
    ind: e.ind === undefined ? 1 : e.ind,
    ty: 4,
    nm: name,
    sr: 1,
    ks: ks || layerTransform(),
    ao: 0,
    shapes,
    ip: e.ip === undefined ? 0 : e.ip,
    op: e.op === undefined ? 0 : e.op,
    st: 0,
    bm: 0,
  });
}

function layerTransform(overrides) {
  const o = overrides || {};
  return strip({
    o: prop(100, o.opacityKf),
    r: o.rotation !== undefined ? (typeof o.rotation === 'object' ? o.rotation : val(o.rotation)) : val(0),
    p: prop(o.position || [0, 0], o.positionKf),
    a: prop(o.anchor || [0, 0], o.anchorKf),
    s: prop(o.scale || [100, 100], o.scaleKf),
  });
}

/* -------------------------------------------------------------- composition */

/**
 * Build the composition.
 *
 * `still` is the frame the **reduced-motion** fallback seeks to. It is written
 * into the file as a `still` marker so the Flutter side never has to hard-code
 * a frame number in a widget — see `docs/animation/LOTTIE.md` for the
 * `MediaQuery.disableAnimations` rule that reads it.
 *
 * Choose it as the frame where the asset is in its most complete, most
 * representative state, which is not always the last frame: `coin_burst` and
 * `confetti` end empty because every layer has left the screen, so for those
 * `still` is mid-burst.
 */
function composition({ name, w, h, frames, layers, markers, still }) {
  const op = Math.round(frames * FPS);
  const mk = markers ? markers.slice() : [];
  if (still !== undefined) {
    mk.push({ tm: still, cm: 'still', dr: 0 });
  }
  return strip({
    v: '5.7.4',
    fr: FPS,
    ip: 0,
    op,
    w,
    h,
    nm: name,
    ddd: 0,
    assets: [],
    layers,
    markers: mk,
  });
}

module.exports = {
  FPS,
  hex,
  mix,
  EASE,
  cubicBezier,
  anim,
  val,
  ellipse,
  rect,
  path,
  sparklePath,
  sparklePath4,
  fill,
  gradientFill,
  stroke,
  trim,
  group,
  tr,
  shapeLayer,
  layerTransform,
  composition,
  uid,
  clone,
};
