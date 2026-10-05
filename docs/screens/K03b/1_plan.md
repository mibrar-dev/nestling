# K03b plan — Kid home, all-done state (`/kid-home-done`, kid mode)

Stage 1 (iteration 1). Sources: `design/html-source/screens/K03b-kid-home-done.html`,
`design/screens/light|dark/K03b-kid-home-done.png` (1170×2532 = @3x, ÷3 = logical px),
DESIGN_SPEC §5 K03b, SPACING_SPEC, `docs/screens/K03b/ORCHESTRATOR_NOTES.md` (mandatory,
overrides the PNGs where they conflict), existing `kid_home` feature code.

## 0. Decisive constraints (read first)

1. **ONE kid home.** "All done" is a STATE of `KidHomeView`, shown whenever every one of
   the child's quests counts as done for the current period (`doneCount == totalCount &&
   totalCount > 0`, derived from existing `KidHomeState.doneCount/totalCount` — period
   scoping already lives in `KidHomeRepositoryImpl._watchItemsFor` via
   `countsForCurrentPeriod`, orchestrator PERIODS ruling). Do NOT build a separate screen.
2. **`/kid-home-done` renders the same `KidHomeView`** (route keeps path `/kid-home-done`
   and name `kid-home-done`). Replace the placeholder `KidHomeDoneView` (AppBar "K03b Kid
   home done"): delete `presentation/views/kid_home_done_view.dart` and remove its export
   from `kid_home.dart`. Nothing else imports it (verified: only `kid_home_routes.dart` +
   barrel; no test references it).
3. **K03 must not move.** The not-done branch renders byte-for-byte the current K03 UI.
   Re-run all K03 tests (`kid_home_view_test.dart`, `k03_bugs_test.dart`,
   `kid_home_geometry_test.dart`, etc.).
4. **Seed:** UI checks use `SEED=kid_all_done` (orchestrator branch
   `shared/kid_all_done_seed`, merged to main; the loop merges main before the build).
   Never edit `seed.dart`. Widget tests construct the all-done state directly (fake
   repository / entity lists), so no seed dependency at build/test time.
5. **Data over mocks:** counts and card meta come from the DB. Demo Maya is 4 of 6
   (2 approved + 2 done_pending); `kid_all_done` makes her 6 of 6. Card meta follows K03
   rules verbatim (see §d note on the reading-card discrepancy — do NOT "fix" it).
6. **Pip:** Maya's OWN Pip via `PipAvatar` (`mochi/sunny/none/stage 3` from her row via
   existing `pipStyleOf/pipSkinOf/pipAccessoryOf` in `kid_style_helpers.dart`). Never the
   v1 SVGs. Mood `happy` in the all-done branch (celebrating; screenshots run with
   `DISABLE_ANIMATIONS=1` → SVG fallback, so mood is Rive-only and cannot move K03).
7. No `flutter clean`, no interactive `flutter run` (only `tools/screens/shot.sh`), no
   simulator in builder stages, no `google_fonts`, no `DateTime.now()` (none needed —
   pure view branch), `flutter test --timeout 120s`, every pumped app ends with
   `disposeApp(tester)`.

## (a) Widget tree, top → bottom (design-system components + tokens only)

Root is the existing `_KidHomeBody` in
`app/lib/features/kid_home/presentation/views/kid_home_view.dart`, extended with one
boolean branch. New state getter in `kid_home_state.dart` (feature-owned, allowed):

```dart
bool get allDone => totalCount > 0 && doneCount == totalCount;
```

(`done` = `approved` + `done_pending`, existing definition — unchanged.)

```
KidScope (shared sky gradient + 136-tall meadow hills, bottom 0 — KID BACKGROUND rule;
          never paint local hills)
