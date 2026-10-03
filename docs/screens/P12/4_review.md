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

VERDICT: FAIL
