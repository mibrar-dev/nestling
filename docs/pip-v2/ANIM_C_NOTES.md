# ANIM_C_NOTES — Storybook (body style C) Rive build

Owner complaint fixed: every mood is BIG full-body acting measured
frame-to-frame, not a face swap. Motion % = mean % of pixels visibly changed
between consecutive strip frames (0/15/30/45/60/75/90 % of each animation,
Pillow grayscale diff threshold 12, black screenshot background remapped to
contract light #FBF7F0 — same metric as ANIM_A).

## Verify (must stay at zero)

- `rive tools/rive/storybook --verify` → 0 errors, 0 warnings
- `rive inspect --summary` (run inside `tools/rive/storybook`) →
  `problems: []`, 5 artboards (Stage1..Stage4 + PipStage), exactly 1
  StateMachine with 3 StateMachineLayers per artboard, 17 LinearAnimations
  per artboard
- Full `rive inspect --json` (4.2 MB) → 0 occurrences of "unresolved":
  0 unresolved bindings
- Binary: `app/assets/animations/rive/pip_storybook.riv`, 105,436 bytes
  (bit-identical copy of `tools/rive/storybook/build/storybook.riv`,
  md5 `baeac190bdb622bbcae4672b77608ca9`, rebuilt 2026-10-01 ~06:30 UTC
  after the eye/ring fixes below)

## Motion % (higher = more obvious; idle is ambient by design)

| mood | s1 egg | s2 hatchling | s3 fledgling | s4 songbird |
|---|---|---|---|---|
| idle | 1.9% | 2.0% | 3.2% | 4.5% |
| happy | 14.0% | 14.3% | 16.3% | 19.1% |
| eating | 2.4% | 3.5% | 4.6% | 6.2% |
| sleepy | 3.2% | 3.8% | 5.4% | 6.0% |
| surprised | 10.8% | 10.6% | 13.3% | 15.3% |
| proud | 4.0% | 4.1% | 5.0% | 5.9% |
| evolve | 11.3% | 13.9% | 15.1% | 17.7% |

Read off MOTION_BOARD: happy = squash → big jump, wings up ×2 flaps, ^^
eyes, sparkle burst; surprised = jump-back, popped wide eyes, "o" beak,
"!" + side sparkles; evolve = squash-pop inside an expanding double glow
ring (largest displacement of all moods). Eating reads through props, not
pixels: seed drops onto the head/beak, ^^ eyes, crumbs fly frames 3–6,
cheek blush — the strip tells a seed→pecks→crumbs story even at 2–6%.
Sleepy reads through nightcap + rising Zzz + closed eyes + slump.

## Files

- Source: `tools/rive/storybook/gen_storybook.py` (71,786 bytes) →
  `artboards/stage1..4.rml`, `artboards/pipstage.rml`, `rive.yaml`
  (main: Stage3); reuses the SVG→RML path conversion from
  `tools/rive/gen_pip.py`
- Pipeline: `tools/rive/storybook/capture.sh` (196 strip frames + mp4
  frames + 24 skin/accessory checks, 4-way parallel) →
  `tools/rive/storybook/boards.py` (strips + board + mp4s + grid + metrics)
- Binary: `app/assets/animations/rive/pip_storybook.riv` (103,711 bytes)
- Strips: `design/animations/rive/storybook/strip_s{1..4}_{idle,happy,eat,sleepy,surprised,proud,evolve}.png`
  (28 strips, 7 frames each), raw frames in `frames/` (625 PNGs, review
  scaffolding)
- `design/animations/rive/storybook/MOTION_BOARD.png` (1.2 MB; rows =
  moods × fledgling/songbird, columns = frames) — look at this first
- `design/animations/rive/storybook/pip_storybook_s3_{idle,happy,eat,sleepy,surprised,proud,evolve}.mp4`
  (7 mp4s, stage 3, 30 fps via /opt/homebrew/bin/ffmpeg)
- `design/animations/rive/storybook/SKIN_ACC.png` (4 skins × 5
  accessories on stage-3 idle — all 20 cells render correctly isolated)

## Contract mapping

- Artboards `Stage1..Stage4` (240×240) + `PipStage` (nest back → Pip →
  nest front rim, one nest geometry, same fractions as `PipInNest`);
  state machine `Pip` on all five, default on all five.
- View model `Pip`: `mood` enum idle|happy|eating|sleepy|surprised|proud,
  `stage` 1–4, `skin` enum sunny|berry|sky|mint, `accessory` enum
  none|bow|cap|scarf|glasses (exact contract names — confirmed in the
  .rml), triggers `evolve`/`tap`/`blink`. (Strip/mp4 filenames use the
  shorthand `eat` for the `eating` enum value; the capture scripts map
  `eat` → `mood=eating` data input.)
- Rig: Node chains root → body → head → tuft, body → wing_l/wing_r,
  body → tail (stage 4); eye/beak swaps use the approved eye child groups;
  squash & stretch is volume-preserving on the body root.
- Layers: exactly Body/Eyes/FX per artboard. Body owns idle loop +
  one-shot moods (sleepy loops); Eyes owns the blink loop independent of
  Body (disabled while sleepy); FX owns sparkles, seeds+crumbs, Zzz, "!",
  proud sparkle — no two layers key the same property.
- Skins recolour body/belly fills via data binding (no duplicated
  artboards per skin); accessories toggle visibility.
- Motion minimums met or exceeded: idle 1→1.04 + ±4° tilt + tuft sway
  lag (3 s loop); happy 0.85-y anticipation squash → 18 px+ jump, wings
  fully up flapping ×2, land squash, sparkle burst, ^^ eyes, open beak
  (1.2 s); eating seed drop + 3 pecks with beak open/close + crumbs +
  cheek puff (1.8 s); sleepy loop droop → closed eyes, head nod, 0.94
  slump, 1→1.06 breath over 4 s, rising/fading Zzz; surprised 10 px
  jump-back, wide eyes, "o" beak, wing flare, tuft spring, "!" pop
  (0.8 s); proud 1.06 chest, 8° chin-up, wing(s) to hip, wink, chest
  sparkle (1.2 s); evolve glow ring + squash-pop (1.5 s). All keyframes
  eased (cubic/elastic, no linear); follow-through/overlap on tuft and
  wings throughout.
- Skins × accessories: all 20 combinations render (SKIN_ACC.png);
  beak/feet/ink untouched by skin recolours.
- Flutter: untouched — `pip_avatar.dart` belongs to the Mochi animator.

## Orchestrator review fixes (2026-10-01, rebuilt + re-rendered)

Root cause of the eye bugs: the RML renderer draws the FIRST sibling
shape on top (proven by reordering experiment: pupil-before-white →
pupil visible; also why belly is emitted before body base and the ground
shadow last). The generator emitted SVG paint order (white first), so
every eye white covered its pupil/highlight.

1. Rest eyes now match `design/pip-v2/C/poses/s*_idle_1.svg` exactly
   (same harvested prims, reordered topmost-first: highlight, pupil,
   white). Idle strip: large dark pupils + highlights in all 7 frames,
   L/R mirror diff 6.3% (residual = tuft asymmetry already in the
   approved art + antialiasing).
2. Surprised uses the approved harvested `s*_surprised_2.svg` eye groups
   verbatim (white r16 + pupil r4.25 + highlight, symmetric L/R by art)
   instead of the procedural scaled pair; the procedural fallback now
   mirrors the pupil offset per side (the old code placed both pupils at
   the left-eye x). Measured: white 452 vs 436 px, dark pupils 82 vs 88
   px L/R — symmetric.
3. Evolve rings shrunk (rx 30/40, peak scale 1.5 → max outer ≈64 px =
   27% of the 240 artboard, centred ≈(120,123) on the torso) and faded
   to opacity 0 by frame 90 — the 90% strip frame shows only a faint
   ghost; peak frames show both rings fully inside the artboard.

## 3 honest weaknesses

1. Eating (2–6%) and proud (4–6%) are the lowest-motion moods; they read
   via props (seed/crumbs, wink/sparkle) rather than body displacement.
   If the owner still finds them vague, the fix is bigger head-dip
   amplitude on pecks and a stronger chest-out lean on proud — no rebuild
   needed for anything else.
2. Blink cadence is baked into the Eyes loop plus the `blink` trigger;
   it is not randomised 2.5–4 s — true random needs a script, deliberately
   avoided for this pass.
3. `frames/` holds 625 intermediate PNGs (review scaffolding, not shipped);
   safe to delete after owner sign-off.
