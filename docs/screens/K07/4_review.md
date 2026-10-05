# K07 · Pip evolves — stage 4 QA code review (iteration 4)

Reviewed: `git diff main...HEAD` for K07 at **`HEAD = 7c29857`** (13 `lib` files,
15 changed + 11 inherited test files under `test/features/pip`) against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K07
(`docs/DESIGN_SPEC.md:202`), `docs/design/SPACING_SPEC.md`,
`app/lib/core/design_system/`, `1_plan.md`, `6_bugs.md`,
`ORCHESTRATOR_NOTES.md` and every orchestrator ruling in `.brief_review.md`.

**Iteration-4 delta, re-read line by line:** `git diff 9a6eeb6..HEAD -- app/` —
5 files, +207/−34: `pip_evolution_view.dart` (both app-only `maxLines` caps
dropped — `6_bugs.md` K07-BUG-7), `pip_evolution_stats.dart` (`IntrinsicHeight` +
`CrossAxisAlignment.stretch` — K07-BUG-6), the two parked proofs un-skipped,
the one assertion that pinned the plan's `maxLines == 4` moved to `isNull`, and
+149 lines of production-shaped status-UPDATE proofs in
`pip_evolution_repository_test.dart`. Everything else in `main...HEAD` is
iteration 1–3 and was re-verified against the gates below rather than assumed.

**Nothing was edited.** `git status --porcelain app/lib` is empty; this stage's
own scratch probes (`zz_probe_iter4*_k07_test.dart`) were written, measured and
**deleted** before the end of the stage. No simulator was booted, installed on,
driven or screenshotted (only `5_ui` may, and only
`BC440E48-B3A3-43BC-971B-0EF5DB621874`). No image was attached to this reply —
the light design PNG was read with a local pixel script instead. No
`flutter clean`, no interactive `flutter run`, no `analysis_options` change, no
skipped gate, no `google_fonts`, no `DateTime.now()` in app code, no `pkill`.

## Verdict summary

| # | Severity | Finding |
|---|---|---|
| 1 | **MINOR** | The K07-BUG-6 fix aligns the three card **boxes** but leaves their **contents** misaligned: `FittedBox`'s default `Alignment.center` centres the number inside the stretched card, so at 320 px the three numbers sit 27.56 / 27.47 / 25.16 px below their card top — a **2.40 px** mutual splay, and ~12 px below the CSS position. One word: `alignment: Alignment.topCenter`. |
| 2 | **MINOR** | The `.kcap` keeps an app-only `maxLines: 3` + ellipsis the CSS does not have — the third of the three caps K07-BUG-7 removed in this very commit — and the comment justifying the change cites accessibility scales (iOS 3.16×) that `app/lib/app/app.dart:17-19` clamps away. |
| 3 | **MINOR** | `evolutionSub(0)` still renders **“Because you helped 0 times”** under “Pip grew into a Hatchling!” — iteration-2 finding 2, correctly still open pending the orchestrator's copy sign-off (`SHARED_REQUEST.md` §5). |
| 4 | **MINOR** | The spark count `4` is still transcribed as a literal in three files with no shared constant (iteration-3 finding 2). |
| 5 | **MINOR** | The sky dot's `#3D7FF0` still has no token, so the layer paints light `--sky` in both themes (iteration-3 finding 3; `SHARED_REQUEST.md` §4). |

**No blocker. No major.** The one major open from iteration 3
(`6_bugs.md` K07-BUG-6, the splayed stat cards) is **fixed and measured fixed**:
at 320 px and 280 px the three card boxes are now 102.00 / 102.00 / 102.00 px
with **0.000** height, top and bottom drift, where iteration 3 measured
2.40 / 11.67 / 14.40 px. K07-BUG-7 is fixed for the two lines it named.
**VERDICT: PASS**.

## Gates re-run by this stage (no simulator)

