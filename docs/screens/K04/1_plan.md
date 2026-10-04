# K04 Quest detail — build plan (Stage 1, iteration 1)

Scope: `kid_home` feature · route `/quest-detail` (`KidHomeRoutePaths.detail`) · kid mode.
Sources: `design/html-source/screens/K04-quest-detail.html` (copy + CSS are authoritative),
`design/screens/light/K04-quest-detail.png` + `design/screens/dark/K04-quest-detail.png`
(1170×2532 = 390×844 @3x; all px below are logical = PNG ÷ 3),
`DESIGN_SPEC.md` §5 K04, `SPACING_SPEC.md`, existing `kid_home` code (K03 view is the pattern).
`docs/screens/K04/ORCHESTRATOR_NOTES.md` does not exist (checked) — no extra mandates.

Demo data (from `app/lib/core/data/seed.dart`, DB wins over mocks):
`q-tidy` = “Tidy your bedroom”, icon `bed`, 15 coins, assignee Maya, default repeat (once);
`stepsFor('q-tidy')` = `['Clothes in the basket', 'Toys in the box', 'Books on the shelf']`
(`kid_home_repository_impl.dart:242`). K03 pushes `extra {'questId','childId'}` to this route.
`shot.sh` launches `/quest-detail` directly with NO extra, so the view needs a fallback (§2).

## (a) Widget tree, top → bottom (exact components + tokens)

Scaffold structure mirrors `kid_home_view.dart` (`_KidHomeBody`): `KidScope` (default —
sky gradient + 136 px meadow at bottom 0; NEVER paint local hills) > `Scaffold`
(`backgroundColor: transparent`) > `Column` (no scroll-around-chrome; only middle scrolls):

