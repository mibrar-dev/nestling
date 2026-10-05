# Fix list after iteration 2

## From 3_test.md
# Stage 3 — TEST (iteration 2) · P08b · Today empty

Route `/today-empty` · parent · feature `today` · branch `screen/P08b`
(HEAD `7d106cb` "checkpoint after build (iteration 2)", main merged at
`d340024`). All six iteration-1 bugs were fixed by the iteration-2 builders.

## Result

`flutter test --timeout 120s test/features/today/` → **190 passed, 2 skipped
(the review stage's pending proofs), 2 failed**.

Both failures are my new proofs for the two defects below — **no iteration-1
proof regressed**: the seven red tests from iteration 1 (T01–T06) turned green
on their own when the builders fixed them, which is exactly what a good red
test should do. The whole-app suite is also clean apart from those two:

```
flutter test --timeout 120s            → 4695 passed, 15 skipped, 2 failed
flutter analyze lib/features/today + the 7 today test files → No issues found
dart format --set-exit-if-changed        → clean
```

No screen code was edited (Stage 3 rule): the only file I touched is
`app/test/features/today/today_empty_view_test.dart`.

## Verification of the iteration-1 fixes (measured, not assumed)

Design numbers are `PNG ÷ 3 − 47` (status bar reserved only; widget tests have
no top inset). Measured with the bundled Inter/Nunito faces loaded:

| element | design | app (was) | app now |
|---|---|---|---|
| greeting h1 box | 0–34 | 8–42 | **0–34** ✓ |
| date line | 36–58 | 44–66 | **36–58** ✓ |
| empty card | 74–508 (434) | 82–518 (436) | **74–508 (434)** ✓ |
| `Add a quest` pill | y 376–428, x 40–350 | y 384–436 | **y 376–428, x 40–350** ✓ |
| `Browse ideas` row | y 436–480, h 44 | y 444–490, h 46 | **y 436–480, h 44** ✓ |
| tip card | 524–614 (90) | 534–628 (94) | **524–614 (90)** ✓ |
| tip caption box | y 562 | y 576 | **562** ✓ |
| date line copy | `A fresh nest` | `Happy week: 4 days` | **`A fresh nest`** ✓ |

Every element is now inside ±1 px, and dark mode lays out identically (card
`74–508`, tip `524–614` in both themes). The whole-screen +8 px shift is gone.

## Tests added this iteration

`app/test/features/today/today_empty_view_test.dart` grows from 51 to 63
executed tests (12 groups; 48 written `testWidgets`/`test`/`blocTest`
bodies, several of them parameterised over themes/widths/scales).

**1. `P08b iteration-2 regression pins` (11 new tests)** — each pins the
*mechanism* of a fix, not just its outcome, so the same drift reintroduced
elsewhere still fails:

- the empty greeting's box starts at the `ListView`'s own origin (no padding
  of its own anywhere between them);
- the link row is exactly `NestDevice.tapParent`, its glyph centred, and the row
  spans the card's inner width x 40–350;
- `decorationColor == color == sky` on the link style in **both** themes;
- the tip's `.body-s` and `.caption` boxes are flush (`body.top == title.bottom`)
  and the card is exactly 90 tall;
- the greeting wraps at 1.3× **and really did take two lines** (so the wrap path
  is exercised, not a lucky one-line fit);
- summaries stay in creation order for a roster whose ages disagree;
- **the "A fresh nest" fix does not over-trigger**: one assigned quest puts the
  P08 body back *and* restores `Happy week: 4 days`;
- an unassigned "Anyone" quest still reads as an empty nest (repository contract:
  only assigned quests appear on Today) — proves the empty branch is driven by
  the same predicate the bloc uses;
- an archived (`active = false`) quest does not resurrect the P08 body;
- light and dark produce the identical card rect.

**2. Two new bug proofs** (below), plus the 51 iteration-1 tests unchanged.

## Bugs found

### P08b-T07 · MINOR · the greeting is still capped at two lines, so a double-barrelled surname is clipped

- **Where**: `app/lib/features/today/presentation/widgets/today_loaded_body.dart:773-778`
  (`maxLines: 2, overflow: TextOverflow.ellipsis` on the empty greeting).
- **What changed**: iteration 2 raised the cap from 1 to 2. That fixed the
  iteration-1 case (the design's own `Sarah` at 320 px / 1.3×), but 2 lines is
  still not always enough, and the design's cap is not 2 — it is **none**.
- **Evidence**: P08b's `.greet h1` (`P08b-today-empty.html:4`) sets only font
  family/weight/size/line-height. `components.css:43` gives `h1` exactly one
  related rule — `overflow-wrap: anywhere; min-width: 0` — i.e. the design lets
  the heading run to as many lines as the name needs. `.linkrow a`'s 44 px and
  `.btn`'s 52 px are caps; the h1 has none.
- **Measured** (`didExceedMaxLines`, bundled Nunito Black, 320 px @1.0):

  | parent name | chars | clipped? |
  |---|---|---|
  | `Sarah` (the design's) | 5 | no |
  | `Sarah-Jane` | 10 | no |
  | `Sarah-Jane Watson` | 17 | no |
  | `Boadicea Featherstone` | 21 | **yes** |
  | `Maria-Jose Featherstone` | 23 | **yes** |
  | `Maria-Jose Konstantinopolou` | 27 | **yes** |

  21 characters is an ordinary UK double-barrelled surname at the *smallest*
  supported width, at *normal* text scale — no accessibility setting involved.
- **Repro**: `flutter test --timeout 120s --plain-name "double-barrelled surname" app/test/features/today/today_empty_view_test.dart`
  → `Expected: false  Actual: <true>`.
- **Fix**: drop `maxLines` on the empty greeting (or raise it enough that the
  realistic ceiling is unreachable). The screen scrolls, so a third line costs
  nothing; `overflow: ellipsis` on a heading is what loses the parent's name.
- **Cross-reference**: the concurrent Stage 4 (iteration 2) reached the same
  conclusion independently and filed it as `P08b-B06` in
  `app/test/features/today/p08b_bugs_test.dart` (still `skip: true`). Same fix.

### P08b-T08 · MINOR · the message is capped at five lines, so at 1.3× the children's names are the part that gets cut

- **Where**: `today_loaded_body.dart:848-851` (`maxLines: 5` on the `.empty-card p`).
- **Evidence**: `.empty-card p` sets only `max-width: 260px` — no cap.
- **Measured**: at 1.0× a 6-child roster with long names fits the cap *exactly*
  (5 lines, `didExceedMaxLines == false`). At **1.3×** the same sentence needs
  ~9 lines, so the ellipsis eats the tail — which is precisely the part that
  names the children: `… Maya, Leo, Maximilian-Alexander and …` is cut before
  "will see it straight away".
- **Repro**: `flutter test --timeout 120s --plain-name "every child name survives in the message" app/test/features/today/today_empty_view_test.dart`
  → `Expected: false  Actual: <true>`.
- **Fix**: remove the cap (or raise it). The card is in a `ListView`; a longer
  message just grows the card.
- **Cross-reference**: Stage 4 filed the same as `P08b-B07` (still `skip: true`).

Both are the same root cause: an invented line cap on copy the design does not
cap. Neither moves any element in the design's own state (the design PNG is
unaffected), so this is an a11y/robustness defect, not a geometry one.

## Hunted and clean this iteration (so nobody re-checks)

- **Link row hit area**: the whole 310×44 strip is live, not just the glyph —
  taps at dy ±6/±12/±20 and dx ±20/±100/±152 from the centre all reach
  `/quests`, including the row's far corners. The row is now wider than the
  design's content-width `<a>`, which only enlarges the target; the underline
  still paints on the glyph alone, so nothing is visible at the edges.
- **Child order** now holds for equal ages too (`Zed` at 9 alongside Maya at 9
  reads `Maya, Leo and Zed` — no alphabetical tiebreak).
- **The sort removal did not move P08**: with Maya 9 / Leo 6 / Zara 12 the kids
  grid and group labels render Maya, Leo, Zara (creation order), which is what
  both the design and the CHILD ORDER ruling require. The whole-app suite
  (4 695 tests) shows no regression from the `watchSummaries` change.
- **Empty-state predicates agree**: unassigned "Anyone" quest and archived quest
  both show the P08b card *and* `A fresh nest`; the first assigned quest flips
  both the body and the label together, so the bloc can no longer disagree with
  the view.
- **Navigation**: `Add a quest` → `/quest-editor` with no `questId`, system back
  returns to the empty screen; `Browse ideas` → `/quests`; the tab bar still
  switches branches and the Today tab restores `/today-empty`.
- **Semantics**: both controls expose and honour `performAction(tap)`; the art
  node is a labelled non-interactive `image`; the greeting is a `header`.
- **Sizes**: 320/390/430 × 1.0/1.3 in both themes — no overflow, no exception,
  the tip caption is not ellipsised at the worst case.
- **Bottom edge** (owner rule): tab-bar surface runs to the physical edge in
  both themes with `currentIndex == 0`.
- **Byte-exact copy**: the two-name message, the tip's `— “Make your bed” …`
  and `Reading – 20 minutes`, the UK comma-free `Maya, Leo and Ava`.
- No `google_fonts`, no `DateTime.now()`, no simulator booted/installed/driven
  (Stage 3 rule), no file outside `app/test/features/today/` edited.

## Note for the next iteration

T07 and T08 are both "remove a `maxLines` cap the design does not have" and are
one-line changes in `today_loaded_body.dart`. My two red proofs and Stage 4's
skipped B06/B07 all turn green on their own when they land; no test edits
needed.

