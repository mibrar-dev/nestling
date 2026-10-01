# LOTTIE.md — Nestling's Lottie one-shots

> Generated, not hand-edited. The source of truth is `tools/lottie/`; the JSON
> in `app/assets/animations/lottie/` is a build output. **Never hand-edit a
> `.json` in that directory** — run `node tools/lottie/build.js` instead.
>
> Runtime: `lottie ^3.6.1` (already in `app/pubspec.yaml`). Companion:
> `docs/animation/RIVE_GUIDE.md` §A/§B, which decided *what* gets built and
> *which engine*. This document covers the Lottie half.

---

## 1. The set

Four fire-and-forget one-shots, shortlist entries #5, #4, #7 and #10 from
`RIVE_GUIDE.md` §B. Everything stateful (Pip, the coin jar) is Rive and lives
in `app/assets/animations/rive/` — see `RIVE_GUIDE.md`.

| File | Size | Comp | Duration | Frames | Loop | Screens |
| --- | --- | --- | --- | --- | --- | --- |
| `check_tick.json` | 3.1 KB | 64 × 64 | 0.60 s | 36 | one-shot | K03b, K05, K08, P08, P11, P13 |
| `coin_burst.json` | 35.9 KB | 260 × 260 | 1.00 s | 60 | one-shot | K05, P11, P12, K03b |
| `confetti.json` | 38.9 KB | 390 × 844 | 2.50 s | 150 | one-shot | K07, P13, K05 |
| `badge_unlock.json` | 9.9 KB | 260 × 260 | 0.90 s | 54 | one-shot | K11, K05 |
| **total** | **87.8 KB** | | | | | |

All four are Bodymovin **5.7.4**, **60 fps**, transparent, vector-only.

### 1.1 What each one is

**`check_tick`** — shortlist #5. A leaf-green `#17804F` disc with a 3-unit ink
keyline, a white tick that draws on via a trim path, an 108 % → 97 % → 100 %
scale bounce, and a leaf-tint ripple that expands behind and fades. This is the
**highest-frequency animation in the app** — it fires once per quest row — so
it is authored for the 24–56 px range it is actually painted at:

- no hairlines: the ink ring is 3/64 of the box (≈1.1 px at 24 px) and the tick
  5.4/64 (≈2.0 px). Anything thinner greys out into mush.
- the tick is **white**, never a lighter green, so it survives greyscale and
  colour-blind viewing.
- the bounce travels ≈1.5 px at 56 px. A larger overshoot looks broken when six
  rows tick in a staggered list.

**`coin_burst`** — shortlist #4. 8 coins on ballistic arcs with rotation and
fade, plus 4 sparkles in lilac/leaf. The coin is `illustrations/coin.svg`
reduced to its five load-bearing shapes: gold disc, `#FFF6D8` inner ring at
r = 0.857 r, ink keyline, leaf emboss, specular. **The leaf-to-disc ratio is
the thing to preserve** — at ~40 % of the disc diameter the coin reads as gold
with a leaf on it; oversize the leaf and it reads as a green blob and the
burst loses its "money" meaning entirely.

The 8 coins are laid out as **4 mirror pairs about the vertical axis**, not a
random fan. An unbalanced fan reads as a diagonal wipe and drags the
composition's optical centre off to one side.

**`confetti`** — shortlist #7. 30 pieces — rounded rects, circles, squiggles
and 4-point sparkles in coin / leaf / lilac / peach / sky — falling across the
full 390 × 844 device frame from `tokens.css` (`--w: 390`, `--h: 844`).

Piece sizes are **absolute per silhouette**, not derived from one `size` knob,
because the four are not the same measure: rects 8 × 14 with a 3 px corner
radius, circles Ø10, squiggles 18 long × 3 thick, sparkles r 8. Every piece
carries a 3-unit ink keyline. Driving all four off one `size` made every piece
land at roughly the same apparent *area*, and the field read as specks — the
field was geometrically correct and visually wrong.

Distribution is **strided, not random**: the x positions are stepped evenly
across 0 → 390 and jittered within each slot, and the sine phases are offset by
the piece index. Purely random placement leaves visible vertical gaps and makes
bands of pieces move in lockstep.

