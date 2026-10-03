# P15 · Child profile — Stage 2b BUILD (UI chunk, iteration 3)

Scope owned: `app/lib/features/family/presentation/views/**`,
`presentation/widgets/**`, `app/test/features/family/child_profile_view_test.dart`,
`app/test/features/family/p15_bugs_test.dart` (un-skipping only). No domain/,
data/, bloc/ or core/ edits this stage. Re-read before finishing:
`1_plan.md`, `ORCHESTRATOR_NOTES.md`, `2a_build_logic.md`
(**CONTRACT CHANGES: none**), `FIXES_2.md`, `SHARED_REQUEST.md`.
No simulator booted, no whole-app `flutter test` run (integrator's stages).

## FIXES_2.md items fixed this iteration

### 1. MAJOR — P15-BUG-9: `?childId=` honoured only on the FIRST navigation

`family_routes.dart` dispatches `FamilyChildSelected` inside
`BlocProvider.create`, which runs once per provider element. `StatefulShellRoute`
keeps the Family branch page (and its page element) alive, and go_router keys
the page by matched path — so a later `/child-profile?childId=…` re-renders the
page without re-running `create`, and the previous child stays on screen.

Fix in my scope (the route file belongs to the logic builder's iteration-2
change): `ChildProfileView` is now **stateful**. Its
`didChangeDependencies` reads `GoRouterState.of(context)` (which registers a
dependency on the router-state scope, so it re-fires on the in-place page
update) and dispatches `FamilyChildSelected(childId:…)` whenever the query id
changes while this page is alive. The route's `create`-time dispatch is
unchanged and idempotent (`selectChild` is membership-gated), so the first
entry is unaffected. Fast path: a plain `/child-profile` re-render holds the
current selection.

Proofs un-skipped and green: `p15_bugs_test.dart` **P15-BUG-9a** (Family tab
open, then Leo's Today card → `child.id == 'leo'`) and **P15-BUG-9b** (Leo,
then Today's Maya card → `child.id == 'maya'`).

> Note: iteration-2's closing comment expected the fix in a stateful
> `_ChildProfileRoute` wrapper — same mechanism, but it lives lower, on the
> view that actually reads the route. The route file itself stays untouched by
> my stage.

### 2. MINOR — cross-feature presentation import (`child_profile_copy.dart`)

`child_profile_copy.dart` imported `moneyPounds` from
`…/pocket_money/presentation/widgets/money_pounds.dart`, breaking the
per-feature boundary (`ARCHITECTURE.md:75`). Switched to the shared
`formatPounds` exported by the design-system barrel
(`String _pounds(int pence) => formatPounds(pence.abs() / 100)` — the
`.abs()` preserves `moneyPounds`'s sign-free rendering). The rendered copy
(`£3.00 a week · Owed £4.20`) is unchanged. The read-only domain constant
`PipProfile.evolveAtCoins` and route path constants stay imported, as the
review allows.

### 3. MINOR — `ProfileRow` bare geometry → `NestSpacing` tokens

`child_profile_row.dart`: `fromLTRB(12, 10, 16, 10)` →
`fromLTRB(NestSpacing.s3, NestSpacing.gap10, NestSpacing.s4, NestSpacing.gap10)`,
and tile `width/height: 40` → `NestSpacing.s10`. `minHeight: 56` keeps its
literal because `NestSpacing.tapKid` semantically belongs to the kid-mode
floor; the comment now says so explicitly, keeping the two copies of the row
template textually comparable.

### 4. MINOR — `SHARED_REQUEST.md` housekeeping

Two `## 3.` sections → second one is now `## 4.`. §2's update previously
claimed "P15 now passes `leadingAsset: NestIcons.quests`"; corrected to the
code's actual `leading: (fg) => NestIcon(NestIcons.quests, color: fg)`
builder form.

### 5. Carried-from-iteration-1 finding 6 — `size: 84` (already requested)

No new code; `SHARED_REQUEST.md` §3 already asks for `NestPip.rowSlot = 84`.
The citing comment stays at the call site.

## Reviewed, not mine

* Review findings 3 (`watchProfile` async listener can subscribe twice —
  logic/data builder), 4 (`removeChild` re-implements roster order — logic
  builder), 5 (`debugPrint` of child-scoped error — logic builder).
* The test stage's `child_profile_selection_test.dart`
  *"an explicit clock decides which period counts"* was left red by the
  review's own note: its expectation is wrong, not the code (2026-10-04 is
  Sunday — still inside the London week from Mon 29 Sep, so the two weekly
  completions correctly keep counting; assert `2` at +1 day, `0` at +8 days).
  Not a view/widget test file, so not edited by this stage — flagged for the
  test stage.

## Gates (in `app/`)

```
$ dart format lib/features/family test
(clean)

$ flutter analyze lib/features/family test/features/family
No issues found! (ran in 6.2s)

$ flutter test --no-pub test/features/family/
00:09 +272: All tests passed!
```

All three red proofs I owned (P15-BUG-2, P15-BUG-4, P15-BUG-5) are green;
the two newly bug-fixed proofs (P15-BUG-9a/b) are un-skipped and green; no
whole-suite or simulator run — the integrator's stages.

## LEFT FOR NEXT ITERATION

* Stage 5 (`shot.sh`/`compare.py` light + dark) should confirm switching a
  child via `?childId=` re-renders the whole body **without a vertical shift**
  (hero/stats/list/danger rect geometry is already pinned by
  `child_profile_view_test.dart`).
* `child_profile_row.dart` stays until `SHARED_REQUEST.md` §1 lands on `main`;
  then delete it and go back to `NestListRow` (plus §2b's `leadingWidget`
  for the coin illustration).
* The three shared asks remain open: §1 (row flex), §2b (`leadingWidget` on
  `NestListRow`), §3 (`NestPip.rowSlot = 84`).

VERDICT: PASS