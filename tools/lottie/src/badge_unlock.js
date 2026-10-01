'use strict';
/**
 * badge_unlock.js — shortlist #10.
 *
 * "Medal (ribbon + disc, colour-neutral gold) swings in from the top on its
 * ribbon with damped pendulum, then a diagonal shine sweep and 3 sparkles."
 * 0.9 s / 54 f.
 *
 * Art source: `app/assets/illustrations/badge_*.svg` — ribbon `M22 5h20l-5 21H27Z`
 * and a disc at cy 39 r 20, so the ribbon is 50 % of the disc's diameter. The
 * brief asks for **colour-neutral gold**, so the disc is the earned gold
 * (`#F4B400` fill, `#FFF4D1` inner ring, ink keyline) while the ribbon is
 * desaturated — the medal reads as a *placeholder* that any of the nine badges
 * can be swapped into, which is the "one JSON with a colour swap beats nine
 * files" note in the shortlist.
 *
 * ## One layer, one pivot
 *
 * The ribbon and the disc are **shape groups inside a single shape layer**,
 * not two layers. They must move as one rigid body: a medal on a ribbon is one
 * object rotating about the ribbon's top edge, and any per-part rotation
 * difference is exactly what separates them. Two layers with two rotation
 * channels cannot express that — at 18° the disc and ribbon travel different
 * arcs and visibly detach.
 *
 * Within the layer, the disc and shine are offset to `DISC_DROP` below the
 * origin and the ribbon is authored at the origin, so both share one rotation
 * centre: the layer's own origin, which `position` parks at the ribbon top.
 *
 * ## Geometry
 *
 * The medal spans y 0 → 158 in a 260-unit frame, i.e. **61 % of the frame**,
 * with the disc at Ø124 (48 % of the width) and the ribbon 68 wide — the
 * 55 : 124 ratio the source badge uses. The ribbon's bottom edge sits 4 px
 * *past* the disc's top edge, so it tucks behind the disc rather than stopping
 * short of it. Paint order puts the ribbon last (= behind), which is what
 * makes that overlap read as "attached" instead of "pasted on".
 *
 * ## Pendulum
 *
 * `θ(t) = θ₀ · e^(−ζωt) · cos(ω_d t)`, θ₀ = 18°, ζ = 0.16, ω = 9 rad/s, sampled
 * to keyframes — flutter's lottie has no expression engine. One channel, the
 * whole body.
 *
 * Timeline (60 fps):
 *   f0–14   drops in from above the frame
 *   f0–52   damped pendulum, ±18° → 0, about the ribbon top
 *   f18–50  diagonal shine sweep, carried in the disc's own gradient fill
 *   f30–48  3 sparkles pop, staggered
 */

const B = require('../lib/bodymovin');
const { C, F, round, pendulum } = require('../lib/brand');

const W = 260;
const H = 260;
const CX = W / 2; // 130

/* ------------------------------------------------------------- geometry --- */

// Sized so the medal occupies **60 % of the frame**, measured as the total
// height from the ribbon's top edge to the disc's bottom:
//
//   ribbon (52) + disc Ø (108) = 160   →   160 / 260 = 61.5 %
//
// The disc is Ø108 (41.5 % of the width) and the ribbon 62 wide, keeping the
// source badge's 55 : 108 ratio. An earlier pass used a Ø124 disc, which
// overflowed to 66 % and pushed the composition against the frame edges.
const RIB_H = 52; // ribbon: top edge → bottom edge
const DISC_R = 54; // Ø108
const DISC_DROP = RIB_H + DISC_R - 4; // 106 — see RIB_BOTTOM

// The ribbon's bottom edge sits 4 px *below* the disc's top edge, so the two
// overlap rather than meet. A ribbon that stops exactly at the disc reads as
// detached once the artwork scales down, because the ink keylines are 6–7 units
// wide and the visible gap between them grows as the render size drops.
const RIB_TOP = -10;
const RIB_BOTTOM = RIB_H; // 52
const DISC_TOP = DISC_DROP - DISC_R; // 52 == RIB_BOTTOM, by construction

