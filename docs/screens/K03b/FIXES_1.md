# Fix list after iteration 1

## From 3_test.md

## From 4_review.md
# K03b Kid home all-done — 4 QA code review (iteration 1)

Scope: `git diff main...HEAD` on branch `screen/K03b` — kid_home feature
files plus this screen's notes. No code edited by this stage. No
simulator booted, installed on, screenshotted or driven (stage 5 owns
the one allowed UDID).

## Files reviewed

| File | Δ |
|---|---|
| `app/lib/features/kid_home/kid_home.dart` | drop barrel export of deleted placeholder |
| `app/lib/features/kid_home/kid_home_routes.dart` | `/kid-home-done` now builds `KidHomeView` |
| `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart` | +`allDone` getter |
| `app/lib/features/kid_home/presentation/views/kid_home_view.dart` | all-done branch (`_AllDoneBody`, `_AllDoneBar`), K03 branch re-indented |
| `app/lib/features/kid_home/presentation/views/kid_home_done_view.dart` | deleted placeholder |
| `app/test/features/kid_home/k03b_all_done_view_test.dart` | new (8 tests) |
| `docs/screens/K03b/**` | plan, build notes, orchestrator notes |

## Evidence gathered

- `dart format --output=none --set-exit-if-changed app/lib/features/kid_home app/test/features/kid_home` → 50 files, **0 changed**.
- `flutter analyze lib/features/kid_home test/features/kid_home/k03b_all_done_view_test.dart` → **No issues found!**
- `flutter test --timeout 120s test/features/kid_home/k03b_all_done_view_test.dart` → **All tests passed!** (+8). Build log records the full suite green (+4395 ~12), including K03's `kid_home_view_test.dart`, `k03_bugs_test.dart`, `kid_home_geometry_test.dart`.
- Edit set is clean against RULES §1: only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**`, `docs/screens/K03b/**`. No
  `app/lib/core/**`, `app/lib/app/**`, `tools/**` or `analysis_options`
  entry in the diff. No `SHARED_REQUEST.md` needed — every component the
  screen uses (`NestSpeechBubble`, `NestPetStage` with `slotHeight`,
  `NestKidButton`, `KidStatusChip`, `NestProgress`, confetti asset)
  already exists on main.
- Orchestrator rules re-checked: Pip is the child's own `PipAvatar`
  (`pipStyleOf/pipSkinOf/pipAccessoryOf` from the row, stage clamped
  1..4, `PipMood.happy` — Rive-only, harmless under
  `DISABLE_ANIMATIONS`); no v1 `pip_stage_*.svg`. `NestStatusBar` is the
  shared height-only bar. Counts/copy derive from the DB
  (`doneCount`/`totalCount`/`fraction` off period-scoped items); no
  design numbers hard-coded. Children are added-order (untouched path).
  Klondike: `_AllDoneBar` + `SafeArea(top: false)` keeps the bar's
  `surface` running to the physical edge — no meadow strip under the
  bar in either theme. No `google_fonts`, no `DateTime.now()`, no
  `name[0]`, no v1 assets. Accessibility: Visit Pip exposes
  `SemanticsAction.tap` (tested); confetti is `ExcludeSemantics` +
  `IgnorePointer`; header text group is a non-control
  `excludeSemantics` label; done checks are display-only (same as K03).
  Children's Code: no analytics/ads/tracking; failures/loading/empty
  channels are the shared K03 widgets. K03 not-done branch is
  behaviourally unchanged (all K03 tests pass).

## Findings

1. **major** — `_AllDoneBody` vertical rhythm is off by 16 px versus the
   design CSS. `design/html-source/screens/K03b-kid-home-done.html`
   puts the speech bubble, then `.k3-stage` with
   `.scroll > * + * { margin-top: var(--s4) }` (= **16 px**,
   `components.css:66`), and inside `.k3-stage` the `.k3-pet` carries
   `margin: 14px auto 0`. So the design's bubble→pet gap is **16 + 14 =
   30 px**. The code (`kid_home_view.dart:870`) emits a single
   `SizedBox(height: NestSpacing.gap14)` (**14 px**) between the bubble
   and the stage stack, and the `NestPetStage` slot starts immediately.
   Net effect, measured against the HTML: the Pip/nest slot top sits
   ~16 px higher than the design, and the whole section row → progress
   → quest-card block rides along 16 px high; the confetti plate lands
   at bubble-bottom + 18 instead of the designed +20 (its
   `Positioned(top: 4)` is now relative to the raised stack instead of
   the design's `+16` stage origin). Under the UI-verdict ±2 px rule
   the pet slot, section row, progress and cards all fail. Concrete
   fix: `bubble → const SizedBox(height: NestSpacing.s4) → Stack(…)`,
   and inside the Stack wrap the `NestPetStage` in
   `Padding(top: NestSpacing.gap14)` so the confetti's `top: 4`
   measures from the design's stage origin — the same structure K05
   uses (`.k5-pip { margin: 14px 0 2px }` lives on the Pip, not the
   stage, `quest_complete_view.dart:399-403`). Both the 16 px and the
   14 px then land exactly where the CSS puts them.

2. **minor** — `docs/ARCHITECTURE.md` route table (line ~104) still
   maps `/kid-home-done` to `KidHomeDoneView`; this branch renders
   `KidHomeView` there now. The doc is shared (orchestrator owns), so
   no edit happens on `screen/K03b` — worth one line in
   `SHARED_REQUEST.md` or a note to the loop.

Everything else passed: tokens only, shared components reused, BLoC
contract unchanged (one pure getter), no new events/states, loading/
failure/empty paths shared with K03, all-done bar matches the design's
`.kid-bar` paddings and reuses `NestHomeIndicator` inside the surface
per the BOTTOM EDGE owner rule, dark mode is token-driven.


## From 5_ui.md
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


## From 6_bugs.md
# 6 BUGS — K03b · Kid home all done (iteration 1)

Stage 6 adversarial pass over the all-done state (`/kid-home-done`, and the
same state of `/kid-home` after the last quest), on `SEED=kid_all_done`
(Maya 6/6, light + dark).

Suite: `app/test/features/kid_home/k03b_bugs_test.dart`
— **24 probes run green**, **7 parked proofs fail on demand**:

```
cd app && flutter test --timeout 120s test/features/kid_home/k03b_bugs_test.dart
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-1
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-2
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-3
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-4
cd app && flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-5
```

Cross-reference: 5_ui.md deviation 1 measured the same +15.3 px shift
(title 469.3→484.7, progress 513.0→528.7, card 1 545.0→560.7); this stage's
parked proofs pin the root causes and the exact target decomposition below.
The 04:52 ORCHESTRATOR_NOTES (D1 no shared edits, ROW ORDER, ROW META) are
mandatory for iteration 2; K03B-BUG-4/5 are their current-code violations.

Design rows used by the geometry proofs (measured from
`design/screens/light/K03b-kid-home-done.png` ÷3 with PIL):
bubble 125…191 (2 lines, 260 wide), pet box top 221 = bubble + 16
(`.scroll > * + *`) + 14 (`.k3-pet` margin), pet block 226
(`.k3-pet { height: 226px }`), chip 464…496 (centre 480), progress 513…529,
card 1 top 545, confetti plate 320×250 at stage top + 4 (= pet top − 10),
nest art 226×226 (SVG `meet` in the 260×226 img) → outline 190×104,
rim 310.4, bowl bottom 413.9, Pip box −16…134 from the pet top.

---

## K03B-BUG-1 — the bubble→pet gap is 14 px where the design is 30 px (Major, feature)

**Symptom.** The hero sits 16 px high (pet box top **205** vs the design
**221**) and, together with K03B-BUG-2, every row below it is **15.4 px low**:
chip centre **495.4** vs 480, progress top **528.4** vs 513, card 1 top
**560.4** vs 545 — a UI-verdict failure at every band.

**Cause.** The design has two stacked gaps between the bubble and the pet:
`.scroll > * + * { margin-top: var(--s4) }` (16) on `.k3-stage`, then
`.k3-pet { margin: 14px auto 0 }` (14, inside the flex stage so the two do not
collapse). `_AllDoneBody` uses a single `SizedBox(height: NestSpacing.gap14)`
(`kid_home_view.dart:870`) — it reproduces the 14 and drops the 16.

**Repro.**
`flutter test --run-skipped --plain-name K03B-BUG-1`
(`K03B-BUG-1: the bubble→pet gap is the design 30 px, not 14` → Actual 14.0;
`K03B-BUG-1: every row below the hero is on the design row` → pet 205 vs 221).

**Suggested fix.** After the bubble use `SizedBox(height: NestSpacing.s4)`
and put the `.k3-pet` margin back as 14 px of top padding around the pet/Stack
(or a single 30 px gap with the confetti moved to pet top − 10). Keep the
confetti plate at 320×250 (see K03B-BUG-2's interaction note). Do not touch
the not-done branch.

**Exact target decomposition (why “stage ≈ 248.6” is a trap).** The design's
bubble-bottom→title-box distance is exactly 272 px = 16 (`.scroll > * + *`) +
14 (`.k3-pet` margin) + 226 (`.k3-pet` height) + 16 (`.k3-sec` margin):
190.7 + 272 = 462.7 box top, and the measured title glyph top 469.3 is
462.7 + 6.6 (Nunito 28/34 cap offset — the app's own glyph sits 6.6 below its
box top today). 5_ui's “block ≈ 248.6” comes from reading the glyph top as a
box top under the current 14 px gap; hard-coding a 248.6 px stage under that
structure would land the title glyph at ≈ 475.9 — still ~6.6 px low. Fix the
gap and the block is the design's 226.

## K03B-BUG-2 — `PipNestFallback.explicitGeometry` ignores `slotHeight` (Major, shared/core)

**Symptom.** K03b's pet block is **257.4 px** instead of the design's **226**
(`.k3-pet { height: 226px }`), i.e. the shared `_explicitBleed` 31.4 is added
on top of the slot.

**Cause.** `app/lib/core/design_system/motion/pip_rive.dart`
(`explicitGeometry`, ~line 677): the `if (slotHeight != null)` branch sets
`stageH = effectiveSlotH`, but the final `return` recomputes
`stageH: nestTop + nestH + _explicitBleed` (38 + 188 + 31.4 = 257.4). The
`pipBottom` early-return correctly returns the variable, which is why K06
(206) is unaffected; K03 passes no `slotHeight` and is unaffected too. Only
K03b (slotHeight without pipBottom) is bitten.

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-2`
(`K03B-BUG-2: the slotHeight pet block is the design 226 px` →
unit `stageH` 257.4, widget height 257.4).

**Suggested fix (shared).** In `explicitGeometry`, return the `stageH`
variable in the final return as well (it already holds `effectiveSlotH` when
`slotHeight != null`). File as a SHARED_REQUEST: the screen may not edit
`core/**` (ORCHESTRATOR_NOTES 04:52 D1 explicitly forbids touching
`pip_rive.dart` from this branch — a feature-side height correction at the
call site is the alternative; the required block height and the exact row
decomposition are in K03B-BUG-1).

**Interaction.** Today the extra 31.4 px is what gives the confetti plate its
250 px of room, so the plate paints 320×250 (top 209 vs design 211.3). Fixing
this alone shrinks the plate to 284×222 — K03B-BUG-1/2/3 must land together,
and the plate needs an explicit 250 px height plus `Stack(clipBehavior:
Clip.none)` so the CSS overflow (14 px past the stage) is reproduced instead
of scale-down.

## K03B-BUG-3 — the nest art is K03's 236×188 box, not the design's 226×226 (Major, feature)

**Symptom.** The celebration nest is 8.4 px too wide and 17.3 px too flat:
bowl outline **198.6×86.2** vs the design **190.2×103.5**; rim **317.4** vs
310.4; bowl bottom **403.6** vs 413.9; Pip centre **285.6** vs 280.3.
A screenshot band check cannot pass this.

**Cause.** `_AllDoneBody` passes K03's transcribed numbers
(`nestWidth: 236, nestHeight: 188`, `BoxFit.fill`) but K03b's `.k3-pet` is
260×**226** tall, so the browser's SVG `meet` draws a **226×226** art
(letterboxed 17 px each side). K03's numbers paint K03's 236-tall design, not
this one.

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-3`
(`K03B-BUG-3: the nest art is the design 226×226 (outline 190×104)` →
width 236 vs 226).

**Suggested fix.** Add all-done-local constants `226/226` (do **not** change
`_kNestBoxWidth/_kNestBoxHeight` — `_KidPetStage` shares them and K03 must not
move): `nestWidth: 226, nestHeight: 226, fixedPipHeight: 152, slotHeight: 226`.
With K03B-BUG-1/2 fixed this lands the art at pet top 0, rim 310.5, bowl
bottom 414, feet 333.5 and Pip box −18.3…133.7 (design −16…134) — all within
2 px.

## K03B-BUG-4 — the done-row meta is missing “Mum said yes!” and the +N chip (Major, feature, mandated)

**Symptom.** `_QuestCard` renders `Done` for every `approved` row and never a
coin chip. The 04:52 ORCHESTRATOR_NOTES ROW META (and the K03b HTML) require:
waiting → “Waiting for Mum” (current app OK), approved-and-needed-approval →
“Mum said yes!”, done-and-no-approval → the `+N` coin chip. The
`kid_all_done` seed makes all six `done_pending`, so the UI-check seed hides
this; a real parent approval (or a no-approval quest) exposes it.

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-4`:
`…says “Mum said yes!”` (app shows `Done`) and
`…shows its +N coin chip` (app shows `Done`, no `+15`).

**Suggested fix.** Branch the meta on the completion status + the quest's
`needsApproval` flag (`app/lib/features/kid_home/data/kid_home_repository_impl.dart`
does not surface `needsApproval` on `KidQuest` yet — add it to the entity/model
in this feature and use it in `_QuestCard`). Keep K03's demo rows
(`Waiting for Mum` / `+10` / `+15`) unchanged and re-run K03's geometry pin.

## K03B-BUG-5 — the quest list is alphabetical, the owner rule says creation order (Major, feature, owner rule)

**Symptom.** The all-done list renders dishwasher, hoover, lay-the-table,
bins, reading, tidy; the design and the 04:52 ROW ORDER rule say creation
order: dishwasher, reading, bins, tidy, hoover, table. The repository re-sorts
by title (`kid_home_repository_impl.dart:74`).

**Repro.** `flutter test --run-skipped --plain-name K03B-BUG-5` — the card
titles list starts `['Empty the dishwasher', 'Hoover the stairs', …]` instead
of `[… 'Reading – 20 minutes', 'Put the bins out', …]`.

**Suggested fix.** Drop the title sort and keep `watchActiveQuests`' creation
order (`created_at`, then id); prove K03's demo rows still match the K03
design (its UI check pinned card 1 only, but the seed's first card is
dishwasher in both orders).

---

## Checked clean (probes kept green in the plain run)

| Area | Evidence |
|---|---|
| all-done truth table | empty/partial/`not_yet` → false; approved+pending → true (`allDone` probe) |
| live flip K03→K03b | completing the last two quests on `/kid-home` shows “All done!” + “6 of 6 done” + Visit Pip |
| live flip K03b→K03 | a completion flipped to `to_do` in the DB flips the screen back to “5 done today” + dock |
| period expiry | next London day: daily completions reset, weekly survive → “2 done today”, no all-done (anchor-shift probe); direct `countsForCurrentPeriod` probes for London midnight and Mon–Sun weeks |
| BST fall-back | 00:30 BST Sun 25 Oct counts at 04:00 GMT; not on Mon 26 Oct |
| 0 children | `/kid-home-done` → “Who’s playing?”, no bar |
| 0 quests | “No quests today”, never all-done |
| 1 quest | “1 of 1 done”, Visit Pip |
| 6 children | extra children don’t change Maya’s all-done state |
| long name + 9999 coins | “Maximilian-Alexander” + 9999 at 320 px / textScale 1.3, no overflow |
| money | 0 coins renders `0`; kid screens never show `£`; coins are ints end-to-end |
| rapid double tap | double-tapping Visit Pip lands on one `/pip`; cards/checks keep their K03 latches; lock latch K03-tested |
| deep link / back | `/kid-home-done` deep link renders the state; card → `/quest-detail` → back returns to the live all-done screen |
| restart | file-DB reopen keeps Maya 6/6 (all completions persist) |
| dark mode | all-done renders in dark; `leafInk`/`onAccent` pairs ≥ 4.5:1 on sky, leaf-tint and lilac |
| bottom edge (owner rule) | the bar’s surface reaches the physical edge in light and dark (34 px inset) |
| a11y actions | Visit Pip `hasAction(tap)` + `performAction(tap)` opens `/pip`; each done card is one tappable node; decorative checks expose no tap |
| mode guard | kid mode reaches `/kid-home-done`; `/approvals` still redirects to the gate |
| overflow | scrolling the whole all-done list at 320 px / 1.3 raises nothing |
| async/close | every pumped test ends with `disposeApp`; no pending-timer teardown failures |

## Observations (not findings)

- The bubble matches the design (260 wide, 2-line box, measured 65…325);
  the wrap point matches the design’s “You did everything today! Pip /
  is so proud.” within Flutter-vs-browser shaping tolerance. The design’s
  start alignment (line 2 at the left edge) is fixed on main by
  `shared/speech_align` (ORCHESTRATOR_NOTES 04:52 D2) — not this branch.
- The all-done state itself (getter, route, header, semantics, live flips,
  period expiry) held up under every edge probe; the bugs above are layout
  transcription errors in the new all-done body, one shared slot-height
  contract bug, and two mandated row-content/order rules the current code
  does not implement.

