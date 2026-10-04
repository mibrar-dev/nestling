# 3 — TEST (iteration 3) — K06 · Pip's nest (`/pip`, feature `pip`)

In-memory Drift + `Seed.demo` / `Seed.empty`. **No simulator was booted,
installed on, screenshot or driven** (stage rule — only `5_ui` may, and only
on 604697A9-…-396E9CA2493A). No `flutter clean`, no `analysis_options` change,
no image attached. **No product code touched** — iteration 3's build
(`a17df6b`) is what changed the screen; this stage verified it and covered the
contract changes it introduced.

## Headline

```
dart format --output=none --set-exit-if-changed .   → 587 files (0 changed)  exit 0
flutter analyze                                    → No issues found!         exit 0
flutter test --timeout 120s test/features/pip      → +219 ~1: All tests passed! exit 0
flutter test --timeout 120s                        → +3790 ~5: All tests passed! exit 0
```

`~1` in the feature directory is **one** parked proof: the sun-hat glyph
(`SHARED_REQUEST.md` §7, a shared asset a screen agent may not edit — §4).
Every other parked proof from iterations 1 and 2 is now live and green.
`~5` in the whole repo adds four pre-existing non-K06 skips, none of them
K06's and none touched by this stage: `k01_bugs_test.dart:569`,
`k03_bugs_test.dart:1665`, `k03_bugs_test.dart:1733` and
`p12_bugs_test.dart:321`. K06's own parked proofs are exactly the one above.

## VERDICT: PASS

Both conditions the brief sets are met: **all tests pass** (feature and whole
repo) and **this stage found no bug**.

The screen still carries the review stage's open **major** — the 13:52
component switch is only 2/5 landed (`4_review.md` finding 1) — and one parked
glyph proof. Both are §4; neither is a test-stage bug, and this PASS must not
be read as "K06 is done".

## 1. What iteration 3 changed, and what I verified

