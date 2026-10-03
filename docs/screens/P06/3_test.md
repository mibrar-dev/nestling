# P06 Pocket money setup — Stage 3 TEST (iteration 7)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · in-memory
Drift DB (`Seed.demo` / `Seed.empty` / `Seed.onboardingKids`), real router +
DI + themes, real bundled fonts where the layout is font-sensitive.

The iteration-7 build closed the two mandatory note items (09:30 coin-value
alignment, 09:42 semantics tap actions) plus review findings #1–#8, and the new
**ACCESSIBILITY ACTIONS** rule arrived with it. This stage verifies all of that,
adds the rule's missing coverage (the screen's own stepper buttons), and pins
P06-BUG-13's regression.

## Tests added (6 new; 148 → 154 in my three files)

### `pocket_money_setup_view_test.dart` (+6, now 97) — group "semantics actions reach the database"

The rule: *every* interactive element must expose `SemanticsAction.tap`, and
`performAction(tap)` must change the real state or DB. 2b covered the three
option cards and the seven day cells (hasAction + performAction moving the
selection). The screen's **four stepper buttons** are P06-owned too
(`P06WeeklyStepper`, feature-private), and they had no action-level coverage
anywhere, so:

| Test | What it pins |
|---|---|
| `all four stepper buttons expose a tap action` | each of Maya's/Leo's `+`/`−` announces `hasAction(tap)`, `isButton` and enabled — `_StepBtn` declares no `excludeSemantics`, so the `InkWell`'s action merges up |
| `performAction(tap) on "More weekly pocket money for Maya" writes the child row` | the action moves `children.weekly_base_pence` 300 → **350** in the database (not just the painted row), and `£3.50` appears |
| `performAction(tap) on "Less weekly pocket money for Leo" writes the child row` | the decrease path: 150 → **100** |
| `performAction(tap) on an option card writes mode to BOTH mirrored rows` | the accessibility path keeps `families` **and** its `settings` write-mirror in step, exactly like a finger tap |
| `performAction(tap) on a day cell writes the payout day` | day 6 → **7** in the database |

Plus one assertion added to the existing real-font matrix sweep: **`Coin value`
must never ellipsize** at any of the twelve width × scale × theme combinations
— the exact P06-BUG-13 failure mode ("Coin val…" at 320 × 1.3) when the row
split 50/50. The label now wraps and the trailing value (the one text
`1_plan.md` §5 sanctions for ellipsis) takes the shortfall.

### Method note — the trap that cost this stage an hour (worth keeping)

**Never `await` a Drift future directly inside a `testWidgets` body.**
`AppDatabase`'s watch streams deliver on the real isolate event loop, which the
widget test's `FakeAsync` clock never pumps, so the `await` blocks until the
framework's **10-minute** timeout — the test reports "did not complete", not a
useful failure. Read through `await tester.runAsync(() => repository.watchSetup().first)`
instead.

This is not hypothetical: the sibling `p06_bugs_test.dart` hit exactly that
failure during this stage (its `performAction(tap) … writes the DB` test hung
for 10 minutes and cascaded into 10 downstream failures and a ~10-minute file
run). I diagnosed it, reproduced it in isolation, and confirmed the BUGS stage's
own fix (10:34) resolves it — the file is green again. Recorded here because the
same trap is one copy-paste away in any feature test.

A second, smaller trap: `find.semantics.byLabel(String)` matches the label
**exactly**, and the stepper/day nodes are merged, so it finds nothing
(`Bad state: No element`); `find.semantics.byLabel(RegExp(...))` is the robust
form for merged nodes.

## Results

- `dart format --set-exit-if-changed` on my three files → clean (0 changed).
- `flutter analyze` (full app) → **No issues found!** (2.8s).
- `flutter test test/features/pocket_money/` → **+184: All tests passed!**
- `flutter test` (full app) → **+1526: All tests passed!**, exit 0, ~30s.
- Per file: bloc **+30**, repository **+15**, view **+97**, view-geometry
  **+6**, stepper-widget **+5**, bugs **+31**.
- Zero `skip:` anywhere in the feature, no `google_fonts`/`GoogleFonts`, no
  simulator used (only the UI stage may drive one). Scope:
  `app/test/features/pocket_money/**` + `docs/screens/P06/**`; `app/lib/`
  untouched.

## Bugs found

**None.** Every iteration-7 fix is covered by a passing test, and I found no
defect in the rewritten view, the coin-row layout change or the semantics
work.

### Verified fixed this iteration

- **ORCHESTRATOR 09:30 / review #1 (P06-BUG-13's cause)** — the three
  coin-alignment geometry tests I left red last iteration are now **green** in
  light, dark and at 430: the value's right edge equals the card content edge
  (`card.right − s4`, i.e. 354 at 390) within ±1 px, sharing that edge with the
  `+` buttons and the Sun pill.
- **P06-BUG-13** (the label truncating at 320 × 1.3 while the value took the
  room) — regression-pinned in all twelve real-font combinations by the new
  matrix assertion.
- **ORCHESTRATOR 09:42 / review #2** — all three option cards and all seven day
  cells expose `SemanticsAction.tap` (2b's tests) **and** now the four stepper
  buttons do too (my tests), with `performAction` proven to write the database
  for a stepper, an option card and a day cell.
- **review #6** — the option cards announce `checked` +
  `inMutuallyExclusiveGroup` (the HTML's `role="radiogroup"` of `role="radio"`),
  pinned in my view test.
- **review #4** — `watchSetup` now uses the canonical
  `AppDatabase.watchChildren` (insertion order preserved; the repository's
  insertion-order tests, including the `Anna` case, stay green).
- **review #5 / #8** — `_FailureBody` takes its message from the builder (so it
  no longer defeats `buildWhen`) and the radio dot diameter is a private
  constant instead of `NestSpacing.gap10`.
- **review #3 (shared)** — *not* a P06 finding per the 09:42 note and not
  failed here: the tap action on `NestButton`/`NestChip` (the Back chevron and
  the Continue CTA) is being fixed on `shared/semantics_tap`. My tests
  deliberately do not assert it for those two controls; everything P06 owns is
  covered.

## Coverage that did not change

Bloc/repo contract from iterations 3–5 (request-tracking accumulation, the
2000p/0p clamps, the pending-day guard, `clearErrorMessage`, `withChildBase`,
`ArgumentError` past the `assert`, mirrored `families`/`settings` writes,
insertion order) is unchanged and still green; the real-font matrix, the
day-row 32 px band geometry, the balanced-H1 guards, the bottom-edge pixel probe
and the 20 px alignment group all still pass.

## Open items for the orchestrator (not screen defects)

- **SHARED_REQUEST 4/5** — `NestStepper` U+2212 override (retire
  `p06_weekly_stepper.dart`) and the `NestChip` day variant (retire
  `_DayPill`): shared-code asks, neither blocking.
- **review #7** — the screen-authored empty-state copy
  `Add children to set weekly amounts.` has been awaiting ratification for four
  iterations; it renders only under `Seed.empty`/`Seed.fresh`.
- **Coin value at 320 dp** ellipsizes by design (`1_plan.md` §5); the sweep now
  asserts that fallback is present at 320 and absent from 390 up.

VERDICT: PASS