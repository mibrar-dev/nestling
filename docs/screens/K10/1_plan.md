# K10 · Payout day (`/payout-day`) — build plan

Iteration 1 plan. Sources, all read: `design/html-source/screens/K10-payout-day.html`,
`design/screens/light/K10-payout-day.png` + `design/screens/dark/K10-payout-day.png`
(1170×2532 = 390×844 logical, ÷3), DESIGN_SPEC §5 K10, SPACING_SPEC,
`app/lib/features/kid_jar/**` (incl. K09 `MyJarView` precedent),
`PocketMoneyRepositoryImpl.recordPayout`, `QuestDetailView` `.kid-bar` precedent,
`PipAvatar`, `KidScope`. No `ORCHESTRATOR_NOTES.md` exists for K10.

## 0. What this screen is

Post-payout celebration for the active child (kid mode, Nunito everywhere).
Parent flow (P13 `recordPayout`) writes one `payout` row (`-amount`, note
`Paid · <day>`) plus an optional companion `savings_move` (`+move`, note
`Jar → savings goal`) and bumps the goal. K10 renders that event back:
paid note, savings note, live goal card, cheering Pip, `Thanks Mum!` CTA.
It is the second screen of feature `kid_jar` and reuses `KidJarBloc`
(one bloc per feature — no new bloc).

Copy is transcribed below from `K10-payout-day.html`. Where the plan says
DB, the database value wins over the design mock (DATA OVER MOCKS):
design shows paid £4.20 / moved £1.00 / goal £16.50 / £8.49 to go / 66%,
demo seed yields paid £3.80 / moved £5.50 / goal £15.50 / £9.49 to go / 62%
(see §b). The UI check must allow those number differences (DB-driven
content) but layout geometry must still match ±2 px.

Byte check required: `K10-payout-day.html:39` writes `It's payout day!` —
verify whether the apostrophe is U+0027 or U+2019 and copy the exact byte.
Same for every string below (COPY rule).

## (a) Widget tree, top → bottom (all logical px, PNG ÷ 3)

Chrome: `KidScope` (shared sky gradient + meadow hills 390×136 pinned to
bottom 0 — never paint local hills) > `Scaffold(backgroundColor:
transparent)` > `SafeArea(top: false)` > `Column`:

1. `NestStatusBar()` — reserves 47 px (`0…47`). OS draws glyphs; ignore in
   UI checks.
2. `_PayoutTopRow` (`47…107`): `Padding(20 left/right, 0 top, s1=4 bottom)`
   > `Row`: `NestIconButton(icon: NestIcons.back, semanticLabel: 'Back'`
   (`K10:37` aria-label), `size: NestDevice.tapKid (56)`, `iconSize: 26`
   (K09 `_backIconSize` precedent, `K09:13`/`K10` same glyph), transparent
   bg + transparent border, fg `tokens.ink`) + `Spacer` + lock
   (`_GateLockButton`, same double-tap guard pattern as K09: stateful,
   `_busy` flag, `context.push(ParentalGateRoutePaths.gate)`).
   `NestLockButton` large renders exactly the design's `.lock-btn.lg`
   (56×56, r18, surface fill, 1 px line border). Both boxes 56×56.
