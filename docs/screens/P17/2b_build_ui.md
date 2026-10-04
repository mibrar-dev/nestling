# P17 Parental gate — 2b build UI (iteration 4)

Scope: `app/lib/features/parental_gate/presentation/views/**` +
`presentation/widgets/**`, and the widget/view-side tests in
`app/test/features/parental_gate/` (`parental_gate_view_test.dart`,
`parental_gate_states_test.dart`, `parental_gate_geometry_test.dart`,
`p17_bugs_test.dart`). No bloc/domain/data edits, no DI/route edits, no
simulator, no `flutter clean`, no whole-app `flutter test`.

Contract re-read (mandatory before finishing): `2a_build_logic.md` (iteration 4)
says **CONTRACT CHANGES: none** — same three events, same state fields
(`status/items/entered/attempts/unlocked/errorMessage`), same
`challengeFor(utcNow)` London-day rule. Nothing in this layer had to be re-cut.

Inputs re-read: `ORCHESTRATOR_NOTES.md` (items 1–7, the 07:13 shared-keypad
note and the **new 09:48 shared/kid_trial_gate note**), `FIXES_3.md`,
`6_bugs.md`, `4_review.md`, `3_test.md`, `1_plan.md`, the light/dark design PNGs
and `design/html-source/screens/P17-parental-gate.html`.

## Summary

Four UI-layer changes, all in the view, plus their pins. Every one of them
closes an item that three consecutive stages had recorded as still open, and
none of them moves a design band: the 11 `ORCHESTRATOR_NOTES` geometry pins are
still **Δ0** against the design PNG.

| Change | Closes | Layout impact |
|---|---|---|
| Card centred per CSS (no `66` literal) | `4_review` finding 3 | Δ0 at textScale 1.0; **better** at 1.3 (no internal scroll) |
| `.gate-note` rhythm owned by one column | `4_review` finding 4 | removes a 10 px orphan gap in `failure` |
| `Try again` 44 → `NestDevice.tapKid` (56) | `4_review` finding 6 / `6_bugs` obs 2 / `3_test` obs 2 | failure state only (not in any design PNG) |
| Real `Back to Pip` escape while loading | `3_test` obs 3 / `6_bugs` obs 1 | **none** — same 56 px slot |
| `P17-BUG-1` un-skipped (shared fix landed) | `ORCHESTRATOR_NOTES` 09:48 | none |

Feature suite: **115 pass · 0 skip · 0 red** (iteration 3: 106 pass · 1 skip).

## 1. The card is now centred like the CSS (4_review finding 3)

The view pinned the card with a derived literal: `Padding.fromLTRB(s6, 66, s6, 0)`
+ `ConstrainedBox(minHeight: maxHeight − 66)` + `Align(topCenter)`. That `66` is
`(844 − 712) / 2`, i.e. the CSS truth `.modal { top: 50%; transform:
translateY(-50%) }` re-encoded as a magic number (DESIGN_SPEC §5 P17 describes
the screen as "a centred `.modal`"). Now:

```dart
SingleChildScrollView
└ ConstrainedBox(minHeight: constraints.maxHeight)          // the canvas
  └ Column(mainAxisAlignment: center, crossAxisAlignment: stretch)
    └ Padding(horizontal: NestSpacing.s6) → Semantics('Parental gate') → NestModal
```

`Column`, not `Align(Alignment.center)`/`Center`: inside a scroll view those
shrink-wrap, so a card taller than the canvas would hang off the top with its
first pixels unreachable. The Column grows past the viewport instead, so the
scroll view can still reach the top. Horizontal padding moved *inside* the
scroll view so the gutters stay 24 px; the modal still gets tight 342 px
constraints.

Measured effect (390×844, textScale 1.0 — `parental_gate_geometry_test.dart`,
all 11 pins green, every band Δ0):

| Band | Design | App |
|---|---|---|
| card top / left / width | 66 / 24 / 342 | 66 / 24 / 342 |
| card bottom / height | 778 / 712 | 778 / 712 |
| title / instruction / question centres | 168 / 201 / 228 | same |
| answer boxes centre | 288 | 288 |
| keypad row centres | 380/462/544/626 | same |
| `Back to Pip` centre / caption centre | 702 / 749 | same |

The one pin that *was* an artefact of the old anchoring has been re-pointed at
CSS instead of deleted — `the card stays centred at every supported scale · 390
× 1.3 centres the card, fits it and needs no scroll` now asserts
`top == height − bottom` (±1), `bottom ≤ 844`, and
`Scrollable.position.maxScrollExtent == 0`. Previously it asserted
`top == 66`, i.e. it pinned the 10 px internal scroll that `3_test` obs 1
recorded. The card now sits at top 41 / bottom 803 at textScale 1.3: centred,
whole, nothing scrolled out of reach. **The expectation moved to CSS truth, it
was not weakened** — the old one is strictly stronger about top-anchoring and
weaker about reachability, and top-anchoring was the finding.

