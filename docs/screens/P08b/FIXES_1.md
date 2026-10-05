# Fix list after iteration 1

## From 3_test.md
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


## From 4_review.md
# P08b · Today empty — QA code review (Stage 4, iteration 1)

Scope: `git diff main...HEAD` on branch `screen/P08b` (5 app files + docs),
reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md` (§1 scope,
§4 data contract, §7 done criteria), `docs/DESIGN_SPEC.md` §5 P08b,
`docs/design/SPACING_SPEC.md` §2/§3/§5, `design/html-source/screens/P08b-today-empty.html`
+ `components.css`/`tokens.css`, the design system as used, the loop's
orchestrator rules (PIP, COPY, CHILD ORDER, BOTTOM EDGE, CLOCK, FONTS,
LETTER SPACING, a11y actions), and `docs/screens/P08b/ORCHESTRATOR_NOTES.md`.

Iteration 1 delta: one bloc line, four UI widgets (`_EmptyGreeting` new,
`_EmptyCard` rewritten, `_TipCard` new, `emptyMessageSuffix` new), a view
doc-comment, and two test files. No code was edited by this stage.

## Gates re-run independently on `main...HEAD`

```
dart format --set-exit-if-changed lib/features/today test/features/today/{today_bloc_test,today_view_test}.dart   → 17 files, 0 changed, exit 0
flutter analyze                                    → No issues found!, exit 0
flutter test --timeout 120s test/features/today/today_bloc_test.dart \
    test/features/today/today_repository_test.dart → +35: All tests passed!
flutter test --timeout 120s test/features/today/today_view_test.dart \
    test/features/today/today_semantics_tap_test.dart \
    test/features/today/p08_bugs_test.dart         → +77: All tests passed!
grep added lines for Colors./Color(0x/fontFamily/google → none
grep added lines for ignore:/skip:                    → none
```

Independent PNG measurement (design vs app screenshot, logical px):
title ink top **53 → 61**, empty-card top **121 → 129** — confirms the UI
stage's numbers below. Underline pixel scan: design sky `(37,99,214)` light /
`(127,169,255)` dark vs app ink `(30,27,58)` / near-white.

**Result: 0 blockers, 4 majors, 4 minors. VERDICT: FAIL.**

---

## Findings

### 1. MAJOR — the empty-state date line shows “Happy week: 4 days” instead of “A fresh nest” on the mandated seed

`app/lib/features/today/presentation/bloc/today_bloc.dart:65-66`

```dart
dateLine:
    '${formatLondonDay(now)} · ${summaries.isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}',
```

The view's empty branch is `state.items.isEmpty || state.summaries.isEmpty`
(`today_loaded_body.dart:264`), but the suffix is gated on `summaries.isEmpty`
only. With `Seed.newFamily` — the seed every P08b UI check uses
(ORCHESTRATOR_NOTES (03:25)) — there are children (summaries non-empty) and no
quests (items empty), so the P08b card renders while the date line reads
`Sat 3 Oct · Happy week: 4 days` (both PNGs and HTML line 13 say `A fresh
nest`). Reproduced in the stage-5 screenshots:
`docs/screens/P08b/ui/app_light_1.png` reads “Mon 5 Oct · Happy week: 4 days”.

Fix: use the same predicate in the bloc:

```dart
final isEmpty = items.isEmpty || summaries.isEmpty;
// … '${formatLondonDay(now)} · ${isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}'
```

P08 cannot move (its demo seed always has items). Add the missing
`blocTest` case (items empty + summaries non-empty) and a `Seed.newFamily`
widget assertion.

### 2. MAJOR — the whole empty body sits 8 px too low; a uniform vertical shift the UI-verdict rule fails

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:763-764`

```dart
return Padding(
  padding: const EdgeInsets.only(top: NestSpacing.s2),
```

The 8 px `padding-top` belongs to **P08's** screen-local rule
(`P08-today.html:3`, `.greet{padding-top:8px}`); P08b's `<style>` block styles
only `.greet h1` and `.greet .date` and has **no** padding. The design formula
is `121 = 47 + 34 + 2 + 22 + 16` (card top), and the populated P08 greeting
already keeps its own padding in `_Greeting`. Measured (design → app):
greeting h1 box top `0 → 8` (scroll-relative), empty-card top `121 → 129`,
tip card also +8; the tab bar is exact so this is body-only. Fix: drop the
top padding from `_EmptyGreeting` only.

### 3. MAJOR — the new message names children in age order, violating the mandatory CHILD ORDER ruling

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:279`
(`_EmptyCard(names: state.summaries.map((s) => s.nickname).toList())`) and the
doc comment at `:794-797`, fed by the re-sort at
`app/lib/features/today/data/today_repository_impl.dart:84-89`:

```dart
// Eldest first (Maya 9 before Leo 6 in the demo), then nickname.
..sort((a, b) { … age desc, then nickname … });
```

`watchChildren` is documented creation order (`createdAt`, then `rowid`) — the
schema comment says “Roster order is creation order everywhere (CHILD ORDER
ruling)” — but `watchSummaries` overrides it by age, with an alphabetical
tiebreak. For a family whose second child is older, the copy reads in age
order; equal ages fall back alphabetically (both forbidden). For the two seeds
in play (Maya 9 added before Leo 6) the order happens to coincide, which is
why it was not caught earlier.

Fix (inside the today feature, RULES §1): drop the `..sort(...)` so
`kids.map(...)` preserves `watchChildren` creation order; update the stale
“Eldest first” comments at `today_repository_impl.dart:84` and
`today_repository_test.dart:306`. Demo/new-family rendering does not move.

### 4. MAJOR (a11y) — the greeting is clipped, not wrapped, at large text scales

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:771-776`
(`maxLines: 1`, `overflow: TextOverflow.ellipsis`)

P08b's `.greet h1` carries **no** `white-space: nowrap` (that is P08's rule,
`P08-today.html:5`); `components.css:43` gives `h1 { overflow-wrap: anywhere }`
so the design wraps. At 320 px width or 1.3× text scale on 390 px,
“Good morning, Sarah” exceeds one line and paints “Good morning, Sa…” — the
parent's name is lost for large-text users. Fix: allow two lines (keep the
ellipsis as a last resort) or render with `NestBalancedText`; copy and
`NestType.h1` unchanged.

