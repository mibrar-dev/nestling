# Fix list after iteration 2

## From 2_build.md
# P17 Parental gate — 2 build (integrate, iteration 2)

Integration of the two iteration-2 builders. Scope: compile + green suite, no
redesign, no simulator, no `flutter clean`, no interactive run, no skipped or
weakened tests.

## Summary of 2a (logic)

- Contract unchanged from iteration 1 (same three events, same state fields and
  helpers) — so again no shape conflict with 2b. Two additive internals:
  `ParentalGateState.copyWith` gained optional `clearError: false` (PaywallState
  precedent, no call-site change) and `challengeFor(utc)` now reads the
  calendar day in the family zone (Europe/London) instead of UTC — P17-BUG-2.
- `onData` (P17-BUG-3): resets `entered`/`attempts`/`unlocked` when the live
  challenge id changes, keeps the half-typed entry on same-challenge re-emits,
  and clears a stale `errorMessage` on loading/loaded (3_test §3.3.3 sticky-error
  minor).
- Tests: `parental_gate_bloc_test.dart` 25, `parental_gate_repository_test.dart`
  13 (shared memory DB per 4_review finding 3, + BST London-day split proof),
  and the `p17_bugs_test.dart` `skip:`s on the BUG-2/BUG-3 proofs removed (both
  green now). P17-BUG-1 stays skip-marked — shared `router.dart`, request #2.

## Summary of 2b (UI)

- FIXES_1 §3.1 closed: `_unlock` now pops **before** flipping `AppModeController`,
  because flipping the mode mid-pop made the router's refreshListenable re-parse
  and resurrect `/parental-gate`. The root deep-link branch keeps the old order
  (nothing to pop, redirect must not re-fire).
- ORCHESTRATOR_NOTES addressed: card anchored at the design's top **66** instead
  of centred (the uniform-shift failure), `NestStatusBar` reserve added as the
  first child of the dimmed backdrop so the header sits below the OS status bar,
  CSS vertical rhythm restored (lock→12→title→8→instr→4→question→16→digits→16
  →keypad→12→cancel→10→caption→20), loading question placeholder resized to the
  h3 line box (no jump), leaf caret on every empty box per `.digit.empty::after`.
- Keypad pitch: **not** fixed — shared `NestKeypad` hard-codes 24/16 gaps where
  the CSS grid is `gap:10` + `padding:8 24 0`. Filed as SHARED_REQUEST #3.

## Merge check — no integration breakage

No mismatched BLoC states/events, no import fixes, no renamed members, no test
collisions. 2b consumed exactly the iteration-1 contract that 2a extended
additively. The two halves needed no reconciliation.

## FIXES items

