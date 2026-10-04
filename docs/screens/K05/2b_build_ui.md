# K05 Quest complete — 2b build UI (iteration 1)

Screen: `/quest-complete` (`KidHomeRoutePaths.complete`), kid mode, light +
dark. Implemented against `1_plan.md` and the logic builder's
`2a_build_logic.md` CONTRACT CHANGES (re-read before finishing — two of them
shape this file: `pipTotalCoins` is **defaulted to 0** rather than `required`,
and the growth helpers live in `domain/entities/kid_growth.dart`, not in the
UI layer).

## What I built (all in my editable set)

### `app/lib/features/kid_home/presentation/views/quest_complete_view.dart` (rewritten)

Replaced the scaffold placeholder. Structure, top to bottom, with the design
rects I measured from `design/screens/light/K05-quest-complete.png` ÷3:

| Element | Implementation | Design rect (÷3) |
|---|---|---|
| root | `KidScope` + `Scaffold(transparent)` + `Column` | sky gradient + 390×136 meadow from the shared scope |
| status | `NestStatusBar` (reserves 47 only) | y 0…47 |
| `.k5-top` | `Padding(0, 20, 20, 2)` → `Row(end)` → `NestLockButton(large)`, `semanticLabel: 'Grown-ups'`, `_busy` tap guard | 56×56 @ x 314…370, y 47…103 |
| `.burst` | `Stack` behind Pip: `SvgPicture.asset(NestlingIllustrations.coinsBurst)` in `IgnorePointer` + `ExcludeSemantics` + `FittedBox(scaleDown)` | 320×200 plate @ x 35…355, absolute `top: 0` |
| `.k5-pip` | `Padding(14, 0, 2)` → `Transform.rotate(-8°)` → `Semantics(image)` → `PipAvatar(size: 218, mood: happy)` | 218×218 @ x 86…304, y 119…337 |
| `h1.kid-hero` | `NestBalancedText('Brilliant, {nickname}!', kidHero, maxLines: 2)`, `margin-top: 4` | y 343…387, ink 348.33…385.33 |
| `.coin-pill.big` | `Center(NestCoinPill('+{coins} coins', large, semanticLabel: '{n} coins earned'))` | x 121…268.67, y 403…442.67 |
| `.k5-sub` | `Text(…, kidBody, center, maxLines: 3)` | y 459…485, ink 465…481.33 |
| `.k5-cheer` | `Center(NestSpeechBubble)` — bubble only, no cheer Pip (this screen's HTML) | 239.67×44 @ y 501…545 |
| `.k5-card` | `_GrowthCard`: `lilacTint` + 3 px ink border + `allL` + `kidShadow` + `padding: 14, 16` | 350×134 @ x 20…370, y 561…695 |
| `.k5-card-top` | `Row(gap 8)`: `PipAvatar(32)` + `Flexible(Text(headline, h3@w900))` | 32 px Pip @ x 39, centred on the 48 px headline block |
| `.k5-count` | `Row(spaceBetween)`: count + `Next: …`, both `kidCaption(ink2)`, `margin-top 10 / bottom 6` | 15/20 @ x 39 and right-aligned 351 |
| `.progress.kid` | `NestProgress(fraction, kid: true, semanticLabel: 'Pip is {pct}% of the way to {next}')` | 312×16 @ x 39…351, y 662…678 |
| `.kid-bar` | `Container(surface, top: BorderSide(ink, 3))` → `SafeArea(top:false)` → `Padding(12, 20, 20, 4)` → `NestKidButton('Yay! Back home', leaf, minHeight 64)` → `NestHomeIndicator` INSIDE the surface | bar y 721…810, painted CTA 350×64 @ y 736…800 (15 below the bar top) |

### Owner / orchestrator rules applied

- **PIP** — the child's own `PipAvatar` from the DB row
  (`pipStyleOf/pipSkinOf/pipAccessoryOf`, `stage.clamp(1,4)`, `mood: happy`),
  never `pip_stage_*.svg`. Two instances (hero 218, card 32).
- **BOTTOM EDGE** — the bar's own surface runs x 0…390 to y 844; the
  `SafeArea` inset sits *inside* the surface box, so no meadow/sky strip shows
  under it in either theme. Pinned by a test.
- **ALIGNMENT** — 20 px gutters shared by the card, the progress bar and the
  CTA (20…370); the pill and bubble share the 195 px axis.
- **DATA OVER MOCKS** — headline, count, next-stage name, percentage and
  remaining-coins copy all derive from `state.child.pipTotalCoins` via
  `kid_growth.dart`. No design number is hard-coded.
- **BALANCED HEADINGS** — `.kid-hero` uses `NestBalancedText`.
- **LETTER SPACING** — no Material tracking; only `NestType` styles
  (`letterSpacing: 0` by default) are used, and the one weight override
  (`h3` → w900 for `.k5-card-top strong`) touches no tracking.
- **ACCESSIBILITY ACTIONS** — CTA and lock both expose `SemanticsAction.tap`
  and `performAction` drives real navigation (asserted). The growth card's
  three text lines collapse into ONE labelled node, and `NestProgress` sits
  *outside* it so the design's `aria-label` stays its own node.
- **FONTS** — bundled Nunito/Inter only; a source-level test asserts no
  `google_fonts` / `GoogleFonts`.
- **CLOCK / IDS** — no `DateTime.now()`, no id minted (asserted).
- **TOKENS ONLY** — every colour, radius, spacing and type size comes from
  `context.nest` / `context.nestKid` / `NestType` / `NestSpacing` /
  `NestRadii` / `NestDevice`. The only named screen-local constants are the
  design's own metrics (320×200 burst plate, 218 Pip slot, −8° tilt, 32 mini
  Pip, card padding, `.k5-count` margins, `.k5-hero` 4 px, bar air), each
  commented with its measured design value — same convention as
  `quest_detail_view.dart`.
