# K10 · Payout day — QA code review (iteration 2)

Scope: `git diff main...HEAD` — `kid_jar` presentation/bloc/domain/data for
K10, feature tests, `docs/screens/K10/**`. No code was edited at this stage.
No simulator was booted, installed on, screenshot or driven. No images
attached; design PNGs read with the file reader only.

Checks run (evidence):

- `flutter analyze lib/features/kid_jar test/features/kid_jar` →
  2 `info`-level lints, both in the new iteration-2 test file (finding 1).
  `lib/` itself is clean.
- `dart format --set-exit-if-changed lib/features/kid_jar
  test/features/kid_jar` → 0 changed.
- `flutter test --timeout 120s test/features/kid_jar` → **+267 ~6, All
  tests passed!**
- Byte checks: title is U+0027 (`It's payout day!`); the `Jar →` arrow in
  the impl (`e2 86 92`) matches the seed's bytes; no `pip_stage_*.svg`
  reference in `kid_jar` lib; no `TODO`/`FIXME`; no `DateTime.now()` in
  lib (one comment mention only); no `google_fonts` import/call in lib or
  tests; no `letterSpacing` on this screen (K10 CSS sets none).
- Isolation (RULES §1): every changed app/test file is inside
  `app/lib/features/kid_jar/**`, `app/test/features/kid_jar/**`,
  `docs/screens/K10/**`. No `core/**`, `app/**`, other feature, or
  `tools/screens/**` touched. The `k09_bugs_test.dart` /
  `my_jar_view_states_test.dart` deltas are pure interface conformance
  (the new `watchLatestPayout` stub on existing fakes). No
  `SHARED_REQUEST.md` needed.
- Architecture: feature-first holds. `PayoutCelebration` is an Equatable
  domain entity with clamped helpers; `watchLatestPayout` is the abstract
  repo method with the Drift impl in `data/`; one `KidJarBloc` per feature
  (factory in `kid_jar_di.dart`, fresh instance per route, so K09/K10 state
  never cross-contaminates); routes dispatch `KidJarPayoutRequested`
  instead of `KidJarLoadRequested` at the route level per the contract.
  No use-case classes, no extra folders. Cross-feature imports are route
  constants only (`kid_home`, `parental_gate`), same as the K09 precedent —
  navigation, not layering.
- Iteration-1 bugs verified fixed: K10-BUG-1 (`_closing` synchronous guard
  on BOTH `*Requested` handlers, stronger than the suggested `isClosed`
  check — correct, since `isClosed` flips last in `Bloc.close()`);
  K10-BUG-2 (`goalPercent` now derives from the clamped `goalFraction`,
  the K09 `JarGoalCard.percent` precedent); K10-BUG-3 (note title wraps
  freely with no `maxLines` cap; fund amounts sit in
  `FittedBox(scaleDown)` inside `Flexible` rows). Iteration-1 review
  findings 1 (pip comment) and 2 (failure `message` param) are fixed in
  the current code.
- Design-system usage: all fills/borders/shadows/radii/spacing via tokens
  (`surface`, `ink`, `coinTint`, `leafTint`/`lilacTint`, `ink2`,
  `nestKid.borderWidth`, `kidShadow`, `NestRadii`, `NestSpacing`);
  components reused (`KidScope`, `NestStatusBar`, `NestIconButton`,
  `NestLockButton`, `NestKidButton`, `NestProgress(kid: true)`,
  `NestBalancedText` on the balanced `.kid-title` heading,
  `NestSpeechBubble`, `PipAvatar` with the DB child's own
  style/skin/accessory/stage, clamped). Fixed colours exist only in the
  transcribed illustration palette (`_RainPalette`, circle-arrow glyph —
  same fixed-illustration rule as `JarIllustration`) plus `transparent`.
  The 3 px-top-border kid bar is built inline per the K04 precedent, not
  `NestBottomCta` (whose 1 px border contradicts `K10:13`).
- Copy: `It's` (U+0027), `Grown-ups`, `Thanks Mum!`, `Mum marked £X as
  paid` / `Pocket money for this week`, `£X went into your <goalTitle>` /
  `Just like you asked`, fund captions — shapes match the HTML; amounts,
  goal figures, nickname and Pip look come from the DB (DATA OVER MOCKS).
  UK spelling throughout.
