# Fix list after iteration 2

## From 3_test.md
# P15 · Child profile — Stage 3 TEST (iteration 2)

Route `/child-profile` · feature `family` · parent mode · light+dark designs.
Tree: branch `screen/P15` at `31a44b8` ("P15: checkpoint after build
(iteration 2)"), `main` merged through `17a21b6`.

Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md` (iteration 2), `2a_build_logic.md`, `2b_build_ui.md`,
`3_test.md` (iteration 1), `4_review.md`, `5_ui.md`, `6_bugs.md`,
`FIXES_1.md`, `SHARED_REQUEST.md` and **`ORCHESTRATOR_NOTES.md`** (all four
items still mandatory). No `ORCHESTRATOR_NOTES.md` update since iteration 1.

**No simulator was booted, installed on, driven or screenshotted** (stage 3
must not). No `flutter clean`. No production file was touched: this stage's
diff is `app/test/features/family/**` plus `docs/screens/P15/**`.

---

## 1. Iteration 1 → 2: the six red proofs are green

Every iteration-1 bug repro was left in place (not rewritten, not weakened);
all six now pass against the iteration-2 build:

| Iteration-1 bug | Proof (same file, same test) | Iteration-2 result |
|---|---|---|
| **1** major · `?childId=` ignored | `child_profile_view_test.dart` → *BUG: `?childId=leo` must show Leo* / *BUG: tapping Leo on Today must land on Leo's profile* | ✅ green |
| **2** minor · load failure reported twice | `child_profile_states_test.dart` → *BUG P15-BUG-2* | ✅ green (`listenWhen` now gates on `status == loaded`) |
| **3** minor · recovered load kept the dead message | `child_profile_bloc_test.dart` → *BUG P15-BUG-3* | ✅ green (`clearErrorMessage` on every load emission) |
| **4** minor · "Pip is a Egg" | `child_profile_copy_test.dart` → *BUG P15-BUG-4* | ✅ green (`pipStageArticle`) |
| **5** major · all three subtitles ellipsised | `child_profile_theme_size_test.dart` → *no list-row paragraph is ellipsised at 390* | ✅ green (`ProfileRow` takes the trail out of the flex distribution) |

Stage 6's own six proofs (`p15_bugs_test.dart`, un-skipped by 2a) are green
too, and this stage added **40 new tests** — 33 of them on code that did not
exist at iteration 1.

---

## 2. Tests added this iteration (40)

Three groups: the new `ProfileRow` component, the new selection/cascade/clock
logic, and the review findings the build closed.

### `child_profile_row_test.dart` — NEW, 15 tests

Iteration 2 replaced `NestListRow` with a P15-local `ProfileRow`
(`child_profile_row.dart`) and swapped two row glyphs. Both are new
behaviour:

* **the component** — the 40 px tile carries the tint's background and hands
  its foreground to the caller's glyph builder (radius 12); the trail keeps
  its **intrinsic** width while `.list-main` takes the remainder
  (`.list-main{flex:1}` / `.list-trail{flex-shrink:0}`); `minHeight: 56` is a
  floor (an 80 px trail grows the row); no `leading` ⇒ no tile; one labelled
  button whose tap — and whose `performAction(SemanticsAction.tap)` — reach
  the same `onTap`; `semanticLabel` overrides the title announcement.
* **ORCHESTRATOR item 2, the two glyphs** — the Quests row's tile holds
  `NestIcons.quests`, and the test reads the asset off disk to prove it *is*
  the design's glyph (`<circle cx="12" cy="12" r="9"/>` + the tick); the
  Pocket-money row holds a bare `SvgPicture.asset(NestlingIllustrations.coin)`
  with **no** `colorFilter` (the illustration keeps its gold fill — asserted
  on the file, `#F4B400`) and **no** `NestIcon` at all, i.e. the `£` glyph is
  gone; the PIN row keeps `NestIcons.lock`. Each glyph's **shape** is measured:
  24 × 24 centred on both axes inside the 40 × 40 tile (the UI-check rule —
  shapes, not just where text lands).
* **ORCHESTRATOR item 1, generalised** — the full width × scale matrix, and
  the column arithmetic that produced the iteration-1 bug:

  | width · scale | PIN sub | Quests sub | Money sub |
  |---|---|---|---|
  | 320 · 1.0 | 117.3 **cut** | 162.1 full | 169.2 full |
  | 320 · 1.3 | 96.1 **cut** | 179.4 **cut** | 179.4 **cut** |
  | 390 · 1.0 (design) | 171.2 full | 162.1 full | 169.2 full |
  | 390 · 1.3 | 166.1 **cut** | 210.8 full | 219.9 full |
  | 430 · 1.0 | 171.2 full | 162.1 full | 169.2 full |
  | 430 · 1.3 | 206.1 **cut** | 210.8 full | 219.9 full |

  At the design's own width and scale **nothing** is cut; the remaining cuts
  are the CSS's own `nowrap` + `text-overflow: ellipsis` fallback
  (`components.css:118`) where the text genuinely cannot fit — see §5. The
  last test pins the geometry itself: every row's column equals
  `row − 12 − 16 − 40 − 2 × 12 − trailIntrinsic`, and at 390 the PIN row's
  column is exactly **187.29 px** — the CSS number, and wider than the longest
  string in the design (171.24 px).

### `child_profile_selection_test.dart` — NEW, 17 tests

The iteration-2 logic contract that `p15_bugs_test.dart` does not already
cover (its six proofs stay where they are, un-skipped and green):

* **`selectChild`** — a valid id lands in `app_state.active_child_id` and
  `watchProfile` follows it; an **unknown id is ignored** (never persisted —
  six kid-mode repositories resolve that column, so junk there is P15-BUG-7's
  class of damage) and the roster fallback still holds; an unknown id *after*
  a valid one does not clear the good one; overlapping requests — last write
  wins (`family_repository_impl.dart:352`).
* **`FamilyChildSelected`** — forwards the id to the repository and emits no
  state (a successful selection is persisted, not state); a **throwing**
  `selectChild` reports the error and leaves `status: loaded` (the only branch
  of the new event with no other proof).
* **`clearErrorMessage`** — the flag drops a message `copyWith` cannot express
  (a literal `null` keeps it), an unrelated emission keeps it, and two
  identical remove failures emit **three distinct states** (raise → clear →
  raise) so `BlocListener.listenWhen` sees a change on both. Stage 6 proved
  the bloc half of the same fix; this is the state-level sequence the view
  listener depends on.
* **the injectable clock**, driven explicitly (no global
  `Seed.anchorOverride` mutation): Maya's four counted completions are two
  `daily` (3 Oct) and two `weekly` (1–2 Oct), so the count walks
  **4 → 2 → 0** as the clock crosses a London day and then a London week —
  the PERIODS ruling, with the clock as the only input. A companion test
  proves the clock touches nothing else (roster, 4 daily / 2 weekly, £4.20
  all identical at a clock eight days out).
* **the remove cascade's two remaining branches** — a family-wide quest
  (`assignee_child_id` NULL) **survives** and keeps its NULL assignee while
  the other child's quests stay; removing the selected child repoints
  `active_child_id` at the **first remaining child in ADDED order**; removing
  the last child clears it to NULL; removing a *non-selected* child moves the
  selection to the roster's first child and leaves the rest of the data alone;
  the profile always names a child that is in the roster, and each child's
  numbers come from their own rows (Maya £4.20/120 coins/stage 3, Leo
  £2.10/45/stage 2).

### `child_profile_view_test.dart` — +7 tests

* **P15-BUG-3, user-visible half** — a *second* identical remove failure
  raises its own toast (2b's proof covers the first; the 3 s snackbar is
  retired between attempts because it floats over the last row and would
  swallow the next tap).
* **review finding 5** — the child's name is announced as a **heading**
  (`SemanticsFlags.isHeader` on the name's node), like every other screen's
  title.
* **review finding 6** — a long nickname **wraps and grows the hero** instead
  of truncating (the design's `h1` has no `nowrap`), the card is taller than
  164, the name is never cut, the 390/one-line case still yields the exact
  164 px band the geometry proofs pin, and a 30-character name at 320 × 1.3
  stays inside its three-line cap with no overflow.
* **the deep-link ordering contract** — the requested child is never preceded
  by the active one: pumping `/child-profile?childId=leo` and watching frame
  by frame, `Maya` must never appear, not even for one frame (the repository
  records the request synchronously precisely so this holds).
* **the second deep link** — see P15-BUG-9 below (red).

### `child_profile_states_test.dart` — +1 test

`Seed.empty()` + `?childId=leo`: the route now dispatches
`FamilyChildSelected` before the first load, so with no children the request
must be dropped — the empty state renders, no spinner is left behind, and its
CTA still reaches `/add-children`.

---

## 3. Gates (run in `app/`)

```
$ dart format .
Formatted 495 files (1 changed) in 8.10 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 14.8s)

$ flutter test
03:01 +2531 ~3 -1: Some tests failed.
```

Per file (`flutter test test/features/family/<file>`):

| File | Result |
|---|---|
| `child_profile_view_test.dart` | **+24 −1** (red = P15-BUG-9) |
| `child_profile_bloc_test.dart` | +23 |
| `child_profile_copy_test.dart` | +20 |
| `child_profile_theme_size_test.dart` | +17 |
| `child_profile_selection_test.dart` | +17 (new) |
| `child_profile_row_test.dart` | +15 (new) |
| `child_profile_states_test.dart` | +12 |
| `p15_bugs_test.dart` (stage 6) | +6 ~2 (its two new `skip:` proofs are stage 6's, not this stage's) |
| `add_children_test.dart` / `p05_bugs_test.dart` / `p05_view_metrics_test.dart` | +119 / +12 / +4 |
| **family total** | **+269 ~2** |

The single suite failure is the P15-BUG-9 repro below. The 3 skips are: 2 in
`p15_bugs_test.dart` (stage 6's `skip: true` markers) and 1 pre-existing in
another feature. **This stage skipped, deleted and weakened nothing**, and
made no `analysis_options.yaml` change; no `google_fonts` anywhere.

---

## 4. Bug found

### P15-BUG-9 — major — the deep link only works on the FIRST entry

`app/lib/features/family/family_routes.dart:31-53`: the fix dispatches
`FamilyChildSelected` from the route's **`BlocProvider(create:)`**, which runs
once per route *instance*. The Family tab lives in a
`StatefulShellRoute.indexedStack` (`app/lib/router.dart:129-140`), so the
`/child-profile` page stays **mounted** after you leave it. Re-entering with a
different `?childId=` re-uses the same page key, the builder never runs again,
no selection is dispatched — and the screen keeps showing the child it was
already showing.

**Repro (user path).** `/today` → tap **Leo's** card (opens Leo's profile) →
tap the **Today** tab → tap **Maya's** card. The URL is
`/child-profile?childId=maya` and the screen shows **Leo**: "Age 4–6 · Pip is
a Hatchling", Leo's `PipAvatar` (bolt · sky · stage 2) and
"Remove **Leo** from family". Stage 6 reported the same defect
(`p15_bugs_test.dart`, P15-BUG-9a/9b, currently `skip:`-marked); this stage
reproduced it independently from the Today tab, so the finding does not rest
on one stage's file.

**Proof.** `child_profile_view_test.dart` → *BUG P15-BUG-9: a SECOND deep link
must switch the profile* (red: expected `maya`, actual `leo`).

**Impact.** Any second "open this child" navigation inside one app session
shows the wrong child — the same wrong-child-personal-data class as P15-BUG-1,
which this fix was meant to close.

**Fix direction (P15-local).** The selection has to follow the *route*, not
the route's construction: either listen to `GoRouter.of(context).routerDelegate`
/ `GoRouterState` inside `ChildProfileView` (or a thin
`BlocListener`-style wrapper that dispatches `FamilyChildSelected` whenever
`state.uri` changes while mounted), or move the dispatch into the bloc's load
handler and pass the id through a `FamilyBloc` constructor argument that is
refreshed on navigation. A `GoRoute` `redirect` that rewrites the location
would also re-key the page, but it must not fight the parent's own state.

---

## 5. Checked and found sound (no finding)

* **The design ellipsises too.** `.list-sub` is `white-space: nowrap` +
  `text-overflow: ellipsis` (`components.css:118`), so a string that cannot
  fit the column is cut **by the design's own rule**. Measured (table in §2),
  the only remaining cut at scale 1.0 is the PIN subtitle at 320, where the
  CSS column is 117.29 px and the string is 171.24 px. At text scale 1.3 (no
  design exists at 1.3) the same graceful fallback applies; the titles are
  never cut, nothing overflows, and the trail keeps its intrinsic width. Not
  a finding — recorded so the next UI stage does not re-flag it.
* `Seed.empty()` (no children, with and without a deep link), `Seed.demo()`
  selection fall-through, and each child's own Pip look.
* Tap targets: rows ≥ 56, danger 48, modal buttons 48, `Try again` and the
  empty CTA ≥ 44 — in both themes and at 1.3.
* Every interactive node exposes `SemanticsAction.tap`; `performAction(tap)`
  drives the real navigation, the real modal and the real repository write;
  every `isImage` node is labelled in both themes.
* Copy is character-exact against the HTML source (U+2013 / U+00B7 / U+203A /
  U+00A3), no `NestType` tracking added, tokens only, no hard-coded colours.

## 6. ORCHESTRATOR_NOTES.md — all four items

1. **Subtitles in full, trail at intrinsic width** — proved at the design's
   width and scale, plus the column arithmetic and the whole matrix
   (`child_profile_row_test.dart`); the 390 citation `2_build.md` makes is
   still green in `child_profile_theme_size_test.dart`.
2. **Row icons** — proved by asset identity (`ic_quests.svg` contains the
   design's `<circle r="9"/>` + tick) and by the coin illustration with no
   tint filter; both glyphs measured as 24 px boxes centred in their tiles.
3. **Pronoun "their"** — unchanged, per the note.
4. **DB quest counts** — unchanged, per the note (4 / 4 daily / 2 weekly).

---

## 7. Verdict

`dart format` clean, `flutter analyze` **No issues found**, 2531 tests pass and
every iteration-1 red proof is now green — but the stage found one new
**major** bug (P15-BUG-9: the `?childId=` deep link is honoured only on the
first entry to an already-mounted route, so a second navigation shows the
wrong child, including the Remove button). The brief's PASS bar is "all tests
pass and no bugs were found".


## From 4_review.md
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


## From 6_bugs.md
# P15 · Child profile — bug hunt (Stage 6, iteration 2)

Route `/child-profile` (`FamilyRoutePaths.childProfile`) · feature `family` ·
parent mode · designs `design/screens/{light,dark}/P15-child-profile.png` ·
tree tested: iteration-2 checkpoint **`31a44b8`** ("P15: checkpoint after
build (iteration 2)"), main merged through `17a21b6`.

Sources re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md`, `FIXES_1.md`, `SHARED_REQUEST.md`, `ORCHESTRATOR_NOTES.md`
(exists — all four items mandatory and re-checked below), plus the
iteration-2 sources (`family_repository_impl.dart`, `family_routes.dart`,
`family_bloc.dart`, `family_state.dart`, `child_profile_row.dart`,
`child_profile_body.dart`, `child_profile_copy.dart`, `child_profile_view.dart`).

Method: iteration 1's six proofs are un-skipped and green (regression guards);
the adversarial pass for this iteration re-probed every fixed area, then
targeted the new code — the deep-link selection, the remove cascade, the
injectable clock and the new P15-local `ProfileRow`. Every red probe is
written as a skipped proof in `app/test/features/family/p15_bugs_test.dart`
with its bug id, so this stage adds no red to the suite.

**Result: iteration-1 bugs all verified fixed; 1 NEW major bug (P15-BUG-9).**
**VERDICT: FAIL** (the brief's PASS bar is "no major bugs").

| Id | Iteration-1 status | Independent evidence on `31a44b8` |
|---|---|---|
| P15-BUG-1 (major) | **FIXED** | `?childId=` selects on the first navigation (`P15-BUG-1a/b` green); probes A2/A3 show the URI and the first deep link work — see P15-BUG-9 for the repeat case |
| P15-BUG-3 (minor) | **FIXED** | clear-then-raise re-emits both failures (`P15-BUG-3` green; test stage's state-level proof green) |
| P15-BUG-6 (major) | **FIXED** | `removeChild` cascade: no dependent row survives (`P15-BUG-6` green; probe J: no approval rows outlive the child; family-wide quests survive per the test stage's proof) |
| P15-BUG-7 (major) | **FIXED** | `active_child_id` repointed to the first remaining child (`P15-BUG-7` green) |
| P15-BUG-8 (major) | **FIXED** | injectable clock follows the pinned anchor (`P15-BUG-8` green); explicit-clock seam covered by the test stage's file |
| P15-BUG-9 (major) | **NEW** | repeat `?childId=` navigation is ignored while the Family branch page is alive — below |

The parallel stages' iteration-1 findings are also closed: the test stage's
P15-BUG-2 (double failure report), P15-BUG-4 ("Pip is a Egg") and P15-BUG-5
(`NestListRow` starvation) proofs are green, and `5_ui.md` (iteration 2)
PASSes with every band within ±2 px and the icons/subtitles fixed.

---

## P15-BUG-9 — major — a later `?childId=` is ignored while the Family branch page is alive

**Repro (user paths).**

1. Open the Family tab (`/child-profile`), then switch to Today and tap
   **Leo's** card. P15 shows **Maya** (the previous selection); the router URI
   says `?childId=leo`.
2. From Today, tap **Leo's** card, switch back to Today, tap **Maya's** card.
   P15 still shows **Leo**.
3. Router-level: `go('/child-profile?childId=leo')`, then
   `go('/child-profile?childId=maya')` — still Leo.

This is the common in-app flow: once the parent has looked at the Family tab
(or any child profile), every later kid-card tap on Today opens the *previous*
child's profile — wrong-child personal data, the same harm class as
iteration 1's P15-BUG-1.

**Evidence (probes on `31a44b8`, real Drift + shell).**

* probe-A: `go('/child-profile?childId=leo')` → Leo ✓; then
  `go('/child-profile?childId=maya')` → rendered child still `leo` ✗.
* probe-A2 (diagnostic): after the second `go`,
  `GoRouter.state.uri.queryParameters['childId'] == 'maya'` **but** the
  rendered `ChildProfileBody.profile.child.id == 'leo'` — the router knows the
  new id; the screen never hears it.
* probe-A3: start on `/child-profile` (Maya), tab to Today, tap Leo's card →
  still `maya` ✗ (the deep link is ignored even on its first use, if the
  branch page already exists).
* probe-B (full user path): Leo card → tab Today → Maya card → still `leo` ✗.

**Root cause.** `family_routes.dart:42-50` dispatches `FamilyChildSelected`
inside `BlocProvider.create`, which runs **once per route page**. With
`StatefulShellRoute`, the Family branch page stays alive; a later
`go('/child-profile?childId=…')` updates that existing page in place (same
route/page key), so `create` does not re-run and the new query never reaches
the bloc. The repository side is fine: `selectChild` and `_pendingSelection`
work whenever they are called (probes G/H green).

**Failing tests.** `p15_bugs_test.dart` → `P15-BUG-9a` (Family tab first, then
Leo's Today card) and `P15-BUG-9b` (Leo, then Maya). Both RED on `31a44b8`,
currently `skip: true` so the suite stays green until the build fixes them.

**Suggested fix.** React to the route's query changes instead of only to page
creation — e.g. keep `BlocProvider` in the builder and put a small stateful
wrapper between it and `ChildProfileView`:

```dart
class _ChildProfileRoute extends StatefulWidget {
  const _ChildProfileRoute({required this.requested});
  final String? requested;
  ...
}
// initState + didUpdateWidget: when `requested != null` (and changed),
// context.read<FamilyBloc>().add(FamilyChildSelected(childId: requested));
```

`FamilyLoadRequested` still goes through `create` once; `selectChild` is
idempotent and membership-gated, so re-dispatching on updates is safe.
Alternative: have the view watch `GoRouterState.of(context)` in
`didChangeDependencies` and dispatch when the id changes.

**Impact.** Wrong child's profile (PIN state, coins, owed money, Pip, and the
remove action) in the most common navigation flow, whenever the Family branch
has been visited before.

---

## Verified sound (iteration-2 probes on `31a44b8`, all green)

| Probe | Result |
|---|---|
| P15-BUG-1a/b, 3, 6, 7, 8 (iteration-1 proofs, un-skipped) | all green — the fixes are real |
| P11 fallout: after removing Maya, her approval rows are gone (probe J) | ✓ |
| Unknown `?childId=` after a valid one falls back to the roster (probe C) | ✓ |
| 6 children, deep link to the 6th (probe D) | ✓ renders, no exception |
| Back from `/kid-pin` keeps the deep-linked child (probe E) | ✓ |
| Long name (`Maximilian-Alexander`) at 320 × 1.3 after the hero wrap change (probe F) | ✓ no overflow |
| Overlapping `selectChild` calls: last request wins, none persists a removed child (probes G/H) | ✓ |
| Deep-linked selection survives an app re-pump (probe I) | ✓ persisted |
| `selectChild` failure after `bloc.close()` (probe K) | ✓ no unhandled emit-after-close |
| Icons: `ic_quests.svg` is exactly the design's circle r9 + check; `NestlingIllustrations.coin` = `assets/illustrations/coin.svg` (the design's `coin.svg`) | ✓ (also confirmed visually by `5_ui.md` iteration 2) |
| ORCHESTRATOR_NOTES item 1 (full subtitles at 390) | ✓ test stage's `didExceedMaxLines` proof green; UI stage measured no `…` |
| ORCHESTRATOR_NOTES items 2/3 (circled check, coin) | ✓ assets verified; UI stage PASS |
| ORCHESTRATOR_NOTES item 4 (pronoun "their", DB quest counts) | ✓ not reported as findings anywhere here |
| Double-tap / rapid confirm, dark mode, kid-mode guard, money rounding, empty states | ✓ unchanged, covered by the green suite |
| Simulator policy | no simulator was booted, installed on, screenshotted or driven in this stage ✓ |

## Gates (run in `app/` on `31a44b8` + this stage's file)

```
$ dart format test/features/family/p15_bugs_test.dart
Formatted 1 file (0 changed) in 0.01 seconds.

$ flutter test --no-pub test/features/family/p15_bugs_test.dart
00:03 +6 ~2: All tests passed.        # six regression guards + two skips

$ flutter test --no-pub test/features/family        # snapshot ~19:40 BST
00:10 +252 ~2 -1: Some tests failed.
```

* The two `~` are this stage's new P15-BUG-9 proofs (skipped by design).
* The one `-1` is **not a product bug and not this stage's file**: the
  parallel test stage's in-flight
  `child_profile_selection_test.dart` → `P15-BUG-8 · an explicit clock decides
  which period counts` expects `0` one London day after the anchor
  (`31a44b8` gives `2`). Sunday 4 Oct 2026 01:00 London is still inside the
  London week Mon 28 Sep 00:00 – Sun 4 Oct 24:00, so the two weekly
  completions from Thu/Fri **must** count under the PERIODS ruling — the
  product is right and the test's expectation is wrong. Left to the test
  stage (its file was still being written at this snapshot; the suite was
  `+230` green before that file landed).
* `flutter analyze` at the same snapshot reports 10 lint infos, all in the
  test stage's in-flight `child_profile_selection_test.dart` /
  `child_profile_view_test.dart` (unused imports, an underscore local, missing
  EOF newline, …). **No issue is attributed to `p15_bugs_test.dart` or to any
  `lib/` file**; my file is format- and lint-clean.

No production file was changed by this stage: the only additions are the two
skipped P15-BUG-9 proofs in `app/test/features/family/p15_bugs_test.dart` and
this document.

