# P12 · Money (ledger) — Stage 6 bug hunt (iteration 1)

Adversarial pass over `/money` (parent mode, `pocket_money`): data edge cases
(0/1/6 children, long UK names, £0.00, £999.99, empty ledgers), rapid double
taps, back navigation and deep links, Drift restart persistence, parent/kid
mode guard, dark-mode contrast, 320 dp × text scale 1.3, async gaps,
Europe/London/BST timezone handling and integer-pence rounding.

Method: widget tests on the real app routes with the in-memory Drift seed
(plus one file-backed restart probe), direct `MoneyEditSheet` harnesses for
the parser, and pure tests for time/contrast. **No simulator was used** (stage
rule; only stage 5_ui may). No screen code was edited (stage rule). All probes
ran with `test/flutter_test_config.dart` pinning `Seed.anchorDay` to
Sat 3 Oct 2026.

Reproducers live in `app/test/features/pocket_money/p12_bugs_test.dart`.
Findings P12-BUG-01…05 are marked `skip: true` so the suite stays green; run
them with `flutter test --run-skipped` (all five fail for the stated reason).
Suite state at hand-off: `flutter test` 1879 pass / 5 skipped, `flutter
analyze` No issues found, `dart format` clean.

---

## P12-BUG-01 — Unbounded amount: int64 clamp, wrong £ display, 98 px row overflow — MAJOR

`MoneyEditSheet._parsePence` accepts any digit string and returns
`(double * 100).round()` with no upper bound.

**Repro**
1. `/money` → scroll down → `Add money`.
2. Enter `99999999999999999999999` (23 digits — a mash/paste; the field has no
   `maxLength`).
3. Tap `Add money`.
4. Result: a `RenderFlex overflowed by 98 pixels on the right` exception; the
   stored `gift` row is clamped by `.round()` to `9223372036854775807`
   (int64 max) and renders as `+£92233720368547760.00` — already 2p short of
   the stored value because the display path is also double-based.

**Failing test** `P12-BUG-01: an unbounded amount is clamped to int64 and
overflows the history row` (skipped)

**Suggested fix**
- Cap the parsed amount (e.g. reject > £1,000,000) with the sheet's inline
  error, and parse pence without a float multiply: split the input on `.`,
  `int.parse(left) * 100 + int.parse(right.padRight(2, '0'))`.
- Defence-in-depth for the row: wrap `MoneyHistoryRow`'s trailing amount in
  `Flexible` + `TextOverflow.ellipsis` (it is `softWrap: false` with no
  overflow policy today).

---

## P12-BUG-02 — Separator stripping silently rewrites the amount by 10–100× — MAJOR

`_parsePence` runs `replaceAll(RegExp('[^0-9.]'), '')` before parsing, so any
separator is *deleted*, never rejected.

**Repro**
1. `/money` → `Record spending`.
2. Enter `1,50` (a comma-decimal keyboard, or a paste).
3. Tap `Record spending`.
4. Result: `15000p` → **£150.00** recorded, not £1.50 (probe DB value
   `-15000`). Same class: `1,5` → £15.00; `-5` → +£5.00 (minus silently
   dropped); `5 5` → £5.50.

**Failing test** `P12-BUG-02: "1,50" is silently recorded as £150.00 (100x)`
(skipped)

**Suggested fix**
- Validate instead of stripping: allow an optional leading `£`/spaces and then
  only `^\d+(\.\d{1,2})?$` (or a lone leading `.`); reject everything else
  with the existing inline error copy.
- If comma support is wanted, accept exactly one comma as the decimal
  separator only when no dot is present and ≤ 2 digits follow; never silently
  delete an ambiguous separator.

---

## P12-BUG-03 — >2-decimal input drops half a penny through float rounding — MINOR

**Repro** `Add money` → enter `1.005` → `Add money`. `1.005 * 100` evaluates
to `100.49999999999999` and `.round()` floors it: **100p** (£1.00) is stored
instead of 101p (or a rejection of sub-penny input).

**Failing test** `P12-BUG-03: "1.005" silently stores £1.00 (half-penny
dropped)` (skipped)

**Suggested fix** covered by BUG-02's strict two-decimal parser (integer
pence maths; no float multiply).

---

## P12-BUG-04 — Six children at 320 dp shrink the segment below the 44 px target — MINOR

With six children, `NestSegmented`'s five 4 px gaps plus 4 px track padding
divide 280 px into six 42 px options at 320 dp (measured semantics rect
`42.0 × 44.0`), under the parent-mode 44 px tap-target rule, and long names
truncate to ~5 characters (`Maximili…`). At 390 dp the same roster gives
53.7 px, so this is a 320 dp-only collapse.

