'use strict';
/**
 * build.js — writes every Lottie one-shot to `app/assets/animations/lottie/`.
 *
 *   node tools/lottie/build.js
 *
 * Also asserts the two invariants that matter in review: the file is under
 * 40 KB, and it contains no expressions or embedded images (Flutter's lottie
 * runtime supports neither, and both silently break rather than error).
 */

const fs = require('fs');
const path = require('path');

const { DURATIONS } = require('./lib/brand');

const OUT_DIR = path.join(__dirname, '..', '..', 'app', 'assets', 'animations', 'lottie');

const ASSETS = {
  check_tick: require('./src/check_tick'),
  coin_burst: require('./src/coin_burst'),
  confetti: require('./src/confetti'),
  badge_unlock: require('./src/badge_unlock'),
};

const MAX_BYTES = 40 * 1024;

/**
 * Fields Bodymovin writes for the After Effects round-trip that neither
 * lottie-web nor flutter lottie reads. Layer `nm` is **kept** — it is what
 * makes a file debuggable in a Lottie viewer and in review diffs; the
 * per-shape ones below are the redundant tail.
 *
 * Verified against the parsers: `nm`, `hd`, `ix`, `np`, `d` and `sr` are all
 * read into a name/hidden flag or skipped entirely
 * (`parser/{layer,shape_group,rectangle_shape,circle_shape}_parser.dart`),
 * so dropping them cannot change a rendered pixel.
 */
const REDUNDANT = new Set(['ix', 'np', 'hd', 'd']);

/**
 * Recursively drop redundant keys.
 *
 * Deliberately does **not** strip the all-zero `i`/`o` tangent arrays from
 * `sh` paths, even though they look like the obvious win (~2.2 KB across
 * confetti's 10 sparkles). Measured: removing them makes lottie-web throw
 * inside `ShapeProperty` and render nothing at all, so both tangents are load
 * bearing even when every handle is the identity. Verified, not assumed.
 *
 * Applied only when a file busts the 40 KB budget (see the `minify` call site).
 */
function minify(node) {
  if (Array.isArray(node)) return node.map(minify);
  if (node && typeof node === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(node)) {
      if (REDUNDANT.has(k)) continue;
      // `nm` on a non-layer node is a generic constant in every asset; keep it
      // only on layers, where it carries real information.
      if (k === 'nm' && (v === 'group' || v === 'tr' || v === 'fill' || v === 'stroke' || v === 'el' || v === 'rect' || v === 'path' || v === 'trim' || v === 'gf')) continue;
      out[k] = minify(v);
    }
    return out;
  }
  return node;
}

/**
 * How many layers are actually drawing at a given frame.
 *
 * A layer draws if it is in range (`ip <= f < op`) **and** its opacity at `f`
 * is non-zero — which is why "the last frame" is not a safe still: every
 * `confetti` piece has left the frame by then, and every `coin_burst` coin has
 * faded to 0. This mirrors the runtime's own test closely enough to catch a
 * still frame that would render as an empty box.
 */
function framesDrawnAt(comp, frame) {
  return comp.layers.filter((L) => {
    if (L.ip > frame || L.op <= frame) return false;
    const o = L.ks && L.ks.o;
    if (!o) return true;
    if (!o.a) return typeof o.k === 'number' ? o.k > 0 : o.k[0] > 0;
    let v = null;
    for (const k of o.k) {
      if (k.t <= frame) v = k.s[0];
    }
    return v === null || v > 0;
  }).length;
}

function fail(msg) {
  console.error(`\n  ✗ ${msg}\n`);
  process.exitCode = 1;
}

