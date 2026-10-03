# P12 · Money (ledger) — Stage 4 QA code review (iteration 3)

Scope: `git diff main...HEAD` (66 files, 26 of them code) for screen P12 /
feature `pocket_money` / route `/money`, plus the iteration-3 delta
`git diff 1185513...HEAD` (the three build stages since the iteration-2
review). Reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P12, `docs/design/SPACING_SPEC.md`,
`design/html-source/screens/P12-money.html` (copy source of truth),
`design/html-source/{components,tokens}.css`, the design PNGs
(1170×2532 ÷ 3 = 390×844), the design system in
`app/lib/core/design_system/`, `1_plan.md`, `ORCHESTRATOR_NOTES.md`,
`SHARED_REQUEST.md`, iteration 2's `4_review.md` and iteration 2's
`5_ui.md` / `6_bugs.md`.

**No code was edited in this stage. No simulator was booted, installed on,
driven or screenshotted; no image was attached** (PNGs and CSS were read with
the file reader only).

Gates re-run in this worktree (read-only, host VM — no simulator):

```
$ dart format --output=none --set-exit-if-changed .
Formatted 437 files (0 changed) in 2.67 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 7.3s)

$ flutter test test/features/pocket_money/
00:12 +321 ~1: All tests passed!        ← the ~1 is the documented P12-BUG-04 skip

$ flutter test                             # whole app, not just the feature
00:49 +1914 ~1: All tests passed!        ← 0 failed anywhere
```

## Result

**No blocker and no major findings. VERDICT: PASS.**

Iteration 2's only major (the 47 px status-bar band scrolling away with the
ledger) is genuinely fixed and is now covered by a guard that could not
exist before, and findings 2 and 3 are closed properly. Ten findings remain,
none of them blocking: seven carried/declined minors with their rationale,
two new minors, and two nits.