3. `Expanded` > loaded scroll: `SingleChildScrollView(padding:
   fromLTRB(padSide=20, 0, 20, s8=32))` > `Column(stretch)` with 16 px
   separators (base `.scroll` rule; K10 has no override):
   - Title (`~107…141`): `Semantics(header: true)` > `NestBalancedText`
     (`It's payout day!`, `.kid-title` is in the balanced-headings list;
     single line at 390) `style: NestType.kidTitle(ink)`,
     `textAlign: center`, `maxLines: 1`. Wrap in `FittedBox(scaleDown)` so
     320 px / 1.3× cannot overflow (title is 28 px; at 1.3× it exceeds 280).
   - `Center` > `_PayoutJarRain` (`180×270`, `.rain`, `K10:19`, `~141…411`
     incl. separators): feature-private `CustomPaint` (static transcription
     of the `K10:40-74` SVG — seven rain coins, leaf + lilac sparkles,
     lilac lid, glass body, clipped coin mass + eight coins, white gloss,
     lilac sparkle cross, ground ellipse). Fixed palette exactly as drawn
     (`#F4B400` coins, `#E09700` mass, `#7C6CF2` lid/sparkle, `#F2FAFF`
     glass, `#1F9D63` leaf spark, `#1E1B3A` 3–4 px outlines — same
     fixed-illustration rule as `_JarPainter`: only the ground ellipse uses
     `tokens.groundShadow`). `Semantics(image: true, label: 'A jar of coins
     with coins raining down into it')` (`K10:40` aria-label).
   - `_PayoutNote` × 2 (`surface`, 3 px ink border, `r-m`=16, `sh-kid`,
     `padding: 10 vertical / 12 horizontal`, `gap: 10`, row, `min-height`
     from content ≈ 68): leading 40 px circle + `Expanded(Column(cross
     start, [title, sub]))`, both `maxLines` generous (2/2) with ellipsis +
     `Flexible` parents so 320 px / 1.3× wraps instead of overflowing.
     - Note 1: circle `leafTint` bg, `NestIcon(NestIcons.check, 22,
       leafInk)` (verify glyph matches the `K10:76` check, stroke ≈3);
       title `.k10-t` = `kidTitle.copyWith(fontSize: 17, height: 22/17,
       w800)`; sub `.k10-s` = `kidCaption(ink2)` at 14/18 w700 (if
       `kidCaption` is not 14/18, `kidBody.copyWith(fontSize: 14, height:
       18/14, w700)` — no hard-coded sizes elsewhere).
       Title copy: `Mum marked {jarPounds(paidPence)} as paid` (DB amount;
       design `£4.20`). Sub (static): `Pocket money for this week`.
       One spoken sentence: wrap row in `Semantics(label: '<title>.
       <sub>', excludeSemantics: true)` (K09 amount+weekday precedent).
     - Note 2 (only when `movedPence != null`, §b): circle `lilacTint` bg,
       ink glyph 22 = exact transcription of the `K10:80` circle+arrow
       paths (`circle 9.5,15 r5.5` + `M17.5 12V4…`). Builder: inventory
       `NestIcons` first; if no exact match, draw feature-private 22 px
       icon (never a look-alike, never a shared edit).
       Title: `{jarPounds(movedPence)} went into your {goalTitle}`
       (DB; design `£1.00 went into your Lego fund`). Sub (static):
       `Just like you asked`. Same merged-semantics treatment.
   - `_PayoutFundCard` (`coinTint` bg, 3 px ink border, `r-l`=24,
     `sh-kid`, `padding: 14 vertical / 16 horizontal`): NEW feature-private
     widget — do NOT reuse `JarGoalCard` (it carries the 34 px coin-art row
     and different rhythm; K09 geometry must not shift).
     - Title `h2` 20/26 w900: `kidTitle.copyWith(fontSize: 20, height:
       26/20)` (DB `goalTitle`; design `Lego Friends set`), maxLines 2,
       ellipsis.
     - `SizedBox(s3=12)`? No — `.k10-amts` margin is `10px 0 6px`: use
       `SizedBox(gap10)` then amts row then `SizedBox(gap6)`.
       Amts: `Row(spaceBetween)`: left `jarPounds(goalSavedPence)`
       (design `£16.50`), right `{jarPounds(remaining)} to go` (design
       `£8.49 to go`), both `kidTitle.copyWith(fontSize: 17, height:
       23/17, w900)` (the browser `normal` line box at 17 px, JarGoalCard
       precedent), each `Flexible` + ellipsis + `TextAlign.end` on right
       (320 px / 1.3× rule).
     - `NestProgress(fraction: saved/target clamped, kid: true,
       semanticLabel: '{percent}% of the {goalTitle} saved')`.
     - `SizedBox(s2=8)` (second `.k10-amts` margin-top 8) then captions row
       (`spaceBetween`, both `Flexible` + ellipsis): left `of
       {jarPounds(target)}` (design `of £24.99`), right `{percent}% there!`
       (design `66% there!`), both `.kcap` = `kidCaption(ink2)` 15/20 w700.
   - `_PayoutPip` (`center` row, `gap: 12`): `Semantics(image: true, label:
     'Pip cheering', excludeSemantics: true)` > `PipAvatar(style:
     pipStyleOf(pipStyle), stage: pipStage.clamp(1,4), skin:
     pipSkinOf(pipSkin), accessory: pipAccessoryOf(pipAccessory), mood:
     PipMood.happy, size: 72)` — PIP RULE: the ACTIVE CHILD's own Pip from
     the DB row (demo: Maya Mochi·sunny·stage 3), never v1 SVGs; keep the
     design's 72 px slot. `pipStyleOf/pipSkinOf/pipAccessoryOf` are
     feature-local copies of the `pip_look.dart` switches (RULES §1: no
     cross-feature imports; ARCHITECTURE: no new shared code) — or import
     from `kid_home`? No: kid_home already imports pip; kid_jar must not
     import either. Copy the three 10-line switches feature-privately.
     + `Flexible` > `NestSpeechBubble(text: 'Pip says well done,
     {nickname}!')` (DB nickname; K04 adjacency-merge precedent gives one
     announcement). Import `NestSpeechBubble` from the design system
     barrel (it lives in `nest_pet_stage.dart`, shared — allowed to USE).
