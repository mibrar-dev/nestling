# K03 Kid home — build plan (Stage 1, iteration 1)

Scope: `kid_home` feature, route `/kid-home` (`KidHomeRoutePaths.home`), kid mode.
Design: `design/screens/light/K03-kid-home.png` + `design/screens/dark/K03-kid-home.png`
(1170x2532 @3x; all numbers below are logical px = PNG px / 3).
HTML: `design/html-source/screens/K03-kid-home.html`.
Spec: DESIGN_SPEC §5 K03; SPACING_SPEC §§2/4/6/7/10/11.

Demo data (Seed.demo, source of truth — RULES §4, do NOT fork):
Maya `maya`: nickname Maya, avatarColour `lilac`, coins 120, pipStage 3 (fledgling),
happiness 4, happyDays 4. Maya quests (6, repo sorts alphabetically by title):
q-bins approved(15), q-dishwasher done_pending(15), q-hoover approved(20),
q-table done_pending(10), q-reading to_do(10), q-tidy to_do(15).
So live counts are done=4/total=6 (done = approved + done_pending).
The PNG copy says "3 of 6 done" / "3 done today" — stale design copy; the UI
renders the live counts ("4 of 6 done" under demo). Logged in §(g), not blocking.

## (a) Widget tree, top → bottom (exact components + spacing)

Root: `KidScope` (sky gradient + 390x136 meadow hill pinned bottom — matches
`.meadow` 390x136 in HTML) > `Scaffold(backgroundColor: transparent)` >
`Column` (no AppBar; kid screens have no nav bar, no tab bar):

1. `NestStatusBar(time: '9:41')` — h47 (`NestDevice.statusH`), padding top 12 /
   horizontal 24, ink colour (kid keeps ink in both themes, SPACING §1).
2. Header `Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 10))` (`.k3-top`,
   HTML l.19) > `Row(spacing: 8)`:
   - `NestAvatar(initial: first letter of nickname, size: s64, color: mapped
     from child.avatarColour: lilac→lilac, peach→peach, sky→sky, leaf→leaf,
     coin→coin, else neutral)` — 64 circle (PNG ~192px).
   - `Expanded > Column(crossAxisAlignment: start, mainAxisSize: min)`:
     `Text('Hi {nickname}!')` — screen style `.k3-name`: Nunito 22/26 w900 ink
     (no exact NestType; use `GoogleFonts.nunito(22, 26/22, w900, ink)`,
     colour from `context.nest` token only);
     `Text('{done} done today')` — `.k3-sub`: Nunito 15/20 w700 ink2, same pattern.
   - `NestCoinPill(amount: '{coins}')` — standard: 16 w800, padding 8x12, icon 20.
   - `NestLockButton(large: true, onPressed: push gate, semanticLabel: 'Grown-ups')`
     — 56x56, r18 (`.lock-btn.lg`, HTML l.13; `large` gives `NestDevice.tapKid`=56).