- Accessibility: back/lock/Thanks/Try-again/Back-home all expose
  `SemanticsAction.tap` via the Nest buttons (asserted with
  `performAction` driving real navigation/reload); title is a header;
  notes merge to one spoken sentence; rain/progress/Pip carry image/value
  labels; `_busy` double-tap guard proven by mutation in `3_test.md` §4.
  Targets ≥ 56 px in all 12 matrix cells.
- Performance: no timers/controllers; painters repaint only on their token
  input; `close()` cancels both subs; reload cancels the previous sub;
  error path releases the sub; repository `_switchMap` cancels inner/outer
  on dispose. No rebuild storms (single `BlocBuilder`, state-driven).
- Error handling: failure → kid-voice card with `Try again` that really
  re-subscribes (second stream controller asserted); `null` payout →
  dedicated empty state; loading keeps chrome + live-region spinner.
  PERIODS correctly documented N/A (payout rows are event history).
- Children's Code: no analytics/ads/external links; no red, no countdowns,
  no shaming copy; only the active child's own row is rendered.

Findings:

1. minor — `app/test/features/kid_jar/kid_jar_bloc_test.dart:917,953`
   Two `cascade_invocations` infos (`Unnecessary duplication of
   receiver`). RULES §7 requires `flutter analyze` → No issues found.
   Fix: rewrite each receiver-duplicated block as a cascade
   (`repo..a()..b()`), re-run `flutter analyze
   test/features/kid_jar/kid_jar_bloc_test.dart`.
2. minor — `app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart:56,123`
   Both reload paths `emit(state.copyWith(status: KidJarStatus.loading))`,
   which preserves a stale `errorMessage` from a previous failure during
   the reload (carried over from iteration-1 review finding 3; the
   iteration-2 close-guard edit did not sweep it). Invisible today — the
   loading view wins and the next healthy emission clears it via
   `copyWithPayout`/`copyWithLoaded` — but any `errorMessage` reader sees
   failure text while `status == loading`. Fix: emit loading with the
   error cleared (e.g. extend `copyWith` with an explicit clear, since
   `??` cannot null it).
3. minor — `app/lib/features/kid_jar/data/kid_jar_repository_impl.dart:150-158`
   The companion move is the NEWEST `Jar → …` move stamped at/after the
   payout instant, so a later unrelated manual jar→savings move would be
   attributed to an older payout (carried over from iteration-1 review
   finding 4). Documented, seeded paths covered and correct. Fix (hardening
   only): prefer the OLDEST qualifying move — the one `recordPayout`
   writes in the same single-`now` transaction as the payout.
4. minor — `app/lib/features/kid_jar/presentation/views/payout_day_view.dart:234-256`
   Plan §a specifies the bar as `NestKidButton` + `NestHomeIndicator`
   inside the surface box; the indicator is missing (K04 keeps it at
   `quest_detail_view.dart:691`). Zero prod impact — `NestHomeIndicator`
   returns `SizedBox.shrink()` when mock glyphs are off
   (`nest_chrome.dart:225`; the OS draws the pill) — and the matrix raster
   probes pass; only the design-system gallery mock pill is absent. Fix:
   wrap the bar child in `Column(mainAxisSize: MainAxisSize.min)` holding
   the existing `Padding` plus `const NestHomeIndicator()`, matching K04.
5. minor — `app/lib/features/kid_jar/presentation/views/payout_day_view.dart:263,279`
   `_CheckDisc` and `_MovedDisc` declare no `const` constructor, so the
   `disc:` arguments rebuild with every parent build. Negligible (parent
   rebuilds only on state change). Fix: add `const _CheckDisc({super.key});`
   / `const _MovedDisc({super.key});` and mark the call sites `const`.

Recorded, not filed (loop/orchestrator-owned, per the stage rules):

- No in-product navigation reaches `/payout-day` yet (deep-link only;
  `6_bugs.md` record 1). Cross-screen integration outside K10 scope.
- `RULES.md` §4 calls K09 "the only £ screen", but the K10 design, HTML
  source and plan all show £ on payout day too. Shared-doc wording drift;
  the code correctly follows the design + plan.

No blocker or major findings. All three iteration-1 bugs are fixed with
proofs green, isolation and architecture hold, and the remaining items are
lints, invisible-state polish, hardening, and gallery cosmetics.

VERDICT: PASS
