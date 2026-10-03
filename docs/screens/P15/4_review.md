# P15 · Child profile — Stage 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` on branch `screen/P15` (52 files, +7166/−49 —
code under `app/lib/features/family/**` + `app/test/features/family/**`, notes
and UI captures under `docs/screens/P15/`). `main` is at the merge-base
(`e0470fa`), so the shared `NestListRow` fix this screen is waiting on has not
landed yet. **No code was edited by this stage; no simulator was booted,
installed on, screenshotted or driven (stage-4 policy).**

Inputs read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`,
`design/html-source/screens/P15-child-profile.html` (+ `components.css`),
`app/lib/core/design_system/**`, `app/lib/app/router.dart`,
`1_plan.md`, `5_ui.md` (iteration 2), `6_bugs.md` (iteration 2),
`SHARED_REQUEST.md`, `ORCHESTRATOR_NOTES.md` (all four items checked below).

## Gates (run in `app/`)

```
$ dart format --output=none --set-exit-if-changed lib/features/family \
    test/features/family/{child_profile_bloc,child_profile_copy,child_profile_states,\
child_profile_theme_size,child_profile_view,p15_bugs,add_children}_test.dart
Formatted 28 files (0 changed)

$ flutter analyze lib test/features/family
No issues found! (ran in 6.1s)

$ flutter test test/features/family/child_profile_bloc_test.dart \
    child_profile_copy_test.dart child_profile_states_test.dart \
    child_profile_theme_size_test.dart child_profile_view_test.dart \
    p15_bugs_test.dart add_children_test.dart p05_bugs_test.dart
00:13 +233 ~2: All tests passed!      # the two ~ are the concurrent bugs stage's
                                      # P15-BUG-9 proofs, uncommitted
$ flutter test test/features/family test/features/today
00:21 +362 ~2 -1                     # the -1 is the concurrent test stage's
                                      # in-flight child_profile_selection_test.dart
                                      # (wrong expectation: see 4_review note)
```

`analysis_options.yaml` untouched; no `ignore:`, no `skip:` in the committed
tests; no `google_fonts`/`GoogleFonts.*` anywhere in the diff; `disposeApp(tester)`
closes every pump in the new view tests (RULES §7).

## What holds up

- **ARCHITECTURE** — feature-first intact. `ChildProfile` is an Equatable
  entity; `family_repository.dart` gained only abstract methods
  (`watchProfile`, `selectChild`); one `FamilyBloc` extended (no second bloc,
  `Status initial/loading/loaded/failure` unchanged); DI untouched
  (`family_di.dart` still `registerLazySingleton` + `registerFactory`); routes
  in `<feature>_routes.dart`. No file outside RULES §1 except
  `app/test/features/today/today_view_test.dart` (recorded in
  `SHARED_REQUEST.md` §"Cross-feature test anchor").
- **Design system** — tokens only for colour (`tokens.surface/ink/ink2/ink3`,
  `NestTileTint`, `avatarColourFor`); every type style is a `NestType.x()` plus
  a `copyWith` that reproduces the CSS exactly (`.hero h1` 24/30, `.stat .v`
  22/26 via `kidName`, `.stat .l` 12/16 w600, `.piprow` head 17/24 w800,
  `.hero .sub` 14/20). No letter-spacing reintroduced. `NestCard`, `NestList`,
  `NestProgress`, `NestAvatar`, `NestButton`, `NestModal`, `NestEmptyState`,
  `NestStatusBar`, `NestToast`, `showNestToast` all reused; the only raw
  `SvgPicture.asset` is the coloured `NestlingIllustrations.coin`, which
  `nest_icon.dart:81-83` explicitly documents as the illustration path.
- **Owner rules** — PIP: `_PipCard` renders the child's own Pip from the DB row
  (`mochi·sunny·none·3` for Maya, proven in `child_profile_view_test.dart`),
  never `pip_stage_*.svg`; the no-children empty state uses
  `PipAvatar(mochi, stage: 1)`. COPY: `Age 7–9 · Pip is a Fledgling`,
  `Pip · Fledgling`, `175 of 250 · 70%`, `Change ›` (U+203A), `£3.00 a week ·
  Owed £4.20` are asserted with the exact code points. DATA OVER MOCKS: `4`
  (not the PNG's `18`) and `6 active · 4 daily, 2 weekly`. CHILD ORDER:
  creation order via the shared `watchChildren` helper and
  `_selectProfileChild`'s first-in-order fallback. TRIAL: no
  `subscription_status` write anywhere. `subscription_status` untouched.
  BOTTOM EDGE / ALIGNMENT / CHIP ROWS: not this screen's surface (tab bar is
  the shared `ParentShell`; no chips).
- **ORCHESTRATOR_NOTES.md** — item 1 fixed and *proved*, not eyeballed:
  `child_profile_theme_size_test.dart:362-405` asserts
  `RenderParagraph.didExceedMaxLines == false` for all nine row paragraphs and
  that the trailing keeps its intrinsic width. Item 2 fixed with existing
  assets: `assets/icons/ic_quests.svg` is byte-for-byte the design's
  `<circle r9/> + check` and `NestlingIllustrations.coin` is the design's
  `coin.svg` (I diffed both against `design/html-source/`). Item 3 pronoun kept
  per the ruling — not a finding. Item 4 DB counts — not findings.
- **Iteration-1 findings closed** — 1 (deep link) *partially*, see finding 1;
  2 (`active_child_id` after removal) closed (`family_repository_impl.dart:395-413`
  repoints to the first remaining child in creation order, or NULL);
  3 (wall-clock period maths) closed (`_clock` defaults to
  `Seed.anchorOverride ?? DateTime.now().toUtc()`, `family_repository_impl.dart:27-39`,
  the `TodayRepositoryImpl` pattern); 4 (listener scoped to the non-destructive
  path) closed (`child_profile_view.dart:50-55`); 5 (`Semantics(header: true)`)
  closed (`child_profile_body.dart:122-124`); 6 (hero wrap) closed (`maxLines: 3`,
  grows like the CSS); 8 (pronoun) ruled not a finding; 10 (loading/failure/
  toast view proofs) closed by `child_profile_states_test.dart` + the
  remove-failure view test.
- **Accessibility** — every control asserts `hasAction(SemanticsAction.tap)`
  *and* that `performAction(tap)` drives the real effect (navigation,
  dialog); the Pip node is `Semantics(image: true, label: …)` + `ExcludeSemantics`;
  `ProfileRow` forwards `onTap:` on its `Semantics(button: true)` node; the
  confirm dialog's bloc is read before `showNestModal` (the dialog is a sibling
  route and cannot resolve the provider) — a real trap, correctly avoided.
- **Performance** — `ChildProfileBody` is stateless over an immutable entity,
  so bloc emissions (DB-driven, not per-frame) rebuild it; no `setState`, no
  timers, no stream subscriptions in the view layer beyond bloc.

## Findings

### 1. MAJOR — `?childId=` is only honoured on the route page's FIRST build; a later deep link silently keeps the previous child (cross-stage: bugs stage P15-BUG-9)

`app/lib/features/family/family_routes.dart:34-53`

```dart
return BlocProvider<FamilyBloc>(
  create: (_) {
    final bloc = GetIt.instance<FamilyBloc>();
    if (requested != null) bloc.add(FamilyChildSelected(childId: requested));
    bloc.add(const FamilyLoadRequested());
    return bloc;
  },
  child: const ChildProfileView(),
);
```

The selection is dispatched from `BlocProvider.create`, which runs **once per
provider element's `initState`**. `childProfileRoute` is the Family branch of a
`StatefulShellRoute.indexedStack` (`app/lib/app/router.dart:137-139`), and the
branch page stays alive once the tab has been visited. The chain for a second
deep link:

1. go_router keys a page by its **matched path only** —
   `go_router-18.0.2/lib/src/match.dart:231`: `pageKey:
   ValueKey<String>(newMatchedPath)` — the query string is not part of it, so
   `/child-profile?childId=leo` reuses the live page.
2. `NavigatorState` matches the key and calls
   `matchingEntry.route._updateSettings(nextPage)`
   (`flutter/lib/src/widgets/navigator.dart:4331`), which rebuilds the route
   content from the **new** page child
   (`flutter/lib/src/material/page.dart:275-277`, `buildContent => _page.child`)
   — so the route builder *does* re-run and hands over a new `BlocProvider`
   widget.
3. Flutter **updates** that element (same runtimeType, no key) rather than
   recreating it, and provider only calls `create` once per element
   (`provider-6.1.5+1/lib/src/inherited_provider.dart:739-749`,
   `if (!_didInitValue) { _didInitValue = true; _value = delegate.create!(…) }`).

Net effect: no `FamilyChildSelected`, `_pendingSelection` and
`app_state.active_child_id` keep the old child, and the screen shows the
**wrong child's** name, age/Pip line, Pip avatar, PIN state, coins, quest counts
and owed pocket money — plus a "Remove <other child> from family" button.

User paths: (1) open the Family tab, then Today → tap a kid card; (2) P05 →
Edit the pencil on a child other than the one currently selected; (3) any
re-entry into P15 with a different `childId`. The committed suite cannot see it:
every deep-link test (`child_profile_view_test.dart`, `p15_bugs_test.dart`
P15-BUG-1a/1b) pumps a **fresh** app, so the branch page is always created, not
updated. The bugs stage's skipped proofs `P15-BUG-9a/b`
(`app/test/features/family/p15_bugs_test.dart:280-344`, in flight) reproduce it
at the widget level and agree with this analysis.

**Fix (in feature scope, no shared change):** react to the *route*, not to the
provider's creation. Either

```dart
// child_profile_view.dart → a small StatefulWidget around the current body
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final id = GoRouterState.of(context).uri.queryParameters['childId'];
  if (id != null && id != _seen) {
    _seen = id;
    context.read<FamilyBloc>().add(FamilyChildSelected(childId: id));
  }
}
```

(go_router's documented pattern — `GoRouterState.of` registers a dependency on
`GoRouterStateRegistryScope`, `go_router-18.0.2/lib/src/state.dart:129-144`, so
it re-fires on the in-place update), or, as the bugs stage suggests, a stateful
wrapper between the `BlocProvider` and the view reacting to the new `requested`
value in `didUpdateWidget`. `selectChild` is idempotent and membership-gated
(`family_repository_impl.dart:339-361`), so re-dispatching is safe; keep the
`FamilyLoadRequested` dispatch in `create`. A keyed `pageBuilder`
(`MaterialPage(key: ValueKey('p15-$requested'))`) also works but replaces the
page (transition animation inside the tab, brief loading flash) — worse UX.
Then un-skip `P15-BUG-9a/b` and add the "second deep link" case to
`child_profile_view_test.dart`.

### 2. MINOR — cross-feature *presentation* import breaks the per-feature contract

`app/lib/features/family/presentation/widgets/child_profile_copy.dart:25`
(`import '…/features/pocket_money/presentation/widgets/money_pounds.dart'`),
used at `:110-111`.

`docs/ARCHITECTURE.md:75` defines `presentation/widgets/` as
"feature-private widgets". P15 is the first file in the app to import another
feature's presentation widget, so the two features now fail to compile
independently and the money format can drift (P12 changing `moneyPounds`
silently changes P15's copy).

**Fix:** use the shared formatter that is already in the design-system barrel —
`formatPounds` (`core/design_system/components/nest_money.dart:5`, exported at
`design_system.dart:25`) — e.g.
`String _pounds(int pence) => formatPounds(pence.abs() / 100)` (`.abs()`
preserves `moneyPounds`'s sign-free rendering), or, if pence-exact formatting
is preferred, keep a local 3-line helper and add a `SHARED_REQUEST.md` entry
promoting `moneyPounds` into the design system. Reading the sibling feature's
*domain* constant (`PipProfile.evolveAtCoins`, `child_profile_body.dart:38`)
and the route path constants are fine — those are the normal cross-feature edges.

### 3. MINOR — `watchProfile`'s async listener can subscribe twice and orphan a ledger stream

`app/lib/features/family/data/family_repository_impl.dart:135-164`

```dart
).listen((parts) async {
  …
  if (ledgerChildId != selected.id) {
    await ledgerSub?.cancel();
    ledgerChildId = selected.id;
    latestLedger = null;
    ledgerSub = _db.watchLedger(selected.id).listen((rows) { … });
    return;
  }
  tryEmit();
}, onError: controller.addError);
```

`combineLatest4` re-emits **once per source event**
(`core/data/stream_combine.dart:44-47`), and the `removeChild` transaction
(`:372-414`) writes `quest_completions`, `ledger_entries`, `quests`,
`children` and `app_state` in one commit — so four emissions land while the
first body is still suspended at its `await` (`await` on `null` still yields).
Two bodies can therefore both pass the `ledgerChildId != selected.id` test and
both subscribe: the second assignment overwrites `ledgerSub`, so
`controller.onCancel` (`:166-169`) can only cancel the last one. The orphan is a
live Drift listener on a query the store keeps cached
(`drift-2.35.1/lib/src/runtime/executor/stream_queries.dart:96-117`), so nothing
crashes and no wrong-child rows are rendered — the leak is one listener (and one
`_QueryStreamListener`) per extra emission of a multi-table transaction, i.e. per
removal, accumulating for the app's lifetime.

**Fix:** re-check after the await and cancel what you are about to replace, or
serialise the handler (store the latest snapshot in `pending` and re-run from a
single `Future` chain / `scheduleMicrotask`), e.g.

```dart
if (ledgerChildId != selected.id) {
  final previous = ledgerSub;
  ledgerSub = null;                      // claim the slot synchronously
  await previous?.cancel();
  if (_selection != selected.id) return; // superseded while awaiting
  ledgerChildId = selected.id; latestLedger = null;
  ledgerSub = _db.watchLedger(selected.id).listen(…);
}
```

### 4. MINOR — `removeChild` re-implements the roster order without citing the shared query

`app/lib/features/family/data/family_repository_impl.dart:399-409` repeats
`orderBy([createdAt, CustomExpression<int>('rowid')])` — the CHILD ORDER
ruling that lives in `app/lib/core/data/app_database.dart:496-508`
(`watchChildren`). The two copies are the *only* definition of roster order,
and they can diverge (e.g. if the shared tie-break changes, `removeChild` picks
a different "next child" than the roster the screen renders).

**Fix:** cite `app_database.dart:499` in the comment (as `watchChildren`'s own
comment cites it), and add a `SHARED_REQUEST.md` line asking for a one-shot
`AppDatabase.childrenInCreationOrder(familyId)` so both call sites share one
query. No behaviour change today.

### 5. MINOR — `debugPrint` of a child-scoped error ships to release logs

`app/lib/features/family/presentation/bloc/family_bloc.dart:130`
(`debugPrint('P15 removeChild failed: $error')`) and `:152`
(`'P15 selectChild failed: $error'`). `debugPrint` is not compiled out in
release; a Drift exception string can contain the failing statement, i.e. a
child id, and the Children's Code rule ("no child data in places a child or
third party can reach") argues for keeping it debug-only.

**Fix (in scope):** `debugPrint` → `assert`-guarded logging, or gate both on
`kDebugMode`. If a shared solution is wanted (P05's `_onAddChildRequested`
prints the same way on `main`), add it to `SHARED_REQUEST.md` as a repo-wide
`NestLog` that no-ops outside debug.

### 6. MINOR — bare `size: 84` in the Pip slot (carried, already requested)

`app/lib/features/family/presentation/widgets/child_profile_body.dart:286`.
Carried from iteration-1 finding 7: `.piprow img { 84px }` is off the 4 pt grid
and has no token, and `core/design_system/**` is off-limits under RULES §1. The
value is correct and the comment cites `SHARED_REQUEST.md` §3. No action beyond
landing that request (`NestPip.rowSlot = 84`) and swapping the literal.

### 7. MINOR — screen-local `ProfileRow` uses bare geometry where tokens exist, and duplicates `NestListRow`

`app/lib/features/family/presentation/widgets/child_profile_row.dart:96`
(`fromLTRB(12, 10, 16, 10)`), `:101-102` (`width/height: 40`), `:153`
(`minHeight: 56`). `NestSpacing.s3` (12), `s4` (16), `s10` (40) and `gap10` (10)
all exist, so "tokens only, never hard-code sizes" is bent; `56` has no token
and is fine with its comment.

The larger point is duplication: this file re-implements the shared
`NestListRow` row because of `SHARED_REQUEST.md` §1 (`Flexible` trailing starves
`.list-main`). It is byte-equivalent to `core/design_system/components/nest_list_row.dart`
today (same 12/10/16/10 padding, same radius-12 tile per owner QA, same
`Semantics(button:, onTap:)` contract, same `NestList` dividers), which is why
the geometry tests are swap-neutral. But two copies of a row will drift the
moment either side changes something (radius, `compact`, focus, keyboard).

**Fix:** keep the file (SHARED_REQUEST §1 still blocks the real fix) and land §1
on `main`; then delete `child_profile_row.dart` and go back to `NestListRow`.
While it lives, use the `NestSpacing` tokens for 12/16/40/10 so the two copies
stay textually comparable.

### 8. MINOR — `SHARED_REQUEST.md` has two `## 3.` sections, and §2's update describes code that isn't there

`docs/screens/P15/SHARED_REQUEST.md:102` (`## 3. NestPip.rowSlot = 84`) and
`:114` (`## 3. Cross-feature test anchor…`). The second should be `## 4`.
Separately `:60-61` says "P15 now passes `leadingAsset: NestIcons.quests`",
while the shipped code passes the builder
`leading: (fg) => NestIcon(NestIcons.quests, color: fg)`
(`child_profile_body.dart:398`) because `ProfileRow` has no `leadingAsset`.
Doc-only, but it is the document the orchestrator reads to ratify cross-feature
work. Fix the numbering and the wording.

## Notes for the next stages (not findings)

- **Concurrent stages' in-flight work is not in this diff** (PROCESS ITEMS rule):
  `child_profile_view_test.dart`, `child_profile_states_test.dart`,
  `p15_bugs_test.dart` and `6_bugs.md` are modified-but-uncommitted and
  `child_profile_selection_test.dart` / `child_profile_row_test.dart` are
  untracked — all written after `.start_review` (19:20:59). One of them,
  `child_profile_selection_test.dart` → *"an explicit clock decides which period
  counts"*, is red (`Expected: <0> Actual: <2>`); its expectation is wrong, not
  the code: 2026-10-04 is a Sunday, still inside the London week that began
  Mon 29 Sep, so the two weekly completions correctly keep counting under the
  PERIODS ruling while the dailies fall out. Fix the expectation (assert 2 at
  +1 day, 0 at +8 days) — worth telling that stage.
- **Bottom edge / tab bar** belong to the shared `ParentShell` + `NestTabBar`
  (`app/lib/app/router.dart:25-46`); `5_ui.md` iteration 2 measured the
  below-tab area as bar surface in light and dark. Not P15's to edit.
- **`IntrinsicHeight`** on the three stat tiles (`child_profile_body.dart:183`)
  reproduces the CSS grid's equal-height behaviour at the cost of one extra
  layout pass. Negligible for three children; recorded so it stays deliberate.
- **Copy caveat already sanctioned**: `On · Maya knows their code` deviates from
  the PNG's "her" by owner decision (ORCHESTRATOR_NOTES item 3).
- 5_ui owes nothing further this iteration; after the finding-1 fix the UI stage
  should re-check that switching children re-renders the whole body without a
  vertical shift (the hero/stats/list geometry is already pinned by rect
  assertions in `child_profile_view_test.dart`).

VERDICT: FAIL
