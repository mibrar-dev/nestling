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

VERDICT: FAIL
