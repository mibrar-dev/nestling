# K05 Quest complete — plan (Stage 1, iteration 1)

Screen: K05 · `kid_home` · route `/quest-complete` (`KidHomeRoutePaths.complete`,
`app/lib/features/kid_home/kid_home_routes.dart:22-29`) · kid mode.
Design: `design/screens/light/K05-quest-complete.png`,
`design/screens/dark/K05-quest-complete.png` (1170×2532 = 390×844 logical, ÷3),
HTML `design/html-source/screens/K05-quest-complete.html`,
DESIGN_SPEC §5 K05 (`docs/DESIGN_SPEC.md:198`),
SPACING_SPEC (`docs/design/SPACING_SPEC.md`).
ORCHESTRATOR_NOTES.md: absent — no extra mandates beyond the stage prompt.

Copy (byte-checked, all ASCII — use exactly, `python3` repr check):
- `Brilliant, Maya!` (h1, exclamation U+0021, comma U+002C)
- `+15 coins` (plus U+002B; dynamic — see §b)
- `Mum will give it a thumbs-up soon.` (hyphen-minus U+002D in `thumbs-up`, period U+002E)
- `Pip is doing a happy dance!`
- `Pip needs 75 more coins to grow` (dynamic — see §b)
- `175 of 250 coins` / `Next: Songbird` (dynamic)
- `Yay! Back home` (CTA)
Title-tag `—`/`·` are doc-only, never rendered.

Seed truth (DATA OVER MOCKS — never hard-code design numbers):
- Maya `pipTotalCoins: 175` (`app/lib/core/data/seed.dart:214`), Leo 60;
  `evolveAtCoins = 250` (`app/lib/features/pip/domain/entities/pip_profile.dart:20`).
  Design `175 of 250 / 75 more / 70%` happens to match Maya — the view computes
  all three from the DB + route extra.
- Maya Pip: mochi · sunny · none · stage 3 (`seed.dart:210-213`);
  Leo: bolt · sky · none · stage 2. Render the ACTIVE child's own Pip via
  `PipAvatar` (orchestrator PIP rule), never `pip_stage_*.svg`.
- Quest coins come from the celebration extra / quest row (e.g. `q-tidy` 15).
  `countsForCurrentPeriod` / period ruling is K03/K04 business; K05 only reads
  the already-saved completion.

## (a) Widget tree top→bottom (tokens only, no hard-coded colours/sizes)

Root: `KidScope` (`theme/kid_scope.dart:19`) — sky gradient + meadow hills
(`kid_meadow.dart`, 390×136, bottom 0). Never paint local hills/meadow.
`Scaffold(backgroundColor: transparent)` → `Column`:

1. `NestStatusBar` — reserves 47 (`NestDevice.statusH`). OS draws glyphs;
   ignore status-bar pixels in UI checks.
2. `k5-top` (`K05 HTML:19`): `Padding(0, 20, 20, 2)` → `Row(end)` →
   `NestLockButton(large: true)` — 56×56, r18, surface bg, `semanticLabel:
   'Grown-ups'`. Rect x 314–370, y 47–103. Kid min target 56 ✓.