### 5. MINOR — the “Browse ideas” row is 46 px; the design's is 44

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:865-866`
(`Padding(vertical: NestSpacing.s3)` = 12 + 22 + 12)

`.linkrow a { min-height: 44px }`, so the design card is exactly 434 tall
(121 → 555); the app's link row adds 2 px, drifting the card bottom to 556 on
top of finding 2. Fix without a magic number: replace the vertical padding
with `ConstrainedBox(minHeight: NestDevice.tapParent)` around the centred
22 px glyph (44 exactly, tap floor kept).

### 6. MINOR — the tip card adds a 4 px gap the design does not have

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:896`
(`spacing: NestSpacing.s1`)

`tokens.css:201` is `* { margin: 0 }`, so the `.body-s` and `.caption` boxes
**touch**: 16 + 22 + 36 + 16 = 90, which is exactly what the PNG shows
(571 → 661, pixel-verified). The app's tip card is 94 tall. Fix: drop the
`spacing` on `_TipCard`'s column.

### 7. MINOR — the “Browse ideas” underline paints ink, not sky

`app/lib/features/today/presentation/widgets/today_loaded_body.dart:869-870`

```dart
style: NestType.bodySmallStrong(color: tokens.sky)
    .copyWith(decoration: TextDecoration.underline),
```

`decorationColor` is null, so the engine falls back to the ambient ink: pixel
scan shows the app underline at ink `(30,27,58)` light / near-white dark while
the design PNG's underline row is solid sky `(37,99,214)` / `(127,169,255)` —
zero dark pixels in the design. Fix: add `decorationColor: tokens.sky` (the
same pattern already used at `create_account_view.dart:545-546`).

### 8. MINOR — committed regression coverage does not pin three of the fixed behaviours

`app/test/features/today/today_view_test.dart:896-897` asserts only
`link.height >= 22` (the glyph box) — not the 44 px tap row, the underline
colour, the `new_family` date line, or a `performAction(SemanticsAction.tap)`
for the two P08b controls (loop rule: every control's tap action must be
proven; plan §f items 7–8). The 320/1.3 test also never asserts the tap area.
Fix: land assertions for findings 1, 5 and 7 together with their fixes and add
the two semantics-action proofs for `Add a quest` / `Browse ideas`.

---

## Verified correct (not findings)

- **Scope (RULES §1)**: only `app/lib/features/today/presentation/**`,
  `app/test/features/today/**`, `docs/screens/P08b/**` touched. No `core/`,
  no `app/`, no router/seed edits (the shell move and `Seed.newFamily` landed
  on main, merged at `eac2f66`).
