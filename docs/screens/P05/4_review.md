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

VERDICT: FAIL