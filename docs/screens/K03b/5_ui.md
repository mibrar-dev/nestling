# 5 UI CHECK — K03b Kid home all done (iteration 1)

Seed `kid_all_done` (per ORCHESTRATOR_NOTES, which overrides the brief's
`demo` arg), route `/kid-home-done`, mode kid, child maya,
simulator BC440E48-B3A3-43BC-971B-0EF5DB621874, `DISABLE_ANIMATIONS=1`.
Tool note: `shot.sh` must be given an ABSOLUTE out path — a relative
`docs/...` out fails at the final `cp` because the script `cd`s into
`$APP_DIR` before copying (first light run hit this; re-ran absolute).

Process note (not a finding): this branch was behind `main` and lacked
`SEED=kid_all_done`, so this stage merged `main` into `screen/K03b`
(`e2472fa`, brings `075aed5` seed + K07 loop artefacts only). No source
file was hand-edited by this stage; new/changed paths are
`docs/screens/K03b/ui/*` + this file.

Shots: `docs/screens/K03b/ui/app_light_1.png`, `app_dark_1.png`
(1170×2532, ÷3 = logical). Compares: `cmp_light_1.png`, `cmp_dark_1.png`.

## Mean diff + bands

Light: mean diff **10.70%**
band 0 (0–105) 3.69 · 1 (105–211) 3.91 · 2 (211–316) 6.62 ·
3 (316–422) 9.90 · 4 (422–527) 15.60 · 5 (527–633) 25.73 ·
6 (633–738) 14.35 · 7 (738–844) 5.80

Dark: mean diff **9.10%**
band 0 3.74 · 1 3.78 · 2 4.36 · 3 6.28 · 4 13.70 · 5 24.27 ·
6 12.06 · 7 4.58

Bands 0–1 ≈ status-bar clock (OS-drawn, ignored) + header AA.
Bands 2–4 ≈ Pip art swap (mandated PipAvatar vs v1 SVG) + confetti
positions (shared asset, decorative). Band 5 is the real drift (below).

## Measured y (logical px = full-res ÷ 3), design vs app

Light (dark identical unless noted):

| Element | Design | App | Δ |
|---|---|---|---|
| Header "Hi Maya!" glyph top | 64.3 | 64.3 | 0 |
| Speech bubble top / bottom | 125.0 / 190.7 | 125.0 / 190.7 | 0 / 0 |
| Section title "Today's quests" top | 469.3 | 484.7 | **+15.4** |
| Kid progress bar outer top | 513.0 | 528.7 | **+15.7** |
| Quest card 1 top border | 545.0 | 560.7 | **+15.7** |
| Quest card 1 bottom border | 630.0 | 645.3 | **+15.3** |
| Quest card 1 height | 85.0 | 85.0 | 0 (shapes identical) |
| Quest card 2 top border | 645.0 | 660.3 | **+15.3** |
| Card left / right edges | 20.3 / 369.3 | 20.3 / 369.3 | 0 / 0 |
| "Visit Pip" lilac fill top / bottom | 739.0 / 796.7 | 739.0 / 796.7 | 0 / 0 |
| Button fill left / right | 23.0 / 366.7 | 23.0 / 366.7 | 0 / 0 |

Cross-correlation of identical-shape strips confirms a clean uniform
shift: title strip best dy = +46 full-res px (+15.3 logical, residual
2.1), card-1 strip +46 px; bubble strip dy = 0, button strip dy = 0.
Dark mode measures the same (title 484.7, card1 560.3, button exact).

## Deviations (design value → app value + fix)

1. Section + cards shifted down ~15.3 px (MAJOR — breaks ±2 px rule).
   Title 469.3→484.7, progress 513.0→528.7, card1 545.0→560.7,
   card2 645.0→660.3; card shapes/heights identical (85.0 both),
   gutters exact. Because card2's bottom lands ~9 px lower, the app
   clips card 2 behind the bottom bar while the design shows it whole
   with a gap. Everything above the pet stage (header, bubble) and the
   bottom bar itself are pixel-exact, so the pet-stage block lays out
   ~15 px too tall: bubble bottom 190.7 + 14 gap + stage + 16 gap =
   title ⇒ app stage ≈ 264, design PNG block ≈ 248.6 (note: the PNG
   block is NOT the CSS 226 — do not blindly force 226, which would
   overshoot to ≈446.7). Suspect: `slotHeight: 226` is not honoured
   as the total — shared `explicitGeometry` (`motion/pip_rive.dart`)
   returns `nestTop + nestH + _explicitBleed` (= 257.4) and the
   `stageH = effectiveSlotH` local is dead code, plus a possible 6 px
   `_padTop`. Shared code may not be touched from this branch: file a
   SHARED_REQUEST or apply an approved feature-side height correction,
   then re-shoot until title = 469.3, progress top = 513.0,
   card1 top = 545.0 (both themes).
2. Speech-bubble text alignment (MINOR, visible). Design `.speech`
   sets no `text-align` (browser left): line 2 "is so proud." starts
   at the left. App `NestSpeechBubble` hard-codes
   `textAlign: center`. Single-line K03/K05 bubbles hide this; the
   2-line K03b bubble shows it. Needs `textAlign: start` for this
   bubble — shared-param SHARED_REQUEST or approved approach; do not
   fork the bubble component.

## Explicitly NOT deviations (rules override the PNGs)

- Status-bar clock 9:41 vs 04:37 — OS-drawn; `NestStatusBar` only
  reserves height. Ignored.
- Pip art (round Mochi avatar vs tall v1 fledgling SVG) — PIP rule:
  the child's OWN `PipAvatar` is mandatory; v1 SVGs never in product.
- Confetti piece positions — shared `confetti.svg` asset, decorative.
- Card meta/order ("Waiting for Mum" chips, 2nd card "Hoover the
  stairs" vs design "Reading – 20 minutes" with +10/+15 pills) —
  DB-driven per DATA OVER MOCKS and the known 1_plan §d discrepancy;
  `kid_all_done` marks everything `done_pending`. Excluded.
- Bottom edge: design shows a meadow-green strip under the bar; app
  runs bar surface to the edge (light `#FFFFFF`, dark `#1F1C2E`
  sampled at y 836/841) — BOTTOM EDGE owner rule; app is correct.
- Copy is ASCII-exact vs the HTML: "Hi Maya!", "All done!",
  "You did everything today! Pip is so proud.", "Today's quests"
  (straight apostrophe), "6 of 6 done", "Visit Pip", "Empty the
  dishwasher". Coin pill 120, lilac bar, leaf-ink sub-line, full
  progress fill all match.

## Verdict

Two real deviations (a +15.3 px block shift and a text-alignment
flip) exceed the ±2 px design-match rule.

VERDICT: FAIL
