# P12 · 2b BUILD (UI chunk, iteration 3)

Files touched (all inside the 2b ownership boundary — `presentation/views/**`,
`presentation/widgets/**`, view/widget tests, `docs/screens/P12/`):

```
app/lib/features/pocket_money/presentation/views/money_ledger_view.dart
app/lib/features/pocket_money/presentation/widgets/money_edit_sheet.dart
app/test/features/pocket_money/money_ledger_view_test.dart      (live-region idiom + 1 new test)
app/test/features/pocket_money/money_ledger_geometry_test.dart  (+1 test, +1 assert)
docs/screens/P12/2b_build_ui.md                                (this file)
```

No `bloc/`, no `domain/`, no `data/`, no `core/`, no `app/`, no other feature,
no `tools/`, no `analysis_options`. No simulator booted, installed on,
screenshotted or driven (only BC440E48… exists for stage 5 and it was not
touched). No image attached — the light design PNG was READ with the file
reader only. No whole-app `flutter test`; the feature dir was run
(`316 pass, 1 documented skip`).

## CONTRACT CHANGES (re-read before finishing)

`2a_build_logic.md` (iteration 3) declares **no** state/event/entity shape
change — `errorMessage`, `MoneyLedgerData`, the three P12 events and
`watchLedgerData` all keep their iteration-2 shapes, and the only behavioural
change on the logic side is the order-independent `summarise()` tie rule
inside the repository. Nothing in this stage coded against a new or renamed
member, so no reconciliation was needed.

## FIXES_2.md triage (UI layer)

| # | Severity | Subject | Status here |
|---|---|---|---|
| 1 | **major** | Status-bar reserve was `ListView` child 0, so it scrolled away | **FIXED** (+ scrolled-state guard) |
| 2 | minor | Sheet hand-rolled the inline error instead of `NestTextField.errorText` | **FIXED** |
| 3 | minor | Write-confirmation toast lost / misattributed across a child switch | **FIXED** (+ regression test) |
| 4 | minor | `summarise()` same-second tie | 2a — not mine |
| 5 | minor | `domain/next_payout.dart` not an entity | 2a (retained, plan mandates the path) |
| 6 | minor | `_PageTitle` is the 4th private `.ptitle` | open — core/, `SHARED_REQUEST.md` §2 |
| 7 | minor | Raw exception text reaches the parent | 2a — retained deliberately |
| 8 | minor | `state.items` is the selected child's ledger | 2a / P13 brief |
| 9 | minor | `MoneyLedgerData.setup` couples the ledger to P06 | 2a — declined, documented |

### 1 (MAJOR) — the status-bar band is now pinned above the scroller

`money_ledger_view.dart`, `_LoadedBody.build` and `_EmptyBody.build`.

`P12-money.html:17-20` is a flex column in which `.status-bar` is the
**preceding sibling** of `.scroll` (`components.css:46`
`.status-bar { min-height:47px; flex-shrink:0 }`, `:65`
`.scroll { flex:1; overflow-y:auto; min-height:0 }`). Both bodies rendered
`NestStatusBar()` as the *first child of the ListView*, so the ledger — which
is longer than the fold by design — scrolled the reserve (and the title) off
and painted the white history cards under the OS-drawn clock. P12 was the
only screen doing it; P05, P06 and K03 all reserve the band outside their
scroller.

Both bodies are now `Column[NestStatusBar, Expanded(ListView)]`:

```dart
return Column(
  children: <Widget>[
    const NestStatusBar(),     // pinned band, outside the scroller
    Expanded(
      child: ListView(
        padding: _scrollPadding,
        children: <Widget>[
          const _PageTitle(),  // still at 55 — its own padding-top: s2
          …
```

At rest nothing moves: the band is the same 47 px in the same place, so the
anchors stay title 55 / segmented 105 (h 52) / owed 173 (h 211, `Payout time`
312) / goal 400 (h 88) / history 504 — `money_ledger_geometry_test.dart`
passes unchanged (11/11 after the new test).

**Guard added** (the at-rest assertions cannot catch this class of defect —
both layouts are pixel-identical at scroll 0): a new test drags the list by
120 px and asserts the band is still at top 0, the scroller still starts at
47, and the first `MoneyHistoryRow` paints at `≥ 47`. The empty-state test
now also asserts its `ListView` starts at 47.

### 2 (minor) — the sheet uses the shared `NestTextField.errorText`

`money_edit_sheet.dart`. The Amount field now passes `errorText: _error` and
the hand-rolled `SizedBox` + `Semantics(liveRegion:)` + `Text` block that sat
**under the Note field** is gone (with its now-unused `context.nest`).

* the invalid state is the shared one: 2 px `danger` border on the field it
  is about, plus a gutter-aligned error row under that field
  (`nest_text_field.dart:329-341`);
