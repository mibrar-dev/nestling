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

VERDICT: FAIL