# Fix list after iteration 1

## From 3_test.md
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


## From 4_review.md
# P12 · Money (ledger) — Stage 4 QA code review (iteration 1)

Scope: `git diff main...HEAD` (35 files) for screen P12 / feature
`pocket_money` / route `/money`. Reviewed against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P12,
`design/html-source/screens/P12-money.html` (copy source of truth),
`design/screens/{light,dark}/P12-money.png` (1170×2532 → ÷3 = 390×844), the
design system in `app/lib/core/design_system/`, and `1_plan.md`.
**No code was edited in this stage.** No simulator was booted, installed on,
driven or screenshotted; no image was attached (PNGs were read, never
uploaded).

Design geometry used below was measured directly from
`design/screens/light/P12-money.png` by scanning rows/columns for the fills
the HTML specifies (`--paper` #FBF7F0, `--surface` #FFFFFF, `--hero-bg`
#1E1B3A, `--leaf` #17804F, `--leaf-tint` #E3F5EC). These reproduce the CSS
exactly: status bar 47 (`.status-bar{height:var(--status-h)}`), title line box
55..89 (`.ptitle{padding-top:8}`), segmented track 105.0 h 52 with a
169-wide thumb at x 24, hero fill 173.0..384.0 x 20..370, `Payout time` fill
x 40 w 310 y 312 h 52, goal card fill 400.0..488.0, history card top 504.0,
tab bar 726..810.

Independent gates re-run in this worktree: `dart format
--output=none --set-exit-if-changed .` and `flutter analyze` (results in
"Process notes" — the only diagnostics are in untracked files a sibling stage
is writing right now).

## Result

**3 major findings — all three are design-geometry defects that the
orchestrator's own measurement already flagged. VERDICT: FAIL.**

| # | Severity | Subject |
|---|---|---|
| 1 | **major** | Whole screen sits 16 px below the design (extra spacer after `NestStatusBar`) |
| 2 | **major** | Goal card is 2 px too tall (`bodyStrong` 24 vs the CSS's 22 line box) |
| 3 | **major** | History tile corner radius is 12 px; the design's `.icon-tile` is 16 px |
| 4 | minor | Hero card still +3 px vs the PNG after 1–3 — measure, do not guess |
| 5 | minor | Sheet validation error is not a live region |
| 6 | minor | Success toast fires before the write is confirmed |
| 7 | minor | Raw `error.toString()` rendered to the parent |
| 8 | minor | `domain/next_payout.dart` breaks the `domain/` contract |
| 9 | minor | Test-only `ledgerDataFallback` shipped in production domain code |
| 10 | minor | `MoneyLedgerData.setup` couples the ledger aggregate to P06 |
| 11 | minor | `BlocBuilder` without `buildWhen` rebuilds every history row |
| 12 | minor | `.ptitle` has no shared component (4 screens need it) |
| 13 | minor | `state.items` semantics changed for the shared bloc (P13 hand-off) |

---

## 1. MAJOR — the whole screen is 16 px below the design

**File:** `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart:141`
(same defect in the empty state at `:378`).

```dart
const NestStatusBar(),
const SizedBox(height: NestSpacing.s4),   // ← not in the design
const _PageTitle(),
```

`P12-money.html:18-20` puts `.status-bar` **outside** `.scroll`:

```html
<div class="screen parent">
  <div class="status-bar">…</div>
  <div class="scroll">
    <div class="ptitle">Pocket money</div>
```

so `.scroll > * + * { margin-top: var(--s4) }` (`components.css:66`) does
**not** apply to `.ptitle` — it is the first child — and its only top spacing
is `.ptitle{padding-top:8px}`. The design therefore puts the title line box at
47 + 8 = **55**; the app puts it at 47 + 16 + 8 = **71**.

Measured against `design/screens/light/P12-money.png`:

| Element | design (÷3) | app (code) | Δ |
|---|---|---|---|
| title line box top | 55 | 71 | +16 |
| segmented track top | 105.0 | 121 | +16 |
| hero card top | 173.0 | 189 | +16 |
| goal card top | 400.0 | 419 | +19 (= +16 and finding 2) |
| history card top | 504.0 | 525 | +21 (+16, +3 hero, +2 goal) |

This reproduces `ORCHESTRATOR_NOTES.md` exactly (title 72→88, segmented
106→121, hero 173→189, goal 400→419, history 504→525), so the notes' "find
the extra 16 px above the title" is this line and no other. Side effects:
the history card bottom lands at 807 instead of 788, so the fold cuts the
third history row ~6 px earlier than the design, and the whole 10.46 % mean
diff is dominated by a constant translation.

**Fix:** delete the `const SizedBox(height: NestSpacing.s4),` that follows
`const NestStatusBar()` in both `_LoadedBody` (`:141`) and `_EmptyBody`
(`:378`). Every other gap on the screen is already an `s4` separator, which
is exactly the design's `.scroll > * + * { margin-top:16px }` — no other
separator changes.

## 2. MAJOR — the goal card is 2 px too tall

**File:** `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart:342`

The design's goal title is `P12-money.html:11`
`.goal .t{font-weight:700;font-size:16px;line-height:22px}` — a **22 px**
line box. `NestType.bodyStrong` is 16/**24**
(`core/design_system/tokens/typography.dart:69`). The column is
`24 + 18 (caption) + 8 (progress margin) + 8 (NestProgress) = 58` where the
design has `22 + 18 + 8 + 8 = 56`; the row is `max(56 art, column)`, so the
card is 90 instead of 88.

Measured: design goal card fill `400.0..487.67` = **88**. App = 90. This is
the "one more +5 inside the stack" the notes mention (it turns +19 into +21
on the history card top) and it is the only inner delta that is
attributable to a token mismatch.

**Fix:** override at the call site, following the pattern the orchestrator
mandated for `.hero .amt`'s `-0.4`:

```dart
style: NestType.bodyStrong(color: tokens.ink).copyWith(height: 22 / 16),
```

(or file a `SHARED_REQUEST.md` for a 16/22 `bodyStrong` variant if other
screens need it — do not edit `core/` from here).

## 3. MAJOR — history tile corner radius is 12 px, the design says 16 px

**File:** `app/lib/features/pocket_money/presentation/widgets/money_history_row.dart:69`

```dart
borderRadius: BorderRadius.circular(NestSpacing.s3),   // 12
```

`components.css:110` is `.icon-tile { width:40px; height:40px;
border-radius: var(--r-m) }` and `tokens.css:77` is `--r-m:16px`. A circle
fit on the design PNG's first tile (fill x 36.0..75.7, y 556.0..595.7,
`--leaf-tint` #E3F5EC) reproduces **r = 16** to < 0.2 px over 15 rows
(predicted vs measured left edge: y+1 46.43/46.33, y+3 42.67/42.67,
y+8 38.14/38.00, y+12 36.51/36.67); r = 12 is off by up to 3.1 px. So all ten
history tiles are 4 px too square — and `NestSpacing.s3` is a *spacing*
token: the design system has no 12 px radius at all (`--r-s:10 --r-m:16
--r-l:24 --r-xl:32`), so the wrong token family is being used as well.

Where the 12 came from: `core/design_system/components/nest_list_row.dart:65`
applies P02's **compact 36 px** tile radius (`P02-value-tour.html:25`
`.pg-rows .icon-tile{width:36px;height:36px;border-radius:12px}` — its own
doc comment at `nest_list_row.dart:32` attributes 12 to the compact variant)
to the standard 40 px tile as well. `MoneyHistoryRow` correctly mirrors the
shared `NestTileTint` mapping, but should not mirror that radius.

**Fix (local, RULES-legal):** `borderRadius: NestRadii.allM` in
`MoneyHistoryRow`. **Also** file `SHARED_REQUEST.md` for
`nest_list_row.dart:65` so the compact radius is split from the standard one
— every other screen's tiles are 4 px off for the same reason.

## 4. MINOR — the hero card is still +3 px after 1–3; measure, don't guess

**File:** `money_ledger_view.dart:158-195`. The app's stack computes
`20 + 20 (lab) + 44 (amt) + 4 + 40 (brk × 2 lines) + 14 + 52 (btn) + 20 =
214`; the PNG fill is `173.0..384.0` = **211**. `ORCHESTRATOR_NOTES.md`
reconciles to `189 + 214 + 16 = 419` (goal top) and `419 + 90 + 16 = 525`
(history top), so the app's +21 is fully explained by `+16` (finding 1),
`+3` (hero) and `+2` (goal).

The 3 px cannot be attributed from the source: `P12-money.html:2` links only
`tokens.css` + `components.css` and no webfont, so the PNG's text line boxes
were laid out with fallback metrics (the glyph bands inside the card do not
match Inter's real ascent/descent). **Do not** nudge `NestType` line-heights
or add padders to force it. Re-measure after findings 1–3 and either close
the residual with a measurement or record it as a design-render artefact;
the notes' "±1 px" mandate cannot be signed off until it is resolved one way
or the other.

## 5. MINOR — the sheet's validation error is not announced

**File:** `app/lib/features/pocket_money/presentation/widgets/money_edit_sheet.dart:97-105`.
The inline error appears after a tap with no `liveRegion`, so VoiceOver /
TalkBack users get no notification that the amount was rejected (the sheet
stays open with the reason off-screen or unannounced).
**Fix:** `Semantics(liveRegion: true, child: Text(error, …))`.

## 6. MINOR — the success toast is fired before the write is confirmed

**File:** `money_ledger_view.dart:288-309`. `onSubmit` calls
`bloc.add(PocketMoneyAddMoneySubmitted(…))` and then immediately
`showNestToast('Added £5.00 for Maya')`. If the write throws, the user sees
"Added £5.00 for Maya" followed by the raw error toast from finding 7.
**Fix:** either `await` the repository call before popping/toasting (moving
the write out of the sheet), or have the bloc emit a one-shot confirmation
the view toasts on state change (as it already does for errors at
`money_ledger_view.dart:43-48`).

## 7. MINOR — raw exception text is rendered to the parent

**File:** `pocket_money_bloc.dart:85` (load), `:217`, `:233` (submits).
`error.toString()` becomes `errorMessage`, which `_FailureBody`
(`money_ledger_view.dart:412`) prints and the toast (`:48`) shows verbatim —
a Drift/SQLite message on a parent-facing screen. This is the inherited P06
pattern, but P12 is a new surface.
**Fix:** map to a friendly "We couldn't load your ledger" style message and
keep the raw string for logs.

## 8. MINOR — `domain/next_payout.dart` breaks the `domain/` contract

`ARCHITECTURE.md` §"Per-feature contract": `domain/` = *entities + abstract
`<feature>_repository.dart` ONLY*. `next_payout.dart` is the only non-entity,
non-repository file in any feature's `domain/` (checked across all 19
features). Its two top-level functions are presentation formatting
(`formatDay` lives in `core/data/family_time.dart`).
**Fix:** move it under `presentation/` (it is used only by
`money_ledger_view.dart` and its test), or fold `payoutLabel` into the
entity and file a `SHARED_REQUEST.md` for a shared payout-day helper, since
P13 will need the same label.

## 9. MINOR — a test-only helper ships in production domain code

**File:** `app/lib/features/pocket_money/domain/pocket_money_repository.dart:66-156`
— `ledgerDataFallback` plus `_owedFromEntries` and a private
`_combineLatest2`. Grep confirms the only callers are three **test** fakes
(`p06_bugs_test.dart:136`, `pocket_money_setup_bloc_test.dart:82`,
`pocket_money_setup_view_test.dart:69/:436`). `ARCHITECTURE.md` puts fakes
and models under `data/`; a domain file that implements stream plumbing (and
a second, feature-local `combineLatest` next to `core/data/stream_combine.dart`)
inverts the dependency direction.
**Fix:** move the three helpers to `app/test/features/pocket_money/`
(a shared test helper) and keep `domain/pocket_money_repository.dart`
abstract-only.

## 10. MINOR — `MoneyLedgerData.setup` couples the ledger aggregate to P06

**File:** `domain/entities/money_ledger_data.dart:11,41-48,88`. A
P12-named entity carrying `PocketMoneySetup?` means every setup edit
(mode / payout day / weekly base) lands in `props` and re-emits
`MoneyLedgerData`, rebuilding the whole ledger for a change the ledger does
not display. It works and it is additive, which is why it is minor.
**Fix (optional):** serve `PocketMoneySetup` from its own stream/aggregate so
the ledger aggregate only carries what `/money` renders.

## 11. MINOR — `BlocBuilder` without `buildWhen`

**File:** `money_ledger_view.dart:49`. A failed submit changes only
`errorMessage`, which the `BlocListener` already consumes, yet the entire
`ListView` (title, segmented, hero, goal card and every history row) rebuilds.
**Fix:** `buildWhen: (p, c) =>
p.status != c.status || p.data != c.data || p.selectedChildId != c.selectedChildId`.
The sibling P06 view already does this (`pocket_money_setup_view.dart:51`).

## 12. MINOR — `.ptitle` has no shared component

**Files:** `money_ledger_view.dart:74-92` (private `_PageTitle`).
`.ptitle` appears in `P10-quest-library.html`, `P12-money.html`,
`P13-payout.html` and `P16-settings.html` — four screens, one private
re-implementation, and finding 1 shows how easily the top spacing drifts.
**Fix:** file `SHARED_REQUEST.md` for a `NestPageTitle` (28/34 w900,
`padding-top: 8`, `Semantics(header: true)`, `maxLines: 1` + ellipsis) so
the four screens share one source.

## 13. MINOR — `state.items` semantics changed under the shared bloc

**Files:** `pocket_money_bloc.dart:79` and `:195`. `items` is now the
**selected** child's ledger (`data.entriesFor(selectedChildId)`); before this
diff it was `watchItems()` = the active child's ledger
(`data/pocket_money_repository_impl.dart:26-32`). `payout_view.dart:24-30`
(P13) reads `state.items`, so when P13 is built its list will silently follow
whichever child the parent last selected on `/money` instead of the active
child. No current test fails (P13 is still a placeholder), which is exactly
why it needs to be in P13's hand-off.
**Fix:** add a note to P13's brief, or keep `activeChildItems` alongside
`items`.

---

## Verified clean (no finding)

- **Scope / RULES.md §1.** `git diff main...HEAD --stat` touches only
  `app/lib/features/pocket_money/**`, `app/test/features/pocket_money/**`
  and `docs/screens/P12/**`. No `app/lib/core/**`, no `app/lib/app/**`, no
  other feature, no `tools/screens/**`, no `analysis_options.yaml`.
- **Copy, character by character, against `P12-money.html`.** "Pocket
  money", "Maya is owed", "Weekly base £3.00 + quests £1.20 · Next payout
  <date>", "Payout time", "Lego Friends set — £24.99" (U+2014),
  "£15.50 saved · 62%" (U+00B7), "History", "Paid · Sat 27 Sep",
  "Cash from Mum", "Quest bonus · …", "+12p · Approved", "Birthday money
  (added by Mum)", "To savings goal", "Spent · Comic", "Recorded by Mum",
  "−£2.00" (U+2212), "+£0.12", "£3.80" (payout unsigned), "Add money",
  "Record spending", "Nestling keeps track — the real money stays with
  you." (U+2014). The design's hard-coded "Sat 4 Oct" is correctly replaced
  by the DB/clock value (DATA OVER MOCKS). UK spelling throughout ("Mum",
  "£", no US forms). `kMoneyMinus`/`kMoneyDot`/`kMoneyEmDash` are named
  constants, and the view test asserts no ASCII hyphen survives anywhere on
  the route.
- **Design-system reuse.** `NestStatusBar`, `NestType`, `NestSegmented`,
  `NestCard(variant: hero)`, `NestButton`, `NestProgress`, `NestEmptyState`,
  `NestTextField`, `showNestBottomSheet`, `showNestToast`, `NestIcon` and the
  shared `NestTileTint` are all reused; nothing is re-implemented, no colour
  literal, no font family, no `GoogleFonts`, no `NestChip`/`Wrap`
  (no chips on this screen), no `NestBalancedText` (no `text-wrap:balance`
  in the P12 CSS). Only `NestSpacing`/`NestRadii`/`NestDevice`/`NestType`
  values are used, with two documented screen-local consts (`.hrow`
  min-height 56, `.goal img` 56) that match the CSS and follow the existing
  `NestPager` convention. Letter spacing: `kidHero.copyWith(letterSpacing:
  -0.4)` at the hero only, exactly the known P12 case; no Material tracking
  anywhere else. Dark mode has zero theme branches — every colour via
  `context.nest`, the hero paints `heroBg`/`onHero`/`onHero2` (never `ink`).
- **Tokens and dark geometry.** Side gutters 20 everywhere, cards/bars share
  x 20..370, hero button fills x 40 w 310 h 52, `Payout time` 52, row
  buttons 48 with `fontSize: 15`, segmented 52 track / 44 options (the
  `1_plan.md` watch-item is resolved in `NestSegmented`, no local padding
  needed), progress 8 px. BOTTOM EDGE is safe: `ParentShell` +
  `NestTabBar` paint `surface` through `SafeArea` to the physical edge, so
  no paper strip appears under the bar in either theme.
- **CHILD ORDER.** `watchChildren` orders by `createdAt` then `rowid`
  (`app_database.dart:457-469`) and `watchLedgerData` maps that list as-is,
  so Maya precedes Leo in the segment, the oweds and the goals. Asserted in
  the repository test.
- **Accessibility / RULES §8.** Every control exposes `SemanticsAction.tap`
  and is operable: both segment options (44 px), `Payout time` (52),
  `Add money` / `Record spending` (48), sheet CTA (52), sheet close (44),
  empty-state `Add a child` (52), `Try again` (52). No
  `Semantics(excludeSemantics: true)` wrapper without `onTap:` anywhere in
  the diff; the tile/coin art is `ExcludeSemantics` display-only; the goal
  progress carries `semanticLabel: 'Savings goal progress'` +
  `value: '62 percent'`; the toast is a live region. `performAction(tap)`
  is asserted to change real state (segment → hero re-renders) and the real
  DB (sheet CTA → new ledger row) in
  `money_ledger_view_test.dart:399-476`. Width 320 × text scale 1.3 is
  covered with `takeException() isNull` (`:524-542`).
- **Streams and lifecycle.** One `emit.forEach` per load, cancelled by the
  bloc; `_combineLedgers` cancels all N subscriptions in `controller.onCancel`
  and `asyncExpand` cancels the inner graph on a roster change; the P06
  `_pendingDay` / `_requestedBase` bookkeeping is preserved. Both
  `TextEditingController`s and the `NestButton` focus nodes are disposed. No
  `Timer`, no `AnimationController`, nothing to gate for
  `DISABLE_ANIMATIONS`.
- **Error handling.** Load failure → `_FailureBody` with the only legal
  retry; submit failure keeps the ledger on screen and toasts (does not blank
  the screen) — better than the P06 write path, and the tests cover the
  load path.
- **Routing / DI.** `/money` is a tab root, so both pushes use
  `context.push` (`money_ledger_view.dart:191`, `:388`), never `go`; the
  route constants come from `PocketMoneyRoutePaths` / `FamilyRoutePaths`;
  no shared DI or router file was touched.
- **Children's Code.** Parent-only screen; no analytics, ads, network calls,
  or child identifiers leaving the device; no kid-mode code path touched.
- **Tests.** 544-line widget suite, plus repository (24), `next_payout` (7)
  and ledger-bloc suites; every `pumpAppRoute` test ends with
  `disposeApp(tester)`; no `skip:`, no weakened expectations, no
  `analysis_options.yaml` change.

## Process notes (explicitly NOT findings)

`flutter analyze` currently reports 54 diagnostics, all inside
`app/test/features/pocket_money/{p12_probe_test.dart, p12_probe2_test.dart,
p12_probe3_test.dart, money_ledger_states_test.dart}` and one modified
`pocket_money_ledger_bloc_test.dart` — untracked/uncommitted scratch from the
sibling `5_ui`/`6_bugs` stages writing into this same worktree while this
review ran (mtimes 12:05–12:08, after this stage started). Per the brief,
uncommitted work is a process item: the loop commits each iteration. The
committed tree (`git diff main...HEAD`) is analyzer-clean apart from finding 3.
`docs/screens/P12/ORCHESTRATOR_NOTES.md` (12:08) and `5_ui.md` were also
written during this review; every item in the notes is treated as mandatory
and findings 1, 2 and 4 above cover it.

## Handed to the next stage

1. Fix findings 1–3 (three one-line edits), then re-shoot light + dark and
   re-run `compare.py`; the expected design targets are listed in the tables
   above (title 55, segmented 105, hero 173, goal 400 h 88, history 504,
   tile radius 16).
2. Add the real-font geometry test the notes ask for: pin the title,
   segmented, hero, goal-card and history-card **tops** (plus the goal card
   height 88 and a history-tile radius assertion), so the ±1 px requirement
   is enforced by `flutter test` and not only by the band table.
3. File `SHARED_REQUEST.md` for the `nest_list_row.dart:65` tile radius
   (compact 12 vs standard 16) and, if convenient, for a shared
   `NestPageTitle`; both are cross-screen and cannot be fixed from here.
4. Findings 5–13 can ride along in the same iteration.


## From 6_bugs.md
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