3. `.scroll` (`components.css:65-66`): `Expanded` +
   `SingleChildScrollView(padding: 0,20,20,32=s8)`; children separated by
   `s4` 16 (`.scroll > * + *`). All content x 20–370 (350 wide, 20 gutters,
   OWNER alignment rule).
   1. `k5-stage` (HTML:20): centred `Stack` 320×200:
      - `_CoinsBurst` 320×200 (`burst`, HTML:21,41-58): 9 gold circles
        (`--coin`) + 3 sparkles (lilac/leaf/peach), 3px ink stroke, static SVG
        (`CustomPaint`, `IgnorePointer`, `ExcludeSemantics`). No animation, so
        `DISABLE_ANIMATIONS` still frame is identical. Scales down at 320 px
        width (never overflows; `FittedBox`/`LayoutBuilder` scale, centred
        x 35–355 at 390).
      - `PipAvatar(style: pipStyleOf(child.pipStyle), skin:
        pipSkinOf(child.pipSkin), accessory: pipAccessoryOf(child.pipAccessory),
        stage: child.pipStage.clamp(1,4), mood: PipMood.happy, size: 218)`
        in `margin 14,0,2`, `Transform.rotate(-8° ≈ -0.14 rad)` (`.k5-pip`,
        HTML:22). Slot keeps design size/position. `riveEnabled` defaults;
        `kDisableAnimations` → SVG fallback (`pip_avatar.dart:384`). Semantics
        image: `Pip the Fledgling, stage 3 of 4, doing a happy dance`.
   2. `k5-hero` (HTML:25,61): `.kid-hero` HAS `text-wrap: balance`
      (`components.css:37`) → `NestBalancedText('Brilliant, {nickname}!',
      style: NestType.kidHero(ink), center, maxLines: 2)`. 40/44 w900,
      letterSpacing 0 (never Material tracking). Screen `margin-top: 4` wins
      over scroll-16 (screen wins, SPACING §9). Dynamic nickname
      (`nestAvatarInitial` not needed here — full nickname in title).
   3. `k5-mid` (HTML:24,62): `Center` → `NestCoinPill(amount: '+{coins} coins',
      size: large)` — 20px, `10px 16px`, icon 20, coinTint/coinInk
      (`nest_coin_pill.dart:56-60`). Shape rect compared, not just text
      (orchestrator UI rule). Semantics `'{coins} coins earned'`.
   4. `k5-sub` (HTML:26,63): `Text('Mum will give it a thumbs-up soon.',
      style: NestType.kidBody(ink), center, maxLines: 3, softWrap)`. 18/26 w700.
   5. `k5-cheer` (HTML:23,64): `Center` → `NestSpeechBubble(text: 'Pip is doing
      a happy dance!')` — surface, 3px ink border, r18, `8px 14px`, Nunito 800
      16 + 22 strut, maxWidth 260, 9px tail (`nest_pet_stage.dart:379-461`).
   6. `k5-card` (HTML:27-31,65-75): growth card. `Container(lilacTint,
      3px ink border, r-l 24, kidShadow, padding 14,16 + bottom 6 shadow room
      like K03 `_kQuestCardShadowRoom`)`:
      - `Row(gap 8)`: mini `PipAvatar(same look, size: 32)` (decorative,
        `ExcludeSemantics`) + `Expanded(Text('{remaining-copy}',
        18/24 w900 ink, wrap))`. Design 2 lines at 350 — wraps, never
        overflows (Flexible + ellipsis guard for huge scales).
      - `Padding(10 top, 6 bottom)` → `Row(spaceBetween)`: `Text('{total} of
        250 coins', kidCaption ink2)` + `Text('Next: Songbird', kidCaption
        ink2)`. `.kcap` 15/20 w700 (HTML:15). `kidCaption` is the token match
        (K03 precedent).
      - `NestProgress(fraction: total/250, kid: true, semanticLabel: 'Pip is
        {pct}% of the way to Songbird')` — 16 tall, 2px ink border, surface
        track, leaf fill + gloss (`nest_progress.dart:18-62`).
4. `kid-bar` (HTML:14,77-79): NOT `NestBottomCta` (that is 1px `line` border;
   K05 is 3px ink). Local bar exactly like the K03 dock
   (`kid_home_view.dart:528-622`): `Container(surface, top BorderSide(ink, 3))`
   → `SafeArea(top: false)` → `Padding(12,20,20,10, gap 10)` →
   `NestKidButton(label: 'Yay! Back home', color: leaf, minHeight: 64)`
   (base 20/26 w900, r-l 24, 3px ink, sh-kid) → `NestHomeIndicator` INSIDE the
   surface (BOTTOM EDGE owner rule — no meadow/sky strip under the bar in
   light or dark; SafeArea inset sits inside the surface box).

Dark mode: same tree; tokens flip (leafTint→dark, coinTint→dark, lilacTint→dark,
sky gradient→night + stars via `KidScope`, sh-kid→black@45). Hero white, coin
pill dark tint, card dark lilac, CTA green fill.

## (b) BLoC events/states + repository calls

