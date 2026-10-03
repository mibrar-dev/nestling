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

VERDICT: FAIL