function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const rows = [];
  let bad = false;

  for (const [name, mod] of Object.entries(ASSETS)) {
    const comp = mod.build();
    // Minify only what needs it: small files stay fully readable in review.
    let json = JSON.stringify(comp);
    let minified = false;
    if (Buffer.byteLength(json) > MAX_BYTES) {
      json = JSON.stringify(minify(comp));
      minified = true;
    }

    // --- invariants -------------------------------------------------------
    if (json.includes('"x":"') || json.includes('"expr"')) {
      fail(`${name}: contains an expression — Flutter lottie has no expression engine.`);
      bad = true;
    }
    // Every layer needs a unique `ind`. lottie-web indexes its element array
    // by it, so a missing or duplicated value leaves a hole and *every* layer
    // in the file fails to render — a total blank output from a one-field
    // mistake, with no error surfaced to the author.
    const inds = comp.layers.map((l) => l.ind);
    if (inds.some((i) => i === undefined || i === null)) {
      fail(`${name}: a layer has no "ind" — the whole file will render blank.`);
      bad = true;
    } else if (new Set(inds).size !== inds.length) {
      fail(`${name}: duplicate layer "ind" values (${inds.join(', ')}).`);
      bad = true;
    }
    if (comp.assets && comp.assets.length > 0) {
      fail(`${name}: embeds assets (${comp.assets.length}) — must be pure vector shapes.`);
      bad = true;
    }
    const layers = comp.layers.length;
    if (comp.fr !== 60) {
      fail(`${name}: fr is ${comp.fr}, expected 60.`);
      bad = true;
    }
    const seconds = comp.op / comp.fr;
    if (Math.abs(seconds - DURATIONS[name]) > 1e-6) {
      fail(`${name}: duration ${seconds}s, expected ${DURATIONS[name]}s.`);
      bad = true;
    }

    // The reduced-motion still must be a frame that actually draws something.
    // `coin_burst` and `confetti` deliberately end empty (every layer has left
    // the frame), so "just use the last frame" is not a safe default — and a
    // still that renders nothing fails *silently* in the app, showing the user
    // an empty box where their celebration should be.
    const still = (comp.markers || []).find((m) => m.cm === 'still');
    if (!still) {
      fail(`${name}: no "still" marker — reduced motion has no frame to show.`);
      bad = true;
    } else if (still.tm <= 0 || still.tm >= comp.op) {
      fail(`${name}: still frame ${still.tm} is outside 0..${comp.op - 1}.`);
      bad = true;
    } else if (framesDrawnAt(comp, still.tm) === 0) {
      fail(`${name}: still frame ${still.tm} draws no layers — it would show an empty box.`);
      bad = true;
    }

    const bytes = Buffer.byteLength(json);
    if (bytes > MAX_BYTES) {
      fail(`${name}: ${(bytes / 1024).toFixed(1)} KB exceeds the 40 KB budget.`);
      bad = true;
    }

    const outFile = path.join(OUT_DIR, `${name}.json`);
    fs.writeFileSync(outFile, json);
    rows.push({
      name,
      size: `${(bytes / 1024).toFixed(1)} KB`,
      frames: comp.op,
      seconds: `${seconds.toFixed(2)}s`,
      dims: `${comp.w}×${comp.h}`,
      layers,
      minified,
      raw: bytes,
    });
  }

  const pad = (s, n) => String(s).padEnd(n);
  const lpad = (s, n) => String(s).padStart(n);
  console.log('\n  Lottie one-shots → app/assets/animations/lottie/\n');
  console.log(
    `  ${pad('file', 20)}${lpad('size', 9)}${lpad('frames', 8)}${lpad('dur', 7)}${lpad('layers', 8)}${lpad('comp', 10)}  notes`,
  );
  console.log(`  ${'-'.repeat(72)}`);
  for (const r of rows) {
    console.log(
      `  ${pad(`${r.name}.json`, 20)}${lpad(r.size, 9)}${lpad(r.frames, 8)}${lpad(r.seconds, 7)}${lpad(r.layers, 8)}${lpad(r.dims, 10)}  ${r.minified ? 'minified' : 'readable'}`,
    );
  }
  const total = rows.reduce((a, r) => a + r.raw, 0);
  console.log(`  ${'-'.repeat(60)}`);
  console.log(`  ${pad('total', 20)}${lpad(`${(total / 1024).toFixed(1)} KB`, 9)}\n`);

  if (bad) process.exit(1);
}

main();