## 2. `.gate-note` has one owner (4_review finding 4)

`_GateFailure` rendered its own `SizedBox(s2 + gap2)` + `This keeps settings and
purchases safe.`, while the enclosing column added a second `s2 + gap2` gap plus
a `SizedBox.shrink()` standing in for the caption it skipped — a 10 px orphan
gap under the caption in the failure state, and two owners for one piece of
copy (flipping the `status == failure` condition would have printed it twice).
The enclosing column now always renders the gap + caption and `_GateFailure`
renders neither. Pinned in the retry/escape test:

- `findsOneWidget` for the caption;
- `captionTop − cancelBottom == s2 + gap2` (±1) — the `.gate-note` gap is the
  only gap below it;
- `cardBottom − captionBottom == s5` (20) — pad-bottom, **no dead space**.

## 3. `Try again` is a kid control: 56, not 44 (4_review finding 6)

`1_plan.md` §(d) said `minHeight: 44` for the retry; DESIGN_SPEC §5 kid rules
("tap targets ≥56") and the sibling `Back to Pip` in the same card say 56. The
spec wins on a kid screen, no design PNG shows the failure state, and the
reviewer's own instruction was to amend the plan line. The pin in
`parental_gate_states_test.dart` moved from `≥ NestDevice.tapParent` (44) to
`≥ NestDevice.tapKid` (56) — a **stricter** assertion, not a relaxed one. This
is the only place I deviated from `1_plan.md`; it is called out here for the
orchestrator, and the code comment at the call site records why.

## 4. The loading state has a real escape (3_test obs 3 / 6_bugs obs 1)

`_GateLoading` reserved a bare `const SizedBox(height: 56)` under the spinner, so
during `initial`/`loading` the only way out was the system back gesture — bad
for a kid and worse for VoiceOver. It now renders the same 56 px ghost
`Back to Pip` the loaded card shows, wired to the existing `_leave`. The button
is exactly the 56 px the placeholder stood in for, so the card does not move:
the `loading placeholders keep the loaded card height` geometry pin is still
**Δ0**. New proof `loading still offers the Back to Pip escape` asserts the
semantics node exists, has `SemanticsAction.tap`, and that tapping it lands on
`/kid-home` in kid mode.

## 5. `P17-BUG-1` un-skipped — the shared fix has landed (ORCHESTRATOR_NOTES 09:48)

`main` merged `shared/kid_trial_gate` (`0d7aa52`): `router.dart:128-131` now
routes kid mode + `trialExpired` to the gate and exempts the gate from that
redirect, so the loop cannot form. Per the 09:48 note I un-skipped the proof and
it passes. It is slightly **stronger** than before: it now also asserts there is
no router error page (`find.textContaining('redirect loop')` is absent) and that
`currentPath(tester) == '/parental-gate'`. The feature suite therefore has **no
skips at all**. `SHARED_REQUEST.md` #1 and #2 are annotated RESOLVED.

## FIXES_3 triage

`FIXES_3.md` is the iteration-3 `2_build` summary; per the orchestrator's
PROCESS-ITEMS rule its `dart format` / `flutter analyze` / suite rows are not
findings. Every item I own is closed or explicitly out of layer:

| Item | Status |
|---|---|
| ORCHESTRATOR_NOTES 2–6 + item 11 (11 geometry pins + scrim) | **MET, re-verified Δ0** this iteration |
| SHARED_REQUEST #3 (keypad pitch) | resolved on `main` (`9cac0c6`), nothing P17-local — closable |
| P17-BUG-1 (shared router) | **fixed on `main`, proof un-skipped and green** |
| 8 reds in `kid_home` | out of layer (RULES §1); `main` fixed them (`0d7aa52`); not touched by me |
| `flutter test` whole app | not run — integrator's job (stage brief) |

Beyond FIXES_3 I also closed the three `4_review` UI findings and the two
`3_test`/`6_bugs` UI observations listed above, because they would otherwise be
re-found every iteration.

## Owner-rule sweep (re-checked, all clean)

- **PIP** — the backdrop still renders the child's own Pip from the DB via
  `PipAvatar` (`style/skin/accessory/stage`; Maya = Mochi·sunny·stage 3), with
  the no-child fallback `PipAvatar(style: mochi, stage: 3)` (default skin
  `sunny`). No `pip_stage_*.svg`. Untouched this iteration.
- **STATUS BAR** — `NestStatusBar` still only reserves height.
- **DATA OVER MOCKS** — question and digits stay repo/DB driven; nothing
  hard-coded, and the design's `seven times six` example is not asserted
  against the DB value anywhere.
