# P08 · Today (home) — build plan (Stage 1, iteration 1)

Route `/today` (`TodayRoutePaths.today`), parent mode, feature `today`.
Design: `design/screens/light/P08-today.png` + `design/screens/dark/P08-today.png`
(1170×2532 @3x → divide by 3 = 390×844 logical px = Flutter dp 1:1).
HTML: `design/html-source/screens/P08-today.html`.
Seed: `Seed.demo()` (Sarah + Maya 9/lilac/stage-3/120 coins + Leo 6/peach/stage-2/45 coins,
12 active quests, 3 `done_pending`).
Editable files (RULES.md §1): `app/lib/features/today/**`,
`app/test/features/today/**`, `docs/screens/P08/**` only.
Tokens/components only — no hard-coded colours/sizes (RULES + SPACING_SPEC §10).

## (a) Widget tree, top → bottom (exact components + token spacing)

Scaffold (no AppBar; tab bar comes from `ParentShell` in `app/lib/app/router.dart` —
do NOT add `NestTabBar` in the view; system status bar/home indicator are real
chrome, not HTML mocks).

Body: `BlocProvider` is at route level (`today_routes.dart`, already wired:
`GetIt.instance<TodayBloc>()..add(const TodayLoadRequested())`). `TodayView`
is `BlocBuilder<TodayBloc, TodayState>` on the extended state (§b):

1. `ListView`, padding `EdgeInsets.fromLTRB(NestSpacing.padSide=20, 0, 20, 32=s8)`,
   separators `SizedBox(height: NestSpacing.s4=16)` between children, EXCEPT
   group-label→first-card gap = 8 (`s2`; `.qgroup{margin:16 0 -8}` over the 16 base).
   All math from SPACING_SPEC §§1,8–9. No horizontal overflow: every text-bearing
   row uses `Flexible`/`Expanded` + ellipsis.
2. Greeting row (`.greet`: `padding-top: 8=gap8`, row, `gap: 8=s2`,
   space-between, center):
   - `Expanded` column: title `Text('Good morning, Sarah')` —
     Nunito 900 22/28 ls −1% (`NestType.h2(color: ink).copyWith(fontSize: 22,
     height: 28/22)`; P08 override of base h1 — SPACING_SPEC §8), `maxLines: 1`,
     ellipsis. Name/greeting/day-part from state (§b).
     Subtitle `Text('Sat 4 Oct · Happy week: 4 days')` — Inter 500 15/22
     (`NestType.bodySmall(color: ink2).copyWith(fontWeight: w500,
     letterSpacing: -0.15)` — ≈ CSS `-.01em`), `margin-top: 2=gap2`, maxLines 1.
   - Actions row `gap: 8`: `NestIconButton(icon: NestIcons.plus,
     semanticLabel: 'New quest', size: 44, iconSize: 24,
     backgroundColor: tokens.leaf, foregroundColor: tokens.onLeaf,
     borderColor: Colors.transparent)` (`.newquest`: 44 circle, leaf bg,
     surface fg, `sh-1`; shadow comes free via non-transparent bg) → §c.
     Avatar button: 44 circle `InkWell` wrapping
     `NestAvatar(initial: 'S', size: s44, color: leaf)` → §c.
3. Approvals banner (visible only when `pendingCount > 0`): `NestCard`
   (standard geometry but leaf-tint fill — implement as `Container`: bg
   `tokens.leafTint`, radius `NestRadii.allL=24`, shadow `tokens.cardShadow`,
   padding `16=s4`; NestCard has no leaf-tint variant, and RULES forbids touching
   `core/` — local Container with tokens is compliant), row `gap: 12=s3`,
   center: `Expanded` column (title Inter 700 16/22 `leafInk`, `textWrap: balance`
   ≈ `softWrap: true, maxLines: 3`; subtitle Inter 500 13/18 `leafInk`
   with `alpha .85` → `leafInk.withValues(alpha: .85)`), plus
   `NestButton(label: 'Review', fullWidth: false, minHeight: 44,
   fontSize: 15, horizontalPadding: 18=gap9×2)` (P08 `.banner .btn` override,
   SPACING_SPEC §2) → §c.
