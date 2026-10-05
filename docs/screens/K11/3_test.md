# K11 · Badges — stage 3 TEST (iteration 1)

Route `/badges` (feature `badges`, kid mode). Plan `1_plan.md` §f, orchestrator
rules, RULES §1/§7/§8/§9. No `ORCHESTRATOR_NOTES.md` existed when the stage
started; one appeared at 02:40 mid-stage — both of its items are handled below.
**No screen code was edited by this stage** (RULES: a stage that finds a bug
records it, it does not patch it). Only `app/test/features/badges/**` and this
file changed.

## Starting point

The screen arrived from stage 2 with **70 passing feature tests** (12 repository,
14 bloc, 26 view, 18 geometry — `2_build.md`). This stage added **50 tests**
across three new files and three extensions, taking the feature suite to
**120 passed**.

## Tests added

### New — `app/test/features/badges/badges_a11y_test.dart` (14)

`1_plan.md` §f item 5 (merged labels, SVG exclusion, spinner label, header
semantics) plus the tap-target rule from this stage's brief. The file is
isolated because it drives `tester.ensureSemantics()` and walks the
accessibility tree.

- **Tap targets** — back and lock are exactly `NestDevice.tapKid` (56) squares
  and also clear the 44 px parent floor. Two tests enumerate every node with
  `SemanticsAction.tap` in the loaded and the loading tree and assert the
  labelled set is exactly `{Back, Grown-ups}` — i.e. *nothing else on the shelf
  is a control*, proved rather than asserted by comment — and that each one's
  semantics rect is ≥ 44.
- **Icon-button labels** — the HTML's `aria-label`s verbatim (`K11-badges.html:38`),
  never announced disabled; `performAction(SemanticsAction.tap)` on `Back`
  navigates to `/kid-home` and on `Grown-ups` pushes `/parental-gate`; the
  chrome stays operable while the stream is still loading.
- **Static content** — one merged node per badge tile (`<name>, <detail>`) with
  no tap action and no `isButton` flag; neither the bare name nor the bare sub
  copy exists as its own node; exactly one labelled node per tile (the medal is
  `ExcludeSemantics`, so no SVG/rosette node leaks); title, subtitle and the
  week line reach the tree character-for-character (em dash U+2014, curly ’
  U+2019 asserted); the week card contributes one text run — `M T W T F S S`
  then the why-line, no per-dot glyph nodes, no tap; the spinner announces
  `Loading badges` and is not a control.

Multi-line text reaches the tree with `\n` where it wrapped, so every lookup
normalises whitespace first — otherwise a design line that happens to wrap in
the test font reads as "no node". That is why the week-line assertion matches a
fragment of the merged run rather than the whole node.

### New — `app/test/features/badges/badges_matrix_test.dart` (22)

The full matrix this stage's brief asks for, which the inherited suite only
covered in corners.

- **3 widths × 2 text scales × 2 themes = 12 tests** (320/390/430 × 1.0/1.3 ×
  light/dark): no layout exception, chrome present, copy intact, and the grid
  stays on the 20 px gutters (ALIGNMENT owner rule) — `left == 20` and
  `column 3 right == width − 20` at every corner. The week card is checked
  separately at all three widths after a scroll (it can sit below the fold at
  320/1.3, so it is scrolled into view first).
- **Long-name clipping** — a badge title far longer than the design's two lines
  still clips: `maxLines: 2` + `TextOverflow.ellipsis`, no overflow at 320/1.3.