| Item | Status |
|---|---|
| `dart format .` | DONE — `517 files (1 changed)`: the one change was an unrelated shared file (`test/design_system/list_row_trailing_test.dart`, unformatted on `main`), **reverted** — RULES §1. My scope: `Formatted 18 files (0 changed)` |
| `flutter analyze` (whole app) | DONE — `No issues found! (ran in 4.0s)` |
| `parental_gate` suite | 90 pass · 1 skip (shared-router proof, request #2) · **2 red** |
| `flutter test` (whole app) | **NOT GREEN** — `+2811 ~2 -9: Some tests failed.` |
| Integration fixes in scope | NONE FOUND — nothing to fix |
| 2 reds in `parental_gate_geometry_test.dart` | BLOCKED on shared core — marked `TODO(P17)` in code, request #3 |
| 7 reds in `kid_home` (K03) | OUT OF SCOPE — request #1, unfixed |

Iteration 1 had 41 reds; this merge of `main` cleared the 34 pre-existing ones
(K03 layout matrix, P11 approvals copy/semantics, P08-B11). **9 remain: 7 + 2.**

### The 2 reds in my own suite — why I could not fix them

Both are the ORCHESTRATOR_NOTES item 11 pins that 2b added, and both fail on the
keypad alone:

```
card height: app 738.0 vs design 712.0 (Δ26.0)
keypad row 2 centre: app 468.0 vs design 462.0 (Δ6.0)   ← already +6 inside the keypad
keypad row 3 centre: app 556.0 vs design 544.0 (Δ12.0)
keypad row 4 centre: app 644.0 vs design 626.0 (Δ18.0)
"Back to Pip" centre: app 728.0 vs design 702.0 (Δ26.0)
caption centre: app 775.0 vs design 749.0 (Δ26.0)
Expected: 82.0 (±0.5) / Actual: <88.0>
```

The card top is now correct (66) and keypad row 1 matches, so the whole Δ26 is
the shared component: `nest_keypad.dart` uses `SizedBox(s4)`=16 row gaps and
`EdgeInsets.all(s2)` (8 all round) ⇒ 352 tall, where the CSS grid
(`gap:10`, `padding:8 24 0`) gives 326. **No call-site change can fix it** —
row 2's centre is already 6 px low inside `NestKeypad`, so nothing P17 does
around it moves that row, and the alternative (a local keypad) is forbidden by
plan §g and by "never re-implement components". The fix is in
`app/lib/core/**`, which RULES §1 puts off-limits to me.

I did **not** skip or relax those two pins — the red is the honest signal the
orchestrator needs. Per RULES §2 I recorded the block in code as `TODO(P17)` at
the `NestKeypad` call site and refreshed request #3 with the exact numbers,
the reasoning, and the concrete patch (three `Expanded` columns with the 72 px
key centred, row gap `NestSpacing.gap10`, `padding: EdgeInsets.only(top: 8)`),
which also fixes K02's pitch.

### The 7 reds outside my scope

`kid_home` K03 tests navigate to `/parental-gate` and assert the v1 scaffold
title `P17 Parental gate`; the real gate renders design copy `Grown-ups only`.
Failure: `Found 0 widgets with text "P17 Parental gate": []`. Still present after
the `main` merge (`k03_bugs_test.dart:1059,1531`;
`kid_home_view_test.dart:1243,1259,1275,1290,1989`). Those files are outside
RULES §1 for P17; the one-line fix each is `expect(find.text('Grown-ups only'),
findsOneWidget);`. Re-adding the scaffold string to the view is not an option —
it is not design copy and it would fail P17's own copy test. Request #1 updated
with the live line numbers and status.

## Change I made this stage

One, comment-only, in `parental_gate_view.dart`: the `TODO(P17)` block-quote at
the `NestKeypad` call site recording the shared-component gap conflict and
pointing at request #3 — the RULES §2 mechanism for building against the
foundation while blocked. No behaviour, no layout, no copy change. I also
reverted `dart format .`'s edit of the shared
`test/design_system/list_row_trailing_test.dart` so this stage touches nothing
outside `app/lib|test/features/parental_gate/**` and `docs/screens/P17/**`.

## Tails

`dart format .` → `Formatted 517 files (1 changed) in 3.62 seconds.` (that 1 was
the unrelated shared test; reverted). My scope:
`Formatted 18 files (0 changed) in 0.13 seconds.`

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 4.0s)
```

`flutter test test/features/parental_gate`

```
00:05 +90 ~1 -2: .../parental_gate_view_test.dart: states Seed.empty: no child, but the gate still works
00:05 +90 ~1 -2: Some tests failed.
```

`flutter test` (whole app)

```
01:33 +2811 ~2 -9: Some tests failed.

Failing tests:
  app/test/features/kid_home/k03_bugs_test.dart: K03-BUG-9: double-tapping the lock stacks two gate routes
  app/test/features/kid_home/k03_bugs_test.dart: performAction(tap) on the lock opens the gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) failure state: the lock still opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) loaded home: the lock opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) loading state: the lock is reachable and opens the gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) no active child: the lock still opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 navigation lock opens the parental gate
  app/test/features/parental_gate/parental_gate_geometry_test.dart: ORCHESTRATOR_NOTES design pins (390×844, light, textScale 1.0) every band sits within ±2 px of the design PNG
  app/test/features/parental_gate/parental_gate_geometry_test.dart: ORCHESTRATOR_NOTES design pins (390×844, light, textScale 1.0) the keypad follows the HTML grid gap (pitch 82)
