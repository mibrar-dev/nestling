# P06 Pocket money setup — Stage 3 TEST (iteration 5)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · in-memory
Drift DB (`Seed.demo` / `Seed.empty` / `Seed.onboardingKids`), real router +
DI + themes.

Iteration 4 ended FAIL on one finding of mine (P06-BUG-10, unbalanced `.h1`)
plus the review's #1–#14. The iteration-5 build merged main (so
`NestBalancedText` finally exists in this worktree), adopted it, put the
payout-day row back at the design's 32 px band, and closed the rest. This
stage verifies every one of those with executable contracts and looks for new
defects in the rewritten code.

## Tests added (7 new, all widget-level; 112 → 119 in my three files)

`pocket_money_setup_view_test.dart` (+7, now 74) — new group "iteration 5 contract":

| Test | Fix it pins | What it asserts |
|---|---|---|
| `the H1 renders through NestBalancedText (P06-BUG-10)` | review #3 / my iteration-4 finding | an ancestor of the heading **is** `NestBalancedText`; identical copy and `NestType.h1` style (28px/w900); `TextAlign.left` so the balanced box cannot slide off the 20 px gutter (owner ALIGNMENT rule); the painted box stays within `20 … width-20`; the `Semantics(header: true)` node survives; light **and** dark |
| `the balanced H1 holds its gutter at every measured width and scale` | same, at the matrix | 320/390/430 × 1.0/1.3: the component's own `lineCountFor` reports the same line count at the gutter width as at 4× that width (balancing never *adds* a line), and the painted rect keeps its left edge at 20 and its width ≤ gutter |
| `the day row paints the design 32px band with the pills flush at the label's baseline (review #1)` | review #1 (MAJOR) | 320/390/430: the first cell starts exactly `gap6` (6 px) below the `Payout day` label (`.day-row { margin-top: 6px }`), cells and pills are 32 tall (not 44 — a 44-tall box would centre every pill 6 px low), all seven pills share one top edge, and the six inter-pill gaps are all exactly 6 px |
| `the settings card stays flush above the CTA panel (review #1)` | same | light + dark: scrolled to the end, the card's bottom **and** the `Coin value` row sit above `NestBottomCta.top` — nothing stays permanently hidden behind the fixed panel (the card is a sibling in the page column, not an overlay); card height bounded to the design's ~270 |
| `names and the coin-value label use .amount-name (review #5)` | review #5 | `Maya`, `Leo` and `Coin value` all resolve to 16px / w600 / height 22/16 (`.amount-name` in the HTML) |
| `the loading spinner is token-coloured, not the Material default (review #6)` | review #6 | the `CircularProgressIndicator` colour is `tokens.leaf`, and explicitly not Material's `0xFF2196F3` |
| `a ledger-only emission does not rebuild the setup form (review #14)` | review #14 | with broadcast-driven fake streams: a new ledger row with an unchanged setup leaves the option card's **widget instance identical** (no rebuild) while the bloc still carries the row for /money; a real setup change does rebuild and flips the selection |

New helper `_PushRepository` (broadcast `StreamController`s for both halves of
the bloc's combined stream) makes the `buildWhen` contract testable — the
one-shot stream fakes could never emit twice.

**Teeth check.** `a ledger-only emission does not rebuild the setup form` was
verified against the pre-fix behaviour: with `buildWhen` temporarily removed
from `pocket_money_setup_view.dart` the test fails with
`Expected: same instance as Semantics… Actual: Semantics…`; with the shipped
filter it passes. The view file was restored byte-for-byte (`git status` on
`app/lib/` is empty) — this stage edits no screen code.

## Results

- `dart format --set-exit-if-changed` on my three files → clean (0 changed).
- `flutter analyze` (full app) → **No issues found!** (ran in 2.7s; the two
  transient warnings that appeared mid-run were unused imports in the parallel
  BUGS stage's `p06_bugs_test.dart`, cleared by that stage before I finished).
- `flutter test test/features/pocket_money/pocket_money_setup_bloc_test.dart` → **+30: All tests passed!**
- `flutter test test/features/pocket_money/pocket_money_setup_repository_test.dart` → **+15: All tests passed!**
- `flutter test test/features/pocket_money/pocket_money_setup_view_test.dart` → **+74: All tests passed!**
- `flutter test test/features/pocket_money/` → **+144 ~2: All tests passed!**
- `flutter test` (full app) → **+1161 ~2: All tests passed!**, exit 0.
- No `skip:` in my three files, no `google_fonts`/`GoogleFonts`, no simulator
  used (only the UI stage may boot one). Scope: `app/test/features/pocket_money/**`
  + `docs/screens/P06/**` (RULES §1).

## Bugs found

**None.** P06-BUG-10 is fixed and now guarded by two passing tests, and the
iteration-4 review's items #1, #3, #5, #6 and #14 each have an executable
contract. I found no new defect in the day-row rewrite, the balanced heading
swap, the `buildWhen` filter or the `.amount-name`/spinner restyling.

## Coverage that did not change (and why)

- **`_requestedBase` accumulation, the 2000p/0p clamps, the unknown-child
  no-op, the `_pendingDay` guard, `clearErrorMessage`, `withChildBase`** — all
  from iterations 3–4, still green and still meaningful after this build.
- **`ArgumentError` past the `assert` (review #12)** — not directly testable
  here: in a `flutter test` run assertions are enabled, so the `assert` always
  fires first and the release-only `ArgumentError` is unreachable. The
  observable half is already pinned (the repository rejects `yearly` and days
  outside 1..7 with `AssertionError`, and the view only ever sends the three
  valid mode strings).
- **Review #11 (screen-authored empty-state copy)** — `Add children to set
  weekly amounts.` renders only under `Seed.empty`/`Seed.fresh` and is
  mandated by `1_plan.md` §4; it still needs the orchestrator's ratification,
  which is not a test question.
- **P06-BUG-04** — proof deleted by 2b (its ≥44 px **width** demand is
  superseded by `ORCHESTRATOR_NOTES` item 2: seven chips must fit inside the
  card's 16 px inset). The 32 px band and the 44 px hit slop are now pinned by
  this iteration's day-row test plus the ±5 px tap test.

## Notes for the next stages

- The day row's geometry moved again this iteration (32 px cells, no 44 px
  cell box, pills flush at the design y). The `±5 px above/below` tap contract
  now rests on `NestChipWrap`'s hit slop rather than a taller cell box — if a
  future change inserts a `LayoutBuilder`/`Semantics`/`SizedBox` between the
  wrap and the card column, hit testing re-clamps and the integrator's ±5 px
  test fails. That fragility is documented in the view's comment.
- `SHARED_REQUEST.md` items 1 (shared `NestChip` day variant) and 2 (spacing
  tokens for 13/22/200/60/300) remain open; they are shared-code items, not
  screen defects.

VERDICT: PASS