3. `Expanded > ListView(padding: EdgeInsets.fromLTRB(20, 0, 20, 32))`
   (`.scroll` base; separator 16 between blocks) containing:
   - `NestPetStage(stage: mapped from child.pipStage (1→egg, 2→hatchling,
     3→fledgling, 4→songbird; see `PipStage` in `motion/pip_rive.dart`),
     mood: PipMood.idle, speech: "Let's do some quests!")` — bubble: surface,
     3px ink border (`context.nestKid.borderWidth`), r18, padding 8x14,
     Nunito 16/24 w800, maxW 260 + tail; art ~152px Pip on 260x236 nest
     (PNG pip ~456px → 152 logical; component scales geometry itself).
   - Hearts `Row(spacing: 8)` (`.k3-hearts`): `filled` = clamp(happiness,0,5)
     × `NestIcon(NestIcons.heart, size: 26)` tinted coin (filled hearts use
     `var(--coin)` fill in HTML l.57) + `5-filled` ×
     `NestIcon(NestIcons.heartOutline, size: 26)` tinted ink3;
     + `Text('Pip is happy today')` — `.kcap`: Nunito 15/20 w700 ink2
     (always positive framing, never negative — product principle).
   - Section `Row(spacing: 10)` (`.k3-sec`): `Expanded > Text("Today's quests",
     style: NestType.kidTitle ink)` (28/34 w900) + count chip
     `KidStatusChip(label: '{done} of {total} done')` (see feature widget below).
   - `NestProgress(fraction: done/total, kid: true,
     semanticLabel: "{done} of {total} of today's quests done")` — h16
     (`NestSpacing.s4`), 2px ink border, surface track, leaf fill + gloss.
   - `Column(spacing: 12)` (`.k3-quests` gap 12) of cards, one per `state.items`
     in repo order (alphabetical — visual order differs from PNG sample order;
     data order wins, do NOT re-sort):
     `NestKidQuestCard(title, icon: NestIcon(mapped, size: 28), done, coinAmount
     OR metaChip, onTap, onToggled)` — min-h 72, padding 12, r24 (`NestRadii.l`),
     3px ink border, kid shadow; icon tile 48x48 r16 (component renders
     `surface2` tile — accepted drift vs HTML tinted tiles, see §(g));
     title ≤2 lines ellipsis; check 56 circle (`NestDevice.tapKid`), 3px border,
     done → leaf fill + 28 check icon onLeaf.
     Icon map from `KidQuest.icon` string: dishwasher→`NestIcons.dishwasher`,
     book→`NestIcons.book`, bed→`NestIcons.bedSit` (K03 glyph per
     `nestling_assets.dart`), bins→`NestIcons.bin`, hoover→`NestIcons.hoover`,
     plate/table→`NestIcons.table`, fallback→`NestIcons.questCard`.
     Per-status card content:
     - `to_do` / `not_yet`: `coinAmount: '+{coins}'` (NestCoinPill standard),
       `done: false`, check tappable (see §c).
     - `done_pending`: `metaChip: KidStatusChip(label: 'Waiting for Mum')`,
       `done: true`, check NON-interactive (`onToggled: null`,
       semantics 'Waiting for Mum's thumbs-up').
     - `approved`: `metaChip: KidStatusChip(label: 'Done')`, `done: true`,
       check non-interactive.
4. Dock `Container(color: surface, border: Border(top: 3 ink),
   padding: EdgeInsets.fromLTRB(20, 12, 20, 10))` (`.k3-dock`, HTML l.31) >
   `Row(spacing: 12)` with 3 × `Expanded > NestKidButton(axis: vertical, gap: 4,
   minHeight: 66, fontSize: 17, contentPadding: EdgeInsets.symmetric(horizontal: 6),
   fullWidth: true, …)`:
   - Pip — `color: lilac`, `icon: NestIcon(NestIcons.pipFace)`, label 'Pip'.
   - Shop — `color: coin`, `icon: NestIcon(NestIcons.bag)`, label 'Shop'.
   - My jar — `color: leaf`, `icon: NestIcon(NestIcons.jar)`, label 'My jar'.
   (Component tints icons 26 via IconTheme; PNG shows 24 — accept 26.)
5. `NestHomeIndicator()` — h34, 134x5 pill ink@90%.

Feature-private widget (new file
`app/lib/features/kid_home/presentation/widgets/kid_status_chip.dart`):
`KidStatusChip({required label})` — static (non-interactive) pill matching
`.kchip` (HTML l.16): h32, padding 0x12, r-pill, bg `leafTint`, fg `leafInk`,
Nunito 800 15/15, nowrap ellipsis. (NestChip is parent-mode Inter 14 — wrong
font/role — so a feature-private chip from tokens is required, not a fork.)
Use for the section "X of Y done" chip and card meta chips.

Colours/sizes: every colour via `context.nest` (`NestTokens`); spacing via
`NestSpacing`/`NestDevice`; radii via `NestRadii`; type via `NestType` except
the two screen-exact styles (`.k3-name` 22/26 w900, `.k3-sub`/`.kcap` 15/20 w700,
`.kchip` 15 w800) which use `GoogleFonts.nunito` with token colours, citing
this plan. No hex literals, no magic numbers. Motion: `kDisableAnimations`/
`MediaQuery.disableAnimations` → `NestPetStage` SVG still path (already built
into the component); no timers/controllers on this screen.

## (b) BLoC + repository (local Drift via existing repo — no new repo methods)

State (`kid_home_state.dart`, extend — same file, K01/K02/K04/K05 share it):
```dart
final class KidHomeState extends Equatable {
  const new({status, this.child, this.items = const [], this.errorMessage, this.actionError});
  final KidHomeStatus status; final KidChild? child; final List<KidQuest> items;
  final String? errorMessage; final String? actionError;
  int get doneCount => items.where((q) => q.status == 'approved' || q.status == 'done_pending').length;
  int get totalCount => items.length;
  double get fraction => totalCount == 0 ? 0 : doneCount / totalCount;
  copyWith(...); props += [child, actionError];
}
```

Events (`kid_home_event.dart`, add ONE):
- `KidHomeLoadRequested` (existing, fired once by `kidHomeRoute` builder).
- `KidHomeQuestCompleted({childId, questId, coins})` — new, K03 check taps only.
  (K04 will add its own completion event later; K03 must not pre-empt it.)

Bloc (`kid_home_bloc.dart`):
- On `KidHomeLoadRequested`: `emit(loading)`; `await emit.forEach(
  combineLatest2(repo.watchActiveChild(), repo.watchItems()), onData: (parts) =>
  state.copyWith(status: loaded, child: parts[0] as KidChild?, items: parts[1]
  as List<KidQuest>), onError: (e,_) => state.copyWith(status: failure,
  errorMessage: e.toString()))`. Uses `core/data/stream_combine.dart`
  (read-only import, no shared edit). Never re-add load events to refresh.
- On `KidHomeQuestCompleted`: `try { await repo.completeQuest(childId, questId); }
  catch (e) { emit(state.copyWith(actionError: e.toString())); }`
  (stream re-emits → card flips to done_pending automatically; no manual refresh).
- No new repository interface methods: `watchActiveChild()`, `watchItems()`,
  `completeQuest()` all exist on `KidHomeRepository`/`KidHomeRepositoryImpl`.

## (c) Interactions → navigation (exact route constants)

| Element | Action | Destination |
|---|---|---|
| Quest card body tap (any status) | `context.push(KidHomeRoutePaths.detail, extra: {'questId': item.questId, 'childId': child.id})` | `/quest-detail` (K04; K04 builder contract: read `state.extra as Map`) |
| Check on `to_do`/`not_yet` card | `bloc.add(KidHomeQuestCompleted(...)); context.push(KidHomeRoutePaths.complete, extra: {'questId','childId','coins'})` | `/quest-complete` (K05 celebration) |
| Check on `done_pending`/`approved` | none (non-interactive, semantics label only) | — |
| Dock Pip | `context.go(PipRoutePaths.nest)` | `/pip` (K06) |
| Dock Shop | `context.go(KidShopRoutePaths.shop)` | `/reward-shop` (K08) |
| Dock My jar | `context.go(KidJarRoutePaths.jar)` | `/my-jar` (K09) |
| Lock button | `context.push(ParentalGateRoutePaths.gate)` | `/parental-gate` (P17) |

`go` for dock (sibling roots), `push` for detail/complete/gate (return to home).
Imports of `pip_routes.dart`, `kid_shop_routes.dart`, `kid_jar_routes.dart`,
`parental_gate_routes.dart` path-constant files are read-only cross-feature
imports (constants only — allowed; no feature code touched).
No back button on K03 (kid home is the hub). No FAB, no tab bar, no £ anywhere
(coins only — `NestCoinPill`).

## (d) Empty / loading / error states

- Loading (`initial`/`loading`, or `child == null` while loaded): `KidScope` bg
  kept + `Center(child: CircularProgressIndicator(color: leaf))`, semantics
  'Loading your quests'.
- Failure: kid-friendly `Center` column: Pip stage-1 art (140px via
  `NestlingIllustrations.pipStage1`), `Text('Oh no! Pip got lost.',
  kidTitle-ish h2)`, sub "Let's try again.", `NestKidButton.white('Try again',
  onPressed: () => bloc.add(KidHomeLoadRequested()))` (failure-only retry is
  allowed; streams self-update otherwise). `actionError` (completeQuest fail):
  keep list, show `SnackBar(content: Text('Hmm, that did not work. Try again.')))`.
- Empty child (kid mode with no active child): message "Who's playing?" +
  `NestKidButton.lilac('Choose', onPressed: go picker)` → `KidHomeRoutePaths.picker`.
- Empty quests (`items.isEmpty` with child): `NestEmptyState` with Pip art,
  title 'No quests today', body 'Enjoy playing with Pip!', no CTA (quests are
  parent-created). Never red, never shaming copy.
- All-done is K03b (`/kid-home-done`, separate builder) — K03 renders counts
  as-is and does NOT redirect.

## (e) Accessibility

- Semantics: header name+sub merged label 'Hi Maya, 4 done today'; coin pill
  label '120 coins' (component default); lock label 'Grown-ups' (matches HTML
  aria-label); each card `Semantics(button: true, label: '{title}, {status
  text}')`; done_pending check label "Waiting for Mum's thumbs-up"; progress
  has value semantics (component); hearts `Semantics(image, label: 'Pip is
  happy today, 4 of 5 hearts')`; dock buttons use `label` directly.
- Tap targets: lock 56, checks 56, quest cards whole-row `onTap` (≥72 high),
  dock buttons min-h 66 — all ≥ 56 kid minimum (`NestKidTheme.minTarget`).
  Chips/hearts are display-only (no tap needed).
- Text scale: app clamps `textScaler` to 1.0–1.3 (SPACING §10); verify at 1.3:
  header `Expanded` + ellipsis, section title `Flexible`, card titles maxLines 2
  ellipsis, dock labels `FittedBox(scaleDown)` inside buttons, coin pills
  `Flexible` (component already wraps in Flexible).
- Width 320: header row keeps lock 56 fixed, hi `Expanded`, pill shrinks
  (ellipsis); dock `Row(spacing:12)` → each ≈85 wide, labels scale down;
  ListView side padding stays 20. Widget test at 320x844 + scaler 1.3 must not
  overflow (assert no `OverflowBox`/exception).
- Contrast: token pairs only (ink on sky-bg, coinInk on coinTint, leafInk on
  leafTint, onLeaf/onAccent/onWarm button fg) — all ≥ 4.5:1 per palette; verify
  in dark too (ink #F3F0FA surfaces). No `danger`/red anywhere in kid mode.

## (f) Test plan

New: `app/test/features/kid_home/kid_home_bloc_test.dart` (blocTest or
direct): load emits loading→loaded with Maya child + 6 items via fake repo
streams; doneCount==4, totalCount==6, fraction≈0.667; failure path sets
`errorMessage`; `KidHomeQuestCompleted` calls `completeQuest('maya','q-reading')`
then stream emits done_pending card. Extend `repositories_test.dart`? No —
repo already covered; only add if new repo logic appears (none planned).
New: `app/test/features/kid_home/kid_home_view_test.dart` (follow
`test_scope.dart`: `setUpTestScope(seedDemo)`, `GoogleFonts` fetching off,
`pumpAppRoute(tester, '/kid-home')`, end with `disposeApp(tester)`):
1. light: finds 'Hi Maya!', coin '120', '4 of 6 done', 'Pip is happy today',
   6 `NestKidQuestCard`, dock Pip/Shop/My jar; first done_pending card shows
   'Waiting for Mum' and disabled check.
2. dark (`pumpAppRoute(..., theme: ThemeMode.dark)`): pumps, no exceptions,
   dock + cards present.
3. tap first to-do card → pushes `/quest-detail` with extra questId (assert via
   router location / K04 placeholder text); tap its check → pushes
   `/quest-complete`; tap lock → `/parental-gate`; dock taps → `/pip`,
   `/reward-shop`, `/my-jar`.
4. a11y: 320-wide surface + `textScaler 1.3` → no overflow; `Semantics` checks
   for lock label + progress value.
Then: `dart format .`, `flutter analyze` (no issues, no ignores),
`flutter test` all pass. Screenshots/compare are a later stage
(`shot.sh /kid-home` light+dark, `compare.py` vs PNG; pre-declared accepted
drifts: count copy 4-vs-3, tile tint surface2, title 17/22 vs 18/24, icons 26
vs 24, h2 22/28 vs 22/26, chip 1.5px border — all fixable only via shared
changes in §(g)).

## (g) SHARED_REQUEST (non-blocking — build fully against foundation as-is)

File `docs/screens/K03/SHARED_REQUEST.md` (builder writes it):
1. `NestKidQuestCard` icon tile is fixed `surface2`; K03 HTML tints tiles per
   quest (sky-tint/lilac-tint/peach-tint). Need: optional `tileColor`/`tileBg`
   param. Files: `app/lib/core/design_system/components/nest_quest_card.dart`.
   Blocks: no (ship with surface2 tiles, note drift in compare).
2. Stale design copy only: PNG/HTML say "3 of 6 done" but demo DB yields 4 of 6
   (dishwasher+table pending, bins+hoover approved). No seed change wanted
   (RULES §4); either accept live "4 of 6 done" or orchestrator updates PNG
   copy. Blocks: no.
No schema/route/DI/token changes needed. No new assets needed (all icons +
`pipStage3`/`nest`/`coin`/`meadowHill` exist in `nestling_assets.dart`).

VERDICT: PASS
