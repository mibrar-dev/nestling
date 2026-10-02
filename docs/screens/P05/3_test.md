# P05 · Add children — test notes (STAGE 3, iteration 4)

Route `/add-children`, feature `family`, parent mode. Changes are confined to
`app/test/features/family/add_children_test.dart` plus these notes — no screen
code touched.

Iteration 4 is the loop's last iteration and its brief is "be exact". The
orchestrator's four targets are addressed; the build stage's fixes (rowid child
order, 116 px cards, the `IntrinsicWidth` removal now that the shared chip is
fixed) are all re-proved. **P05's own suite is green (116 tests).** The full
`flutter test` run is still red on the one shared test filed as BLOCKING in
iteration 3, which arrived from main and is outside RULES §1 — hence FAIL.

## Tests added / rewritten (9 added; 3 superseded)

### CHILD ORDER ruling — now asserted directly (note 1)

The build implemented the interim `rowid` ordering in
`family_repository_impl.dart`, and flipped one assertion to `maya.left <
leo.left`. I replaced that single assertion — and my iteration-3 invariant
group — with a five-test group that proves the ruling itself:

| Test | What it rules out |
|---|---|
| the seeded roster reads **Maya, then Leo** (on `onboarding_kids`) | alphabetical order (Leo < Maya is the trap) |
| a child added in this session **appends**: `[Maya, Leo, Ollie]` | sorted-into-place — 'Ollie' lands between Leo and Maya alphabetically, so only insertion order gives this |
| **renaming** Maya → 'Zoe' keeps `[Zoe, Leo]` | nickname ordering: 'Zoe' would sort *after* Leo and flip the roster |
| the grid renders the bloc's roster **verbatim, unsorted** | a local re-sort in the grid |
| the bloc never reorders (fed both orders) | a sort in the bloc |

The rename test is the decisive one for the durable fix: it passes on the
`rowid` interim and would fail on any nickname-based ordering, so it keeps
proving the ruling after the shared `createdAt` column lands. Two harness
details that cost a cycle and are now written down: `pumpEventQueue()` hangs in
`testWidgets` (its `Future.delayed` never fires in the fake-async zone — drive
the clock with `tester.pump()` instead), and `FamilyBloc` is a GetIt *factory*,
so the rendered order must be read from `BlocProvider.of` on the grid.

### Form-card rhythm — every gap and row height vs the HTML (note 3)

The note asked me to take every vertical gap from the HTML because the rows
"drift down cumulatively". Measured on the current code, **they do not drift —
every gap and every row height is the design value** (390 px, scale 1.0):
`h3` 24 · →field 10 · label 18 · →input 6 · input **52** · →Age band 8 ·
label 18 · →chips 4 · →Avatar colour 8 · label 18 · →swatch 4 · swatch 44 ·
→note 6. Two new tests pin exactly that table (row heights + the seven gaps,
with the HTML selector quoted in the reason strings) and a second test asserts
`sub → grid = 14` and `grid → form card = 12` at **320, 390 and 430** (notes 2
and 3's gap targets).

## Results

```
dart format .        clean (362 files, 0 changed)
flutter analyze      No issues found!
flutter test test/features/family/    00:05 +116: All tests passed!
    add_children_test.dart   105 · p05_bugs_test.dart 11 · zero skips
flutter test (full suite)             1 failure — app/test/app/router_push_test.dart
```

## Bugs found

### None in P05 code

Nothing in this iteration's diff produced a defect: the order fix, the 116 px
card, the chip-component cleanup and the removed `IntrinsicWidth` wrappers all
re-pass, including the BUG-1 geometry proofs (no chip claims the run, ≤2 rows in
the test font, one row in production).

### 1. Still-open shared gate: `router_push_test.dart` asserts P05's placeholder

Unchanged from iteration 3 — `app/test/app/router_push_test.dart:104` passes
`showsFrom: 'P05 Add children'`, the pre-build placeholder title, so line 37
fails and the repo gate stays red on every branch where P05 is built. The file
is still at main's `7eaa1f7`, this worktree has never touched
`app/test/app/**` or `app/lib/app/**`, and the fix is one string
(`'Who\u2019s in your nest?'`). Filed as BLOCKING since iteration 3.

### 2. The residual 4.87% band drift is a shared typography effect, not P05's

The QA note's ladder (+4 at "Nickname", +8 at the field, +13 at the chips, +20
at "Avatar colour", and the form card top at ≈407 vs the design's 399) is real,
but **it is not produced by P05's layout**: every gap is a literal `SizedBox`
and every row height measures the HTML value in a widget test (table above).
The only variable left is the line boxes, and they only differ on device —
`NestType` promises "line boxes match the CSS exactly"
(`typography.dart:8`), which holds for the test fallback font (1.0 em) but not
for Nunito/Inter, which the app **fetches at runtime** (`pubspec.yaml` bundles
no fonts). Flutter scales a font's ascent+descent, whose natural line height
exceeds 1 em, so each row grows ~4 px and the error compounds down the card —
which reproduces the QA ladder and the 8 px head offset exactly.

Consequence: I could not reproduce it in tests, so it is not something this
stage can gate on; it belongs to the type scale, and it affects **every**
screen's vertical rhythm equally. Filed in `SHARED_REQUEST.md` with the
measurement table and three owner options (clamp line height with
`TextHeightBehavior`/strut, bundle metrics-matching fonts, or accept it as a
known delta). P05's action is complete: the gaps and heights are now pinned, so
any future drift is either caught here or attributable to that shared effect.

## Noted, not bugs

* `NestChip`'s 44 px tap row still occupies 44 (design `.chip` visual is 32);
  correct per `SPACING_SPEC` §6 ("base 32 high is below 44 → wrap in a 44-min
  tap area").
* The chips wrap to two rows **in tests only** (the fallback font is ~30%
  wider); production renders one row, verified on the simulator in iteration 2.
* Mid-save Continue is still dropped by the BUG-2 guard (buttons disable for the
  whole save; the design has no "still saving" state).
* `onSaved` on the event, `child_display.dart` placement, the raw exception
  string and the 1 px pencil offsets remain carried accepts from the review.

VERDICT: FAIL