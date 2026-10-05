# Stage 3 — TEST (iteration 1) · P08b · Today empty

Route `/today-empty` · parent · feature `today` · branch `screen/P08b`.
Working tree: `main` (eed3978, the `shared/p08b_shell` merge) merged in before
writing, so `Seed.newFamily` and the Today-tab shell route are present.

## What I added

`app/test/features/today/today_empty_view_test.dart` (new, ~1 200 lines, 51 tests).
Nothing else in the repo was edited — per the Stage 3 rule a test that finds a
bug **records** it, it does not patch the screen.

Seeds used (in-memory Drift, `test/test_scope.dart`):
- `Seed.newFamily` — Sarah + Maya + Leo, **no quests**: the state the P08b
  design PNG shows, and the seed every P08b UI check uses (ORCHESTRATOR_NOTES
  (03:25)). Two children ⇒ the design's two-name sentence.
- `Seed.empty` — 0 children ⇒ the sentence-less copy variant.
- `Seed.demo` — the populated fallback (`/today-empty` renders the P08 body).

Real bundled Inter/Nunito faces are loaded in `setUpAll` (`FontLoader`), so line
breaking and box heights in the geometry proofs match a device run — without
that the test fallback font wraps the message onto 5 lines instead of the
design's 3 and every y measurement is meaningless.

### Coverage

| Group | Tests | What it pins |
|---|---|---|
| copy · light/dark | 5 | every line of copy byte-exact (em dash, curly quotes, en dash, never `"` or ` - `); the absent `New quest` `+`, avatar, approvals banner, kids grid, `Today's quests`, hand-off; dark renders the same copy |
| message copy · family size | 5 | `emptyMessageSuffix` for 0/1/2/3+ children (UK, no Oxford comma); widget proofs for 0, 1 and 3 children (a child is inserted/removed in the DB); a child added **last** who is the **oldest** still comes last (creation order, not age) — **red** |
| navigation · every control | 4 | `Add a quest` → `push /quest-editor` with **no** `questId`, system back returns to the empty screen (not out of the app); `Browse ideas` → `go /quests`; tab bar still switches branches (Today/Quests); a non-empty DB falls back to the populated P08 body |
| states · loading + failure | 2 | spinner and no card while loading; failure copy + `Try again` → recovers into the card. Both need a mock repository (a healthy DB can never produce them) |
| semantics | 5 | greeting is a `header` node with no tap action; Pip art is an `image` node with the HTML `alt` (`Pip the bird as a speckled egg`) and **no** tap action; `Add a quest` and `Browse ideas` both expose `SemanticsAction.tap` **and** `performAction(tap)` changes the real route; no `excludeSemantics` control without its own label |
| tap targets | 3 | primary 52, link ≥ 44 in light + dark, and a tap 12 px above / below the glyph centre still navigates (the `NestChipWrap`-style off-glyph check) |
| size matrix | 12 | light+dark × 320/390/430 × 1.0/1.3: full copy, scroll to the tip, no exception, the tip caption is not ellipsised away at 320 @1.3 (4 lines vs `maxLines: 4`) |
| alignment | 3 | 20 px gutters at 320/390/430; card, tip card and button on the same edges; Pip, button and link centred on the card; the message keeps the 260 px measure |
| geometry vs design | 5 | design y positions (see below) — **4 of 5 are red** |
| bottom edge | 2 | `NestTabBar` spans 0 → physical edge, its `Container` decoration is `tokens.surface` in both themes, `currentIndex == 0` |
| bloc | 6 | `bloc_test` for every path: no children, children-but-nothing-to-do, something-to-do, stream error → failure, initial state, retry-after-failure (keeps the stale `errorMessage` in state, never on screen) |

## Results

- `flutter analyze` (whole app) → **No issues found**.
- `flutter test --timeout 120s test/features/today/` → **165 passed, 5 skipped
  (pre-existing `p08b_bugs_test.dart` proofs), 7 failed**.
- The 7 failures are the 7 bug proofs below; **all of them are in the new
  file** and every pre-existing P08 test still passes (no regression).

## Bugs found (7 red proofs, 6 distinct bugs)

Cross-reference: `docs/screens/P08b/6_bugs.md` (Stage 6, iteration 1)
independently proves **P08b-B01** = my P08b-T05 (date line), **P08b-B03** =
my P08b-T01 (8 px shift) and **P08b-B04** = my P08b-T04 (greeting clipped),
and also **P08b-B02** = my P08b-T06 (child order) and **P08b-B05** (the
`Browse ideas` underline paints in ink, not sky). Same root causes, reached
independently. My P08b-T02 (link row 46 px) and **P08b-T03** (the tip card's
4 px caption gap) are **not** in 6_bugs.md — 6_bugs.md lists the 46 px link row
only as an "observation (not a bug)", and it does not measure the tip card's
internal spacing at all. I keep my own ids below.

