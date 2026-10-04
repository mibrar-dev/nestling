# P17 Parental gate — 3_test (iteration 3)

Stage 3 for `/parental-gate` (feature `parental_gate`, kid mode), third
iteration. Tests only: **no file under `app/lib/**` was touched** — every
defect below is recorded, not patched. No simulator was booted, installed on,
screenshotted or driven (SIMULATORS rule: only 5_ui may use E7D5555E-…).

**Headline:** P17's own suite is **fully green — 113 pass, 1 skip, 0 red**
(96 tests in the five stage-3 files + 17 in the stage-6 `p17_bugs_test.dart`;
the single skip is P17-BUG-1, the shared-router proof in
`SHARED_REQUEST.md` #2). Every finding this stage raised in iterations 1 and 2
is closed and stays closed under its own regression pin, the design is matched
band-for-band (independent re-measurement in §3: **every Δ0**), and **no new
defect was found this iteration**. The whole app is still red on **8 tests, all
in `app/test/features/kid_home/**`** — out of this screen's RULES §1 set, all
caused by P17's own copy replacing the v1 scaffold title (plus one missing AppBar
back button), each with a one-line fix already filed in `SHARED_REQUEST.md` #1.

Inputs: `ORCHESTRATOR_NOTES.md` (items 1–7 and the 07:13 keypad note — both
honoured, §4), `1_plan.md`, `2_build.md` / `2a` / `2b` (iteration 3), `FIXES_2.md`,
`4_review.md`, `5_ui.md`, `6_bugs.md`, `SHARED_REQUEST.md`, and this file's
iteration-1 and iteration-2 reports.

## 1. Iteration 3 fixed everything this stage had pinned — re-verified, not assumed

| Prior finding | Fix (iteration 3) | Test that proves it now |
|---|---|---|
| **it-2 §3.2** MAJOR: every band below the keypad 26 px low (shared `NestKeypad` 16 px row gap / 8 px padding all round vs the CSS grid) | the shared fix `9cac0c6` merged (`Expanded` cells, `gap: 10`, `padding: 8 24 0`) — **no local re-spacing**, per ORCHESTRATOR_NOTES 07:13 | `the bands below the keypad match the design` and `the keypad follows the HTML grid gap (pitch 82)` — **green**, card 66…778 h 712, rows 380/462/544/626, cancel 702, caption 749, column pitch 88 |
| **it-2 §3.3** MAJOR: `SizedBox(296) > FittedBox(scaleDown)` hands the keypad unbounded width, which the new `Expanded` grid cannot lay out (`RenderFlex … unbounded`) | call site made compatible: `LayoutBuilder` picks `NestKeypadFit.stretch` when the card content ≥ `NestKeypad.contentWidth` (rendered directly) and `shrinkWrap` inside a width-bounded `FittedBox` below that | `the keypad is never laid out under unbounded width` — **green**; plus **new** `shared keypad fit (CSS grid stretch vs shrink-wrapped)`: the `fit` property is asserted per width and its painted geometry with it |
| **it-2 §3.1** MINOR: the dimmed backdrop row used `CrossAxisAlignment.start`, so the greeting sat 5 px above the CSS `align-items: center` position | argument dropped; and the pin's own constant was **corrected**, not relaxed: `designBackdropHeaderTop` 55 now pins the *row* (the avatar) and a new `designBackdropGreetingTop` 60 pins the *centred* h1 line box | `the backdrop row centres its items like `.kb-top`` — **green** (greeting and pill centres == avatar centre) |
| 6_bugs observation 1: the attempt counter's high-water mark swallowed the first announcement after a challenge change | `_announcedChallengeId` re-bases `_announcedAttempts` when the live challenge id changes | **new this iteration**: `a new challenge announces its first wrong answer again` — **green** |
| it-2 §4.1: the anchored card needed a 10 px scroll at 390 × textScale 1.3 | the keypad grid is 26 px shorter (326 vs 352), so the card is 762 tall at 1.3 and fits the canvas | **new this iteration**: `390 × 1.3 fits the card, every control stays reachable` — **green** (`card bottom ≤ 844`) |
| 2b self-check: `_GateLoading` over-reserved the caption gap + line box, standing the loading card 28 px tall | placeholders now 22 + 4 + 24 + 16 + 64 + 16 + **326** + 12 + 56 | `the loading placeholders keep the loaded card height`, **tightened this iteration from ≤6 px to ≤0.5 px** — measured **712 vs 712, Δ0.00** — **green** |

## 2. Tests added / changed this iteration (6 new, 1 pin tightened, 1 harness fix)

