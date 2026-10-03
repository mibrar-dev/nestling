# P12 · 3 TEST (iteration 1)

Route `/money`, feature `pocket_money`, parent mode. In-memory Drift DB
(`AppDatabase.memory()`) with `Seed.demo` / `Seed.empty`; the story day is
pinned to Sat 3 Oct 2026 by `test/flutter_test_config.dart`.

No production code was edited in this stage. No simulator was booted,
installed on, screenshotted or driven (stage 5 only). No images attached.

## Verdict in one line

**FAIL — one real defect (P12-BUG-05): the whole stack renders 16–21 px below
the design because of a spacer the design does not have. It is now pinned by
6 failing, un-skipped, real-font geometry tests.**

## Tests added (53 new, +6 red)

| File | Tests | Covers |
|---|---|---|
| `money_ledger_geometry_test.dart` **(new)** | 7 | Real-font geometry guard for the ORCHESTRATOR_NOTES 12:08 mandate: status bar 47, title top 55, segmented top 105 (+52 track height), owed card 173, goal card 400, history 504, and the empty body's title top. **6 of 7 fail** — the defect below. |
| `money_ledger_states_test.dart` **(new)** | 15 | Loading / failure / retry / empty-ledger / navigation / surfaces / semantics. |
| `money_ledger_responsive_test.dart` **(new)** | 24 | light+dark × 320/390/430 dp × text scale 1.0/1.3; owner ALIGNMENT (one 20 px gutter) and BOTTOM EDGE (pixel probe); ≥ 44 dp tap targets. |
| `pocket_money_ledger_bloc_test.dart` (extended) | 7 → 15 | The remaining event/state paths of `PocketMoneyBloc`. |

### `pocket_money_ledger_bloc_test.dart` (+8)

New fakes `_ScriptedLedgerRepository` (per-subscription scripted
`watchLedgerData`, writes recorded), `_ledgerData()` / `_entry()` fixtures.

- `PocketMoneyChildSelected` before the first load → **no emission at all**.
- Re-selecting the already-selected child → **no further emission**.
- The stream **drops the selected child** → selection falls back to the first
  child in creation order and `items` re-filter (no dangling `selectedChildId`).
- A family with **no children** → `loaded`, `selectedChildId == null`
  (`clearSelectedChildId`), `items` empty.
- A rejected **spending** submit keeps `status: loaded` and sets
  `errorMessage` (mirror of the add-money case).
- An **accepted** submit reaches the repository and emits **nothing**
  optimistically — the row only appears when the watch stream re-emits.
- **Retry** after a stream error re-subscribes and recovers, clearing the stale
  message.
- A load failure leaves **no pending timer**: `bloc.close()` completes inside
  5 s (the `_closeOnError` terminal-error contract).

### `money_ledger_states_test.dart` (new, 15)

Repository doubles (`_SilentLedgerRepository`, `_FlakyLedgerRepository`)
delegate every member to the real Drift repository, so only `watchLedgerData`
is scripted — writes/reads stay real.

- **Loading**: a silent stream shows `CircularProgressIndicator` and *no*
  ledger chrome (no hero, no `History`, no `Add money`) — no misleading £0.00.
- **Failure**: message shown, spinner gone, `Try again` exposes
  `SemanticsAction.tap` with a ≥ 44 dp rect, and `performAction(tap)` opens a
  **second subscription** (`repository.attempts == 2`) that recovers into the
  real seeded ledger (`£4.20`, `Maya is owed`), message cleared.
- **Failure repeated** three times → still the failure body, 4 subscriptions,
  no crash.