// Total medal height, used to place the drop and to centre the composition.
const MEDAL_H = DISC_DROP + DISC_R; // 160

// The pivot sits just inside the top edge so the ribbon's top row of ink is
// never clipped. The medal is then *pushed down* so its 160-unit height is
// centred in the 260 frame: (260 − 160) / 2 = 50 of top margin, and ANCHOR_Y
// below supplies the rest.
const ANCHOR_Y = 18;
// Clears the frame: at t=0 the medal's bottom is at ANCHOR_Y + MEDAL_H + DROP_FROM < 0.
const DROP_FROM = -(MEDAL_H + ANCHOR_Y + 40);

/* -------------------------------------------------------------- the art --- */

/**
 * The 5-point star from `badge_first_quest.svg`.
 *
 * Generated from the 10 polar vertices rather than transcribed: the source
 * radii are visibly uneven and reading ten coordinates off a 64-unit viewBox by
 * hand is how you end up with a pentagon.
 */
function starPath(rOuter, rInner) {
  const pts = [];
  for (let i = 0; i < 10; i += 1) {
    const a = (-90 + i * 36) * (Math.PI / 180);
    const r = i % 2 === 0 ? rOuter : rInner;
    pts.push([round(Math.cos(a) * r, 2), round(Math.sin(a) * r, 2)]);
  }
  const cmds = [['M', pts[0][0], pts[0][1]]];
  for (let i = 1; i < pts.length; i += 1) cmds.push(['L', pts[i][0], pts[i][1]]);
  return B.path(cmds, true);
}

/**
 * Medal disc, authored around (0,0) — the disc's own centre.
 *
 * Paint order: **index 0 is on top** (verified against lottie-web with a
 * two-square probe). So: specular, star, light ring, keyline, gold fill.
 *
 * Stroke weights are scaled to DISC_R. At the previous Ø56 they were 2.4–3.4
 * for a 28-unit radius; ×2.21 keeps the same *relative* weight, which is what
 * keeps the outlined-illustration look at a 2.2× larger size.
 */
/**
 * The disc's gold fill, with the shine **in the gradient itself**.
 *
 * ## Why the gradient, not a band
 *
 * The shine has to be clipped to a circle, and Bodymovin offers no way to clip
 * a shape to a sibling shape without a matte (a whole extra layer for one
 * effect). A moving band therefore always overhangs somewhere: sized to stay
 * inside a Ø108 circle it is too short to read as a sweep, and sized to sweep
 * it washes over the ribbon and the background.
 *
 * Putting the shine *in the disc's own fill* solves it exactly: the gradient
 * line crosses the disc, so the highlight is bounded by the ellipse by
 * construction, at every frame, with no clipping and no extra layer.
 *
 * The stop pattern is a hard-edged white band — gold, gold, white, gold, gold —
 * with the two inner stops only 0.12 apart in gradient space. That narrowness
 * is what makes it read as a glint rather than a wash. Before the sweep starts
 * and after it ends the gradient is parked fully off the disc, so the disc is
 * flat `#F4B400` and the still frame is unaffected.
 */
function goldFill() {
  const R = DISC_R;
  // The gradient line is diagonal (top-left → bottom-right) so the band is
  // diagonal. `LEN` is its length and the band sits at its midpoint, so the
  // band is 0.12·LEN wide — 0.12 × 260 = 31 units, a clearly visible glint on
  // a Ø108 disc.
  const LEN = 260;
  const HALF = LEN / 2;
  // Five stops with explicit positions: two gold, white, two gold. Evenly
  // spaced stops would give a soft wash instead of a glint. Offsets are 0–1
  // fractions — see `bodymovin.flatStops` for why percentages fail silently.
  const stops = [
    { c: C.coin, at: 0 },
    { c: C.coin, at: 0.44 },
    { c: '#FFFFFF', at: 0.5 },
    { c: C.coin, at: 0.56 },
    { c: C.coin, at: 1 },
  ];
  // The band's midpoint runs from the disc's top-left corner to its
  // bottom-right: ±R in both axes, so it enters and exits exactly at the
  // silhouette edge with no time wasted off the disc.
  //
  // `s` and `e` are the line's two ends, LEN apart, translating together so the
  // direction stays fixed. They **must** be LEN apart — the same point for
  // both gives a zero-length line whose offsets all collapse, and the gradient
  // renders as flat gold with no shine on any frame.
  const start = [
    { t: 18, v: [-R - HALF, -R - HALF], ease: B.EASE.linear },
    { t: 50, v: [R - HALF, R - HALF] },
  ];
  const end = [
    { t: 18, v: [-R + HALF, -R + HALF] },
    { t: 50, v: [R + HALF, R + HALF] },
  ];
  return B.gradientFill(stops, 100, null, null, start, end);
}