| Gate | Result |
|---|---|
| `dart format --set-exit-if-changed lib` | **clean** — 642 files, 0 changed *on the committed tree*. (The one file it reformatted is another stage's untracked scratch probe — see *Tree state*.) |
| `flutter analyze lib` | **No issues found!** (3.8 s) |
| `flutter analyze $(git ls-files test/features/pip)` | **No issues found!** (4.6 s, 26 items) — the committed test tree is clean, including iteration 4's new `pip_evolution_repository_test.dart` |
| `flutter test --timeout 120s test/features/pip` | **434 tests, all passed**, `00:11`, 0 skips (every `skip:` hit in `rg` is inside a comment) |
| `flutter test --timeout 120s` (whole app) | **run 1:** 4503 passed, ~10 skipped, 2 failed — this stage's own scratch probe mid-edit (since deleted) and `test/features/family/child_profile_states_test.dart` “P15 loading state streams that never emit keep the spinner up”, which **passes 12/12 in isolation**. **run 2:** 4502 passed, ~10 skipped, 4 failed — **neither run-1 failure appears**, and all four are in `test/features/kid_shop/reward_shop_widget_geometry_test.dart` (K08), which **passes 24/24 in isolation**. Two runs, zero failures in `features/pip`, zero reproducible outside their own feature: whole-suite concurrency flakes, not K07 defects (see *Notes*). |

RULES §7.1 is satisfied for everything this branch owns.

## RULES §1 scope — clean

```
$ git diff --stat main...HEAD -- app/analysis_options.yaml app/lib/core app/lib/app tools design app/pubspec.yaml
(empty)
$ git diff --name-only main...HEAD -- app/ | sed 's#/[^/]*$##' | sort -u
app/lib/features/pip/data          app/lib/features/pip/domain
app/lib/features/pip/domain/entities                        app/lib/features/pip/presentation/bloc
app/lib/features/pip/presentation/views                     app/lib/features/pip/presentation/widgets
app/test/features/pip
```

No `core/`, no `app/`, no `tools/`, no design source, no `analysis_options.yaml`,
no other feature. `docs/screens/K07/**` is the only other path touched.

## `ORCHESTRATOR_NOTES.md` — every item mandatory, all still satisfied

| Item | Ruling | Verified |
|---|---|---|
| **D4** (23:55) dark sparks | stroke AND every fill from `NestColors.light` in both themes; `shouldRepaint` theme-independent; a test under dark theme asserting stroke `0xFF1E1B3A` | **Intact** — iteration 4 did not touch `pip_evolution_sparks.dart`. `_Spark.color` (`pip_evolution_sparks.dart:91-97`) takes no parameter and reads `NestColors.light.*`; the stroke reads `NestColors.light.ink` (`:167`); `shouldRepaint` is `false` (`:194-199`); the whole layer is `const` (`:142-156`). Proofs `k07_bugs_test.dart:953-1013` and `pip_evolution_sparks_test.dart:274-309` are green. Only exception: finding 5. |
| **D2** (19:10) sparkle shape | the exact HTML 4-point path at the 4 spots, ink 3 px stroke | **Intact** — all four `d` strings and all four `(cx, cy, r)` triples are byte-identical to `K07-evolution.html:37-44`; every vertex (including the `M` tip) goes through one `addPolygon` (`:216-219`). |
| **D3** (19:10) bubble tail | accept the CSS 18×9; the shared `NestSpeechBubble` follows it | **Intact** — the view mounts the shared bubble (`pip_evolution_view.dart:365-370`); no local re-implementation anywhere in the feature. |
| **D1** (19:10) Fledgling copy | accept the +34 px stack shift (DB truth) | **Re-derived, and correct.** Measured off the design PNG with a local pixel scan: the hero's ink occupies **one** 34 px line at y 377.00–401.67, the sub 427.33–440.00, the stat cards' borders 545.00–629.00, the `.kid-bar` top border 721.00, the CTA 736.00–800.00. The app's hero is two lines at 371.00–439.00, so everything below it sits +34 (sub 455, speech 497, cards 579.00–663.00, caption 679). The cause is exactly D1: Maya's DB copy is `Pip grew into a Fledgling!`, one character longer than the design's `Pip grew into a Songbird!`, which tips `.kid-title` (Nunito 900 28/34, identical in `NestType.kidTitle` and `tokens.css --fs-kid-title`) from one line to two. Nothing in the app causes it, and no CSS `font-size`/weight/width change would fix it without breaking the type scale. |

## Architecture, design system, accessibility, performance, error handling, Children's Code

Re-verified on the iteration-4 tree; all sound.

- **Architecture** — feature-first intact. `domain/` holds entities + the abstract
  repository only (`pip_evolution.dart`, one new Equatable value object; no
  use-case class, no new folder, no presentation import in `domain/` — the stage
  names stay in `presentation/widgets/pip_look.dart`, as ARCHITECTURE's domain
  rule requires). One bloc per **feature** (ARCHITECTURE `:85`; the brief's
  “BLoC per screen” is the looser reading and the shared bloc is what lets K06
  and K07 have independent per-stream statuses), provided per route by a GetIt
  **factory** (`pip_di.dart:17`, `pip_routes.dart:30-40`, neither touched by K07),
  so the two screens can never share one instance. `watchEvolution()` maps Drift
  rows in `data/pip_repository_impl.dart:79-111` and reads **no clock** — correct:
  this is a lifetime milestone, so the PERIODS ruling does not apply, and the
  new repository tests prove both production writers (K05's `to_do → done_pending`
  flip and P11's `approved` / `not_yet` flips) without double credit.
- **Design-system usage** — `rg` over `lib/features/pip` finds **zero** hex
  literals, **zero** `Color(…)`, **zero** `letterSpacing`, no
  `google_fonts`/`GoogleFonts`, no `DateTime.now()`, no `print`/`debugPrint`, no
  `£`, no network/analytics symbol, no `name[0]`, no `Timer`/`AnimationController`.
  Re-checked every spacing constant against `tokens/spacing.dart` after the
  iteration-4 diff: nothing in it moved. Components reused, never re-implemented:
  `NestStatusBar`, `NestHomeIndicator`, `NestLockButton` (its own
  `Semantics(button:, label:, onTap:)`, `large: true` → 56 px), `NestKidButton`,
  `NestSpeechBubble`, `NestBalancedText`, `NestIcon.arrowRight`,
  `NestKidStarsPainter`, `NestType.*`, `NestRadii.allM`, `NestSpacing.*`,
  `context.nest*`. `_EvolutionBar` is a local box on purpose: `NestBottomCta`
  paints its top border with `tokens.line` (1 px) and pads `s4`, which cannot
  express `.kid-bar`'s 3 px **ink** border, its `12 20 10` padding or its
  `NestHomeIndicator` child — the same local-bar precedent as K03's dock.
- **DESIGN_SPEC §5 K07** — every element of the spec line is present (lilac radial
  glow, stage N−1 silhouette left + arrow + grown Pip right, hero, sub, bubble,
  three stat cards, caption, CTA) and the copy is byte-exact: all nine design
  strings were matched against `K07-evolution.html` with a Python byte compare
  (`Pip grew into a Songbird!`, `Because you helped 25 times`,
  `Hear that? That is Pip's new song!`, `quests done`, `coins grown`,
  `of 4 stages`, `Pip still loves a chin scratch.`, `Meet Songbird Pip`,
  `aria-label="Grown-ups"`) — all present in the HTML **and** in the Dart, with
  the design's literal ASCII apostrophe. Non-design copy is the app-wide kid-card
  set (ASCII apostrophes, matching K01/K02/K03/K06). No `-ize/-or` spelling; kid
  screens show coins, never `£`.
- **BALANCED HEADINGS** — `.kid-title` carries `text-wrap: balance`, so the hero
  is `NestBalancedText` with the same copy, style and `textAlign: center`
  (`pip_evolution_view.dart:348-352`); `.kid-body`, the bubble and `.kcap` are not.
- **PIP rule** — both slots render the **child's own** Pip from
  `pip_style`/`pip_skin`/`pip_accessory` at the DB stage
  (`pip_evolution_stage.dart:97-103`); no `pip-stage-*.svg` anywhere in `lib/`;
  the design's SLOT geometry (68 px silhouette at 0.24 opacity + grayscale, 30 px
  lilac arrow, 240 px grown Pip at `right: 6`) is preserved, measured at
  `k07-old-pip 22..90 × 283..351`, `k07-arrow 96..126 × 301..331`,
  `k07-new-pip 124..364 × 115..355`; the no-child card uses
  `PipAvatar(mochi, sunny)` per the no-child rule.
- **BOTTOM EDGE / ALIGNMENT** — `_EvolutionBar` puts the surface `Container`
  **outside** `SafeArea(top: false)` (`pip_evolution_view.dart:411-454`), so the
  surface reaches the physical edge and the 34 px inset sits inside it: no glow
  strip under the bar and no tint around the home indicator in either theme.
  One 20 px gutter everywhere: stage `20..370`, title `20..370`, stats
  `20..370` with cells at 20/140/260 and 10 px gaps, CTA `20..370`, bar `0..390`.
  Reading the **shapes**, not just the text, as the UI rule requires: cards
  `110 × 84` at 390, exactly the design's; CTA `350 × 70` including its 6 px
  `--sh-kid` shadow room; lock `56 × 56` at `314..370 × 47..103`.
- **Accessibility** — every interactive node is a shared control that carries its
  own `onTap` (`NestLockButton` with the design's `Grown-ups` label, `NestKidButton`
  for CTA / retry / choose). The two `excludeSemantics` nodes are **not**
  interactive, so RULES §8 owes them no action: the merged stat sentence
  (`pip_evolution_stats.dart:70-77`) and the decorative silhouette, arrow and
  sparks (`alt=""` / `aria-hidden` in the CSS, `ExcludeSemantics` +
  `IgnorePointer`). The grown Pip is announced as an image
  (“Maya's Pip, a fledgling”), the old one is excluded. Tap targets: lock 56,
  CTA ≥ 64. `pip_evolution_a11y_test.dart` sweeps the **whole** Scaffold
  subtree for button-flagged tap nodes (exhaustive, not a hand-picked list),
  asserts `hasAction(SemanticsAction.tap)` and drives real state/DB changes
  through `performAction`.
- **Performance** — no `Timer`, no `AnimationController` (RULES §6), no reload
  events, no per-frame state; both background layers, the sparks box and the lock
  row are `const`; the parsed sparkle `Path`s are cached per `d`; both painters
  key `shouldRepaint` on exactly what they read (`_SparksPainter` returns
  `false`). `IntrinsicHeight` (finding 1's fix) does add one intrinsic-measure
  pass over three small cells, but only on layout — not on scroll or repaint —
  and the subtree is three `Text`s, so it is not a rebuild storm; the
  alternative the bug stage rejected (a pinned card height) would have broken
  scaling. `close()` awaits both cancels and nulls the fields; `_switchMap`
  cancels its inner subscription per outer emission; a stream error releases only
  its own subscription, so “Try again” genuinely re-subscribes (pinned for both
  Dart failure-delivery shapes, and for a *second* failure).
- **Error handling** — no raw exception can reach a kid screen: the failure card
  renders its own kind copy (“Oh no! Pip got lost.” / “Let's try again.” /
  “Who's playing?”), `errorMessage` is documented diagnostic-only and read by no
  view in the feature, and a stream that answered and then failed keeps its data
  on screen (`_streamStatus` prefers `settled`), so a mid-session error never
  blanks a celebration.
- **Children's Code** — kid mode only: no analytics, no ads, no network, no
  third-party SDK, no identifiers, no `£`, no red, no timers or countdowns, no
  loss framing, nothing logged or transmitted. The child's only exposure is their
  own nickname inside a VoiceOver label, on device.

## Findings

### 1. MINOR — the stat cards align, but their **numbers** still do not (2.40 px at 320 px)

`app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart:88-91`
(the fix) and `:164-166` (`FittedBox(fit: BoxFit.scaleDown)`, no `alignment`).

The iteration-4 fix is right and works: `IntrinsicHeight` +
`CrossAxisAlignment.stretch` is CSS `align-items: stretch`, and the three card
BOXES now measure

| width | card heights | box height/top/bottom drift |
|---|---|---|
| 390 | 84.00 / 84.00 / 84.00 | **0.000** |
| 375 | 84.00 / 84.00 / 84.00 | **0.000** |
| 320 | 102.00 / 102.00 / 102.00 | **0.000** |
| 280 | 102.00 / 102.00 / 102.00 | **0.000** |

(iteration 3 measured 2.40 / 5.24 / 11.67 / 14.40 px of splay.) But the fix
stretches the *box* only. Inside it, `FittedBox` defaults to
`Alignment.center`, so the (differently scaled) number+label pair is **centred**
in the stretched box, whereas the design's `.k7-stats > div` is a block box with
`padding: 12px 6px` — its content starts at the **top**, 15 px down (3 px border
+ 12 px padding). Measured on the real screen with the bundled Nunito and the
shipped demo seed:

| width | number inset from its card's top (design: 15.00 at every width) | drift |
|---|---|---|
| 390 | 15.00 / 15.00 / 15.00 | **0.000** ✓ |
| 320 | 27.56 / 27.47 / **25.16** | **2.401** ✗ |
| 280 | 32.11 / 32.04 / **30.18** | **1.935** ✗ |

So on a 320 px phone the screen's three focal numbers are 2.40 px apart from one
another — over the ±2 px UI VERDICT tolerance and exactly the “cards and bars
aligned to the same edges, nothing a few px off” the owner ALIGNMENT rule names —
and 10–17 px lower inside their cards than the CSS puts them. The 390 px design
rendering is pixel-exact (15.00 × 3), which is why `5_ui` cannot see it.

**Impact.** Visible misalignment of the celebration screen's three headline
numbers on a supported width (`docs/design/SPACING_SPEC.md:369` plans 320
layouts), introduced by — and surviving — the iteration-4 fix. No data, state,
a11y or copy impact.

**Fix** (one argument, `pip_evolution_stats.dart:164-166`):

```dart
child: FittedBox(
  fit: BoxFit.scaleDown,
  // CSS puts the card's content at the TOP of the stretched box
  // (`padding: 12px 6px`), so 15 px below the card edge at every width;
  // FittedBox's default Alignment.center drifts up to 2.40 px between the
  // three numbers on a 320 px phone.
  alignment: Alignment.topCenter,
  child: Column( … ),
),
```

Verified in a scratch replica of `_StatCell` (real Nunito, three unequal label
widths, `IntrinsicHeight` + `stretch`): the number's inset is `15.00` with
`topCenter` against `56.17` with the default — i.e. `topCenter` reproduces the
CSS position exactly. A permanent test belongs next to the K07-BUG-6 proof in
`k07_bugs_test.dart` (it must assert the number tops, not just the card tops,
since the boxes now agree at every width).

### 2. MINOR — the third app-only line cap survives on `.kcap`, and the justification comment cites scales the app never renders

`app/lib/features/pip/presentation/views/pip_evolution_view.dart:380-387`
(`maxLines: 3`, `overflow: TextOverflow.ellipsis`) and the comment at
`:338-355`.

K07-BUG-7 correctly established that `.k7-hero` and `.k7-sub` carry **no** clamp
in `K07-evolution.html:24-25`, and iteration 4 dropped both app-only caps. The
caption is the same class of app-only clamp and was left in place: `.kcap`
(`K07-evolution.html:14`, used at `:63`) sets only a font/weight/size/line-height/
colour, so the browser grows the line and `.scroll` scrolls — but the app still
caps it at 3 lines and ellipsizes.

The whole premise is also unreachable in this app, which makes the surviving cap
pure noise rather than a live defect: `app/lib/app/app.dart:17-19` clamps the
ambient text scaler to **1.0–1.3** (`_clampTextScaler`, SPACING_SPEC §10), so no
screen ever renders above 1.3×. Measured live through `pumpAppRoute`: asking for
`textScaleFactorTestValue = 3.16` produces the same caption height as 1.3×
(`20.0 → 26.0`, then flat), i.e. the clamp really is applied. At 1.3× the caption
needs 1 line at 390/320 and 2 at 280 — never 3. So neither the caps just removed
nor the one kept could ever truncate anything; the only real issue is the
divergence from the CSS.

**Fix.** `pip_evolution_view.dart:380-387`: drop `maxLines: 3` and
`overflow: TextOverflow.ellipsis` so all three lines match the CSS (and move the
`k07-caption` assertion into the K07-BUG-7 proof so the fourth cap cannot be
added back silently). Then correct `:338-347`, which justifies the dropped caps
with “iOS reaches 3.16×” — a scale `app.dart` clamps away — and `6_bugs.md`
K07-BUG-7’s reachability table with it, so the next stage does not “restore” a
cap or file a shared request for a scale the app cannot produce. The honest
statement of the fix is: *the design clamps neither line, so neither line is
clamped*.

### 3. MINOR — `evolutionSub(0)` renders “Because you helped 0 times”

`app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart:48-50`
(unchanged from iteration 2's finding 2 and iteration 3's finding 1).

```dart
String evolutionSub(int questsDone) => questsDone == 1
    ? 'Because you helped 1 time'
    : 'Because you helped $questsDone times';
```

The singular branch exists, the zero branch does not. `questsDone` is the
lifetime `done_pending + approved` count and nothing ties `pip_stage > 1` to
having completions (stage is a seeded column), so `0` is a real DB state: a
family whose Pip has grown through birthday money opens `/pip-evolution` and
reads “Pip grew into a Hatchling!” above **“Because you helped 0 times”** — a
self-contradiction on a celebration screen, the tone class the Children's Code
and `no nagging` rules exist to prevent.

MINOR, not major, for the same structural reason as the last two iterations:
`rg 'PipRoutePaths.evolution' app/lib` still returns only `pip_routes.dart:31`,
so the screen is reachable via `INITIAL_ROUTE` or a deep link, not by tapping.
It is also blocked on copy the screen may not invent (no design source has a zero
case), so it needs the orchestrator's wording before it lands
(`SHARED_REQUEST.md` §5). Today's behaviour is pinned as *under review* by
`k07_bugs_test.dart`, so it cannot be forgotten silently.

**Fix** (once the wording is signed off), in the same copy table:

```dart
String evolutionSub(int questsDone) => switch (questsDone) {
  0 => '<signed-off zero line>',            // e.g. 'Pip is ready for its first adventure'
  1 => 'Because you helped 1 time',
  _ => 'Because you helped $questsDone times',
};
```

then move the assertion in `k07_bugs_test.dart` with it and add
`evolutionSub(0)` / `(1)` / `(4)` to `pip_evolution_copy_test.dart:252-255`.

### 4. MINOR — the spark count `4` is transcribed as a literal in three files

`pip_evolution_view.dart:67` (`_kStatsStageCount = 4`),
`pip_evolution_stage.dart:92` (`profile.stage.clamp(1, 4)`) and
`pip_evolution_copy.dart:74` (`'of 4 stages'`) + `:107`
(`'stage $stage of 4'`). The design's `of 4 stages` is a literal, so
transcribing it is correct today; the risk is that the number lives in three
files with no shared source, so a fifth stage would leave the card claiming
“of 4 stages” while a clamp silently drops the new stage.

**Fix** (feature-local, no shared file): declare `const int pipStageCount = 4;`
beside `pipStageName` in `presentation/widgets/pip_look.dart:18` and use it in
both clamps and both copy strings, deleting the private view constant.

### 5. MINOR — the sky dot's `#3D7FF0` cannot be painted literally without breaking the tokens-only rule

`pip_evolution_sparks.dart:91-97` and `:124-125` (header rationale at `:17-29`;
pinned by `pip_evolution_sparks_test.dart:245-273`; filed as
`SHARED_REQUEST.md` §4). The 23:55 note asks to “verify each fill hex equals the
HTML's literal”. Five of the six entries do, because `NestColors.light` holds
exactly those values. The sixth — the `cx=268 cy=8 r=6` dot, `fill="#3D7FF0"` —
has **no token in either scheme** (`--sky` is `#2563D6` light / `#7FA9FF` dark),
and the MUST-level tokens rule forbids hard-coding it, so the layer paints the
light `--sky` in both themes: a 6 px dot, 24/28/26 per channel off the design.
`const Color(0xFF3D7FF0)` would violate “never hard-code colours”, which is the
stricter instruction, so the current choice is the defensible one; it is
documented in the file header, asserted in both directions by a test (the literal
is **never** painted, every *other* design hex always is), and filed for the
orchestrator.

**Fix:** one of the two rulings already requested in `SHARED_REQUEST.md` §4 — add
`sparkBlue: #3D7FF0` to `app/lib/core/design_system/tokens/colors.dart` (shared,
so the orchestrator's to apply; then the entry becomes
`_SparkFill.sky => NestColors.light.sparkBlue`), or correct the HTML to
`var(--sky)`. Nothing to change on this branch until one lands.

## Notes for the next stages (not findings)

- **Orchestrator still owes three rulings**, all recorded and all non-blocking:
  the K07 `KidScope` exception (lilac glow, no meadow — `SHARED_REQUEST.md` §1,
  so a later iteration does not “fix” it back; the exception is right:
  `K07-evolution.html:16` overrides `.screen.kid` and the body has no `.meadow`
  element); the `evolutionSub(0)` wording (§5, finding 3); and the `#3D7FF0`
  token question (§4, finding 5). `SHARED_REQUEST.md` §2 (a screen-scoped load
  event, so `/pip-evolution` would not open K06's nest stream for three watches
  it does not render) remains accepted-as-is.
- **`1_plan.md` was not re-ratified.** `6_bugs.md` K07-BUG-7 asked for the plan's
  `maxLines: 4` / `maxLines: 2` to be re-ratified “rather than a silent change”;
  the deviation is documented in `2b_build_ui.md:87-101` (so it is not silent),
  but `1_plan.md:139,150` still specifies the dropped caps and `:207` still
  specifies the caption's. Updating the plan is one edit in an allowed path and
  would stop a future stage reading the caps as the contract.
- **`IntrinsicHeight` cost, deliberately accepted.** It adds one
  intrinsic-measure pass over three `Text`s on layout only (not on scroll or
  repaint), so it is not a rebuild storm; the alternative the bug stage rejected
  (a pinned card height) would have frozen the cards at large text scales.
- **Tree state when this stage measured.** `HEAD = 7c29857`. Another stage was
  writing in the same worktree: `app/test/features/pip/pip_evolution_stats_scales_test.dart`
  and `zz_probe2_iter4_k07_test.dart` are untracked (the second is another
  stage's scratch probe) and `ui/{app,cmp}_{light,dark}_4.png` are untracked stage-5
  screenshots. Per the PROCESS rule that is the loop's and the orchestrator's, not
  a finding — but the scratch probe must not be committed: it is the only reason
  `dart format --set-exit-if-changed lib test` and `flutter analyze` report
  anything at all (5 infos, all in `zz_probe2_iter4_k07_test.dart`); the committed
  tree (`flutter analyze lib`, and the 26 committed test files) is
  **No issues found**.
- **Whole-suite flakes, for whoever owns the next gate.** Two runs of
  `flutter test --timeout 120s`, 4502–4503 passed and ~10 skipped each:
  **run 1** failed `test/features/family/child_profile_states_test.dart` (“P15
  loading state streams that never emit keep the spinner up”) plus this stage's
  own scratch probe; **run 2** failed neither and instead failed four tests in
  `test/features/kid_shop/reward_shop_widget_geometry_test.dart` (K08). Both
  files **pass in isolation** (12/12 and 24/24), neither imports anything from
  `pip`, and the failure set does not repeat. Not a K07 defect, and per the
  PROCESS rule not a process finding either — recorded so the next stage does
  not spend time re-diagnosing a moving failure set.
- **No in-app entry point to `/pip-evolution` yet.** Navigation into this screen
  belongs to K06's growth bar or the K03 dock (DESIGN_SPEC §5 draws neither as a
  link), so it is the orchestrator's call, not a defect in this branch.
- **Stage 5 (UI), iteration 4** should re-measure after finding 1 is fixed (the
  numbers move ~12 px up inside the cards below ~330 px widths; the 390 px design
  rendering does not move) and re-confirm D4: the dark sparkles must show no
  light outline, with the five design hexes sampled off the device frame
  (expected now: stroke `#1E1B3A`, lilac `#7C6CF2`, success `#1F9D63`, coin
  `#F4B400`, peach `#FF8A5B`, sky dot `#2563D6`). Every other anchor carries
  over from `5_ui.md` iteration 2 unchanged — title 376.33, lock 47.00/103.00,
  CTA 736.00 (all Δ 0.00), cards 545.00 in the design against the app's 579.00
  with the accepted +34.00 D1 DB-copy shift, bottom edge with no strip, 20 px
  gutters.

VERDICT: PASS