4. Bottom bar (`.kid-bar`, fixed): K04 `quest_detail_view.dart:645-695`
   structure copied exactly (it is NOT `NestBottomCta` — CSS uses a 3 px
   ink top border, not the 1 px line CTA):
   `Container(decoration: surface + Border(top: ink 3))` > `SafeArea(top:
   false)` > `Padding(fromLTRB(20, s3=12, 20, s1=4))` (CSS 10 px bottom
   air hands 6 px back for the button's own shadow room, K04 comment) >
   `NestKidButton(label: 'Thanks Mum!', color: leaf, onPressed: …)` (base
   64 min-height, 20/26 label — no extension params) + `NestHomeIndicator`
   INSIDE the surface box (BOTTOM EDGE owner rule: surface runs to the
   physical edge; SafeArea inset sits inside).

Dark mode: all fills via tokens (`surface`, `ink`, `coinTint`,
`leafTint/lilacTint`, `ink2`); illustration keeps its fixed palette in
both themes (verified against `design/screens/dark/K10-payout-day.png`).

Letter-spacing: the K10 CSS sets none → `NestType` default 0, no
`copyWith(letterSpacing:)` anywhere on this screen.

## (b) BLoC events/states, repository calls (local Drift, existing repo)

New entity `domain/entities/payout_celebration.dart` (Equatable):

```dart
PayoutCelebration {
  childId, nickname, paidPence,           // paidPence = abs(latest payout)
  movedPence,                             // int? — null hides note 2
  goalTitle, goalSavedPence, goalTargetPence,
  pipStyle, pipSkin, pipAccessory, pipStage,
}
```

New abstract method `KidJarRepository.watchLatestPayout() →
Stream<PayoutCelebration?>`. Impl (`kid_jar_repository_impl.dart`,
same `_switchMap(watchAppState → _payoutFor(childId))` pattern, K09-BUG-1
comment style):

- `combineLatest3(_db.watchLedger(childId), _db.watchGoals(familyId),
  _db.watchChild(childId))` (all exist; `combineLatest3` exists in
  `core/data/stream_combine.dart`).
- Latest row with `type == 'payout'` (ledger is date-desc; ties broken by
  the P13 rule: rows on the payout instant count as the event, never
  before). None → emit `null`.
- `paidPence = payoutRow.amountPence.abs()`.
- Companion move: first `savings_move` with `note.startsWith('Jar →')`
  and `date >= payout.date` (covers `recordPayout`'s exact
  `Jar → savings goal` and the seed's `Jar → Lego fund`); none → null
  (note 2 hidden). Demo seed (Maya): payout 26 Sep −380 → paid 380;
  move 30 Sep `Jar → Lego fund` 550 → moved 550.
- Goal: first goal for child (same as `_summarize`); none →
  `goalTitle 'Savings goal'`, saved/target 0 → fund card shows
  £0.00/100%? No: target 0 → fraction 0, `remaining` 0, captions
  `of £0.00` / `0% there!` — acceptable, matches K09 zero-goal handling
  (K09 hides its card; K10 keeps the card because the design always shows
  it and the title carries the goal name).
- Child row: `nickname`, `pipStyle/pipSkin/pipAccessory/pipStage`
  (may be null when child missing — cannot happen behind an active child,
  but guard: null child → emit null).
- PERIODS ruling is N/A here (payout rows are event history, not quest
  status); state this in code comment so no one "fixes" it later.

`KidJarBloc` additions (same guarded-subscription shape as `_jarSub`):

- `KidJarPayoutRequested` (view event; `kid_jar_routes.dart`
  `payoutDayRoute` dispatches it INSTEAD of `KidJarLoadRequested`).
- Internal `KidJarPayoutReceived(PayoutCelebration?)`; reuse
  `KidJarStreamFailed` for payout-stream errors.
- State: add `PayoutCelebration? payout` (null = no payout yet) to
  `KidJarState` + `copyWith`/`copyWithLoaded` extension
  (`copyWithPayout(...)`); `props` extended. K09 fields untouched.
- `_payoutSub` with cancel-before-reload + release on error/close
  (K09-BUG-1 pattern verbatim).

## (c) Interactions → navigation (route constants)

- Back chevron (`Back`): `context.canPop() ? pop() : go(KidHomeRoutePaths.home)`
  (`/kid-home`, K09 precedent).
- Lock (`Grown-ups`): `push(ParentalGateRoutePaths.gate)` (`/parental-gate`)
  with the `_busy` double-tap guard.
- `Thanks Mum!`: `context.go(KidHomeRoutePaths.home)` (celebration end-point;
  K05 `Yay! Back home` precedent). Single-tap guard not needed (go, not
  push, idempotent) — but disable while `state.status != loaded`.
- Failure `Try again` (white `NestKidButton`, `fullWidth: false`):
  re-add `KidJarPayoutRequested` (K09 `_JarFailure` precedent).
- Empty-state `Back home` (white kid button): `go(KidHomeRoutePaths.home)`.
- Every control keeps `onTap` on its Semantics node (ACCESSIBILITY ACTIONS
  rule); tests assert `hasAction(SemanticsAction.tap)` + `performAction`
  drives the real route/DB reload.

## (d) Empty / loading / error states (no design source; K09 kid voice)

- Loading (`initial`/`loading`): chrome + meadow stay; `Center(
  CircularProgressIndicator(leaf))` with `Semantics(label: 'Loading payout
  day', liveRegion: true)`.
- Failure: centered column — `NestIcon(NestIcons.jar, 96, ink3)` +
  `Oh no! Something went wrong.` (kidBody) + white `NestKidButton('Try
  again')`. No card frame (K08/K09 precedent).
- No payout yet (`loaded` + `payout == null`): same shape —
  jar glyph 96 + `No payout yet` + `When Mum marks your pocket money as
  paid, the celebration starts here.` + white `NestKidButton('Back home')`.
- Zero goal (target 0): fund card stays, fraction 0 (§b).
- No savings move (`movedPence == null`): note 2 hidden, 16 px rhythm kept.

## (e) Accessibility

- Screen title is the heading (`Semantics(header: true)` on the
  `NestBalancedText`); notes merge title+sub into one label; progress and
  jar-rain carry image/value labels (§a); Pip image + bubble merge
  (K04 precedent).
- Tap targets: back/lock 56, kid buttons ≥64, failure/empty buttons 64 —
  all ≥ kid 56 minimum.
- Text scale: app clamps to 1.0–1.3 (SPACING_SPEC §10.1); at 1.3× + 320 px
  width: title uses `FittedBox(scaleDown)`; note/fund text sits in
  `Flexible`+ellipsis rows (never fixed 170-style widths; K10 has no
  grids); rain box fixed 180×270 (illustration, allowed).
- Contrast: `ink`/`ink2` on `surface`/`coinTint`, `leafInk` on
  `leafTint`, `onLeaf` on `leaf` — all token pairs, both themes.

## (f) Test plan (`flutter test --timeout 120s …`, end pumped tests with
`disposeApp(tester)` from `test/test_scope.dart`; pinned clock Sat 3 Oct
2026 09:41 London; `clock.now()` only — no `DateTime.now()`; no
`google_fonts` imports anywhere)

1. `payout_celebration_test.dart` (repo): demo seed → Maya paid 380,
   moved 550, goal `Lego Friends set` 1550/2499, nickname Maya, Pip
   mochi/sunny/none/3; after `recordPayout(maya, 420, move 100,
   goal-lego)` → paid 420 / moved 100 / saved 1650; payout with no move →
   `movedPence` null; child with no payout row → `null`; active-child
   switch re-emits (belt: Leo paid 190).
2. `kid_jar_bloc_test.dart` (extend): payout emission → `loaded` with
   celebration; two `KidJarPayoutRequested` → single live sub (reload
   guard); stream error → `failure`; retry after error recovers.
3. `payout_day_view_test.dart`: seeded payout+move+goal renders
   `Mum marked £4.20 as paid`, `£1.00 went into your Lego Friends set`,
   `£16.50`-style goal math from the SAME rows (e.g. saved 1650/2499 →
   66%, `£8.49 to go`); `Thanks Mum!` → `/kid-home`; back pops (else home);
   lock pushes `/parental-gate`; failure shows `Try again` and reloads;
   null payout shows empty state; every control has tap action and
   `performAction(tap)` navigates/reloads; `PipAvatar` present with the
   seeded look (mochi, stage 3); no `pip_stage_*.svg` asset referenced.
4. `payout_day_view_geometry_test.dart`: rain box 180×270; note cards
   x=20/w=350 with 3 px ink border + r16; fund card x=20/w=350 r24;
   bar surface runs to the physical bottom edge (no meadow strip under
   bar/home indicator, either theme); title + first card + fund tops
   within ±2 px of `compare.py` design bands.

## (g) SHARED_REQUEST

None. Every component exists and is used, not modified: `KidScope`,
`NestStatusBar`, `NestIconButton`, `NestLockButton`, `NestKidButton`,
`NestProgress(kid: true)`, `NestBalancedText`, `NestSpeechBubble`,
`NestHomeIndicator`, `PipAvatar`, `PipMood.happy`, `jarPounds`,
`combineLatest3`, `watchChild/watchLedger/watchGoals`. The 3 px-top-border
kid bar is built inline per the K04 precedent (not `NestBottomCta`, whose
1 px line border contradicts `K10:13`). Pip switches are copied
feature-locally per RULES §1 (no cross-feature import, no shared edit).

VERDICT: PASS
