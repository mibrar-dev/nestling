# K04 — Stage 2b build, UI chunk (iteration 1)

Scope: `app/lib/features/kid_home/presentation/views/**` + `presentation/widgets/**`
for K04, and the `view`/`widget`-named tests in `app/test/features/kid_home/`.
No `domain/`, `data/` or `bloc/` edits (the logic builder owns those; its
`2a_build_logic.md` reports **no CONTRACT CHANGES**, and the one planned logic
addition — `KidHomeBloc.stepsFor` — is already in place, so the view codes
against exactly the plan §b contract).

## Files changed

- `app/lib/features/kid_home/presentation/views/quest_detail_view.dart`
  (full rewrite; the placeholder `Scaffold(appBar: AppBar('K04 Quest detail'))`
  is gone)
  - `QuestDetailView` — `BlocListener` (celebration → `/quest-complete`) →
    `BlocListener` (`actionError` → `showNestToast`) → `BlocBuilder`
    (`initial|loading` → loading, `failure` → Pip lost, `loaded` + no child →
    who's playing, `loaded` + no quest → pick a quest, else the detail body).
  - `_resolveQuest` — plan §b order: route `extra` (`questId` + `childId`) →
    design quest `q-tidy` → first `to_do`/`not_yet` → first item. An `extra`
    id that no longer resolves goes to `_QuestMissing` (it never silently
    shows a different quest).
  - `_TopBar` — `.k4-top` (`0 20px 6px`): `NestIconButton` 56/back/26 px icon
    (transparent) + `Spacer` + `NestLockButton` large (`Grown-ups`).
  - `_QuestDetailBody` — the design's `.scroll`: tile, title, coin pill, hint,
    steps card, cheer row; `_ticked` (`Set<int>`) is local checklist state,
    fresh per visit; `_busy` tap guard released on the next frame (K03-BUG-11
    pattern) and on status/`actionNonce` change.
  - `_StepsCard` / `_StepRow` — surface + 3 px ink border + r24 + `kidShadow`,
    `.k4-dot` 40 px rings (leaf + on-leaf tick when ticked), 2 px `line`
    dividers, per-row `Semantics(button, toggled, label, onTap)`.
  - Bottom bar — `Container(surface, top: 3 ink)` → `SafeArea(top:false)` →
    `Padding(20,12,20,4)` → `Column(spacing:4)` → `NestKidButton('I did it!',
    leaf, check 26)` + `NestKidButton('Back', white)` → `NestHomeIndicator`.
  - `_GateLockButton` (K03-BUG-9 double-tap guard), `_KidLoading`,
    `_KidFailure`, `_NoActiveChild`, `_QuestMissing`.
- `app/test/features/kid_home/quest_detail_view_test.dart` (new, 19 cases)
- `app/test/features/kid_home/quest_detail_geometry_test.dart` (new, 3 cases)
- `app/test/features/kid_home/kid_home_view_test.dart`,
  `app/test/features/kid_home/k03_bugs_test.dart` — **placeholder anchors
  only** (see "Cross-screen test repairs"). No K03 assertion was weakened.

## Design geometry — measured, not estimated

`design/screens/light/K04-quest-detail.png` was measured pixel-exact with a
throwaway PNG decoder (colour-run bounding boxes at ÷3) before writing any
layout code. Every number below is the design; the geometry test pins all of
it, and it passes.

| element | design y (÷3) | app (test) |
|---|---|---|
| `.k4-top` row (back 56×56 @ x20, lock 56×56 @ x314) | 47…103 | ✅ |
| `.k4-tile` 120×120 @ x135…255 | 109…229 | ✅ |
| `h1.kid-title` 28/34 (`margin-top: 4`) | 233…267 | ✅ |
| `.coin-pill.big` x148…242 | 283…323 | ✅ |
| `.kcap` hint 15/20 | 339…359 | ✅ |
| `.k4-steps` 350×186 @ x20…370 | 375…561 | ✅ |
| `.k4-step` rows / dividers | 378…438 / 438 / 440…498 / 498 / 500…558 | ✅ |
| `.k4-dot` 40 @ x37…77, centre 408; text x89 | — | ✅ |
| `.k4-cheer` (margin-top 22), Pip 64 @ x37…101, bubble x113…353 | 583…647 | ✅ |
| `.kid-bar` top border | 647 | ✅ (relative, see below) |
| painted buttons 350×64, 10 apart, 15 below the bar top | 662…726 / 736…800 | ✅ |

Two layout facts worth keeping (both verified, both commented in the code):

1. **Step rows are border-box 60.** `.k4-step { min-height: 60 }` +
   `.k4-step + .k4-step { border-top: 2px }` renders the design card
   186 = 3 + 60 + 60 + 60 + 3, so a row that carries the divider lays its
   content out in 58 (`_StepRow.dividerAbove`). Without that the card is 190
   and everything below it drifts.
2. **This Flutter's `Container` already insets its child by the decoration's
   border padding**, which is exactly the CSS content box. Adding an explicit
   `EdgeInsets.all(3)` doubles it (card 192). The card therefore carries no
   padding; rows measure 344 wide (x 23…367), the ring lands at x 37 and the
   dividers bleed to the inner edge, like the PNG.
3. **`NestKidButton` reserves 6 px of shadow room per button**, so the CSS
   `.kid-bar` `gap: 10` and `padding-bottom: 10` each hand 6 px back
   (gap and bottom air = `s1` = 4). The painted buttons then land exactly on
   the design rects and the bar stays 163 tall — the same compensation K03's
   dock already documents. The test asserts the bar relative to its own top
   because the app puts the 34 px home-indicator inset *inside* the surface
   (owner bottom-edge rule) while the test surface has no inset.

## Owner rules honoured

- **Bottom edge:** the bar is an in-flow `Container(surface, top 3 px ink)`
  wrapping `SafeArea(top: false)` — the surface box runs to the physical edge,
  so no meadow/sky strip appears under it or around the home pill (test pins
  `bar.bottom == 844`).
- **PIP:** the cheer Pip is `PipAvatar(style/skin/accessory/stage)` from the
  child's own row (Maya = mochi · sunny · stage 3, `mood: happy`), 64 px in the
  design slot; no `pip_stage_*.svg`.
- **Kid background:** shared `KidScope` only — sky gradient + the shared
  136 px meadow; no local hills.
- **Alignment:** 20 px gutters everywhere; the card, bar and buttons all share
  x 20…370 (measured and pinned).
- **Balanced headings:** the title is `NestBalancedText` (`.kid-title` is a
  `text-wrap: balance` class), `maxLines: 3`, centred.
- **Semantics / accessibility:** every control exposes `SemanticsAction.tap`
  and drives real state. The step rows wrap in
  `Semantics(button, toggled, label, onTap:)` **and** pass `onTap`, because
  they also use `excludeSemantics` (the wrapper would otherwise drop the
  action) — pinned by `performAction(SemanticsAction.tap)` flipping the ring.
- **No clock:** no `DateTime.now()`, no `newId`, no `subscription_status`, no
  `google_fonts` (the view uses the bundled Nunito/Inter through `NestType`).
- **Copy:** verbatim from the HTML (all ASCII here); a test blots for
  `’ “ ” – — …` in every `Text` on the screen.
- **No new components / no hard-coded colours or sizes:** everything is
  `NestType` / `NestSpacing` / `NestRadii` / `NestIcons` / `context.nest`
  tokens, plus six screen-local design values named with their CSS class
  (`_kTileSize`, `_kDotSize`, `_kStepHeight`, `_kStepDivider`, `_kCheerGap`,
  `_kPipSlot`, `_kBarGap`) — the same shape as K03's documented constants.
  `_iconFor` is a local copy of K03's icon mapping so this screen never edits
  another screen's view file.
- **No simulator, no whole-app test run** (stage 2b rule): only
  `flutter analyze lib/features/kid_home` + `test/features/kid_home`.

## Tests

`flutter test --timeout 120s test/features/kid_home` → **484 passed, 3 skipped,
0 failed**; `flutter analyze` (whole app) → No issues found.

- `quest_detail_geometry_test.dart` loads the bundled faces with `FontLoader`
  in `setUpAll` (on `flutter_test`'s default font the title wraps to two lines
  and every rect below moves) and pins the whole table above, the card
  decoration (r24 / 3 px ink / shadow), the bar surface reaching y 844, and a
  320 px × 1.3 text overflow check.
- `quest_detail_view_test.dart` runs the design quest on the real seeded DB
  (`Seed.demo`: `q-tidy`, Maya, mochi/sunny Pip) and a feature-local fake
  repository for the states a healthy DB cannot produce (silent stream, stream
  error, failing write, no active child, unknown quest id). It covers: copy,
  the `+15` pill semantics (`Plus 15 coins`), unticked-on-arrival, tap and
  `performAction(tap)` toggling both ways, a same-frame double tap dispatching
  exactly one `KidHomeQuestCompleted(maya, q-tidy)` and then pushing
  `/quest-complete`, a failed write toasting
  `Hmm, that did not work. Try again.` and staying put, a `done_pending`
  quest disabling the primary button (`isEnabled` false, no dispatch, no
  celebration), top-back pop vs `go(home)` on a direct launch, the lock
  pushing `/parental-gate`, the `extra` selecting the quest, and the four
  non-loaded states. Every pump ends with `disposeApp(tester)`.

## Cross-screen test repairs (needed because K04's placeholder is gone)

The K03 suite anchored "did we land on the quest detail?" on the placeholder's
AppBar title `K04 Quest detail`, and one K03 probe used `tester.pageBack()`
(which needs an AppBar back button). Both are placeholder artefacts, so they
were repointed at real K04 content — no K03 behaviour assertion was weakened:

- `kid_home_view_test.dart` (4 sites) + `k03_bugs_test.dart` (2 sites):
  `find.text('K04 Quest detail')` → the K04-only hint line
  `find.text('Tick each bit off, then press the big button.')`
  (new `_k04DetailAnchor()` helper in `kid_home_view_test.dart`).
- `k03_bugs_test.dart` K03-BUG-6: `tester.pageBack()` →
  `tester.tap(find.byType(NestIconButton))` (K04's own Back) plus an extra
  `findsNothing` on the detail copy, which actually proves the "no stacked
  second route" intent — a stacked route would render the hint twice.

## LEFT FOR NEXT ITERATION

- **UI check (stage 5) still owed:** `shot.sh` for `/quest-detail` in light +
  dark and `compare.py` against both design PNGs. The geometry test predicts
  an exact match at 390×844 in light (every rect in the table is within 0.01
  px); dark uses the same tokens and layout, and needs the device capture to
  confirm, plus the meadow/sky colours behind the bar.
- **Semantics nuance to eyeball in the UI check:** the cheer Pip's image node
  and the speech bubble's text node are adjacent label-only siblings, so the
  semantics compiler merges them into one node reading
  "Pip cheering you on\nPip is doing a happy dance!". Both strings are the
  design's verbatim copy and the announcement is correct; the copy-parity test
  matches the Pip `alt` on the `Semantics` widget's own property for that
  reason. If a reviewer wants two separate nodes, that needs a
  `MergeSemantics`-free boundary (a shared-component change, not a screen one).
- Nothing else: no `SHARED_REQUEST.md` needed (every component the screen uses
  already exists on main, the route is registered, and the design's 3 px card
  border, 186 px card and 163 px bar are all expressed with existing tokens
  plus named screen constants).

## Iteration 2 — FIXES_1 remediation (2026-10-04)

All three bugs from `6_bugs.md` / `FIXES_1.md` are fixed and the skipped bug
tests are now un-skipped and passing:

- **K04-BUG-1 (Major)** — `NestBalancedText` collapsed to a ~0 px-wide
  invisible heading when a DB-driven title needed more lines than its
  `maxLines` cap. Fixed in
  `app/lib/core/design_system/components/nest_balanced_text.dart`:
  - `balancedWidthFor` now probes with the natural line count
    (`maxLines: null`) instead of the capped probe, which had reported
    "3 lines" at every width and collapsed the binary search to ~0 px.
  - `build` first computes the natural line count with `maxLines: null`;
    when it exceeds the requested `maxLines`, it renders the full-width
    `Text` (clipped/ellipsised by the Text itself) instead of a narrowed
    invisible box.
  - Verified: the unit probe (`balancedWidthFor` > 50) and the widget probe
    (measured title width > 100 px for the 59-char playroom title) both pass.
  - NOTE: this is a shared-component fix — flagged in
    `docs/screens/K04/SHARED_REQUEST.md` for the orchestrator to upstream,
    since stage rules assign `app/lib/core/**` to shared ownership.
- **K04-BUG-2 (Minor)** — `_resolveQuest` no longer falls through to the
  `q-tidy` fallback when the route `extra` names another child or an
  unknown quest. An explicit `questId` that does not resolve for the active
  child now returns `null` → the "Pick a quest" empty state. The design-
  quest fallback now only fires for true direct launches (no `questId`).
- **K04-BUG-3 (Major, mandated)** — `_iconFor` replaced with the P09 batch-5
  mapping: `bed|sofa → questBed`, `dishwasher|plate → questDishes`,
  `hoover → questHoover`, `book → book`, `bin|bins|shirt|bag → questBins`,
  `paw|leaf → paw`, fallback `questCard` (ORCHESTRATOR_NOTES 14:28).

All four previously skipped proofs in `app/test/features/kid_home/k04_bugs_test.dart`
are now un-skipped and passing; full `test/features/kid_home` run is green.
## Iteration 3 — FIXES_2 remediation (2026-10-04)

- **K04-BUG-4 (Minor, FIXED):** the over-cap title path in
  `quest_detail_view.dart` (`NestBalancedText`) now passes
  `overflow: TextOverflow.ellipsis`. The previously skipped proof
  `K04-BUG-4: an over-cap title must ellipsise, not clip` is un-skipped and
  passes (asserts `title.overflow == TextOverflow.ellipsis` and
  `maxLines == 3`).
- **Icon audience ruling (ORCHESTRATOR_NOTES 15:08, mandated this round):**
  the local `_iconFor` in `quest_detail_view.dart` now delegates to the shared
  single source `questIconFor(key, audience: NestAudience.kid)`, mirroring
  K03's `_iconFor` byte-for-behaviour. Side effect that clears 5_ui.md's
  verdict-driving MAJOR: the K04 hero now renders `ic_quest_bed_kid.svg` —
  verified the asset's path data is the K04 HTML hero drawing
  (`M2 18v-7 / M2 14h20v4 / …h-9v3 / M6 11V8h4v3`), not the P09 flat arch.
  `k04_bugs_test.dart` BUG-3 expectations updated to the kid assets
  (`questBedKid` / `questDishesKid` / `questHoover` / `questBins`) and the
  file header notes the iter-2 → iter-3 supersede. No `core/**` edits needed —
  the shared asset already existed on main.

Verification: `flutter analyze` clean;
`flutter test --timeout 120s test/features/kid_home` → 545 passed, ~3 skipped
(pre-existing skips in K01/K02/K03 files, none from K04), 0 failed.
The remaining 5_ui.md MAJOR needs a stage-5 re-shot; nothing in `kid_home/`
left that can change it.

VERDICT: PASS
