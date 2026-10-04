# Fix list after iteration 1

## From 2_build.md
# P17 Parental gate — 2 build (integrate, iteration 1)

Stage 2 integration of the two parallel builders. Job was compile + green
suite only; no redesign, no simulator, no `flutter clean`, no interactive run.

## Summary of 2a (logic)

- Extended the existing per-feature contract only, no CONTRACT CHANGES:
  state `+entered`/`attempts`/`unlocked` (+`copyWith`/`props`, helpers
  `challenge`, `expectedLength`, `isComplete` where
  `isComplete = expectedLength > 0 && entered.length == expectedLength`);
  events `ParentalGateDigitEntered`, `ParentalGateDeletePressed`,
  `ParentalGateUnlockAcknowledged`; bloc handlers for append / auto-verify /
  clear-on-wrong / delete / acknowledge, all with the plan's guards.
- Repository untouched (existing `ParentalGateRepository` via Drift only).
- Tests: `parental_gate_bloc_test.dart` (17) + `parental_gate_repository_test.dart` (5).

## Summary of 2b (UI)

- `parental_gate_view.dart` rewritten from the scaffold to the full-bleed
  kid-mode gate: `Scaffold`(transparent) → `KidScope` → `Stack` of
  backdrop (`Hi {nickname}!` + `NestCoinPill` + `PipAvatar` 200, dimmed,
  `ExcludeSemantics`) / full-bleed `tokens.scrim` / centred `NestModal`
  (24 gutter, radius 32) containing `_LockTile` 52, `Grown-ups only` (h2),
  `Type the answer in numbers:`, repo-derived question (h3, maxLines 2),
  `_DigitsRow` 56×64 gap 12, `NestKeypad(kid: true)` in a 296 `FittedBox`
  slot, `Back to Pip` ghost (minHeight 56), caption.
- States: loading placeholders + leaf spinner; failure message + ghost
  `Try again`; disabled-gate pass-through (once).
- Listener: `unlocked` → `UnlockAcknowledged`, parent mode first
  (`AppModeController.selectMode(parent)` + `AppSession.setAppMode('parent')`
  + `refresh()`), then `pop()` else `go('/today')`; wrong answer announces
  `That wasn’t right — try again` (no danger styling).
- Tests: `parental_gate_view_test.dart` (9), `parental_gate_geometry_test.dart` (2),
  `parental_gate_states_test.dart` (5).

## Merge check — no breakage between the halves

The two halves did not collide: 2b was written against the exact contract 2a
reports, so there were **no** mismatched states/events, no import fixes, no
renamed members and no test conflicts to repair. Verified: the view consumes
only `state.challenge/expectedLength/entered/attempts/unlocked/status/items`
and adds only the three new events; the bloc never imports view code. Nothing
was changed by me in `lib/**` or `test/**` — the combined result is 2a + 2b as
handed over, and it is internally consistent (38/38 feature tests green).

## FIXES items

| Item | Status |
|---|---|
| `dart format .` whole app | DONE — `Formatted 489 files (0 changed)` (already clean) |
| `flutter analyze` whole app | DONE — `No issues found! (ran in 11.0s)` |
| `flutter test test/features/parental_gate` | DONE — `+38: All tests passed!` |
| `flutter test` (whole app) | **BLOCKED** — 41 failures; see below |
| Fix integration breakages in my scope | NONE FOUND — nothing to fix |
| Out-of-scope failures from the P17 view replacing the scaffold | FILED — `docs/screens/P17/SHARED_REQUEST.md` |

### Whole-suite failures — classified

Baseline measured by `git stash -u` (HEAD = main + the P17 wip merge, builders'
work removed) and compared failure-by-failure with the integrated tree:
**34 failing before, 41 after ⇒ exactly 7 new failures, all from this build**,
and 34 pre-existing and untouched by P17:

1. **7 new — caused by P17 replacing the v1 scaffold screen** (out of my edit
   scope, `app/test/features/kid_home/**`): K03 tests navigate to
   `/parental-gate` and assert the scaffold title `P17 Parental gate`, which
   the real gate (design copy `Grown-ups only`) no longer renders:
   `k03_bugs_test.dart` `performAction(tap) on the lock opens the gate`,
   `K03-BUG-9: double-tapping the lock stacks two gate routes`;
   `kid_home_view_test.dart` `K03 navigation lock opens the parental gate` and
   the four `K03 grown-ups lock (every kid state) …` cases. Failure text:
   `Expected: exactly one matching candidate / Actual:
   _TextWidgetFinder:<Found 0 widgets with text "P17 Parental gate": []>`.
   Fix belongs in the K03 tests (assert `Grown-ups only`), routed via
   `SHARED_REQUEST.md`. Re-adding the placeholder string to the view is not an
   option: it is not design copy and it breaks P17's own copy test.
2. **34 pre-existing on HEAD, other features' screens** (not P17, not mine to
   edit — no edits made to them): `kid_home` K03 layout matrix light/dark
   320/390/430 @1.0/1.3 overflow, K03 typography/shapes/copy pins, K03 bottom
   edge + a11y probes, `k03_bugs` edge-case probes; `approvals` P11 copy +
   semantics; `today` P08-B11 period scoping (both cases).

So the stage's "full suite passes" gate is not met — 41 red, 7 of them
introduced here (blocked on a cross-feature test the loop owns) and 34 already
red at HEAD. Analyze is clean and P17's own suite is fully green.

## Tails

`dart format .`

```
Formatted 489 files (0 changed) in 1.29 seconds.
```

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 11.0s)
```

`flutter test test/features/parental_gate`

```
00:05 +38: .../parental_gate_geometry_test.dart: modal frame and children match the spec — dark
00:05 +38: All tests passed!
```

`flutter test` (whole app)

```
00:56 +2414 ~1 -41: Some tests failed.

Failing tests:
  app/test/features/approvals/approvals_view_states_test.dart: P11 approvals — copy the child quote is announced next to the card summary
  app/test/features/approvals/approvals_view_states_test.dart: P11 approvals — copy the screen uses the design's exact characters
  app/test/features/approvals/approvals_view_states_test.dart: P11 approvals — semantics each card announces one summary label, buttons stay live
  app/test/features/approvals/approvals_view_test.dart: P11 approvals screen title, helper copy and the three seeded cards
  ... and 37 more