1. `NestStatusBar` — height 47 only; OS draws glyphs (ignore in UI checks).
2. Top row — `Padding(EdgeInsets.fromLTRB(20, 0, 20, 6))` (`.k4-top: padding 0 20px 6px`)
   > `Row[ NestIconButton(icon: NestIcons.back, semanticLabel: 'Back', size: 56
   (= `NestDevice.tapKid`), iconSize: 26, backgroundColor: transparent,
   borderColor: transparent)`, `Spacer`, `NestLockButton` large (56×56, r18,
   `semanticLabel: 'Grown-ups'`) ]`. K02 precedent (`kid_pin_view.dart:184`).
   Row box y ≈ 47…103; content starts ≈ 109.
3. `Expanded` > `ListView(padding: EdgeInsets.fromLTRB(20, 0, 20, 32))` (`.scroll`
   base; bottom 32 = s8). Separators are explicit `SizedBox`es (no collapsing):
   - Icon tile — `Center` > `Container(120×120)` (`.k4-tile: 120×120, margin 0 auto`),
     `r-l` (24), `color: tokens.peachTint`, `border: 3×ink`
     (`context.nestKid.borderWidth`), `boxShadow: tokens.kidShadow`
     (same tokens `NestKidButton` uses). Glyph: `NestIcon` of the quest icon
     (reuse K03 `_iconFor`: `bed` → `NestIcons.bedSit`), `size: 64`, `color: ink`
     (HTML svg 64 px, stroke ink). Decorative: `ExcludeSemantics`.
   - `SizedBox(4)` (`.k4-title margin-top: 4`, screen wins over the 16 rhythm).
   - Title — `NestBalancedText` (orchestrator rule: `.kid-title` is always balanced)
     `title`, `style: NestType.kidTitle(color: ink)` (28/34 w900 Nunito),
     `textAlign: center`, `maxLines: 3`. y ≈ 233 (light PNG).
   - `SizedBox(16)` > reward row — `Center` > `NestCoinPill(amount: '+$coins'`
     e.g. `'+15'`, `size: NestCoinPillSize.large` (20 px, pad 10/16, icon 20),
     `semanticLabel: 'Plus $coins coins'`).
   - `SizedBox(16)` > hint — `Text('Tick each bit off, then press the big button.'`,
     `style: NestType.kidCaption(color: ink2)` (15/20 w700 = `.kcap`), center.
   - `SizedBox(16)` > steps card — `Container`: `color: surface`,
     `border: 3×ink`, `radius: r-l (24)`, `boxShadow: kidShadow`, `clipBehavior:
     hardEdge` (for divider bleed). Children: `Column` of step rows with
     `Container(height: 2, color: line)` dividers between (`border-top: 2px line`).
     Step row = full-width button, `constraints: minHeight 60`, `padding:
     EdgeInsets.symmetric(horizontal: 14)` (`.k4-step: min-h 60, pad 0 14px`),
     `Row(gap 12)`: dot `SizedBox(40)` circle, `border: 3×ink`, `bg: surface`;
     ON: `bg: leaf`, check glyph 22 px `on-leaf` (reuse the exact done-ring check
     glyph from `NestKidQuestCard` — do NOT invent a new asset); text
     `Expanded > Text(step, style: NestType.h3(color: ink)` (18/24 w800 =
     `.k4-step-t`), `softWrap: true`). Semantics per row: `button: true`,
     `label: '{step}, ticked' / '{step}, not ticked'`, `toggled: on/off`,
     `onTap:` toggles (accessibility rule: tap action mandatory; test asserts
     `hasAction(tap)` + `performAction` flips the dot).
   - `SizedBox(22)` (`.k4-cheer margin-top: 22`, screen wins) > cheer row —
     `Row(mainAxisAlignment: center, gap 12)`: `PipAvatar(style: pipStyleOf(child.pipStyle),
     stage: child.pipStage.clamp(1,4), skin: pipSkinOf(child.pipSkin),
     accessory: pipAccessoryOf(child.pipAccessory), mood: PipMood.happy, size: 64)`
     (PIP rule: the CHILD's own Pip — Maya = mochi/sunny/stage 3; never v1 svg;
     keep the design slot: 64 px, left of bubble) + `Flexible >
     NestSpeechBubble(text: 'Pip is doing a happy dance!')` (shared `.speech`:
     maxW 260, pad 8/14, 16 w800, 3 px border, bottom tail — tail points at the
     bottom bar exactly like the PNG). Pip semantics: `image: true`,
     `label: 'Pip cheering you on'` (design HTML `alt`, verbatim).
4. Bottom bar — fixed (in-flow, NOT overlay), owner bottom-edge rule OVERRIDES the
   design (both PNGs show a meadow strip under the bar around the home pill — FAIL
   if reproduced): copy the K03 dock container verbatim —
   `Container(color: tokens.surface, border: Border(top: 3×ink)) > SafeArea(top: false)
   > Column[ Padding(EdgeInsets.fromLTRB(20, 12, 20, 10)) (`.kid-bar: padding
   12px 20px 10px`) > Column(spacing: 10) (`.kid-bar gap: 10`):
   `NestKidButton(label: 'I did it!', color: leaf, icon: check-26 onLeaf,
   minHeight: 64, fontSize: 20)` then `NestKidButton(label: 'Back', color: white,
   minHeight: 64)` (`.btn-kid` base: 64 high, r-l 24, 3 px border, sh-kid,
   Nunito 20 w900, gap 8, pad 0 24 — all inside `NestKidButton` defaults),
   `NestHomeIndicator` ]`. The surface box runs to the physical edge; buttons sit
   above the inset; OS draws the home pill.
5. Shadows: kid buttons/cards paint a 6 px bottom offset shadow — `NestKidButton`
   already reserves it internally; the steps card gets `margin-bottom: 6`-equivalent
   clearance from the following `SizedBox(22)` (no clipping).

Copy (verbatim from the HTML, all ASCII — no curly/dash/ellipsis issues on this screen):
title (DB) / `'+15'` / `'Tick each bit off, then press the big button.'` /
`'Clothes in the basket'` / `'Toys in the box'` / `'Books on the shelf'` /
`'Pip is doing a happy dance!'` / `'I did it!'` / `'Back'` / back aria `'Back'` /
lock aria `'Grown-ups'`.

## (b) BLoC + repository (NO new events, NO repo changes)

- Route builder already dispatches `KidHomeLoadRequested` (`kid_home_routes.dart:79`);
  the view only `BlocBuilder`s `KidHomeState` (`initial/loading → _KidLoading`,
  `failure → _KidFailure`, `loaded + child null → _NoActiveChild`,
  `loaded + quest found → _QuestDetailBody`, `loaded + quest missing → _QuestMissing`).
- Quest resolution (in the view, per build from `state.items`): (1) `questId` from
  `GoRouterState.of(context).extra` (`{'questId','childId'}` as pushed by K03) when it
  matches an item AND `childId` equals `state.child.id`; (2) else `'q-tidy'` when the
  active child's items contain it — the screen's design quest; this branch ONLY fires
  on direct launches with no extra (K03 always supplies extra); justified because a
  detail screen must show ONE quest and the DB has no “selected quest” column;
  (3) else first `to_do`/`not_yet` item in list order; (4) else first item.
- Steps: `context.read<KidHomeBloc>()` is NOT involved — `steps =
  repository.stepsFor(questId)` is sync/local; call it via a tiny `BlocBuilder`-local
  read: the repository is obtained with `GetIt`? NO — views never touch `GetIt`
  directly; instead the view calls `stepsFor` on the bloc? The bloc has no such
  method. Resolution: `KidHomeRepository.stepsFor` is a pure sync function of
  `questId` — the VIEW keeps a `static` mirror? NO duplication. Correct call path:
  expose through the bloc? That needs a bloc edit (allowed: bloc is feature code).
  Simplest precise instruction: add NO bloc API — `stepsFor` is deterministic and
  already unit-covered; the view reads it from the repository instance the bloc
  owns? Bloc holds `_repository` privately. THEREFORE: add a one-line bloc getter
  `List<String> stepsFor(String questId) => _repository.stepsFor(questId);`
  (presentation-supporting read, no event/state change, no test breakage). Tick state
  itself (`Set<int>` of ticked indices, initial EMPTY = all unticked) lives in the
  view's `State` (local working checklist; v1 has no per-quest step storage — repo
  comment on `stepsFor`). Fresh each visit (initState).
- `I did it!`: guard `_busy` (K03 `_QuestCard` pattern: set on tap, release on
  `completionToken`/`status` change via `didUpdateWidget` + post-frame release);
  dispatch existing `KidHomeQuestCompleted(childId:, questId:, coins:)`. Celebration:
  existing `BlocListener justCompletedQuestId → context.push('/quest-complete',
  extra {'questId','childId','coins'})` (same as K03). Failure: existing
  `actionError/actionNonce → showNestToast(context, 'Hmm, that did not work. Try again.')`.
- Done quests (`done_pending`/`approved`): primary button DISABLED (`onPressed: null`
  → opacity .45, `enabled: false` semantics; label stays `'I did it!'`) — retapping an
  idempotent no-op would confuse; documented product decision, no design state exists.
  Also disabled (same visual) while `_busy` awaiting the stream flip.
- No `DateTime.now` anywhere (steps carry no time); `completeQuest` timestamps via
  `appNowUtc()` inside the repo. No `subscription_status` writes. No `newId` use.

## (c) Interactions → navigation (route constants only)

- Top back + bottom `Back`: `context.canPop() ? context.pop() : context.go(KidHomeRoutePaths.home)`
  (K02 precedent `kid_pin_view.dart:191`; direct launch has nothing to pop).
- Lock: `context.push(ParentalGateRoutePaths.gate)` with the K03 `_busy` double-tap guard.
- Step row tap: local `setState` toggle only (aria-pressed/toggled flips; NEVER gates
  the primary button — design shows it enabled at 2/3 ticked).
- `I did it!` (enabled): dispatch (above) → success pushes `KidHomeRoutePaths.complete`
  with extra; failure toasts, stays.
- Child switch / quest deleted mid-view: next `watchHome` emission rebuilds; unknown id →
  `_QuestMissing` (below). No navigation inside the bloc (architecture rule).

## (d) Empty / loading / error states (copy K03 `_KidLoading`/`_KidFailure` structure)

- `initial/loading`: `KidScope` > status bar + top row (back + lock, so chrome never
  jumps) + centered `CircularProgressIndicator(color: leaf)`, semantics `'Loading quest'`.
- `failure`: same chrome + centered column: child’s own `PipAvatar(size: 140)` (or neutral
  `mochi/stage 1` when no child known), `'Oh no! Pip got lost.'` (h2),
  `"Let's try again."` (bodySmall ink2), white `NestKidButton('Try again')` →
  re-add `KidHomeLoadRequested` (subscription is released on error, so retry reloads).
- `loaded` + `child == null`: `"Who's playing?"` + lilac `NestKidButton('Choose')` →
  `context.go(KidHomeRoutePaths.picker)`.
- `loaded` + quest missing (items empty OR id unmatched): `NestEmptyState(art: child Pip
  120 / neutral, title: 'Pick a quest', message: 'Choose a quest to see its steps.')` +
  white `NestKidButton('Back home', fullWidth: false)` → `context.go(KidHomeRoutePaths.home)`.
- KNOWN DEVIATION (for the UI stage): steps render initially UNTICKED (correct product
  behaviour — fresh local checklist), while the design PNG shows the first two ticked.
  Geometry (40 px dots, 60 px rows, card rect) is identical; only dot fill differs.
  Do NOT pre-tick to match the mock.

## (e) Accessibility

- Every control exposes `SemanticsAction.tap`: `NestKidButton`/`NestIconButton`/
  `NestLockButton` already do (pass `onTap:`; disabled passes none + `enabled: false`).
  Custom step rows MUST wrap in `Semantics(button: true, toggled:, onTap:)` — never bare
  `excludeSemantics` without `onTap` (tests assert `hasAction(tap)` and that
  `performAction(tap)` flips the dot).
- Labels: steps `'{step}, ticked/not ticked'`; dot check excluded (dot is inside the
  labelled button); title/pill/hint plain text; cheer Pip `image` label (above);
  coin pill semantic `'Plus 15 coins'`; top-row order: Back, Grown-ups.
- Targets: steps 60×full-width, buttons 64 high full-width, back/lock 56×56 — all ≥ 56.
- Text scale 1.3 (clamp 1.0–1.3): title `maxLines: 3` wrap; step text `softWrap` in
  `Expanded`; cheer bubble `Flexible`; buttons keep `wrapLabel: true` (default).
- Width 320: `ListView` scrolls vertically; top row (56 + spacer + 56) fits 280 content;
  tile 120 fixed centred; steps card full-bleed minus 20 gutters; no `Row` overflow
  (bubble is `Flexible`, button labels wrap).
- Contrast: leaf button fg `onLeaf`, white button fg `ink`, dots `leaf/on-leaf` —
  all token pairs, both themes. No red anywhere (kid rule).

## (f) Test plan (`app/test/features/kid_home/`, `flutter test --timeout 120s …`, every pump ends with `disposeApp(tester)` per RULES §7; pinned clock `test/flutter_test_config.dart`)

Follow `kid_home_view_test.dart` (harness/fake repo) + `kid_home_geometry_test.dart` (rect pins):

1. `quest_detail_view_test.dart` — fake `KidHomeRepository` (stream `watchHome` with
   Maya `pipStyle mochi/skin sunny/stage 3` + items incl. `q-tidy` 15 coins `to_do`;
   `stepsFor` real impl expectations; `completeQuest` records calls):
   renders title / `+15` pill (semantics `Plus 15 coins`) / hint / 3 steps unticked /
   cheer bubble + Pip / both buttons; extra `{'questId':'q-tidy','childId':maya}`
   selects it; unknown questId → `_QuestMissing`; empty items → missing; no child →
   picker prompt; failure → Try again re-dispatches load; step tap toggles dot twice
   incl. via `performAction(tap)` semantics; `I did it!` dispatches
   `KidHomeQuestCompleted(maya, q-tidy, 15)` exactly once under double-tap; success
   emission pushes `/quest-complete` with extra; failed write toasts
   `'Hmm, that did not work. Try again.'`; done_pending quest disables primary
   (`enabled: false`, no dispatch); Back/top-back pop (and `go(home)` when no pop);
   lock pushes `/parental-gate`; every control `hasAction(tap)`; 1.3 text + 320 width
   pump asserts no overflow. No `google_fonts`/`GoogleFonts` import in the test.
2. `quest_detail_geometry_test.dart` — logical-px rects at 390×844: tile 120×120
   centred (x 135…255); title/pill/hint x within 20 gutters; steps rows min-h 60,
   card radius 24 border 3; cheer Pip 64, gap 12; kid-bar buttons full-width
   (350) min-h 64, gap 10, bar pad 12/20/10; bar surface rect runs to y 844
   (no meadow strip under it); top-row buttons 56.
3. `quest_detail_copy_parity_test.dart` — exact strings incl. `'Pip cheering you on'`,
   `'Tick each bit off, then press the big button.'`, `'I did it!'`; blot: no `’`.
4. Bloc/repo untouched → no new bloc unit tests (existing `kid_home_bloc_test` covers
   the completion channel); the one-line `stepsFor` getter needs no test.

## (g) SHARED_REQUEST

None. All components exist in the design system (`NestKidButton` leaf+white,
`NestCoinPill.large`, `NestLockButton` large, `NestIconButton`, `KidScope` default
meadow, `NestSpeechBubble`, `PipAvatar`, `NestStatusBar`, `NestHomeIndicator`,
`NestEmptyState`, `showNestToast`, `KidHomeRoutePaths` + `ParentalGateRoutePaths`);
route `/quest-detail` already registered; BLoC events + `stepsFor`/`completeQuest`
already exist. No shared-file edit, no new route, no schema/seed change. Do NOT file
`SHARED_REQUEST.md`. Only files the builder may touch: 
`app/lib/features/kid_home/presentation/views/quest_detail_view.dart` (rewrite) +
`app/test/features/kid_home/quest_detail_*_test.dart` (new).

VERDICT: PASS