No new events. Route already wires
`BlocProvider(create: GetIt<KidHomeBloc>()..add(KidHomeLoadRequested()))`
(`kid_home_routes.dart:91-101`). K05 reuses the live subscription:
- `KidHomeLoadRequested` → `watchHome()` (child + items, single-subscription,
  `kid_home_repository_impl.dart:38-59`) + existing profiles sub (harmless).
  States: `initial/loading/loaded/failure` (`kid_home_state.dart:5`).
- Celebration data: view reads `GoRouterState.of(context).extra`
  `{'questId','childId','coins'}` (what K03 pushes,
  `kid_home_view.dart:116-124`). Coins = `extra coins ?? items.firstWhere(
  questId).coins ?? 0`; title uses `state.child.nickname`. `childId` mismatch
  → trust the stream's active child (DATA rule).
- `KidHomeQuestCompleted` is NOT dispatched here (write already saved on K04).

Feature-local data change (allowed by RULES §1, no SHARED_REQUEST):
- `KidChild` gains `required pipTotalCoins` (`domain/entities/kid_child.dart`),
  mapped in `_toChild` from `row.pipTotalCoins`
  (`kid_home_repository_impl.dart:201-215`), added to `props`. Update every
  `KidChild(` fixture in `app/test/features/kid_home/**`.
- Growth helpers (pure, in view or `kid_style_helpers.dart`):
  `remaining = (250 - total).clamp(0, 250)`; `fraction = total / 250`
  (clamp 0..1); copy `remaining == 0 ? 'Pip is ready to grow!'
  : 'Pip needs $remaining more coin${s} to grow'` (design plural; seed 75 →
  plural path); count `'$total of 250 coins'`; next `'Next: ${pipStageName(4)}'`
  = `Next: Songbird` (`kid_style_helpers.dart:71-77`, `evolveAtCoins`
  `pip_profile.dart:20`). App code uses `clock.now()`/`appNowUtc()` only —
  K05 needs no clock at all (static celebration + DB values).

## (c) Interactions + navigation

| Control | Action | Route |
|---|---|---|
| `Yay! Back home` (`NestKidButton.leaf`) | `context.go(KidHomeRoutePaths.home)` (`/kid-home`, `kid_home_routes.dart:26`) — `go`, not `push` (K03 pushed us; no stack pile-up) | `/kid-home` |
| Lock `Grown-ups` (`NestLockButton`) | `context.push(ParentalGateRoutePaths.gate)` with `_busy` tap guard (K03 `_GateLockButton`, `kid_home_view.dart:632-656`); double-tap opens one gate | `/parental-gate` |
| Burst / Pip / speech / growth card | none (display-only; Pip `onTap` null) | — |
| System back | default `pop` (no explicit back control in design) | — |

No bloc event on any K05 tap. CTA/labels never wrap unexpectedly
(`wrapLabel` default true is fine at full width).

## (d) Empty / loading / error states

- `initial/loading`: `KidScope` + `NestStatusBar` + top-right lock +
  `Center(CircularProgressIndicator(leaf))`, semantics `Loading your
  celebration` (K03 `_KidLoading` pattern).
- `failure`: `KidScope` + lock + failure card (K03 `_KidFailure` pattern):
  own Pip when `state.child != null` else neutral `PipAvatar(mochi, stage 1,
  140)`; `Oh no! Pip got lost.` / `Let's try again.` + white `NestKidButton
  Try again` → `add(KidHomeLoadRequested())`. Mid-session error keeps loaded
  list (bloc `_onStreamFailed`).
- `loaded` + `child == null`: `Who's playing?` + lilac `Choose` →
  `context.go(picker)` (K03 `_NoActiveChild` pattern).
- `loaded` deep-link with no resolvable quest (no extra, no `done_pending` /
  `approved` item): still celebrate the active child — title + `+{coins} coins`
  (`coins` = extra ?? 0), growth card from `pipTotalCoins`. Never blank; the
  only error card is stream failure. `total >= 250` → card top
  `Pip is ready to grow!`, fraction 1.0 (K07 owns the evolution moment).

## (e) Accessibility

