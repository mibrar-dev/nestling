# P17 Parental gate — QA code review (stage 4, iteration 1)

Scope reviewed: `git diff main...HEAD` limited to
`app/lib/features/parental_gate/**`,
`app/test/features/parental_gate/**`,
`app/test/core/family_time_test.dart`,
`docs/screens/P17/**`,
`docs/screens/_shared/family_time_test_fix_REPORT.md`.
Verified: `dart format` clean, `flutter analyze` → No issues found,
`flutter test test/features/parental_gate` → +38 All tests passed!.

Architecture: feature-first respected — domain (entity + abstract repo)
untouched; BLoC owns all gate logic; routes/DI per feature reused as-is.
No new cross-feature imports beyond route constants and the documented
`PipAvatar` motion import.

Design-system: `NestModal`, `NestKeypad(kid: true)`, `NestButton.ghost`,
`NestAvatar`, `NestCoinPill`, `KidScope`, `NestTokens` only; no hard-coded
colours (`Colors.transparent` only), no `google_fonts`, no extra
`letterSpacing`, no v1 pip SVGs.

Spec copy (DESIGN_SPEC §5 P17) matches the HTML character-for-character:
`Grown-ups only`, `Type the answer in numbers:`, `Back to Pip`,
`This keeps settings and purchases safe.`, dialog label `Parental gate`,
UK spelling, DB-derived question (`three times nine` on the pinned seed day).

Accessibility: modal `Semantics(label: 'Parental gate',
explicitChildNodes: true)`; digits group announces
`Answer, {n} of {total} entered`; all 13 interactive nodes expose
`SemanticsAction.tap` and `performAction` drives real state; wrong answer
live-announced `That wasn’t right — try again` with no danger styling;
backdrop `ExcludeSemantics` (non-interactive, so no `onTap` needed); no
`excludeSemantics: true` wrapper on an actionable control without `onTap`.
Text-scale 1.3 at 390 and 320×844 overflow-tested.

Performance: `buildWhen`/`listenWhen` bound rebuilds; no timers or
animation controllers; disabled gate renders `SizedBox.shrink()`; keypad
slot uses `FittedBox(scaleDown)` instead of scaling text; the
`StreamBuilder` child resolves in one emission and re-subscribes only on
session refresh — no rebuild storm.

Error handling / Children's Code: failure state with `Try again` +
`Back to Pip`; loading placeholders avoid frame jumps; no analytics, ads,
or tracking; the gate is a protective feature for kid mode.

## Findings

1. **minor** — `app/test/core/family_time_test.dart` (and new
   `docs/screens/_shared/family_time_test_fix_REPORT.md`) are edits
   outside RULES §1 (`app/test/features/<feature>/**` + feature dirs
   only). The fix is test-only, documented, and its suite is green
   (`+547`), so no product impact. **Fix:** if this was
   orchestrator-dispatched, append a line to
   `docs/screens/P17/SHARED_REQUEST.md` citing the `_shared` report so
   the inbox explains the shared-path edit.

2. **minor** — `parental_gate_view.dart:286-292`: the backdrop reads
   `AppDatabase`/`AppSession` directly via GetIt instead of the feature's
   repository/bloc. The `AppModeController`/`AppSession` GetIt reads have
   precedent (P07 paywall), but the `watchChildren` stream bypasses the
   repository contract the rest of the app follows. **Fix:** expose the
   active-child backdrop data via `ParentalGateRepository` (or have the
   bloc own the child stream) and bind the view to bloc state.

3. **minor** — `app/test/features/parental_gate/parental_gate_repository_test.dart:11,19,26`:
   `AppDatabase.memory()` is instantiated once per `challengeFor` test to
   call a pure method, tripping Drift's "database class created multiple
   times" warning in the test output. **Fix:** create one memory DB per
   file (`setUp`) or call `challengeFor` on a single shared instance.

4. **minor** — `parental_gate_view.dart:455-461` (`_DigitsRow`): the
   leaf caret renders only on the first empty box
   (`i == entered.length`), while the HTML source's `.digit.empty::after`
   paints the caret on *every* empty box (initial state would show two
   carets in the HTML, one in the app). **Fix:** drop the
   `i == entered.length` guard to paint every empty box, or confirm with
   design that first-empty-only is the intent and leave a comment.

5. **minor** — `parental_gate_view.dart:485-486` (`_GateLoading`): the
   placeholder heights (20/34/64/352) match the *filled* layout, but a
   one-line question occupies ~28 px vs the 34 px placeholder, so the
   keypad slot shifts ~6 px when data arrives. **Fix:** size the
   question placeholder to the real one-line `NestType.h3` height (28)
   or reuse the same measuring row the loaded state uses.

6. **note (no action)** — `parental_gate_repository_impl.dart:22` uses
   `DateTime.now().toUtc()` (pre-existing on main, unchanged in this
   diff) and keys the challenge to the UTC day, not the Europe/London
   day. Worth a shared follow-up via SHARED_REQUEST; not blocking P17.

No blocker or major findings. Tests, analyze, and format are green;
P17's own 38 tests pass; K03's known gate-copy failures are documented
in `docs/screens/P17/SHARED_REQUEST.md` for the orchestrator/K03.

VERDICT: PASS