```

(`~1` is one pre-existing skip; 2414 passed.)

## Notes for the next stage

- No simulator was booted by this stage. The `Center`/`LayoutBuilder` wrapper
  above `NestModal` is where 5_ui adjusts a uniform vertical shift if the modal
  band does not match the design's `y ≈ 66…778`; everything inside the card is
  token-exact and asserted by `parental_gate_geometry_test.dart`.
- `presentation/widgets/parental_gate_placeholder_card.dart` is now unused
  (no references in `lib` or `test`). Left in place — deleting it buys nothing
  and is not this stage's call.


## From 3_test.md
# P17 Parental gate — 3_test (iteration 1)

Stage 3 for `/parental-gate` (feature `parental_gate`, kid mode). Tests only:
**no file under `app/lib/**` was touched** — every defect below is recorded,
not patched. No simulator was booted, installed on, screenshotted or driven
(SIMULATORS rule: only 5_ui may use E7D5555E-…).

Sources of truth used: `docs/screens/P17/1_plan.md`, `ORCHESTRATOR_NOTES.md`
(02:08 update — items 1–7 are mandatory), `4_review.md`, `5_ui.md`,
`6_bugs.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P17,
`docs/design/SPACING_SPEC.md` §7, and the design PNGs
(`design/screens/{light,dark}/P17-parental-gate.png`, ÷3) plus
`design/html-source/screens/P17-parental-gate.html`.

## 1. Tests added / extended

Suite in `app/test/features/parental_gate/` — **78 tests in the five stage-3
files** (38 before, 40 added or rewritten), plus the concurrent stage-6
`p17_bugs_test.dart` (8 green + 3 skip-marked proofs, not mine).

| File | Tests | Coverage |
|---|---|---|
| `parental_gate_bloc_test.dart` | 23 (was 17) | every event/state path: load → loading/loaded/failure, disabled gate, digit append, extra digits ignored, non-digit rejected, delete (incl. no-op on empty), correct answer → `unlocked`, wrong answer → cleared + `attempts`, acknowledge one-shot, **+ retry after failure (the `Try again` path)**, **+ digits/delete absorbed while unlocked**, **+ acknowledge without unlock emits nothing**, **+ two wrong answers count 2**, **+ live settings change re-emits `loaded` with an empty list**, **+ every 2…9 × 2…9 product has a spelled-out question and a 1–2 digit answer** |
| `parental_gate_repository_test.dart` | 11 (was 5) | `challengeFor` determinism/stability, the design fixture (7×6), the pinned demo day (3×9), **+ a one-digit product (2 Feb 2026 → 4)**, **+ title/detail copy + id**, **+ model JSON round trip**, gate switch on/off, **+ live re-emit on switch flip**, **+ missing settings row fails open**, **+ `Seed.empty` still enables the gate** |
| `parental_gate_geometry_test.dart` | 6 (was 2) | real-font geometry (`FontLoader` Inter/Nunito, the P04/`nest_balanced_text_test` pattern — this harness reproduces the 5_ui simulator numbers to ≤1 px): structural facts light + dark (card x24/w342/radius 32, lock 52 r16, digit boxes 56×64 gap 12 centred, **box count derived from the answer, not hard-coded to 2**, 11 keys of 72, cancel ≥56 full width), **+ the scrim barrier covers (0,0) → (390,844)**, **+ the barrier is painted above the kid backdrop**, **+ the ORCHESTRATOR_NOTES design pins** (items 2–6 + the item-1 backdrop header), **+ the keypad's HTML row/column pitch** |
| `parental_gate_states_test.dart` | 19 (was 5) | full matrix: light + dark × 320/390/430 × textScale 1.0/1.3 with no overflow and the card's 24 px gutters intact, **+ the app's 1.0–1.3 scaler clamp (2.0 renders as 1.3)**, **+ painted (transform-aware) kid tap targets ≥56 at 320/390/430**, **+ the failure state's `Try again` ≥44 and `Back to Pip` ≥56**, dark surface/scrim tokens, contrast (ink/ink-2 on surface ≥4.5, lilac on lilac-tint) |
| `parental_gate_view_test.dart` | 19 (was 9) | copy character-for-character with the HTML, **+ no v1 scaffold string**, **+ the question is spelled out (no digits) and letterSpacing 0 on every line with the bundled Nunito/Inter faces**, real pointer tap + semantics taps (fill left→right, delete, delete-on-empty), **+ filled vs empty digit-box styling from tokens**, **+ wrong entry clears and announces `That wasn’t right — try again` exactly once (curly ’ + em dash, captured off `SystemChannels.accessibility`)**, **+ a second wrong attempt announces again**, navigation: unlock → parent mode + `/today`; **+ unlock from a pushed gate**; `Back to Pip` popped **+ and unpushed**, semantics: all 11 keys + cancel expose `SemanticsAction.tap` and `isButton`, dialog label `Parental gate`, `Number pad`, `Answer, n of N entered`, **+ the dimmed backdrop stays out of the a11y tree while still rendering `Hi Maya!` / `120`**, states: loading spinner, failure + `Try again` **+ retry recovers to a working keypad**, disabled-gate pass-through, **+ `Seed.empty` (no child) fallback `Hi there!` + `0` coins and a fully usable gate** |

Robustness fixes to the pre-existing tests (test-side only):

- The geometry test asserted `hasLength(2)` digit boxes — true only when the
  day's product is two digits (products run 4…81). It now derives the count
  from `ParentalGateRepository.getItems()`.
- The view test computed "today's" challenge with `DateTime.now()` and built
  its wrong answer as `'${answer + 1}'.substring(0, len)` (2 chars for a
  99 answer ⇒ the test would silently stop exercising the reset). Both now
  read the challenge from the registered repository and use a same-length
  wrong entry. Nothing in the suite asserts real-wall-clock copy, so the files
  behave identically before and after the shared clock pin merges.
- Every widget test that awaits Drift uses `tester.runAsync` (a bare `await`
  on a query inside `testWidgets` hangs the fake-async zone).

## 2. Results

```
dart format .                                    → 0 changed (clean)
flutter analyze test/features/parental_gate/parental_gate_*.dart
                                                  → No issues found!
flutter test  (per file)
  parental_gate_bloc_test.dart         23 tests, 23 pass, 0 fail
  parental_gate_repository_test.dart   11 tests, 11 pass, 0 fail
  parental_gate_geometry_test.dart      6 tests,  4 pass, 2 fail   ← intentional pins (§3.1)
  parental_gate_states_test.dart       19 tests, 19 pass, 0 fail
  parental_gate_view_test.dart         19 tests, 18 pass, 1 fail   ← intentional pin (§3.2)
flutter test test/features/parental_gate/p17_bugs_test.dart   → +8 ~3: All tests passed!
flutter test test/features/parental_gate (whole folder)
                                              → +83 ~3 -3: Some tests failed.
flutter test (whole app)               → 01:33 +2459 ~4 -44: Some tests failed.
```

Whole-app `-44`: **3 are the deliberate pins in §3**; the other 41 are the
same pre-existing red set the build stage measured — 35 `kid_home` (K03,
including the 7 that assert the old scaffold title and are already in
`SHARED_REQUEST.md`), 4 `approvals` (P11) and 2 `today` (P08-B11 period
scoping). No new breakage was introduced by this stage — it changed only files
inside `app/test/features/parental_gate/`.

## 3. Bugs found

### 3.1 MAJOR (screen-local): a successful unlock never dismisses a pushed gate

**Where:** `app/lib/features/parental_gate/presentation/views/parental_gate_view.dart:36-49`
(`_unlock`, called from the `BlocListener` on `state.unlocked`).

**Failing test (the pin):**
`app/test/features/parental_gate/parental_gate_view_test.dart` →
`navigation › unlocking a pushed gate dismisses it and keeps the kid route`.

**Repro:** kid mode → `/kid-home` → tap the `Grown-ups` lock (K03 pushes
`/parental-gate`) → type the correct answer.
*Expected:* parent mode, the gate closed, the kid route showing.
*Actual:* `AppModeController.mode == AppMode.parent` and the declarative
location is `/kid-home`, **but the pushed `/parental-gate` route is still on
screen** (`pushedPath` = `/parental-gate`, `find.byType(NestModal)` finds 1)
and it never clears — verified stable after 6 × 100 ms of pump plus real-time
delays. The kid is left staring at the grown-ups gate in parent mode; typing
the answer again re-runs `_unlock` and changes nothing.

**Why (isolated with an A/B/C harness):** `_unlock` switches the app mode and
starts the async session write **before** popping:

```dart
GetIt.instance<AppModeController>().selectMode(AppMode.parent);        // :41
unawaited(session.setAppMode('parent').then((_) => session.refresh())); // :43
if (Navigator.of(context).canPop()) { context.pop(); }                  // :44-46
```

`AppSession` is part of the router's `refreshListenable`
(`app/lib/app/router.dart:80-82`), so when the write lands, the router
re-parses its match list while the imperative `push` is being popped and the
popped route comes back. Measured, same fixture:

| Sequence | Result |
|---|---|
| `selectMode(parent)` → `context.pop()` | gate dismissed ✔ |
| `selectMode(parent)` → session write → `context.pop()` (**shipped order**) | gate **kept** ✘ |
| `context.pop()` → `selectMode(parent)` → session write | gate dismissed ✔ |
| `selectMode(parent)` → session write, no pop | gate kept (expected) |

**Suggested fix (P17 owns this file):** pop first, then flip the mode and
persist it — or await `setAppMode` and only then pop. Do not flip the mode
while an imperative route is mid-pop.

**This corrects an earlier stage's record:** `6_bugs.md` lists
"pushed unlock — correct answer on a gate pushed from K03 → parent mode +
`/kid-home`, no error — **pass**". That probe
(`p17_bugs_test.dart:277-291`) only asserts `AppModeController.mode` and
`currentPath` (the *declarative* location, which is `/kid-home` either way) —
it never checks that the pushed route was dismissed. My test asserts
`pushedPath` and the absence of `NestModal`, which is what exposes the bug.

### 3.2 MAJOR (design fidelity): the card and keypad miss ORCHESTRATOR_NOTES 2–6

**Where:** `parental_gate_view.dart:100-273` (the `Center`/`LayoutBuilder`
layer) and, underneath it, the shared
`app/lib/core/design_system/components/nest_keypad.dart:39,44` (row gap
`NestSpacing.s4` = 16, column gap `NestSpacing.s6` = 24).

**Failing tests (the pins the orchestrator asked for):**
`parental_gate_geometry_test.dart` →
`ORCHESTRATOR_NOTES design pins … every band sits within ±2 px of the design PNG`
and `… the keypad follows the HTML grid gap (pitch 82)`.

**Measured at 390×844, light, textScale 1.0 (design → app), all values from
this harness and identical to the 5_ui simulator measurements:**

| Band | Design | App | Δ |
|---|---|---|---|
| card top | 66.0 | 53.0 | −13.0 |
| card bottom | 778.0 | 791.0 | +13.0 |
| card height | 712.0 | 738.0 | +26.0 |
| title "Grown-ups only" centre | 168.0 | 155.0 | −13.0 |
| instruction centre | 201.0 | 188.0 | −13.0 |
| question centre | 228.0 | 215.0 | −13.0 |
| answer boxes centre | 288.0 | 275.0 | −13.0 |
| keypad row 1 centre | 380.0 | 367.0 | −13.0 |
| keypad row 2 centre | 462.0 | 455.0 | −7.0 |
| keypad row 3 centre | 544.0 | 543.0 | −1.0 |
| keypad row 4 centre | 626.0 | 631.0 | +5.0 |
| "Back to Pip" centre | 702.0 | 715.0 | +13.0 |
| caption centre | 749.0 | 762.0 | +13.0 |
| dimmed backdrop header top | 55.0 | 13.0 | −42.0 |
| keypad row pitch | 82.0 | 88.0 | +6.0 |
| keypad column pitch | 88.0 | 96.0 | +8.0 |

**Why:** the card is vertically centred in the 844 px body while the design
anchors it at 66 (= (844 − 712) / 2 — centring only coincides with the design
because the card is 26 px too tall), and `NestKeypad`'s fixed 24/16 gaps make
it 26 px taller than the CSS grid (row pitch 82, column pitch 88 at this
width). The dimmed kid header sits at y 13 because the view renders no
`NestStatusBar` reserve, so the OS clock overlaps the avatar (5_ui deviation 2).

**Ownership:** the card anchoring, the status-bar reserve and the internal
vertical gaps are screen-local (fix in iteration 2, exactly as `5_ui` and
`ORCHESTRATOR_NOTES` prescribe). The keypad gaps are **shared** and match
neither P17 (88/82) nor K02 (82/82), so I filed a third entry in
`SHARED_REQUEST.md` with the measured pitches and the CSS-grid fix.

### 3.3 Minor observations (recorded, not fixed, not pinned)

1. **No escape while loading.** `_GateLoading` (`parental_gate_view.dart:475-504`)
   reserves 56 px for a button and renders none: during `initial`/`loading`
   the only way out is the system back gesture. The failure state has both
   `Try again` and `Back to Pip`, and the plan's loading design has no cancel,
   so this is a deliberate-but-incomplete choice; flagging it because the
   reserved 56 px suggests a button was intended.
2. **`Try again` is 44 px on a kid screen** (`parental_gate_view.dart:529-534`,
   plan-mandated `minHeight: 44`). DESIGN_SPEC §5 kid rules ask for ≥56; my
   tap-target test pins ≥44 as the plan specifies, so this is a plan/DS
   question rather than a test failure.
3. **Sticky `errorMessage`.** `ParentalGateState.copyWith` cannot clear a
   field, so the failure text survives a successful retry inside the state.
   Never rendered (the view reads it only while failing) — harmless, but it
   is why the retry bloc test matches status/items rather than the whole state.
4. **Parent-mode deep link + `Back to Pip` lands on `/kid-home`** (kid UI in
   parent mode), the same product question `6_bugs.md` observation 1/5 raises
   for the post-unlock pop. Not reachable from the product UI.
5. Dead code: `presentation/widgets/parental_gate_placeholder_card.dart` and
   `data/models/parental_gate_challenge_model.dart` (the model now has a
   round-trip test, the placeholder card has no references).

## 4. Method notes

- **Real fonts matter.** Without `FontLoader` the test font makes every glyph
  em-wide, the title and instruction wrap, and the card measures 806 px
  instead of 738 — a geometry suite built on that would have been fiction.
  With the bundled faces the harness matches the 5_ui device measurements
  within 1 px, so these pins are usable as regression gates.
- **Painted rects, not layout rects.** The keypad's `FittedBox(scaleDown)`
  shrinks the on-screen key at 320 px while `getSize` still reports 72, so the
  tap-target tests transform the rect (`getTransformTo`) — at 320 px the
  painted key is 56.4 px, still ≥56 but only just.
- **Semantics handles** must be disposed inside the test body, before
  `disposeApp`, not via `addTearDown` (the framework's leak check runs first).

## 5. Process note (not a finding)

While this stage ran, the loop's later P17 stages were executing in the same
worktree: `4_review.md`, `5_ui.md`, `6_bugs.md`, `ORCHESTRATOR_NOTES.md` and
`p17_bugs_test.dart` appeared mid-stage (their temporary `p17_probe_*` files
have since been removed by that stage). `ORCHESTRATOR_NOTES.md` did not exist
when this stage started; its items 1–7 were adopted as mandatory and §3.2
exists because of them. The bugs stage's `p17_bugs_test.dart` is green
(8 probes + 3 skip-marked proofs) and its 3 bugs (P17-BUG-1 router redirect
loop, filed in `SHARED_REQUEST.md`; P17-BUG-2 UTC-vs-London challenge day;
P17-BUG-3 stale entry after a challenge change) do not overlap §3 — except
that its "pushed unlock: pass" row is corrected by §3.1.

## 6. Verdict basis

Two major defects are proven by failing tests that were written to the
mandated acceptance conditions (ORCHESTRATOR_NOTES 2–6 and the ACCESSIBILITY
ACTIONS rule that a tap must change the real state — here the success tap does
not complete its navigation), so the stage cannot pass. Everything else in the
suite is green, `flutter analyze` is clean, and no screen code was patched.


## From 5_ui.md
# P17 Parental gate — 5_ui (iteration 1)

Route `/parental-gate`, mode kid, child maya, seed demo. Simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical, 1170×2532 physical; ÷3).
No code edited by this stage.

Shots:
- `docs/screens/P17/ui/app_light_1.png` (THEME=light)
- `docs/screens/P17/ui/app_dark_1.png` (THEME=dark)
- `docs/screens/P17/ui/cmp_light_1.png` / `cmp_dark_1.png` via `tools/screens/compare.py`

Mean diff:
- light: 7.86% (bands 0–7: 7.68 / 6.72 / 4.57 / 10.59 / 11.29 / 8.48 / 4.65 / 8.84; y-ranges 0-105 … 738-844)
- dark: 6.43% (bands: 3.21 / 6.51 / 4.14 / 9.91 / 10.63 / 8.08 / 4.34 / 4.54)
- Hot bands 3–4 (y 316–527, digits + keypad rows 1–2) peak at ~10–11% in both themes.

Measured y (logical px, physical ÷3; centre-column / dark-pixel histogram; modal edges = first/last row with >60% modal-surface run across middle 70% width):
- Modal top: design 66.0 / app 53.0 (Δ −13.0) — both themes identical
- Modal bottom: design 777.7 / app 790.7 (Δ +13.0) — both themes identical
- Modal left/width: design x24.0 w342.0 / app x24.0 w342.0 (Δ 0) — PASS
- Title “Grown-ups only” top: design 164.0 / app 151.0 (Δ −13.0)
- Instruction “Type the answer in numbers:” band: design ~160.0 / app ~147.0 (Δ −13)
- Question band top: design 225.0 / app 212.3 (Δ −12.7)
- Keypad row 1 top: design 344.0 / app 331.0 (Δ −13.0)
- Keypad row 2 top: design 426.0 / app 419.0 (Δ −7.0)
- Keypad row 3 top: design 508.0 / app 507.0 (Δ −1.0)
- Keypad row 4 top: design 590.3 / app 595.3 (Δ +5.0)
- Cancel “Back to Pip” top: design 696.3 / app 711.0 (Δ +14.7)
- Backdrop header “Hi Maya!”: design hidden behind scrim+modal (only ~10 px dimmed slivers peek above modal top); app fully visible band 18.3–37.7, overlapping the OS status time (01:49/01:50 glyphs over the “M” avatar)
- Caption follows cancel (+10 gap per CSS); inherits the ~+13…+15 bottom shift.

Non-findings (do NOT fix — orchestrator rules):
- Question copy “seven times six” (design) vs “four times nine” (app): DATA OVER MOCKS, challenge is deterministic per London day from the seeded DB. Do not hard-code design numbers.
- Digit boxes: design shows filled “4” + empty (example filled state); app initial state both empty with leaf caret in first box. Correct empty state, not a layout deviation.
- Status time 9:41 vs 01:49/01:50 and status glyph style: ignored per STATUS BAR rule.
- Home-indicator pill in design vs none in simctl screenshot: gallery mock only, ignored.
- Coin “120”, avatar “M” lilac, “Hi Maya!” copy: match DB/design.

What matches:
- Copy (title, instruction, “Back to Pip”, “This keeps settings and purchases safe.”) character-for-character with the HTML source.
- Side gutters x24/366 w342 exact in both themes; cards/bars aligned, no horizontal misalignment.
- Lock tile lilac tint, h2/h3/body-s/caption styles, leaf caret, kid key rings (light: ink ring + shadow; dark: white ring, no shadow), radii (modal 32, digits 16, keys circular), no overflow/clipping/ellipsis, dark-mode surfaces correct.
- BOTTOM EDGE owner rule: no bottom bar on this screen; scrim + KidScope hill run full-bleed to the physical edge in both themes. No coloured strip under a bar. PASS.
- Pip slot: Pip is fully covered by the modal in both design and app, so PipAvatar vs v1 SVG cannot be discriminated from these frames; backdrop header correctly shows Maya (M, lilac, 120). Geometry tests assert the 200 px PipAvatar.

Deviations (design value → app value + fix):

1. Modal frame shifted and stretched — FAIL (±2 px rule; uniform shift alone is FAIL).
   Design: top 66.0, bottom 777.7, height 711.7. App: top 53.0, bottom 790.7, height 737.7 (Δtop −13.0, Δbottom +13.0, +26 tall).
   Fix: anchor the modal layer as the design does (top-anchored sheet at y66 with 24 px side gutters, not vertically centred), and re-check internal gaps so total height returns to ~712. Likely the `Center`/`LayoutBuilder` wrapper noted in 2_build centres the card; replace with top-anchored positioning per `.modal`/`.gate` CSS.

2. Backdrop header exposed and colliding with the status bar — FAIL.
   Design: header row sits below the 47 px status-bar reserve and is almost fully covered + dimmed by the scrim (only slivers peek). App: full header (“M” + “Hi Maya!” + 120 pill) painted at y18–38, undimmed in light, overlapping the OS time (01:49 over “M”).
   Fix: reserve the status-bar height above the kid backdrop (backdrop starts below `NestStatusBar`, not under it) and ensure the full-bleed scrim dims the whole backdrop including the header.

3. Internal vertical rhythm drifts beyond ±2 px (consequence of 1, but each band independently fails).
   Title Δ −13.0, question Δ −12.7, keypad row 1 Δ −13.0, row 2 Δ −7.0, row 4 Δ +5.0, cancel Δ +14.7 (values above).
   Fix: with the modal frame fixed at top 66, restore CSS gaps exactly (title +12, instr +8, question +4, digits +16, keypad +16, cancel +12 with min-height 56, caption +10) and keypad geometry 72 keys / 24 col / 16 row; do not stretch gaps to fill height.

4. (Consequential, not separate fix) Band diffs 10–11% in y316–527 and 7–9% elsewhere are fully explained by 1–3 plus the expected question/digits state differences. No separate colour/radius/shadow deviation found at this pass; key rect sizes measure 72 tall in both (histogram row height 72.0), digit/box/key shapes match when overlaid modulo the shift.

Builder notes for iteration 2: fix modal anchoring + status-bar reserve + gaps per CSS; re-shoot light+dark and confirm top 66±2, bottom 778±2, title 164±2, question 225±2, row 1 344±2, cancel 696±2. Do not hard-code the design question/digits to reduce diff — DB values are correct.

