# K05 Quest complete — 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` on branch `screen/K05` — 4 lib files, 7 test
files, this screen's notes. No code edited by this stage. No simulator
booted, installed on, screenshotted or driven (stage 5 owns the one allowed
UDID).

## Files reviewed

| File | Δ |
|---|---|
| `app/lib/features/kid_home/presentation/views/quest_complete_view.dart` | celebration view (+710 / placeholder replaced) |
| `app/lib/features/kid_home/domain/entities/kid_growth.dart` | new, 30 (pure growth maths) |
| `app/lib/features/kid_home/domain/entities/kid_child.dart` | +8 (`pipTotalCoins`) |
| `app/lib/features/kid_home/data/kid_home_repository_impl.dart` | +1 (map `pipTotalCoins`) |
| `app/test/features/kid_home/quest_complete_view_test.dart` | new (~879) |
| `app/test/features/kid_home/quest_complete_geometry_test.dart` | new (~296) |
| `app/test/features/kid_home/k05_bugs_test.dart` | new (~593, probes + fixed proofs) |
| `k03_bugs_test.dart`, `kid_home_view_test.dart`, `kid_home_bloc_test.dart`, `kid_home_repository_test.dart` | CTA adaptation + `pipTotalCoins` coverage |

## Evidence gathered

- `dart format --output=none --set-exit-if-changed app/lib/features/kid_home app/test/features/kid_home` → 49 files, **0 changed**.
- `flutter analyze app/lib/features/kid_home app/test/features/kid_home` → **No issues found!**
- `flutter test --timeout 120s test/features/kid_home` → **All tests passed (+613, ~3 skipped)** — the whole feature, not just the K05 files.
- Edit set is clean against RULES §1: every touched path is
  `app/lib/features/kid_home/{data,domain,presentation}/**`,
  `app/test/features/kid_home/**` or `docs/screens/K05/**`.
  The full `--name-only` list contains no `app/lib/core/**`, `app/lib/app/**`,
  `tools/**` or `analysis_options` entry. No `SHARED_REQUEST.md` filed —
  none needed (route and all components already exist).
- Iteration-1 re-check: findings 3, 4, 6, 7, 8, 9 from `4_review.md`
  (iteration 1) are fixed in this tree — single `hide PipMood` comment,
  separate `_kPipMarginTop`, token-resolved geometry finders, bar height
  asserted as `89` with the collapse reason, card label without the second
  percentage, `buildWhen` on the `BlocBuilder`. K05-BUG-1…4 are fixed
  (singular `+1 coin`, floored percent, stacking count row, hero
  `maxLines: 3`) and their proofs are green in the suite above.

## What passed (checked, no finding)

- **Orchestrator rules.** PIP: two `PipAvatar`s from the active child's own
  row (`pipStyleOf/pipSkinOf/pipAccessoryOf`, `stage.clamp(1,4)`,
  `mood: happy`) — no `pip_stage_*.svg`. STATUS BAR: `NestStatusBar` only.
  DATA: hero/coins/headline/count/fraction/`Next:` all derive from the DB
  (`pipTotalCoins`, `evolveAtCoins` from `PipProfile`, extra → quest row →
  first-done → 0); no design number hard-coded. BOTTOM EDGE: bar `surface`
  `Container` with top-only 3 px ink border spans x 0…390 to y 844,
  `SafeArea(top: false)` inside the surface box. ALIGNMENT: card/CTA share
  x 20…370, pill/bubble share the 195 axis (pinned by geometry tests).
  BALANCED HEADINGS: `NestBalancedText` on `.kid-hero` only. LETTER SPACING:
  none added. FONTS: no `google_fonts`/`GoogleFonts` (source-asserted).
  CLOCK: no `DateTime.now()` (only `appNowUtc()` in pre-existing repo code;
  K05 needs no clock). IDS: none minted. AVATAR INITIALS: none on screen.
  KID BACKGROUND: `KidScope` only, no local hills. No chips (no
  `NestChipWrap` owed), no quest/reward icons on this screen, no trial read.
  ACCESSIBILITY ACTIONS: both `excludeSemantics` wrappers are
  non-interactive (Pip image, card static text) so no `onTap:` is owed;
  every control asserts `hasAction(tap)` + `performAction` drives real
  navigation. CHILD ORDER: Maya-then-Leo in repo/order-sensitive tests.
- **Geometry (static).** Seed-value rects unchanged by the iteration-2
  fixes (singular/stack/floor/maxLines paths only trigger off-seed):
  lock 56×56 @ 314,47; Pip slot 218 centred; hero 44 @ y 343; pill
  147.67×40 @ y 403; sub 26 @ y 459; bubble 44 @ y 501; card 350×134 @
  y 561; progress 312×16 @ y 662; painted CTA 350×64, 15 below bar top.
  ±2 px pinning lives in `quest_complete_geometry_test.dart` (bundled
  fonts loaded). Simulator confirmation belongs to stage 5.
- **Copy.** Byte-compared against `design/html-source/screens/K05-quest-complete.html`:
  `Brilliant, Maya!`, `+15 coins`, `Mum will give it a thumbs-up soon.`
  (U+002D), `Pip is doing a happy dance!`, `Pip needs 75 more coins to grow`,
  `175 of 250 coins`, `Next: Songbird`, `Yay! Back home`, progress
  `Pip is 70% of the way to Songbird` — all exact; the `+1 coin` singular
  only fires for 1-coin quests (correct English, off-design-path).