└ Scaffold (transparent)
  └ Column
    ├ NestStatusBar (reserves 47; OS draws glyphs — ignore in UI checks)
    ├ Header Padding(20, 4, 20, 10) Row(gap s2=8)
    │   ├ NestAvatar s64 lilac "M" (nestAvatarInitial — already used)
    │   ├ Expanded Semantics(label, excludeSemantics — informational grouping, NOT a
    │   │   control, so no onTap per ACCESSIBILITY rule) Column
    │   │   ├ Text 'Hi Maya!' — NestType.kidName (Nunito 22/26 w900), ink, 1 line
    │   │   └ Text — NestType.kidCaption (Nunito 15/20 w700)
    │   │       NOT-DONE: '$done done today', ink2 (CURRENT K03 — untouched)
    │   │       ALL-DONE: 'All done!', leafInk (K03b HTML l.22 `.k3-sub` = leaf-ink;
    │   │                PNG light shows green; dark shows light-green)
    │   ├ NestCoinPill(amount: '120' — child.coins from DB, standard size) (unchanged)
    │   └ _GateLockButton → NestLockButton large (56×56, r18) (unchanged)
    ├ Expanded
    │   NOT-DONE: current K03 ListView — untouched (pet stage w/ speech
    │             "Let's do some quests!", hearts row, section, progress, cards).
    │   ALL-DONE ListView(padding: zero):
    │   ├ Padding(20 sides) Center(NestSpeechBubble(text:
    │   │     'You did everything today! Pip is so proud.'))   // `.k3-bubble`,
    │   │     // centred; shared bubble (max-w 260, pad 8/14, Nunito 800 16,
    │   │     // 3px ink border, r18, 9px tail overflow). Copy ASCII-exact.
    │   ├ SizedBox(14)                                          // `.k3-pet
    │   │                                                      // margin-top 14`
    │   ├ Padding(20 sides) Stack(alignment topCenter)          // `.k3-stage`
    │   │   ├ Confetti plate: IgnorePointer + ExcludeSemantics,
    │   │   │   FittedBox(BoxFit.scaleDown) SizedBox(320, 250)
    │   │   │   SvgPicture.asset(NestlingIllustrations.confetti)
    │   │   │   // `assets/illustrations/confetti.svg`, constant already tagged
    │   │   │   // "Screens: K03b" (nestling_assets.dart:470-472). Static art —
    │   │   │   // renders under DISABLE_ANIMATIONS (same pattern as K05 burst).
    │   │   │   // Positioned top 4, centred (`.confetti` CSS). scaleDown keeps
    │   │   │   // 320px-wide devices overflow-free (K05 precedent).
    │   │   └ NestPetStage(
    │   │         pip: Transform.rotate(angle: -7° in rad,
    │   │                child: PipAvatar(style/skin/accessory from child row,
    │   │                  stage clamped 1..4, mood: PipMood.happy)),
    │   │         speech: null, nestWidth: 236, nestHeight: 188,
    │   │         fixedPipHeight: 152, slotHeight: 226,
    │   │         semanticLabel: 'Pip the Fledgling, stage 3 of 4, celebrating')
    │   │       // Same transcribed nest/pip numbers as K03 (236/188/152 — they
    │   │       // paint K03b's bowl outline exactly: same nest.svg, same 260
    │   │       // width, centred; battle-tested on K03). slotHeight 226 =
    │   │       // K03b `.k3-pet height:226px` (K06 precedent for slotHeight).
    │   │       // Tilt −7° = K03b `.pip rotate(-7deg)`; Transform is visual-only.
    │   ├ SizedBox(16)                                          // `.scroll>*+*`
    │   ├ Padding(20 sides) Row(gap 10)
    │   │   ├ Expanded NestBalancedText("Today’s quests", kidTitle ink, maxLines 2)
    │   │   │                                         // ’ = U+2019, as K03
    │   │   └ KidStatusChip('$done of $total done')             // `.kchip` h32
    │   ├ SizedBox(16)
    │   └ Padding(20, 0, 20, 32) Column(spacing 16)
    │       ├ NestProgress(fraction: state.fraction (=1.0), kid: true,
    │       │   semanticLabel: "$done of $total of today's quests done")
    │       └ Column(spacing: s3 − _kQuestCardShadowRoom) — same list, same
    │           _QuestCard (icon via questIconFor kid audience; tile tints:
    │           dishwasher→skyTint, book→lilacTint, bed→peachTint — all automatic;
    │           all checks done/display-only since every status is done)
    └ Bottom bar (replaces 3-button dock ONLY when allDone):
        Container(color: surface, border-top: 3px ink)
        └ SafeArea(top: false) Column
          ├ Padding(20, 12, 20, 4) NestKidButton(label: 'Visit Pip',
          │     color: lilac, icon: NestIcon(check), defaults: min-h 64, r24,
          │     Nunito 20 w900, gap 8, onPressed: () => context.go('/pip'))
          │   // `.kid-bar { padding:12px 20px 10px }`; bottom 4 = 10 − 6 button
          │   // shadow room (K05-measured precedent). Bar ≈ 3+12+64+6+4 = 89
          │   // (y 721…810), home indicator 810…844.
          └ NestHomeIndicator INSIDE the surface (BOTTOM EDGE owner rule: surface
              runs to the physical edge; no meadow strip under the bar, light+dark)
