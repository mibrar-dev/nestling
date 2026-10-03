# P12 · Money (ledger) — build plan (Stage 1, iteration 1)

Route `/money` (`PocketMoneyRoutePaths.ledger`), parent mode, feature `pocket_money`.
Design: `design/screens/light/P12-money.png` + `design/screens/dark/P12-money.png`
(1170×2532 @3x → divide by 3 = 390×844 logical px = Flutter dp 1:1).
HTML: `design/html-source/screens/P12-money.html`.
Seed: `Seed.demo()` anchored to Sat 3 Oct 2026 in tests (`test/flutter_test_config.dart`
pins `Seed.anchorOverride`); the app itself anchors to today. Design copy says
“Sat 4 Oct” but the seed story day is Sat 3 Oct 2026 so the weekday renders
correctly — database/anchor values win over the PNG (DATA OVER MOCKS).
Editable files (RULES.md §1): `app/lib/features/pocket_money/**`,
`app/test/features/pocket_money/**`, `docs/screens/P12/**` only.
Tokens/components only — no hard-coded colours/sizes. No `google_fonts`.
`docs/screens/P12/ORCHESTRATOR_NOTES.md` does not exist → no extra mandates.
No Pip slot on this screen → PIP rule N/A. No chips → CHIP ROWS N/A.
No `text-wrap: balance` in P12 CSS → no `NestBalancedText`.

Seed truth (assert, never hard-code in UI):
- Children in creation order: Maya then Leo (CHILD ORDER ruling).
- Maya owed £4.20 = base 300p + quests 120p (12 + 40 + 40 + 28).
- Leo owed £2.10 = base 150p + quests 60p (35 + 25).
- Goal `goal-lego` (Maya): “Lego Friends set”, target 2499p, saved 1550p → 62%.
- `families.payoutDay = 6` (Saturday), `timeZone = Europe/London`.

## (a) Widget tree, top → bottom (exact components + token spacing)

`MoneyLedgerView` replaces the placeholder `Scaffold`/`AppBar`/`ListTile` entirely.
`BlocProvider` stays at route level (`pocket_money_routes.dart`, already wired:
`GetIt.instance<PocketMoneyBloc>()..add(const PocketMoneyLoadRequested())`).
Tab bar comes from `ParentShell` (`app/lib/app/router.dart`, branch index 2 =
Money) — do NOT add `NestTabBar` in the view. OS draws status bar / home
indicator; the view only reserves space. Bottom edge (OWNER RULE): `Scaffold`
background is `tokens.paper`; nothing coloured may render below the shell tab
bar (NestTabBar paints `surface` to the edge itself, height 84 incl. 24 bottom
reserve). Side gutters are 20 everywhere; cards/bars align to x = 20…370.

`BlocBuilder<PocketMoneyBloc, PocketMoneyState>` over §b state. Loaded body:

1. `Scaffold(backgroundColor: tokens.paper, body: ListView(padding:
   EdgeInsets.fromLTRB(20, 0, 20, 32), children separated by SizedBox(height:
   16)))`. Separators are always 16 (`NestSpacing.s4`); no child adds extra
   vertical margin except where noted. All text rows use `Flexible`/`Expanded`
   + ellipsis; never overflow x 0…390.
2. `const NestStatusBar()` first (reserves 47; mock glyphs are off in the app —
   orchestrator STATUS BAR rule: ignore status-bar diffs in UI checks).
3. Title `Text('Pocket money')` — `NestType.h1(color: ink)` (Nunito 900 28/34),
   `maxLines: 1`, ellipsis, wrapped in `Padding(top: 8)` (`.ptitle` padding-top
   8). Semantics `header: true`.
4. Child switch: `NestSegmented<String>(options: [Maya, Leo], value:
   selectedChildId, onChanged: add PocketMoneyChildSelected,
   semanticLabel: 'Child')`. Options come from state children in creation
   order (Maya, then Leo). Height/padding/shadow are inside `NestSegmented`
   (do not re-specify).
