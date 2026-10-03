# Fix list after iteration 2

## From 3_test.md
# P06 Pocket money setup — Stage 3 TEST (iteration 2)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · in-memory
Drift DB (`Seed.demo` / `Seed.empty`), real router + DI + themes.

## Tests added (37 new, 46 → 83 in `app/test/features/pocket_money/`)

### `pocket_money_setup_bloc_test.dart` (+6, now 17)

| Test | What it pins |
|---|---|
| a throwing write lands in failure with the error message | `_onModeChanged` catch → `status: failure`, `errorMessage` kept |
| a throwing payout-day write lands in failure too | `_onPayoutDayChanged` catch path (after a successful load, so the guard has run) |
| a throwing stepper write lands in failure too | `_onWeeklyBaseStepped` catch path |
| a stream error reaches failure, and Retry re-subscribes to recovery | `combineLatest2` + `_closeOnError`: `loading → failure → loading → loaded` with the real DB truth; the plan §4 "no stuck UI" promise |
| a day tap before the first emission still writes | the `event.day == state.setup?.payoutDay` no-op guard must not swallow a write while `setup == null` (`repository.payoutDayWrites == [7]`) |
| stepping a child that is not in the setup is a silent no-op | unknown id → repository call with `0 + delta`, no emission, no throw (cross-checks review finding #5) |

New private fake `_RecordingRepository` (records every write, can throw,
can fail its first `watchSetup()`), built by factories so Retry re-listens.

### `pocket_money_setup_repository_test.dart` (+6, now 14)

| Test | What it pins |
|---|---|
| a child added later lands LAST even when it sorts first alphabetically | inserting `Anna` yields Maya → Leo → **Anna**, not Anna-first (orchestrator CHILD ORDER ruling, the hard case the two-child seed cannot show) |
| re-emits when the family row changes out of band | `watchSetup` is a live watch, not a one-shot (out-of-band `coinValuePencePerCoin = 2` re-emits) |
| setMode stamps one UTC instant on both rows | one transaction, `families.updatedAt == settings.updatedAt`, moved to now (drift reads `DateTime` back in local time, so the UTC contract belongs to the write site) |
| writes both rows with no children (Seed.empty) | the mirror write does not depend on children existing |
| an unknown child id writes nothing and does not throw | `setWeeklyBasePence('nobody', 350)` leaves Maya/Leo untouched |

### `pocket_money_setup_view_test.dart` (+25, now 51)

| Group | Coverage |
|---|---|
| owner rule: bottom edge (4) | light/dark × OS inset 0/34: `NestBottomCta` rect ends at y=844, panel is full-bleed, and a painted-pixel probe at (195, 843) equals `tokens.surface` with `tokens.paper ≠ tokens.surface` first asserted so the probe discriminates (no coloured strip under the bar) |
| owner rule: alignment (6) | light/dark × 320/390/430: H1, all three option cards, the settings card and the Continue button share one 20px gutter; the CTA panel is full-bleed; every settings row (`Payout day`, day cell 1, `Weekly base`, the 40px coin tile, Maya's avatar) starts on the card's inner edge, and the names/coin label sit exactly one avatar/tile in; the trailing coin value never crosses the right inset |
| orchestrator rulings (6) | light/dark × 320/390: Maya's row above Leo's (rows, names, steppers, initials M/L, bases £3.00/£1.50); the coin string follows the DB (`10 coins = 20p` after an out-of-band 2p/coin write, never a hard-coded `10p`); `/pocket-money-setup` in kid mode redirects to `/parental-gate`, which is why the ≥44 parent target (not ≥56) is the right bar for this screen |
| state recovery (4) | loading shows the spinner + H1 + CTA and **no** invented money style / `£3.00` / `10p` (plan §4); Retry after a stream error recovers the full loaded screen and clears the message; the failure body never leaks a half-loaded option card or day cell; `Seed.empty` still selects a style, moves the payout day and advances to `/paywall` |
| navigation, every tap (2) | mode/day/stepper taps never leave `/pocket-money-setup` (the coin row is display-only and stays put), Continue → `/paywall`, Back → `/add-children`, and exactly two navigable controls exist |
| accessibility (4 new) | the back button is a labelled 44×44 icon button; **all 16 controls** (back, 3 option cards, 7 day cells, 4 steppers, Continue) expose exactly one labelled semantics node, announce `isButton`, and are ≥44dp tall, with each `Mon…Sun` matched exactly once; the decorative coin `NestIcon` carries no `semanticLabel` and sits inside an `ExcludeSemantics`; a user-level double tap on `+` still reaches `£4.00` |

Kept from iteration 1 (unchanged): exact §0 copy in light + dark, the
320/390/430 × 1.0/1.3 matrix, `Seed.empty` caption, write-through taps,
loading/failure bodies, header/radiogroup/stepper semantics, 44dp targets.

## Results

- `dart format .` → clean (`dart format test/features/pocket_money` → 0 changed after the last edit).
- `flutter analyze` (full app) → **No issues found!** (ran in 3.9s).
- `flutter test test/features/pocket_money/pocket_money_setup_{bloc,repository,view}_test.dart` → **+83: All tests passed!**
- `flutter test` (full app) → **+741 ~7: All tests passed!**, exit 0. The 7
  skips all live in `p06_bugs_test.dart`, the parallel BUGS stage's
  bug-proof file (skips are that file's own convention); **my three files
  contain no `skip:`** and no `google_fonts`/`GoogleFonts`.
- Scope: only `app/test/features/pocket_money/**` edited (RULES §1). No
  shared code, no `analysis_options` change, no `SHARED_REQUEST` needed.

## Bugs found

### 1. P06-BUG-01 (MAJOR, confirmed by my own test) — stepper loses rapid taps

- **File:line** — `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart:83`
  ```dart
  final current = state.setup?.childById(event.childId)?.weeklyBasePence ?? 0;
  ```
  The handler reads the current base from `state.setup`, which only
  refreshes when the independent `emit.forEach` watch re-emits, then writes
  an **absolute** value. Two `PocketMoneyWeeklyBaseStepped` events handled
  before that emission therefore read the same base and write the same value
  twice. (`setMode`/`setPayoutDay` write absolute values too, but they have
  no read-modify-write arithmetic, so they are immune.)
- **Repro (deterministic, in-memory Drift, `Seed.demo`)** — I wrote this as a
  normal passing-shaped `blocTest` and watched it fail:
  ```dart
  bloc.add(const PocketMoneyLoadRequested());
  await bloc.stream.firstWhere((state) => state.setup != null);
  bloc.add(const PocketMoneyWeeklyBaseStepped('maya', 50));
  bloc.add(const PocketMoneyWeeklyBaseStepped('maya', 50)); // same turn
  ```
  Observed: `PocketMoneySetup(both, 6, 1, [PocketMoneySetupChild(maya, Maya,
  lilac, 350), …])` and `families`/`children` row = **350p**. Expected 400p.
  Two taps on `+` move £3.00 → £3.50 instead of → £4.00, and the UI settles
  on the wrong number silently.
- **User-level note** — the widget-level double tap
  ("two quick + taps add 50p each") currently passes only because
  `tester.tap` drains microtasks between gestures, so the first write lands
  first. That test is kept as the guard that must keep passing after the fix;
  the same-tick race is the defect.
- **Not patched** (Stage 3 rule). The parallel BUGS stage filed the same
  defect independently as `P06-BUG-01` with a skipped proof in
  `p06_bugs_test.dart`; I removed my duplicate proof rather than leave two
  copies, and left a header comment in
  `pocket_money_setup_bloc_test.dart` pointing at it so nobody "fixes" a test
  to match the bug.
- **Suggested fix** (for the next build stage) — accumulate in-flight deltas
  per child, or push the arithmetic into the repository as an atomic
  `SET weekly_base_pence = MIN(MAX(weekly_base_pence + Δ, 0), 2000)` and let
  the watch reconcile the display.

### Confirmed by tests, not bugs

- **Unknown-child step** (`review` finding #5): the handler writes `0 + Δ` for
  an id that is not in the setup; Drift updates 0 rows, nothing is persisted
  and no error surfaces. Pinned by two tests (bloc + repository). Cosmetic
  only — a real row is never reachable from this screen.
- **`errorMessage` survives recovery** (`review` finding #3): the state keeps
  the old message, but the failure body is gone and the loaded screen renders
  normally (asserted: `find.textContaining('offline')` finds nothing after
  Retry). No user-visible defect; flagged for the review stage only.
- **Day-cell tap width** (`review` finding #7): measured 30.3dp wide at 320dp
  and ≈40.3dp at 390dp (7 chips across the design's own row: 45.7dp cell
  pitch), height pinned to `NestDevice.tapParent` = 44. The plan §5 defines
  these cells as "44-min" and the HTML puts 7 chips in the same row, so this
  is design-inherent, not a screen defect — my tests assert the 44dp height
  contract and no width claim.
- **Text truncation is not assertable in widget tests** (method note): a
  standalone `TextPainter` built from `RenderParagraph.text` measures
  differently from the rendered tree (measured "Coin value" at 162.5dp vs the
  tree fitting it), and `RenderParagraph.didExceedMaxLines` reports `true`
  even for single-line text that fits, so neither is a usable oracle. Copy
  integrity is therefore pinned structurally (exact strings present, no
  layout exception, no widget box crossing a gutter or inset) and the glyph
  question stays with the UI stage — where it passed (the coin row and the
  day chips render unclipped on the simulator with the bundled Inter).

## Cross-stage notes

- The parallel REVIEW stage's MAJOR finding #1 is the same defect as above
  (independently reproduced here); its MINORs #2–#7 are either covered by the
  tests above or are non-defects for this screen.
- The parallel UI stage returned PASS, including the bottom-edge and
  alignment rules that the new owner-rule groups now pin at the widget level.


## From 4_review.md
# P06 — Stage 4 QA code review (iteration 2)

Diff reviewed: `git diff main...HEAD` (feature `pocket_money`, docs/screens/P06).
Checks: architecture contract, RULES §1 path isolation, design-system/token
usage, DESIGN_SPEC §5 P06 copy, a11y, performance, error handling, Children's
Code. Verified locally: `flutter analyze lib/features/pocket_money
test/features/pocket_money` → No issues found; `flutter test
test/features/pocket_money` → 46/46 pass.

## Scope compliance — OK

All edits under `app/lib/features/pocket_money/**`,
`app/test/features/pocket_money/**`, `docs/screens/P06/**` (RULES §1). No
shared code touched, no `SHARED_REQUEST.md` outstanding. Architecture: domain
still entities + abstract repo only; one bloc per feature; DI/routes per
feature; view wrapped at the route level. Verified locally: analyze clean,
`flutter test test/features/pocket_money` 46/46 pass, no
`google_fonts`/`GoogleFonts.*`, no skips, no analytics/ads imports, copy
matches `design/html-source/screens/P06-pocket-money.html` character-for-
character, children in insertion order (rowid, not nickname), bottom edge rule
holds (NestBottomCta SafeArea runs the CTA surface to the edge).

## Findings

1. **MAJOR — weekly-base stepper loses rapid taps (lost update).**
   `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`
   `_onWeeklyBaseStepped` (~line 83) computes the new value from
   `state.setup?.childById(...)?.weeklyBasePence ?? 0` and writes it
   absolute.
   The bloc only awaits the repository write; the updated `state.setup`
   arrives later via the independent `emit.forEach` subscription. Two quick
   "+" taps can both read the stale base (e.g. £3.00), so both write £3.50
   and net +50p instead of +£1.00. Mode/day writes are absolute so they are
   immune; only the stepper arithmetic races. Fix: track in-flight deltas per
   child and add them to the last confirmed base, or have the repository
   accept a delta and do `SET weekly_base_pence = MIN(MAX(weekly_base_pence +
   Δ, 0), 2000)` atomically, then let the stream reconcile the display.

2. **MINOR — a failed write blanks the whole screen.**
   `pocket_money_bloc.dart` `_onModeChanged` / `_onPayoutDayChanged` /
   `_onWeeklyBaseStepped` emit `status: PocketMoneyStatus.failure`, and the
   view's failure branch (`pocket_money_setup_view.dart` line 57-58) swaps
   the entire settings card for `_FailureBody` even though
   `state.setup` is still valid. A transient Drift error on a stepper tap
   hides all setup UI until a later stream emission flips status back. Fix:
   keep `status: loaded` and surface the error inline/snackbar.

3. **MINOR — stale `errorMessage` survives recovery.**
   `pocket_money_state.dart` `copyWith` never clears `errorMessage`; the
   `onData` path doesn't reset it either, so after failure → re-emit the
   message persists in state. Fix: clear `errorMessage` when status becomes
   `loaded`.

4. **MINOR — `assert` validation is a no-op in release.**
   `pocket_money_repository_impl.dart` `setMode` (~line 105) and
   `setPayoutDay` (~line 135) assert only; in release an invalid value would
   be persisted and the screen would render with no option/day selected. Fix:
   `throw ArgumentError.value(mode, 'mode')` in all modes.

5. **MINOR — stepper fallback writes for unknown child.**
   `pocket_money_bloc.dart` `_onWeeklyBaseStepped`: when the child id is not
   in `state.setup` (`?? 0`), it still writes `±50` (clamped) for that id.
   Fix: no-op when `childById` returns null.

6. **MINOR — hard-coded pixel sizes instead of tokens.**
   `pocket_money_setup_view.dart`: line 292 `horizontal: 13`, lines 349-364
   radio `22`/`10`, line 145 loading placeholder `200`, lines 651-652 coin
   tile `40` (could be `NestSpacing.s10`). Fix: move to spacing/size tokens
   in the shared scale (or file a SHARED_REQUEST to add them) and reference
   the tokens.

7. **MINOR — day-cell tap targets ~30dp wide at 320dp.**
   `pocket_money_setup_view.dart` `_DayRow`/`_DayCell` (lines 461-527): 7
   `Expanded` cells across `320 − 40` gutters ≈ 40dp each minus 6px gaps —
   below the 44dp parent target on the width axis alone (height is 44 via
   `NestDevice.tapParent`). Fix: enforce a minimum chip width with
   horizontal scroll at small widths, or widen the row into two lines under a
   breakpoint (same pattern as `_WeeklyBaseRow`).

## Positives

Correct insertion-order children query (`ORDER BY rowid`, not nickname — and
a repository test pins it), `families`/`settings` mirrored writes in one
transaction, `0..2000p` clamp, day re-tap guard, `_closeOnError` so Retry
resubscribes without leaking watchers, one combined `emit.forEach`, 44dp
targets on option cards/steppers/cells, full Semantics labels on steppers,
copy verbatim from the HTML, mock glyphs/status bar follow the foundation
chrome, children only ever in Maya→Leo order.


## From 6_bugs.md
# P06 Pocket money setup — Stage 6 adversarial bug hunt (iteration 2)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). No `ORCHESTRATOR_NOTES.md` exists. No Pip on this screen.

Method: adversarial testing against the committed screen (no source edits).
Executable repros live in `app/test/features/pocket_money/p06_bugs_test.dart`;
every bug test is `skip: true` so the default suite stays green (`flutter test
test/features/pocket_money/` → `+91 ~7: All tests passed!`). Removing the skips
makes all seven fail deterministically — verified this iteration:

```text
00:00 +0 -1  P06-BUG-01  Expected: <400>       Actual: <350>
00:01 +0 -2  P06-BUG-02  Expected: <6>         Actual: <7>
00:02 +0 -3  P06-BUG-03  Expected: >= <30>     Actual: <19.11864406779661>
00:02 +0 -4  P06-BUG-04  Expected: >= <44.0>   Actual: <40.285714285714285>
00:02 +0 -5  P06-BUG-05  "Weekly amount" not found (form blanked)
00:02 +0 -6  P06-BUG-06  Expected: null        Actual: 'Exception: database is locked'
00:02 +0 -7  P06-BUG-07  Expected: empty       Actual: [(childId: ghost, pence: 50)]
00:03 +8 -7  Some tests failed.
```

## Summary

| # | Severity | Area | One-line |
|---|---|---|---|
| 01 | **MAJOR** | bloc state race | weekly-base stepper loses rapid taps (lost update, –50p per lost tap) |
| 02 | minor | bloc state race | fast Sun→Sat payout-day correction silently dropped |
| 03 | minor | visual fidelity | day pills paint at ~55–63% of the design size via `FittedBox` |
| 04 | minor | accessibility | day cells are 40.3 dp wide at 390 (spec: ≥ 44×44) |
| 05 | minor | error handling | a failed write replaces the whole form with the load-failure body |
| 06 | minor | state hygiene | `errorMessage` is never cleared after recovery |
| 07 | minor | robustness | a stepper event for an unknown child id still writes ±50p |

---

## BUG-01 (MAJOR) — weekly-base stepper loses rapid taps

**Where:** `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart:79-97`
(`_onWeeklyBaseStepped` reads `state.setup?.childById(id)?.weeklyBasePence ?? 0`
and writes an *absolute* `current + delta`).

**Repro:** on `/pocket-money-setup`, tap `+` on Maya twice in quick succession
(the two `PocketMoneyWeeklyBaseStepped('maya', 50)` events are queued before the
`watchSetup` stream re-emits). Maya ends on **£3.50**, not £4.00 — one tap is
lost. The same race makes a correction tap land on a stale base.

**Failing test:** `P06-BUG-01: two quick "+" taps must each add 50p (real repo)`
(real Drift repository; 350 vs 400).

**Root cause:** the bloc's arithmetic is a read-modify-write on state that is
updated only by the independent `emit.forEach` subscription, while the event
handlers run to completion before the stream re-emits. Note: a widget-level
double `tester.tap` currently lands (see “attacks that hold”), because the test
crosses the pointer-event gaps the DB round-trip needs — the defect is timing-
dependent and real under load/slow storage, which is why it is rated major:
the amount the parent sets can silently differ from the amount stored.

**Suggested fix:** make the write atomic. Either (a) have the repository accept
a delta — `UPDATE children SET weekly_base_pence =
MIN(MAX(weekly_base_pence + Δ, 0), 2000) WHERE id = ?` — or (b) keep an
in-flight per-child pending delta on the bloc/state and add it to the last
confirmed base, clearing it when the stream confirms.

---

## BUG-02 (minor) — fast Sun→Sat payout-day tap is dropped

**Where:** `pocket_money_bloc.dart:61-77` (`_onPayoutDayChanged` guard
`if (event.day == state.setup?.payoutDay) return;`).

**Repro:** tap `Sun`, then tap `Sat` straight away. The first write stores 7;
the second event still sees `state.setup.payoutDay == 6` (stream not yet
re-emitted), matches the guard, and is dropped. The stored payout day stays
**Sunday** although the last tap was Saturday.

**Failing test:** `P06-BUG-02: a fast Sun→Sat correction must end on Saturday
(real repo)` (7 vs 6).

**Suggested fix:** guard against the last *requested* day (a pending value on
the bloc) or read the current value from the repository; alternatively drop
the guard and let the idempotent write run — re-tapping the selected day is
already a harmless no-op at the DB level.

---

## BUG-03 (minor, largest remaining visual deviation) — day pills render scaled down

**Where:** `pocket_money_setup_view.dart:504-527` — each day cell wraps a
standard `NestChip` (14 px label, `0 14px` padding, 32 px pill) in
`FittedBox(fit: BoxFit.scaleDown)` inside a 44-tall box.

**Repro:** at 390 dp the cell width is 40.3 dp while the chip’s intrinsic box
is 73.8 dp (test-metric font); the whole pill — label, radius and 1.5 px
border — is scaled to fit, so the painted pill is **19.1 dp high** (real-device
Inter metrics land ~20–22 dp) instead of the design’s 32 dp with 13 px labels.
The design `.chip.day` uses `padding: 0; font-size: 13px` and fills the grid
cell (SPACING_SPEC §10.3 “cells Expanded, font 13 … scaleDown”).

**Failing test:** `P06-BUG-03: a day pill must paint at the design height
(32, ±2)` (19.1 < 30).

**Suggested fix (shared, not screen scope):** add an optional `labelStyle` /
compact mode to `NestChip` (pre-agreed follow-up in `1_plan.md` §7,
`SHARED_REQUEST` candidate — do not fork the component) so the day cell can
use `padding: 0`, 13 px label, no `FittedBox`. UI stage records the same
deviation (its “deviation 3”); it needs the shared change to close.

---

## BUG-04 (minor) — day cell tap targets are 40.3 dp wide

**Where:** `pocket_money_setup_view.dart:461-489` — 7 `Expanded` cells across
318 dp of card content with 6 px gaps.

**Repro:** at 390 dp `tester.getSize(p06_day_1)` is `40.3 × 44`; DESIGN_SPEC
§0.9 requires parent tap targets ≥ 44×44 (height is correct at 44; width is
not). At 320 dp the cells are ~30.3 dp wide (worse).

**Failing test:** `P06-BUG-04: every day cell must be a 44×44 parent tap
target` (40.29 vs 44).

**Suggested fix:** keep the 7-up single-select look but give the row a
horizontal scroll (like P10 chips) or a two-line layout under a breakpoint so
each cell can reach 44 dp wide, or lift the day row out of the 16 px card
inset. Cross-check SPACING_SPEC §10.3, which assumes ≥44-tall cells.

---

## BUG-05 (minor) — a failed write blanks the whole setup form

**Where:** `pocket_money_bloc.dart:49-77` (write handlers emit
`status: failure`) + `pocket_money_setup_view.dart:57-58` (failure branch
renders `_FailureBody`, replacing the loaded body).

**Repro:** with a write that throws (`setMode`), tap `Weekly amount`: the
option cards, payout day and stepper rows all disappear and are replaced by
the error message + `Retry`, even though `state.setup` is still valid and only
one write failed. The parent loses the form until a later stream emission.

**Failing test:** `P06-BUG-05: a failed write must not blank the setup
controls` (finds 0 × “Weekly amount” after the failed tap).

**Suggested fix:** keep `status: loaded` for write errors and surface a
snackbar/inline error; reserve `_FailureBody` for load failures (or gate the
failure branch on `state.setup == null`).

---

## BUG-06 (minor) — stale `errorMessage` survives recovery

**Where:** `pocket_money_state.dart:23-35` (`copyWith` keeps `errorMessage`
when not passed; the loaded `onData` path never clears it).

**Repro:** let a `setMode` write throw (state `failure`,
`errorMessage: 'Exception: database is locked'`), then let `watchSetup`
re-emit (status back to `loaded`). `bloc.state.errorMessage` is still
`'Exception: database is locked'`. Any UI that renders `errorMessage`
irrespective of status (or a later failure branch) would show a stale error.

**Failing test:** `P06-BUG-06: errorMessage must clear when the setup
recovers` (non-null after recovery).

**Suggested fix:** clear `errorMessage` in the `onData` path
(`emit(state.copyWith(status: loaded, …, errorMessage: null))` via a
sentinel/`Value`-style parameter, since `copyWith` cannot express null today).

---

## BUG-07 (minor) — unknown child id still gets a stepper write

**Where:** `pocket_money_bloc.dart:83` — `?? 0` fallback when `childById`
returns null.

**Repro:** dispatch `PocketMoneyWeeklyBaseStepped('ghost', 50)`; the bloc
writes 50 pence for `ghost` instead of ignoring the event. Not reachable from
the current UI (rows are built from `setup.children`), but any future caller /
stale key hits a silent phantom write (the SQL UPDATE matches 0 rows, so the
visible effect is a failure only if the child reappears — still wrong).

**Failing test:** `P06-BUG-07: a stepper event for an unknown child must not
write` (records `(ghost, 50)`).

**Suggested fix:** `final child = state.setup?.childById(event.childId); if
(child == null) return;`.

---

## Attacks that hold (passing probes, same file, not skipped)

- **Kid-mode guard:** `GetIt → AppModeController.selectMode(kid)` then deep-link
  `/pocket-money-setup` → router redirects to `/parental-gate`; the setup H1 is
  not rendered. No guard bypass (also checked the expired-trial path: it
  redirects to `/paywall` then re-redirects through the kid gate).
- **Restart persistence (file-backed Drift):** mode `weekly`, payout day 2 and
  Maya £4.50 survive `db.close()` + reopen; children still come back in
  insertion order `[maya, leo]`.
- **6 children incl. “Maximilian-Alexander” at 320 dp × text scale 1.3:** no
  overflow, no exception, name ellipsized, insertion order kept (Maya first).
- **0 children (Seed.empty) at 320 dp × 1.3:** the `Add children to set weekly
  amounts.` caption renders; no £0.00 rows; no overflow.
- **£0.00 / £20.00 via the real repository:** render exactly, no rounding
  artifact (also brute-forced `(p/100).toStringAsFixed(2)` against exact pence
  formatting for **every pence value 0…2000** — zero mismatches).
- **Async gap / emit after close:** with a write pending, close the bloc and
  only then fail the write — `bloc.close()` completes and the late `emit` is a
  contained no-op (bloc 9 cancels the emitter), no `StateError`/unhandled
  exception.
- **Dark + light contrast:** P06’s text pairs (`ink`/`ink2` on `surface`,
  `ink2` on `leafTint`, `leafInk` on `leafTint`, `ink2` on `paper`) all pass
  WCAG 4.5:1 in both themes.
- **Widget-level quick taps:** two immediate `tester.tap`s on the real screen
  do land (`£4.00`), because the test crosses DB/stream turns between pointers
  — documented so the timing dependence of BUG-01 is explicit.

## Hunted and found clean / not applicable

- **One child:** row loop is child-count independent (demo path covers 2, the
  probe covers 6; no per-index assumptions).
- **£999.99 / 9999 coins:** unreachable on P06 — the repository clamps writes
  to 0…2000 pence by design (`pocket_money_repository_impl.dart:164`), and the
  screen renders no coin balance (the “Coin value” row is display-only from
  `coinValuePencePerCoin`, seed 1). No finding.
- **Empty lists:** covered above and by the existing suite.
- **Timezone / BST:** P06 stores a weekday index (1–7, DB `payout_day`) with no
  time-of-day or period math, and writes `updatedAt` as UTC + `updatedAtTz` —
  no DST-sensitive path on this screen. Not applicable.
- **Back navigation / deep link in parent mode:** `/add-children` back and
  `/paywall` continue are covered by the existing view suite; deep link loads
  the screen in both light and dark.

## Verdict rationale

One MAJOR defect stands: **P06-BUG-01** — a stepper tap can be silently lost,
so the saved weekly base may not match what the parent entered. Per the stage
rule (“PASS only if no major bugs”), the stage fails; BUG-02/03 share the same
stale-state class and should be fixed together. No files were changed outside
`app/test/features/pocket_money/p06_bugs_test.dart` and this report; the
temporary probe files were deleted.