| Change | Code | Verified by |
|---|---|---|
| **K06-BUG-7 fixed** — a purchase the fresh balance refuses answered the tap with silence | `PipRepository.buyItem` returns `Future<PipBuyResult>` (`bought \| cannotAfford \| alreadyOwned \| unavailable`); the bloc announces only `cannotAfford` | the build's fake-repository proof + the un-skipped burst proof in `k06_bugs_test.dart`; **and my 18 new tests** at the result, mapping and sequence layers (§2) |
| **the outcome now survives a refresh** — `PipState.copyWithLoaded` carries `actionError` + `actionNonce` instead of clearing them, so the refused tap's toast is not wiped by the sibling purchase's stream emission | `pip_state.dart` | the build's unit proof; **and my sequence proofs** — survives, announced exactly once (the view's real `listenWhen` predicate), clears on the next attempt, and a success between two refusals still announces the second |
| **item 2 glyphs** — `pipWardrobeIcon` → `NestIcons.wardrobeScarf` / `.wardrobeWellies` (batch 7's exact HTML paths) | `pip_look.dart` | the byte proofs (now live) read the design source at test time; **plus my new non-circular proof** that each named tile really paints `ic_wardrobe_scarf.svg` / `ic_wardrobe_wellies.svg` and not the look-alike files — the byte proofs alone would still pass if the screen pointed back at the old files |
| **item 3 prices** — the seed moved to the design's 30/60 on `shared_batch7` | `seed.dart` (core) | `K06-BATCH7` is live and green with **no expectation changed**, plus the green "follows the row" proofs (one re-seeds Crown to 7) |

Two things I checked rather than assumed, because the price change touched
every premise:

* **No stale price literals survive.** `grep` across `app/test/features/pip`
  and `app/lib/features/pip` finds no `40`/`120` price literal anywhere; the
  remaining 120s and 40s are coin *balances* (Maya's 120 coins, Leo's 45→40).
* **One premise had gone vacuous and was rebuilt honestly.** The two-item
  burst probe ("a 120 balance cannot afford both 40 and 120") became
  meaningless at 30/60 — the balance affords both. The build re-based it to a
  balance *strictly between* the two seeded prices and asserts the premise
  (`sum > balance`) so the probe cannot silently stop testing anything. My
  `pip_buy_result_test.dart` does the same thing independently and reads both
  prices from the rows rather than typing them.

## 2. Tests added this stage

One new file (18 tests) and two additions to an existing one. All inside
`app/test/features/pip/` (RULES §1). No existing assertion was weakened.

### `pip_buy_result_test.dart` (18, new) — the iteration-3 contract

Both halves of the BUG-7 fix are contract changes, so both are pinned here.

* **The four outcomes, from the real database** (7): `bought` charges exactly
  the **ROW's** price — read back with a `priceOf()` helper, this file types
  no price at all — and flips the label from the price to `Owned`;
  `cannotAfford` and `alreadyOwned` write nothing; **`unavailable`** (unknown
  item id, unknown child) is the one enum value no other test names, and both
  paths must leave the wardrobe rows and the balance untouched; a same-item
  burst reports exactly `{bought, alreadyOwned}` and charges once — a second
  `bought` there would let the bloc announce a phantom purchase; a two-item
  burst on a between-prices balance yields one `bought` and one
  `cannotAfford`.
* **Only `cannotAfford` is announced** (4): a table walk over the other three
  outcomes asserting no `actionError`, **no state carrying one**, and — the
  sharpest form — that the *view's own gate* would never fire, i.e. zero
  toasts. If `alreadyOwned` announced, a double tap on one tile would nag the
  child about a purchase that simply worked.
* **The carried outcome, as a sequence** (4): a real-database burst proves the
  refusal is still the state the screen is left in *and* that it was announced
  exactly once, not again when the sibling purchase refreshed the nest; a
  carried outcome clears on the next successful attempt; two refusals in a row
  still announce twice with the nonce sequence `0, 0, 1, 0, 1` (load, refusal,
  reset, refusal); and the one sequence the carry change could plausibly
  break — a *successful* purchase between two refusals — still announces both.
* **`PipState` itself** (3): `copyWithLoaded` carries the outcome and nonce but
  drops a stale **load** `errorMessage`; `withActionStarted` still forgets it;
  `toLoading` still carries it (the retry path).

  The toast counting evaluates the view's **actual** predicate —
  `previous.actionNonce != current.actionNonce && current.actionError != null`
  — copied from `pip_nest_view.dart` with a comment saying so, so a change
  there has to be mirrored deliberately. It walks *consecutive pairs*: two
  identical states are `==`, so `indexOf` would always return the first and
  the count would be meaningless (an iteration-1 lesson, re-learned here after
  a first draft used exactly that).

### `pip_orchestrator_notes_test.dart` (+1, corrected 1)

* **New**: the two tiles the note names must render
  `ic_wardrobe_scarf.svg` / `ic_wardrobe_wellies.svg` **by file name** and
  must not fall back to the superseded look-alikes. This is what closes the
  circularity in the byte proofs, which read whatever `pipWardrobeIcon()`
  returns.
* **Corrected**: the re-seed proof asserted `find.text('120')` findsNothing —
  a stale literal (the seed has been 60 since batch 7) that would have passed
  for the wrong reason. It now reads the row's previous value, consistent with
  that group's own "a price is never a literal" rule.

## 3. Two wrong-premise assertions of my own (found and fixed before the
suite went green — recorded because stage 4 saw the draft)

`4_review.md` finding 8 caught `pip_buy_result_test.dart` mid-write and named
both red lines. They were mine, and my analysis of each matched the review's:

1. the post-purchase `PipStage.detail` is `'Owned'`, not the price — the tile's
   copy rule, which I had misread as "the price stays on the row";
2. the collected nonce log starts with the load's two states, so the sequence
   is `[0, 0, 1, 0, 1]` (including the load) and not `[1, 0, 1]`.

Both are fixed; the file is now 18/18. Nothing else in the repo was red at any
point in this stage, and the review's other note — that the in-flight draft
should be fixed or deleted before the commit — is satisfied.

## 4. Open items (not test-stage bugs, recorded so this PASS is not misread)

| Item | Severity | Who owns it |
|---|---|---|
| **The 13:52 component switch is 2/5 landed** (`4_review.md` finding 1): glyphs and prices adopted; `PipCareButton` → `NestKidButton(trailing:)`, `PipNestSlot` → `NestPetStage(…)`, the local `_DashedBorderPainter` → `NestDashedBorder` are **not**. The note is mandatory ("switch to the shared ones and delete the local copies") | **major** | the next build iteration; the review FAILs the screen for it |
| **Sun-hat glyph** — `ic_sun_hat.svg` still carries the same silhouette on different coordinates plus an extra brim stroke (`SHARED_REQUEST.md` §7, filed by the build stage; my proof found it) | minor, design fidelity | a shared asset; parked proof |
| `kPipNotWearable` — still the only on-screen string not in the design | copy | awaiting ratification (`2_build.md` §5.2) |
| `NestProgress`'s kid highlight spans the whole track | shared component | core's; deliberately not pinned green by me |
| `pipStageName()` in `domain/`, the view reading `PipRepositoryImpl`'s cost constants, `_BackButton` re-rolling `NestIconButton` | minors | `4_review.md` findings 2–4, carried |

