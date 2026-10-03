# Fix list after iteration 3

## From 3_test.md
# P05 · Add children — test notes (STAGE 3, iteration 3)

Route `/add-children`, feature `family`, parent mode. All changes are in
`app/test/features/family/add_children_test.dart` — no screen code touched.

Two new orchestrator rulings arrived this iteration (**CHILD ORDER**, **COPY**)
plus four mandatory items in `ORCHESTRATOR_NOTES.md`. All four are now covered
by tests. P05's own suite is fully green (108 tests), but **the full
`flutter test` run is red on one shared test** that asserts P05's pre-build
placeholder copy — outside RULES §1, filed in `SHARED_REQUEST.md`. Hence FAIL.

## Tests added (9, in `add_children_test.dart`)

### COPY — character-exact against the HTML (ruling + note 3)

Compared every P05 string with
`design/html-source/screens/P05-add-children.html` after decoding the entities
(`&rsquo;` → U+2019, `&mdash;` → U+2014, `&ndash;` → U+2013). The only strings
the app does not hold as literals are composed from the database band
(`Age 7–9`, `4–6`…) via `displayAgeBand`; all other literals match exactly, and
the iteration-3 build's `’` fix is confirmed in the rendered output. Pinned by:

1. the h1 is `’` (U+2019), asserted by code unit, with a guard that no ASCII
   `'` remains;
2. the subtitle keeps the em dash (U+2014), `findsNothing` for any ASCII
   hyphen anywhere on screen, `Avatar colour` present and `color` absent (UK
   spelling);
3. every chip label and both card ages use en dashes (U+2013) and the hyphen
   forms never render;
4. a pure unit guard on the conversion boundary: the seed stores `7-9`, the UI
   shows `7–9`, `13+` passes through unchanged.

### CHILD ORDER — the grid follows the repository (ruling + note 2)

P05 must show children in the order they were added and must never sort
locally. Core still orders `watchChildren` by `nickname`
(`app_database.dart:310`) and the table has no creation marker, so the ruling
cannot be satisfied inside RULES §1 (blocking shared request filed by the build
stage). The tests therefore pin the invariant that makes the ruling true the
moment the shared fix lands, without hard-coding either order:

5. the grid renders the bloc's roster verbatim (reading order: row by row) —
   passes today with Leo-before-Maya and will pass unchanged with
   Maya-before-Leo;
6. a child saved in-test lands exactly where the repository puts it (3 cards, 2
   rows — also exercises the row-major reading order);
7. the bloc never reorders: fed `[Maya, Leo]` and `[Leo, Maya]` it stores each
   list untouched.

Two harness facts worth recording: `FamilyBloc` is a GetIt **factory**
(`family_di.dart:19`), so `GetIt.instance<FamilyBloc>()` is an empty bloc — the
order must be read from `BlocProvider.of<FamilyBloc>` on the rendered grid; and
`watchChildren().first` never resolves under the shared test scope (2_build.md
deviation 6), so the same accessor is used.

### Note 4 — focused nickname field

8. unfocused: the field's wrapper `Container` has no `boxShadow`; focused: it
   equals `NestShadows.focusRing(tokens.leafTint, tokens.leaf)` and the
   `InputDecoration.focusedBorder` (an `OutlineInputBorder`) side is
   `tokens.leaf`; unfocusing removes both. The finder is scoped to the field's
   own container because the card and the selected swatch carry shadows too.

### Note 1 / P05-BUG-8 — the fix's user-visible symptom

9. with iPhone-class insets (`view.padding` + `view.viewPadding` = 47/34
   logical) and the seed's two children, scrolling to the end leaves the
   closing note **above** the CTA. That is precisely what the missing
   `padding: EdgeInsets.zero` broke: the grid re-applied 47 + 34 px of
   MediaQuery padding as its own `SliverPadding` and pushed the tail of the form
   under the bar, where scrolling could not lift it clear. The gap proof
   (14.0 / 12.0 with insets present) already lives in `p05_bugs_test.dart`.

## Results

```
dart format .        clean (362 files, 0 changed)
flutter analyze      No issues found!                       (full app)
flutter test test/features/family/    00:04 +108: All tests passed!
flutter test (full suite)             1 failure — app/test/app/router_push_test.dart
```

99 tests in `add_children_test.dart`, 9 in `p05_bugs_test.dart`, **zero skips**
in both files.

## Bugs found

### 1. Shared contract test still asserts P05's placeholder title (red repo gate)

`app/test/app/router_push_test.dart:104` passes `showsFrom: 'P05 Add children'`
— the string the **placeholder** view rendered before P05 was built. The real
screen shows `Who’s in your nest?`, so `router_push_test.dart:37` fails:

```
00:01 +3 -1: push/pop contract push between top-level onboarding routes,
pop returns [E]
Expected: true   Actual: <false>   … router_push_test.dart line 37
```

