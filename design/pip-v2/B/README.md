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
`blink` is the neutral idle pose with the eyes closed for two frames and nothing
else — no slump, no Zzz. `sleepy` slumps (body scale 0.92-0.97, dropped), tilts
the head 20-23 deg, uses heavy curved lids and the `snore` beak.
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
* `head` is a parent group holding `cheek_l · cheek_r · brow_l · brow_r ·
  eye_l · eye_r · beak_top · beak_bottom`. It carries the head nod/tilt
  transform; rotate it for nods, keep it upright for bounce. `head_tuft`
  is ONE fused swept-back crest (three lobes, middle tallest, curving back)
  sitting just before `head`; its outline stays open at the base so the fill
  melts into the head with no seam.
* Never scale or offset the two eyes or the two beak halves independently —
  the face stays symmetric about the head's centre line and the whole `head`
  group is what tilts. Wings pivot about the top of the paddle (the shoulder
  joint), so raises swing wide and high.
* All faces are emitted by the face generator (`tools/pip-v2/B/face.mjs`,
  `buildFace()` + `faceSelfTest()`). Both eyes render from ONE shared markup
  string at mirrored offsets; the beak is a single path centred on x = 0;
  cheeks/brows are mirrored pairs; the whole face rotates once by the head
  tilt. Eye size/spacing and beak size are fixed ratios of r (fitted to the
  stage-3 idle face). The generator accepts NO per-eye/per-side input, so
  asymmetric output is inexpressible — except the deliberate wink (left lid a
  clean deep curve, right eye open). Run `node face.mjs` for the symmetry
  self-test; `node qa.mjs` additionally fails the build if any pose carries
  asymmetric face keys.
* All lid shapes (`closed`, `happy`, `sleepy`, `wink`) are true quadratics
  through a shared apex — both eyes use the identical path, so the pair can
  never skew. The wink is a clean deep curve with no lash. Cheek puff is
  clamped at 1.45 in the generator so puffed cheeks stay clear of eyes+beak.
* The eating seed is drawn INSIDE the head (wedged in the open beak, tilting
  with it) on the "seed enters" key frame; approach seeds and flying crumbs
  stay in screen-space `fx`.
* Surprised eyes are idle-sized/positioned with small dot pupils (0.35R) plus
  two raised brow arcs — shock reads in pupils + brows + round `o` beak +
  sprung crest, never in stretched eyes. On wink frames the crest sits centred
  so no dark mass crowds the closed eye.
* All ink is 8 px, including mouth cavities (sized to keep a visible fill).
* Sleepy frames on stages 2-4 wear a nightcap (deep blue cone, white brim,
  white pom) inside `accessory_head` — it is part of the sleepy key frames,
  the same as the other two styles.
* `beak_bottom` is `opacity="0"` when the beak is closed. An open beak is a
  peach `beak_top` over an ink mouth cavity (`beak_bottom`); the surprised
  "o" mouth is a small round cavity — that is the shape that sells the surprise.
* `fx` holds sparkles, Zzz, seeds, crumbs, hearts and "!" — **all drawn as
  shapes, never as text**.
* `shell_top` / `shell_bottom`: on the egg these are the two halves of the
  shell and the crack between them; on the hatchling they are the cap and cup.
  On stage 1 the face is layered *between* them, so the chick peeks through the
  crack. The egg shows **no crest** — the shell is unbroken above the crack.
  Shells are single flat shapes: the cap has no interior lines, the egg keeps
  three spots and one sheen, the cup keeps two spots.
* Only the songbird (stage 4) has a tail — three long feathers in a wide fan.
  The fledgling (stage 3) is a clean oval with two wing paddles and no tail.
* `beak` states: `closed · thin · snore · open · wide · o`. `snore` is the small
  open sleeping mouth; `o` is the round surprise hole; `open`/`wide` are a peach
  upper beak over an ink mouth cavity.

## Stage anatomy

Stage 4 is **not** stage 3 scaled up. The songbird has its own silhouette:

| | stage 3 fledgling | stage 4 songbird |
|---|---|---|
| outline | single pear | head mass + neck + slim chest (`songbirdPath`) |
| height | 112 px | ~131 px (+17 %) |
| crest | 3 feathers, 45 px | 3 feathers, 45 px x 1.12 |
| wings | 35 x 52 | 33 x 70, pointed, swept down-back |
| tail | short fan below the body | 3 long feathers, wide fan clearing the feet |
| stance | feet 44 apart | wider, planted |

The face anchor is the **skull** on stage 4 (`S.head.cy`), not the body centre —
eyes, beak and cheeks all follow the head, so tilting the head on a neck works.

## Colours

| Skin | body | belly | wing |
|---|---|---|---|
| sunny | `#FFD93D` | `#FFF1B8` | `#E9AE00` (tail `#C08700`) |
| berry | `#FF9EBB` | `#FFE1EA` | `#E0688F` (tail `#B84E74`) |
| sky | `#8EC9FF` | `#E2F1FF` | `#5A9FE0` (tail `#3C7FC4`) |
| mint | `#8EE3B5` | `#DDF8E8` | `#46BE90` (tail `#2E9A72`) |

Beak and feet stay peach `#FF8A5B` on every skin; ink stays ink. One soft
highlight per figure, upper-left, 55 % white.

## Regenerating

```
cd tools/pip-v2/B
npm i
node build.mjs         # writes every SVG into design/pip-v2/B
node qa.mjs            # contract ids, stroke, viewBox, canvas-edge clipping
node face.mjs            # face-generator symmetry self-test (round 5)
python3 proof48.py ../../../design/pip-v2/B/poses /tmp/p48.png 1,2,3,4
                       # 48 px legibility proof, nearest-upscaled
node build_boards.mjs  # renders the four BOARD_*.png with sharp
```

`rig.mjs` is the single character rig — poses are data (`poses.mjs`), so a new
beat is a new object, not new drawing code.