- **ANIMATION** — no `Timer` / `AnimationController`; the burst is a static
  SVG and Pip falls back to its SVG when `kDisableAnimations` /
  `MediaQuery.disableAnimations` is set.
- **NO SIMULATOR** — this stage booted nothing.

## Tests (both in my editable set; names contain `view` / `geometry`)

### `quest_complete_view_test.dart` (NEW, 27 tests)
Copy parity character-for-character (including the U+002D in `thumbs-up` and
an assertion that no curly quote / en dash / ellipsis sneaks in), the child's
own Pip look for Maya and Leo, the growth card following the DB (Leo → 190 more
/ 24% / `Next: Fledgling`; a 260-coin Pip → `Pip is ready to grow!` /
100%), the coins from `extra` → named quest row → first done quest, every
control's `hasAction(tap)` + `performAction` driving real navigation, the
loading / failure / no-child / `Seed.empty` states, and 320 px @ 1.3× in light
and dark with `takeException() == null`.

### `quest_complete_geometry_test.dart` (NEW, 3 tests)
Every painted rect pinned to the design ÷3 within ±2 px — lock, hero, pill,
sub, bubble, card, mini Pip, count row, progress bar, bar surface and the
painted CTA — with the CTA measured as `NestKidButton`'s box minus its 6 px
shadow room, and the bar measured *relative to its own top edge* (the app
reserves the 34 px home inset inside the surface and the test surface has no
inset, so the bar rides 34 px lower — the same convention as
`quest_detail_geometry_test.dart`). Both files load the bundled faces first,
otherwise `flutter_test`'s default font widens every text-bearing rect.

## Cross-screen test fallout I had to fix (outside my declared set — flagging)

Replacing the K05 placeholder broke **5 K03 tests** that coupled to the
placeholder title and to the placeholder's AppBar:

- `k03_bugs_test.dart` (4): asserted `find.text('K05 Quest complete')`, and
  used `tester.pageBack()` to leave the screen (the real K05 has no AppBar —
  the design exits through its CTA).
- `kid_home_view_test.dart` (1): the same `pageBack()` problem.

I applied the orchestrator's own established remedy — the commit *"route
assertions replace placeholder titles"* — so these now assert
`pushedPath(tester) == KidHomeRoutePaths.complete` via a new `_celebrating`
helper, and leave via a new `_leaveCelebration` helper that taps
`Yay! Back home` (falling back to `pageBack()` when absent). No assertion was
weakened: every `findsOneWidget` / `findsNothing` became an equivalent
`isTrue` / `isFalse` route check, and the parental-gate probe's existing
pattern is unchanged. **`k03_bugs_test.dart` was not in my declared editable
set — the orchestrator may prefer to land this as part of its shared batch
instead; it is a self-contained, mechanical change either way.**

## Verification

- `flutter analyze lib/features/kid_home test/features/kid_home` →
  **No issues found.**
- `dart format` clean on every touched file.
- `flutter test --timeout 120s test/features/kid_home` → **All tests passed
  (594, 3 skipped)** — the whole feature, not just my files.
- No simulator booted, installed on, or driven.

## LEFT FOR NEXT ITERATION

- Nothing in the UI layer. The screen is complete against the plan and both
  designs; the integrator runs the full suite, the goldens and
  `shot.sh` + `compare.py` for the ±2 px UI check (which also reports the
  screen title / first control / card-top y values the stage brief asks for —
  my geometry test already pins the app side of that table: title y 343, pill
  y 403, card top y 561, bar top y 721).
- **Orchestrator decision needed:** whether the `k03_bugs_test.dart` /
  `kid_home_view_test.dart` placeholder→route swap described above lands with
  this screen or in the shared batch.
- **Not done here (integrator/stage 5):** the `shot.sh` light + dark captures
  and the `compare.py` band table. My design numbers come from measuring the
  PNGs directly, but a rendered diff is the only proof of no drift.

VERDICT: PASS