Design numbers below are `PNG ÷ 3 − 47` (the status bar is only reserved, see
the ORCHESTRATOR STATUS BAR rule; widget tests have no top inset, so the app's
measured `y` is directly comparable).

### P08b-T01 · MAJOR · the whole empty body sits 8 px too low

- **Where**: `app/lib/features/today/presentation/widgets/today_loaded_body.dart:762-767`
  (`_EmptyGreeting`'s `Padding(EdgeInsets.only(top: NestSpacing.s2))`).
- **Evidence**: P08b's HTML has **no** `.greet { padding-top }` rule — its
  `<style>` block (line 4) only styles `.greet h1` and `.greet .date`. The 8 px
  belongs to **P08's own screen-local rule** (`P08-today.html:3`), which
  `_EmptyGreeting` inherited. Cross-checks on the design PNGs (÷3):
  - P08: banner top **123** = 47 + 8 (greet pad) + 28 (h1) + 2 + 22 (date) + 16
  - P08b: card top **121** = 47 + 34 (h1) + 2 + 22 (date) + 16  ← no padding
  The whole design PNG is consistent with the second formula: the primary
  button lands at 423 (= 121 + 28 + 140 + 8 + 28 + 8 + 66 + 8 + 8 + 8) and the
  card bottom at 555 (= 434 tall). Both are exact.
- **Measured (app, 390×844, seed `new_family`) vs design**:
  title 8 vs 0 · date 44 vs 36 · card top 82 vs 74 · card bottom 518 vs 508 ·
  tip card 534 vs 524 · tip bottom 628 vs 614.
- **Repro**: `flutter test --timeout 120s --plain-name "the greeting starts at the top of the scroll" app/test/features/today/today_empty_view_test.dart`
  → `Expected: a numeric value within <1> of <0.0> Actual: <8.0>`.
- **Why it matters**: 8 px on every element — a clear UI-check FAIL (the rule
  is ±2 px), and it also moves the tip card, which the design places well
  above the fold.
- **Fix**: drop the top padding on `_EmptyGreeting` only (the populated P08
  `_Greeting` keeps its 8 px).

### P08b-T02 · MINOR · the `Browse ideas` row is 46 px, the design's is 44

- **Where**: `today_loaded_body.dart:863-876` (`Padding(vertical: NestSpacing.s3)`
  = 12 above and below the 15/22 glyph).
- **Evidence**: `.linkrow a { min-height: 44px }` — the HTML row is exactly 44,
  so the card is 434 = 28 + 140 + 28 + 66 + 8 + 52 + **44** + 28 + 5×8 gaps,
  which is what the PNG shows (card 121 → 555). 2b chose `s3` to clear the 44 px
  tap floor; `s3` overshoots because 22 + 12 + 12 = 46.
- **Measured**: link row height 46 vs 44 → card bottom 518 vs 508 (+2 on top of
  T01's +8).
- **Repro**: `--plain-name "the empty card is 434 tall and the link row is 44"`
  → `Expected: within <1> of <44> Actual: <46.0>`.
- **Fix**: 11 px vertical padding (or a `ConstrainedBox(minHeight: 44)` around
  the 22 px glyph) — still ≥ 44, and exactly the design.

### P08b-T03 · MINOR · the tip card adds a 4 px gap the design does not have

- **Where**: `today_loaded_body.dart:894-895` (`spacing: NestSpacing.s1`).
- **Evidence**: `.card.inset` is a plain block card and `tokens.css:201` is
  `* { margin: 0 }`, so the `.body-s` and `.caption` divs **touch**:
  16 + 22 + 36 + 16 = 90, which is exactly the PNG (571 → 661).
- **Measured**: caption box sits 42 px below the card top instead of 38; tip
  card is 94 tall instead of 90 (→ tip bottom 628 vs 614 on top of T01/T02).
- **Repro**: `--plain-name "the tip card stacks title and caption with no gap"`
  → `Expected: within <1> of <38.0> Actual: <42.0>`.
- **Fix**: drop the `spacing` (the two lines then sit flush, 22 + 36).

### P08b-T04 · MAJOR (a11y) · the greeting is clipped, not wrapped

- **Where**: `today_loaded_body.dart:769-777` (`maxLines: 1, overflow: ellipsis`).
- **Evidence**: P08b's `.greet h1` carries no `white-space: nowrap` — only
  **P08's** `.greet-text h1` has `white-space: nowrap; text-overflow: ellipsis`
  (`P08-today.html:5`). In P08b the design wraps (and `h1 { overflow-wrap:
  anywhere }` at `components.css:43` exists for exactly that).
- **Measured**: the greeting's intrinsic width is 288.2 px, so it is clipped at
  **320 px** (available 280) and at **1.3× text scale on 390 px** (intrinsic
  374.7 vs 350) — i.e. most large-text users lose the parent's name and see
  `Good morning, Sa…`.
- **Repro**: `--plain-name "the greeting is never ellipsised"`
  → `Expected: <= <280.0> Actual: <374.7>`.
- **Fix**: let it wrap (`maxLines: 2`, or `NestBalancedText`, which the
  BALANCED HEADINGS rule prescribes for `.h1` headings) — same copy, same style.

### P08b-T05 · MAJOR · the date line says `Happy week: 4 days` instead of `A fresh nest`

- **Where**: `app/lib/features/today/presentation/bloc/today_bloc.dart:66`.
- **Evidence**: the bloc gates the fresh-nest label on `summaries.isEmpty`, but
  the view's empty branch is `state.items.isEmpty || state.summaries.isEmpty`
  (`today_loaded_body.dart:264`). With `Seed.newFamily` (2 children, 0 quests)
  the summaries are **not** empty, so the screen shows the P08b empty card while
  the date line keeps counting the children's seeded `happyDays` (4).
- **Design**: both P08b PNGs read `Sat 4 Oct · A fresh nest`.
- **Measured**: `Sat 3 Oct · Happy week: 4 days`.
- **Repro**: `flutter test --timeout 120s --plain-name "the date line uses the design day part" app/test/features/today/today_empty_view_test.dart`
  → `Expected: 'Sat 3 Oct · A fresh nest' Actual: 'Sat 3 Oct · Happy week: 4 days'`
  (and the same at bloc level in the `blocTest` of the same name).
- **Why it matters**: this is the seed the UI check screenshots, so the UI check
  fails on the first line of copy under the card.
- **Fix**: gate on the same condition as the view, i.e.
  `items.isEmpty || summaries.isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)`.
  P08 is unaffected (its demo seed always has items).

### P08b-T06 · MAJOR · the message names children in age order, not creation order

- **Where**: `app/lib/features/today/data/today_repository_impl.dart:84-89`
  (`watchSummaries()` re-sorts the roster `ageYears` desc, then nickname).
- **Evidence**: the CHILD ORDER ruling is creation order everywhere. The
  schema's own `watchChildren` already returns creation order (`createdAt`,
  then `rowid`), and the repository throws it away.
- **Measured**: `new_family` + a child added **last** who is the **oldest**
  (Zara, 12) renders `… Zara, Maya and Leo will see it straight away.`
  instead of `… Maya, Leo and Zara …`.
- **Repro**: `flutter test --timeout 120s --plain-name "a later child who is OLDER still comes last" app/test/features/today/today_empty_view_test.dart`
  → `Found 0 widgets with text "Add your first quest and Pip will start to hatch. Maya, Leo and Zara…"`.
- **Fix**: keep the `watchChildren` order in `watchSummaries` (drop the sort).
  The demo and new-family seeds are unaffected (Maya first and oldest), so
  P08's kids grid does not move.

## What passes (so the next iteration does not re-litigate it)

- All copy is byte-exact, including `Maya and Leo will see it straight away.`
  and the tip's `— “Make your bed” … “Reading – 20 minutes”`.
- Children are listed in creation order, 3 children read
  `Maya, Leo and Ava` (no Oxford comma), 0 children drop the sentence.
- Navigation, the shell/tab bar, the bottom-edge owner rule (`currentIndex == 0`,
  surface to the physical edge in both themes) and the populated fallback all
  hold — the `shared/p08b_shell` merge is in this worktree.
- Inside the card the geometry is already exact: Pip 140×140, `h2` 28, the
  message 260 wide × 66 (3 lines), the button 310×52 at x 40–350, all at the
  design's offsets **from the card's own top**. Only the card's own top (T01)
  and bottom (T02) drift.
- Semantics: both controls expose and honour `performAction(tap)`; the art node
  is a labelled, non-interactive `image`.
- No overflow at 320/390/430 × 1.0/1.3 in either theme, and the tip caption is
  not ellipsised at the worst case (320 @1.3 needs exactly 4 lines).
- `flutter analyze` clean; `dart format` clean; no `google_fonts`, no
  `DateTime.now()`, no simulator used (Stage 3 rule).

## Note for the UI stage

- The design PNGs show the area under the tab bar (y 810–844) in the page tint
  `#FBF7F0`, not the bar's surface. That is the OLD artwork: the owner BOTTOM
  EDGE rule requires the bar's surface to run to the physical edge, and the app
  already does that (proven in the bottom-edge group). Do not "fix" the app to
  match the PNG strip.
- `docs/screens/P08b/5_ui.md` and `6_bugs.md` are untracked leftovers from the
  5_ui and 6 stages of this same iteration; I read both before writing this
  report and did not duplicate their work — only T02/T03 are new (see the
  cross-reference above).

## Suggested next step

One build iteration fixes all six: T01 (`_EmptyGreeting`), T02 (link padding),
T03 (tip spacing), T04 (wrap the greeting), T05 (`today_bloc.dart:66`) and T06
(`today_repository_impl.dart:84-89`). The red proofs stay in the suite and
turn green on their own — no test edits needed.

VERDICT: FAIL