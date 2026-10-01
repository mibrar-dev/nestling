# ANIM_B_NOTES — Bolt (body style B) Rive build

Owner complaint fixed: every mood is full-body acting measured frame-to-frame,
not a face swap. Motion % = mean % of pixels visibly changed between
consecutive strip frames (0/15/30/45/60/75/90 % of each animation, same metric
as ANIM_A: summed RGB diff > 36 on every 2nd pixel).

## Verify (must stay at zero)

- `rive tools/rive/bolt --verify` → 0 errors, 0 warnings
- `rive inspect tools/rive/bolt --summary` → `problems: []`, 5 artboards
  (Stage1..Stage4 + PipStage), exactly 1 StateMachine with 3 StateMachineLayers
  per stage artboard (Body/Eyes/FX), 21 LinearAnimations per stage
- Full `rive inspect --json` → 0 occurrences of "unresolved": 0 unresolved bindings
- Binary: `app/assets/animations/rive/pip_bolt.riv` (161,539 bytes, bit-identical
  copy of `tools/rive/bolt/build/pip_bolt.riv`, md5
  `3d980753a3d30a4a879bc75b9a6f57f5`, rebuilt 2026-10-01 ~14:03 UTC from the
  latest approved poses + orchestrator fix rounds below)

## Motion % (higher = more obvious; idle is ambient by design)

| mood | s1 egg | s2 hatchling | s3 fledgling | s4 songbird |
|---|---|---|---|---|
| idle | 2.3% | 4.1% | 5.5% | 5.4% |
| happy | 7.3% | 14.5% | 17.4% | 17.5% |
| eating | 2.9% | 4.9% | 9.6% | 9.4% |
| sleepy | 2.5% | 3.5% | 5.8% | 6.5% |
| surprised | 5.3% | 9.0% | 10.7% | 11.0% |
| proud | 3.9% | 5.8% | 7.3% | 7.2% |
| evolve | 9.8% | 15.0% | 17.7% | 16.5% |

Read off MOTION_BOARD: idle = breathe + tilt + crest sway (ambient); happy =
0.82 squash → 24 px jump, wings fully up flapping ×2 (behind the head, ^^ +
open beak visible at peak), crest whip, sparkle burst, land squash; eating =
big seed drops in → 3 pecks with beak open/close → crumbs fly → cheek puff +
satisfied ^^; sleepy = slump + nod + nightcap + rising Zzz; surprised =
12 px jump-back, 1.3× eyes with constant 8 px outline (no glasses), "o" beak,
wing flare, crest spring, "!" pop; proud = chest 1.08, chin 8°, wings to hips,
clean wink, chest sparkle; evolve = centred glow ring + pop (largest motion).

## Files

- Source: `tools/rive/bolt/gen_bolt.py` (affine-aware Bolt port of
  `tools/rive/mochi/gen_mochi.py`) → `stage1..4.rml`, `pipstage.rml`,
  `shared.rml`, `rive.yaml` (main: Stage3, name: pip_bolt)
- Matrix: `tools/rive/bolt/matrix.py` (196 strip renders),
  `tools/rive/bolt/assemble.py` (strips + board + motion % table)
- Binary: `app/assets/animations/rive/pip_bolt.riv` (159,599 bytes)
- Strips: `design/animations/rive/bolt/strip_s{1..4}_{idle,happy,eating,sleepy,surprised,proud,evolve}.png`
  (28 strips, 7 frames each), raw frames in `frames/` (review scaffolding)
- `design/animations/rive/bolt/MOTION_BOARD.png` (rows = moods ×
  fledgling/songbird, columns = frames) — look at this first
- `design/animations/rive/bolt/mp4_{idle,happy,eating,sleepy,surprised,proud,evolve}.mp4`
  (Stage3, 30 fps via /opt/homebrew/bin/ffmpeg)
- `design/animations/rive/bolt/SHOWREEL.mp4` (112 KB, 6.00 s, 30 fps —
  fledgling idle→happy→eating→sleepy→surprised→proud→evolve, 26 frames each)
- `design/animations/rive/bolt/SKIN_ACC.png` (4 skins × 5 accessories on
  stage-3 idle — all 20 cells render isolated, accessory default none)
- Widget: `app/lib/core/design_system/motion/pip_avatar.dart` (untouched —
  Mochi animator owns it; Bolt matches its Numbers + bodyColor/darkColor/
  bellyColor contract)
- Fallbacks: `app/assets/illustrations/pip_v2/bolt/` untouched (placeholder
  until owner approves; Mochi fallbacks only)

## Contract mapping