Nothing new was filed by this stage.

## 5. Coverage against the stage brief

| Required | Where | Status |
|---|---|---|
| bloc_test for every event/state path | `pip_bloc_test.dart` (18) + `pip_bloc_actions_test.dart` (22) + the mapping and carry-through groups in `pip_buy_result_test.dart` (18) | ✅ |
| light + dark | every widget group; dark × 320/430 for the loaded body, failure card and no-child card | ✅ |
| widths 320 / 390 / 430 | real surfaces, asserted inside every `_pumpNest` (the size is applied *after* `pumpAppRoute`, which pins 390 itself) | ✅ |
| text scale 1.0 / 1.3 | fit matrix on the loaded body, the failure/no-child cards, and the care-height proofs at all six width × scale combinations | ✅ |
| empty / loading / error | `pip_nest_states_test.dart` (19) | ✅ |
| every tap → right route | Back → `/kid-home` (loaded, failure, no-child), lock → `/parental-gate`, Choose → `/who-is-playing`, six non-navigating taps proven to stay on `/pip`, and the burst proof still on `/pip` | ✅ |
| semantics labels on icon buttons | Back / Grown-ups read from the HTML `aria-label`s; every control asserts `hasAction(tap)`; disabled care buttons assert `enabled: false` + no tap; the toast gate itself is now pinned; `performAction` drives the real DB | ✅ |
| tap targets ≥ 44 parent / ≥ 56 kid | ≥ 56 both axes for all 9 controls + hit test 5 px inside every corner; the height proofs keep ≥ 56 at 320/430 and 1.3× | ✅ |
| in-memory Drift, Seed.demo / empty | all thirteen K06 files | ✅ |

Standing rules: no `google_fonts`/`GoogleFonts`, no `DateTime.now()`, no new
rows, no `letterSpacing` added, `NestBalancedText` on the `.kid-title` intact,
one shared `KidScope` + meadow, no bottom bar, `disposeApp` inside every pumped
test's body, no `google_fonts`, no `DateTime.now()` in feature tests.

## 6. Hand-off for the next build (the component swap)

When the three local widgets are swapped for the shared ones, **only imports
and two fixtures move — no assertion changes**:

* `pip_iter2_fixes_test.dart` imports `PipCareButton`, `PipNestSlot`,
  `PipWardrobeTile`, and asserts the rendered *result* (care heights, the
  `SvgPicture`'s `fit` and painted width, one height per press). A
  `NestPetStage`-based slot that paints the same 230 × 206 box with
  `BoxFit.contain` satisfies it as-is.
* `pip_nest_widget_test.dart` pins the same rendered geometry and will need
  only its widget-type imports re-pointed at the shared components.
* `kPipWardrobeTile` → the shared tile + `NestDashedBorder` keeps every
  colour, inset and art-circle assertion I wrote (surface-2 fill, white art
  circle, 30 px glyph, shared inset).

That is deliberate: those proofs are behavioural so a refactor cannot silently
change what the screen draws. The one thing that **will** need re-checking by
hand is the dark-mode dashed-border pixel probe in `k06_bugs_test.dart` (stage
6's), which reads painted pixels of the local painter.

Also for the next stage: my price expectations read the **row**, so if the seed
prices move again, no edit is needed here (the `K06-BATCH7` proof reads the
HTML and would catch a design/seed divergence on its own).

## 7. Files changed by this stage

* `app/test/features/pip/pip_buy_result_test.dart` (new, 18 tests)
* `app/test/features/pip/pip_orchestrator_notes_test.dart` (edited: +1 glyph
  asset proof, 1 stale price literal re-based on the row)
* `docs/screens/K06/3_test.md` (this file)

No `app/lib/**` file was touched. The other modified paths in `git status`
(`docs/screens/K06/.brief_*.md`) are the loop's own brief refreshes.

VERDICT: PASS
