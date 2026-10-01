# Pip v2 — shared character contract (all body styles)

Owner decisions: Pip is 100% original Nestling art (copyright ours; trademark to be registered). Children **pick** their Pip — no gender data. Customisation = **body style × colour skin × accessory**. Three body styles ship: **A Mochi**, **B Bolt**, **C Storybook** (see `design/pip-v2/PIP_V2_DIRECTIONS.png`).

## Canvas & geometry (every SVG, every style)
- viewBox `0 0 240 240`, ground baseline (feet / egg base) at **y = 214**, ground shadow ellipse centred at (120, 214).
- Ink outline colour token `#1E1B3A`; stroke weight fixed per style (A 6, B 8, C 5).
- Must read at **48 px** and at **280 px**, on light (#FBF7F0) **and dark (#15131F)** backgrounds — "dark" is a rendering check, not a mood.

## Part ids (Rive-ready groups — identical names in every style/stage where the part exists)
`shadow, tail, wing_l, wing_r, body, belly, cheek_l, cheek_r, head_tuft, eye_l, eye_r` (each eye has child groups `open, closed, happy, sleepy, surprised, wink`), `brow_l, brow_r` (optional), `beak_top, beak_bottom, feet, shell_top, shell_bottom` (stages 1–2), `accessory_head, accessory_neck, accessory_face`, `fx` (sparkles, Zzz, seeds, crumbs, hearts).

## Stages
1 egg (peeking eyes through crack) · 2 hatchling (shell hat + shell cup) · 3 fledgling · 4 songbird (tail, spread wings). Clear size progression; same face language across stages.

## Moods (every style × every stage) — must read INSTANTLY; full-body acting, not just a face swap
| Mood | Required readable beats (key poses to draw: anticipation → peak → settle) |
|---|---|
| idle | gentle breathe (body scale 1→1.04), tiny head tilt, tuft sway; loop 3 s |
| blink | eyes close fully in 2 frames, reopen; layered over any mood |
| happy | anticipation squash → jump (≥ 18 px) with wings fully up, ^^ eyes, open beak, sparkles burst, land squash |
| eating | seed falls in → head dips & pecks 3× (beak opens/closes), crumbs fly, cheek puff, satisfied ^^ |
| sleepy | eyes droop → close (curved lines), head nods/droops, slow deep breathing, Zzz rising; nightcap optional |
| surprised | jump-back, eyes wide (big pupils), beak "o", wings flare, tuft springs up, "!" fx |
| proud | chest out, chin up, wing on hip / both wings on hips, wink, small sparkle on chest |
| evolve | glow + spin/pop → next stage appears (stage n → n+1) |
Egg adaptations: happy = hop & wobble with sparkle, eating = n/a → "peek & nibble crumb through crack", sleepy = slow rock + Zzz, surprised = jolt + crack widens, proud = shine sweep.

## Skins (colour variants, apply to every style) — 4 at launch
`sunny` (yellow #FFD93D, belly #FFF1B8) · `berry` (pink #FF9EBB, belly #FFE1EA) · `sky` (blue #8EC9FF, belly #E2F1FF) · `mint` (green #8EE3B5, belly #DDF8E8). Beak/feet stay peach #FF8A5B; ink stays ink.

## Accessories (each must fit all 4 stages incl. egg where sensible) — 4 at launch + none
`bow` (accessory_head) · `cap` (accessory_head) · `scarf` (accessory_neck) · `glasses` (accessory_face) · `none`.

## Rive contract (for the animators, phase 2)
One `.riv` per body style: `pip_mochi.riv`, `pip_bolt.riv`, `pip_storybook.riv`. Artboards `Stage1..Stage4` + `PipStage` (in nest). One view model **`Pip`** with properties: `stage` (1–4), `mood` (enum idle|happy|eating|sleepy|surprised|proud), `skin` (enum sunny|berry|sky|mint), `accessory` (enum none|bow|cap|scarf|glasses), triggers `evolve`, `tap`, `blink`. Layered state machine `Pip`: layer **Body** (moods), layer **Eyes** (blink loop independent of mood), layer **FX**. Same names in all three files so one Flutter widget (`PipAvatar(style:, stage:, mood:, skin:, accessory:)`) drives any of them.