```

## For the orchestrator

Two shared changes clear the whole suite — no P17 product code is needed for
either:
1. `nest_keypad.dart`: CSS-grid gaps (request #3) → the 2 P17 design pins go
   green and the card returns to 712.
2. K03 tests: assert `Grown-ups only` instead of the scaffold title
   (request #1) → the 7 kid_home reds go green.


## From 3_test.md
# P17 Parental gate — 3_test (iteration 2)

Stage 3 for `/parental-gate` (feature `parental_gate`, kid mode), second
iteration. Tests only: **no file under `app/lib/**` was touched** — every
defect below is recorded, not patched. No simulator was booted, installed on,
screenshotted or driven (SIMULATORS rule: only 5_ui may use E7D5555E-…).

Inputs: `ORCHESTRATOR_NOTES.md` (mandatory, unchanged since iteration 1),
`1_plan.md`, `2_build.md` / `2b_build_ui.md` (iteration 2), `FIXES_1.md`,
`4_review.md`, `5_ui.md`, `6_bugs.md`, `SHARED_REQUEST.md`, and my own
iteration-1 report (the bugs it found are listed in §4 with their status).

## 1. What iteration 1 bought, and what this iteration added

Iteration 1 of this stage left 3 red pins and 78 tests. The iteration-2
builders closed the two majors; this iteration re-verified every one of those
closures with a test that would have caught the original defect, and added
coverage for the behaviour iteration 2 introduced or changed.

### 1.1 Re-verification of the iteration-1 findings (all green now)

| Iteration-1 finding | Fix (iteration 2) | Test that now proves it |
|---|---|---|
| §3.1 MAJOR: a successful unlock never dismissed a pushed gate (`_unlock` flipped the mode and started the async session write before popping) | pop first, then rotate to parent mode | `parental_gate_view_test.dart` → `navigation › unlocking a pushed gate dismisses it and keeps the kid route` (asserts `pushedPath == '/kid-home'` **and** `find.byType(NestModal)` finds nothing) — **green** |
| §3.2 card/geometry drift above the keypad (card 53…791 instead of 66…778) | card anchored at the design top 66 | `parental_gate_geometry_test.dart` → `the card anchor and every band above the keypad match` — **green** (card top/left/width, lock tile 90…142, title/instruction/question centres, digits 256…320, keypad slot 336, keypad row 1, status-bar reserve, header top 55) |
| §3.2 dimmed backdrop header under the OS clock (design 55, app 13) | `NestStatusBar` reserve added above `.kb-top` | same test — `dimmed backdrop header top: 55` — **green** |
| §3.3.3 sticky `errorMessage` after a retry | `copyWith(clearError: true)` on loading/loaded | `parental_gate_bloc_test.dart` → `a second LoadRequested recovers from failure` (now asserts `errorMessage == null` on both states) — **green** |
| 6_bugs P17-BUG-2 (challenge keyed to the UTC day) | `challengeFor` reads the family-zone (London) day | `parental_gate_repository_test.dart` → `the challenge follows the Europe/London day, not UTC`, `one UTC date can span two London challenge days` — **green** |
| 6_bugs P17-BUG-3 (stale typed entry after a challenge change) | `onData` resets `entered`/`attempts`/`unlocked` on a challenge-id change, keeps them on a same-challenge re-emit | `parental_gate_bloc_test.dart` → `a new challenge resets the typed entry and attempts (P17-BUG-3)`, `a same-challenge re-emit keeps the typed entry` — **green** |
| 4_review finding 4 (caret only on the next box) | caret now paints on every empty box (`.digit.empty::after`) | **new this iteration**: `parental_gate_view_test.dart` → `every empty box carries the leaf caret (CSS ::after)` — **green** |
| 4_review finding 5 (loading placeholder heights) | placeholders resized to the real line boxes | **new this iteration**: `parental_gate_geometry_test.dart` → `the loading placeholders keep the loaded card height` (loaded 738 vs loading 734 ⇒ ≤6 px) — **green** |
| 5_ui / PIP rule (the card hides the Pip slot, so it was unverified) | unchanged | **new this iteration**: `the dimmed backdrop shows the child's own Pip in the slot` — `PipAvatar(style: mochi, skin: sunny, stage: 3, accessory: none, size: 200)` at y 125…325, centred — **green** |
| KID BACKGROUND rule (new in this iteration's brief) | shared `KidScope` + `kid_meadow.dart` | **new this iteration**: `parental_gate_states_test.dart` → `kid background (shared KID BACKGROUND rule)` — light + dark: one `KidScope` covering 0,0…390,844 and **every** `SvgPicture` on the screen inside it (no locally painted hills) — **green** |

### 1.2 Tests added this iteration

| File | Tests | Added this iteration |
|---|---|---|
| `parental_gate_geometry_test.dart` | 11 (was 6) | **split the design pins** into `the card anchor and every band above the keypad match` (green — everything P17 owns) and `the bands below the keypad match the design` (red — the shared component), so the orchestrator gets a clean signal instead of one red list mixing both; `the backdrop row centres its items like .kb-top` (new, red — §3.1); `the dimmed backdrop shows the child's own Pip in the slot` (new, green); `the loading placeholders keep the loaded card height` (new, green); `the keypad is never laid out under unbounded width` (new, red — §3.3, the merge-readiness guard for `shared/keypad_grid`); the anchor pins now also assert the CSS **gaps** (lock→title 12, question→instruction 4) and the keypad slot top (336), not just the resulting centres |
| `parental_gate_view_test.dart` | 20 (was 19) | `every empty box carries the leaf caret (CSS ::after)` — caret count == number of empty boxes, colour `tokens.leaf`, radius 2, and one fewer after each digit |
| `parental_gate_states_test.dart` | 23 (was 19) | `kid background (shared KID BACKGROUND rule)` × light/dark, `the scrim dims the whole kid screen down to the edge`, `390 × 1.3 scrolls the card instead of clipping it` |

Everything else in the five stage-3 files was re-run unchanged: 25 bloc tests,
13 repository tests, 23 states tests, 20 view tests — the full matrix
(light + dark × 320/390/430 × textScale 1.0/1.3, no overflow), every tap's
navigation target, all semantics labels and `SemanticsAction.tap` activations,
painted ≥56 kid tap targets, `Seed.demo` / `Seed.empty`, loading / failure /
retry / disabled-gate states, and the real-font (`FontLoader`) geometry harness
that reproduces the 5_ui simulator measurements to ≤1 px.

## 2. Results

```
dart format .   → 517 files, 1 changed — `test/design_system/list_row_trailing_test.dart`
                  (a shared file unformatted on main, outside RULES §1): REVERTED,
                  same as the iteration-2 build stage. My scope: 0 changed.
flutter analyze                                      → No issues found! (ran in 4.1s)
flutter test  (per file, stage-3 files)
  parental_gate_bloc_test.dart         25 tests, 25 pass, 0 fail
  parental_gate_repository_test.dart   13 tests, 13 pass, 0 fail
  parental_gate_geometry_test.dart     11 tests,  7 pass, 4 fail   ← §3.1 + §3.2 (carried) + §3.3
  parental_gate_states_test.dart       23 tests, 23 pass, 0 fail
  parental_gate_view_test.dart         20 tests, 20 pass, 0 fail
flutter test test/features/parental_gate (whole folder)
                                          → 00:03 +101 ~2 -4: Some tests failed.
flutter test (whole app)               → 01:53 +2822 ~2 -11: Some tests failed.
```

Whole-app `-11`: 3 of the pins in §3 (the fourth, §3.3, was added after that
run), 7 are the out-of-scope K03 tests that assert the v1 scaffold title
(`SHARED_REQUEST.md` #1 — unchanged from iteration 1), and 1 was a transient
load error for
`p17_bugs_test.dart`'s sibling `p17_probe_iter2_test.dart`, a scratch file the
concurrent stage-6 agent created and deleted while the run enumerated the
directory (it is not in the tree; process noise, not a finding).

## 3. Bugs found

### 3.0 MANDATORY `ORCHESTRATOR_NOTES` 07:13 re-check — done, and it found a merge blocker

The note (07:13) says the keypad pitch fix is landing on `shared/keypad_grid`,
must not be re-spaced locally, and that the key centres are to be re-checked
once `main` carries it. State of the tree at this stage:

```
git log --oneline main -1        → 7d37756 Shared brief: keypad grid
git log --oneline main -3        → includes 9cac0c6 Merge shared/keypad_grid
git rev-list --count HEAD..main  → 16        (the merge is not in this worktree yet)
```

`main`'s new component is exactly the contract my pins encode — `Expanded`
cells (CSS `repeat(3,1fr)`), row gap `NestSpacing.gap10` (10 ⇒ row pitch 82),
`padding: EdgeInsets.only(top: 8, left: 24, right: 24)`, `NestKeypadFit.stretch`
as the **default**, and a `shrinkWrap` mode at
`contentWidth = 3×72 + 2×10 + 2×24 = 280`. So once `main` merges, my two
keypad pins (row pitch 82, column pitch 88) are expected to go green with **no
P17 call-site change** — and no local re-spacing was done.

But the re-check surfaced a blocker in the call site — see §3.3.

### 3.1 MINOR (new, screen-local): the dimmed backdrop row does not centre its items

**Where:** `app/lib/features/parental_gate/presentation/views/parental_gate_view.dart:365`
(`_GateBackdropBody`'s `Row`, `crossAxisAlignment: CrossAxisAlignment.start`).

**Failing test:** `parental_gate_geometry_test.dart` →
`ORCHESTRATOR_NOTES design pins … the backdrop row centres its items like `.kb-top``.

**Repro:** `/parental-gate`, kid mode, `Seed.demo`, 390×844.
`.kb-top { display:flex; align-items:center; gap:12px; padding-top:8px }`
under the 47 px status bar ⇒ the row is y 55…99 (the 44 px avatar sets the
cross size), the `h1` greeting (28/34) centres at 60…94 and the 36 px coin pill
at 59…95. The app renders 55…99 / **55…89** / **55…91**: the row was given
`crossAxisAlignment: CrossAxisAlignment.start` (added in iteration 2 while the
status-bar reserve went in), so the greeting sits 5 px high and the pill 4 px
high against the avatar.

**Severity: minor.** It is dimmed scenery under the scrim and the card covers
everything below y 66, so only an 11 px sliver of the row is ever visible; the
offset changes how much of the glyph tops peek out. It is nonetheless a
measurable CSS-truth deviation and the ALIGNMENT rule asks for exact edges, so
it is pinned.

**Suggested fix (one line):** drop the `crossAxisAlignment` argument — the
`Row` default is `CrossAxisAlignment.center`, which is what the CSS says.

### 3.2 MAJOR (carried, shared, blocked on core): everything below the keypad is 26 px off

Unchanged from iteration 1 §3.2 and now isolated by its own test
(`the bands below the keypad match the design` + `the keypad follows the HTML
grid gap (pitch 82)`), measured at 390×844 / light / textScale 1.0:

| Band | Design | App | Δ |
|---|---|---|---|
| card height | 712.0 | 738.0 | +26.0 |
| card bottom | 778.0 | 804.0 | +26.0 |
| keypad row 2 centre | 462.0 | 468.0 | +6.0 |
| keypad row 3 centre | 544.0 | 556.0 | +12.0 |
| keypad row 4 centre | 626.0 | 644.0 | +18.0 |
| "Back to Pip" centre | 702.0 | 728.0 | +26.0 |
| caption centre | 749.0 | 775.0 | +26.0 |
| keypad row pitch | 82.0 | 88.0 | +6.0 |
| keypad column pitch | 88.0 | 96.0 | +8.0 |

**Everything above the keypad is now exact** (card top 66, lock tile 90…142,
title centre 168, instruction centre 201, question centre 228, answer boxes
centre 288 at x 133/201, keypad slot top 336, keypad row 1 centre 380, header
top 55) — the iteration-2 fixes hold. The residual Δ26 is one shared component:
`NestKeypad` (`app/lib/core/design_system/components/nest_keypad.dart:33-52`)
hard-codes a 16 px row gap and `EdgeInsets.all(8)`, so it renders 352 tall
against the CSS grid's 326, and each row lands +6 low. P17 cannot fix it under
RULES §1 and must not fork a local keypad; it is filed as
`SHARED_REQUEST.md` #3 with the concrete patch (three `Expanded` columns with
the 72 px key centred, row gap `NestSpacing.gap10`, `padding: EdgeInsets.only(top: 8)`),
which also lands K02's pitch. A `TODO(P17)` marks the call site — and since
`main` now carries the fix, `SHARED_REQUEST.md` #3 can be closed by the
orchestrator once the merge lands (see §3.3 for what P17 must do at the same
time).

### 3.3 MAJOR (screen-local, merge blocker): the FittedBox wrapper will throw once the shared keypad lands

**Where:** `app/lib/features/parental_gate/presentation/views/parental_gate_view.dart:219-224`
(`SizedBox(width: 296, child: FittedBox(fit: BoxFit.scaleDown, child: NestKeypad(kid: true, …)))`).

**Failing test (the guard):** `parental_gate_geometry_test.dart` →
`ORCHESTRATOR_NOTES design pins … the keypad is never laid out under unbounded width`.

**Repro:** merge `main` (which carries `9cac0c6 Merge shared/keypad_grid`) and
open `/parental-gate`. The new `NestKeypad` reproduces CSS
`grid-template-columns: repeat(3, 1fr)` with `Expanded` cells, and
`FittedBox` lays its child out with **unbounded** constraints — so the first
frame throws:

```
RenderFlex children have non-zero flex but incoming width constraints are unbounded.
  Row ← Column ← Padding ← FittedBox ← SizedBox ← … (constraints: BoxConstraints(unconstrained))
```

Verified with a minimal probe of the new component's structure (an
`Expanded`-based grid, throwaway harness, since the component is not in this
worktree yet):

| Wrapper | Result |
|---|---|
| **A.** `SizedBox(296) > FittedBox(scaleDown) > 1fr grid` (**today's call site**) | 8 layout exceptions — `RenderFlex … unbounded` |
| **B.** `SizedBox(232) > FittedBox(scaleDown) > SizedBox(width: 280) > shrinkWrap grid` | no exception; painted key 72 × 232/280 = **59.7 px** ≥ 56 |
| **C.** `SizedBox(302) > 1fr grid` (no FittedBox, the design width) | no exception; columns (302 − 48)/3 = 78 ⇒ **88 px** column pitch, exactly the design's 71/159/247 |

Today's wrapper is fine with the OLD shared component (fixed-size children, no
flex) — that is why the suite is green on this side of the merge — which is
exactly the trap: the crash only appears once `main` lands.

**Suggested fix (P17 owns this call site; no component change, no local
re-spacing):**
- at the design width, drop the `FittedBox` and render the keypad directly in
  the card's 302 px content box — the CSS `.keypad` is a block-level grid that
  fills its parent, so the wrapper is redundant (pattern C above);
- for narrower cards (320 px ⇒ 232 px of content, where 72 px keys no longer fit
  three-across), keep the scale-down but hand the keypad an explicit width:
  `FittedBox(fit: BoxFit.scaleDown, child: SizedBox(width: 280,
  child: NestKeypad(kid: true, fit: NestKeypadFit.shrinkWrap)))` — pattern B,
  which keeps the painted key at 59.7 px, above the 56 px kid minimum my
  tap-target matrix asserts.

A `LayoutBuilder` (or `NestKeypadFit` chosen by available width) picks between
the two. Both patterns are already covered by tests: the 320/390/430 × 1.0/1.3
matrix catches any layout exception, `the keypad follows the HTML grid gap`
catches the pitch, and `every keypad key keeps a ≥56 px rect at N px` (states
file) catches the scale regression.

## 4. Observations (recorded, not pinned, not fixed)

1. **The card needs a 10 px scroll at 390 × textScale 1.3.** With the card
   anchored at 66 the slot below it is 778 px, while the card is 788 px at the
   maximum supported scale, so `SingleChildScrollView` scrolls and the caption
   starts 10 px below the fold (measured: card 66…854, no overflow exception,
   both the cancel and the caption still in the tree). The plan's §(e) fallback
   is "modal scrolls internally", so this is conformant — but before the anchor
   the card fitted at 1.3, so it is a small trade the iteration made to fix a
   worse problem. Pinned as behaviour by
   `390 × 1.3 scrolls the card instead of clipping it`.
2. **The anchor is a magic number.** `EdgeInsets.fromLTRB(NestSpacing.s6, 66, …)`
   and `minHeight: constraints.maxHeight - 66` in
   `parental_gate_view.dart:116-126` hard-code 66, which is really
   `(844 − 712) / 2` derived from the design's card height. It is the one place
   in the screen where a size is not a token; worth a named constant (or
   computing it from the card's content height) if the design's card height ever
   changes.
3. **The loading state still has no `Back to Pip`.** `_GateLoading` reserves 56
   px and renders no button, so the only way out during `initial`/`loading` is
   the system back gesture. Carried from iteration 1 and from `6_bugs.md`
   observation 2; the plan's loading design has no cancel, and Drift's settings
   stream either emits promptly or errors into the failure state (which has both
   buttons).
4. **`Try again` is 44 px on a kid screen** (plan-mandated `minHeight: 44`;
   DESIGN_SPEC §5 kid rules ask ≥56). My tap-target test pins the plan's 44.
5. **A gate left open across London midnight keeps its question.** The day key
   is now the London day (P17-BUG-2 fixed), but `watchItems()` only re-emits
   when the `settings` row changes, so nothing re-keys the question at midnight.
   Same reasoning as `6_bugs.md` P17-BUG-2's last sentence; low impact (a gate
   is a seconds-long interaction).
6. Dead code: `presentation/widgets/parental_gate_placeholder_card.dart` and
   `data/models/parental_gate_challenge_model.dart` (both unreferenced; the
   model has a round-trip test so removing it would delete that coverage too).

## 5. Method notes carried from iteration 1

- **Real fonts are mandatory for geometry.** Without `FontLoader` the test font
  makes every glyph em-wide and the card measures 806 px instead of 738 — a
  geometry suite built on that would be fiction. With the bundled Inter/Nunito
  the harness matches the 5_ui device measurements to ≤1 px, which is why these
  pins are usable as regression gates.
- **Painted rects, not layout rects.** `FittedBox(scaleDown)` shrinks the
  on-screen key at 320 px while `getSize` still reports 72, so tap-target and
  pitch checks transform the rect (`getTransformTo`); at 320 px the painted key
  is 56.4 px — still ≥56, but only just.
- **Drift-aware assertions.** Design pins collect every band that misses by
  more than ±2 px and fail once with the whole list, so one run reports all of
  them.
- **Never hard-code the day.** The challenge comes from the registered
  `ParentalGateRepository` (via `tester.runAsync` — a bare `await` on a Drift
  query inside `testWidgets` hangs the fake-async zone), and the fakes carry a
  fixed 7×6 challenge, so the suite is identical before and after the shared
  clock pin merges.

## 6. Process note (not a finding)

The loop ran its later P17 stages concurrently with this one again: `5_ui`
took `ui/app_light_2.png` / `cmp_*_2.png` at 07:05–07:06 and stage 6 created
and removed `p17_probe_iter2_test.dart` during my whole-app run. Their files
(`p17_bugs_test.dart`, 8 green + 1 skip-marked shared-router proof) are green
and untouched by me.

## 7. Verdict basis

The suite cannot pass, for two independent reasons:

1. **§3.3 is a merge blocker** — when the already-merged `shared/keypad_grid`
   reaches this branch, the gate throws a `RenderFlex … unbounded` layout
   assertion on its first frame. `ORCHESTRATOR_NOTES` (07:13) mandated that
   re-check and it is exactly what caught this; the fix is a call-site change
   in P17 (patterns B and C above), not a component change.
2. **§3.2 remains red** until `main`'s keypad fix lands in this worktree (the
   pins encode the shared component's new contract: row pitch 82, column pitch
   88), and **§3.1** is a new minor CSS-truth deviation in the backdrop row.

All three are proven by failing tests; none was patched here, per this stage's
rules. Everything the iteration-2 builders changed inside `parental_gate` is
covered and green — including all six iteration-1 findings — `flutter analyze`
is clean, and this stage touched no screen code.


## From 5_ui.md
# P17 Parental gate — 5_ui (iteration 2)

Route `/parental-gate`, mode kid, child maya, seed demo. Simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical, 1170×2532 physical; ÷3).
No code edited by this stage. ORCHESTRATOR_NOTES.md applied as mandatory (items 1–7 checked below).

Shots:
- `docs/screens/P17/ui/app_light_2.png` / `app_dark_2.png`
- `docs/screens/P17/ui/cmp_light_2.png` / `cmp_dark_2.png` via `tools/screens/compare.py`

Mean diff:
- light: 6.66% (bands 0–7: 1.22 / 1.51 / 2.76 / 6.51 / 11.40 / 10.84 / 5.56 / 13.38)
- dark: 5.41% (bands: 1.41 / 1.52 / 2.57 / 6.22 / 10.99 / 10.22 / 5.14 / 5.23)
- Iteration 1 was 7.86% / 6.43%: bands 0–2 (scrim/backdrop/title/question) are fixed (now ~1–2.7%); bands 3–7 (keypad rows 2–4, cancel, caption, bottom) still fail.

Measured y, logical px (physical ÷3; modal edges = first/last row with >60% modal-surface run; text bands = dark-ink pixel histogram, centre column ±):
- Modal (card) top: design 66.0 / app 66.0 (Δ 0) — PASS, orchestrator item 2 fixed for top
- Modal bottom: design 777.7 / app 803.7 (Δ +26.0) — FAIL
- Modal left/width: design x24.0 w342.0 / app x24.0 w342.0 (Δ 0) — PASS
- Screen title “Grown-ups only” top: design 164.0 / app 164.0 (Δ 0) — PASS (orchestrator item 3 fixed)
- Instruction “Type the answer in numbers:” band: design 160.0 / app 160.0 (Δ 0) — PASS
- Question band top: design 225.0 / app 225.3 (Δ +0.3) — PASS (orchestrator item 3 fixed)
- Keypad row 1 top: design 344.0 / app 344.0 (Δ 0) — PASS
- Keypad row 2 top: design 426.0 / app 432.0 (Δ +6.0) — FAIL
- Keypad row 3 top: design 508.0 / app 520.0 (Δ +12.0) — FAIL
- Keypad row 4 top: design 590.3 / app 608.3 (Δ +18.0) — FAIL
- Cancel “Back to Pip” top: design 696.3 / app 724.0 (Δ +27.7) — FAIL (orchestrator item 6 not met: centres 702 vs ~729)
- Caption inherits the bottom shift (light band 7 diff 13.38%).

Non-findings (orchestrator rules — do NOT fix):
- Question copy “seven times six” vs “four times nine” and digit content (“4”+caret vs empty/carets): runtime state per orchestrator item 7 / DATA OVER MOCKS. Never hard-code design numbers.
- Status time/glyphs (9:41 vs 07:05/07:06): ignored per STATUS BAR rule. Home-indicator pill in design vs none in simctl shot: gallery mock only.
- Coin “120”, avatar “M” lilac, “Hi Maya!” copy: match DB/design.

What matches (element-by-element):
- Presence/order/copy: lock tile → title → instruction → question → digits → keypad (1–9, 0, delete) → “Back to Pip” → caption. Copy character-for-character with the HTML source.
- Scrim/backdrop (orchestrator item 1): FIXED. Full-screen barrier dims the whole kid screen including header and status-bar area; bands 0–1 now ~1.2–1.5%. Header “Hi Maya!” peeks dimmed above the card exactly like the design; no bright header, no status-bar collision.
- Shapes (background/border rects, not just glyphs): modal x24 w342 radius 32, lock tile 52, digit boxes 56×64 row, key circles match design diameter in row 1 (row height 72.0 in both), delete/lock icons match, no overflow/clipping/ellipsis, dark-mode surfaces/rings correct (dark keys white ring, no shadow).
- Alignment: side gutters exact; rows centred; nothing a few px off horizontally.
- Bottom edge owner rule: no bottom bar on this screen; scrim + shared kid meadow run full-bleed to the physical edge, no strip under a bar. Kid hills visible bottom 0 in both (shared scope, not local paint).
- Pip: covered by the card in both design and app; header child data correct (Maya). No v1 SVG visible.

Deviations (design → app + fix):

1. Keypad row pitch too tall — FAIL (orchestrator item 5 open).
   Design row tops 344 / 426 / 508 / ~590 (pitch 82); app 344 / 432 / 520 / 608 (pitch ~88: Δ 0, +6, +12, +18 cumulative).
   Fix: match the HTML keypad gap (row gap 16 with 72 keys, not 88 pitch); pin rows 2–4 tops to 426 / 508 / 590 ±2 in the geometry test.

2. Modal bottom / cancel / caption pushed down +26 — FAIL (orchestrator items 2, 6 open).
   Design bottom 777.7 (712 tall), cancel top 696.3, footnote ~748; app bottom 803.7 (738 tall), cancel top 724.0.
   Fix: with top fixed at 66, restore the exact bottom stack per CSS (keypad +16 → cancel min-height 56 margin-top 12 → note margin-top 10 → 20 bottom padding) so bottom returns to 778±2 and cancel centre to 702±2. Do not let the taller keypad pitch stretch the card.

3. (Consequence, no separate fix) Bands 4–5 (~11%) and light band 7 (13.38%) are fully explained by 1–2 plus expected question/digits state differences. Top-half geometry (orchestrator items 1–4: scrim, card top, title 168/155→now exact, question 228/215→now exact, boxes/row 1) is verified fixed this iteration.

Builder targets for iteration 3: keep top/title/question/row 1 as-is; fix keypad pitch to 82 and re-pin card bottom 778, cancel centre 702, footnote 748, with the scrim/barrier test (0,0)→full-size from ORCHESTRATOR_NOTES item 7.