Not a P05 regression and not fixable here:

* `'P05 Add children'` appears nowhere in `app/lib` — only in that test;
* the file arrived from **main** (`7eaa1f7`, "Shared requests batch 1 … +
  contract tests" — the batch that answered P05's push/pop investigation), and
  it was written while P05 was still a placeholder;
* this worktree has never touched `app/test/app/**` or `app/lib/app/**`
  (`git status` on both paths is empty), and both are outside RULES §1.

Fix is one string: `showsFrom: 'Who\u2019s in your nest?'`. `showsTo:
'P06 Pocket money setup'` is still correct
(`pocket_money_setup_view.dart:12`), and the test pushes on the router itself,
so it does not depend on how P05 navigates. Filed in `SHARED_REQUEST.md`
("Blocks: yes for the repo gate").

### No P05 screen bugs

The two findings that would have blocked the UI gate are closed and proved:

* **Iteration-2 open item — the vertical rhythm around the kid grid is
  RESOLVED.** My measurement (+45 px above the grid, +34 px below, form card
  +89) was handed to the UI stage, which traced it to the grid re-applying the
  device safe-area insets as its own `SliverPadding`; `padding:
  EdgeInsets.zero` fixes it, and the BUG-8 proof now measures exactly 14.0/12.0
  with insets present, plus my new reachability test.
* **Iteration-1 P05-BUG-1/2 and iteration-2 P05-BUG-4/5/6/7/8** all have
  un-skipped proofs in `p05_bugs_test.dart` and are green.

## Still open (not a test-stage action)

* **CHILD ORDER ruling is not yet satisfied in data.** P05 renders the
  repository order verbatim, but that order is alphabetical today, so the
  screen shows **Leo before Maya** while the ruling wants Maya first. The
  invariant tests above hold either way and will start proving the ruling
  itself the moment core orders by creation; the blocking shared request for
  that (createdAt column or rowid ordering) is already filed.
* **`NestChip` full-width `Center`** (`nest_chip.dart:74`) is still unfixed at
  the design-system level; P05 works around it with `IntrinsicWidth`. Any new
  screen that puts interactive chips in a `Wrap` will hit the same defect.
* **Nickname autofocus**: the design mock shows the field focused; the screen
  launches unfocused (per review, no screen autofocuses). The focus *ring*
  tokens are now pinned by test 8.


## From 4_review.md
# P05 · Add children — QA code review (STAGE 4, iteration 3)

Scope reviewed: `git diff main...HEAD` + the working tree for `screen/P05`
(RULES §1 paths only). No product code was edited in this stage; one throwaway
ordering probe (`app/test/features/family/zz_probe_tmp_test.dart`) was created
and deleted.

Reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P05, `docs/design/SPACING_SPEC.md`, the design system
(including what landed from main in `7eaa1f7`), both design PNGs, the HTML
source, and `docs/screens/P05/ORCHESTRATOR_NOTES.md` (all items checked below).

Gates re-run independently in this stage:

```
dart format --set-exit-if-changed .   → 362 files, 0 changed
flutter analyze                        → No issues found!   (full app)
flutter test test/features/family     → 00:04 +108: All tests passed!
flutter test (full suite)              → 1 failure, in a SHARED file:
   app/test/app/router_push_test.dart: "push between top-level onboarding
   routes, pop returns" (asserts P05's pre-build placeholder title)
grep -c "skip:" test/features/family/*.dart → 0 / 0
git status → features/family/{presentation,data}, test/features/family,
             docs/screens/P05   (all RULES §1; nothing in core or app/)
```

**Result: 1 blocker (merge gate, shared file, outside RULES §1), 1 major,
4 minor, 0 findings against the P05 diff's own quality. The iteration-2 major
(P05-BUG-8, the grid re-applying the device insets) is fixed and proved; the
new major is the standing CHILD ORDER ruling, which this screen still does not
satisfy — and which I have now proved is fixable inside RULES §1.**

---

## Findings

### 1. BLOCKER (repo gate, not a P05 code defect) — the full `flutter test` run is red on a shared test that asserts P05's placeholder copy

`app/test/app/router_push_test.dart:104` passes `showsFrom: 'P05 Add children'`.
P05 is no longer the placeholder, so the assertion at
`router_push_test.dart:37` (`find.text(showsFrom)` is non-empty) fails.

I reproduced it here:

```
00:01 +3 -1: push/pop contract push between top-level onboarding routes,
pop returns [E]
Expected: true   Actual: <false>   … router_push_test.dart line 37
```

Not attributable to the P05 diff, and not fixable by a screen agent:

* `'P05 Add children'` appears nowhere in `app/lib` — only in that test;
* the file arrived from **main** in `7eaa1f7` ("Shared requests batch 1 …
  + contract tests"), written while P05 was still a placeholder;
* `app/test/app/**` and `app/lib/app/**` are both outside RULES §1, and this
  worktree has never touched them (`git status` on both paths is empty).

It is correctly escalated in `SHARED_REQUEST.md:171-206` with the right fix
(`showsFrom: 'Who’s in your nest?'` — note the U+2019 now in the view). I
record it here because the suite must be green before this branch lands
(RULES §7), and because a reviewer reading only the stage notes would
otherwise be told the suite passes. It does not change the P05-diff verdict;
it needs a shared batch.

### 2. MAJOR — the CHILD ORDER ruling is not satisfied, and the interim it asks for is implementable inside RULES §1

`app/lib/features/family/data/family_repository_impl.dart:37-41` (consumes
`_db.watchChildren(...)`, which orders by `nickname` at
`app/lib/core/data/app_database.dart:310`) and
`app/lib/features/family/presentation/widgets/kid_card_grid.dart:13-16` (the
`TODO(P05)` deferral).

`ORCHESTRATOR_NOTES.md` iteration 3, item 2, is mandatory and says: children are
always listed **in the order they were added (Maya first, then Leo), never
alphabetically — in every screen and repository**; *"if the children table
lacks a usable column, file it in SHARED_REQUEST.md **and order by rowid
meanwhile**"*. The shared request was filed (correct — it is the durable fix,
and the table genuinely has no `createdAt`: `app_database.dart:51-81`). But the
interim ordering was not implemented, and `2_build.md:75-79` asserts it *"cannot
be done in RULES §1 … so no local sort can recover insertion order"*.

**That claim is wrong, and I verified the fix end to end.** The family
repository impl *is* an allowed path (RULES §1: `domain/** + data/**`) and is
handed the database by DI (`app/lib/features/family/family_di.dart:13` →
`FamilyRepositoryImpl(db: sl<AppDatabase>())`), so it can run its own ordered
query instead of the core helper. Drift 2.35.1's `OrderingTerm` takes a plain
`Expression` and `package:drift/drift.dart` exports `CustomExpression`, so:

```dart
// app/lib/features/family/data/family_repository_impl.dart  (data/** = RULES §1)
Stream<List<ChildrenData>> _watchChildrenInAddedOrder() {
  return (_db.select(_db.children)
        ..where((c) => c.familyId.equals(Seed.familyId))
        ..orderBy([
          (c) => OrderingTerm(
            expression: CustomExpression<Object>('rowid'),
          ),
        ]))
      .watch();
}
```

Verification (throwaway probe, since deleted):

* `flutter analyze` on the probe: **no errors** — `OrderingTerm(expression:
  CustomExpression<Object>('rowid'))` type-checks inside the generated
  `orderBy([(c) => …])` form.
* Runtime against the seeded demo DB: `ROWID ORDER: [Maya, Leo]` — the ruling's
  order, and the design PNG's order. (The nickname-ordered stream the screen
  consumes today yields `[Leo, Maya]`; the iteration-2 UI stage measured the
  rendered result as "Leo | Maya" against a "Maya | Leo" mock.)