- **Empty ledger for one child** (Leo's rows deleted from the real DB):
  `£0.00` hero, `Weekly base £0.00 + quests £0.00 · Next payout …`,
  `No history yet` inside the history card, no goal card, row buttons still
  live and the sheet title is `Record spending for Leo`.
- **Navigation**: `Payout time` **pushes** `/payout` (not `go` — the ledger is a
  tab root) and `pageBack()` restores `/money` with state intact; **every** tab
  bar item routes to its own branch (`Today`→`/today`, `Quests`→`/quests`,
  `Family`→`/child-profile`, `Money`→`/money`) and the ledger state survives
  every switch; the segment is **not** a navigation (`pushedPath` stays
  `/money`).
- **Child order** ruling: `Maya` renders left of `Leo` (alphabetical would be
  the reverse).
- **Sheet semantics**: `Amount` / `Note` fields are labelled, hints `£0.00` /
  `e.g. Birthday money` render, and a rejected amount shows
  `Enter an amount like £1.00` with the sheet **stays open**.
- **Surfaces (light + dark)**: the hero card's painted `BoxDecoration.color` is
  `tokens.heroBg` (and `heroBg != ink` in dark, so the probe discriminates);
  the history card paints `tokens.surface`, `surface != paper`.
- **Progressbar**: the goal announces `Savings goal progress` + `62 percent`
  and exposes **no** tap action (display-only card).
- **Icon-only button**: the sheet's close glyph is labelled `Close`, exposes
  `SemanticsAction.tap` on a ≥ 44 dp rect, is the only `Close` node, and the
  semantics action really dismisses the sheet.

### `money_ledger_responsive_test.dart` (new, 24)

- **Copy/overflow**: light+dark × 320/390/430 dp × text scale 1.0/1.3 — every
  screen's copy present, `tester.takeException()` null (no `RenderFlex
  overflowed`).
- **ALIGNMENT (owner rule)**: light+dark × 320/390/430 — the title, segmented
  track, hero card, goal card and history card all start at x = 20 and end at
  `width − 20`; the two row buttons are equal halves split by exactly 10 px
  (`.rowbtns gap`) and the footer caption is centred on the same column.
- **BOTTOM EDGE (owner rule)**: light+dark × OS inset 0/34 — `NestTabBar` ends
  at y = 844, spans x 0…390, and a rendered-pixel probe at (195, 843) equals
  `tokens.surface` and is **not** `tokens.paper` (no coloured strip around the
  home indicator in either theme).
- **Tap targets** at 320/430 dp: both segment options, `Payout time` (≥ 52 per
  `.hero .btn`), `Add money`, `Record spending`, the sheet CTA (≥ 52) and the
  sheet close all expose `SemanticsAction.tap` and keep a ≥ 44 dp target.
  *Kid-mode ≥ 56 dp is N/A: `/money` exists only in the parent shell — there is
  no kid-mode route for this screen.*

## Results

```
$ dart format .
Formatted 435 files (0 changed) in 1.89 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.1s)