5. Hero: `NestCard(variant: hero)` (bg `heroBg` — NEVER `ink`; dark hero
   #2A2640 ≠ ink. Padding 20, radius 24, `raisedShadow` come from the variant):
   `Column(crossAxisAlignment: stretch)`:
   - lab `Text('<Name> is owed')` — `NestType.chipLabel(color: onHero2)`
     (Inter 600 14/20). Dynamic name (“Maya is owed” / “Leo is owed”).
     Semantics: hero wrapped in `Semantics(label: '<Name> is owed £4.20.
     Weekly base £3.00 plus quests £1.20. Next payout Sat 3 Oct.',
     excludeSemantics: true)`? No — inner button must stay reachable, so do
     NOT exclude; instead give the texts no special semantics and the button
     its label (screen-reader reads texts + button in order).
   - amt: amount via custom `Text` (not `NestMoney`: sign logic is custom, §(b)):
     `NestType.kidHero(color: onHero).copyWith(letterSpacing: -0.4)` (Nunito
     900 40/44; −0.4 = CSS `-.01em` at 40px — orchestrator LETTER SPACING
     ruling; `NestType` defaults to 0 elsewhere, never add tracking).
     `maxLines: 1`, `softWrap: false`, ellipsis. E.g. `£4.20`.
   - brk `Text('Weekly base £3.00 + quests £1.20 · Next payout Sat 3 Oct')` —
     `NestType.chipLabel(color: onHero2).copyWith(fontWeight: FontWeight.w400)`
     (Inter 400 14/20), `margin-top: 4` → `SizedBox(height: 4)`. Middle dot is
     `·` (U+00B7) with single spaces; weekday/date from §b (NOT hard-coded
     “Sat 4 Oct”; with the Sat-3-Oct anchor the label is “Sat 3 Oct”).
   - `SizedBox(height: 14)` then `NestButton.primary(label: 'Payout time',
     fullWidth: true, minHeight: 52)` (`.hero .btn` margin-top 14, min-h 52) →
     §c. Format helpers: pounds via `(pence / 100).toStringAsFixed(2)` prefixed
     `£`; pence via `$p Kaplan`? No — pence subtitle uses `'${p}p'` (e.g.
     `+12p`).
6. Goal card (only when the selected child has a goal, else omitted):
   `NestCard()` standard (surface, r24, sh-1, padding 16): `Row(gap: 12,
   crossAxisAlignment: center)`:
   - Coin art: `SvgPicture.asset(NestlingIllustrations.coin, width: 56,
     height: 56)` (illustration keeps own colours — NEVER `NestIcon`/tint),
     `ExcludeSemantics`, shrink 0 (`.goal img` 56×56).
   - `Expanded Column(crossAxisAlignment: start)`: title
     `Text('Lego Friends set — £24.99')` — em dash `—` (U+2014) with spaces,
     `NestType.bodyStrong(color: ink)` (16 w700/22), `maxLines: 1`, ellipsis;
     caption `Text('£15.50 saved · 62%')` — `NestType.caption(color: ink2)`
     (13/18); `SizedBox(height: 8)`; `NestProgress(fraction: saved / target,
     semanticLabel: 'Savings goal progress')` (base 8px track; progressbar
     role + `aria-valuenow` ≈ labelled value comes free from the semantics).
     Card itself is display-only (no tap).
7. History card: `NestCard()` standard containing `Column`:
   - Header `Text('History')` — `NestType.h3(color: ink)` (Nunito 800 18/24),
     `maxLines: 1`, ellipsis, followed by `SizedBox(height: 4)`
     (CSS `margin-bottom: 4`).
   - One `_HistoryRow` per ledger entry of the selected child, newest first
     (the `watchLedger` order = `date` desc; DATA OVER MOCKS: the first visible
     rows come from the DB and will differ from the PNG — accepted). Row
     geometry mirrors `NestListRow` (40×40 tile radius 12, `gap: 12`,
     min-height 56, padding `10/16/10/12`) but rows are NOT tappable and carry
     NO dividers (HTML `.hrow` has none). Build with a local `_HistoryRow`
     widget in `presentation/widgets/` using tokens only (do not fork
     `core/`): `Row(spacing: 12)`: tile `Container(40×40, radius 12, color:
     tintBg, child: Center(icon 24 tintFg))` + `Expanded Column(start)`:
     title `NestType.bodySmallStrong(color: ink)` (15 w600/22 — HTML inline
     `600 15px`), `maxLines: 1`, ellipsis; sub `NestType.caption(color:
     ink2)`, `maxLines: 1`, ellipsis + trailing amount `Text` with
     `NestType.money(color: ink)` (Inter 700 tabular), `maxLines: 1`,
     `softWrap: false` (NOT `NestMoney`: signs are custom). Tile `ExcludeSemantics`.
   - Per-type mapping (icon / tint / title / sub / amount):
     * `weekly_base` → `NestIcons.poundCoin`, sky; title `Weekly pocket money`;
       sub `formatDay(date)` (e.g. `Sat 3 Oct`); amount `+£3.00`.
     * `quest_bonus` → coin illustration `SvgPicture.asset(
       NestlingIllustrations.coin, 24×24)` on `coinTint` tile (no colour filter);
       title `Quest bonus · <note>` (`·` U+00B7); sub `+<p>p · Approved`
       (e.g. `+12p · Approved`); amount `+£0.12` (`amountPence/100`, 2dp).
     * `gift` → `NestIcons.gift`, lilac; title = note verbatim
       (`Birthday money (added by Mum)` — plain parens, no dash); sub
       `To savings goal`; amount `+£10.00`.
     * `spend` → `NestIcons.bag`, peach; title `Spent · <note>`
       (`Spent · Comic`); sub `Recorded by Mum`; amount `−£2.00` with MINUS
       SIGN U+2212 + abs value (NOT hyphen `-` — compare char-by-char with HTML).
     * `payout` → `NestIcons.check`, leaf; title `Paid · <Sat 26 Sep>`
       (`Paid · ` + `formatDay` of the payout row); sub `Cash from Mum`;
       amount `£3.80` — NO sign (design shows plain `£3.80`).
     * `savings_move` → `NestIcons.saved`, lilac; title = note verbatim
       (e.g. `Birthday money → Lego fund` — arrow `→` U+2192 as seeded);
       sub `To savings goal`; amount `+£x.xx`.
   - Empty ledger (child has no rows): show `Text('No history yet',
     NestType.caption(ink2))` instead of rows (card + header stay).
8. Row buttons: `Row(spacing: 10)` with two `Expanded NestButton.secondary`:
   `label: 'Add money'` / `label: 'Record spending'`, each `minHeight: 48,
   fontSize: 15, horizontalPadding: 12` (P12 `.rowbtns` override per
   `NestButton` docs + SPACING_SPEC §2) → §c (open the edit sheet).
9. Footer caption `Text('Nestling keeps track — the real money stays with
   you.')` — em dash `—` U+2014, `NestType.caption(color: ink2)`,
   `textAlign: center`, wrap (design `.cap` centered).

Dark theme: zero theme branches — every colour via `context.nest` (paper/
surface flip per SPACING_SPEC §0; hero uses `heroBg`/`onHero`/`onHero2`;
coin illustration unchanged; button leaf flips per tokens).

## (b) BLoC events/states + repository calls (Drift via existing repo)

New/edited feature-private files (all RULES-legal under
`features/pocket_money/`):
- `domain/entities/money_child.dart`: `MoneyChild(id, nickname)` Equatable.
- `domain/entities/savings_goal_data.dart`: `SavingsGoalData(id, childId,
  title, targetPence, savedPence)` Equatable + `fraction` getter
  (`targetPence == 0 ? 0 : savedPence / targetPence`, clamped 0..1 in view).
- `domain/entities/money_ledger_data.dart`: `MoneyLedgerData(children:
  List<MoneyChild>, entries: List<PocketMoneyEntry>, oweds:
  List<OwedSummary>, goals: List<SavingsGoalData>, payoutDay: int, zoneId:
  String)` Equatable. `entries` holds ALL children newest-first (view filters
  by selected id); `oweds` one per child.
- `domain/entities/pocket_money_entry.dart`: add `dateTz: String` (the row's
  stored zone id) and map it in `_toEntity` (`dateTz: row.dateTz`). The view
  needs it for `formatDay(date, dateTz, familyZoneId: zone)` on payout /
  weekly_base rows — without it only the pre-baked `detail` string carries a
  date and the per-type copy in §a cannot render zone-correct labels.
- `domain/next_payout.dart`: pure `DateTime nextPayoutDayUtc({required int
  payoutWeekday, required DateTime nowUtc, required String zoneId})` — the
  upcoming `payoutWeekday` (DateTime Mon=1..Sun=7; Sat=6) in `zoneId`, today
  if it matches; plus `String payoutLabel(...)` = `formatDay(result, zoneId)`.
  Uses `family_time.dart` (`toFamilyZone`, `formatDay`) only.
- `domain/pocket_money_repository.dart`: add
  `Stream<MoneyLedgerData> watchLedgerData();` (keep all existing members;
  `getItems()` stays for compat).
- `data/pocket_money_repository_impl.dart`: implement `watchLedgerData()` by
  combining existing `AppDatabase` streams with `combineLatest3/4` nesting
  from `core/data/stream_combine.dart` (max arity 4 → nest: `combineLatest3(
  watchChildren, watchGoals+familyRow, ledgerParts)` or two-level combine;
  re-emits when ANY table changes):
  children = `db.watchChildren(Seed.familyId)` → `MoneyChild`;
  entries = per-child `db.watchLedger(id)` for the CURRENT children ids
  (children set is near-static; rebuild the combined stream with `switchMap`
  on the children stream — `switchMap` via plain `Stream.multi`/`asyncExpand`:
  `db.watchChildren(...).asyncExpand((kids) => combineLatest2(
  db.watchLedger(kids[0].id), kids.length > 1 ? db.watchLedger(kids[1].id) :
  Stream.value([])))` — generalise to N children with a manual fan-in, NOT a
  fixed per-child bloc subscription); oweds via existing `summarise(childId,
  rows)` pure (already tested); goals = `db.watchGoals(Seed.familyId)`;
  family row (`payoutDay`, `timeZone`) via `db.watchFamilyZoneId()` +
  one-shot `select(families)` for `payoutDay` (re-emit on zone stream; day
  value is static seed data). Map rows with existing `_toEntity` (keep its
  generic title/detail — the P12 row copy in §a is composed in the VIEW from
  `type/note/amountPence/date/dateTz`, not from `_toEntity` strings).
- `presentation/bloc/pocket_money_event.dart`: add `PocketMoneyChildSelected(
  childId)`, `PocketMoneyAddMoneySubmitted(childId, amountPence, note)`,
  `PocketMoneySpendingSubmitted(childId, amountPence, note)` (all Equatable).
- `presentation/bloc/pocket_money_state.dart`: add `data: MoneyLedgerData?`,
  `selectedChildId: String?` (null until first load → view uses
  `data.children.first.id`). Keep `status/items/errorMessage` (`items` =
  selected child's entries, kept updated for compat/tests).
- `presentation/bloc/pocket_money_bloc.dart`: `PocketMoneyLoadRequested` →
  `emit(loading)` then ONE `await emit.forEach(_repository.watchLedgerData(),
  onData: (data) => state.copyWith(status: loaded, data: data,
  selectedChildId: state.selectedChildId ?? data.firstChildId, items:
  entriesFor(selected…)), onError: failure)` — never re-add load events.
  `PocketMoneyChildSelected` → synchronous `emit(state.copyWith(
  selectedChildId, items: filtered))` (no stream work, no reload).
  Submit events → `emit` optimistic nothing; `await repository.addMoney/
  recordSpending(...)`; streams re-emit (failure → `failure` + message only
  for the submit path? keep `status: loaded`, surface error via `NestToast`
  in view on `errorMessage` change — simpler: submit errors set
  `errorMessage` + toast; state stays loaded).

Owed math: reuse `summarise()` (base + quest_bonus after latest payout only;
gift/spend/savings_move excluded) — matches £4.20 / £2.10. Formats: owed
`totalPence/100` 2dp (`£4.20`); breakdown `Weekly base £X + quests £Y`.

## (c) Every interaction → navigation (route constants)

Via `go_router` (`context.push`, never `go` — ledger is a tab root; `go`
would reset branch state, `push` preserves it):
1. Segmented Maya|Leo → `PocketMoneyChildSelected` only (no navigation;
   hero/goal/history re-render for that child; segmented thumb animates via
   `NestSegmented`).
2. `Payout time` → `context.push(PocketMoneyRoutePaths.payout)` (`/payout`,
   P13). Semantics `Payout time for <Name>`.
3. `Add money` → `showNestBottomSheet(context, title: 'Add money for <Name>',
   child: _MoneyEditSheet(mode: gift))` (shared helper: scrim barrier, 92%
   max height, `onClose` defaults to pop). Sheet content (feature-private
   `presentation/widgets/money_edit_sheet.dart`): `NestTextField(label:
   'Amount', hintText: '£0.00', keyboardType: decimal)` + `NestTextField(
   label: 'Note', hintText: 'e.g. Birthday money')` + inline error text for
   non-positive/unparseable amounts + `NestButton.primary('Add money')` →
   parses pounds→pence (`(double.parse * 100).round()`, guard tryParse) →
   `PocketMoneyAddMoneySubmitted` → pop + `showNestToast(context,
   'Added £X for <Name>')` (shared helper: floating SnackBar, 3s).
4. `Record spending` → same sheet with `title: 'Record spending for <Name>'`,
   CTA `Record spending` → `PocketMoneySpendingSubmitted` → pop +
   `showNestToast(context, 'Spent £X recorded')`.
5. History rows, goal card, hero texts, footer caption: not tappable.
6. Tab bar Today/Quests/Money/Family — owned by `ParentShell`, not this view.

## (d) Empty / loading / error states

- `initial/loading` (or `data == null`): `Center(child:
  CircularProgressIndicator(color: leaf))` inside the `Scaffold` (chrome +
  shell tab bar stay).
- `failure`: centered column: message (`NestType.bodySmall(ink2)`, maxLines 5)
  + `NestButton.secondary('Try again', fullWidth: false)` re-adding
  `PocketMoneyLoadRequested` (the only legal retry).
- `loaded` + `children.isEmpty` (Seed.empty/fresh): same scroll chrome with
  `NestEmptyState(art: SvgPicture.asset(NestlingIllustrations.coin),
  title: 'No pocket money yet', message: 'Add a child to start tracking
  pocket money.', action: NestButton.primary('Add a child', fullWidth: false)
  → `context.push(FamilyRoutePaths.addChildren)` (`/add-children`)). The art
  slot is 160×160 component-owned (do not size the Svg); title/message/action
  per component. No hero / goal / history / row buttons in this state.
- `loaded` + child has no goal: goal card omitted (no placeholder).
- `loaded` + child has no ledger rows: hero shows `£0.00` with
  `Weekly base £0.00 + quests £0.00 · Next payout <date>`; history card shows
  `No history yet` caption; row buttons + payout stay enabled.
- Long names/notes: title/sub `maxLines: 1` + ellipsis; amount `softWrap:
  false`; row `Expanded` middle absorbs overflow; 320px width safe (§e).

## (e) Accessibility (semantics, tap targets, text scale 1.3, width 320)

- Semantics: screen title `header: true`; segmented `label: 'Child'`, options
  announce selected; hero texts read in order + button labelled
  `Payout time for <Name>`; progress `semanticLabel: 'Savings goal progress'`
  (announces `62 percent`); history tiles `ExcludeSemantics`, row = plain text
  (rows are display-only, not buttons); sheet fields labelled; toast
  `liveRegion` (via `NestToast`).
- Tap targets ≥ 44×44 parent mode: segmented (44 container), hero payout 52,
  row buttons 48, sheet CTA 52, sheet close ≥ 44 (via `NestBottomSheet`
  `onClose`), empty CTA 52. Coin art/tiles/progress/caption are display-only.
- Text scale (app clamps `textScaler` 1.0–1.3): at 1.3 verify title/hero/rows
  ellipsis with no `RenderFlex overflowed`; row trailing amount keeps
  `softWrap: false` inside `Flexible`; goal title 1-line ellipsis; breakdown
  line wraps to 2 lines max (no overflow — column, not row).
- Width 320: scroll padding still 20 (content 280); row buttons `Expanded`
  (each ~135) with `fontSize: 15` labels that wrap, not overflow; history row
  middle `Expanded` + ellipsis; segmented options `Expanded`. No fixed-170 or
  fixed-width content anywhere.
- Contrast: smallest text = caption 13px ink-2 on surface/paper (≥ 4.5:1 both
  themes per token table); hero 14px `onHero2` on `heroBg` (dark: #C9C4DC on
  #2A2640 ✓); coin-tile art exempt (illustration). No red anywhere.
- Motion: no animation controllers/timers; static coin SVG; sheet uses the
  platform bottom-sheet animation (disabled under `DISABLE_ANIMATIONS` by the
  framework — no custom motion to gate).

## (f) Test plan (all under `app/test/features/pocket_money/` — new dir)

1. `pocket_money_repository_test.dart` (in-memory Drift via `setUpTestScope`):
   `summarise()` pure — Maya rows → base 300 / quests 120 / total 420; rows
   before the Sep payout ignored; gift/spend/savings_move never counted.
   `watchLedgerData()` on `Seed.demo()`: children order `['maya', 'leo']`
   (creation order, NOT alphabetical); Maya entries newest-first; oweds
   Maya 420 / Leo 210; goals → Lego 1550/2499; `payoutDay == 6`,
   `zoneId == Europe/London`.
2. `next_payout_test.dart` (pure): anchor Sat 3 Oct 2026 + payoutDay 6 →
   `Sat 3 Oct`; Mon 5 Oct → `Sat 10 Oct`; fake zone `Asia/Dubai` still formats
   via stored zone.
3. `pocket_money_bloc_test.dart` (`bloc_test`): load → loading→loaded with
   data + default selected `maya` + items filtered to Maya; `ChildSelected(
   'leo')` → selected leo, items = Leo rows, no reload event; submit add-money
   → ledger grows (stream re-emit); stream error → failure + message.
4. `money_ledger_view_test.dart` (widget, `setUpTestScope(seedDemo: true)` +
   `pumpAppRoute(tester, '/money')`, end EVERY test with `disposeApp(tester)`):
   light finds `Pocket money`, `Maya`, `Leo`, `Maya is owed`, `£4.20`,
   `Weekly base £3.00 + quests £1.20 · Next payout Sat 3 Oct` (middle dot
   U+00B7), `Payout time`, `Lego Friends set — £24.99` (em dash U+2014),
   `£15.50 saved · 62%`, `History`, `Add money`, `Record spending`,
   `Nestling keeps track — the real money stays with you.`; tap `Leo` →
   `Leo is owed` + `£2.10`; tap `Payout time` → `pushedPath == '/payout'`;
   tap `Add money` → sheet `Add money for Maya`, enter `5.00` + note, Save →
   toast + ledger contains the row; dark (`ThemeMode.dark`) same finds.
   Empty scope (`Seed.empty()` variant): finds `No pocket money yet` +
   `Add a child`, tap → `/add-children`. NO `google_fonts` import anywhere.
5. Copy audit (in view test): exact code points — `—` U+2014 ×2
   (goal title, footer), `·` U+00B7 (breakdown, history titles/subs), `−`
   U+2212 (spend amount), `→` U+2192 only inside seeded savings-move notes.
6. A11y/size: `textScaler: 1.3` + 320×844 surface → no
   `RenderFlex overflowed` (`tester.takeException()` null); 44px asserts on
   segmented options, `Payout time`, both row buttons, sheet CTA.
   A11y-actions (orchestrator rule): for every control (segmented options,
   `Payout time`, `Add money`, `Record spending`, sheet Save + Close, empty
   `Add a child`, error `Try again`) assert
   `getSemantics(f).getSemanticsData().hasAction(SemanticsAction.tap)` and
   that `performAction(SemanticsAction.tap)` changes real state or DB
   (segmented → hero re-renders for Leo; Save → new ledger row in DB).
   Never wrap a control in `Semantics(excludeSemantics: true)` without
   passing `onTap:` on that node (`NestButton`/`NestSegmented` already
   expose tap via their GestureDetector/InkWell — do not add extra
   Semantics wrappers that would swallow the action).
7. `dart format .` clean, `flutter analyze` → No issues found, full
   `flutter test` green. NEVER `flutter clean`; NEVER boot a simulator
   (only stage 5_ui may use one).

## (g) SHARED_REQUEST needed?

None blocking. No schema/seed/router/DI/design-system change: children,
ledger, goals, `payoutDay` and zone are all readable from existing tables via
the feature's own repository (RULES-legal `data/`+`domain/` edit); tab bar,
status/home chrome and `/payout` + `/add-children` routes already exist;
per-type history icons (`check`, `poundCoin`, `gift`, `bag`, `saved`, coin
illustration) all exist in `NestlingIcons`/`NestlingIllustrations`;
`NestSegmented`, `NestCard(hero)`, `NestButton`, `NestProgress`,
`NestBottomSheet` (+`showNestBottomSheet`), `NestTextField`,
`NestEmptyState`, `NestToast` (+`showNestToast`) cover every element.

Watch-items (NOT blocking, do not work around locally):
- `NestSegmented` renders 44 total height (44 container incl. 4 padding,
  36 thumb) while SPACING_SPEC §178 / design CSS (padding 4 + 44 button)
  give 52 total. Shared code — the P12 builder must NOT pad/shrink locally
  to chase it. If the UI check flags the pill-rect drift, file
  `SHARED_REQUEST.md` then.
- Same-feature coordination: P06 (`pocket_money_setup_view.dart`) and P13
  (`payout_view.dart`, `recordPayout`) share `pocket_money_bloc/event/state`,
  the repository and entities. Touch only: `money_ledger_view.dart`, new
  `presentation/widgets/money_*.dart`, bloc additions (additive events/fields
  only — never rename/remove members P06/P13 use), repository additions
  (additive methods only), `pocket_money_entry.dart` (`dateTz` add only).
  Never edit `payout_view.dart` / `pocket_money_setup_view.dart` content
  beyond what compiles; the loop merges main before each build.

VERDICT: PASS