Impact if left as is: the screen renders the roster in the one order the
ruling forbids, against the design mock, and the fix is one query away. Cost
of doing it in-feature: a short-lived duplicate of a query the shared fix will
retire — which is precisely what an interim is for.

Fix: implement the rowid-ordered watch above (keep the filed shared request as
the permanent fix), drop the `TODO(P05)` deferral in `kid_card_grid.dart`, and
replace the order-pinning test at
`add_children_test.dart:1487-1501` (finding 4).

### 3. MINOR — the `IntrinsicWidth` chip workaround is now dead weight, and its comment (and one test note) claim a bug that main already fixed

`app/lib/features/family/presentation/widgets/add_child_form_card.dart:78-90`
— *"until the shared fix lands"* — plus `docs/screens/P05/3_test.md:136-138`
(*"`NestChip` full-width `Center` (`nest_chip.dart:74`) is still unfixed"*).

The shared fix landed in `7eaa1f7`: `app/lib/core/design_system/components/nest_chip.dart:65-108`
no longer has the greedy `Center` at all — the interactive branch is
`Material → InkWell → ConstrainedBox(minWidth 44) → Padding(4.5) → Ink(pill)`,
which shrink-wraps by construction (the comment in that file names P05 as the
motivation). The wrappers are now redundant work (an intrinsic-dimension pass
per chip per layout) guarding nothing, and both comments mislead the next
reader — and P15, which imports this feature.

