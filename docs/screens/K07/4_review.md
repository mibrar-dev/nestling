# K07 · Pip evolves — stage 4 QA code review (iteration 3)

Reviewed: `git diff main...HEAD` for K07 (13 `lib` files; 15 test files under
`test/features/pip`, of which 4 are the foundation's K06 bloc/state tests and
were adapted, not weakened) against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K07
(`docs/DESIGN_SPEC.md:202`), `docs/design/SPACING_SPEC.md`,
`app/lib/core/design_system/`, `1_plan.md`, `6_bugs.md`,
`ORCHESTRATOR_NOTES.md` and the orchestrator rulings in the brief.

**No simulator was booted, installed on, driven or screenshotted** (only stage 5
may, and only `BC440E48-B3A3-43BC-971B-0EF5DB621874`). **Nothing was edited** —
`git status app/` shows no product change from this stage. No image was attached
to this reply. No `flutter clean`, no interactive `flutter run`, no
`analysis_options` change, no global kill.

Iteration-3 delta actually re-reviewed line by line: `git diff 34abefa f4174f9
-- app/` (3 lib files, +112/−39: the D4 dark-palette fix, the `toLoading`
retry fix, the fixture change). The rest of `main...HEAD` is iteration 1+2,
re-checked wherever iteration 3 touched it, and re-verified against the gates
below.

## Verdict summary

| # | Severity | Finding |
|---|---|---|
| 1 | **MINOR** | `evolutionSub(0)` still renders **“Because you helped 0 times”** under “Pip grew into a Hatchling!” — iteration-2 finding 2 is unfixed, correctly, because it is waiting on the orchestrator's copy sign-off (`SHARED_REQUEST.md` §5). |
| 2 | **MINOR** | The design's spark count is transcribed as the literal `4` in **three** places (view clamp, stage-slot clamp, two copy strings) with no shared constant — a fifth stage would leave the copy lying. |
| 3 | **MINOR** | The one mandatory item the 23:55 note asks for that is **not literally satisfiable**: the sky dot's `#3D7FF0` has no token, so the layer paints light `--sky` (`#2563D6`) in both themes. Documented, pinned by a test, filed as `SHARED_REQUEST.md` §4. |

**No blocker. No major.** The one major open from iteration 2 (`6_bugs.md`
K07-BUG-5, the dark-mode sparkle palette) is **fixed and proven**; both
iteration-2 review findings that could be closed are closed.
**VERDICT: PASS**.

## Gates re-run by this stage (no simulator)

| Gate | Result |
|---|---|
| `dart format --set-exit-if-changed .` | **clean** — 642 files, 0 changed |
| `flutter analyze` | **No issues found!** (6.2 s) — iteration 2's *gate risk* is **closed**: the file that then carried 4 diagnostics (`pip_evolution_stream_contract_test.dart`, untracked with a `NestKidTokens` type error) is now committed and analyses clean |
| `flutter test --timeout 120s test/features/pip` | **419 tests, all passed**, `00:10`, 0 skips (every `skip:` hit in `rg` is inside a comment) |
| `flutter test --timeout 120s` (whole app) | **run 1:** 4476 tests, 2 failures — `test/widget_test.dart` (“App launches to the design system gallery”) and `test/features/rewards/rewards_write_failures_test.dart` (P14); both **pass in isolation** (1/1 and 9/9), neither file references `pip` at all, and K07's diff touches nothing they import. **run 2:** 4485 tests, 3 failures — **neither of run 1's tests appears**, and all three are in `test/features/pip/zz_probe*_iter3_k07_test.dart`, untracked scratch probes another stage created in this worktree *during* the run. Two runs, zero committed-code failures, zero pip failures: the run-1 pair is a full-suite concurrency flake, not a K07 defect (see *Notes*). |
| **tree state** | the three gates above were measured on the committed state (`HEAD = f4174f9`). Part-way through this stage another stage began writing in the same worktree (`git status app/` now shows 4 modified test files and 6 untracked `zz_probe*_iter3_k07_test.dart` scratch files). Per the PROCESS rule that in-flight work is the loop's and the orchestrator's — not a finding — but it is why the probe files must not be committed: `zz_probe*` scratch has been deleted by K07's own earlier stages for exactly this reason. |