**Failing test** `P12-BUG-04: six children at 320dp collapse the segment below
the 44px tap target` (skipped)

**Suggested fix** Shared component, not P12: file a SHARED_REQUEST to make
`core/design_system/components/nest_segmented.dart` horizontally scrollable
(or wrap into rows) when `width / options.length` would drop below 44 px.
P12 should not fork the shared control locally.

---

## P12-BUG-05 — ORCHESTRATOR_NOTES geometry: the stack sits 15–21 px low — MAJOR

Mandated by `ORCHESTRATOR_NOTES.md` (12:08, overruling the stage-5 PASS). The
extra `SizedBox(height: NestSpacing.s4)` between `NestStatusBar` and
`_PageTitle` pushes everything down 16 px (title centre 88 vs design 72);
the cards then accumulate +3/+5 more px.

**Repro** Pump `/money` at 390×844 with the bundled real fonts and measure:

| Element | Design | App |
|---|---|---|
| Title centre | 72 | **88** |
| Segmented top | 106 | **121** |
| Owed card top | 173 | **189** |
| Goal card top | 400 | **419** |
| History card top | 504 | **525** |

**Failing test** `P12-BUG-05: the whole stack sits 15-21px below the design`
(skipped; `setUpAll(_loadBundledFonts)` real-font metrics)

**Suggested fix**
- Drop the extra 16 px spacer above the title (keep `_PageTitle`'s own
  `top: 8`) so the title/segmented/hero land on the design y.
- Reconcile the remaining hero/goal/history heights against the HTML
  (`.hero .brk` margin-top 4, card paddings) so every anchor is within ±1 px,
  then un-skip this test as the real-font geometry guard. The hero amount
  already carries the required `letterSpacing: -0.4`.

---

## Attacks that hold (no bug found)

All of these are unskipped guards in `p12_bugs_test.dart`:

- **Parser exactness for 2 dp input**: `5.00`/`£5`/`.5`/`0.01`/`1.15`/`999.99`
  → `500/500/50/1/115/99999` pence; empty/`abc`/`0`/`0.00`/`1.2.3`/`.` show the
  inline error and never reach the bloc.
- **Rapid taps**: two same-frame taps on `Add money` open one sheet; two fast
  presses (0 and 120 ms apart) of the sheet CTA write exactly one row.
- **Six children at 390 dp**: creation order (Maya, Leo, Maximilian-Alexander,
  Noah, Ava, Ethan), one row, no overflow.
- **Long UK name** `Maximilian-Alexander` at 320 dp × 1.3: hero renders, no
  `RenderFlex` exception.
- **Empty ledger child**: `£0.00`, `Weekly base £0.00 + quests £0.00 · …`,
  `No history yet`, buttons still live.
- **Single-child family**: one segment, no crash.
- **£999.99 top-up**: stores `99999p`, toast `Added £999.99 for Maya`.
- **Rapid child switching**: last tap wins.
- **Back from `/payout`**: route returns to `/money`, ledger state intact.
- **Deep links**: kid mode `/money` → `/parental-gate`; never-onboarded
  `Seed.fresh` `/money` → `/welcome`.
- **Empty state**: `Add a child` exposes `SemanticsAction.tap`; performing it
  navigates to `/add-children`.
- **Dark mode**: same copy; P12 text pairs (onHero2/heroBg, onHero/heroBg,
  ink/ink2 on surface/paper, danger/paper) all ≥ 4.5:1 in both themes.
- **Europe/London + BST**: 23:30 UTC 24 Oct 2026 → `Sun 25 Oct`,
  `12:30am` (BST still in force); post-fall-back instants resolve to GMT;
  `payoutLabel(Sat)` from Sun 4 Oct → `Sat 10 Oct`; Saturday 23:59 still names
  today.
- **Family zone change**: `Asia/Dubai` floats the `Next payout` label in
  Dubai; stored London rows keep and name their own zone `(London)`.
- **Restart (file-backed Drift)**: gift `+500` and spend `-150` rows persist
  across close/reopen; owed maths unchanged at 420p.

## Process notes

- Concurrent loop stages added `money_ledger_states_test.dart`,
  `money_ledger_responsive_test.dart` and `ORCHESTRATOR_NOTES.md` while this
  stage ran; a transient 8-test failure in the responsive file mid-write
  disappeared once the file settled (it passes on its own and in the full
  run). Not a finding.
- `p06_bugs_test.dart` was left untouched.

VERDICT: FAIL
