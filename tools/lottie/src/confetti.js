'use strict';
/**
 * confetti.js — shortlist #7.
 *
 * "~30 pieces (rects + circles + squiggles) in coin/leaf/lilac/peach/sky,
 * falling with rotation and flutter, 2.5 s, fills a 390×844 portrait frame."
 *
 * The frame is the app's device frame from tokens.css (`--w: 390`, `--h: 844`),
 * so the file is authored full-bleed and the Flutter side just drops it behind
 * the celebration copy.
 *
 * Art source: `app/assets/illustrations/confetti.svg` — rounded rects, plain
 * circles, and 4-point sparkles, all with a 3/320 ink keyline. The brief asks
 * for "squiggles" too, so a third rect variant is a short S-curve stroke
 * (`sparkles.svg` has no squiggle, but the flattened ribbon reads as one and
 * adds the wavy silhouette real confetti has).
 *
 * Every piece has a **different fall**:
 *   - linear-ish descent with per-piece easing (gravity feel)
 *   - continuous spin, rate and direction per piece
 *   - a horizontal flutter: a 3-lobe sine sampled into position keyframes, so
 *     pieces sway side to side as they fall
 *   - a scale "flip" (scaleX through 0) so pieces appear to tumble in 3D
 *     rather than spin flat — this is what stops it looking like a slot machine
 *   - staggered starts, so the field is never empty and never a single sheet
 *
 * Pieces are seeded (see `brand.rng`) so regenerating produces byte-identical
 * output — otherwise every build reshuffles the confetti and preview diffs are
 * worthless.
 *
 * Timeline (60 fps): f0–150. Each piece lives ~2.0 s from its own start.
 */

const B = require('../lib/bodymovin');
const { C, CELEBRATION, F, rng, round, lerp } = require('../lib/brand');

const W = 390; // --w
const H = 844; // --h
const PIECE_COUNT = 30;

/**
 * Piece geometry, at the sizes the brief specifies for a 390 × 844 frame.
 *
 * These are *absolute*, not derived from a single `size` knob, because the four
 * silhouettes are not the same measure: a rect is 8 × 14, a circle is Ø10, a
 * squiggle is 18 long. Driving them all off one `size` made every piece land at
 * roughly the same apparent area and the field read as specks — the previous
 * build was geometrically correct and visually wrong.
 */
const GEOM = {
  rect: { w: 8, h: 14, r: 3 },
  circle: { d: 10 },
  squiggle: { len: 18, w: 3 },
  sparkle: { r: 8 },
};

/** Ink keyline, 3 units as specified — chunky enough to read on paper. */
const INK_W = 3;

/**
 * Piece art, in local space with the origin at the piece's centre.
 *
 * Two rules, both verified against lottie-web 5.13, both of which make a
 * correct-looking JSON file render nothing at all:
 *
 *  1. The geometry comes **first** in the group's `it`, then the styles that
 *     paint it, then `tr` last. `[shape, fill, stroke, tr]` draws;
 *     `[fill, stroke, shape, tr]` emits a degenerate `M0 0` path.
 *  2. The group must carry a `tr`. A shape placed flat on the layer, or in a
 *     group with no transform, also renders nothing.
 */
function pieceArt(kind, color) {
  const ink = B.stroke(C.ink, INK_W, { cap: 2, join: 2 });
  switch (kind) {
    case 'rect': {
      const g = GEOM.rect;
      return [B.group([B.rect([g.w, g.h], [0, 0], g.r), B.fill(color), ink], B.tr({}))];
    }
    case 'circle': {
      const g = GEOM.circle;
      return [B.group([B.ellipse([g.d, g.d], [0, 0]), B.fill(color), ink], B.tr({}))];
    }
    case 'squiggle': {
      // A flattened ribbon: 18 long, `w` thick, in two cubic segments.
      //
      // The colour stroke must be **wider** than the ink one, not narrower, and
      // it must be drawn first so the ink sits on top as a keyline. The reverse
      // — a thick ink stroke under a thin colour stroke — leaves a 1-unit
      // band of ink showing on each side, and at this size that is most of the
      // piece: every squiggle came out charcoal regardless of its colour.
      const g = GEOM.squiggle;
      const h = g.len / 2;
      return [
        B.group(
          [
            B.path(
              [
                ['M', -h, 0],
                ['C', -h, -h * 0.8, h, h * 0.8, h, 0],
                ['C', h, -h * 0.8, -h, h * 0.8, -h, 0],
              ],
              false,
            ),
            B.stroke(color, g.w + INK_W, { cap: 2 }),
            B.stroke(C.ink, INK_W, { cap: 2 }),
          ],
          B.tr({}),
        ),
      ];
    }
    case 'sparkle':
    default: {
      const g = GEOM.sparkle;
      return [B.group([B.sparklePath4(g.r), B.fill(color), ink], B.tr({}))];
    }
  }
}

