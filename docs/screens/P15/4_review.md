# P15 · Child profile — Stage 4 QA code review (iteration 4)

Scope: `git diff main...HEAD` at checkpoint `686bd69` ("checkpoint after build
(iteration 4)"). The only lib delta vs the iteration-3 checkpoint (`422e41e`)
is a 6-line guard in `child_profile_view.dart` (P15-BUG-10 fix); everything
else is tests and docs. **No code was edited by this stage; no simulator was
booted, driven, screenshotted or installed on (stage-4 policy); no
`flutter clean`; `analysis_options.yaml` untouched; no `skip:` or new
`ignore:` in tracked files.**

## Gates (run on the tracked tree in `app/`)

```
$ dart format --output=none --set-exit-if-changed lib/features/family \
    $(git ls-files test/features/family | grep '\.dart$')
Formatted 32 files (0 changed)

$ flutter analyze lib/features/family test/features/family
No issues found!

$ flutter test $(git ls-files test/features/family | grep '\.dart$')
00:19 +283: All tests passed!          # 283 tests, family feature only
$ flutter test test/features/today/today_view_test.dart
00:04 +51: All tests passed!           # the only :today file P15 touches
$ flutter test test/features/family/p15_bugs_test.dart
00:04 +8: All tests passed!            # iteration-3 bug proofs stay green
```

`test/features/today/p08_bugs_test.dart` (P08 feature, outside P15's §1 scope
and outside the P15 diff) has 2 red tests for a date-dependent reason — noted
under the verdict list below.

## Iteration-3 review findings — dispositions

| # | Finding | Disposition in iteration 4 |
|---|---|---|
| 1 | MAJOR (from review 2) — repeat `?childId=` ignored while branch page alive | **FIXED in iteration 3, verified green in 4.** `_ChildProfileRoute.didUpdateWidget` (`family_routes.dart:78-88`) + view's `didChangeDependencies` (`child_profile_view.dart:45-68`); un-skipped proofs `P15-BUG-9a/b` red→green; view-level repro at `child_profile_view_test.dart:482` green; no churn on rebuild (`:521`) or re-entry with same id; stale `?childId=` cannot resurrect a removed child; dropping the query keeps the selection. |
| 2 | MINOR — cross-feature `moneyPounds` import | **FIXED** (iteration 3). `child_profile_copy.dart:107-114` uses the barrel's `formatPounds`; `child_profile_copy_test.dart` gains byte-for-byte and sign-free regression tests. `ARCHITECTURE.md:75` boundary intact. |
| 3 | MINOR — `watchProfile` re-entrancy/duplicate ledger subscriptions | **FIXED** (iteration 3). Slot claimed synchronously; only the newest base emission may re-subscribe (`family_repository_impl.dart:138-169`). Two new tests pin"a cascading remove leaves one live subscription" and "emptying and refilling re-subscribes cleanly" — green. |
| 4 | MINOR — roster-order duplication in `removeChild` | **Mitigated**: shared-source comment added at the repoint query (`family_repository_impl.dart:419-422`) + new `SHARED_REQUEST.md` §5 asking main for `AppDatabase.childrenInCreationOrder`; new 3-child proof (`child_profile_selection_test.dart:399`) green. |
| 5 | MINOR — release-visible child data in debugPrint | **FIXED**: both sites are `if (kDebugMode) debugPrint(...)` (`family_bloc.dart:130`, `:154`). |
| 6 | MINOR — bare `size: 84` | Accepted/document; `SHARED_REQUEST.md` §3 owns the token. |
| 7 | MINOR — `ProfileRow` duplicated component + bare sizes | **Partially fixed**: geometry now on `NestSpacing` tokens (`child_profile_row.dart:99-113`), `minHeight: 56` bare with justification; component remains temporarily until `SHARED_REQUEST.md` §1 lands. |
| 8 | MINOR — `SHARED_REQUEST.md` duplicate §3 numbering + stale §2 wording | **FIXED**: §1–§6 now ordered, §2 describes the actual `leading: (fg) => …` builder, §6 records the main-console reds and says do not fix here (orchestrator UPDATE at 23:55 confirms). |

## What was changed in iteration 4 itself (the 6-line guard)

`child_profile_view.dart:57-62`:

```dart
// P15-BUG-10: a route-less mount (a bare `MaterialApp` test, a preview
// harness, the design gallery) has no GoRouterState ancestor…
if (GoRouter.maybeOf(context) == null) return;
final requested = GoRouterState.of(context).uri.queryParameters['childId'];
```

Reviewed against stages' contract: **correct**. `GoRouter.maybeOf` returns
null rather than throwing when there is no ancestor (`router.dart:602`), so
the router state read is skipped only when no router exists — the P15-BUG-9
in-place-update re-dispatch still works inside the app (BUG-9 tests green),
a bare-`MaterialApp` mount now renders from the bloc's stream without
requiring `GoRouterState` (new test at `child_profile_view_test.dart:698`
green), and `GoRouterState.of`'s dependency registration is untouched on the
normal path. This is the minimal surgical fix and no UI/state contract
changes. Good.

## Findings

No blocker or major in the P15 diff. Three minors and one shared-test note:

### 1. MINOR — stale comment still claims P15-BUG-3 is unfixed

`app/lib/features/family/presentation/views/child_profile_view.dart:82-84`:

> "A repeated IDENTICAL remove failure is still swallowed here … clearing
> `errorMessage` needs a new bloc event, so BUG P15-BUG-3 stays with the
> logic builder."

BUG P15-BUG-3 was closed in iteration 2: `family_bloc.dart:132-138` does the
clear-then-raise sequence and `family_state.dart:72-76` has the
`clearErrorMessage` flag; its widget proof (`child_profile_view_test.dart:833`,
"a repeated identical remove failure toasts again") is green. A new builder
reading the comment will re-investigate a closed bug. **Fix:** replace the
sentence with e.g. "P15-BUG-3 closed in iteration 2: clear-then-raise in the
bloc `_onRemoveChildRequested`; the listener scope above is unaffected."

### 2. MINOR — `family_event.dart:44-48` doc no longer describes reality

> "The route dispatches this before the first [FamilyLoadRequested]; events run
> in order, so the first emission already follows the requested child."

True only for the cold-entry dispatch in `family_routes.dart:46-51`. The two
followers (`family_routes.dart:78-88`, `child_profile_view.dart:45-68`)
dispatch on later query changes, and their dispatch is *independent* of the
load event's position. That is fine and tested; the comment simply
over-promises now. **Fix:** "The route dispatches once before the first
`FamilyLoadRequested` on cold entry; `_ChildProfileRoute.didUpdateWidget` and
`_ChildProfileViewState.didChangeDependencies` re-dispatch on any later
`?childId=` change."

### 3. MINOR — wrong token owner in the comment (`NestSpacing.tapKid`)

`app/lib/features/family/presentation/widgets/child_profile_row.dart:91-92`:

> "the CSS grid-row meter matches `NestSpacing.tapKid` but that constant is
> the kid-mode floor…"

`tapKid` is on `NestDevice` (`core/design_system/tokens/spacing.dart:82`), not
`NestSpacing`. The intent (parent screen should not borrow the kid tap target)
is correct; the import-level name is wrong. **Fix:** change to `NestDevice.tapKid`.

### 4. MINOR — duplicate `FamilyChildSelected` dispatch on every child switch is still two writes

Iteration-3 review finding 1. Iteration 4 intentionally kept both followers
AND pinned the bound: at most one cold dispatch from the route plus one from
the view, no churn on same-id rebuilds or re-entry (`child_profile_view_test.dart:521-560`,
`:546-548` document the `lessThanOrEqualTo(2)` bound). It is bounded,
member-gated and idempotent, so it is not a regression — but the class is
"choose one channel" once `SHARED_REQUEST.md` §1's shared fix lets the bloc
rely on a single dispatch site. Leave as-is and bank it when main picks up §1.

### 5. NOTE — `test/features/today/p08_bugs_test.dart` has 2 red tests for a date-dependent reason (main-owned)

`[P08-B11] a daily completion from the previous London day is to do` and
`the kid card count excludes stale completions` fail on 2026-10-04:
`p08_bugs_test.dart:390,428,464` compute `stale` from `DateTime.now()`
instead of the pinned `Seed.anchorOverride`, while `TodayRepositoryImpl`
follows the anchor. On Sat 03 Oct the two agree and the tests pass; on Sun 04
Oct the wall clock has rolled past the pinned anchor and the "stale" row lands
*inside* the anchor's own London-day window, so `approved` is the correct
answer and the stale-window assertion inverts. This file is byte-identical to
main and outside P15's §1 scope — **P15 must not edit it**. Its name-slot is
the exact fix: replace the bare `DateTime.now()` with
`Seed.anchorOverride ?? DateTime.now().toUtc()` in each. Logged so the
orchestrator can batch it with `shared/family_time_test_fix` instead of
mistaking it for a P15 regression.

## Audited, no findings

- **ARCHITECTURE.md**: feature-first maintained; `domain/` held to
  entities + abstract repo; one `FamilyBloc` per feature with the same
  initial/loading/loaded/failure contract; DI and `*_routes.dart` per
  feature; no cross-feature *source* imports into a sibling feature dir.
- **RULES.md §1/§2/§7**: edits confined to `app/lib/features/family/**`,
  `app/test/features/family/**`, `docs/screens/P15/**`, plus already-approved
  cross-feature test anchors recorded in `SHARED_REQUEST.md` §4. Format/analyze
  clean, tracked test suite green, no skips/ignore.
- **Design system**: the iteration-4 guard adds no new style. New test code
  touches only `NestSpacing` tokens and existing components. No hard-coded
  colours/sizes/fonts introduced anywhere in the diff.
- **§5 P15 + ORCHESTRATOR_NOTES**: geometry, all three rows' copy, danger
  button copy, pronoun ruling (`their`), DB-driven counts, PipAvatar with the
  child's own DB look, status-bar as reserve, card/avatar/row heights and the
  20 px gutters — verified unchanged from the iteration-3 assessment and all
  UI-check captures (`ui/*_4.png`) are produced through `shot.sh`, not
  hand-drawn.
- **Accessibility**: no new interactive element was added in this diff.
  Existing tests still assert `getSemantics(f).getSemanticsData().hasAction(
  SemanticsAction.tap)` and that `performAction(tap)` drives the real behaviour.
- **Performance**: the guard adds one ancestor lookup per dependency change;
  no new stream, no per-frame work, streams are still disposed in the bloc and
  the repository's `watchProfile` controller honours the same supersession
  rule after the slot-claim fix.
- **Error handling**: same clean branches (loading spinner, in-place `Try
  again`, remove-failure toast + screen stays `loaded`, repeated identical
  failure toasts again, empty-state CTA, membership-gated selection,
  cascading remove, no stale `?childId=` resurrection). No new failure modes.
- **Children's Code**: no analytics, no ads, no new child-data exposure; the
  remove-cascade effects and debugPrint gating are still the iteration-2/3
  behaviour, unchanged.

VERDICT: PASS
