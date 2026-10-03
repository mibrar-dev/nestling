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

VERDICT: FAIL