```

PNG spot-checks (÷3): header y 51…115 (avatar 64); bubble ~y 150…195; confetti
~y 200…450 around Pip; nest bowl ~x 62…328; section title y ~870/3≈870? (title
"Today's quests" baseline row ≈ y 880/3 ≈ 293? — builder: verify against HTML, HTML
wins; PNG ÷3 confirms). Kid-bar button y ≈ 2160…2400/3 = 720…800. Dark mode: same
geometry; surface/lilacStrong tokens flip automatically.

## (b) BLoC events / states / repository calls

**No new events, no new states, no repository changes.** `KidHomeLoadRequested` →
`watchHome()` (child + items, period-scoped statuses) exactly as K03. The view reads:

- `state.child` (nickname, coins, pip look, avatar colour) — unchanged.
- `state.items` (titles, icons, coin rewards, statuses) — unchanged.
- `state.allDone` (new pure getter, §a) — the only logic addition.
- `state.fraction` (1.0 when all done) — unchanged.

Loading / failure / null-child channels render the existing `_KidLoading` /
`_KidFailure` / `_NoActiveChild` widgets verbatim (shared view = shared channels).
`_onQuestCompleted` path is unreachable when all done (all checks display-only), but
stays wired — no removal.

## (c) Interactions + navigation (route constants)

| Element | Gesture | Destination |
|---|---|---|
| Visit Pip (lilac, 64-min) | tap | `context.go(PipRoutePaths.nest)` = `/pip` (`features/pip/pip_routes.dart`; same call K03 dock Pip uses) |
| Lock button (56) | tap | `context.push(ParentalGateRoutePaths.gate)` via existing `_GateLockButton` (tap guard kept) |
| Quest card (any) | tap | `context.push(KidHomeRoutePaths.detail, extra:{questId, childId})` — existing `_openDetail` (unchanged; approved/done cards behave exactly as K03's do) |
| Quest check (all done) | none | display-only (`onToggled: null` — automatic: every item is done) |
| Coin pill, avatar, bubble, confetti, progress | none | informational / decorative |
| `/kid-home-done` route | — | builder returns `BlocProvider(...KidHomeLoadRequested, child: KidHomeView())` — copy `kidHomeRoute`'s builder; path/name constants unchanged |

## (d) Empty / loading / error states

- `initial/loading` → `_KidLoading` (spinner + gate lock row, same as K03).
- `failure` → `_KidFailure` (own-Pip art, "Oh no! Pip got lost." + Try again → `KidHomeLoadRequested`).
- `loaded` + `child == null` → `_NoActiveChild` ("Who's playing?" + Choose → `/who-is-playing`).
- `loaded` + items empty → `allDone` is false (guard `totalCount > 0`) → existing `_KidEmptyQuests`. (Unreachable under `kid_all_done`, which seeds 6 quests.)
- **Known design discrepancy (do NOT code around it):** K03b HTML shows the reading/tidy
  cards with `+10`/`+15` coin pills AND filled checks, while K03 card logic shows a done
  card as `Waiting for Mum('s thumbs-up)` (done_pending) or `Done` (approved) chip and
  the dishwasher card as `Mum said yes!`. Cards reuse K03 rendering verbatim; meta content
  is DB-driven and excluded from the UI verdict. If `kid_all_done` marks everything
  `done_pending`, every card shows the waiting chip — correct per DATA OVER MOCKS.

## (e) Accessibility

- Every interactive element keeps `hasAction(tap)`: Visit Pip (`NestKidButton` exposes
  button+onTap semantics), lock (`NestLockButton`), cards (`NestKidQuestCard` onTap node;
  display-only checks report `enabled: false`, no tap — same as K03 approved cards).
- Header `Semantics(excludeSemantics: true)` groups STATIC text only (not a control) —
  same pattern as K03. All-done label: `'Hi $nickname, all done!'`.
- Confetti: `ExcludeSemantics` + `IgnorePointer` (decorative, K05-burst precedent).
- Pet semantics: image node `'Pip the ${pipStageName(stage)}, stage $stage of 4,
  celebrating'`.
- Progress keeps its `role=img` label; section chip is plain text (read in order).
- Tap targets: header/lock 56, checks 56, Visit Pip 64-min, cards 72-min — all ≥ 56 kid
  minimum. Text scale 1.3 + width 320: bubble max-w 260 + Center; confetti scaleDown;
  title/chip in Expanded/Flexible with ellipsis (existing K03 guards); bar button label
  single-line "Visit Pip" (no wrap risk). Clamp textScaler 1.0–1.3 per app rule.

## (f) Test plan (new file `app/test/features/kid_home/k03b_all_done_view_test.dart`)

Follow `kid_home_view_test.dart` patterns (in-memory Drift via `setUpTestScope`, fake
repository for state control, `disposeApp(tester)` at the end of EVERY pumped test,
`flutter test --timeout 120s …`, no `google_fonts`, pinned clock Sat 3 Oct 2026):

1. `allDone` getter: empty list → false; partial (4/6 demo statuses) → false; all
   approved/done_pending → true.
2. All-done pump (fake repo: Maya + 6 done items): finds `All done!` (leaf-ink),
   `You did everything today! Pip is so proud.`, `6 of 6 done`, `Visit Pip`;
   does NOT find 3-button dock (`Pip`/`Shop`/`My jar`), hearts row
   (`Pip is happy today`), or `Let's do some quests!`.
3. Partial pump (demo 4/6): finds `$done done today`, dock, hearts — i.e. K03 unchanged.
4. Semantics: Visit Pip node `hasAction(SemanticsAction.tap)`; `performAction(tap)`
   navigates to `/pip` (router pump test). Lock + cards keep K03 tap actions.
5. Cards display-only: all checks `enabled: false`; card tap still pushes detail.
6. Layout: 320-wide + textScaler 1.3 pump — no overflow exceptions; confetti renders
   (finds svg semantics excluded, i.e. silently present).
7. Route test: `/kid-home-done` pumps `KidHomeView` (no AppBar 'K03b Kid home done').
8. Re-run FULL existing kid_home suite — zero regressions (K03 must not move).

## (g) SHARED_REQUEST

None. Confetti asset exists (`NestlingIllustrations.confetti`,
`assets/illustrations/confetti.svg`). Route, bloc, repo, seed all exist or are
orchestrator-owned (`kid_all_done` seed lands via `shared/kid_all_done_seed` — builder:
confirm it is on main after the loop's pre-build merge; if absent, UI-check stage owns
the wait, NOT a screen-side seed edit). No design-system changes needed
(`NestSpeechBubble`, `NestPetStage(slotHeight)`, `NestKidButton`, `KidStatusChip`,
`NestProgress(kid:)` cover every element).

Builder file checklist (only §1 of RULES may be touched):
- EDIT `features/kid_home/presentation/views/kid_home_view.dart` (all-done branch).
- EDIT `features/kid_home/presentation/bloc/kid_home_state.dart` (add `allDone` getter).
- EDIT `features/kid_home/kid_home_routes.dart` (`kidHomeDoneRoute` → `KidHomeView`).
- DELETE `features/kid_home/presentation/views/kid_home_done_view.dart`.
- EDIT `features/kid_home/kid_home.dart` (drop deleted export).
- ADD `app/test/features/kid_home/k03b_all_done_view_test.dart`.
- `dart format`, `flutter analyze` clean, full kid_home suite green.

VERDICT: PASS