RULES §7.1 is satisfied for everything this branch owns.

## RULES §1 scope — clean

```
$ git diff --stat main...HEAD -- app/analysis_options.yaml app/lib/core app/lib/app tools design
(empty)
```

The diff touches only `app/lib/features/pip/{domain,data,presentation}/**`,
`app/test/features/pip/**` and `docs/screens/K07/**` — no other feature, no
`core`, no `app/`, no `tools/`, no design source, no
`analysis_options.yaml`. (`git diff --stat main...HEAD -- app/` = 28 files, all
under `features/pip` + `test/features/pip`.)

## `ORCHESTRATOR_NOTES.md` — every item mandatory, all satisfied

| Item | Ruling | Verified in code |
|---|---|---|
| **D4** (23:55, iteration 3) dark sparks | stroke AND every fill from `NestColors.light` in both themes; `shouldRepaint` theme-independent; test under dark theme asserting stroke `0xFF1E1B3A` | **Delivered, exactly.** `_Spark.color` (`pip_evolution_sparks.dart:91-97`) takes **no parameter** and reads `NestColors.light.*`; the stroke reads `NestColors.light.ink` (`:167`) = `0xFF1E1B3A`; `shouldRepaint` is `false` (`:194-199`); the widget tree is `const` end to end (`:142-156`), so a theme switch no longer repaints the layer at all. Proofs: `k07_bugs_test.dart:953-1013` (real app shell in dark, palette sampled off the painter's own raster: stroke `#1E1B3A`, lilac/success/coin/peach at their light values, and the **whole dark raster equal to the light raster**, which is the property the design's inline SVG has by construction) + `pip_evolution_sparks_test.dart:274-309` (every hex **in the HTML block** reaches the canvas in both themes, read from the design source, not from the app). **100 % of the dark-mode defect is gone.** The single exception is finding 3 below. |
| **D2** (19:10) sparkle shape | the exact HTML 4-point path at the 4 spots, ink 3 px stroke | **Still intact after the rewrite** (iteration 3 only touched colour resolution). Re-derived mechanically from the HTML, not by eye: all four `d` strings and all four `(cx, cy, r)` triples are byte-identical to `K07-evolution.html:36-44`; `<g stroke="#1E1B3A" stroke-width="3" stroke-linejoin="round">` maps to `NestColors.light.ink`, `strokeWidth = 3`, `StrokeJoin.round`. Every vertex including the `M` tip goes through one `addPolygon` (`:216-219`) — the D2 tip-loss bug cannot come back. Shape proofs still live in `k07_sparkles_bug_test.dart` and are green. |
| **D3** (19:10) bubble tail | accept the CSS 18×9; the shared `NestSpeechBubble` follows it | Nothing owed. The view uses the shared bubble (`pip_evolution_view.dart:358-363`) — no local re-implementation, no second bubble in the feature. |
| **D1** (19:10) Fledgling copy | accept the +34 px stack shift (DB truth) | Correctly DB-driven: `evolutionTitle(stage)` is built from `profile.stage`, so demo Maya reads “Pip grew into a Fledgling!” and the stage-4 numbers (`25`/`250`) appear nowhere in code. |

## Iteration-2 review findings — disposition (all 3)