- **DB-driven copy branches** (the design only ever shows 4 earned / 4 happy
  days): 0 happy days → `Let’s make today a happy day!` and zero filled dots
  (no loss-aversion — Children's Code std 13); 1 → `1 happy day` singular; 7 →
  all seven dots filled; 0 earned → `No shiny ones yet. Finish a quest to earn
  your first!`, no `Got it!`, week card still shown; 1 earned → `One shiny one
  already.`; all 8 earned → every cell `Got it!`, none `Keep going!`, word list
  resolves.
- **`Seed.empty`** — an onboarded parent with no children renders the empty
  shelf, hides the grid and the week card, keeps back + lock, and does not
  throw; a second test pins the invented zero copy exactly (plan §d flags it).

### New — `app/test/features/badges/badges_art_test.dart` (7)

The test side of the mandatory `ORCHESTRATOR_NOTES.md` (02:40) item — "every one
of the nine ids must render its own design medal … in BOTH earned and locked
states, light and dark … the generic rosette fallback is only for ids not in
the design".

- **Asset level** — the nine `NestlingIllustrations.badge*` constants are nine
  *different* files, and each file exists in the bundle and is an SVG drawing
  (catches a typo that would point two ids at one medal).
- **Cell level** — each of the nine design ids pumped as a real `BadgeGridCell`
  in earned × locked × light × dark draws an `SvgPicture` medal at 60×60 and
  **never** the `NestIcons.ribbon` fallback; an id outside the design falls back
  to the rosette. Ids come from the test, not the seed, so these hold both
  before and after the nine-badge seed correction lands on `main`.

### Extended

- `badges_bloc_test.dart` **+3** — `BadgesDataReceived` before any load still
  populates state (and never starts a watch), `BadgesStreamFailed` before any
  load reaches the retry surface, and a failure after a healthy load keeps the
  last shelf/count in state while releasing the subscription (`liveCancels == 1`,
  which is what makes `Try again` work).
- `badges_repository_test.dart` **+1** — a `happyDays` write above 7 is reported
  verbatim by `watchHappyDays`, i.e. the repository invents no clamp of its own
  (the 0…7 framing belongs to the screen; a silent clamp here would let the dots
  and the why-line disagree unnoticed).
- `badges_view_test.dart` **+3** — the failure surface still navigates: back to
  `/kid-home`, lock to `/parental-gate`, and a screen-reader
  `performAction(tap)` on `Try again` that drives the real bloc event and
  repaints the real shelf (`2 happy days this week — Pip hasn’t stopped
  singing.`).

## Results (verbatim tails)

```
$ dart format lib/features/badges test/features/badges
Formatted 21 files (0 changed) in 0.30 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 10.9s)

$ flutter test --timeout 120s test/features/badges
00:10 +120 ~2: All tests passed!

$ flutter test --timeout 120s
05:06 +4410 ~12: All tests passed!
```

Per file (`--reporter=json`, passed/skipped/failed): bloc 15/0/0, repository
15/0/0, view 29/0/0, geometry 18/0/0, **a11y 14/0/0, matrix 22/0/0, art 7/0/0**.
Full suite 4410 passed, 12 skipped, 0 failed. No hangs, no timeouts — every
test is bounded and every widget test ends with `disposeApp`.

## Bugs found

**None in the screen.** No test in this stage exposed a defect in
`lib/features/badges/**`; nothing was patched, and no screen file was opened
for edit.

Two things worth recording, neither a K11 screen bug:

1. **`happyDays > 7` is rendered literally** (already filed as `4_review.md`
   finding 2 / the bugs stage's E4). Repro I used:
   `db.children` → `happyDays = 9` → all 7 dots fill and the line reads
   `9 happy days this week — Pip hasn’t stopped singing.`
   (`happy_week_card.dart:86,97`). `children.happyDays` has no upper bound in
   the schema and the only writers (the demo seed: 4 and 3) cannot exceed 7, so
   it is not reachable from the app today — it is defensive hardening, owned by
   the review/bugs stages. I deliberately did **not** write a test that pins the
   wrong behaviour; my repository test pins the opposite contract (no clamp in
   the data layer).
2. **Test-harness details fixed inside my own tests** (not screen bugs, noted so
   the next stage does not lose time): a raw `await db…write(…)` inside
   `testWidgets` hangs the file until SIGTERM — every mutation goes through
   `tester.runAsync` (documented at the top of `badges_matrix_test.dart`); and
   `_FakeBadgesRepository.hang` wins over `failFirstWatch`, so the failure
   surface must be reached with `failFirstWatch` alone.

## Orchestrator notes (`ORCHESTRATOR_NOTES.md`, 02:40 — mandatory)

- *"Do not edit `seed.dart` yourself"* — honoured. No file under
  `app/lib/core/**` was touched by this stage; the seed correction stays with
  the orchestrator's `shared/k11_badges_seed` branch.
- *"Every one of the nine ids must render its own design medal … in BOTH earned
  and locked states, light and dark"* — now enforced by
  `badges_art_test.dart` (7 tests, all green today). The note's other half —
  removing the `TODO(K11)` in `badges_view.dart:326` once the seed lands — is a
  build-stage action; the art map itself already resolves all nine ids to their
  own asset, so the TODO is about shelf *content*, not art.

## Scope and rules

- Edited only `app/test/features/badges/**` and `docs/screens/K11/**` (RULES §1).
- No simulator was booted, installed on, screenshotted or driven by this stage;
  `E7D5555E-…` was not touched.
- No `flutter clean`, no `pkill`/`killall`, `analysis_options.yaml` untouched, no
  tests skipped or ignored to get green.
- No `DateTime.now()` / `clock` reads, no `google_fonts` in any new test, no
  hard-coded design numbers — every count is read from the seeded database and
  cross-checked against it.
- Numbers, names and order in the new files come from the DB (8-row demo shelf),
  not from the design's nine, so the pending seed correction will not break them.

VERDICT: PASS