4. Kids 2-up grid: `Row(gap: 10=gap10)` with two `Expanded` cards (colW =
   `(W − 40 − 10) / 2`; at 390 → 170 each; NEVER fixed 170 — SPACING_SPEC §10.2).
   Each card: `NestCard(padding: EdgeInsets.all(14=gap14))` (P08 card override),
   column: top row (`gap: 8`): `NestAvatar(initial: 'M'/'L', size: s32,
   color: lilac/peach from `avatarColour` map: lilac→lilac, peach→peach,
   sky→sky, leaf→leaf, coin→coin, else neutral) + `Expanded` column (name:
   Nunito 800 17/22 → `NestType.h3(ink).copyWith(fontSize: 17, height: 22/17)`,
   maxLines 1 ellipsis; sub `'4 of 6 quests'`: Inter 13/18 ink2 =
   `NestType.caption`); Pip art `SvgPicture.asset(pipStageAsset(stage),
   width: 72, height: 72)` centered with `margin: 6=gap6 top, 2=gap2 bottom`
   (`NestlingIllustrations.pipStage1/2/3` by `pipStage`; exclude semantics,
   wrap in `Semantics(label: "Maya's Pip, a fledgling", image: true)`);
   `NestProgress(fraction: done/total, semanticLabel: "<Name>'s quest progress")`
   (base 8px track — `kid: false`); `SizedBox(height: 10=gap10)`;
   `NestCoinPill(amount: '120', size: standard)` (16px pill, icon 20).
5. Section header (`.sec-t`): row space-between center: `Text("Today's quests")`
   Nunito 800 18/24 = `NestType.h3(ink)`; leaf link `'See all'` (Inter 600 14,
   `leaf`, `minHeight: 44` tap via `Padding(12 vertical)+InkWell` or `TextButton`
   with 44 constraints) → §c.
6. Per child group: label `Text('MAYA · 9')` = `NestType.sectionLabel`
   (13 w700 uppercase ls +6%, ink2; age from `ageYears` via summaries — see §b
   extension; fallback `'MAYA'` only if unknown). Margin: top 16 is the list
   separator; bottom gap to first card 8 (s2).
   Quest rows: `NestQuestCard(title: ..., maxLines: 2, onTap: ...)` (P08 wins over
   base single-line — SPACING_SPEC conflict §9.2; `softWrap` already true):
   - `leading`: 40×40 tinted tile — `Container(40×40, radius 16=r-m,
     color: tintBg, child: Center(NestIcon(icon, size: 24, color: tintFg)))`.
     Tint map (from `.icon-tile` + HTML `tint-*`): sky→(skyTint, sky),
     lilac→(lilacTint, lilac), leaf→(leafTint, leafInk), peach→(peachTint, aPeach),
     coin→(coinTint, coinInk). Default sky.
   - `meta`: `'· Daily'`-style repeat string (Inter 13/18 ink2). Build from
     quest repeat: `Once→'· Once'`, `daily→'· Daily'`,
     `weekly→'· Weekly · Sat'` (payout weekday from families.payoutDay; Sat=6).
     Repeat text is NOT in `TodayItem` today — §b adds `repeatRule` to the entity.
   - `metaChips`: [`NestCoinPill(amount: '<coins>', size: xSmall)` (13px,
     pad 5/9, icon 15 — P08 inline override), status chip]. Order in HTML:
     coin pill, repeat text (as `meta:`), status chip — reproduce via
     `meta: '· Daily'` + `metaChips: [coinPill, statusChip]`? NOTE: HTML order is
     coin → repeat → status. `NestQuestCard` renders `meta` text FIRST then
     `metaChips`. So pass `meta: null` and
     `metaChips: [coinPill, Text('· Daily', caption ink2), statusChip]` to keep
     exact order.
   - Status chip: `Container(height: 26, padding: 0 10=gap10 horizontal,
     radius: pill, color: bg, child: Center(Text(label, NestType.chipSmall(fg))))`,
     `softWrap: false`, maxLines 1. Map: `done_pending`→('Needs a look',
     coinTint, coinInk); `to_do`→('To do', surface2, ink2);
     `approved`→('Approved ✓', leafTint, leafInk); `not_yet`→('Try again',
     surface2, ink2).
   - `trailing`/`done`: none on P08 (no check circles in design). `onTap` → §c.
   - `semanticLabel`: `'<title>, <coins> coins, <status label>'`.
7. `'Hand to Maya or Leo'` button: `NestButton.secondary(label: ...,
   leading: NestIcon(NestIcons.phone, size: 20), fullWidth: true)` (base 52px;
   HTML `btn-secondary` + phone glyph) → §c.
8. Quest icon map (seed `quests.icon` → `NestIcons`): dishwasher→dishwasher,
   book→book, bins→bin, bed→bed, hoover→hoover, paw→paw, bag→schoolBag,
   leaf→sprout, shirt→washingMachine, plate→table, sofa→questCard fallback?
   CHECK: `table` asset exists (`NestIcons.table`); sofa has NO asset →
   fallback `NestIcons.questCard`. plate→`table`. Unknown → `questCard`.
   (P08 visible rows need only dishwasher/book/bin/bed/paw — all exist.)

Dark theme: everything via `context.nest` tokens (leaf-tint/paper/surface flip
per SPACING_SPEC §0 table) — zero theme branches in feature code. Banner text
uses leafInk (dark: #8EE6BC on #173A2B ✓ contrast).

## (b) BLoC events/states + repository calls (Drift via existing repo)

Extend (feature-private, RULES-legal) — builder edits these files:
`presentation/bloc/today_event.dart`, `today_state.dart`, `today_bloc.dart`,
`domain/entities/today_item.dart` (+`repeatRule` field), `domain/entities/child_day_summary.dart`
(+`ageYears`), `domain/today_repository.dart`, `data/today_repository_impl.dart`.

State (all Equatable, default `initial`):
```dart
TodayState(status, items, summaries, pendingCount, parentName, greeting, dateLine, happyDays, errorMessage)
```
- `items: List<TodayItem>` (existing, +`repeatRule: String` field, default `''`).
- `summaries: List<ChildDaySummary>` (+`ageYears: int?` field) — drives kids cards
  + group labels.
- `pendingCount: int` = items where `status == 'done_pending'`.
- `parentName: String` ('Sarah'), `greeting: String` ('Good morning'),
  `dateLine: String` ('Sat 4 Oct · Happy week: 4 days'), `happyDays: int` (4).
- `status/errorMessage` unchanged (`initial/loading/loaded/failure`).

Events: keep `TodayLoadRequested` only (RULES §4: blocs subscribe via
`emit.forEach` — never re-add load events to refresh).

Bloc handler: on `TodayLoadRequested`: `emit(loading)`, then
`await emit.forEach(combineLatest2(repository.watchItems(),
repository.watchSummaries()) ...)` — hmm, repo has two separate streams; simplest
contract-compliant: subscribe `watchItems()` with `emit.forEach`, and inside
`onData` compute `pendingCount`; second subscription for summaries/parent/meta:
use `combineLatest2` from `core/data/stream_combine.dart` (already used in impl).
Concretely builder implements in bloc:
```dart
await emit.forEach(
  combineLatest2(_repository.watchItems(), _repository.watchSummaries()),
  onData: (parts) { items...; summaries...; pending...; meta...;
    return state.copyWith(status: loaded, ...); },
  onError: ...failure...);