| # | Was | Now |
|---|---|---|
| 1 | MINOR `toLoading()` cleared **both** arrival flags while a retry re-subscribes only the dead stream, stranding the sibling on a spinner with no retry button | **fixed** — `toLoading({restartingNest, restartingEvolution})` (`pip_state.dart:125-148`) now resets only the streams actually restarted, and `_onLoadRequested` passes exactly that (`pip_bloc.dart:57-62`, `restartingNest: _nestSub == null`). Both directions are proven at two levels: state-level (`pip_evolution_bloc_test.dart:699-…`) drives a real `PipLoadRequested` where the **nest fails and the evolution stream never re-emits again**, then asserts `evolutionStatus` stays `loaded`, the celebration data survives, and every published `evolutionStatus` after the retry is `loaded`; the mirror case (evolution fails, nest survives) is asserted too. The invariant “settled ⇔ this stream has answered since its last load” now actually holds. |
| 2 | MINOR `evolutionSub(0)` = “Because you helped 0 times” | **open, correctly** — no zero branch in `pip_evolution_copy.dart:48-50`. The build stage did not invent copy the design has no source for; it pinned today's behaviour as *under review* in `k07_bugs_test.dart:1111-1115` and filed for sign-off (`SHARED_REQUEST.md` §5). Severity stays MINOR for the reason given last iteration: `rg 'PipRoutePaths.evolution' app/lib` still finds only the route definition, so the screen is reachable via `INITIAL_ROUTE=/pip-evolution` or a deep link, not by tapping. → finding 1. |
| 3 | MINOR a test header pointed at `pip_evolution_sparks_bug_test.dart`, which does not exist | **fixed** — `pip_evolution_sparks_test.dart:14` now names `k07_sparkles_bug_test.dart`, the file that exists and holds the silhouette proofs. |

## `6_bugs.md` K07-BUG-5 (the iteration-2 MAJOR) — closed

Fixed in `pip_evolution_sparks.dart` only, per the orchestrator's recipe, and it
is **not** a hard-coded-colour violation: `NestColors.light` *is* the 1:1
transcription of `tokens.css :root`, so `ink #1E1B3A`, `lilac #7C6CF2`,
`success #1F9D63`, `coin #F4B400`, `peach #FF8A5B` are read from tokens and
happen to equal the HTML's literals — verified token by token against
`tokens/colors.dart:274-320`. The proof was un-skipped and is green; the
`shouldRepaint → false` and "no dark ink reaches the canvas" assertions live in
`pip_evolution_sparks_test.dart`.

## What was checked and found sound