- **Architecture**: domain untouched (entities + abstract repo only); one bloc
  line changed; DI factory and per-feature routes unchanged; no new folders.
- **Design-system usage**: zero added literal colours/sizes/fonts (grep-verified);
  `NestCard` (standard + inset), `NestButton`, `PipAvatar`, `Semantics`,
  `NestSpacing`/`NestType` reused. `NestEmptyState` deliberately not reused —
  its h3 title (18 vs the design's 22), 160 art box (vs 140) and 24/16 insets
  (vs 28/20) genuinely differ from `.empty-card` (SPACING_SPEC §5), so this is
  a screen-specific variant, not a re-implementation.
- **PIP rule**: `PipAvatar(style: mochi, stage: 1, size: 140)`; `skin`
  defaults to `PipSkin.sunny` → satisfies the childless/onboarding rule; no v1
  `pip_stage_*` SVG; design size/position kept.
- **Copy**: tip body and message byte-exact vs HTML (em dash U+2014, curly
  quotes U+201C/U+201D, en dash U+2013, middle dot U+00B7), verified bytewise;
  UK spelling throughout; the two-sentence message is DB-derived (no hard-coded
  names).
- **One empty state**: `/today` and `/today-empty` share `TodayLoadedBody`
  (orchestrator item 1); no `TodayEmptyLoadedBody`; empty greeting has no `+`
  and no avatar (confirmed in both screenshots).
- **A11y**: both controls expose tap (`NestButton` Semantics + the link's
  `Semantics(button, excludeSemantics, onTap:)` mirror); Pip art is an
  `image` node labelled exactly like the HTML `alt` (“Pip the bird as a
  speckled egg”) with no tap action; greeting is a `header`.
- **Performance / streams**: widgets stay stateless, `const` used; no new
  streams, timers or controllers; bloc disposal unchanged; no rebuild storm.
- **Error handling**: loading/failure paths untouched; retry re-adds only
  `TodayLoadRequested`; raw error never on screen.
- **Children's Code**: no analytics/ads/tracking added; nickname only, no
  child data leaves the device.
- **Bottom edge / shell**: tab-bar surface runs to the physical edge in both
  themes; design PNG's old tint strip is overridden by the owner rule; tab bar
  top exact (727) in the stage-5 measurements.
- **Clock/fonts/letter-spacing**: no `DateTime.now()`; no `google_fonts`; no
  new `letterSpacing` (dateLine correctly tracking-free).


## From 5_ui.md
# P08b · Today empty — Stage 5 UI check (iteration 1)

Route `/today-empty` · parent · seed `new_family` (per SCREENS.tsv + ORCHESTRATOR_NOTES item 8, which override the stage brief's `empty`) · child `maya` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Worktree already contains `Seed.newFamily` and `/today-empty` in the Today `StatefulShellBranch` (p08b_shell content present), so the check is valid. Tab bar renders with Today active in both shots.

Shots: `docs/screens/P08b/ui/app_light_1.png`, `app_dark_1.png` (1170×2532, absolute out-path — relative `OUT` breaks because `shot.sh` `cd`s into `app/` before `cp`).
Compares: `cmp_light_1.png`, `cmp_dark_1.png`.

## Mean diff

- Light: **5.81%** (bands: 0–105: 10.31 · 105–211: 2.58 · 211–316: 5.65 · 316–422: 7.31 · 422–527: 10.54 · 527–633: 4.55 · 633–738: 3.13 · 738–844: 2.50)
- Dark: **5.51%** (bands: 0–105: 10.56 · 105–211: 2.52 · 211–316: 4.70 · 316–422: 7.20 · 422–527: 8.14 · 527–633: 4.79 · 633–738: 3.62 · 738–844: 2.61)

Band 0 is dominated by OS status-bar glyphs/time (ignored per STATUS BAR rule) plus findings 1–2 below. All geometry measured in logical px (pixels ÷ 3).

## Measured positions (design → app, logical px)

| Element | Design | App (light + dark identical) | Δ |
|---|---|---|---|
| Screen title top ("Good morning, Sarah") | 53.0 | 61.0 | **+8** |
| Empty-card top | 121.0 | 129.0 | **+8** |
| "Add a quest" button rect | y 423–475, h 52, x 40–350 | y 431–483, h 52, x 40–350 | **+8**, size exact |
| Tip card top | ~556 | ~566 | +8–10 (same shift; corner radius adds ±2 detector tolerance) |
| Tab-bar top | 727.0 | 727.0 | 0 (shell chrome exact) |
| Card gutters | x 20–370 | x 20–370 | 0, aligned |

## Findings (must fix)

1. Date-line suffix wrong — copy bug, not DB-driven content. Design: `A fresh nest`. App: `Happy week: 4 days` (both themes; day part `Mon 5 Oct` itself is legitimately DB-driven — seed anchored to today — and excluded). A brand-new family with zero quests showing "Happy week: 4 days" is nonsense a designer would reject. Root cause chain (read-only): `today_bloc.dart:65-66` gates the suffix on `summaries.isEmpty`, but `watchSummaries()` (`today_repository_impl.dart:59-83`) emits one summary per child even with zero quests, and `happyDays` comes from the seeded child column (`kid.happyDays`), which is 4 for Maya because `Seed.newFamily` reuses `_childrenDemo` (`seed.dart:110,236-270`). Fix: gate the suffix on `items.isEmpty` (no active quests — the same condition that selects the empty branch) so any quest-less nest shows the static `A fresh nest` suffix; the 2-child message variant already renders correctly.
2. Body content shifted +8 px vertically (table above: title, card, button, tip all +8; exceeds the ±2 px rule; a uniform shift of body content is explicitly a FAIL). Tab bar is exact, so this is a body-only top inset — likely the status reserve (47) plus a second 8 pt inset (SafeArea/status padding stacking, or scroll top padding applied on top of the greet's own `padding-top: 8`). Fix: remove the extra 8 pt top inset in the empty greeting/scroll path so the title lands at y 53; P08 populated path must not move.
3. "Browse ideas" underline colour wrong. Design: sky underline (pixel scan: underline row all sky-blue, zero dark pixels). App: ink/dark underline under sky text (light: 73-px dark run `(16,16,48)` at y 522 with zero blue pixels; dark theme shows a white-ish underline the same way). Text colour/weight correct in both. Fix: set `decorationColor` to the sky token on the link `TextStyle` (the CSS has no `text-decoration-color`, but the design PNG renders the UA-default sky underline — match the PNG).

## Checked and passing

- Presence/order: greeting (no `+`, no avatar) → empty card (art, h2, message, 8 px spacer, primary button, link row) → inset tip → tab bar (Today active leaf). No overflow, no clipping, no ellipsis anywhere.
- Copy byte-exact vs HTML source: `Your nest is quiet`; two-sentence message with `Maya and Leo` in creation order (orchestrator 2-child variant); tip title/body with curly quotes, em dash (`each — "Make`), en dash (`Reading – 20 minutes`); `Add a quest`; `Browse ideas`; greeting `Good morning, Sarah` (real-clock morning, parent name from DB).
- Button shape: h 52, x 40–350, pill, leaf fill, white (light) / dark (dark) label — rect exact apart from the +8 y shift.
- Tip card: inset variant, r 24, no shadow, correct padding/typography both themes.
- Bottom edge (owner rule): app runs the tab-bar surface (`#FFFFFF` light) to the physical screen edge (sampled y 815–843 all surface). The design PNG's cream strip + pill under the tab bar predates the owner rule — the app correctly follows the rule, not the PNG. PASS aspect.
- Dark mode: identical geometry to light; card/inset/button/link colours match dark tokens (leaf `#3CC98A`-family button with dark label, sky link); no colour deviation found.
- Tab bar icons/labels: Today active leaf, Quests/Money/Family ink-3 — exact, top at 727 like the design.

## Explicit non-findings (do not "fix")

- Pip art differs from the PNG (v1 egg SVG vs rendered PipAvatar mochi·sunny stage 1, 140 px): MANDATED by the PIP orchestrator rule — the app is correct, the PNG is overridden.
- Money tab glyph differs (design credit-card vs app banknote): shared `NestIcons.money` (`nestling_assets.dart:69`), identical on every parent screen (P08/P10/P12/P15/P16/P08b) — not a P08b deviation; flagged for the orchestrator as possible shared design-system follow-up, not a P08b fix (this stage may not touch `core/`).
- Status-bar time/glyphs (`03:29/03:30` vs `9:41`, icon shapes): OS-drawn, ignored per rule.
- Date day-part (`Mon 5 Oct` vs `Sat 4 Oct`): DB-driven (seed anchored to today via `Seed.anchorDay`), excluded per DATA OVER MOCKS / UI VERDICT RULE. Only the suffix (finding 1) is a bug.

No code edited (read-only inspection plus `shot.sh`/`compare.py` outputs). Temporary icon crops removed; `ui/` contains only the four required PNGs.


## From 6_bugs.md
# P08b · Today empty — Stage 6 bugs (iteration 1)

Adversarial pass over `/today-empty` (`Seed.newFamily` — the mandated P08b
UI-check state — plus `Seed.empty`, demo, and crafted DB states). Five bugs
proven with failing tests; no screen code was changed. Proofs:
`app/test/features/today/p08b_bugs_test.dart`.

Skip note: this Flutter version's `testWidgets` accepts `skip: bool` only
(a `skip:` string is not allowed), so each proof carries `skip: true` with
its bug id in the test name and a comment; `flutter test --run-skipped`
shows all five fail as documented.

**Three majors ⇒ VERDICT: FAIL.**

---

## P08b-B01 · MAJOR · Empty-state date line says “Happy week: 4 days” instead of “A fresh nest”

**Where** `presentation/bloc/today_bloc.dart` (dateLine) vs
`presentation/widgets/today_loaded_body.dart` (empty branch).

**Repro** Launch with `SEED=new_family` (Sarah + Maya + Leo, no quests) at
`/today-empty`. The quiet-nest card renders, but the date line reads:

```
Sat 3 Oct · Happy week: 4 days
```

The design (HTML line 13, both PNGs) says `Sat 4 Oct · A fresh nest` →
pinned clock = `Sat 3 Oct · A fresh nest`. The app's own probe printed
`dateLine="Sat 3 Oct · Happy week: 4 days"`.

**Root cause** The shared empty body triggers on
`state.items.isEmpty || state.summaries.isEmpty`, but the bloc picks the
suffix with `summaries.isEmpty` only. `new_family` has children
(`summaries` non-empty) and no assigned quests (`items` empty), so the body
shows P08b while the date line falls through to `happyWeekLabel(happyDays)`
— and the seed's Maya has `happyDays: 4`.

**Failing test** `[P08b-B01] new-family date line reads A fresh nest, not
Happy week`.

**Suggested fix** Use the same predicate in the bloc:

```dart
final isEmpty = items.isEmpty || summaries.isEmpty;
// dateLine: '${formatLondonDay(now)} · ${isEmpty ? 'A fresh nest' : happyWeekLabel(happyDays)}'
```

P08's demo path cannot move (its `items` are never empty).

---

## P08b-B02 · MAJOR · Empty message names children in age order, not creation order

**Where** `data/today_repository_impl.dart` — `watchSummaries()` re-sorts.

**Repro** `new_family` + insert `Zara` (12) **after** Maya and Leo, then open
`/today-empty`. The mandatory CHILD ORDER ruling (creation order: Maya,
Leo, Zara) expects:

```
Add your first quest and Pip will start to hatch. Maya, Leo and Zara will see it straight away.
```

The app renders (probe output):

```
… Zara, Maya and Leo will see it straight away.
```

Because `watchSummaries` sorts by `ageYears` descending, then nickname —
overriding `watchChildren`'s documented creation order (`createdAt`, then
`rowid`; schema comment: “Roster order is creation order everywhere (CHILD
ORDER ruling)”). Ties between same-aged children fall back to an
alphabetical sort, which the ruling also forbids.

**Failing test** `[P08b-B02] empty message names children in creation
order`.

**Suggested fix** Keep the `kids` order returned by `watchChildren` in
`watchSummaries` (drop the sort). The demo/new-family seeds are unaffected
(Maya is added first and oldest), so P08's kids grid does not move.

---

## P08b-B03 · MAJOR · Whole empty body shifted 8 px down by an extra greeting top padding

**Where** `_EmptyGreeting` in `presentation/widgets/today_loaded_body.dart`
(`Padding(top: NestSpacing.s2)`).

**Repro** `/today-empty` at 390×844. Measured in the widget tree:

| element | design (scroll-relative) | app |
|---|---|---|
| greeting (h1 box top) | 0 | **8** |
| empty card top | 74 | **82** |

The design's `.greet { padding-top: 8px }` lives in **P08's** local CSS
(`P08-today.html:3`), not P08b's. P08b's `.greet` has no padding, and both
PNGs place the card top at logical y = 121 = 47 (status bar) + 34 + 2 + 22 +
16 — i.e. the h1 starts exactly at the status-bar bottom. The shared empty
greeting copied P08's 8 px, so greeting, card and tip all sit 8 px low — a
uniform vertical shift, which the UI-verdict rule fails even if elements
“look the same”.

**Failing test** `[P08b-B03] empty greeting starts at the scroll origin, no
8 px pad`.

**Suggested fix** Drop the top padding in `_EmptyGreeting`; the populated
P08 `_Greeting` keeps its own (correct for P08).

---

## P08b-B04 · MINOR · Greeting is clipped, not wrapped, at text scale 1.3

**Where** `_EmptyGreeting` (`maxLines: 1`, `TextOverflow.ellipsis`).

**Repro** `/today-empty` at 390 px (and 320 px) with system text scale 1.3:
“Good morning, Sarah” exceeds the single line and paints clipped
(“Good morning, Sara…”). `RenderParagraph.didExceedMaxLines == true` with
the bundled Nunito Black loaded. P08b's CSS sets no `white-space: nowrap`
(that trick is P08's), so the design wraps instead of cutting the parent's
name. Note the plan contradicts itself: §a says `maxLines 1`, §e says the
title wraps — the CSS side wins.

**Failing test** `[P08b-B04] greeting wraps instead of clipping at text
scale 1.3`.

**Suggested fix** Allow the greeting two lines at large scales (`maxLines:
2`, keep the ellipsis only as a last resort), keeping `NestType.h1`.

---

## P08b-B05 · MINOR · “Browse ideas” underline paints in ink, not sky

**Where** `_EmptyCard` link `Text` (`today_loaded_body.dart`); the same
finding is independently measured by the 5_ui stage (finding 3).

**Repro** `/today-empty`, both themes. The design PNG's underline row is
solid sky — light `(37,99,214)` (pixel scan y = 512, 290 px wide, zero dark
pixels). The app paints the underline in the ambient ink: light
`(30,27,58)` at y ≈ 521.3–522, dark `(243,240,250)` at y ≈ 521.3–522.
`TextStyle.decorationColor` is null, so the engine falls back to the
paragraph's default foreground (ink) instead of the span's sky colour.

**Failing test** `[P08b-B05] Browse ideas underline paints sky, not ink`.

**Suggested fix** Add `decorationColor: tokens.sky` to the link style:

```dart
NestType.bodySmallStrong(color: tokens.sky).copyWith(
  decoration: TextDecoration.underline,
  decorationColor: tokens.sky,
)
```

---

## Hunted clean (pinned by passing tests in the same file)

| Area | Result |
|---|---|
| Rapid double-tap “Add a quest” (same frame, and one frame apart) | one editor, no stacking |
| Back from `/quest-editor` | returns to `/today-empty` |
| Restart over the same Drift DB | empty state + child names persist |
| “Browse ideas” semantics | `SemanticsAction.tap` present; `performAction` → `/quests` |
| 320 px + 1.3×, two names | message fits (4 lines), no overflow/exception |
| 6 children, long UK names, 390 px | full message fits (5 lines — exactly at the cap) |
| Bottom edge light + dark | tab bar surface to the physical edge, Today active (0) |
| BST end (24/25 Oct 2026) | date line stays Europe/London |
| Kid-mode deep link to `/today-empty` | already proven by `[P08-B01]` (p08_bugs_test.dart); suite green |
| £0.00 / £999.99 / 9999 coins | N/A — this screen renders no money |
| Async gaps / emit-after-close | none observed (bloc factory per route; guards per frame) |

Observation (not a bug): the “Browse ideas” row is 46 px tall vs the
design's 44 (`min-height:44px`; the plan said 11 px padding, the code uses
`NestSpacing.s3` = 12). It pushes the tip card +2 px, exactly at the ±2 px
UI tolerance — flagging for the UI stage, no fix demanded here.

## Verification

```
$ dart format test/features/today/p08b_bugs_test.dart
Formatted 1 file (0 changed)

$ flutter analyze test/features/today/p08b_bugs_test.dart
No issues found!

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart
+9 ~5: All tests passed!

$ flutter test --timeout 120s --run-skipped test/features/today/p08b_bugs_test.dart
9 passed, 5 failed = the five proofs above (B01–B05) fail as documented

$ flutter test --timeout 120s test/features/today/p08b_bugs_test.dart \
    test/features/today/today_view_test.dart test/features/today/today_bloc_test.dart \
    test/features/today/today_repository_test.dart test/features/today/today_semantics_tap_test.dart
+101 ~5: All tests passed!
```

No simulator was booted, installed on or driven (stage rule); no screen code
was edited (`do not fix the screen`); only
`app/test/features/today/p08b_bugs_test.dart` and this report were created
(RULES §1).