- Every interactive exposes `SemanticsAction.tap`: `NestKidButton` /
  `NestLockButton` already pass `onTap` on the labelled node; never wrap in
  `Semantics(excludeSemantics: true)` without `onTap:`. Tests assert
  `hasAction(tap)` + `performAction(tap)` drives real navigation/DB.
- Labels: hero heading; coin pill `'{n} coins earned'`; sub text; speech text;
  growth card single label `'{top}. {total} of 250 coins. Next Songbird.
  {pct} percent'`; progress `role=img` label; Pip image label (decorative mini
  Pip excluded).
- Targets: CTA ≥64 high, lock 56×56 (kid min 56 ✓), Try again/Choose 64.
- Text scale: app clamps 1.0–1.3 — verify at 1.3: hero balances ≤2 lines, coin
  pill `softWrap:false` + ellipsis parent, card title `Flexible` wraps,
  count row wraps without overflow.
- Width 320: gutters stay 20 (content 280); burst scales (never 390-fixed);
  Pip 218 fits; card wraps to 3 lines; CTA full width; assert zero horizontal
  overflow.
- Contrast ≥4.5:1 body (ink on sky/meadow, coinInk on coinTint, ink on
  lilacTint, onLeaf on leaf) in both themes; no red anywhere (kid rule);
  kind copy only (no timers, no shame, no `locked` negativity).
- `DISABLE_ANIMATIONS=1` / `MediaQuery.disableAnimations` → Pip SVG fallback,
  static burst; no `Timer`/`AnimationController`.

## (f) Test plan (`flutter test --timeout 120s`, end widget tests with `disposeApp`)

`app/test/features/kid_home/quest_complete_*_test.dart` (+ extend
`kid_home_bloc_test.dart` / `kid_home_repository_test.dart` for the
`pipTotalCoins` mapping):
- Bloc/repo: `watchHome` emits Maya with `pipTotalCoins 175`; remaining 75,
  fraction 0.7; `copyWithLoaded` carries the field; Leo 60 → 190 more / 0.24.
- View (pumpApp SEED=demo, CHILD=maya, `/quest-complete` + extra
  `{questId: q-tidy, childId: maya, coins: 15}`): hero `Brilliant, Maya!`
  (`NestBalancedText`, kidHero); coin pill rect vs design (large: 20px,
  `10px 16px`, icon 20) + `+15 coins`; sub exact `Mum will give it a
  thumbs-up soon.`; speech `Pip is doing a happy dance!`; card
  `Pip needs 75 more coins to grow` / `175 of 250 coins` / `Next: Songbird` /
  70%; `PipAvatar` mochi·sunny·none·stage 3 size 218 + mini 32; Leo pump →
  bolt·sky·stage 2.
- Interactions: CTA tap → `/kid-home`; lock tap → `/parental-gate` (single
  push on double-tap); every control `hasAction(tap)` + `performAction`
  navigates; failure `Try again` re-adds load; `Choose` → picker.
- States: loading spinner; failure card; null-child chooser; deep-link no-extra
  still celebrates; `total >= 250` ready-to-grow copy + fraction 1.0.
- Layout: light + dark goldensshapes — every pill/button/card background rect
  within ±2 px of PNG÷3 (burst x 35–355, Pip 218, card x 20–370, bar surface
  to edge, no meadow strip under bar/home indicator); title/first-control/card
  y reported design-vs-app; 320 width + textScale 1.3 no-overflow.
- Hygiene: no `google_fonts`/`GoogleFonts` import; no `DateTime.now()`; ids via
  `newId` only (no new ids needed here); `nestAvatarInitial` if initials used;
  `dart format`, `flutter analyze` clean.

## (g) SHARED_REQUEST

None. Route `/quest-complete` exists; all components exist (`KidScope`,
`PipAvatar`, `NestCoinPill.large`, `NestProgress(kid:)`, `NestKidButton.leaf`,
`NestLockButton`, `NestSpeechBubble`, `NestStatusBar`, `NestHomeIndicator`).
The `pipTotalCoins` addition is feature-private (`kid_home/domain/entities` +
`kid_home/data`), editable under RULES §1. No schema/seed/router/DI/design-
system change needed.

VERDICT: PASS
