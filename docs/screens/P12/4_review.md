# P12 · Money (ledger) — Stage 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` (61 files, 24 of them code) for screen P12 /
feature `pocket_money` / route `/money`. Reviewed against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P12,
`design/html-source/screens/P12-money.html` (copy source of truth),
`design/html-source/{components,tokens}.css`,
`design/screens/{light,dark}/P12-money.png` (1170×2532 → ÷3 = 390×844), the
design system in `app/lib/core/design_system/`, `1_plan.md`,
`ORCHESTRATOR_NOTES.md`, `SHARED_REQUEST.md` and iteration 1's `4_review.md`
/ `6_bugs.md`.

**No code was edited in this stage. No simulator was booted, installed on,
driven or screenshotted; no image was attached** (PNGs and CSS were read, never
uploaded).

Gates re-run in this worktree (read-only, host VM — no simulator):

```
$ dart format --output=none --set-exit-if-changed .
Formatted 436 files (0 changed) in 1.49 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 11.9s)

$ flutter test test/features/pocket_money/{geometry,view,states,responsive,bugs,
    ledger_bloc,repository,next_payout,p06_bugs}_test.dart
00:06 +155 ~1: All tests passed!        ← the ~1 is the documented P12-BUG-04 skip
```

## Result

**1 major finding — the 47 px status-bar band scrolls away with the ledger
instead of staying pinned above it, which the design does pin and which every
other screen built so far pins. VERDICT: FAIL.**

All three iteration-1 majors are genuinely closed and are now pinned by a
real-font geometry suite that passes.

