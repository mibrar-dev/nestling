# P01 Welcome — build notes (Stage 2, iteration 2)

Plan `1_plan.md` + every item in `FIXES_1.md` (review findings 1–11,
UI deviations 1–4, bugs BUG-1–5, orchestrator notes). Only RULES §1 paths
touched (`git status`: the 3 files below + this note).

## Files changed

- `app/lib/features/onboarding/presentation/views/welcome_view.dart`:
  BUG-1 — inner frame is now `OverflowBox(min/max 350/388, topLeft)` so the
  `Stack` always lays out at full design size and only paint scales;
  BUG-5 — `Stack(clipBehavior: Clip.none)` matching the HTML `.scene`;
  orchestrator Pip rule — v1 `pipStage2` SVG replaced by
  `PipAvatar(style: mochi, stage: 2)` (sunny = default) in the same
  168×168 @ (91,120) slot, wrapped in `Semantics(image, label)` keeping the
  HTML alt text verbatim; finding 5 — `_frameW/_frameH` constants with
  source comment; finding 6 — dead `BlocBuilder` + misleading doc claim
  removed (route `BlocProvider` untouched); finding 10 — redundant
  `Scaffold.backgroundColor` removed (theme owns it).
- `app/test/features/onboarding/welcome_view_test.dart`: strengthened the
  4 no-crop regressions with `expect(stack.size, Size(350, 388))` (fails on
  the old 280×310.4 layout even with clipping off); added 47dp
  `NestStatusBar` reserve pin. Finding 7 (`isHeader`) was already covered
  by a prior iteration — my duplicate assert was removed.
- `app/test/features/onboarding/p01_bugs_test.dart`: BUG-1 + BUG-5 proofs
  un-skipped (both pass, incl. the new layout-size assert); BUG-2/3/3b/4
  stay skipped — shared code I must not touch (see SHARED_REQUEST).
- `docs/screens/P01/SHARED_REQUEST.md`: kept BUG-2/3/4 items, added item 4
  (findings 4+8: warm SVGs via `precachePicture` from the app shell +
  bundle Inter/Nunito, disable runtime fetching).

## Fix items (FIXES_1 disposition)

1. Blocker scene crop — fixed, regressions green at 320/360/390/430.
2. Stale SHARED_REQUEST claim — already replaced in iteration 1 (verified:
   `router_redirect_test` is route-location based); numbers corrected here.
3. Coin shadow clip — fixed (`Clip.none`).
4. Precache — shared item 4 filed.
5. Frame constants — done.
6. Dead BlocBuilder — removed.
7. Header flag — already pinned; duplicate removed.
8. Fonts — shared item 4 filed.
9. Cross-feature route import — kept (plan §c compliant, conscious).
10. Redundant background — removed.
11. 430dp left-aligned scene — kept (matches `.scene{width:350px}`).
- UI dev 1 (headline break `feel like/a game` vs design `feel/like a game`):
  kept natural wrap. Forcing the design break needs ≤330pt width at 390dp,
  but `Chores that feel` alone exceeds the 280pt content at 320dp → forced
  break would overflow and fail this stage's 320dp gate. Tracking −1% and
  34/40 metrics already match; remainder is engine font metrics. Accepted
  band-4 drift; pixel parity is stage 5's gate.
- UI dev 2 (CTA +34dp) = BUG-2, shared item 2. UI dev 3 = harness artifact,
  no action. UI dev 4 = BUG-1, fixed.
- BUG-2/3/4 — shared, skipped proofs + SHARED_REQUEST items 1–3.
- Orchestrator notes — PipAvatar swap done (idle, still frame under
  DISABLE_ANIMATIONS/reduced motion via PipAvatar's own gate; loader's FFI
  gate keeps `flutter test` on the SVG path); status-bar ignore applied.

## Checks (`app/`)

- `dart format .` — 341 files, 0 changed.
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — 43 passed, 4 skipped (shared).
- `flutter test` (full) — **331 passed, 4 skipped, 0 failed**
  (`+331 ~4: All tests passed!`). Skips are exactly the shared-blocked
  BUG-2/3/3b/4 proofs; every P01-owned test, incl. the un-skipped BUG-1/5
  proofs, passes.

VERDICT: PASS
