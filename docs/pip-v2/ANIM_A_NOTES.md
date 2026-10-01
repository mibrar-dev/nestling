# ANIM_A_NOTES — Mochi (body style A) Rive build

Owner complaint fixed: every mood is full-body acting measured frame-to-frame,
not a face swap. Motion % = mean % of pixels visibly changed between
consecutive strip frames (0/15/30/45/60/75/90 % of each animation).

## Verify (must stay at zero)

- `rive tools/rive/mochi --verify` → 0 errors, 0 warnings
- `rive inspect tools/rive/mochi --summary` → `problems: []`
- `rive tools/rive/mochi --once` → `build/pip_mochi.riv`, 161,520 bytes,
  `RIVE` magic, format major 7 (same runtime as v1 `pip.riv`)

## Motion % (higher = more obvious; idle is ambient by design)

| mood | s1 egg | s2 hatchling | s3 fledgling | s4 songbird |
|---|---|---|---|---|
| idle | 4.7% | 3.3% | 5.0% | 5.5% |
| happy | 12.0% | 14.3% | 18.0% | 16.1% |
| eating | 7.4% | 5.0% | 8.4% | 9.6% |
| sleepy | 6.3% | 4.3% | 7.9% | 8.6% |
| surprised | 10.0% | 9.0% | 11.5% | 10.8% |
| proud | 9.3% | 5.8% | 7.7% | 7.5% |
| evolve | 22.8% | 24.2% | 18.1% | 17.6% |

## Orchestrator fix pass (board re-rendered + re-checked)

1. Happy wings covered the face at peak (rotation overshot inward over the
   eyes: ±2.2, then ±1.6). Peak cut to ±1.3 rad (proven-clear surprised-flare
   geometry) plus a 12 px outward shift keyed on each wing node, so wings
   rise to the sides and stay behind the head; ^^ eyes and open beak are
   fully visible at peak on fledgling and songbird (verified pixel-level:
   head node is emitted before the wing nodes, i.e. front-most).
2. Surprised ~15 % showed grey double-ring eyes (open + surprised whites
   overlapping mid-blend). Eyes-layer mood transitions shortened 120 → 80 ms
   on all artboards (Body stays 150 ms); the swap completes before the 15 %
   frame. Verified accessory_face stays hidden unless `accessory` is set
   (Formula-isolated, see `skin_accessory_grid.png`).
3. Evolve ring ran off the artboard (r86 × scale 1.5). Ring cut to r72,
   peak scale 1.2 (max radius 86 px < 108 = 45 % of 240), centred on the
   body centre, opacity out by f66 — last board frame is clean.
   Rebuild md5 `0394fc701e792ecf816fc8fd7a0f6376` (supersedes `e5e43439…`).

Proud was 2–5% on first pass (face-only); it now lifts, leans, splays a wing
and pops a bigger sparkle. Egg adaptations per contract: happy = hop + wobble,
eating = rock + nibble crumbs through the crack, sleepy = slow rock + Zzz,
surprised = jolt, proud = rock + shine sweep.

## Files

- Source: `tools/rive/mochi/gen_mochi.py` (69 KB) → `stage1..4.rml`,
  `pipstage.rml`, `shared.rml`, `rive.yaml` (main: Stage3)
- Matrix scripts: `tools/rive/mochi/matrix.py` (196 renders),
  `tools/rive/mochi/assemble.py` (strips + board + table)
- Binary: `app/assets/animations/rive/pip_mochi.riv` (160,404 bytes)
- Strips: `design/animations/rive/mochi/strip_s{1..4}_{mood}.png`
  (7 frames each), raw frames in `frames/` (3.2 MB, review scaffolding)
- `design/animations/rive/mochi/MOTION_BOARD.png` (1.3 MB; rows = moods ×
  fledgling/songbird, columns = frames) — look at this first
- `design/animations/rive/mochi/mp4/{idle,happy,eating,sleepy,surprised,proud,evolve}.mp4`
  (Stage3, 30 fps, true duration)
- `design/animations/rive/mochi/skin_accessory_grid.png` (4 skins ×
  5 accessories, all isolated correctly)
- Widget: `app/lib/core/design_system/motion/pip_avatar.dart`,
  test `app/test/pip_avatar_test.dart` (27 tests)
- Fallbacks: `app/assets/illustrations/pip_v2/mochi/s{1..4}_idle_1.svg`
  (exact copies of the approved poses); bolt/storybook hold a marked
  placeholder until their animators land

## Contract mapping

- Artboards `Stage1..Stage4` (240×240) + `PipStage` (350×260, one nest
  geometry, back → Pip → front rim, same split/feet fractions as
  `PipInNest`); state machine `Pip` on all five, default on all five.
- View model `Pip`: `mood` 0–5, `stage` 1–4, `skin` 0–3, `accessory` 0–4 as
  Numbers (same representation as v1 `mood`/`stage`, so transitions use the
  proven `BindablePropertyNumber` path); `bodyColor`/`darkColor`/`bellyColor`
  Colors; `evolve`/`tap`/`blink` Triggers.
- Rig: Node chains root → body → head → tuft, body → wings/tail; eye/beak
  swaps use the approved eye child groups verbatim; squash & stretch is
  volume-preserving (1.18×0.85, 0.93×1.08, 1.10×0.94 …).
- Layers: exactly Body/Eyes/FX on Stage1..4. PipStage = Stage selector +
  one Body/Eyes/FX trio per rig (13 layers) so the four rigs move as one
  and `stage` picks the visible one. Layer ownership is strict (Body owns
  transforms + beak, Eyes owns the 12 eye-variant opacities, FX owns the 7
  fx nodes) — no two layers key the same property.
- Skins recolour body + dark (wings/tuft/tail) + belly via data binding;
  beak/feet/ink untouched. Accessories toggle through Formula converters
  `1 − min(1, (input−N)²)` (no `abs` exists in the formula function table).
- Motion minimums all met or exceeded: idle 1→1.04 + ±4° tilt + tuft lag
  (3 s loop); happy 0.85 squash → 22 px jump, wings ±126° ×2 flaps, ^^,
  open beak, sparkle burst (1.2 s); eating seed drop + 3 pecks + 3 crumb
  bursts + cheek puff (1.8 s); sleepy loop 0.94 slump, 4 s breath, nods,
  nightcap (approved art), rising Zzz; surprised 10 px jump-back, wide eyes,
  "o" beak (approved peak art), ±74° flare, elastic tuft + "!" (0.8 s);
  proud 1.10 chest, −11° chin, akimbo wings, wink, chest sparkle (1.2 s);
  evolve squash-pop + glow ring (1.5 s). Everything cubic/elastic; follow-
  through on tuft and wings everywhere.
- Flutter: `flutter analyze` clean, `flutter test` 241/241 pass (27 new).
  v1 `pip_rive.dart` untouched.

## 3 honest weaknesses

1. PipStage duplicates all four rigs + all trios (8,622 objects, 160 KB —
   6× v1). Runtime cost is one widget, but the file is heavy; a future pass
   could drive PipStage through nested artboards instead.
2. Sleepy on the egg reuses the nightcap-less rock; the egg has no cap art
   in the approved set, so stages 1–2 sleep bare-headed while 3–4 wear caps.
3. Blink is baked into the Eyes `open` loop (3 s) plus the `blink` trigger;
   cadence is fixed, not randomised 2.5–4 s — true random needs a Luau
   script, deliberately avoided for this pass.