function discArt() {
  return [
    // Specular arc — small, upper-left, as in the illustration family.
    B.group([B.ellipse([30, 13], [-15, -19]), B.fill('#FFFFFF', 42)], B.tr({})),
    // Star outline, centred on the disc. rOuter 25 / rInner 10.6 ≈ the 1 : 2.35
    // ratio of the source path.
    B.group([starPath(25, 10.6), B.stroke(C.ink, 4.8, { cap: 2, join: 2 })], B.tr({})),
    // Inner light ring, r 45 of 54 (0.84 r) as in the source badge.
    B.group(
      [B.ellipse([91, 91], [0, 0]), B.stroke(C.coinTint, 5.5, { opacity: B.val(85) })],
      B.tr({}),
    ),
    // Ink keyline.
    B.group([B.ellipse([DISC_R * 2, DISC_R * 2], [0, 0]), B.stroke(C.ink, 6)], B.tr({})),
    // Gold disc, with the shine in its gradient.
    B.group([B.ellipse([DISC_R * 2, DISC_R * 2], [0, 0]), goldFill()], B.tr({})),
  ];
}

/**
 * The ribbon, authored around the pivot (its own top edge at y ≈ 0).
 *
 * The V-notch is cut into the bottom of the tails so the disc behind shows
 * through it. Since the ribbon is painted *behind* the disc, the notch is
 * visible as a wedge of gold — the same read as `badge_first_quest.svg`, where
 * the disc sits on top of the ribbon's V.
 */
function ribbonArt() {
  const HW = 31; // half-width at the top
  const BW = 25; // half-width at the bottom (tapered, as in the source)
  const NOTCH = 17; // how far the V cuts up into the tails
  return [
    // Tails.
    B.group(
      [
        B.path(
          [
            ['M', -HW, RIB_TOP],
            ['L', HW, RIB_TOP],
            ['L', BW, RIB_BOTTOM],
            ['L', -BW, RIB_BOTTOM],
          ],
          true,
        ),
        B.stroke(C.ink, 6, { join: 2 }),
        B.fill(C.ink2, 62),
      ],
      B.tr({}),
    ),
    // The V-notch, cut up into the bottom edge so the disc behind shows through.
    //
    // This is drawn in the ribbon's own grey, *not* as a hole, and that is
    // deliberate: cutting a real hole needs a boolean path operation, and a
    // grey wedge reads identically at render sizes where a 1 px seam between
    // two grey shapes would not. The wedge is the same fill and the same 62 %
    // opacity as the tails, so the two are visually one shape.
    B.group(
      [
        B.path(
          [
            ['M', -BW - 1, RIB_BOTTOM + 1],
            ['L', 0, RIB_BOTTOM - NOTCH],
            ['L', BW + 1, RIB_BOTTOM + 1],
          ],
          true,
        ),
        B.fill(C.ink2, 62),
      ],
      B.tr({}),
    ),
  ];
}

/* ---------------------------------------------------------------- build --- */