| # | Severity | Subject | Status |
|---|---|---|---|
| 1 | minor | A `gift` row is captioned "To savings goal" but `addMoney` never credits the goal | **new** |
| 2 | minor | The goal caption's percentage is not clamped; >100 % is reachable | **new** |
| 3 | minor | A write-confirmation toast can still fire for a write that later fails (two writes armed at one count) | **new** |
| 4 | minor | `domain/next_payout.dart` is neither an entity nor the abstract repo | carried (it-1 #8) |
| 5 | minor | `_PageTitle` is the 4th private copy of `.ptitle` | carried (it-1 #12, `SHARED_REQUEST` §2) |
| 6 | minor | Raw exception text still reaches the parent after the friendly lead | carried (it-1 #7) |
| 7 | minor | `state.items` is the *selected* child's ledger and P13 reads it | carried (it-1 #13) |
| 8 | minor | `MoneyLedgerData.setup` couples the ledger aggregate to P06 | carried, declined with reason (it-1 #10) |
| 9 | minor | P12-BUG-04: shared `NestSegmented` drops options to 42 px at 320 dp / six children | carried, shared (`SHARED_REQUEST` §3) |
| 10 | nit | The hero amount is the screen's only `.money` string without the design's tabular figures | **new** |
| 11 | nit | `_recordWrite`'s `context` parameter is dead | **new** |
| it-2 1 | ~~major~~ | 47 px status-bar reserve was `ListView` child 0 | **closed** — below |
| it-2 2 | minor | Sheet hand-rolled the inline error | **closed** |
| it-2 3 | minor | Confirmation toast lost / misattributed across a child switch | **closed** (residual in #3) |
| it-2 4 | minor | `summarise()` breaks on the first payout; same-second ties | **closed** |

---

## 1. MINOR — "To savings goal" is printed on money that never reaches the goal

**Files:** `app/lib/features/pocket_money/presentation/widgets/money_history_row.dart:199-202`
(`_subtitleFor`), `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart:286-306`
(`addMoney`), `:353-378` (`recordPayout` — the only writer that credits a goal).

`_subtitleFor` maps **both** `gift` and `savings_move` to the literal
`To savings goal`. Only `savings_move` is actually credited: `recordPayout`
is the sole code path in the app that touches `savings_goals.savedPence`
(`:375 savedPence + savingsMovePence.abs()`). `addMoney` — which is exactly
what the screen's **"Add money"** button invokes — inserts one `ledger_entries`
row and updates nothing else.

So the parent flow is: tap **Add money** → `£5.00` → **Add money** in the
sheet → toast `Added £5.00 for Maya` → a new history row that reads
`Test top-up` / **`To savings goal`** / `+£5.00`, sitting 20 px below a goal
card that still says `£15.50 saved · 62%`. The screen contradicts itself on
one tap of one of its two primary CTAs. The seeded `gift` row in
`core/data/seed.dart:447-453` is a genuine goal contribution (its paired
`savings_move` row at `:455-461` is what actually moved `savedPence` to 1550),
which is why the design HTML prints that subtitle for that row — but the
generic type mapping applies it to writes that move nothing.

This is a product-contract question, not a build error: `1_plan.md` §a item 7
mandates the mapping (and it matches `P12-money.html:27`), and `DESIGN_SPEC`
§5 P12 does not specify history-row subtitles at all. P12 should not pick
silently.

**Fix (needs an orchestrator ruling — do not guess locally).** Either
(a) make `addMoney` a goal contribution: add an optional `goalId`/`toSavings`
to the repository method and pass the selected child's goal
(`MoneyLedgerData.goalFor`) from the sheet, crediting `savedPence` in the same
transaction exactly as `recordPayout` does — and give `gift` a distinct
subtitle; or (b) keep the write as a plain top-up and change the `gift`
subtitle to the design's own jar wording (K09 uses "from Mum"), reserving
`To savings goal` for `savings_move` alone. Option (b) is a one-line copy
change and matches the only writer that backs the words. File it as
`SHARED_REQUEST.md` §5; nothing on `/money` needs it to land.

## 2. MINOR — the goal caption's percentage is unclamped

**Files:** `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart:551-557`,
`domain/entities/savings_goal_data.dart:26-29`, `nest_progress.dart:22-23`.

`SavingsGoalData.fraction` returns `savedPence / targetPence` with no clamp,
and the caption prints `(goal.fraction * 100).round()` unguarded — even
though the entity's own doc comment says *"The view clamps to 0..1"* and the
view does not. `NestProgress` clamps internally, so the bar and its
accessibility value (`'${(f * 100).round()} percent'`) stay correct; only the
visible caption drifts.

Reachable, not hypothetical: `recordPayout` adds `savingsMovePence` to
`savedPence` with no ceiling and no schema CHECK (`app_database.dart:171` is a
plain `integer()`), so after ~10 weekly £1.00 moves the £24.99 goal holds
£25.00+ and the card reads **`£25.50 saved · 102%`** directly above a 100 %
bar announced as "100 percent". Not reachable today only because P13 has not
been built — it becomes reachable the moment the shared feature's payout route
calls it.

**Fix:** clamp once, in the entity, so the bar and the copy cannot disagree:

```dart
double get fraction {
  if (targetPence <= 0) return 0;
  return (savedPence / targetPence).clamp(0.0, 1.0);
}
```

Add a regression test with `targetPence: 2499, savedPence: 2550` asserting the
caption is `£25.50 saved · 100%` and the semantics value is "100 percent".

## 3. MINOR — the confirmation toast can still announce a write that then fails

**Files:** `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart:81-109`
(the confirmation listener), `:156-179` (`_recordWrite`).

Iteration-2 findings 3 and 6 are genuinely fixed for the single-write case:
the pending record carries its `childId`, it is a list (no overwrite), it is
retired on a selection change, and a rejected write clears every armed entry
before the error toast. What is left is a residue of the same class.

`_recordWrite` captures `count` from `bloc.state.data` **at submit time**, and
the listener confirms on `size > pending.count`. If two writes are armed
before the first stream round-trip, both carry the same `count`, so the first
emission satisfies both — including one whose repository call subsequently
throws. The parent then gets `Added £5.00 for Maya` *and*
`We couldn’t save that: …` for the same tap. The single-write path cannot
mis-fire (the failing write produces no size change, and the error listener
clears the list before the confirm listener can run).

Stage 6's iteration-3 probe (two writes held before the first emission)
confirms the **both-succeed** half: both rows land and both confirmations are
announced in order. What is untested is the **one-fails** half.

Reaching it needs the ledger stream to stall across two complete sheet
interactions (open, type, save, twice) — a heavily loaded device or a
backgrounded app. Rare, and not a regression of the fix, but it is the same
"success announced before the write is proven" defect the loop already
decided to fix once.

**Fix:** make the proof per-write rather than per-count. Record the ledger's
newest row id (or a monotonically increasing submission nonce) with each
pending write and confirm only when the selected child's newest row is newer
than the recorded one *and* the size grew; and confirm at most
`size - count` pending writes, oldest first. Simplest sufficient version:

```dart
final confirmed = <_PendingWrite>[];
var budget = size - _pendingWrites
    .where((p) => p.childId == childId)
    .fold(0, (n, p) => n + 1);      // only this many rows can be new
for (final pending in _pendingWrites.where((p) => p.childId == childId)) {
  if (budget-- > 0) confirmed.add(pending); else break;
}
```

## 4. MINOR — `domain/next_payout.dart` is still neither an entity nor the abstract repo

**File:** `app/lib/features/pocket_money/domain/next_payout.dart:13-64`

`ARCHITECTURE.md:71` — "`domain/` — entities + abstract
`<feature>_repository.dart` **ONLY**". This file holds two top-level pure
functions (`nextPayoutDayUtc`, `payoutLabel`) and is the only non-entity,
non-repo file in any feature's `domain/`. Carried across three iterations with
2a's rationale: `1_plan.md` §b mandates the path and P13 will import it.

**Fix:** move it under `presentation/` (its only callers are
`money_ledger_view.dart` and `next_payout_test.dart`) and file a
`SHARED_REQUEST` for a shared payout-day label helper for P13/P16 — with a
plan update, since `1_plan.md` currently pins the path.

## 5. MINOR — `.ptitle` is still a fourth private copy

**File:** `money_ledger_view.dart:199-217`

`.ptitle` appears in P10, P12, P13 and P16. `SHARED_REQUEST.md` §2 asks for a
shared `NestPageTitle`; until it lands P12 keeps a private one — which is
exactly how iteration 1's 16 px drift happened. Now pinned by
`money_ledger_geometry_test.dart` (title top 55 ± 1 with real fonts), so the
risk is contained. Non-blocking.

## 6. MINOR — the raw exception still reaches the parent

**Files:** `pocket_money_bloc.dart:243-247`, surfaced by
`money_ledger_view.dart:74` (`showNestToast`) and `:127` (`_FailureBody`)

`_loadErrorMessage` / `_submitErrorMessage` lead with "We couldn’t load your
ledger: " / "We couldn’t save that: " (curly ’ U+2019 — correct), but the
Drift/SQLite string is still appended and rendered on a parent-facing screen
and in a toast. 2a retained it deliberately because ~12 pinned
`contains(...)` expectations across P06/P12 depend on the suffix; it belongs in
`debugPrint`/`FlutterError.reportError` once those expectations are moved to
`startsWith`. Carried, unchanged from iteration 2.

## 7. MINOR — `state.items` semantics changed under a bloc P13 also owns

**Files:** `pocket_money_bloc.dart:79`, `:195`; consumer `payout_view.dart`

`items` is the **selected** child's ledger, not the active child's
(`watchItems()`). `/payout` reads `state.items`, so when P13 is built its list
will follow whichever child the parent last tapped on `/money`. No test can
fail today (P13 is still a placeholder) — this belongs in P13's brief. Carried.

## 8. MINOR — `MoneyLedgerData.setup` couples the ledger aggregate to P06 (declined)

**File:** `domain/entities/money_ledger_data.dart:18`, `:42-45`

Every P06 setup edit (mode / payout day / weekly base) re-emits the whole
`MoneyLedgerData`, rebuilding the ledger for changes it does not display.
`buildWhen` (`money_ledger_view.dart:115-118`) absorbs the rebuild when the
Equatable state is unchanged, and 2a declined the split with a concrete
reason (a second stream re-breaks the P06 fakes' single-subscription stubs).
Accepted trade-off; `setup` stays optional and nullable.

## 9. MINOR — P12-BUG-04, shared `NestSegmented` 42 px options at 320 dp

**Files:** `p12_bugs_test.dart:277-320` (reproducer, `skip: true`),
`app/lib/core/design_system/components/nest_segmented.dart` (shared)

With six children at 320 dp the five 4 px gaps plus the 4 px track padding
leave **42 px** per option, under the parent-mode 44 px tap-target rule
(`DESIGN_SPEC.md` §0.9, RULES §8). P12 must not fork the shared control, so
the reproducer stays skipped and the fix is requested in
`SHARED_REQUEST.md` §3. This is the only skipped test in the diff; it is the
single open bug-hunt item from iteration 2 (`6_bugs.md`) and it is minor and
cross-screen.

## 10. NIT — the hero amount is the screen's only `.money` string without tabular figures

**File:** `money_ledger_view.dart:360-369`

`P12-money.html:22` is `class="amt money"`, and `.money` is
`font-variant-numeric: tabular-nums; font-weight:700; white-space:nowrap`
(`components.css:155`). The app renders the hero with
`NestType.kidHero(...).copyWith(letterSpacing: -0.4)` — Nunito 900, so the
weight is right, but without `FontFeature.tabularFigures()`, while every other
`.money` string on the screen (all history amounts) correctly uses
`NestType.money`, which carries them. Likely sub-pixel for a fixed `£4.20`
(Nunito's default figures are already uniform), but it is an inconsistency
with the design's own class list.

**Fix (call site, same precedent as the −0.4 tracking):**

```dart
style: NestType.kidHero(color: tokens.onHero).copyWith(
  letterSpacing: -0.4,
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
),
```

## 11. NIT — `_recordWrite`'s `context` parameter is dead

**Files:** `money_ledger_view.dart:156`, `:242-250`, `:504-511`

`_LoadedBodyWrite` threads a `BuildContext` into `_recordWrite`, which never
reads it (the toast is shown from the listener, which has its own context), and
`_openSheet` closes over a `BuildContext` from inside `ListView`'s build purely
to pass it on. Dropping the parameter removes a context-across-a-callback
shape that a future edit could misuse.

---

## Iteration-2 findings — closed, with evidence

| it-2 | Fix | Evidence |
|---|---|---|
| **#1 major** the 47 px band scrolled away | `money_ledger_view.dart:306-310` and `:582-586`: both bodies are now `Column[NestStatusBar, Expanded(ListView)]`, so the reserve is the scroller's *preceding sibling* exactly as `P12-money.html:17-20` + `components.css:46/65` make it | two new guards: `money_ledger_geometry_test.dart:98-125` (drag −120 px → band still at 0, scroller still at 47, first `MoneyHistoryRow` ≥ 47) and `money_ledger_responsive_test.dart:398-455` (a 59 px notch grows the band and drags the scroller with it, light **and** dark). At-rest anchors unchanged: title 55 / segmented 105 (h 52) / owed 173 (h 211, `Payout time` 312) / goal 400 (h 88) / history 504, all ±1 with real fonts loaded |
| #2 hand-rolled sheet error | `money_edit_sheet.dart:120-130`: the Amount field now passes `errorText: _error`; the detached block under the Note field is gone, with the same three byte-identical strings still cleared in `onChanged` | `money_ledger_view_test.dart:624-637` asserts the live region **and** that the error's top is above the Note label, i.e. it is attached to Amount; the shared component paints the 2 px danger border and gutter-aligns the row (`nest_text_field.dart:329-341`) |
| #3 toast attribution | `money_ledger_view.dart:52` + `:186-196`: a `List<_PendingWrite>` carrying `childId`, with the confirmation listener requiring `pending.childId == state.selectedChildId` and retiring foreign entries on a selection change | `money_ledger_view_test.dart:641-…` `a write confirmed after a child switch names its own child` uses a gated repository fake so the window is reachable rather than racy; it fails against the old tuple-free code |
| #4 `summarise` tie | `pocket_money_repository_impl.dart:259-284`: order-independent — find the latest `payout` instant, then sum `weekly_base` + `quest_bonus` with `date >= that instant` | `pocket_money_repository_test.dart:73-118` pins both input orders (payout-first and bonus-first) → quests 25 / base 0 / total 25; the same rule was mirrored in the test-side fallback (`ledger_data_fallback.dart:47-70`) and a `rowid desc` tie-break was requested for the shared query (`SHARED_REQUEST.md` §4) |

The scrolled-state guard is the part worth calling out: both layouts are
pixel-identical at scroll 0, which is why the defect survived two UI passes,
and no at-rest assertion could ever have caught it. It is now covered twice.

## ORCHESTRATOR_NOTES.md (12:08) — all 7 items

1. **+16 px above the title** — gone; pinned at 55 ± 1.
2. **Segmented control top 106 → design** — pinned at 105 ± 1, height 52.
3. **Owed / goal / history card tops** — pinned at 173 / 400 / 504 ± 1.
4. **Hero amount letter-spacing −0.4** — `money_ledger_view.dart:364-365`; no
   other `NestType` style in the feature adds tracking (grep clean).
5. **±1 px mandate + a real-font geometry test** — `money_ledger_geometry_test.dart`
   (11 tests, `FontLoader` for Inter + Nunito, all green).
6. **History rows / dates / amounts are DB-driven** — every string comes from
   `PocketMoneyEntry` / `OwedSummary` / `SavingsGoalData`; `'4.20'`, `'Sat 4
   Oct'`, `'Lego'`, `'Mum'` appear only in repository/seed fixtures, never in
   the view.
7. **"Add a real-font geometry test pinning …"** — done.

## Owner rules re-checked

- **BOTTOM EDGE** — `Scaffold(backgroundColor: tokens.paper)`; the shell
  `NestTabBar` is the shell Scaffold's `bottomNavigationBar`
  (`app/lib/app/router.dart:32-43`), so it paints `surface` to the physical
  edge by construction. `money_ledger_responsive_test.dart` probes real pixels
  and asserts the probe discriminates (`tokens.surface != tokens.paper`), so it
  cannot pass vacuously; stage 5 confirmed `cmp_*_3` at 1.92 %/1.90 % with the
  only bottom-band deviation being the *compliant* one.
- **ALIGNMENT** — `_scrollPadding` is `NestSpacing.padSide` (20) both sides
  (`money_ledger_view.dart:222-227`); title, segment, hero, goal, history, row
  buttons and footer all share x 20…370. Stage 5 measured 20/20 in both themes.
- **CHILD ORDER** — the segment is built from `data.children`, which maps
  `_db.watchChildren(Seed.familyId)` as-is (creation order), asserted in
  `pocket_money_repository_test.dart`.
- **COPY** — character-by-character against `P12-money.html`: "Pocket money",
  "Maya is owed", "£4.20", "Weekly base £3.00 + quests £1.20 · Next payout
  <label>" (U+00B7), "Payout time", "Lego Friends set — £24.99" (U+2014),
  "£15.50 saved · 62%", "History", "Paid · Sat 27 Sep", "Cash from Mum",
  "£3.80" (payout unsigned), "Quest bonus · Put the bins out",
  "+12p · Approved", "+£0.12", "Birthday money (added by Mum)",
  "To savings goal", "+£10.00", "Spent · Comic", "Recorded by Mum",
  "−£2.00" (U+2212, `kMoneyMinus`), "Add money", "Record spending",
  "Nestling keeps track — the real money stays with you." (U+2014). UK
  spelling throughout; no US forms; no ASCII hyphen on the route
  (`money_ledger_view_test.dart:342-347` pins the code points).
- **BALANCED HEADINGS** — `NestBalancedText` is correctly **not** used here:
  `P12-money.html:20` styles the title with `.ptitle`, which has no
  `text-wrap: balance` (`components.css:29` puts `balance` on `.h1`, which
  P12 does not use), and the hero is `.hero .amt`, not `.kid-hero`.
- **CHIP ROWS / `NestChipWrap`** — N/A, P12 has no chips.
- **PIP** — N/A, no Pip slot on this screen.
- **FONTS** — no `google_fonts` import or `GoogleFonts.*` call anywhere in the
  diff (grep clean across `app/lib` and `app/test`).
- **TOKENS ONLY / no re-implemented components** — zero `Color(0x…)` and zero
  `Colors.*` in the whole P12 diff; every colour is `context.nest`. The only
  numeric literals are documented CSS values: `.hrow` min-height 56, `.goal
  img` 56, the two call-site line-box ratios (17/14, 22/16), `.rowbtns .btn`
  15 px / 48 px and the mandated −0.4 tracking. `NestStatusBar`, `NestType`,
  `NestSegmented`, `NestCard(hero)`, `NestButton`, `NestProgress`,
  `NestEmptyState`, `NestTextField`, `showNestBottomSheet`, `showNestToast`,
  `NestIcon`, `NestRadii`, `NestDevice`, `NestTileTint` are all reused.
- **ACCESSIBILITY ACTIONS** — no control is wrapped in
  `Semantics(excludeSemantics: true)` (the only `excludeSemantics` in the
  P12 files is on display-only art: the goal coin and the history tile, both
  matching `alt="" aria-hidden="true"` in the HTML). Every control — both
  segment options, `Payout time` (labelled "Payout time for Maya"), `Add
  money`, `Record spending`, the sheet CTA, the sheet close, the empty-state
  `Add a child` and `Try again` — is asserted to expose
  `SemanticsAction.tap`, and `performAction(tap)` is asserted to change real
  state (segment → hero re-renders) and the real DB (sheet CTA → a new row and
  a toast). The hero card passes neither `onTap` nor `semanticLabel` to
  `NestCard`, so `nest_card.dart:86-100` takes the non-merging branch and the
  button stays independently reachable. `NestProgress` carries
  `semanticLabel: 'Savings goal progress'`.
- **TRIAL** — `subscription_status` is never written (grep clean).
- **SIMULATORS** — none booted, installed on, driven or screenshotted in this
  stage. Only stage 5 may use BC440E48… and it did.
- **CHILDREN'S CODE** — parent-only screen. No analytics, no ads, no network
  import, no `print`/`debugPrint`, nothing logged, nothing leaving the device,
  no kid-mode code path touched. No guilt framing, no timers, no variable
  rewards; the only `danger` colour is the shared input-validation border on a
  parent screen.

## Performance / lifecycle / error handling

- One `emit.forEach` per load, cancelled with the bloc; `_closeOnError`
  forwards the first error then closes the stream, so a failed load cannot leak
  a second watcher set when `Try again` re-subscribes (asserted:
  `money_ledger_states_test.dart:270-345` re-subscribes and asserts the retry).
- `_combineLedgers` cancels all N per-child subscriptions in
  `controller.onCancel` (`pocket_money_repository_impl.dart:445-449`) and
  `asyncExpand` re-cancels the inner graph on a roster change.
- `buildWhen` (`money_ledger_view.dart:115-118`) keeps an `errorMessage`-only
  emission off the whole `ListView`; `Equatable`'s deep list comparison stops
  equal emissions from rebuilding at all. No rebuild storm.
- `const` on everything that can be it (`NestStatusBar`, `SizedBox`,
  `_PageTitle`, `_scrollPadding`, all literals); `MoneyHistoryRow` and
  `MoneyEditSheet` are local widgets, not re-implemented shared ones.
- Both `TextEditingController`s are disposed (`money_edit_sheet.dart:35-38`);
  `NestButton`'s own `FocusNode` is disposed in the component.
- Every sheet rejection is caught before the bloc and the amount is bounded at
  £1,000,000.00 with **integer** pence maths (no float multiply anywhere), so
  the iteration-1 overflow/100× classes cannot recur through the UI.
- A *write* failure keeps the ledger on screen and toasts instead of blanking
  it (better than the P06 write path); a *load* failure shows the message plus
  the only legal retry and no stack/SQLite dump on the layout path.

## Tests

1914 passing / 1 skipped / 0 failing app-wide; 321 + 1 skip in the feature.
`analysis_options.yaml` is byte-identical to `main`; no expectation was
weakened; no test-only escape hatch was added. Every widget test that pumps
the app ends with `disposeApp(tester)` — the four that do not are the two
`_pumpSheet` harnesses and the pure parser/contrast groups
(`p12_bugs_test.dart:85-114`), which pump a bare `MoneyEditSheet` on their own
`MaterialApp` and never open a Drift scope, so RULES §7 does not apply. The
one skip is P12-BUG-04 (finding 9).

## Verified clean (no finding)

- **RULES §1 scope.** `git diff main...HEAD --name-only` outside `docs/` is
  exactly `app/lib/features/pocket_money/**` and
  `app/test/features/pocket_money/**`. No `app/lib/core/**`, no `app/lib/app/**`,
  no other feature, no `tools/screens/**`, no `analysis_options.yaml`, no
  routes/DI file. `SHARED_REQUEST.md` is filed (5 non-blocking shared items).
- **ARCHITECTURE.** Feature-first ✓; one bloc per feature shared by P06/P12/P13
  ✓ (the documented contract, not a violation); entities are Equatable value
  objects and the model extends the entity with `fromJson`/`toJson` ✓; no
  use-case classes, no `utils` dumping ground, `package:nestling/...` imports
  only ✓; DI and routes untouched because `/money` was already wired at
  branch index 2 ✓. Only deviation: finding 4.
- **DESIGN_SPEC §5 P12.** Every listed element is present: title, segmented
  Maya|Leo, hero (`Maya is owed` / `£4.20` / breakdown / `Payout time`), goal
  card (coin art 56, `Lego Friends set — £24.99`, `£15.50 saved · 62%`, 62 %
  progress), history header + rows, `Add money` / `Record spending`, footer
  caption, Money tab active. Findings 1–3 are the only content-level
  departures.
- **Routing.** `/money` is a tab root, so all three navigations use
  `context.push` (never `go`, which would reset branch state);
  `PocketMoneyRoutePaths.payout` and `FamilyRoutePaths.addChildren` come from
  the features' own constants; the kid-mode guard is the router's (asserted in
  `p12_bugs_test.dart:630-638`).

## Process notes (explicitly NOT findings)

* Uncommitted work in the tree — `app/test/features/pocket_money/money_ledger_responsive_test.dart`
  (+141, the notch and scroller-end guards), `docs/screens/P12/5_ui.md`,
  `docs/screens/P12/ui/*_3.png` — is stage-3/stage-5 output, handled by the
  loop. Reviewed and green where it touches product behaviour (the notch and
  bottom-of-scroller guards both pass and neither weakens an expectation), but
  not listed as a finding.
* `docs/screens/P12/SHARED_REQUEST.md:111-113` still says finding 7's mapping
  "belongs in `pocket_money_bloc.dart`, which this stage does not own" — that
  is now stale: 2a did add the friendly lead and deliberately retained the raw
  suffix (finding 6). A doc line, not code.
* `docs/screens/P12/3_test.md` and `6_bugs.md` were rewritten for iteration 3
  (and `money_ledger_responsive_test.dart` +141) while this review was running,
  and the four `ui/*_3.png` captures landed too. Stage 6's iteration-3 hunt
  reports the same verdict (no blocker/major, `6_bugs.md:109-116`) and
  independently confirms the status-band pin, the sheet-error attach, the
  child-id confirmation and the tie rule. Handled by the loop; not listed as
  findings.
* No `flutter clean`, no interactive `flutter run`, no simulator of any kind.

## Handed to the next stage

1. Findings 1 and 2 are the only ones with user-visible consequences. Both
   want an orchestrator/product ruling (`SHARED_REQUEST.md` §5 for finding 1);
   finding 2's fix is a one-line clamp in the entity plus a regression test and
   can land locally whenever the loop prefers.
2. Finding 3 is self-contained in `money_ledger_view.dart` and its regression
   test can reuse the gated-repository fake already in
   `money_ledger_view_test.dart`.
3. Findings 4–9 stay open with their documented rationale (4, 5, 9 →
   `SHARED_REQUEST.md`; 7 → P13's brief; 6, 8 → accepted trade-offs).
4. Stage 6 should re-run its bug hunt with the multi-write window and the
   over-target goal in scope: both are states the existing probes do not
   reach.

VERDICT: PASS