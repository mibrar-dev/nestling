'use strict';
/**
 * coin_burst.js — shortlist #4.
 *
 * "8 coins burst outward on arcs with rotation + fade, 4 small sparkles in
 * lilac/leaf." 1.0 s / 60 f.
 *
 * Art source: `app/assets/illustrations/coin.svg` — gold `#F4B400` disc, a
 * lighter `#FFF6D8` inner ring, an `#1E1B3A` keyline, a white specular, and the
 * leaf `#1F9D63` emboss. At burst size the emboss's vein detail is sub-pixel,
 * so the coin is reduced to: gold disc → light inner ring → ink keyline →
 * leaf leaf-shape (no veins) → specular. Five shapes, still unmistakably the
 * same coin.
 *
 * The motion is **ballistic, not tweened per-coin**: each coin is integrated on
 * its own parabola with gravity, and the whole trajectory is baked to
 * keyframes. That is what makes the burst read as "coins thrown" rather than
 * "eight shapes fading outward", and it costs nothing at runtime because
 * Lottie evaluates keyframes, not physics.
 *
 * Timeline (60 fps):
 *   f0–4    all coins at the centre, scale 0 (a beat, so the burst has an origin)
 *   f3–40   coins travel their arcs, spinning
 *   f24–48  coins scale down and fade (they "leave", they don't stop dead)
 *   f8–34   4 sparkles pop at staggered points along the burst
 */

const B = require('../lib/bodymovin');
const { C, F, rng, round } = require('../lib/brand');

const SIZE = 260;
const MID = SIZE / 2;
// The origin is nudged up from the geometric centre of the frame. A coin burst
// spends most of its life *falling*, so the perceived mass of the animation
// sits below the launch point; launching dead-centre makes the whole burst
// read as sitting too high. 22 px of offset puts the mid-burst mass on the
// frame's centre line.
const ORIGIN_Y = MID - 22;

/**
 * One coin, in local space: origin at the coin's centre, r = 15.
 *
 * Paint order: **index 0 is on top** (verified against lottie-web with a
 * two-square probe — the first item in `shapes` ends up last in DOM order and
 * therefore in front). So: specular, leaf, light ring, keyline, gold disc.
 *
 * Proportions come from `coin.svg` (r 84, inner ring r 72, keyline 6, leaf
 * spanning ~34 units, specular 24×12) scaled to r 15.
 *
 * The critical ratio is **leaf-to-disc**. In the source the leaf is about 40 %
 * of the disc diameter and sits off-centre toward the lower right. Oversize it
 * — the obvious mistake when hand-authoring — and the coin reads as a green
 * blob with a gold rim rather than a gold coin with a leaf on it, and the whole
 * burst loses its "money" read, which is the entire point of the asset.
 */
function coinArt() {
  const R = 15;
  return [
    // Specular — the white blob from coin.svg, upper-left.
    B.group([B.ellipse([8.6, 4.3], [-4, -5.4]), B.fill('#FFFFFF', 60)], B.tr({})),
    // Leaf emboss, simplified from coin.svg's `q`-curve leaf: one lens shape
    // with the veins dropped (invisible below ~40 px), offset to the right of
    // centre as in the source.
    B.group(
      [
        B.path(
          [
            ['M', 4, -5.5],
            ['Q', 6, -1, 3, 3.6],
            ['Q', -0.6, 6, -4, 4.4],
            ['Q', -5.6, 0.6, 4, -5.5],
          ],
          true,
        ),
        B.stroke(C.ink, 1.5, { cap: 2, join: 2 }),
        B.fill(C.leafBright),
      ],
      B.tr({ position: [2.4, 1.6, 0] }),
    ),
    // Inner light ring (#FFF6D8 at 85 %) — the `r 72` circle in coin.svg.
    B.group(
      [B.ellipse([R * 1.714, R * 1.714], [0, 0]), B.stroke(C.coinRim, 1.9, { opacity: B.val(85) })],
      B.tr({}),
    ),
    // Ink keyline.
    B.group([B.ellipse([R * 2, R * 2], [0, 0]), B.stroke(C.ink, 2.6)], B.tr({})),
    // Gold disc.
    B.group([B.ellipse([R * 2, R * 2], [0, 0]), B.fill(C.coin)], B.tr({})),
  ];
}

/** A four-point sparkle (the shape used across `sparkles.svg` / `coins_burst.svg`). */
function sparkleArt(color, size) {
  return [
    B.group(
      [B.sparklePath(size), B.stroke(C.ink, 2, { cap: 2, join: 2 }), B.fill(color)],
      B.tr({}),
    ),
  ];
}