Each piece has its own fall time (0.62–1.0 of the timeline), start time, spin
rate and direction, a **scaleX tumble through zero** so pieces read as paper
seen edge-on, and a horizontal sine for flutter. The x-sway is folded into the
*same* four position keyframes as the y-fall rather than being a separate
channel — a keyframe is a keyframe either way — and 4 samples suffice because
the sway period is deliberately long (0.9–1.7 s), so a piece completes roughly
one oscillation over its fall and each sample is a real extremum or midpoint.

**`badge_unlock`** — shortlist #10. A gold medal on a desaturated ribbon swings
in from the top of the frame with a **damped pendulum**, then a diagonal shine
sweeps across the disc and 3 sparkles pop. The disc is deliberately
colour-neutral gold so one file serves all nine badges (the shortlist's "one
JSON with a colour swap beats nine files").

The ribbon and disc are **shape groups inside one layer**, not two layers. A
medal on a ribbon is a single rigid body rotating about the ribbon's top edge,
and two layers with two rotation channels travel different arcs — at 18° the
pair visibly detaches. The ribbon's bottom edge sits 4 px *past* the disc's top
edge and the ribbon is painted behind, so the overlap reads as attached rather
than pasted on. The medal fills 61 % of the frame (ribbon 52 + disc Ø108 = 160
of 260).

The shine is a **moving gradient in the disc's own fill** (`gf`), not a shape
over the top. Bodymovin cannot clip a shape to a sibling circle without a matte,
and flutter lottie's `Layer` has no matte field at all, so a travelling band
always overhangs somewhere — sized to sweep, it washes over the ribbon and the
background. A gradient that crosses the disc is bounded by the ellipse by
construction, at every frame, with no extra layer.

The pendulum is `θ(t) = θ₀ · e^(−ζωt) · cos(ω_d t)` with θ₀ = 18°, ζ = 0.16,
ω = 9 rad/s, sampled to keyframes — **not** an expression, because Flutter's
lottie runtime has no expression engine.

---

## 2. Flutter usage

### 2.1 The widget

`assets/animations/lottie/` is already declared in `app/pubspec.yaml`. No
change needed.

```dart
import 'package:lottie/lottie.dart';

// Fire-and-forget one-shot. `repeat` defaults to true, so it is written
// explicitly here: the failure mode of getting it wrong — a one-shot looping
// forever on a quest row — is very visible.
Lottie.asset(
  'assets/animations/lottie/check_tick.json',
  package: 'nestling',
  animate: true,
  repeat: false,
  width: 32,
  height: 32,
  fit: BoxFit.contain,
  onLoaded: (composition) => debugPrint('check_tick ${composition.duration}'),
);
```

Notes on the real signatures in `lottie ^3.6.1` (`lib/src/lottie.dart`):

- `onLoaded` is `void Function(LottieComposition)` — **one** argument, not two.
- `animate` and `repeat` are `bool?` and both **default to `true`**. For a
  one-shot, pass both explicitly.
- There is **no `frame:` parameter**. To hold a specific frame, drive an
  `AnimationController` and set `animate: false` (§3).

`Lottie.asset` is the correct entry point for all four: they are bundled with
the app, need no network, and are small enough to decode lazily.

### 2.2 Precache

Decode the three small ones at startup so the very first quest row does not
hitch on a JSON parse.

```dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

// In main(), after WidgetsFlutterBinding.ensureInitialized():
Future<void> precacheAnimations() async {
  for (final asset in const [
    'assets/animations/lottie/check_tick.json', // fires per quest row
    'assets/animations/lottie/coin_burst.json',
    'assets/animations/lottie/badge_unlock.json',
  ]) {
    await AssetLottie(asset, package: 'nestling', bundle: rootBundle).load();
  }
}
```

`AssetLottie(...).load()` is the API for this, and it populates
`sharedLottieCache` (exposed as `Lottie.cache`) — so every later
`Lottie.asset` of the same path is a cache hit rather than a re-parse.

`confetti` is deliberately **not** in that list: it is the largest file and the
least latency-sensitive, since it always plays after a tap. Precache it on first
use instead:

```dart
// K7 / P13, once per session, well before the tap that needs it.
Lottie.cache.putIfAbsent('confetti', () async {
  return AssetLottie(
    'assets/animations/lottie/confetti.json',
    package: 'nestling',
  ).load();
});
```

### 2.3 Per-asset notes

| Asset | Render size | Notes |
| --- | --- | --- |
| `check_tick` | 24–56 px | Sized to the row's icon slot. Do not scale below 24 px — see §1.1. |
| `coin_burst` | 160–260 px | Place behind the reward copy on K05; the burst is centred in a 260-unit box. |
| `confetti` | full-bleed | `Positioned.fill` + `fit: BoxFit.cover`. The comp *is* 390 × 844, so at any other aspect ratio the pieces will be letterboxed — that is intended. |
| `badge_unlock` | 120–200 px | The ribbon enters from above the comp, so do not clip the top of the box. |

---

## 3. Reduced motion — the rule

**When `MediaQuery.disableAnimationsOf(context)` is true, do not play the
animation. Show the asset's `still` frame instead.**

`disableAnimationsOf` is the flag the OS sets from
*iOS Settings → Accessibility → Motion → Reduce Motion* and
*Android Settings → Accessibility → Remove animations*. It is **false by
default**, so this costs the default user nothing.

Worth knowing: `MediaQueryData` also exposes `accessibleNavigation`, which is
*Settings → Accessibility → Display & Text Size → Larger Text* on iOS. It is
**not** a reduced-motion signal — it should drive text scaling, not animation.
Do not conflate the two.

```dart
import 'package:flutter/animation.dart';
import 'package:lottie/lottie.dart';

/// Renders a one-shot, or its still frame when the user has asked for
/// reduced motion.
///
/// There is no `Lottie.asset(frame:)` in `lottie ^3.6.1`. The supported way to
/// park on a frame is an `AnimationController` seeded to that value plus
/// `animate: false`, which renders it and never starts a ticker.
class CelebrationOneShot extends StatelessWidget {
  const CelebrationOneShot({
    required this.asset,
    this.width = 200,
    super.key,
  });

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _StillFrame(asset: asset, width: width);
    }
    return Lottie.asset(
      asset,
      package: 'nestling',
      animate: true,
      repeat: false,
      width: width,
      fit: BoxFit.contain,
    );
  }
}

class _StillFrame extends StatefulWidget {
  const _StillFrame({required this.asset, required this.width});

  final String asset;
  final double width;

  @override
  State<_StillFrame> createState() => _StillFrameState();
}

class _StillFrameState extends State<_StillFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      widget.asset,
      package: 'nestling',
      controller: _c,
      animate: false, // render the controller's value and stop there
      width: widget.width,
      fit: BoxFit.contain,
      onLoaded: (composition) {
        if (_c.value == 0) {
          _c.value = stillFrameOf(composition);
        }
      },
    );
  }
}
```

### 3.1 Reading the still frame from the file

Prefer reading the `still` marker over hard-coding numbers, so the fallback
frame travels with the asset:

```dart
/// The frame the generator marks as the reduced-motion still, or the last
/// frame if the marker is missing.
double stillFrameOf(LottieComposition composition) {
  for (final marker in composition.markers) {
    if (marker.matchesName('still')) return marker.startFrame;
  }
  return composition.endFrame - 1;
}
```

`LottieComposition.markers` is a `List<Marker>`; `Marker` has a plain `double
startFrame` plus `matchesName(String)` (case-insensitive). The generator writes
`{ "cm": "still", "tm": <frame>, "dr": 0 }`, which parses to
`matchesName('still') == true` and `startFrame == <frame>`.

If you would rather not pay a `LottieComposition` lookup on the critical path,
the literals are in §3.2 and are asserted by `tools/lottie/build.js`.

### 3.2 The still frames

These are written into each file as a `still` marker by the generator, so they
are declared **next to the animation**, not in a widget:

| Asset | Still frame | What the user sees |
| --- | --- | --- |
| `check_tick` | 32 | Green disc, ink ring, tick fully drawn, ripple gone. |
| `coin_burst` | 30 | The fan at full spread with the 4 sparkles lit. |
| `confetti` | 75 | The field at its densest. |
| `badge_unlock` | 50 | Medal at rest, swing settled, shine finished. |

**The still frame is not always the last frame.** `coin_burst` and `confetti`
*end* empty, because every coin and every confetti piece has left the frame by
then — seeking to `endFrame` would show the user nothing at all.

`tools/lottie/build.js` **fails the build** if a `still` marker is missing, out
of range, or lands on a frame where zero layers actually draw. That is not
theoretical — it is the check that exists because a still frame rendering
nothing fails silently in the app, showing an empty box where the celebration
should be. The frames themselves are visible in
`design/animations/LOTTIE_PREVIEW.png` (the `still · reduced motion` column).

Read the marker at runtime rather than hard-coding these numbers:

```dart
double stillFrameFor(String asset) => switch (asset) {
  'assets/animations/lottie/check_tick.json' => 32,
  'assets/animations/lottie/coin_burst.json' => 30,
  'assets/animations/lottie/confetti.json' => 75,
  'assets/animations/lottie/badge_unlock.json' => 50,
  _ => 0,
};
```

### 3.3 What reduced motion does *not* change

Reduced motion is about **vestibular triggers** — large-area movement, motion
that persists, motion the user did not ask for. It does not mean "remove all
feedback":

- `check_tick` still appears. It is a 0.6 s, 32 px, stationary-state change with
  no translation — suppressing it would remove the *only* signal that a quest
  was completed. The still frame is the correct reduced-motion rendering.
- `badge_unlock` still appears. Same reasoning: it is the payoff for an action
  the child just took.
- `confetti` full-screen falling **is** suppressed. It is 2.5 s of continuous
  movement across the whole viewport — the textbook case.

So: reduce to a still frame everywhere, and that still frame is the complete
feedback. No screen needs a second, non-Lottie reduced-motion path.

---

## 4. Rebuilding and verifying

```sh
cd tools/lottie && npm install    # once — lottie-web + puppeteer-core
node tools/lottie/build.js        # generate the JSON
node tools/lottie/preview.js      # render frames + contact sheet
```

`build.js` **fails the build** on: no expressions, embedded assets, `fr ≠ 60`, a
duration that disagrees with `lib/brand.js`, a file over 40 KB, or a `still`
marker that is missing / out of range / on a frame where nothing draws. Those
are the five ways this asset set has actually gone wrong.

### 4.1 Previews

- `design/animations/previews/<name>_f{0,25,50,75,100}.png`
- `design/animations/previews/<name>_still.png`
- `design/animations/LOTTIE_PREVIEW.png` — all four, all stops, plus the still
  column, on a checkerboard so a transparent animation cannot be mistaken for a
  white one.

`preview.js` renders with **real Chrome** via `puppeteer-core` (no bundled
Chromium download) and treats a frame with no rendered nodes, or a swallowed
renderer error, as a **failure** — it exits non-zero. That matters: lottie-web
catches exceptions inside `renderFrame` and re-emits them as an `error` event
with an empty `nativeError`, so a broken file looks identical to a working one
unless you check.

### 4.2 The 40 KB budget, and what it cost

`confetti.json` is the only file anywhere near the limit, and it only fits
because of two measured decisions:

- **Piece mix weighted by JSON cost, not uniform.** A sparkle costs ~830 bytes,
  a squiggle ~630, a rect ~545, a circle ~520 — the 8-vertex sparkle path and
  the squiggle's two cubic segments dominate. A uniform 4-way mix spends the
  budget on the two most expensive shapes. The mix is 4 rects / 3 circles /
  2 squiggles / 2 sparkles.
- **Four position keyframes per piece**, not six. The flutter period is long
  enough (0.9–1.7 s) that each sample is a real extremum or midpoint, so a
  finer sample rate buys nothing.

Five "obvious" optimisations were tried, measured, and **rejected** because each
one either made the file *larger* or broke it:

| Attempt | Result |
| --- | --- |
| Omit `i`/`o` bezier handles on linear keyframes | Saves ~21 KB… and **breaks lottie-web**, which dereferences `keyData.o.x` unguarded. Flutter tolerates it; the preview renderer does not. |
| Strip all-zero `i`/`o` tangents from `sh` paths in the minifier | Saves ~2.2 KB… and **renders nothing**. Both `i` and `o` are load-bearing even when every handle is the identity. |
| 4-vertex sparkle (waist moved into bezier handles) | **Larger.** A non-zero tangent pair costs more than four zero-tangent vertices. Vertices are the cheap unit; tangents are the expensive one. |
| Drop the `gr` wrapper per piece, items flat on the layer | Saves ~6 KB… and **renders nothing** (§5). |
| Solve the squiggle as a gradient fill | Fewer path bytes, but a `gf` costs a keyframed colour property per stop and came out *larger* than the two-cubic path. |

The general lesson, and the reason `lib/bodymovin.js` exists: in Bodymovin the
cheap wins are the ones that look like *deleting* something, and most of the
deletable things turn out to be load-bearing. The wins that actually work change
the content — fewer, simpler pieces.

---

## 5. Format constraints (all verified against the shipped runtime)

Content types used, and the complete set `lottie ^3.6.1` can parse:

```
gr  st  gs  fl  gf  tr  sh  el  rc  tm  sr  mm  rp  rd
```

| Constraint | Why |
| --- | --- |
| **No expressions** | Flutter's lottie has no expression engine. Everything is baked to keyframes — including the pendulum and the ballistic arcs. |
| **No embedded images** | Pure vector shapes only. `assets: []` in all four. |
| **No mattes** | `tt`/`tp` are not in flutter lottie's `Layer` at all, so anything relying on clipping to a sibling is Rive-only. This is why the badge's shine is a gradient rather than a masked band. |
| **Every keyframe except the last carries `i`/`o`** | lottie-web's `KeyframedProperty.getValue` calls `BezierFactory.getBezierEasing(keyData.o.x, …)` with no guard. A handle-less keyframe throws inside `renderFrame`'s `try`, and the layer renders as nothing. Flutter tolerates it; the preview renderer does not. |
| **A `gr` always contains a `tr`**, and never one in the items list | A group with no transform — or a shape placed flat on the layer — emits a degenerate `M0 0` path and renders nothing. A `B.tr(...)` passed *inside* the items array instead of as the transform argument leaves a `ty`-less object in `it` that stops the whole layer building. `bodymovin.group()` throws on the latter. |
| **Geometry precedes styles in `it`** | A `fl`/`st`/`gf` only paints shapes declared *after* it. `[fill, rect, tr]` draws nothing; `[rect, fill, tr]` draws. `group()` sorts items into this order rather than trusting call sites. |
| **Every layer has a unique `ind`** | lottie-web indexes its element array by it, so a missing value leaves a hole and *every* layer fails with `prepareFrame is not a function` — a total blank file from a one-field mistake. `build.js` asserts this. |
| **Shape art is authored in layer-local coordinates** | The layer transform already applies `translate(position)`. Art authored in comp coordinates gets translated twice and lands outside the clip — which is how `check_tick`'s tick spent an afternoon as an invisible check on a plain green dot. |
| **Gradient stops are `[offset, r, g, b]` × p**, offsets as 0–1 | The first value is the *position*, not an alpha. Writing RGBA shifts every channel by one (gold-and-white comes out magenta); writing percentages makes lottie-web emit `stop@4400%`, every stop clamps, and the gradient flattens to one colour. Both render without an error. `bodymovin.flatStops` owns this. |
| **A gradient's `s` and `e` must be distinct** | The same point for both is a zero-length line, which collapses all offsets and renders as flat fill. |

---

## 6. Layout

```
tools/lottie/
  lib/bodymovin.js     Bodymovin writer: shapes, keyframes, easings, groups.
                       Enforces the §5 ordering rules rather than documenting them.
  lib/brand.js         Colours from tokens.css, durations, seeded PRNG, pendulum maths.
  src/check_tick.js    ─┐
  src/coin_burst.js     │ one file per animation, each self-documenting
  src/confetti.js       │ with the art source and the timing decisions
  src/badge_unlock.js  ─┘
  build.js             Writes the JSON and enforces the invariants. Prints the size table.
  preview.js           Headless Chrome frame capture + contact sheet. Non-zero exit on failure.
app/assets/animations/lottie/*.json   Build output — do not hand-edit.
design/animations/previews/*.png      Per-frame stills.
design/animations/LOTTIE_PREVIEW.png  Contact sheet.
```

Confetti is **seeded** (`mulberry32` in `lib/brand.js`) so regenerating produces
byte-identical output. Unseeded randomness would reshuffle every field on every
build and make preview diffs useless.