```
Greeting: `hour = toLondon(DateTime.now()).hour`: <12 'Good morning',
<18 'Good afternoon', else 'Good evening'. `dateLine =
'${formatLondonDay(now)} · Happy week: $happyDays days'` (use `london_time.dart`
`formatLondonDay` — tokens only, no new dep). `parentName`: new repo call
`watchParentName()` (members row id 'sarah' — first member by name; impl:
`(_db.select(_db.members)..where((m) => m.familyId.equals(Seed.familyId)))`
`.watchSingle()` mapped to `.name`). `happyDays`: max over summaries' child
`happyDays` — needs child field: add `happyDays` to `ChildDaySummary` (from
`ChildrenData.happyDays`) and compute `max`. So three repo streams combined via
`combineLatest3(..., watchParentName())`.

Repository additions (interface + impl, Drift only, no schema change):
- `Stream<String> watchParentName()` (members table, family `fam1`).
- `TodayItem` gains `repeatRule` (from `Quest.repeatRule`); `ChildDaySummary`
  gains `ageYears`, `happyDays` (from `ChildrenData`).
- `rows()` pure builder updated + unit-tested (grouping by child, α-sorted
  quests, latest-completion status — keep existing semantics).

`getItems()` stays for tests. No new tables/columns → no migration, no seed change.

## (c) Every interaction → navigation (route constants)

All via `context.go(...)` (go_router; paths from feature `*_routes.dart`):
1. `+` New-quest button → `QuestsRoutePaths.editor` (`/quest-editor`, P09 sheet).
2. Avatar `S` button → `FamilyRoutePaths.childProfile`? NO — avatar is the
   parent's own profile; there is no parent-profile route. Spec: avatar opens
   Family/Settings area. Decision: → `/settings` (`SettingsRoutePaths.settings`,
   P16 lists Sarah/James). Semantics 'Sarah's profile'.
3. `Review` (banner) → `ApprovalsRoutePaths.approvals` (`/approvals`, P11).
   Banner hidden when `pendingCount == 0`.
4. Kid card tap → `FamilyRoutePaths.childProfile` (`/child-profile`, P15)
   with `queryParameters: {'childId': summary.childId}` (P15 shows per-child —
   builder passes id; if P15 ignores params, still lands correctly).
5. `See all` → `QuestsRoutePaths.library` (`/quests`, P10).
6. Quest row tap → `QuestsRoutePaths.editor` + `queryParameters:
   {'questId': item.questId}` (P09 edits existing; new-quest omits param).
7. `Hand to Maya or Leo` → `KidHomeRoutePaths.picker` (`/who-is-playing`, K01).
8. Tab bar (Today/Quests/Money/Family) — owned by `ParentShell`, not this view.
9. Group labels / progress / coin pills: not tappable (coin pill
   `ExcludeSemantics` inside, outer label via card semantics).

## (d) Empty / loading / error states

- `initial/loading`: `Center(child: CircularProgressIndicator(color: leaf))`.
- `failure`: centered column: caption-friendly message (ink2, maxLines 5) +
  `NestButton.secondary('Try again', fullWidth: false)` re-adding
  `TodayLoadRequested` (only legal retry — single-shot event, not a refresh loop).
- `loaded` + `summaries.isEmpty` (Seed.empty): same chrome (greeting + banner
  hidden + no kids + no groups) with `NestEmptyState(art: SvgPicture pipStage1
  140×140, title: 'Your nest is quiet',
  message: 'Add your first quest and Pip will start to hatch.',
  action: Column[NestButton.primary('Add a quest') → /quest-editor,
  NestButton.ghost('Browse ideas') → /quests])` inside the scroll. P08b spec
  wants an `.empty-card` (surface, r24, sh-1, padding 28/20, img 140, h2 22,
  body 15 maxW 260) — implement as `NestCard(standard, padding:
  EdgeInsets.fromLTRB(20, 28, 20, 28))` wrapping the `NestEmptyState` content
  (NestEmptyState padding 24/16 stays; net matches within 4px). `TodayEmptyView`
  (`/today-empty`) renders the identical widget (shared private widget
  `TodayLoadedBody` + `TodayEmptyCard` in `presentation/widgets/`).
- `loaded` + `pendingCount == 0` but items exist: banner omitted, rest identical.
- Long titles: quest `maxLines: 2` wrap (P08 balance rule); greeting/names
  ellipsis 1 line; coin pill `Flexible` inside; never overflow x 0…390.

## (e) Accessibility

- Semantics: greeting heading `header: true`; banner `liveRegion` label
  `'<n> quests waiting for your thumbs-up'`; progress bars labelled per child;
  coin pills `'$amount coins'` (built into `NestCoinPill`); quest rows button
  with `'<title>, <coins> coins, <status>'`; icon tiles `ExcludeSemantics`;
  Pip art `image` with `"<Name>'s Pip, a <stage-name>"` (stage names:
  1 Egg, 2 Hatchling, 3 Fledgling, 4 Songbird).
- Tap targets ≥ 44×44 parent mode: plus/avatar 44; Review 44 high; See-all link
  44 high; quest rows full-width (height ≥ 56 by content); Hand button 52;
  status chips/coin pills/progress are display-only (inside tappable row).
- Text scale: app clamps `textScaler` 1.0–1.3 (SPACING_SPEC §10.1); at 1.3 verify:
  greeting ellipsis, kid-card name/sub 1-line ellipsis, chips `Flexible` +
  ellipsis, group label wraps (uppercase short strings — safe).
- Width 320: kids `Row` uses `Expanded` (colW = (320−40−10)/2 = 135) — content
  must fit 135px: avatar+name row wraps via `Expanded` column + ellipsis;
  Pip 72 + pill keep (min); quest meta `Wrap` (NestQuestCard uses Wrap) runs to
  2 lines. No fixed-170 widths anywhere.
- Contrast: body ≥ 15px parent (spec §0.9): smallest text = status chip 12px
  w700 on coin-tint/leaf-tint/surface-2 — coin-ink #6B4E00 on #FFF4D1 ≈ 7:1 ✓;
  leaf-ink on leaf-tint ✓; ink-2 on surface-2 ✓ (all ≥ 4.5:1; dark tokens per
  §0 table preserve ratios — verify in dark screenshot review).
- No red anywhere (kind-motivation rule); no timers/animation (motion rule —
  static SVG Pip; `kDisableAnimations` irrelevant, no Rive/Lottie here).

## (f) Test plan (all under `app/test/features/today/` — new dir)

1. `today_repository_test.dart` (pure + drift-memory): `rows()` groups by child,
   α-sorts quests, picks latest completion status (`to_do/done_pending/approved/
   not_yet`), carries `repeatRule`; `watchSummaries()` demo → Maya(done 4?—see
   note, total 6, coins 120, stage 3), Leo(total 4, coins 45, stage 2);
   `watchParentName()` → 'Sarah'. NOTE: `done` counts `done_pending+approved`:
   demo Maya = dishwasher+table pending + bins+hoover approved = 4 ✓ '4 of 6';
   Leo = bed pending + bag approved = 2 ✓ '2 of 4'. Progress fractions 4/6≈.67,
   2/4=.5 match HTML `width:67%/50%` ✓.
2. `today_bloc_test.dart` (`bloc_test`): load → loading→loaded with items+
   summaries+pendingCount 3; stream error → failure + message; seeded empty DB →
   loaded with empty lists.
3. `today_view_test.dart` (widget, `setUpTestScope(seedDemo: true)` +
   `pumpAppRoute(tester, '/today')`, end with `disposeApp(tester)` — RULES §7):
   light: finds 'Good morning, Sarah', 'Sat 3 Oct' (seed anchor — NOT 'Sat 4 Oct';
   seed uses Sat 3 Oct 2026 so weekday renders correctly), banner '3 quests
   waiting', 'Review', 'Maya', 'Leo', '120', '45', 'Today's quests',
   'Empty the dishwasher', 'Reading – 20 minutes', 'Hand to Maya or Leo';
   taps Review → `/approvals`; taps + → `/quest-editor`; taps Hand → K01.
   dark (`ThemeMode.dark`): same finds (contrast eyeball via shot.sh compare).
   empty (`Seed.empty` scope variant): finds 'Your nest is quiet' + 'Add a quest'.
4. A11y/size tests: `textScaler: 1.3` + 320×844 surface (`tester.view.physicalSize
   = 320*3, 844*3`): no `RenderFlex overflowed` (take `tester.takeException`
   null), plus `expect(tester.getSize(find...).height >= 44)` on plus/Review/
   See-all/Hand targets.
5. `dart format .` clean, `flutter analyze` no issues, full `flutter test` green.

## (g) SHARED_REQUEST needed?

None. No schema/seed/router/DI/design-system change required:
- Parent name + happy days + repeat rules all readable from existing tables via
  the feature's own repository (RULES-legal `data/`+`domain/` edit).
- Missing sofa/plate icons handled by in-feature fallback to `NestIcons.questCard`
  (no new `core/` asset requested; optional follow-up request if orchestrator
  wants dedicated glyphs — non-blocking, file only if builder hits an unknown
  icon at runtime).
- Tab bar, status/home chrome owned by shell — no route change (`/today` and
  `/today-empty` already registered).

VERDICT: PASS
