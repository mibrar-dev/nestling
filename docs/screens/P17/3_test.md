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

VERDICT: FAIL