| File | Tests | Change |
|---|---|---|
| `parental_gate_states_test.dart` | 23 → **26** | +`shared keypad fit (CSS grid stretch vs shrink-wrapped)`: 390 asserts `fit == stretch`, every key painted 72×72 and an 88 px column pitch; 320 asserts `fit == shrinkWrap` with painted keys still ≥56 and the `Digit 5` / `Delete` semantics intact; 430 asserts `stretch`. +`390 × 1.3 fits the card…` (replaces iteration 2's now-false "needs a scroll" claim). **Harness fix**: the file now loads the bundled Inter/Nunito with `FontLoader` — see §5, this changed real numbers |
| `parental_gate_view_test.dart` | 20 → **21** | +`a new challenge announces its first wrong answer again`: a `_SequenceRepository` swaps 7×6 → 3×9 mid-entry; the first wrong answer on **each** challenge is announced exactly once, the boxes reset, and a same-challenge re-emit does **not** announce again (no phantom repeat) |
| `parental_gate_geometry_test.dart` | 11 → **11** | the loading↔loaded pin tightened `≤6 px` → `≤0.5 px` after measuring Δ0.00 |
| `parental_gate_bloc_test.dart` / `parental_gate_repository_test.dart` | 25 / 13 | unchanged this iteration (the iteration-2 builders already extended them: challenge-swap reset, same-challenge keep, `clearError`, the London-day proofs) |

Everything else was re-run unchanged: the full matrix (light + dark × 320/390/430
× textScale 1.0/1.3, no overflow, 24 px gutters intact), every tap's navigation
target (unlock → `/today`; unlock from a pushed gate pops and dismisses; cancel
pushed and unpushed), all 13 interactive nodes' `SemanticsAction.tap` and their
real effects, painted ≥56 kid tap targets, `Seed.demo` / `Seed.empty`,
loading / failure / retry / disabled-gate, the letterSpacing-0 + bundled-face
copy checks, and the wrong-answer announcement captured off
`SystemChannels.accessibility`.

## 3. Independent re-measurement (a throwaway harness, not the pins)

I measured the frame myself instead of trusting the pins, with the bundled
faces loaded, 390×844 / light / textScale 1.0, then deleted the harness:

```
card           66.0 … 778.0   h 712.0   (design 66 … 778, 712)      Δ0
key size       72 × 72               (design 72)                    Δ0
key row centres 380 / 462 / 544 / 626 (design 380/462/544/626)      Δ0
row pitch      82.0                   (design 82 = 72 + gap 10)     Δ0
key lefts      71 / 159 / 247          (design 71/159/247)          Δ0
column pitch   88.0                   ((302 − 24×2 − 10×2)/3 + 10)  Δ0
```

Other widths (no design variant exists for these; the invariants are "fits,
usable, ≥56"):

| Width × scale | card | painted key | row pitch | col pitch | exception |
|---|---|---|---|---|---|
| 320 × 1.0 | 66…736 (670) | 58.8 | 67.0 | 67.0 | none |
| 320 × 1.3 | 66…797 (731) | 58.8 | 67.0 | 67.0 | none |
| 390 × 1.0 | 66…778 (712) | 72 | 82 | 88 | none |
| 390 × 1.3 | 66…828 (762) | 72 | 82 | 88 | none |
| 430 × 1.0 | 66…778 (712) | 72 | 82 | 101.3 | none |
| 430 × 1.3 | 66…805 (739) | 72 | 82 | 101.3 | none |

The card keeps its 712 px design height and its exact internal rhythm at 430 as
well (the CSS grid stretches, the row pitch does not), and the 320 px path
scales the shrink-wrapped 280 box down to 58.8 px keys — 2.8 px above the 56 px
kid minimum.

## 4. `ORCHESTRATOR_NOTES` compliance

- **Items 1–7 (02:08)** — all pinned and green: the scrim barrier covers
  (0,0) → (390,844) and is painted above the backdrop
  (`the scrim barrier covers (0,0) to the physical edge`,
  `the barrier is painted above the kid backdrop`); the card, title, question,
  answer boxes, keypad rows, cancel and footnote sit on the design's values at
  Δ0 (§3); the random question and typed digits stay DB-driven (every assertion
  derives the challenge from the registered repository, never hard-coded).
- **The 07:13 note** — the shared keypad fix was **not** re-spaced locally; the
  call site was adapted to it and the key centres were re-checked against the
  design afterwards, as instructed (§3, all Δ0).
- **KID BACKGROUND** — `kid background (shared KID BACKGROUND rule)` pins one
  `KidScope` covering 0,0…390,844 with **every** `SvgPicture` inside it (no local
  hills) in light and dark.
- **PIP** — `the dimmed backdrop shows the child's own Pip in the slot` asserts
  `PipAvatar(style: mochi, skin: sunny, stage: 3, accessory: none, size: 200)` at
  y 125…325 centred, i.e. the DB look and the design's slot. (The card covers it
  on screen, which is why 5_ui could not discriminate it.)
- **BOTTOM EDGE / ALIGNMENT** — no bottom bar on this screen; the barrier owns
  every edge; the card's 24 px gutters and its 20 px inner padding are pinned at
  all three widths, light and dark.
- **ACCESSIBILITY ACTIONS** — unchanged and green: `hasAction(SemanticsAction.tap)`
  on all 11 keys + cancel (+ retry in the failure state), each `performAction`
  changing real state (boxes fill/clear, the route changes, the mode changes).
- **CLOCK / DATA OVER MOCKS / COPY / FONTS / LETTER SPACING** — no
  `DateTime.now()`, no `google_fonts`, `letterSpacing == 0` on every line with
  the bundled Nunito/Inter faces, copy compared character-for-character with the
  HTML (including the curly `’` and em dash in the announcement).

## 5. Results

```
dart format .        → 528 files, 0 changed (nothing outside my scope to revert)
flutter analyze      → No issues found! (ran in 14.3s)
flutter test test/features/parental_gate
                    → 00:03 +113 ~1: All tests passed!   (1 skip = P17-BUG-1, request #2)
  per stage-3 file:  bloc 25 · repository 13 · geometry 11 · states 26 · view 21
flutter test (whole app) → 02:43 +2996 ~3 -8: Some tests failed.
```

The 8 whole-app reds, all in `app/test/features/kid_home/**` (P17 may not edit
them under RULES §1) and all filed in `SHARED_REQUEST.md` #1 with line numbers
and one-line fixes:

| Count | Test | Why it is red |
|---|---|---|
| 7 | `k03_bugs_test.dart` (×2), `kid_home_view_test.dart` (×5) | they assert the v1 scaffold title `P17 Parental gate` after tapping the lock; the real gate renders the design copy `Grown-ups only` |
| 1 | `k01_bugs_test.dart` › `rapid lock double tap pushes exactly one gate` | its own `pushedPath` assertion passes; it then calls `pageBack()` and finds no `CupertinoNavigationBarBackButton`, because the design has no AppBar (the gate's own `Back to Pip` is the affordance) |

Neither may be "fixed" in the view: the scaffold title is not design copy and an
AppBar back button would break the design and all eleven geometry pins.

## 6. Bugs found

**None this iteration.** No new defect in the screen, in the logic layer or in
the shared keypad's use of it: the iteration-3 changes (call-site `LayoutBuilder`,
the announcement re-base, the corrected pin constants, the placeholder sizes)
are all covered by passing tests, including the orderings that break guards
(challenge swap → announce, same-challenge re-emit → no announce, 320/430 → the
right `fit`, 1.3 → no jump).

## 7. Observations (recorded, not defects)

1. **The 320 px key has 2.8 px of headroom.** Painted 58.8 px against the 56 px
   kid minimum; the scaled key would drop under 56 below ≈306 px of screen
   width (`72 × (W − 88) / 280 ≥ 56`). 320 is the narrowest width the specs and
   the brief's matrix reference, so this is a margin note, not a failure.
2. **The states file was measuring with the fallback test font** until this
   iteration. Without `FontLoader` every glyph is em-wide, the title and
   instruction wrap early and the card measures ~947 px at 390 × 1.3 instead of
   762 — which is why the new "fits at 1.3" assertion failed at first. The file
   now loads the bundled faces, so its gutter, tap-target and card-fit numbers
   are real. (The bloc, repository and view files never measured geometry, so
   they were unaffected.)
3. **A gate left open across London midnight keeps its question** — the day key
   is the London day (P17-BUG-2, fixed) but `watchItems()` only re-emits when the
   `settings` row changes. Carried from `6_bugs.md`; low impact for a
   seconds-long interaction.
4. **No escape while loading** — `_GateLoading` reserves 56 px and renders no
   button, so the only way out during `initial`/`loading` is the system back
   gesture (the failure state has both buttons). Carried from iterations 1–2 and
   `6_bugs.md` observation 2; the plan's loading design has no cancel.
5. **`Try again` is 44 px on a kid screen** (plan-mandated; DESIGN_SPEC §5 asks
   ≥56). My tap-target test pins the plan's 44.
6. Dead code, deliberately kept by the builders (repo-wide v1 scaffold):
   `presentation/widgets/parental_gate_placeholder_card.dart` and
   `data/models/parental_gate_challenge_model.dart` (the model carries a
   round-trip test, so deleting it would delete that coverage).
7. **Process (not a finding):** the loop ran stage 6 concurrently again — it
   created and removed `p17_probe_iter3_test.dart` (a copy of the
   announcement test I had just written) while my whole-app run enumerated the
   directory, and its `p17_bugs_test.dart` is green with 1 skip-marked
   shared-router proof. Nothing of mine was touched by it.

## 8. Verdict

`dart format` clean, `flutter analyze` **No issues found**, **P17's own feature
suite 113/114 green with no failing test** (the one skip is the honest
skip-marked shared-router proof, `SHARED_REQUEST.md` #2), every bug this stage
recorded in iterations 1 and 2 closed with its regression pin still in place and
now green, the design matched band-for-band on independent measurement, the
mandatory `ORCHESTRATOR_NOTES` items honoured, and **no new bug found this
iteration**. The full suite is still red on 8 tests that all belong to
`kid_home` — outside this screen's RULES §1 set, recorded in §5 and already
filed with one-line fixes in `SHARED_REQUEST.md` #1, not counted against P17
(same reasoning as `docs/screens/P15/3_test.md` §7 on `main`). The brief's PASS
bar — "all tests pass and no bugs were found" — is met for this screen.

VERDICT: PASS