- Artboards `Stage1..Stage4` (240×240) + `PipStage` (350×260, nest back → Pip
  → nest front rim, one nest geometry, same split/feet fractions as Mochi's
  `PipInNest`); state machine `Pip` on all five, default on all five.
- View model `Pip`: `mood`/`stage`/`skin`/`accessory` as Numbers 0–5/1–4/0–3/
  0–4 (same representation as Mochi + v1, so transitions use the proven
  `BindablePropertyNumber` path and `pip_avatar.dart` drives Bolt with zero
  branches); `bodyColor`/`darkColor`/`bellyColor` Colors; `evolve`/`tap`/
  `blink` Triggers. Accessory default none via Formula converters
  `1 − min(1, (input−N)²)`.
- Rig: Node chains root → body → head → crest, body → wings/tail; eye/beak
  swaps use the approved Bolt eye child groups verbatim (face.mjs symmetric
  geometry — both eyes render from one shared markup, beak centred on x=0,
  whole head tilts once); squash & stretch is volume-preserving.
- Layers: exactly Body/Eyes/FX on Stage1..4 (PipStage = Stage selector + one
  Body/Eyes/FX trio per rig, 13 layers). Body owns transforms + beak, Eyes
  owns the 12 eye-variant opacities (+1.3× surprised pop in geometry, stroke
  stays 8 px), FX owns the 7 fx nodes — no two layers key the same property.
- Skins recolour body + dark (wings/crest/tail) + belly via data binding
  (sunny #FFD93D/#E9AE00, tail #C08700 → darkColor; beak/feet/ink untouched);
  accessories toggle through Formula converters.
- Motion minimums all met or exceeded: idle 1→1.05 + ±5° tilt + crest sway
  (3 s loop); happy 0.82 squash → 24 px jump, wings ±1.3 rad + 12 px outward
  ×2 flaps, ^^, open beak, sparkle burst (1.2 s); eating seed drop + 3 pecks
  (10 px dip, 0.38 rad tilt) + crumbs + cheek puff (1.8 s); sleepy loop 0.94
  slump, 4 s breath, nods, nightcap, rising Zzz; surprised 12 px jump-back +
  8 px up, 1.3× eyes (geometry scale, constant outline), "o" beak, flare,
  elastic crest + "!" (0.8 s); proud 1.08 chest, −0.14 rad (8°) chin, wings
  to hips, wink, chest sparkle (1.2 s); evolve squash-pop + centred glow ring
  (r72, peak 1.2, concentric from frame 0, opacity out by f66) (1.5 s).
  Everything cubic/elastic; follow-through on crest and wings everywhere.
- Flutter: `flutter analyze` clean, `flutter test` all pass (no test edits).
  v1 `pip_rive.dart` untouched.

## Orchestrator fix round (2026-10-01 ~13:15 UTC, rebuilt + re-rendered)

1. SURPRISED — change of approach (owner saw "glasses" in the 1.3× scaled
   whites). New definition on every stage: whites stay idle-sized (r16,
   same 8 px outline, no scaling anywhere — the old geometry-xf 1.3× and
   any node scale are gone); pupils shrink to centred dots (~35% of idle
   pupil, r3.0); two short raised brow arcs (18 px wide, ink 8 px, floating
   clear of the eye tops and of each other — never a bridge/frame); round
   dark "o" beak; crest spring, 12 px jump-back, wing flare and "!" kept.
   Strip frame 0 still shows idle (80 ms Eyes-layer entry blend); frames
   1–6 hold the shock read with zero rings.
2. SLEEPY nightcap sat on the eyes like a blindfold (node+origin shifts
   cancelled out, net zero). Fixed to shift the node only, computed per
   stage so the brim bottom ends above the brow line; the cap sits on top
   of the head behind/above the crest base and both closed sleepy curves
   are fully visible under it.
3. EVOLVE carried the approved file's filled white disc (38% opacity →
   grey wash on dark). The generator now drops filled-translucent prims
   and keeps thin bright rings only (coin r72 + white r78/r43, max
   93.6 px < 45% of 240) + sparkle; Pip stays fully visible and bright,
   last frame clean. Evolve motion % fell 26.3→22.7% (fewer pixels under
   the wash) and is still the highest by far.

## Orchestrator fix round 2 — surprised "glasses" root cause (Mochi commit
565547d applied to Bolt)

Mochi proved the bridge came from (a) a stale duplicate eye helper
overriding the fix, (b) the closed/"o" beak sitting between the eye rims,
(c) wing flare reaching eye level — plus blend double-imaging. Applied to
Bolt (verified each by rendering Stage2/3/4 advance-20 eye zooms):