- **BOTTOM EDGE** — no bottom bar on this screen; scrim + shared `KidScope`
  meadow run full-bleed (pinned).
- **ALIGNMENT** — 24 px gutters unchanged; the horizontal padding moved inside
  the centring Column and the modal still spans exactly 24…366.
- **CHILD ORDER** — `db.watchChildren` order, `kids.first` fallback (insertion
  order, never alphabetical).
- **COPY** — re-verified character-by-character with the HTML source:
  `Grown-ups only`, `Type the answer in numbers:`, `Back to Pip`,
  `This keeps settings and purchases safe.`, `Parental gate`, `Number pad`,
  `Delete`, `Loading the grown-ups check`, `That wasn’t right — try again`
  (curly U+2019). No copy added or changed this iteration.
- **FONTS / LETTER SPACING / BALANCED HEADINGS / CHIP ROWS** — no
  `google_fonts`, no `letterSpacing` (the P17 CSS sets none), no
  `NestBalancedText` (this screen uses `.h2/.h3/.body-s/.caption`, all excluded
  by the owner rule), no chip rows.
- **CLOCK** — no `DateTime.now()`; nothing time-dependent was added.
- **TRIAL / IDS** — no `subscription_status` write; the new id rule does not
  apply (no rows created).
- **ACCESSIBILITY ACTIONS** — every control still exposes
  `SemanticsAction.tap`: 11 keys, `Try again`, both `Back to Pip` buttons
  (loaded + loading). No `Semantics(excludeSemantics: true)` wrapper was added
  around anything interactive; the new button is a plain `NestButton` (outer
  semantics `onTap`), and the new test proves `performAction(tap)` drives real
  navigation.
- **SIMULATORS** — none booted, installed on, screenshotted or driven.

## Test results (my layer only)

```
flutter analyze lib/features/parental_gate test/features/parental_gate
  → No issues found! (ran in 3.1s)

dart format --output=none --set-exit-if-changed lib/features/parental_gate \
    test/features/parental_gate
  → Formatted 18 files (0 changed)

parental_gate_geometry_test.dart   → +11  All tests passed!   (11/11 pins Δ0)
parental_gate_view_test.dart       → +22  All tests passed!   (was +21)
parental_gate_states_test.dart     → +26  All tests passed!   (was +25)
p17_bugs_test.dart                 → +18  All tests passed!   (was +17 ~1)
flutter test test/features/parental_gate
  → +115: All tests passed!         (was +106 ~1 — 0 skips now)
```

Per-file counts include 2a's files; I ran the whole feature folder (not the
whole-app suite) because the brief allows my own view tests.

## Files changed

- `app/lib/features/parental_gate/presentation/views/parental_gate_view.dart`
  — centred card (§1), caption ownership (§2), `Try again` 56 (§3), loading
  escape (§4). The large line count in the diff is `dart format` re-indenting the
  modal subtree under the new `Column` level; `git diff -w` shows only the four
  intended hunks.
- `app/test/features/parental_gate/parental_gate_states_test.dart` — retry pin
  44 → 56, caption single-owner + `.gate-note` + pad-bottom pins, 1.3 pin
  re-pointed at CSS centring.
- `app/test/features/parental_gate/parental_gate_view_test.dart` — new loading
  escape proof.
- `app/test/features/parental_gate/p17_bugs_test.dart` — `P17-BUG-1` un-skipped
  and strengthened.
- `docs/screens/P17/SHARED_REQUEST.md` — #1/#2 annotated RESOLVED.

No change in `presentation/widgets/` (`parental_gate_placeholder_card.dart` is
the repo-wide v1 scaffold, unreferenced in 14 features — deliberately kept, see
`2b_build_ui.md` iteration 3 and `4_review` finding 7).

## LEFT FOR NEXT ITERATION

Nothing in the 2b layer — no outstanding UI/layout/copy item, and every pin that
encodes this screen is green at Δ0. Carried, all outside this layer:

- `4_review` finding 2 (backdrop reads `AppDatabase` via GetIt): a new
  repository method, i.e. a contract change that contradicts `1_plan.md` §(b)
  and needs a joint logic+UI iteration if the orchestrator ever mandates it
  (2a declines it for the same reason).
- `4_review` finding 5 (each `Try again` starts a second open `emit.forEach`):
  bloc file — 2a's layer.
- `6_bugs` obs 3 (dead `parental_gate_placeholder_card.dart`) / finding 7
  (`ParentalGateChallengeModel` unreferenced from `lib`): deliberate, documented.
- Midnight re-key of an open gate (`watchItems()` has no timer): 2a, open by
  design, no pin.
- Whole-app suite and simulator verification: the integrator's stage, not mine.

VERDICT: PASS