function build() {
  const end = F(1.0); // 60
  const rand = rng(0x5eed);
  const layers = [];
  let ind = 1;

  /* ------------------------------------------------------------ 8 coins --- */
  // Hand-tuned fan, not random — and **balanced about the vertical axis**.
  // Angles are measured from straight up (−90) and paired at ±: 8 coins as
  // 4 mirror pairs. An unbalanced fan reads as a diagonal wipe and pushes the
  // composition's optical centre off to one side, which is the single most
  // common way a generated burst looks "cheap". The pairs are deliberately not
  // the same distance (inner/outer alternate) so it still looks thrown.
  const spread = [
    { angle: -90 - 58, dist: 84, delay: 0, spin: -320, depth: 0.74 },
    { angle: -90 + 58, dist: 86, delay: 1, spin: 290, depth: 0.8 },
    { angle: -90 - 32, dist: 62, delay: 2, spin: 240, depth: 0.92 },
    { angle: -90 + 32, dist: 66, delay: 0, spin: -250, depth: 0.9 },
    { angle: -90 - 10, dist: 92, delay: 4, spin: -400, depth: 0.62 },
    { angle: -90 + 10, dist: 88, delay: 3, spin: 420, depth: 0.66 },
    { angle: -90 - 84, dist: 76, delay: 1, spin: 300, depth: 0.76 },
    { angle: -90 + 84, dist: 80, delay: 2, spin: -300, depth: 0.72 },
  ];

  spread.forEach((cfg, i) => {
    const rad = (cfg.angle * Math.PI) / 180;
    const frames = [];
    // Ballistic sample: 7 keyframes per coin is plenty at 60 fps once the
    // renderer interpolates, and keeps the file small.
    const steps = 7;
    const t0 = 3 + cfg.delay;
    for (let s = 0; s <= steps; s += 1) {
      const t = s / steps;
      const f = t0 + t * 34;
      if (f > 58) break;
      // Ease-out travel distance so coins leave fast and coast.
      const travel = 1 - Math.pow(1 - t, 2.1);
      // Gravity: parabolic drop, proportional to how much they've travelled.
      const drop = t * t * 30;
      const x = Math.cos(rad) * cfg.dist * travel;
      const y = Math.sin(rad) * cfg.dist * travel + drop;
      frames.push({
        t: round(f, 1),
        v: [round(MID + x, 1), round(ORIGIN_Y + y, 1), 0],
        ease: B.EASE.linear,
      });
    }
    // Settle the coin off-frame rather than leaving it parked mid-air.
    frames.push({ t: 58, v: [MID, SIZE + 60, 0] });

    const scaleKf = [
      { t: 2 + cfg.delay, v: [0, 0, 100], ease: B.EASE.out },
      { t: 8 + cfg.delay, v: [cfg.depth * 100, cfg.depth * 100, 100], ease: B.EASE.linear },
      { t: 30 + cfg.delay, v: [cfg.depth * 100, cfg.depth * 100, 100], ease: B.EASE.in },
      { t: 47 + cfg.delay, v: [cfg.depth * 62, cfg.depth * 62, 100] },
    ];

    layers.push(
      B.shapeLayer(
        `coin_${i}`,
        coinArt(),
        B.layerTransform({
          anchor: [0, 0, 0],
          positionKf: frames,
          rotationKf: [
            { t: 3 + cfg.delay, v: 0, ease: B.EASE.linear },
            { t: 42 + cfg.delay, v: cfg.spin },
          ],
          scaleKf,
          opacityKf: [
            { t: 3 + cfg.delay, v: 0 },
            { t: 8 + cfg.delay, v: 100, ease: B.EASE.linear },
            { t: 30 + cfg.delay, v: 100, ease: B.EASE.in },
            { t: 47 + cfg.delay, v: 0 },
          ],
        }),
        { ind: ind++, op: end },
      ),
    );
  });

  /* --------------------------------------------------------- 4 sparkles --- */
  // Mirrored about the centre for the same reason the coins are: an off-axis
  // sparkle is the most visible tell that a burst was placed by hand rather
  // than composed. Positions sit just outside the coin ring at the moment each
  // pair arrives, so the sparkle reads as the coin's own flash.
  const sparks = [
    { color: C.lilac, x: 62, y: ORIGIN_Y - 30, at: 13, size: 9.5, rot: -12 },
    { color: C.lilac, x: 198, y: ORIGIN_Y - 30, at: 13, size: 9.5, rot: 12 },
    { color: C.leafBright, x: 76, y: ORIGIN_Y + 58, at: 22, size: 8.5, rot: 10 },
    { color: C.leafBright, x: 184, y: ORIGIN_Y + 58, at: 22, size: 8.5, rot: -10 },
  ];

  sparks.forEach((s, i) => {
    layers.push(
      B.shapeLayer(
        `sparkle_${i}`,
        sparkleArt(s.color, s.size),
        B.layerTransform({
          anchor: [0, 0, 0],
          position: [s.x, s.y, 0],
          rotation: s.rot,
          // Pop with a ring, then drift outward a touch while fading.
          scaleKf: [
            { t: s.at, v: [0, 0, 100], ease: B.EASE.pop },
            { t: s.at + 7, v: [128, 128, 100], ease: B.EASE.in },
            { t: s.at + 15, v: [70, 70, 100] },
          ],
          opacityKf: [
            { t: s.at, v: 0 },
            { t: s.at + 3, v: 100, ease: B.EASE.linear },
            { t: s.at + 12, v: 100, ease: B.EASE.in },
            { t: s.at + 17, v: 0 },
          ],
        }),
        { ind: ind++, ip: s.at, op: Math.min(end, s.at + 18) },
      ),
    );
  });

  return B.composition({
    name: 'coin_burst',
    w: SIZE,
    h: SIZE,
    frames: 1.0,
    layers,
    markers: [{ tm: 0, cm: 'burst', dr: 60 }],
    // Reduced-motion still: the last frame is empty (every coin has left the
    // frame), so the still is mid-burst at f30, where the fan is at full spread.
    still: 30,
  });
}

module.exports = { build, SIZE };