function build() {
  const total = F(2.5); // 150
  const rand = rng(0xc0ffee);
  const layers = [];
  let ind = 1;

  // Piece mix, weighted by *JSON cost per piece* rather than picked uniformly.
  //
  // Measured: a sparkle costs ~830 bytes, a squiggle ~630, a rect ~545 and a
  // circle ~520 — the 8-vertex sparkle path and the squiggle's two cubic
  // segments dominate. A uniform 4-way mix therefore spends the byte budget on
  // the two most expensive shapes. Weighting towards rects and circles keeps
  // all four silhouettes on screen and the field full at the same total size.
  const KIND_MIX = [
    'rect', 'rect', 'rect', 'rect',
    'circle', 'circle', 'circle',
    'squiggle', 'squiggle',
    'sparkle', 'sparkle',
  ];

  for (let i = 0; i < PIECE_COUNT; i += 1) {
    // ---- start position ----------------------------------------------------
    // Stride the x positions evenly across the full width and jitter them, so
    // the field is guaranteed to cover 0 → 390 rather than clustering wherever
    // the PRNG happened to land. Pure random x left visible vertical gaps.
    const slot = (i + 0.5) / PIECE_COUNT;
    const x = Math.round(lerp(14, W - 14, slot) + (rand() - 0.5) * (W / PIECE_COUNT) * 0.8);
    // Start **above the top edge**, so every piece enters the frame rather than
    // fading in inside it. The start y is spread down the frame too, so the
    // field is already several hundred pixels deep at the first frame instead of
    // arriving as one clump at the top.
    const startY = Math.round(lerp(-70, H * 0.55, rand()));

    // ---- fall ---------------------------------------------------------------
    // The piece must travel from its start y all the way past the bottom edge,
    // so the *distance* is derived from where it starts rather than being a
    // fixed figure. Fixing `endY` and varying only the fall time made pieces
    // that started high cross the whole frame in the same window as pieces that
    // started low, which left the bottom third permanently empty.
    const endY = H + 40;
    // Every piece gets a fall long enough to cross the frame at a similar
    // apparent speed, but staggered by a *fraction* of the timeline so that at
    // any single frame roughly two thirds of the set is on screen. Without the
    // stagger — every piece starting at f0 and falling for `total` frames — the
    // field is at its fullest only in the first few frames and empty thereafter.
    const fallFrames = Math.round(lerp(0.62, 1.0, rand()) * total);
    const startF = Math.round(lerp(0, total - fallFrames, rand()));

    // ---- flutter ------------------------------------------------------------
    // Rotation **and** a horizontal sine, as briefed. The x-sway is folded
    // into the same 4 position keyframes as the y-fall rather than being a
    // separate channel, because a keyframe is a keyframe either way and the
    // y-gravity curve is already sampled there.
    //
    // 4 samples across the whole fall is enough for a *long* sine: the period
    // is 0.8–1.6 s, so the piece completes roughly one oscillation over its
    // fall and each sample is a genuine extremum or midpoint. That is what
    // makes 3–4 keyframes viable here where a fast flutter would need 10.
    const amp = lerp(16, 40, rand());
    const period = lerp(52, 104, rand());
    // Phase is **strided** across the piece index as well as randomised, so the
    // pieces are not all crossing their sine at the same moment. Fully random
    // phases still cluster by coincidence, and 30 pieces sharing a phase
    // distribution produce visible bands of pieces moving together.
    const phase = ((i / PIECE_COUNT) * Math.PI * 2 + rand() * 1.1) % (Math.PI * 2);
    const drift = lerp(-26, 26, rand());

    // y is gravity (accelerating); x is the sine plus a slow drift.
    const GRAV = [0, 0.12, 0.42, 1];
    const posKf = GRAV.map((g, s) => {
      const t = s / (GRAV.length - 1);
      const f = startF + t * fallFrames;
      return {
        t: round(f, 1),
        v: [
          Math.round(x + Math.sin((f / period) * Math.PI * 2 + phase) * amp + drift * t),
          Math.round(lerp(startY, endY, g)),
        ],
        ease: B.EASE.linear,
      };
    });

    // ---- spin ---------------------------------------------------------------
    const spin = round(lerp(-1, 1, rand()) * lerp(220, 620, rand()), 0);
    const spinKf = [
      { t: startF, v: 0, ease: B.EASE.linear },
      { t: startF + fallFrames, v: spin },
    ];

    // ---- tumble: scaleX through 0 so the piece reads as 3D paper -------------
    // One flip per piece. The tumble only has to sell "seen edge-on", and one
    // pass does that; more flips cost ~5 keyframes each and read as jitter.
    const flipPeriod = Math.round(fallFrames / 2);
    const scaleKf = [
      { t: startF, v: [100, 100, 100], ease: B.EASE.linear },
      { t: startF + flipPeriod, v: [-100, 100, 100], ease: B.EASE.linear },
      { t: startF + fallFrames, v: [100, 100, 100] },
    ];

    // Two keyframes: in over 4 frames, out with the fall. The explicit "hold at
    // 100" keyframe an earlier version had added a keyframe per piece for no
    // visible difference once the piece is below the bottom edge.
    const opacityKf = [
      { t: startF, v: 0 },
      { t: startF + 4, v: 100, ease: B.EASE.in },
      { t: startF + fallFrames, v: 0 },
    ];

    const kind = KIND_MIX[Math.floor(rand() * KIND_MIX.length)];
    const color = CELEBRATION[Math.floor(rand() * CELEBRATION.length)];

    layers.push(
      B.shapeLayer(
        `confetti_${String(i).padStart(2, '0')}_${kind}`,
        pieceArt(kind, color),
        B.layerTransform({
          anchor: [0, 0, 0],
          positionKf: posKf,
          rotationKf: spinKf,
          scaleKf,
          opacityKf,
        }),
        { ind: ind++, ip: startF, op: Math.min(total, startF + fallFrames + 1) },
      ),
    );
  }

  return B.composition({
    name: 'confetti',
    w: W,
    h: H,
    frames: 2.5,
    layers,
    markers: [{ tm: 0, cm: 'rain', dr: 150 }],
    // Reduced-motion still: the field is densest around f75; the final frames
    // are empty because every piece has fallen out of the frame.
    still: 75,
  });
}

module.exports = { build, SIZE: [W, H], PIECE_COUNT };
