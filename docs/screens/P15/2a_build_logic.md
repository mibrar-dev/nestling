# P15 · Child profile — Stage 2a BUILD, LOGIC CHUNK (iteration 3)

Scope: non-UI layer of feature `family` only — `domain/**`, `data/**`,
`presentation/bloc/**`, the feature's DI/route registration files, unit/bloc
tests, plus the explicitly-instructed un-skip of `p15_bugs_test.dart` proofs.
No edits to `presentation/views/**` or `presentation/widgets/**` (the UI
builder owns those and is concurrently editing them). Implements `1_plan.md`
§b plus every `FIXES_2.md` item in the logic layer.

## CONTRACT CHANGES

None this iteration. No new events, states, or repository methods; the
`_ChildProfileRoute` wrapper is private to `family_routes.dart`, and the
`watchProfile` re-subscribe guard plus `debugPrint` gating change no shapes.
(Iteration-2 additions — `FamilyChildSelected`, `selectChild`,
`clearErrorMessage`, injectable `clock` — unchanged.)

## Fixes landed (all in the logic layer)

- **P15-BUG-9 (major)** — second `?childId=` ignored on the live branch page.
  `family_routes.dart` keeps the first-entry dispatch in
  `BlocProvider.create` (ordering: selection before load, so the requested
  child is never preceded by the active one) and adds a private stateful
  `_ChildProfileRoute` wrapper between the provider and `ChildProfileView`
  that re-dispatches `FamilyChildSelected` in `didUpdateWidget` whenever the
  query id changes while mounted. Dispatch stays out of the view (UI
  builder's file). Both skipped proofs un-skipped and green; the view
  test's "SECOND deep link" proof goes green with no edit to that file.
- **Review 3 (minor)** — `watchProfile` could double-subscribe the ledger
  when a multi-table transaction emits several base events during one
  `await`. The handler now claims the slot synchronously
  (`ledgerSub = null` before the cancel-await) and, after the await, only
  the newest run (`identical(latestParts, parts)`) may clear or
  (re)subscribe — an older run can never orphan a listener. Selection
  resolve factored into `_selectedOf(parts)` so the re-check cannot
  disagree with the first pass.
- **Review 4 (minor)** — the repoint query now cites the shared
  `AppDatabase.watchChildren` ordering in a comment, and `SHARED_REQUEST.md`
  gains §5 asking for a one-shot `childrenInCreationOrder(familyId)`.
  No behaviour change.
- **Review 5 (minor)** — the two P15 `debugPrint` lines (remove/select
  failures) are now `kDebugMode`-gated; P05's pre-existing line untouched.
- **Review 8 (minor)** — `SHARED_REQUEST.md`: numbering was already `## 3`
  / `## 4`; fixed the stale §2 wording that still described
  `leadingAsset:` code (`builder` form + alias-only ask), and the §5 above.

## Not mine (left for their owners)

- Review 2 (cross-feature `moneyPounds` import), 6 (`size: 84`), 7
  (`ProfileRow` tokens/duplication): UI builder's widgets — untouched.
- ORCHESTRATOR items 1–2: shared row/assets + view glyphs (already
  requested/landed); items 3–4 are not findings.

## Files changed

- `app/lib/features/family/family_routes.dart`: `_ChildProfileRoute`
  wrapper + `didUpdateWidget` re-dispatch (`flutter/widgets.dart` import).
- `app/lib/features/family/data/family_repository_impl.dart`:
  `_selectedOf` helper, slot-claim + newest-run-wins guard, order citation.
- `app/lib/features/family/presentation/bloc/family_bloc.dart`:
  `kDebugMode` gates on the two P15 failure logs.
- `app/test/features/family/p15_bugs_test.dart`: P15-BUG-9a/9b un-skipped
  (brief explicitly instructs it); header/group comments updated to
  fixed-state. No proof logic touched.
- `docs/screens/P15/SHARED_REQUEST.md`: §2 wording refresh, new §5.
- `docs/screens/P15/2a_build_logic.md`: this file.

## Verification (in `app/`, no simulator)

- `flutter analyze` on the logic scope → No issues found. `dart format`
  clean. No `google_fonts`. No whole-suite run, no simulator.
- `child_profile_bloc_test` + `p15_bugs_test` → 31/31 (incl. 9a/9b).
- `test/features/family/` → 272/272 (incl. the view BUG-9 proof).
- `test/core/data/repositories_test.dart` + `today_view_test.dart` →
  73/73 (removeChild cascade + route wrapper adjacent coverage).

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer is unfinished. Remaining work (view
  listener/labels, shared row + assets) belongs to the UI builder or the
  orchestrator.

VERDICT: PASS