$ flutter test
00:46 +1880 ~5 -6: Some tests failed.
```

Per file:

```
money_ledger_states_test.dart         +15: All tests passed
money_ledger_responsive_test.dart     +24: All tests passed
pocket_money_ledger_bloc_test.dart    +15: All tests passed
money_ledger_geometry_test.dart        +1 -6: Some tests failed   ← the defect
```

`test/features/pocket_money` overall: 292 → 318 tests, all green except the 6
geometry guards. Everything else in the repo (1880 passed, 5 skipped) is
untouched — the only failures are the new geometry guards.

The pre-existing "created the database class AppDatabase multiple times"
drift `WARNING`s in the raw output are the known notices from
`test_scope.dart` (they appear in main's runs too); they are not failures.

## BUG FOUND — P12-BUG-05 (major): the stack sits 16–21 px below the design

**Where:** `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart:141`
(the loaded body) and `:378` (the empty body) — both insert

```dart
const NestStatusBar(),
const SizedBox(height: NestSpacing.s4),   // ← line 141 / 378: not in the design
const _PageTitle(),
```

**Why:** `design/html-source/components.css` puts a 16 px gap between
siblings with `.scroll > * + * { margin-top: var(--s4) }` — the **first** child
of `.scroll` gets none, and `.ptitle` supplies its own `padding-top: 8px`. So
the design is `47 (status) + 8 (.ptitle padding) + 34 (h1 line box) + 16
(sibling gap) = 105` for the segmented track, which the design PNG confirms to
the pixel (the track's `--surface-2` begins at exactly 315 px = 105.0 dp). The
app adds a `SizedBox(s4)` *above* the title, so every element below it is
16 px low.

**Evidence** — design PNG (`1170×2532 ÷ 3`) scanned pixel-wise vs the app
measured in a real-font widget test at 390×844:

| anchor | design | app | delta |
|---|---|---|---|
| status bar reserve | 47 | 47 | 0 ✔ (the probe passes, so the harness is sound) |
| title line-box top | 55 | **71** | +16 |
| segmented track top | 105.0 | **121** | +16 |
| owed (hero) card top | 173.0 | **189** | +16 |
| owed card height | 211 | **214** | +3 |
| goal card top | 400.0 | **419** | +19 |
| goal card height | 88 | **90** | +2 |
| history card top | 504.0 | **525** | +21 |

Design values were measured from `design/screens/light/P12-money.png`
(segmented surface-2 at 315 px, hero ink at 519 px, goal white at 1200 px,
history white at 1512 px, title ink 183–258 px) and cross-checked against the
CSS arithmetic above. The app numbers are the six failing assertions in
`money_ledger_geometry_test.dart`, run with the bundled Inter/Nunito loaded.

**Repro**

```
cd app
flutter test test/features/pocket_money/money_ledger_geometry_test.dart
```

Fails with `Expected: 55.0 (±1.0) Actual: <71.0>` (title), `105/121`
(segmented), `173/189` (owed card), `400/419` (goal card), `504/525` (history),
and the same +16 for the empty state's title.

**Note on the orchestrator note's own numbers.** The 12:08 note says "title
baseline band: design ≈ 72 → app ≈ 88 (+16) … segmented design ≈ 106". The
+16 delta and the "extra 16 px above the title" diagnosis are exactly right,
but its absolute design figures are ~16–17 px high for the title (measured 55
for the line box / 61 for the ink, not 72) and 1 px high for the segmented
track (105, not 106). The pinned values in
`money_ledger_geometry_test.dart` therefore use the measured PNG/CSS values;
after the fix the title lands at 55 and the track at 105.

**Fix for the build stage (NOT applied here — a test stage records, it does
not patch the screen):** delete `const SizedBox(height: NestSpacing.s4),` at
line 141 and line 378. That removes the global +16 and is what un-skips this
geometry guard (`6_bugs.md` P12-BUG-05 asks for exactly this).

**Residual after that fix** (measured now, so the next iteration does not have
to rediscover it): the owed card renders 214 tall against the design's 211
(+3) and the goal card 90 against 88 (+2), so the goal/history tops will still
be ~3 px / ~5 px low until those two card heights are reconciled with the
HTML (`4_review.md` finding 2 measures the same +3/+2). They are deliberately
**not** pinned here — the mandate asks for the tops, and the same five
assertions will re-report the residual once the +16 is gone.

## Corroboration / not-a-bug notes

- `4_review.md` (major finding 1) and `6_bugs.md` (P12-BUG-05, MAJOR)
  independently report the same defect with the same numbers. The bugs stage
  left its geometry test `skip: true`; `money_ledger_geometry_test.dart` is
  the un-skipped equivalent the note asks for.
- `NestProgress` sets its label without `container: true`, so Flutter merges
  the node into the goal card's column: the screen reader hears
  `Lego Friends set — £24.99 / £15.50 saved · 62% / Savings goal progress /
  62 percent`. The required label and value are both announced (the test
  asserts containment); this is the same `NestCard` merge the hero shows, and
  2b already flagged it as a design-system note, not a P12 fix. Left as-is.
- `Payout time`'s semantics node merges the whole hero card into one button
  (`Maya is owed / £4.20 / … / Payout time for Maya`), inherited from shipped
  P08. It is operable and labelled; 2b's observation stands.
- Design copy differences (`Sat 4 Oct` vs the DB's `Sat 3 Oct`, four history
  rows vs the DB's rows) are DATA OVER MOCKS — not findings, and the copy
  audit in `money_ledger_view_test.dart` still passes character-by-character
  (`—` U+2014, `·` U+00B7, `−` U+2212, `→` U+2192, no ASCII hyphen anywhere).
- No `google_fonts` import or `GoogleFonts.*` call in the feature or its tests.
- CHILD ORDER, STATUS BAR, PERIODS, TRIAL, BOTTOM EDGE, ALIGNMENT and the
  ACCESSIBILITY-ACTIONS rule were all checked; the ones that apply to a
  parent-mode ledger screen are covered by tests above.

## Scope

`git status --porcelain` shows only `app/test/features/pocket_money/**` (4
files, mine) plus this note. No `app/lib/**`, no `app/lib/core/**`, no
`app/lib/app/**`, no other feature, no `tools/screens/**`. No
`flutter clean`, no interactive `flutter run`, no simulator, `analysis_options`
untouched.

VERDICT: FAIL
