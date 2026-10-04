# K06 · 2a BUILD LOGIC (iteration 4)

## CONTRACT CHANGES

None. No state, event, repository, or entity shape changed this
iteration. The bloc contract (`PipCareRequested` / `PipWardrobeBuyRequested`
/ `PipWardrobeEquipRequested`, `PipState` {status, nest, actionError,
actionNonce}, `kPipNotEnoughCoins`, `PipBuyResult`, `pipStageName`,
`PipNest.growthFraction`) is exactly as iteration 3 left it.

## FIXES_3 triage — no item is actionable purely inside this layer

- **#1 (major) local-copy switch** (`PipCareButton` → `NestKidButton`,
  `PipNestSlot` → `NestPetStage`, `_DashedBorderPainter` →
  `NestDashedBorder`): all edits are in `presentation/views/**` and
  `presentation/widgets/**` — the parallel UI builder's layer. Untouched
  here. (Also undecided upstream: `6_bugs.md` defers it as a scheduled
  refactor in `2_build.md` §5.1, so "fixing" it now would pre-empt the
  plan as well as the layer split.)
- **#2 (minor) move `pipStageName()` out of `domain/`**: its three call
  sites are `pip_nest_view.dart:345,355` and `pip_growth_card.dart:46`
  (views/widgets), and the helper is imported by two test files. Moving it
  without updating those call sites breaks compilation; updating them
  edits the UI builder's files. Left for the UI builder — my two test
  imports (`pip_repository_test.dart`, `pip_bloc_test.dart`) move with
  whatever path it lands on.
- **#3 (minor) cost constants onto abstract `PipRepository`**: the six
  readers (`PipRepositoryImpl.feedCostCoins/bathCostCoins`) are all in
  `pip_nest_view.dart:482-542`. Relocating the constants orphans those
  references unless the view is edited in the same pass. Left for the UI
  builder (one mechanical pass: declare on the abstract, re-point the six
  readers, drop the impl duplicates).
- **#4 back button, #5 coin weight**: views/widgets. Not touched.
- **#6 DESIGN_SPEC prose**: shared doc outside `docs/screens/K06/` —
  needs an orchestrator/spec edit, not a screen-layer change. Noted, not
  actionable here. (Behaviour already follows the HTML/PNG oracle.)
- **#8 process leftovers**: the `pip_orchestrator_notes_test.dart`
  sweep state and the untracked `pip_buy_result_test.dart` belong to
  other stages' in-flight work (one is already editing that file in this
  worktree). Process, not findings; untouched.
- **#16 sun-hat proof rewrite**: test-stage file, informational. Not mine.
- **6_bugs items**: BUG-1..7 verified fixed and live (my BUG-7 proof
  green, see below); sun-hat residual is shared-blocked (`SHARED_REQUEST`
  §7, needs a `main`-side asset); local-copy switch scheduled; prices
  done upstream. Nothing for this layer.

Net: zero logic-layer edits this iteration — correctly so, since every
open item either lives in views/widgets, in another stage's files, or in
shared space.

## Verification (logic-stage scope — no full-app test, no simulator)

- `flutter analyze lib/features/pip
  test/features/pip/pip_repository_test.dart
  test/features/pip/pip_bloc_test.dart` → No issues found.
- `flutter test --timeout 120s
  test/features/pip/pip_repository_test.dart
  test/features/pip/pip_bloc_test.dart
  test/features/pip/k06_bugs_test.dart` → All tests passed (+62, zero
  skips in these files).
- No `google_fonts`, no `DateTime.now()`, no new ids, no `core/` or `app/`
  edits, no views/widgets edits, no simulator. `git status` shows no
  logic-layer modifications this iteration.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. UI builder owns #1–#5 (with #2/#3
  needing the coordinated import/reference updates noted above).

VERDICT: PASS