Fix: drop the four `IntrinsicWidth` wrappers (keep the `Semantics` group),
re-run the BUG-1 geometry proofs — they assert the *mechanism* ("no box claims
the run", "at most two rows") and must still pass — and delete the stale claim
from `3_test.md`. The remaining chip question is the DS one already filed: the
44-tall tap box against the design's 32 visual (+12 in the UI check), which is
shared, not P05.

### 4. MINOR — a test pins the alphabetical order the ruling forbids

`app/test/features/family/add_children_test.dart:1487-1501`
(`'roster order comes from the database (nickname order)'` asserts
`leo.left < maya.left`).

It passes today *because* the ruling is unsatisfied, and it will fail the day
the shared fix lands. The new invariant tests added this iteration
("the grid renders the bloc's roster verbatim", "the bloc never reorders") are
the right shape; this older one contradicts them.

Fix: delete it, or invert it to `maya.left < leo.left` when finding 2's interim
lands.

### 5. MINOR — `cardH` reserves 10 px of pencil clearance the design does not have, against a design with zero vertical slack

`app/lib/features/family/presentation/widgets/kid_card_grid.dart:24-31` — the
computed height ends in a trailing `NestSpacing.gap10` "pencil clearance".

The design does not have it: `.kid-card { padding: 12px 10px 10px }` over
44 + 2 + 24 + 4 + 18 = ~113/114 tall, and `.edit` is `position: absolute` —
the 44 px pencil overlays and adds no height (`5_ui.md` measured app 124 vs
design ~113). This is now the largest P05-local vertical error left, and it
matters more than 11 px: the iteration-2 UI stage computed that the design
fits with **zero slack** (content ends 645, CTA top 644), so P05's 10 px plus
the DS chip's +12 push the closing note "We only ask for an age range so quests
suit them." to or under the CTA bar. The UI stage flagged it as optional; the
next UI check will show it.

Fix: drop the trailing `gap10` from `cardH` (the `Positioned` pencil needs 45 px
of headroom inside a 124 px card and more than that inside a 114 px one, so
keep the pencil assertion in the geometry test that already exists).

### 6. MINOR — the build notes' feasibility claim is wrong (documentation, but it is what will be read next)

`docs/screens/P05/2_build.md:75-79` and `3_test.md:130-135` both assert the
CHILD ORDER ruling cannot be satisfied inside RULES §1. Per finding 2 it can.
Stage notes are part of the screen's record, and a wrong feasibility claim
here is what caused a whole iteration to defer.

Fix: correct both to match finding 2 (the shared request stays; the interim is
rowid ordering inside `features/family/data/`).

### 7. MINOR — carried from iteration 2, accepted with stated reasons (no new action, listed so the delta is explicit)

* **Iteration-2 finding 4** — a "Continue" tapped inside the save frame is
  dropped with no feedback: intended; buttons disable for the whole save and
  the design has no "still saving" state.
* **Finding 5** — `FamilyAddChildRequested.onSaved` still carries navigation
  into the bloc: deferred until P15 lands (changing the signature would touch
  a shared member).
* **Finding 6** — `presentation/widgets/child_display.dart` holds no widgets:
  accepted (a feature-private mapper; ARCHITECTURE forbids extra *folders*).
* **Finding 9** — the failure panel shows `error.toString()`: app-wide pattern
  (P08 identical); orchestrator decision if it should change.
* **Finding 10** — `Positioned(top: 1, right: 1)`: signed off as a faithful
  mirror of `.edit { top: 1px }`; no 1 px step exists in `NestSpacing`.

---

## Iteration-2 findings — closed

| # | Finding | State |
|---|---|---|
| 1 | MAJOR · grid re-applied the device insets (P05-BUG-8), grid +47 / form +89 | **fixed** — `padding: EdgeInsets.zero` on the inner `GridView.builder` (`kid_card_grid.dart:36-40`), with an un-skipped proof that measures exactly 14.0/12.0 with 47/34 insets present, plus a reachability test that scrolls to the end with the closing note above the CTA. This closes the mystery I flagged in iteration 2 ("a `const SizedBox(height: 14)` cannot measure 60 on a device") — the UI stage traced it to the nested scroll view re-applying the ambient MediaQuery insets as its own `SliverPadding`, exactly as suspected. |
| 2 | MINOR · single-row chips only provable on the simulator | **resolved** — the shared chip fix landed; see finding 3 for the leftover wrapper. |
| 3 | MINOR · proof name promised no-scroll visibility | **fixed** — renamed to `… are selectable after scrolling`, body unchanged. |
| 7 | MINOR · `copyWith` could never clear `lastSavedNickname` | **fixed** — `_keepLastSavedNickname` sentinel (`family_state.dart:11-14, 57, 71-73`). |
| 8 | MINOR · unknown `avatar_colour` invisible | **fixed** — `debugPrint('P05 unknown avatar colour: $raw')` with the neutral fallback kept (`child_display.dart:11-22`). |
| 4/5/6/9/10 | accepted with reasons | carried as finding 7 above. |

## Orchestrator items (`ORCHESTRATOR_NOTES.md`, iteration 3 — all mandatory)

1. **Grid inherits the MediaQuery insets → `padding: EdgeInsets.zero`; cards
   ~16 px under the subtitle, "Add a child" top ≈ y 399.** Done
   (`kid_card_grid.dart:36-40`), proved with insets in the test, and the UI
   stage re-measures this iteration. No local patch of the shared header, per
   item 3 of the previous block ✓.
2. **CHILD ORDER (creation order, never alphabetical; order by rowid
   meanwhile).** **Not satisfied — finding 2.** The escalation is right; the
   interim is not implemented and is feasible in an allowed path.
3. **Copy: curly `’` (U+2019).** Done (`add_children_view.dart:198`), pinned by
   a code-unit test with a guard against any remaining ASCII `'`. I re-read
   every P05 literal against the HTML entities (`&rsquo;`, `&mdash;`,
   `&ndash;`): all other strings were already character-exact, including
   `Avatar colour` (UK) and the em dash.
4. **Nickname field: focused ring = leaf token; unfocused launch state is fine.**
   Done (`add_children_test.dart:1946+`: unfocused wrapper has no `boxShadow`;
   focused equals `NestShadows.focusRing(tokens.leafTint, tokens.leaf)` with
   the `focusedBorder` on `tokens.leaf`; unfocusing removes both), and no
   autofocus was added.

---

## Confirmed clean (no action)

* **RULES §1 scope.** `git status` touches only
  `features/family/presentation/**`, `features/family/data/**` (used once, for
  `ageYears`), `test/features/family/**`, `docs/screens/P05/**`. Nothing in
  `app/lib/core/**`, `app/lib/app/**`, `app/test/app/**`, another feature, or
  `tools/screens/**`. `analysis_options.yaml` untouched; no test skipped.
* **ARCHITECTURE.md.** Feature-first layout intact; one bloc per feature; one
  view per route; feature-private widgets; no use-case classes, no new folders;
  the route still provides the bloc and the view never re-creates it. The
  shared bloc surface stays additive (`lastSavedNickname` only) with no
  renames or signature changes, so P15 merges cleanly.
* **Design-system usage.** `NestStatusBar`, `NestNavBar`, `NestCard`,
  `NestAvatar`, `NestTextField`, `NestChip`, `NestButton`, `NestBottomCta`,
  `NestIcon` — nothing re-implemented, and the new code consumes the *fixed*
  shared chip rather than fighting it. Colours only from `context.nest`, sizes
  only from `NestSpacing` / `NestDevice` / `NestAvatarSize` / DS props, type
  only from `NestType`; the only raw value left is the accepted 1 px pencil
  offset (finding 7).
* **Copy / UK spelling / spec §5 P05.** Character-exact against the HTML after
  decoding entities; "Who's in your nest?" now carries U+2019, the subtitle
  U+2014, the bands and ages U+2013, "Avatar colour" never "color", and no
  ellipsis or non-breaking space is needed by this screen's copy. Age bands
  and avatar colours come from the seeded rows (`seed.dart:152-177`).
* **Owner rules.** Bottom edge: `NestBottomCta` last in the column, its own
  `SafeArea(top: false)` and `tokens.surface` over a `tokens.paper` Scaffold —
  no strip in light or dark (UI stage: CTA top 645 vs design 644, identical
  geometry). Alignment: one `NestSpacing.padSide` gutter on the `ListView`, so
  head, cards, form card, CTA buttons and caption share the same edges; the
  grid column is computed `(W − 40 − 10)/2` per `SPACING_SPEC` §10.2 and the
  inner grid no longer double-counts insets (finding 1 closed).
* **Accessibility.** h1 exposed as a header landmark; `Edit <nickname>` per
  pencil; chip and swatch groups are labelled containers with reachable
  children; swatches are `Material` + `InkWell(CircleBorder)` with
  `selected` semantics (no raw `GestureDetector` left in product code); the
  focus ring is token-driven and now pinned by test; tap targets 44/44/44/48/52.
* **Error handling.** Spinner for `initial|loading`; failure panel + `Try again`
  that releases the failed load before re-subscribing; empty nickname and
  >24 chars rejected inline with no repository call; repository throw → inline
  message + `debugPrint`, form preserved; mid-save typing survives the
  conditional clear.
* **Resource hygiene / performance.** `TextEditingController` + `FocusNode`
  disposed; the only stream is `emit.forEach` and its error path terminates the
  subscription; no `Timer`, `AnimationController` or manual `Listener`. No
  rebuild storm — one `BlocBuilder` over a short list per keystroke, all
  `const`-able widgets are `const`. (Finding 3 also removes an
  intrinsic-layout pass per chip.)
* **Children's Code.** Parent-only screen; no analytics, ads, telemetry or
  network calls; no child data logged; nothing crosses into kid mode and
  kid-mode deep links to `/add-children` redirect to the parental gate. Pip is
  correctly N/A (initial-letter avatars marked `aria-hidden` in the design).
* **Tests.** 108 in `test/features/family/`, zero skips, no weakened bodies,
  every app-pumping test ends with `disposeApp`; nine new tests this iteration
  cover the COPY ruling by code unit, the CHILD ORDER invariants, the focused
  ring, and the BUG-8 reachability symptom.

## For the next stages (not findings)

* **Re-shoot this iteration** (stage 5) with `SEED=onboarding_kids`; the two
  chip/grid fixes should move band-2…5 drift substantially. Expect the ~11 px
  card-height excess (finding 5) and the DS chip's ~12 px tap-box excess
  (finding 3, shared) to be what remains.
* **If the orchestrator wants the card order right before the shared batch
  lands**, finding 2 is a one-query change inside an allowed path — it does not
  need the schema decision first.
* **Do not re-open the `NestChip` width question in P05**: it is fixed on main;
  only the shared 44-tall tap box vs the design's 32 visual is still owed, and
  it belongs to `SHARED_REQUEST.md` #3.


## From 5_ui.md
# P05 · Add children — UI check (STAGE 5, iteration 3)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Shots use `SEED=onboarding_kids` per `ORCHESTRATOR_NOTES.md` (still mandatory; overrides the
brief's `fresh`). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_3.png` → `cmp_light_3.png`, **mean diff 4.87%** (was 5.51%)
- Dark: `docs/screens/P05/ui/app_dark_3.png` → `cmp_dark_3.png`, **mean diff 4.88%** (was 5.76%)

Per-band drift (light): band0 0–105: 1.54% · band1 105–211: 5.08% · band2 211–316: 2.90% ·
band3 316–422: 4.64% · band4 422–527: 5.88% · band5 527–633: 13.49% · band6 633–738: 1.64% ·
band7 738–844: 3.71%. Dark matches within ~1% (band5 14.56%) — one defect, both modes.

Pixel landmarks measured from both PNGs at 3× (÷3 = logical px), light mode:

| element (ink rows) | design | app | Δ |
|---|---|---|---|
| title "Who's" | 113.3–133.0 | 113.3–132.7 | 0 |
| subtitle | 158.3–166.7 | 158.3–166.7 | 0 |
| card names | 254.0–262.7 | 254.0–262.7 | 0 |
| h3 "Add a child" | 334.7–346.7 | 342.7–354.7 | +8 |
| "Nickname" label | 370.0–376.7 | 378.0–384.7 | +8 |
| "Age band" label | 454.0–460.7 | 462.0–468.7 | +8 |
| chip labels | 481.0–490.7 | 494.0–503.7 | +13 |
| "Avatar colour" label | 516.0–522.7 | 536.0–542.7 | +20 |
| swatch row zone | 529–577 | 549–597 | +20 |
| helper caption | 588.0–594.7 | 608.0–614.7 | +20 |
| CTA ("Add another", Continue, caption) | 678 / 716–768 / 781–790 | identical | 0 |
| CTA top (gutter) | 644 | 645 | +1 |

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs and home-indicator pill ignored (OS-drawn).

## Deviations

1. [FAIL — violates design + mandatory ruling] Card order Leo|Maya, must be Maya|Leo.
   Design: Maya (lilac M, Age 7–9) left, Leo (peach L, Age 4–6) right — and the
   CHILD ORDER ruling mandates creation order (Maya, then Leo) in every screen and
   repository. App (both modes): Leo left, Maya right — the DB still sorts by nickname
   (P05-BUG-3). Whole-card swap; band1 drift (5.1–5.3%) is largely this.
   Fix: shared — order children by creation time/insertion order (`rowid` meanwhile);
   P05 consumes the stream as-is (already noted in `SHARED_REQUEST.md`). Not locally fixable
   without forking the repo order (RULES §4 forbids).

2. [FAIL — systematic offset, designer-visible doubling in compare view] Form region sits
   +8 px low through the field, +13 at chips, +20 at swatches/caption.
   Design → app: h3 +8, Nickname +8, Age-band +8, chips +13, Avatar-colour/swatches/caption +20.
   Everything is still above the CTA (caption ends ~615 < CTA 645) and the CTA itself is
   pixel-identical — but no element below the kid cards is within the ±2 px tolerance.
   Components, from code reading (no code changed): card height 124 vs design ~113
   (the 10 px pencil clearance in `cardH`; content is top-aligned, only height differs →
   explains the +8/+11 passage from cards to form); chip box 44 tall vs design `.chip`
   32 visual (tap area stacked, not overlaid → explains the extra +12 from chips down).
   Fix: P05-local — drop the pencil clearance (design overlays the 44 px edit button with
   zero clearance: avatar spans x 63–107 of 170, button x 125–169, no overlap) to recover
   ~11 px; shared — render the 44-min tap area around a 32 px visual (the standing
   `SHARED_REQUEST.md` #3 follow-up) to recover ~12 px. Together the form lands within ±2.

3. [Pass, verified fixed] GridView safe-area padding (iteration-2 finding): card names now
   254.0–262.7 in both — `padding: EdgeInsets.zero` confirmed working. Header pixel-identical
   (shared 52 px compact nav — do not patch). Chips one row, 7–9 selected, in both modes.

4. [Pass] Copy is character-exact vs the HTML source (COPY ruling): curly ’ (U+2019) in
   "Who’s" (code `\u2019`), em dashes (`\u2014`), en-dash age bands, "Avatar colour",
   "e.g. Ollie", both CTA labels, both captions, `Edit <name>` labels. No overflow,
   clipping, or ellipsis faults.

5. [Pass] Owner rules: `NestBottomCta` surface runs to the physical edge in both modes
   (CTA top 644 vs 645; the design's 34 px cream strip under its CTA is the mock breaking
   the rule — the app is correct). 20 px gutters, head/grid/form/CTA on the same edges,
   nothing visibly misaligned. Dark-mode tokens match (surface cards, leaf-tint selected
   chip, mint Continue, correct swatch fills + peach ring).

6. [Accepted — no action] Nickname field unfocused (design shows the focused state;
   orchestrator note 4: unfocused launch is fine). Swatch caption fully visible above
   the CTA in both modes.

## Verdict basis

Deviation 1 breaks a mandatory orchestrator ruling and mirrors the design's card order
exactly backwards — a designer would reject it. Deviation 2 puts every form element
8–20 px off-spec, plainly visible as doubling in the compare heat-map. Both need a further
pass (one shared, one P05-local + one shared follow-up).


## From 6_bugs.md
# P05 · Add children — bug hunt (STAGE 6, iteration 3)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on the
iteration-3 build (working tree after `21a7e02 P05: loop iteration 2`, main
merged through `8de83cb`; iteration-3 fixes uncommitted).

Gates on this build: `dart format` clean · `flutter analyze` No issues found! ·
`flutter test test/features/family` **108 passed, 2 skipped, 0 failed** · full
`flutter test` is **red on one shared test file outside RULES §1**
(`app/test/app/router_push_test.dart`, pre-existing, see *Repo-gate blocker*
below) · no file outside RULES §1 touched.

Proofs: `app/test/features/family/p05_bugs_test.dart` — P05-BUG-1…8 run
un-skipped and green; the two new proofs carry `skip: true` with the id in the
name so the suite stays green. Verified failing with
`flutter test --run-skipped test/features/family/p05_bugs_test.dart`
→ the nine fixed proofs pass, P05-BUG-9 and P05-BUG-10 fail exactly as
recorded.

**Result: 1 major open (P05-BUG-9, the mandatory CHILD ORDER ruling is still
unsatisfied and is fixable inside RULES §1), 1 minor open (P05-BUG-10, kid
card 8 px taller than the design), 0 other new bugs. VERDICT: FAIL.**

---

## P05-BUG-9 — MAJOR — children are still listed alphabetically (Leo | Maya), not in the order they were added (Maya | Leo)

**Where:** `app/lib/features/family/data/family_repository_impl.dart:37-41`
consumes the core helper `_db.watchChildren(...)`, which orders by `nickname`
(`app/lib/core/data/app_database.dart:307-312`), so the grid renders
**Leo left, Maya right** — the reverse of the design and of the mandatory
ruling (“children are always listed in the order they were added … never
alphabetically — in every screen and repository”; iteration-3 note 2 also says
*“order by rowid meanwhile”*).

**Repro / proof:** `[P05-BUG-9] Maya renders before Leo (order added, never
alphabetical)` — demo seed (Maya inserted first, then Leo), 390×844:
`maya.left = 210`, `leo.left = 30`; expected `maya.left < leo.left`.

**This is fixable inside RULES §1 — the build notes’ “cannot be done” claim is
wrong** (review finding 2). `features/family/data/**` is an allowed path and
`FamilyRepositoryImpl` owns its database handle, so it can run its own ordered
query instead of the core helper. I verified the fix independently against the
demo DB — rowid ordering returns exactly `[Maya, Leo]`:

```dart
// app/lib/features/family/data/family_repository_impl.dart  (data/** = RULES §1)
Stream<List<ChildrenData>> _watchChildrenInAddedOrder() {
  return (_db.select(_db.children)
        ..where((c) => c.familyId.equals(Seed.familyId))
        ..orderBy([
          (c) => OrderingTerm(expression: CustomExpression<Object>('rowid')),
        ]))
      .watch();
}
```

**Suggested fix:** use the query above in `watchChildren()` (keep the filed
shared request as the durable fix), drop the `TODO(P05)` deferral in
`kid_card_grid.dart:13-16`, and **flip or delete**
`add_children_test.dart:1487-1501` (`'roster order comes from the database
(nickname order)'` asserts `leo.left < maya.left` — it pins the exact order the
ruling forbids and will contradict the fix; review finding 4).

---

## P05-BUG-10 — MINOR — kid card renders 124 px tall against the design’s 116, pushing the whole form region 8 px low

**Where:** `app/lib/features/family/presentation/widgets/kid_card_grid.dart:28-35`
— `cardH` ends in a trailing `NestSpacing.gap10` “pencil clearance” and uses
4 px (`s1`) between the name and age, where the design’s flex column has
`gap: 2` + `margin-top: 4` = 6.

Design math (HTML/CSS): `12` padding + `44` avatar + `2` gap + `24` name +
`2+4` gap/margin + `18` age + `10` padding = **116**; `.edit` is
`position: absolute`, so the 44 px pencil adds no height. App `cardH` =
`22` chrome + `44` + `2` + `24` + `4` + `18` + `10` = **124**.

**Repro / proof:** `[P05-BUG-10] kid card height matches the design 116 (±2)` —
both cards measure **124.0** (expected ≤118). This is the P05-local half of the
stage-5 iteration-3 deviation 2 (h3/Nickname/Age-band +8, chips +13,
swatches/caption +20); the remaining +12 at the chips is the shared `NestChip`
44-tall tap box around a 32 px visual (`SHARED_REQUEST.md` #3 — not fixable in
P05).

**Suggested fix:** make the name→age spacing 6 (`gap2` + `s1`) and drop the
trailing `gap10` from `cardH` → 116; keep the existing pencil-inside-card
assertion (the pencil overlays the top-right and fits in a 116 card).

---

## Iteration-1/2 bugs — all fixed and regression-proofed

| # | Bug | Fix landed | Proof status |
|---|---|---|---|
| P05-BUG-1 | Chips stacked full-width; swatches under the CTA | shared `NestChip` fix + P05-local shrink (workaround now redundant) | green |
| P05-BUG-2 | Same-frame double submit | `saveInProgress` guard | green |
| P05-BUG-4 | Retry leaked watchers | `_closeOnError` | green |
| P05-BUG-5 | Typing mid-save discarded | `lastSavedNickname` conditional clear | green |
| P05-BUG-6 | `ageYears` always 7 | band → age mapping | green |
| P05-BUG-7 | H1 had no header landmark | `Semantics(header: true)` | green |
| P05-BUG-8 | Grid re-applied device insets | `padding: EdgeInsets.zero` | green (proof with 47/34 insets) |

Re-read the iteration-3 diff adversarially: the `lastSavedNickname` sentinel
clears correctly, the `debugPrint` on an unknown colour logs only the token
(no child data), and the h1’s `\u2019` matches the HTML’s `&rsquo;`.

## Verified sound (adversarial probes on this build)

| Area | Result |
|---|---|
| Rapid double taps | two same-frame taps with the real DB insert **one** child |
| Data edge cases | 0/1/6 children, “Maximilian-Alexander” + long names at 320/1.3 → no overflow, no exceptions |
| Chips | one row on device (UI check), left-aligned on the card edge, 8 px gaps; in-test 2 rows only from the wider fallback font |
| Back / deep links | Back → `/privacy`; direct launch lands on the screen |
| Kid-mode guard | kid-mode deep link → `/parental-gate` |
| Restart / Drift persistence | child added, fresh app launch over the same DB → card present |
| Dark mode | tokens unchanged; UI check dark ≈ light (4.88% vs 4.87%) |
| Async gaps | bloc drops late emits; `onSaved` callbacks `mounted`-guarded |
| Money / timezone | P05 renders no money or dates — N/A by construction |
| COPY ruling | h1 `’` U+2019, subtitle `—` U+2014, bands/ages `–` U+2013, “Avatar colour”, all other literals character-exact vs the HTML |
| Owner rules | bottom edge and 20 px gutters unchanged and green (existing tests + UI check) |

## Repo-gate blocker (shared file, not a P05 code defect)

`app/test/app/router_push_test.dart:104` still passes
`showsFrom: 'P05 Add children'` — the pre-build placeholder title — so the full
`flutter test` run is red (reproduced: `+3 -1`, line 37). The file arrived from
main in `7eaa1f7`; `app/test/app/**` is outside RULES §1. Already filed with
the one-string fix (`'Who\u2019s in your nest?'`) in `SHARED_REQUEST.md`;
listed here only so the gate record is honest. Not counted against the P05
diff.

## Fix-pass notes (from the iteration-3 review, still open)

* Drop the four now-redundant `IntrinsicWidth` wrappers in
  `add_child_form_card.dart` (the shared chip shrink-wraps by construction) and
  refresh the stale comments (review finding 3).
* Correct the “cannot be done in RULES §1” feasibility claims in `2_build.md`
  and `3_test.md` (review finding 6).

