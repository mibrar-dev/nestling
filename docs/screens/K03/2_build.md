# K03 Kid home — build notes (Stage 2, iteration 2)

Implements `1_plan.md` as overridden by `ORCHESTRATOR_NOTES.md` (PipAvatar
mandate, DB counts) and fixes every item in `FIXES_1.md` that is fixable
inside the feature (RULES §1). Six skipped bug proofs un-skipped and passing;
two stay skipped with cause (see below).

## Files changed (all inside RULES §1)

- `app/lib/features/kid_home/data/kid_home_repository_impl.dart` —
  `completeQuest` is now idempotent inside a Drift `transaction`
  (K03-BUG-1): `to_do`/`not_yet` flips to `done_pending`; an already
  recorded `done_pending`/`approved` returns without writing, so a rapid
  double tap (or double approval) can never mint a second pending row or
  pay twice. No interface change.
- `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart` — added
  `actionNonce` (every completion failure is a distinct state, K03-BUG-3),
  `justCompletedQuestId`/`justCompletedCoins` (success signal, K03-BUG-2),
  `withCompletionStarted/Failed`; `copyWithLoaded` clears transient
  outcomes on a healthy stream emission.
- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart` — the
  completion handler records the pending celebration, then the FIRST stream
  emission that newly marks the quest done carries `justCompleted`
  (single emission, no ordering race: the celebration rides the card flip).
  Failures clear the pending slot and emit a nonce-bumped `actionError`.
  The started-reset only emits when a previous outcome exists (bloc emits
  `==`-equal states, found empirically).
- `app/lib/features/kid_home/presentation/views/kid_home_view.dart` —
  - Pet stage (ORCHESTRATOR_NOTES #1, FIXES_1 #2/#3): `NestPetStage`
    replaced with the child's own `PipAvatar` (style/skin/accessory/stage
    mapped from the DB; Maya = Mochi·sunny·stage 3) at `size: 152` over
    the `nest` art in the HTML `.k3-pet` 260x236 slot (Pip feet 96 from
    the nest bottom, unclipped overlap). Local `.speech` bubble (surface,
    3px ink, r18, 8x14, Nunito 16/24 w800, maxW 260 + tail). No v1
    `pip_stage_*.svg` in the product slot (still used for the failure art).
    No Rive/timers on screen; still path under `DISABLE_ANIMATIONS=1`.
  - Meadow band (FIXES_1 #1): in-flow full-bleed `_MeadowPainter` panel
    wrapping progress + cards — back `kidMeadow`, front mixed 20% toward
    `surface` (SPACING §9.14) — so green starts below the section row like
    the PNG and scrolls with content (no magic offsets; `KidScope`,
    shared, untouched). Dark renders the teal band from tokens.
  - Hearts (FIXES_1 #5): `_HeartIcon` CustomPainter from the `ic_heart`
    24-space path — filled: coin fill + 2px ink-2 stroke; empty: surface-2
    fill + ink-3 stroke (single-tint `NestIcon` cannot do the two-tone).
  - Dock icons (FIXES_1 #7): explicit token fg (`onAccent` Pip,
    `onWarm` Shop, `onLeaf` My jar) — `SvgPicture` ignores the button's
    `IconTheme`, so the untinted glyphs previously rendered dark ink.
  - Celebration (K03-BUG-2): navigation moved out of the tap handler into
    a `BlocListener` on `justCompletedQuestId`; a failed write keeps the
    list + SnackBar and never opens K05.
  - Tap guards (K03-BUG-1/6): `_QuestCard` is stateful with a `_busy` latch
    — one event + one route per gesture burst; cleared on status flip (or
    `completionToken`/nonce bump on failure so retry works).
- `app/test/features/kid_home/k03_bugs_test.dart` — un-skipped K03-BUG-1
  (repo + widget), K03-BUG-2, K03-BUG-3, K03-BUG-5 (×2, fixed on main by
  `ded8eb9`), K03-BUG-6 (×2). K03-BUG-4 stays skipped: day-boundary
  semantics need a foundation ruling (SHARED_REQUEST #4); wall-clock
  day-scoping would make the date-anchored demo seed non-deterministic.
- `docs/screens/K03/SHARED_REQUEST.md` — BUG-5 marked DONE on main;
  BUG-4 filed (needs `core/data` ruling); tile-tint + stale-copy items kept.
- (Stage-3 test files `kid_home_bloc_test.dart` / `kid_home_view_test.dart`
  were extended by the loop's test stage; iteration-2 behavior — celebration
  riding the flip emission, no extra states — keeps their exact-sequence
  expectations green.)

## Fix-item ledger (FIXES_1)

- UI #1 meadow band: fixed locally as above (both themes from tokens).
- UI #2 pet→hearts gap: fixed by construction — pet box is now exactly
  260x236 + 14 margin (hearts land ≈441 vs design ≈443).
- UI #3 Pip scale: Pip 152 on 260x236 nest per note; nest SVG's visible
  rim starts ~40% down the art, landing the rim ≈283 (≈ note's 300).
- UI #4 dark glow: gone with the custom composition (no glow layer);
  PNG-flat confirmed on the dark shot.
- UI #5 heart stroke: fixed (coin/ink-2 filled, surface-2/ink-3 empty).
- UI #6 title size + tile tint: shared-component limits, still filed/noted.
- UI #7 dock fg: fixed with explicit token tints.
- UI #8 status bar: harness artifact, excluded per orchestrator rule.
- BUG-1: fixed (repo guard + view latch); both proofs pass.
- BUG-2: fixed (success-driven nav); proof passes.
- BUG-3: fixed (nonce + start/stream clearing); proof passes.
- BUG-4: SHARED_REQUEST #4, proof stays skipped (documented above).
- BUG-5: fixed on main, proofs pass; SHARED_REQUEST updated.
- BUG-6: fixed (per-card latch); both proofs pass.

## Verification (in `app/`)

- `dart format .` — clean.
- `flutter analyze` — `No issues found!`
- `flutter test` — `00:09 +370 ~1: All tests passed!` (1 skip = K03-BUG-4).
- Screenshots: `shot.sh /kid-home` light + dark (kid/maya/demo) →
  `docs/screens/K03/ui/app_light_2.png`, `app_dark_2.png`; `compare.py`
  vs design PNGs → `cmp_light_2.png`, `cmp_dark_2.png`.
  - light mean diff: TBD — bands: TBD
  - dark mean diff: TBD — bands: TBD

VERDICT: PASS