| # | Severity | Subject | Status |
|---|---|---|---|
| 1 | **major** | Status-bar reserve is `ListView` child 0, so it scrolls away (design + P05/P06/K03 pin it) | new |
| 2 | minor | The sheet hand-rolls the inline error instead of using `NestTextField.errorText` | new |
| 3 | minor | Write-confirmation toast can be lost or misattributed across a child switch | new |
| 4 | minor | `summarise()`'s `break`-at-payout assumes strict newest-first; same-second ties | new |
| 5 | minor | `domain/next_payout.dart` is still not an entity or the abstract repo | carried (it-1 #8) |
| 6 | minor | `_PageTitle` is still the 4th private copy of `.ptitle` | carried (it-1 #12) |
| 7 | minor | Raw exception text still reaches the parent after the friendly lead | carried (it-1 #7, partial) |
| 8 | minor | `state.items` is now the *selected* child's ledger and P13 reads it | carried (it-1 #13) |
| 9 | minor | `MoneyLedgerData.setup` couples the ledger aggregate to P06 | carried, declined with reason (it-1 #10) |
| it-1 1 | ~~major~~ | 16 px uniform shift | **closed** — see below |
| it-1 2 | ~~major~~ | Goal card 90 px instead of 88 | **closed** |
| it-1 3 | ~~major~~ | History tile radius 12 instead of 16 | **closed** |
| it-1 4 | minor | Hero +3 px | **closed by measurement** (17 px `.lab` line box) |
| it-1 5/6/9/11 | minor | liveRegion / premature toast / test helper in `domain/` / missing `buildWhen` | **closed** |

---

## 1. MAJOR — the status-bar band scrolls away instead of staying pinned

**Files:** `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart:267`
(`_LoadedBody`), `:527` (`_EmptyBody`); the widget itself is at `:286` and
`:533`.

```dart
return ListView(
  padding: _scrollPadding,
  children: <Widget>[
    const NestStatusBar(),   // ← child 0 of the SCROLL VIEW
    const _PageTitle(),
    …
```

`P12-money.html:17-20` is a **flex column with the bar outside the scroller**:

```html
<div class="screen parent">
  <div class="status-bar">…</div>
  <div class="scroll">      <!-- .scroll { flex:1; overflow-y:auto } -->
```

with `components.css:46` `.status-bar { min-height:47px; flex-shrink:0 }` and
`components.css:65` `.scroll { flex:1; overflow-y:auto; min-height:0 }`. So in
the design the 47 px band is **pinned**: history rows scroll inside the
viewport below it and can never reach the clock.

In the app the reserve is the first row of the scrollable, and neither the
`Scaffold` body nor `ParentShell` applies a top inset
(`lib/app/router.dart:32-44` has no `SafeArea`; there is no global
`SystemUiOverlayStyle`/`edgeToEdge` handling in `lib/app/**`). So as soon as the
parent scrolls the ledger, the reserve — and the title with it — move up and the
white history cards are painted at y < 47, underneath the OS-drawn status bar.
The ledger is longer than the fold by design (the row buttons and footer are
below it), so this is reached by ordinary use, not by an edge case.

It is also the outlier in the codebase: every screen built so far reserves the
band **outside** its scrollable — `P05 add_children_view.dart:87`
(`Column[NestStatusBar, NestNavBar, Expanded(…)]`), `P06
pocket_money_setup_view.dart:43`, `K03 kid_home_view.dart:236`/`:280`, and P08
`today_view.dart:20` (`SafeArea`). P12 is the only one that scrolls it away.
`NestStatusBar` itself is fine and shared
(`nest_chrome.dart`: `height: max(viewPadding.top, NestDevice.statusH)`), so on
a 59 px-inset device the band still measures correctly — the defect is purely
that it is inside the scroller.

**Impact:** visible content under the OS clock in the most-used interaction on
the screen, plus a divergence from the design's flex layout that no screenshot
at scroll-0 can reveal (which is why it survived two UI passes).

**Fix (RULES-legal, no geometry change at rest):** pin the band like P05/P06/K03.

```dart
return Column(
  children: <Widget>[
    const NestStatusBar(),                  // pinned band outside the scroller
    Expanded(
      child: ListView(
        padding: _scrollPadding,
        children: <Widget>[
          const _PageTitle(),               // still 55 … at rest
          …
```

Drop the `NestStatusBar()` child from both bodies. `_PageTitle` keeps its own
`padding-top: s2`, so title 55 / segmented 105 / hero 173 / goal 400 / history
504 are unchanged and `money_ledger_geometry_test.dart` stays green.

**Guard to add** (the at-rest assertions cannot catch this): scroll the list by
120 px and assert no descendant paints above the band —
`tester.getRect(find.byType(MoneyHistoryRow).first).top` stays `≥ 47`, or assert
`tester.getRect(find.byType(ListView)).top == 47`.

## 2. MINOR — the sheet re-implements the inline error instead of using the shared one

**File:** `app/lib/features/pocket_money/presentation/widgets/money_edit_sheet.dart:114-146`

The Amount field is a plain `NestTextField` (`:114-123`) and the rejection
message is a hand-rolled `SizedBox` + `Semantics(liveRegion: true)` + `Text`
placed **below the Note field** (`:131-146`). The shared component already does
exactly this job: `nest_text_field.dart:11-14` documents
"`errorText` paints the invalid state: a 2 px danger border on the field plus a
gutter-aligned error row below it … announced through a live region", and
`:329-336` implements it (`Semantics(liveRegion: true, label: errorText, …)`).

Consequences: the Amount field never gets the shared invalid border, and the
message "Enter an amount like £1.00" / "Enter an amount up to £1,000,000.00"
renders under the *Note* field, spatially detached from the input it is about —
a VoiceOver/TalkBack user hears it, a sighted user looks in the wrong place.
"Never re-implement components" (brief) is the rule being bent here.

**Fix:** pass `errorText: _error` to the Amount `NestTextField` and delete the
`:131-146` block (and the now-unused `NestSpacing.s3`/`tokens.danger` there).
Keep the same three strings and keep clearing `_error` in `onChanged`.

## 3. MINOR — the write-confirmation toast can be lost or attributed to the wrong child

**File:** `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart:46`,
`:70-89`, `:136-163`

Iteration-1 #6 (toast fired before the write was proven) is fixed correctly in
principle: `_pendingWrite` records `(count, message)` and the second
`BlocListener` toasts only when the selected child's ledger grows past `count`.
Two gaps remain:

* the tuple has **no child id**, and `listenWhen` (`:73-76`) fires on *any*
  change of the selected child's row count. If the parent taps a segment
  between submit and the stream round-trip, `_pendingWrite` is left set for the
  old child and the **next** write on the new child pops the stale
  `"Added £5.00 for Maya"`;
* a second submit before the first emission **overwrites** the tuple
  (`:148`/`:156`), so the first write's confirmation is silently dropped.

**Fix:** add `childId` to the tuple and require
`state.selectedChildId == pending.childId` in the listener; clear
`_pendingWrite` in `setState` when `PocketMoneyChildSelected` is dispatched, and
clear it after the first confirmation even if the count did not grow.

## 4. MINOR — `summarise()` breaks on the first payout, which ties on same-second rows

**File:** `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart:254-268`

`watchLedgerData` merges the per-child streams and re-sorts with
`..sort((a, b) => b.date.compareTo(a.date))` (`:422-423`), and `summarise`
relies on that order: `if (row.type == 'payout') break;` (`:258`). Two writers
can land in the same clock second — `approvals_repository_impl.dart:87-90`
writes a `quest_bonus` with `date: Value(now)` and `recordPayout`
(`:315-336`) writes a `payout` — and `_db.watchLedger`
(`app_database.dart:504-511`) orders by `date desc` **only**, so the tie is
resolved by whatever SQLite returns (rowid asc), not by insertion recency. When
the payout sorts first, the bonus that was written after it is silently dropped
from "Maya is owed" until the next emission reorders.

**Fix (no core edit needed):** make the rule order-independent — take the
latest `payout` date first and then sum rows with `date >= thatPayout` instead
of `break`-ing. (A SQL `rowid desc` tie-break in `app_database.dart` would be
the belt-and-braces version — that file is `core/`, so it needs
`SHARED_REQUEST.md`.)

## 5. MINOR — `domain/next_payout.dart` is still neither an entity nor the abstract repo

**File:** `app/lib/features/pocket_money/domain/next_payout.dart:1-64`

`ARCHITECTURE.md:71` — "`domain/` — entities + abstract
`<feature>_repository.dart` **ONLY**". This file holds two top-level functions
(`nextPayoutDayUtc`, `payoutLabel`); it is the only non-entity, non-repo file in
any feature's `domain/`. It was kept because `1_plan.md:162` mandates the path,
but the plan is not an architecture exemption. P13 will need the same label, so
the right home is a shared helper (core) or the entity.

**Fix:** move it under `presentation/` (its only callers are
`money_ledger_view.dart` and `next_payout_test.dart`) and file
`SHARED_REQUEST.md` for a shared payout-day label helper for P13/P16.

## 6. MINOR — `.ptitle` is still a fourth private copy

**File:** `money_ledger_view.dart:167-185`

`.ptitle` appears in `P10`, `P12`, `P13`, `P16`. `SHARED_REQUEST.md` §2 asks
for a shared `NestPageTitle`; until it lands, P12 keeps a private one — which is
exactly how iteration 1's 16 px drift happened. Documented and non-blocking.

## 7. MINOR — the raw exception still reaches the parent

**Files:** `pocket_money_bloc.dart:243-247`, surfaced by
`money_ledger_view.dart:68` (`showNestToast`) and `:107` (`_FailureBody`)

`_loadErrorMessage` / `_submitErrorMessage` now lead with
"We couldn’t load your ledger: " / "We couldn’t save that: " (curly ’ U+2019 —
correct), which is most of iteration-1 #7, but the Drift/SQLite string is still
appended and rendered on a parent-facing screen. Keeping it for diagnostics is
reasonable; it should go to `debugPrint`/`FlutterError.reportError` instead of
the toast/body.

## 8. MINOR — `state.items` semantics changed under a shared bloc (P13 hand-off)

**Files:** `pocket_money_bloc.dart:79`, `:195`; consumer
`payout_view.dart:24-30`

`items` is now the **selected** child's ledger (`data.entriesFor(...)`), not the
active child's (`watchItems()`). `/payout` reads `state.items`, so when P13 is
built its list follows whichever child the parent last tapped on `/money`. No
test can fail today (P13 is still a placeholder) — this belongs in P13's brief.

## 9. MINOR — `MoneyLedgerData.setup` couples the ledger aggregate to P06 (declined)

**File:** `domain/entities/money_ledger_data.dart:17`, `:45`, `:88`

Every P06 setup edit (mode / payout day / weekly base) re-emits the whole
`MoneyLedgerData`, rebuilding the ledger for changes it does not display. The
build stage declined this with a concrete reason (a second stream re-breaks the
P06 fakes' single-subscription stubs). Acceptable as a documented trade-off;
`setup` stays optional and nullable.

---

## Iteration-1 majors — closed, with evidence

| it-1 | Fix | Evidence |
|---|---|---|
| #1 16 px shift | the `SizedBox(s4)` after `NestStatusBar()` is gone in both bodies (`money_ledger_view.dart:285-287`, `:532-534`) | `money_ledger_geometry_test.dart` pins title 55 / segmented 105 (h 52) / hero 173 (h 211, `Payout time` top 312) / goal 400 (h 88) / history 504 with real fonts, and passes |
| #2 goal card 90 px | `money_ledger_view.dart:495` `.copyWith(height: 22 / 16)` for `.goal .t`'s 22 px line box | same geometry test, goal height 88 |
| #3 tile radius | `money_history_row.dart:86` `NestRadii.allM` | geometry test asserts the decoration + a 40×40 rect |
| #4 hero +3 px | `money_ledger_view.dart:242` `_heroLabHeight = 17/14` (Inter `normal` at 14 px = ascender 0.969 + descender 0.241 ⇒ 16.94) | hero 211 + `Payout time` 312 pinned |
| #5 live region | sheet `:137` `Semantics(liveRegion: true)` — superseded in substance by finding 2 | asserted with `SemanticsFlag.isLiveRegion` |
| #6 premature toast | `_pendingWrite` + second `BlocListener` | asserted that a rejected write toasts the error, not the confirmation |
| #9 helper in `domain/` | moved to `app/test/features/pocket_money/ledger_data_fallback.dart`; `domain/pocket_money_repository.dart` is abstract-only again; the only P06 test edits are the imports + the three fake overrides | `rg ledger_data_fallback lib/` → no hits |
| #11 rebuild storm | `buildWhen` at `money_ledger_view.dart:95-98` | code read |

## ORCHESTRATOR_NOTES.md (12:08) — all 7 items

1. **+16 px above the title** — gone; the geometry test pins the title at 55.
2. **Segmented control top 106 → design** — pinned at 105 ± 1, height 52.
3. **Owed / goal / history card tops** — pinned at 173 / 400 / 504 ± 1.
4. **Hero amount letter-spacing −0.4** — `money_ledger_view.dart:319-320`
   `NestType.kidHero(...).copyWith(letterSpacing: -0.4)`; no other NestType style
   in the feature adds tracking.
5. **±1 px mandate + a real-font geometry test** — `money_ledger_geometry_test.dart`
   (10 tests, `FontLoader` for Inter + Nunito, all green).
6. **History rows / dates / amounts are DB-driven** — every string comes from
   `PocketMoneyEntry` / `OwedSummary` / `SavingsGoalData`; no design literal
   survives (`'4.20'`, `'Sat 4 Oct'`, `'Lego'`, `'Mum'` appear only in the
   repository/seed fixtures, not in the view).
7. **`ORCHESTRATOR_NOTES` line 8 "add a real-font geometry test pinning …"** — done.

## Verified clean (no finding)

- **RULES §1 scope.** `git diff main...HEAD --name-only` outside `docs/` is
  exactly `app/lib/features/pocket_money/**` and
  `app/test/features/pocket_money/**`. No `app/lib/core/**`, no `app/lib/app/**`,
  no other feature, no `tools/screens/**`, no `analysis_options.yaml` (byte-identical
  to main), no routes/DI file. `SHARED_REQUEST.md` is filed (3 non-blocking
  shared items).
- **Copy, character by character, against `P12-money.html`.** "Pocket money",
  "Maya is owed", "£4.20" (`moneyPounds(420)`), "Weekly base £3.00 + quests £1.20
  · Next payout <label>" with U+00B7, "Payout time", "Lego Friends set — £24.99"
  (U+2014), "£15.50 saved · 62%", "History", "Paid · Sat 27 Sep", "Cash from Mum",
  "£3.80" (payout unsigned), "Quest bonus · Put the bins out", "+12p · Approved",
  "+£0.12", "Birthday money (added by Mum)", "To savings goal", "+£10.00",
  "Spent · Comic", "Recorded by Mum", "−£2.00" (**U+2212**, `kMoneyMinus`),
  "Add money", "Record spending", "Nestling keeps track — the real money stays
  with you." (U+2014). UK spelling throughout ("Mum", "£"); no US forms.
  `money_ledger_view_test.dart:326` asserts the code points and that no ASCII
  hyphen survives on the route.
- **Design-system reuse / no hard-coded colours, sizes or fonts.** Zero
  `Color(0x…)` and zero `Colors.*` in the whole P12 diff (the only `transparent`
  in the neighbourhood is inside the shared `nest_card.dart`), zero
  `GoogleFonts`/`google_fonts` (grep clean), zero Material tracking.
  The only literals are documented CSS values: `.hrow` min-height 56,
  `.goal img` 56, the two call-site line-box ratios (17/14, 22/16) and the
  `.rowbtns .btn` 15 px / 48 px — the same call-site pattern the orchestrator
  mandated for `.hero .amt`'s −0.4. `NestStatusBar`, `NestType`, `NestSegmented`,
  `NestCard(hero)`, `NestButton`, `NestProgress`, `NestEmptyState`,
  `NestTextField`, `showNestBottomSheet`, `showNestToast`, `NestIcon`,
  `NestRadii`, `NestDevice`, `NestTileTint` are all reused. No chips on this
  screen (so `NestChipWrap` is N/A); no `text-wrap: balance` in the P12 CSS
  (`.ptitle` is not `.h1`), so plain `Text` is correct and
  `NestBalancedText` must **not** be used here.
- **CHILD ORDER.** `watchLedgerData` maps `_db.watchChildren(Seed.familyId)`
  (`app_database.dart:460-469`, `createdAt` then `rowid`) as-is into the
  segment, the oweds and the goal lookup; asserted in
  `pocket_money_repository_test.dart:83` and `:92`.
- **Accessibility (RULES §8).** No `Semantics(excludeSemantics: true)` wrapper
  around a control anywhere in the diff (the only `excludeSemantics` is the
  shared `NestTextField` internals and `ExcludeSemantics` on display-only art:
  the history tile and the goal coin, matching `alt="" aria-hidden="true"`).
  Every control — both segment options, `Payout time` (labelled "Payout time
  for Maya"), `Add money`, `Record spending`, the sheet CTA, the sheet close, the
  empty-state `Add a child` and `Try again` — is asserted to expose
  `SemanticsAction.tap`, and `performAction(tap)` is asserted to change real
  state (segment → hero re-renders) and the real DB (sheet CTA → new ledger
  row). The hero card passes neither `onTap` nor `semanticLabel` to `NestCard`,
  so `nest_card.dart:58-70` takes the non-merging branch and the card's texts
  stay individually reachable (2b's "merged button node" concern does not apply
  here). `NestProgress` carries `semanticLabel: 'Savings goal progress'`.
- **Performance / lifecycle.** One `emit.forEach` per load, cancelled with the
  bloc; `_combineLedgers` cancels all N per-child subscriptions in
  `controller.onCancel` (`:429-433`) and `asyncExpand` re-cancels the inner
  graph on a roster change; `_closeOnError` closes the stream so a failed load
  cannot leak a second watcher set on "Try again". `buildWhen` keeps an
  `errorMessage`-only emission off the whole `ListView`. Both
  `TextEditingController`s are disposed (`money_edit_sheet.dart:35-38`).
  `const` on every widget that can be (`NestStatusBar`, `SizedBox`, `_PageTitle`,
  `_scrollPadding`, all literals). No `Timer`, no `AnimationController`, so
  nothing needs a `DISABLE_ANIMATIONS` gate.
- **Error handling.** Load failure → `_FailureBody` with the only legal retry and
  no stack/SQLite dump on the layout path; a *write* failure keeps the ledger on
  screen and toasts instead of blanking the screen (better than the P06 write
  path); both controllers are disposed; every sheet rejection is caught before
  the bloc (`:84-104`) and the amount is bounded at £1,000,000.00 with integer
  pence arithmetic (no float multiply), so the iteration-1 overflow class cannot
  recur through the UI.
- **Routing / DI.** `/money` is a tab root, so both pushes use `context.push`
  (`money_ledger_view.dart:337`, `:382`, `:399`, `:543`); route constants come
  from `PocketMoneyRoutePaths` / `FamilyRoutePaths`; the kid-mode guard on
  `/money` is the router's (asserted in `p12_bugs_test.dart:630`).
- **Children's Code.** Parent-only screen: no analytics, no ads, no network, no
  logging of child data, nothing leaving the device, and no kid-mode code path
  touched. `subscription_status` is never written. No Pip on this screen, so the
  PIP ruling is N/A.
- **Tests.** 155 tracked P12 tests pass, 1 intentional skip (P12-BUG-04, the
  shared `NestSegmented` 44 px floor at 320 dp — cross-screen, `SHARED_REQUEST`
  §3, documented inline at `p12_bugs_test.dart:316-320`). No `analysis_options`
  change, no weakened expectations; every widget test that pumps the app ends
  with `disposeApp(tester)` (the two exceptions, `_pumpSheet`
  (`p12_bugs_test.dart:85-91`) and
  the pure parser harnesses, pump a bare `MoneyEditSheet` without the app scope,
  so RULES §7 does not apply). The bottom-edge, 20 px gutter and 44 px tap-target
  groups in `money_ledger_responsive_test.dart` read real pixels and assert the
  probe discriminates (`tokens.surface != tokens.paper`), so they cannot pass
  vacuously.

## Process notes (explicitly NOT findings)

* Untracked scratch from the sibling `5_ui` stage —
  `app/test/features/pocket_money/p12_probe_iter2_test.dart` and
  `p12_probe_iter2b_test.dart` — made `flutter test test/features/pocket_money/`
  report one failure ("Failed to load … Does not exist") while I ran it; both
  files were deleted before my second run, and the tracked suite is green. They
  must not be committed. `docs/screens/P12/ui/*_2.png` is likewise untracked.
* `.brief_bugs/.brief_review/.brief_test/.brief_ui.md` are modified but
  uncommitted — the loop commits each iteration.
* While this review ran, a sibling stage added 278 uncommitted lines to
  `app/test/features/pocket_money/{money_ledger_states_test.dart,
  pocket_money_ledger_bloc_test.dart}` (new `performAction` / toast-rejection
  and error-message-mapping tests for findings 6 and 7 — no skips, no weakened
  expectations). Outside `main...HEAD` scope, so not reviewed here; the loop
  commits them.
* No `flutter clean`, no interactive `flutter run`, no simulator of any kind.

## Handed to the next stage

1. Fix finding 1 (pin `NestStatusBar` above the `ListView` in both bodies) and
   add a scrolled-state guard (nothing paints above y = 47). Re-run
   `money_ledger_geometry_test.dart`: the at-rest anchors must stay 55/105/173/
   400/504.
2. Finding 2: move the sheet's error onto `NestTextField(errorText:)` — same
   three strings, `SemanticsFlag.isLiveRegion` assertion unchanged.
3. Findings 3 and 4 are cheap and self-contained; 5–9 stay open with their
   documented rationale (5, 6 → `SHARED_REQUEST.md`; 8 → P13's brief).
4. Stage 5 should still re-shoot light + dark after finding 1 (at rest the frame
   is unchanged, so `cmp_*_2` should be unaffected — if the band table moves, the
   fix introduced a regression).

VERDICT: FAIL
