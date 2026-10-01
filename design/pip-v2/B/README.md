# Pip v2 · style B "BOLT" — art handoff

100% original art. No third-party assets, no gradients, no text in the art.
Binding spec: `docs/pip-v2/PIP_V2_CONTRACT.md`.

## Files

| Path | Count | What it is |
|---|---|---|
| `poses/s{stage}_{mood}_{n}.svg` | 112 | key-pose library, 4 stages × 7 moods |
| `skins/skin_{skin}_s3_{mood}.svg` | 8 | fledgling idle + happy in all 4 skins |
| `accessories/acc_{kind}_s{stage}.svg` | 17 | bow / cap / scarf / glasses on all 4 stages + `none` |
| `evolve/evolve_{pair}_{n}.svg` | 12 | s1→s2, s2→s3, s3→s4, 4 key frames each |
| `stage_{n}_{name}.svg` | 4 | on-model rest references |
| `BOARD_*.png` | 4 | review boards |

Frames per mood: idle 3 · blink 3 · happy 4 · eating 5 · sleepy 4 · surprised 4 · proud 5.
Egg adaptations per contract: happy = hop + wobble + sparkle, eating = peek & nibble,
sleepy = slow rock + Zzz, surprised = jolt + crack widens, proud = shine sweep.

## Geometry

`viewBox="0 0 240 240"`, ground baseline **y = 214**, ground shadow ellipse centred on
(120, 214). Ink `#1E1B3A`, stroke weight **8**, round joins/caps.

## Part ids (identical in every file)

Every file carries all of these groups; a part that does not exist at a stage is
present with `opacity="0"` so the artboard structure never changes.

```
shadow  tail  wing_l  wing_r  body  belly  cheek_l  cheek_r  head_tuft
eye_l  eye_r  brow_l  brow_r  beak_top  beak_bottom  feet
shell_top  shell_bottom  accessory_head  accessory_neck  accessory_face  fx
```

* `eye_l` / `eye_r` each contain the six state children
  `open · closed · happy · sleepy · surprised · wink`.
  Exactly one has `opacity="1"`; the rest are `opacity="0"`. The Eyes layer
  toggles these independently of mood, so blink layers over any pose.
* `head` is a parent group holding `head_tuft · cheek_l · cheek_r · brow_l ·
  brow_r · eye_l · eye_r · beak_top · beak_bottom`. It carries the head
  nod/tilt transform; rotate it for nods, keep it upright for bounce.
* `beak_bottom` is `opacity="0"` when the beak is closed. An open beak is a
  peach `beak_top` over an ink mouth cavity (`beak_bottom`); the surprised
  "o" mouth is a small round cavity — that is the shape that sells the surprise.
* `fx` holds sparkles, Zzz, seeds, crumbs, hearts and "!" — **all drawn as
  shapes, never as text**.
* `shell_top` / `shell_bottom`: on the egg these are the two halves of the
  shell and the crack between them; on the hatchling they are the cap and cup.
  On stage 1 the face is layered *between* them, so the chick peeks through the
  crack.

## Colours

| Skin | body | belly | wing |
|---|---|---|---|
| sunny | `#FFD93D` | `#FFF1B8` | `#E9AE00` |
| berry | `#FF9EBB` | `#FFE1EA` | `#E0688F` |
| sky | `#8EC9FF` | `#E2F1FF` | `#5A9FE0` |
| mint | `#8EE3B5` | `#DDF8E8` | `#46BE90` |

Beak and feet stay peach `#FF8A5B` on every skin; ink stays ink. One soft
highlight per figure, upper-left, 55 % white.

## Regenerating

```
cd tools/pip-v2/B
npm i
node build.mjs         # writes every SVG into design/pip-v2/B
node qa.mjs            # contract ids, stroke, viewBox, canvas-edge clipping
node build_boards.mjs  # renders the four BOARD_*.png with sharp
```

`rig.mjs` is the single character rig — poses are data (`poses.mjs`), so a new
beat is a new object, not new drawing code.