- **Architecture** — feature-first intact. `domain/` gains exactly one Equatable
  entity (`pip_evolution.dart`) and one abstract method on the existing
  repository (`watchEvolution()`); no use-case class, no new folder, no
  presentation import in `domain/` (`pipStageName` stays in
  `presentation/widgets/pip_look.dart`, ARCHITECTURE's domain rule). The Drift
  mapping and the private `_switchMap` live in `data/pip_repository_impl.dart:79-111`.
  **One bloc per feature** (ARCHITECTURE `:85` — not “one per screen”), provided
  per route by a GetIt **factory** (`pip_di.dart:17`, `pip_routes.dart:32-40`,
  both untouched), so the two screens can never share one bloc instance. Domain
  count logic reads statuses as literals (`done_pending || approved`) exactly as
  `features/today/data/today_repository_impl.dart:72` does, and reads **no
  clock** — correct, this is a lifetime milestone, so the PERIODS ruling does
  not apply (a daily quest completed on two days really is two rows: see
  `kid_home_repository_impl.dart:170-198`).
- **Design-system usage / no hard-coded values** — `rg` over `lib/features/pip`
  finds **zero** hex literals, **zero** `Color(0x…)` constructions, **zero**
  `letterSpacing` writes, no `google_fonts`/`GoogleFonts`, no `DateTime.now()`,
  no `print`/`debugPrint`, no `£`, no network/analytics symbol, no `name[0]`.
  Re-checked every geometry constant against `tokens/spacing.dart` so nothing is
  mis-aliased: `gap2`=2 (`.k7-old left`), `s1`=4 (`.k7-old bottom`),
  `s2`=8 (`.k7-arrow left: 76 = 68+8`), `s6`=24 (`.k7-arrow bottom`),
  `gap6`=6 (`.k7-new right`, `.k7-stats` cell padding), `gap10`=10 (`.k7-stats gap`),
  `s3`=12 (bar top / cell padding), `s8`=32 (`.scroll` bottom),
  `padSide`=20 (`.k7-top`, `.scroll`, `.kid-bar`) — all correct. The only
  non-token sizes are CSS-only values with the source line cited at each site
  (`.k7-stage 250`, `.k7-new 240`, `.k7-old 68`, arrow 30, `.sparks 350×250`,
  `top: 92`, `stroke-width 3`, `.k7-stats b 30/34` and `span 14/18`), which is
  the pattern the LETTER SPACING ruling prescribes.
- **Component reuse** — `NestStatusBar`, `NestHomeIndicator`, `NestLockButton`
  (default `large: true` → 56 px = `.lock-btn.lg`; its own `Semantics(onTap:)`),
  `NestKidButton`, `NestSpeechBubble`, `NestBalancedText`, `NestIcon.arrowRight`,
  `NestKidStarsPainter` (shared, mounted dark-only exactly as `KidScope` does),
  `PipAvatar`, `NestType.*`, `NestRadii.allM`, `NestSpacing.*`,
  `context.nest*` tokens. The radial glow is the one thing `BoxDecoration` cannot
  express (CSS's explicit `118% 62%` radii), so the translate/scale + unit-circle
  shader is the right call and is documented. `pip_look.dart`'s stage names and
  look mappers are reused, not re-declared.
- **BALANCED HEADINGS** — `.kid-title` carries `text-wrap: balance`, so the hero
  is `NestBalancedText` with the same copy, style and maxLines
  (`pip_evolution_view.dart:341-346`); `.kid-body`, the bubble and `.kcap`
  correctly are not.
- **PIP rule** — both slots render the **child's own** Pip from
  `pip_style`/`pip_skin`/`pip_accessory` at the DB stage
  (`pip_evolution_stage.dart:97-103`); no `pip-stage-*.svg` anywhere in `lib/`;
  the design's SLOT geometry (68 px silhouette at 0.24 opacity + grayscale,
  30 px lilac arrow, 240 px grown Pip right-anchored at `right: 6`) is kept; the
  no-child failure card uses `PipAvatar(mochi, sunny)` per the no-child rule.
- **KID BACKGROUND** — the documented exception is right and still holds:
  `K07-evolution.html:16` replaces the kid background with `--kid-stars` + the
  lilac `radial-gradient(118% 62% at 50% 36%)`, the K07 body has **no**
  `.meadow` element, and both PNGs show no sky and no hills. The glow is painted
  and the **shared** stars painter reused; no local hills anywhere. Still owed a
  one-line orchestrator ruling so a later iteration does not “fix” it back
  (`SHARED_REQUEST.md` §1).
- **BOTTOM EDGE / ALIGNMENT** — `_EvolutionBar` puts the surface `Container`
  **outside** `SafeArea(top: false)`, so the surface reaches the physical edge and
  the 34 px inset sits inside it: no glow strip under the bar and no tint around
  the home indicator in either theme, and the loading / failure / no-child bars
  keep the same opaque box with no border rule under nothing
  (`pip_evolution_view.dart:404-448`). One 20 px gutter for the lock row, the
  scroll column, the three cards and the CTA. The `.kid-bar` bottom padding is
  `s1` (4) rather than the CSS 10, because the shared `NestKidButton` reserves
  6 px for `--sh-kid` — 3+12+64+6+4+34 lands the CTA's top edge on the design's
  measured y = 736 exactly (K03's dock absorbs the same 6 the same way).
- **Copy** — every string byte-checked against the HTML with a `repr()` dump:
  line 55 title, 56 sub, 57 `Hear that? That is Pip's new song!` (**ASCII 0x27
  apostrophe, as the source writes it** — the code matches), 59/60/61 stat
  labels, 63 caption, 66 CTA, 48 `aria-label="Grown-ups"`. `…` is the single
  ellipsis character, UK spelling throughout (`rg` for `-ize/-or` user-visible
  strings: none), coins never `£`, no red, no nagging.
- **Accessibility** — every interactive node is a shared `onTap`-bearing widget
  (`NestLockButton` with the design's `Grown-ups` label, `NestKidButton` for CTA /
  retry / choose), and the two `excludeSemantics` nodes are non-interactive: the
  merged stat sentence (`pip_evolution_stats.dart:70-77`) and the decorative
  silhouette, arrow and sparks (`aria-hidden`/`alt=""` in the CSS), so no
  `onTap:` is owed on either. The grown Pip is announced as an image
  (“Maya's Pip, a fledgling”) and the old one is excluded. Tap targets: lock 56,
  CTA ≥ 64. `pip_evolution_a11y_test.dart` asserts `hasAction(SemanticsAction.tap)`
  for every control and drives real behaviour through `performAction` (retry
  re-subscribes, CTA → `/pip`, choose → picker, lock → gate).
- **Performance** — no `Timer`, no `AnimationController` (RULES §6), no reload
  events, no per-frame state. Both background layers, the sparks box and the lock
  row are `const`; both painters key `shouldRepaint` on what they actually read
  (the sparks painter now returns `false`, which is correct because it reads
  nothing but literals). The parsed sparkle `Path`s are cached per `d`
  (`:79-86`), so a repaint allocates one `Paint` per entry and nothing else.
  `close()` awaits both cancels and nulls the fields (`pip_bloc.dart:202-209`);
  `_switchMap` cancels its inner subscription per outer emission; a stream error
  releases only its **own** subscription, so “Try again” genuinely re-subscribes
  (pinned for both Dart failure-delivery shapes).
- **Error handling** — no raw exception can reach a kid screen: the failure cards
  render their own kind copy (“Oh no! Pip got lost.” / “Let's try again.” /
  “Who's playing?”) and `errorMessage` is documented as diagnostic-only and read
  by no view in this feature. A stream that answered and then failed keeps its
  data on screen (`_streamStatus` prefers `settled`), so a mid-session error never
  blanks a celebration.
- **Children's Code** — kid mode only: no analytics, no ads, no network, no
  third-party SDK, no identifiers, no `£`, no red, no timers or countdowns, no
  loss framing, nothing logged or transmitted. The child's only exposure is their
  own nickname inside a VoiceOver label, on device.

## Findings

### 1. MINOR — `evolutionSub(0)` renders “Because you helped 0 times”

`app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart:48-50`
(same finding as iteration 2's #2, unchanged, and deliberately not “fixed”
without sign-off).

```dart
String evolutionSub(int questsDone) => questsDone == 1
    ? 'Because you helped 1 time'
    : 'Because you helped $questsDone times';
```

The singular branch exists, the zero branch does not. `questsDone` is the
lifetime `done_pending + approved` count, and nothing in the schema ties a
child's `pip_stage > 1` to having completions (stage is a seeded column), so
`0` is a real DB state: a family whose Pip has grown through birthday money
opens `/pip-evolution` and the screen reads “Pip grew into a Hatchling!” above
**“Because you helped 0 times”** — a self-contradiction on a celebration
screen, the tone class the Children's Code rules and the `no nagging` rule exist
to prevent.

Kept at MINOR (not major) for the same structural reason as last iteration: the
route has no in-app entry point (`rg 'PipRoutePaths.evolution' app/lib` returns
only `pip_routes.dart:31`), so it is reachable via `INITIAL_ROUTE` or a deep
link. It is also blocked on copy the screen may not invent: no design source has
a zero case, so the wording needs the orchestrator's ruling before it lands
(`SHARED_REQUEST.md` §5). Today's behaviour is pinned as *under review* by
`k07_bugs_test.dart:1111-1115`, so it cannot be forgotten silently.

Fix (once the wording is signed off), in the same copy table:

```dart
String evolutionSub(int questsDone) => switch (questsDone) {
  0 => '<signed-off zero line>',            // e.g. 'Pip is ready for its first adventure'
  1 => 'Because you helped 1 time',
  _ => 'Because you helped $questsDone times',
};
```

then move the assertion at `k07_bugs_test.dart:1115` with it and add
`evolutionSub(0)` / `(1)` / `(4)` to `pip_evolution_copy_test.dart:252-255`.

### 2. MINOR — the spark count `4` is transcribed as a literal in three places

`app/lib/features/pip/presentation/views/pip_evolution_view.dart:67`
(`_kStatsStageCount = 4`), `app/lib/features/pip/presentation/widgets/pip_evolution_stage.dart:92`
(`profile.stage.clamp(1, 4)`) and
`app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart:74` (`'of 4
stages'`) + `:107` (`'stage $stage of 4'`). The design's `of 4 stages` is a
literal, so transcribing it is correct today; the risk is that the number lives
in three files with no shared source, so a fifth stage (`pipStageName` would
need a new arm anyway) would leave the card label claiming “of 4 stages” while
the clamp silently drops the new stage.

Fix (one small addition in the feature's existing Pip table, no shared file):
declare `const int pipStageCount = 4;` beside `pipStageName` in
`presentation/widgets/pip_look.dart:18` and use it in the two clamps and in both
copy strings (`'of ${pipStageCount} stages'`,
`'stage $stage of ${pipStageCount}'`), deleting the private view constant.

### 3. MINOR — the sky dot's `#3D7FF0` cannot be painted literally without breaking the tokens-only rule

`app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:91-97`
(header rationale at `:17-29`; pinned by
`pip_evolution_sparks_test.dart:245-273`; filed as `SHARED_REQUEST.md` §4).

The 23:55 note asks to “verify each fill hex equals the HTML's literal”. Five of
the six entries do, because `NestColors.light` holds exactly those values. The
sixth — the `cx=268 cy=8 r=6` dot, `fill="#3D7FF0"` — has **no token in either
scheme** (`--sky` is `#2563D6` light / `#7FA9FF` dark), and the MUST-level
tokens rule forbids hard-coding it, so the layer paints the light `--sky`
(`#2563D6`) in both themes: a 6 px dot, 24/28/26 per channel off the design.
The alternative — `const Color(0xFF3D7FF0)` — would violate
“never hard-code colours”, which is the stricter instruction, so the current
choice is the defensible one; it is documented in the file header, asserted in
both directions by a test (the literal is **never** painted, and every *other*
design hex always is), and filed for the orchestrator.

Fix: one of the two rulings already requested in `SHARED_REQUEST.md` §4 — add
`sparkBlue: #3D7FF0` to `app/lib/core/design_system/tokens/colors.dart` (shared,
so it is the orchestrator's to apply; then the entry becomes
`_SparkFill.sky => NestColors.light.sparkBlue`), or correct the HTML to
`var(--sky)`. Nothing to change on this branch until one lands.

## Notes for the next stages (not findings)

- **Orchestrator still owes three rulings**, all recorded and all non-blocking:
  the K07 `KidScope` exception (lilac glow, no meadow —
  `SHARED_REQUEST.md` §1, so a later iteration does not “fix” it back); the
  `evolutionSub(0)` wording (§5, finding 1); and the `#3D7FF0` token question
  (§4, finding 3). `SHARED_REQUEST.md` §2 (a screen-scoped load event, so
  `/pip-evolution` would not open K06's nest stream for three watches it does
  not render) remains accepted-as-is pending the ARCHITECTURE reading.
- **Stage 5 (UI), iteration 3** owes the D4 re-measure: the dark sparkles must
  show no light outline, with the five design hexes sampled off the device frame
  (expected now: stroke `#1E1B3A`, lilac `#7C6CF2`, success `#1F9D63`, coin
  `#F4B400`, peach `#FF8A5B`, sky dot `#2563D6`). Every other anchor carries
  over from `5_ui.md` iteration 2 unchanged — title 376.33, lock 47.00/103.00,
  CTA 736.00 (all Δ 0.00), cards 545.00 with the accepted +34.00 D1 DB-copy
  shift, bottom edge with no strip, 20 px gutters.
- **Whole-suite flake, for whoever owns the next gate**: the first full
  `flutter test` run reported 2 failures outside this feature
  (`test/widget_test.dart`, `test/features/rewards/rewards_write_failures_test.dart`);
  both pass in isolation and **neither recurred** in a second whole-suite run,
  whose only failures were inside untracked `zz_probe*_iter3_k07_test.dart`
  scratch files another stage was writing at the time. Not a K07 defect, and per
  the PROCESS rule not a process finding either — recorded here so the next stage
  does not spend time re-diagnosing it if it sees the same pair. Related: the
  `zz_probe*_iter3_*` files currently in `app/test/features/pip/` are another
  stage's scratch and must not be committed (K07's earlier stages deleted their
  `zz_probe*` files; RULES §7.1 wants `flutter analyze` → *No issues found*, and
  a scratch probe left in the tree is how that gate goes red).
- **No in-app entry point to `/pip-evolution` yet.** Navigation into this screen
  belongs to K06's growth bar or the K03 dock (DESIGN_SPEC §5 draws neither as a
  link), so it is the orchestrator's call, not a defect in this branch.

VERDICT: PASS