function build() {
  const end = F(0.9); // 54
  const layers = [];

  /* ------------------------------------------------- medal: one rigid body --- */
  // θ₀ = 18° as briefed, sampled every 2 frames. By f52 the envelope is under
  // 1° of rest, so the badge has visibly settled without snapping to zero.
  const swingKf = (() => {
    const kf = [];
    for (let f = 0; f <= 52; f += 2) {
      kf.push({ t: f, v: round(pendulum(18, f / 60), 2), ease: B.EASE.linear });
    }
    kf.push({ t: 52, v: 0 });
    return kf;
  })();

  const medal = B.shapeLayer(
    'medal',
    [
      // Disc first (its own fill carries the shine), ribbon last so it passes
      // behind — which is what makes the 4 px overlap read as attached.
      B.group(discArt(), B.tr({ position: [0, DISC_DROP, 0] })),
      B.group(ribbonArt(), B.tr({})),
    ],
    B.layerTransform({
      // Anchor at the layer origin; `position` parks that origin on the ribbon's
      // top edge. Lottie composes `translate(position) · rotate(anchor)`, so a
      // zero anchor puts the rotation centre exactly where the ribbon starts.
      anchor: [0, 0],
      positionKf: [
        { t: 0, v: [CX, ANCHOR_Y + DROP_FROM, 0], ease: B.EASE.in },
        { t: 14, v: [CX, ANCHOR_Y + 7, 0], ease: B.EASE.spring },
        { t: 22, v: [CX, ANCHOR_Y, 0], ease: B.EASE.out },
        { t: 28, v: [CX, ANCHOR_Y, 0] },
      ],
      rotationKf: swingKf,
      scaleKf: [
        { t: 0, v: [86, 86, 100], ease: B.EASE.out },
        { t: 11, v: [103, 103, 100], ease: B.EASE.spring },
        { t: 19, v: [100, 100, 100] },
      ],
      opacityKf: [
        { t: 0, v: 0 },
        { t: 4, v: 100 },
      ],
    }),
    { ind: 1, op: end },
  );

  /* ------------------------------------------------------------ sparkles --- */
  // Around the medal's rest centre, since the swing has settled by the time
  // they fire. Placed outside the disc radius (54) so they read as sparks
  // flying off the medal rather than marks printed on it.
  const MX = CX;
  const MY = ANCHOR_Y + DISC_DROP;
  const sparkDefs = [
    { color: C.coin, x: MX - 78, y: MY - 44, at: 30, size: 15, rot: -14 },
    { color: C.lilac, x: MX + 80, y: MY - 30, at: 34, size: 13, rot: 12 },
    { color: C.leafBright, x: MX - 4, y: MY + 78, at: 38, size: 14, rot: 4 },
  ];

  sparkDefs.forEach((s, i) => {
    layers.push(
      B.shapeLayer(
        `sparkle_${i}`,
        [
          B.group(
            [B.sparklePath(s.size), B.stroke(C.ink, 3.4, { cap: 2, join: 2 }), B.fill(s.color)],
            B.tr({}),
          ),
        ],
        B.layerTransform({
          anchor: [0, 0],
          position: [s.x, s.y, 0],
          rotation: s.rot,
          scaleKf: [
            { t: s.at, v: [0, 0, 100], ease: B.EASE.pop },
            { t: s.at + 6, v: [125, 125, 100], ease: B.EASE.in },
            { t: s.at + 14, v: [66, 66, 100] },
          ],
          opacityKf: [
            { t: s.at, v: 0 },
            { t: s.at + 3, v: 100, ease: B.EASE.linear },
            { t: s.at + 11, v: 100, ease: B.EASE.in },
            { t: s.at + 16, v: 0 },
          ],
        }),
        { ind: i + 2, ip: s.at, op: Math.min(end, s.at + 17) },
      ),
    );
  });

  return B.composition({
    name: 'badge_unlock',
    w: W,
    h: H,
    frames: 0.9,
    layers: [medal, ...layers],
    markers: [{ tm: 0, cm: 'unlock', dr: 54 }],
    // Reduced-motion still: the medal at rest, swing settled, shine finished.
    still: 50,
  });
}

module.exports = { build, SIZE: [W, H] };
