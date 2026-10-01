'use strict';
/**
 * check_tick.js — shortlist #5.
 *
 * "Circle fills leaf green, white tick draws on via trim path, tiny scale
 * bounce." 0.6 s / 36 f.
 *
 * This is the highest-frequency animation in the app: it fires once per quest
 * row on K03b/K05/K08/P08/P11/P13, at **24–56 px**. The design constraints
 * follow from that size range:
 *
 *   - No hairlines. The ink ring is 3.5/64 of the box (≈1.3 px at 24 px) and
 *     the tick is 6/64 (≈2.25 px). Anything thinner mushes into grey.
 *   - The tick is drawn in white directly on the leaf fill, so it survives
 *     greyscale and colour-blind viewing; it is never a tinted lighter green.
 *   - Nothing is smaller than the ring radius in perceived weight, so the mark
 *     still reads as a *check* rather than a dot at 24 px.
 *   - The bounce is 108% → 97% → 100%: about 1.5 px of travel at 56 px, which
 *     reads as "pop" rather than "wobble". Bigger overshoot looks broken when
 *     six rows tick in a staggered list.
 *
 * Timeline (60 fps):
 *   f0–2    empty (one frame of air so a list stagger doesn't read as a hitch)
 *   f2–16   circle pops in, overshooting to 108%
 *   f8–24   tick draws on, 0 → 100 % trim, overshoot then settle
 *   f16–30  scale settles 108 → 97 → 100
 *   f12–34  leaf-tint ripple ring expands behind and fades out
 */

const B = require('../lib/bodymovin');
const { C, F } = require('../lib/brand');

const SIZE = 64;
const R = 22; // circle radius — leaves a 10 px margin so the bounce (to 108 %)
// and the ripple ring (to 142 %) both stay inside the comp.
const MID = SIZE / 2;

/**
 * The tick, in **layer-local** coordinates — i.e. relative to the disc centre,
 * not to the comp's top-left corner.
 *
 * This matters: the layer's transform is `translate(MID, MID)`, so any path
 * authored in comp coordinates gets translated *again* and lands at
 * (50.5, 64.5) — one pixel outside a 64-unit comp, where the clip hides it.
 * The animation then looks like a plain green dot with the check missing, and
 * nothing in the DOM looks wrong. Local coords put the tick at ±13 around the
 * origin, which is where it belongs.
 */
const TICK = [
  ['M', -11.5, 0.5],
  ['L', -3.8, 8.2],
  ['L', 11, -8.6],
];

function build() {
  const end = F(0.6); // 36

  // --- ripple: sits behind the disc, expands once the disc has landed --------
  const ripple = B.shapeLayer(
    'ripple',
    [
      B.group(
        [
          B.ellipse([R * 2 + 8, R * 2 + 8], [0, 0]),
          B.fill(C.leafBright, B.anim(null, [
            { t: 11, v: 0 },
            { t: 13, v: 55, ease: B.EASE.out },
            { t: 32, v: 0 },
          ])),
        ],
        B.tr({}),
      ),
    ],
    B.layerTransform({
      anchor: [0, 0, 0],
      position: [MID, MID, 0],
      scaleKf: [
        { t: 11, v: [78, 78, 100], ease: B.EASE.out },
        { t: 33, v: [142, 142, 100] },
      ],
    }),
    { ind: 1, op: end },
  );

  // --- the mark: green disc + white tick, scaled as one unit ----------------
  // Paint order: **index 0 paints on top** (verified against lottie-web with a
  // two-square probe: the first item in `shapes` ends up last in DOM order and
  // therefore in front). So the tick goes first.
  const discAndTick = B.shapeLayer(
    'mark',
    [
      // Tick. Trim `simultaneously` (m:1) is correct here — a single open
      // path, so the two segments grow in series along the path length, which
      // is exactly the "drawing" read we want.
      B.group(
        [
          B.path(TICK, false),
          B.trim(
            B.val(0),
            B.anim(null, [
              { t: 8, v: 0 },
              { t: 20, v: 104, ease: B.EASE.out },
              { t: 24, v: 100 },
            ]),
            B.val(0),
            1,
          ),
          B.stroke(C.white, 5.4, { cap: 2, join: 2 }),
        ],
        B.tr({}),
      ),
      // Ink ring — the brand's outlined-illustration signature. 3/64 is ~1.1 px
      // at the 24 px minimum size, which is the floor: any thinner and the ring
      // greys out and the mark reads as a flat green dot.
      B.group([B.ellipse([R * 2, R * 2], [0, 0]), B.stroke(C.ink, 3)], B.tr({})),
      // Leaf fill.
      B.group([B.ellipse([R * 2, R * 2], [0, 0]), B.fill(C.leaf)], B.tr({})),
    ],
    B.layerTransform({
      anchor: [0, 0, 0],
      position: [MID, MID, 0],
      scaleKf: [
        { t: 2, v: [0, 0, 100] },
        { t: 16, v: [108, 108, 100], ease: B.EASE.spring },
        { t: 23, v: [97, 97, 100], ease: B.EASE.out },
        { t: 30, v: [100, 100, 100] },
      ],
    }),
    { ind: 2, op: end },
  );

  return B.composition({
    name: 'check_tick',
    w: SIZE,
    h: SIZE,
    frames: 0.6,
    layers: [ripple, discAndTick],
    markers: [{ tm: 0, cm: 'pop', dr: 36 }],
    // Reduced-motion still: frame 32 is the disc at rest with the tick fully
    // drawn and the ripple already faded — the mark a child needs to see.
    still: 32,
  });
}

module.exports = { build, SIZE };