1. Duplicate-def check: `grep -n "^def " gen_bolt.py | sort -k2 | uniq -d
   -f1` → empty (Bolt's shock geometry is inline in `build_rig`, no
   helper to go stale); also grepped out stale 1.3/1.15 eye-scale remnants
   — none remain. (One self-inflicted `IndentationError` from the patch
   was caught before build: the first post-patch `--once` silently reused
   stale RML, spotted via unchanged byte size, fixed, rebuilt.)
2. Closed beak now rides its own `beak_top_n` node (new NODE_TABLE entry):
   opacity 1 in every Body timeline except surprised (= 0 — the approved
   surprised art has no closed beak), so nothing sits between the eyes;
   the "o" (`beak_alt_n`) sits at (0, +11) × 0.8 — low, small, clear
   yellow gap to both eye rims at every frame. Brows moved to the OUTER
   halves only (Mochi-style, nothing drawn between the eyes). Eyes-layer
   entry into surprised is now 0 ms (main machine + all four PipStage
   trios) so no blend frame can double-image rings.
3. Surprised wing flare cut ±1.3 → ±0.55 rad — flares stay below eye level
   on all stages (verified full-frame S2/S3/S4).
4. Evolve: dropped every ring smaller than the head (white r78/r43 both
   crossed the face grey-on-black). Only the outer thin gold ring (r72,
   peak ×1.2 ≈ 86 px) + sparkle remain; Pip bright throughout, last frame
   clean. Evolve % 22.7→17.7, still top.
Strip note: frame 0 shows idle (entry), frame 1 catches the 150 ms Body
crossfade at the beak (same accepted Mochi behaviour); frames 2–6 hold pure
shock with a visible eye gap throughout.

## Design handoff (proud rebuilt from latest)

Per T3 the designer was finishing PROUD poses during this build. All other
moods were built first; at the end `design/pip-v2/B/poses/s*_proud_*.svg`
were re-read twice (mtimes 09:40 BST, then 09:45/13:19 BST updates — eyes
mirrored about x=120 on all stages: s3 94/146, s4 95.56/144.44) and proud
was re-harvested (wink + chest sparkle) + strips re-rendered from the
latest files. Proud strips show centred symmetric wink + sparkle. This rig
sidesteps the T2 bug by construction (idle rig + wink variant, never the
proud pose's baked head transform), so faces stay symmetric per face.mjs.

## Pitfalls hit (Bolt-specific, for the next animator)

1. Bolt hides inactive eye variants with `opacity="0"`, not `display:none`
   (Mochi). The collector baked that 0 into paint alpha (`001E1B3A`), so ^^ /
   closed / wink eyes rendered transparent even when their node went to 1.
   Fix: reset harvested eye prims to opacity 1 — node opacity drives
   visibility, paint stays opaque.
2. Bolt nests eyes inside `head` and fx inside sub-groups (`fx_sparkle_0`),
   and positions everything with `translate/scale/rotate` (Mochi uses absolute
   coords + rotate only). The Mochi collector ignored transforms and matched
   only top-level groups, so wings/eyes/beaks landed at the origin. Fix:
   affine-bake every transform (storybook's parse/mat_apply) + subsequence
   group matching.
3. Bolt base idle `beak_bottom` is empty (opacity 0, no shapes); Mochi's base
   carries the open mouth. Harvest the open mouth from `s{n}_happy_2.svg`
   (dropping the in-mouth seed — seed flies via fx) and the "o" from
   `s{n}_surprised_2.svg`.
4. Surprised 1.3× must live in geometry (like Mochi's xf), not node scale —
   node scale turns 8 px ink into 10.4 px glasses rims. Geometry scale keeps
   the outline constant.

## 3 honest weaknesses

1. Eating (2.9–9.6%) and sleepy (2.5–6.1%) are the lowest-motion moods; they
   read via props (seed/crumbs/^^, nightcap/Zzz/closed eyes) rather than body
   displacement. If the owner wants bigger numbers, raise peck dip 10→14 px
   and sleepy nod amplitude — no rebuild needed for anything else.
2. Blink is baked into the Eyes `open` loop (180 f) plus the `blink` trigger;
   cadence is fixed, not randomised 2.5–4 s — true random needs a Luau
   script, deliberately avoided (same as Mochi/Storybook).
3. `frames/` holds ~400 intermediate PNGs (review scaffolding, not shipped);
   safe to delete after owner sign-off. PipStage duplicates all four rigs
   (8,378 objects, 160 KB — same tradeoff as Mochi); a future pass could drive
   it through nested artboards.