- **Architecture.** Feature-first; no new bloc/event/state (one bloc per
  feature holds); `pipTotalCoins` is feature-private, mapped in `_toChild`,
  in `props`, and covered by bloc/repo tests; DI and routes untouched.
- **Accessibility.** CTA → `/kid-home` via `go`; lock → gate via `push`
  with `_busy` single-push guard (`finally` + `mounted`); targets CTA 64,
  lock 56×56; card collapses to one label node with `NestProgress`
  outside it carrying the design's `aria-label`; 320 px + 1.3× and dark
  bottom-edge probes green; 18/18 token contrast pairs ≥ 4.5:1.
- **Performance.** No `Timer`/`AnimationController`; no new subscription
  (bloc-owned); `buildWhen` scopes rebuilds to status/child/items;
  `Transform.rotate`/burst SVG are paint-only; `SvgPicture` has an empty
  placeholder so no grey flash.
- **Error handling.** loading → labelled spinner under the shared top row;
  failure → Pip-lost card, Try again re-adds `KidHomeLoadRequested`,
  own Pip when known; null child → picker; deep link celebrates, never
  blanks; `total >= 250` → ready-to-grow copy, fraction 1.0.
- **Children's Code.** No analytics/ads/network/prints of child data;
  coins only (no £); no red/danger token; kind copy, no timers or shame.

## Findings

No blockers. No majors. Seven minors — none affects the rendered seed
screen, the data path or the accessibility contract.

### 1. minor — deep-link coin fallback can quote the wrong quest (carried)
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:109-127`
`_coinsFor` step 3 falls back to the first done quest in list
(alphabetical-by-title) order. Period-correct and DB-driven, but a guess
about which quest was just finished. No in-app path hits it (K03/K04 always
pass `extra`); only direct launches do.
Fix: surface `Future<KidQuest?> lastCompletedQuest(childId)` from the
repository and prefer it; or gate the fallback behind a debug flag.

### 2. minor — `kid_growth.dart` sits in `domain/entities/` and is the only cross-feature domain import (carried)
`app/lib/features/kid_home/domain/entities/kid_growth.dart:1,13-18`
ARCHITECTURE allows `domain/` "entities + abstract repository ONLY"; the
file holds free functions, and it makes `kid_home`'s domain depend on
`pip`'s domain (a first in the codebase). It also re-implements
`PipProfile.coinsToGrow`. Precedent for pure domain maths is
`pocket_money/domain/next_payout.dart` (domain root, `core/`-only imports).
Fix: move to `app/lib/features/kid_home/domain/kid_growth.dart`. Zero
cross-feature imports would need `evolveAtCoins` in `core/` — a
SHARED_REQUEST touching `core/**`, outside this screen's edit set, so not
a K05 fix.

### 3. minor — loading/failure/no-child/lock copied into a fourth view (carried)
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:168-330,676-700`
Fourth copy of the three kid state screens and sixth `_GateLockButton`
(K03/K04/K02 pattern followed correctly — not a K05 defect, but six
landing sites for every future fix).
Fix: orchestrator batch extracting shared widgets after all `kid_home`
screens merge — not inside this loop.

### 4. minor — test adaptation exceeds the ORCHESTRATOR_NOTES scope by two spots
`app/test/features/kid_home/k03_bugs_test.dart:208-219` (helper, used at two
call sites), `app/test/features/kid_home/kid_home_view_test.dart:1668`
The note permits updating "that one test (and only that one)"; the same
`pageBack`-vs-no-back-button breakage needed the identical CTA-leave fix
in a second K03 test and in the view test. Each change is minimal,
correct, and keeps placeholder compatibility (falls back to `pageBack`).
Fix: none in code — orchestrator to confirm the two extra spots
retroactively.

### 5. minor — `TextPainter` built per layout without `dispose`
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:586-594`
The K05-BUG-3 one-line/stacked decision lays out two labels on every card
build and never calls `painter.dispose()`. Cost is trivial and rebuilds
are `buildWhen`-scoped, so this is hygiene only.
Fix: hoist the measurement into a small helper that disposes in a
`finally`, or cache the decision per (constraints, scaler).

### 6. minor — hand-rolled pi literal
`app/lib/features/kid_home/presentation/views/quest_complete_view.dart:65`
`-8 * 3.141592653589793 / 180` instead of `dart:math` `pi`.
Fix: `import 'dart:math'; const double _kPipTilt = -8 * pi / 180;`

### 7. minor — `pipTotalCoins` defaults to 0 instead of the plan's `required`
`app/lib/features/kid_home/domain/entities/kid_child.dart:18,39`
Plan §b said `required`; the default keeps pre-K05 fixtures (including
sibling screens') compiling. A forgotten mapping would then compile
silently to "needs 250 more". The repo mapping itself is pinned by tests.
Fix (optional): make it `required` once every `kid_home` fixture carries
the field — coordinate with the sibling loops.

## Verdict

The screen meets the brief: feature-first layering, tokens-only styling,
design-exact geometry, DB-driven data, full accessibility actions, clean
format/analysis/tests, and no file outside RULES §1. All seven findings
are minors (three carried, four new nits) — none is a blocker or a major.

VERDICT: PASS