* the live region finding 5 needed is the component's own
  (`Semantics(liveRegion: true, label: errorText)`, inner text
  `ExcludeSemantics` so it announces once);
* the three strings are byte-identical and `_error` is still cleared in
  `onChanged`.

`money_ledger_view_test.dart` was updated to the P03 idiom for this
component (`find.bySemanticsLabel(...)` → `flagsCollection.isLiveRegion`,
because the inner Text is now excluded) and gained an assertion that the
error's top is above the Note label — i.e. it is attached to Amount.

### 3 (minor) — the armed confirmation carries its child id

`money_ledger_view.dart`. The single nullable tuple became a list of
`_PendingWrite { childId, count, message }`:

* the confirmation listener now requires `pending.childId ==
  state.selectedChildId`, and its `listenWhen` also fires on a **selection
  change**, so a write armed for Maya is retired the moment the parent taps
  Leo instead of resurfacing on the next write;
* it is a list, so a second submit before the first emission no longer
  overwrites the first confirmation (both are announced);
* a rejected write still clears every armed entry (the error toast stays the
  only thing the parent is told).

`money_ledger_view_test.dart` gained
`a write confirmed after a child switch names its own child`. It uses a
gated repository fake (`_GatedLedgerRepository` holds `addMoney` /
`recordSpending` until the test releases them) so "the parent switched
children before the stream round-tripped" is a reachable state rather than a
race — with the old tuple-free code the final assertion
(`Added £1.00 for Leo`) fails, so the test discriminates.

## Owner rules re-checked on the files I touched

* **BOTTOM EDGE** — unchanged (`Scaffold` background `tokens.paper`; the
  shell tab bar paints `surface` to the edge). `money_ledger_responsive_test.dart`
  bottom-edge groups stay green.
* **ALIGNMENT** — `_scrollPadding` is still `20` both sides; the pinned band
  is full-bleed like the design's `.status-bar`, so no gutter moved.
* **CHILD ORDER** — untouched (segment built from `data.children`, creation
  order).
* **COPY** — no string changed. The error strings are byte-identical; every
  other glyph (`—`, `·`, `−`, `→`) is as iteration 2.
* **FONTS / LETTER SPACING** — no `google_fonts`, no new tracking; the hero
  keeps `letterSpacing: -0.4` and no other `NestType` copyWith adds tracking.
* **TOKENS ONLY** — zero new literals: the fix only restructures the existing
  widgets. No `Color(0x…)`, no `Colors.*`, no hard-coded sizes.
* **ACCESSIBILITY ACTIONS** — no control was wrapped in
  `Semantics(excludeSemantics: true)`; the sheet error's live region is the
  shared component's, and every control keeps its `SemanticsAction.tap`
  (verified by the still-green states/responsive/bugs suites).
* **PIP / chips / `NestBalancedText`** — N/A on P12 (no Pip slot, no chips,
  no `text-wrap: balance` in the P12 CSS), and none was introduced.
* **SIMULATORS** — none used.

## Verification

```
$ dart format --output=none --set-exit-if-changed .
Formatted 437 files (0 changed) in 1.17 seconds.

$ flutter analyze lib/features/pocket_money test/features/pocket_money
No issues found! (ran in 3.8s)

$ flutter test test/features/pocket_money/money_ledger_geometry_test.dart
00:01 +11: All tests passed!      ← 10 anchors + the new scrolled-state guard

$ flutter test test/features/pocket_money/money_ledger_view_test.dart \
    money_ledger_states_test.dart money_ledger_geometry_test.dart \
    money_ledger_responsive_test.dart p12_bugs_test.dart
00:03 +89 ~1: All tests passed!    ← the ~1 is the documented P12-BUG-04 skip

$ flutter test test/features/pocket_money/        # feature dir, not whole-app
00:07 +316 ~1: All tests passed!
```

The single skip is unchanged: **P12-BUG-04** (`p12_bugs_test.dart:316-320`),
the shared `NestSegmented` 44 px floor at 320 dp. Its fix is in `core/`
(`SHARED_REQUEST.md` §3, already filed — not duplicated here), so it stays
skipped rather than being worked around locally. No other skipped
reproducer was referenced by FIXES_2.

## LEFT FOR NEXT ITERATION

1. Stage 5 must re-shoot light + dark: at rest the frame is unchanged, so
   `cmp_*_2` should be unaffected — if the band table moves after the pin,
   the fix introduced a regression. The scrolled state has never been
   screenshot compared (it now has a widget-test guard instead).
2. Finding 6 (`.ptitle` → shared `NestPageTitle`) and the `NestSegmented`
   44 px floor are blocked on `core/` — `SHARED_REQUEST.md` §2/§3; 2a
   added §4 (core `watchLedger` tie-break).
3. Findings 5, 7, 8, 9 stay open with 2a's documented rationale (plan-
   mandated path; retained raw diagnostics; P13 hand-off; declined
   coupling).

VERDICT: PASS