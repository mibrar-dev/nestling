# 3 — TEST (iteration 2) — K06 · Pip's nest (`/pip`, feature `pip`)

In-memory Drift + `Seed.demo` / `Seed.empty`. **No simulator was booted,
installed on, screenshot or driven** (stage rule — only `5_ui` may, and only
on 604697A9-…-396E9CA2493A). No `flutter clean`, no `analysis_options`
change, no image attached. **No product code touched by this stage** — every
fix below was already in the iteration-2 build (`a7da86b`); this stage verified
it and added the proofs it was missing.

## Headline

```
dart format --output=none --set-exit-if-changed .   → 568 files (0 changed)  exit 0
flutter analyze                                    → No issues found!         exit 0
flutter test --timeout 120s test/features/pip      → +193 ~6: All tests passed! exit 0
flutter test --timeout 120s                        → +3576 ~8: All tests passed! exit 0
```

`~6` in the feature directory is 6 parked proofs, every one of them a
**shared-blocked or already-filed** defect with a runnable repro (§4). `~8` in
the whole repo adds the two pre-existing skips (`k01_bugs_test.dart`
K01-BUG-7, `p12_bugs_test.dart` P12-BUG-04), neither K06's. In
`test/features/pip` there are 4 `skip: true` lines and they make **6** parked
tests: the three glyph proofs are one declaration inside a 3-iteration loop.

## VERDICT: PASS

Both conditions the brief sets are met: **all tests pass** (feature and whole
repo, twice each) and **this stage found no new bug**.

The screen is *not* finished, and this verdict must not be read as "it is":
one minor bug is open (**K06-BUG-7**), and four proofs are parked on work that
is not a screen finding — the mandatory `ORCHESTRATOR_NOTES` item 2 glyphs and
item 3 prices, which `ORCHESTRATOR_NOTES` **13:52** has taken onto
`shared/shared_batch7` ("they are not K06 findings meanwhile"). §4 and §6 spell
out what a reader needs to know.

## 1. What iteration 2 changed, and what I did about it

The build fixed all six iteration-1 bugs. I verified each fix rather than
trusting `2_build.md`, and covered the branches the build's own proofs did not
reach:

| Fix | Code | Proofs the build left | What I added |
|---|---|---|---|
| **BUG-1** lost update | `_care` is now one conditional `customUpdate` | 5 concurrent feeds; the BUG-1 burst | the **affordability guard** under concurrency (7 coins → exactly one Feed; 2 coins → nothing at all; 5 coins → inclusive), a mixed care burst, per-child independence, unknown children — `pip_atomic_writes_test.dart` |
| **BUG-2** concurrent buys | one transaction, conditional deduction, claim-only-while-unowned | wellies+crown; same-item×3 | the **boundary** (40 coins buys the 40-coin wellies; 39 buys nothing), unknown child/item, already-owned, plus the widget-level consequence — `pip_atomic_writes_test.dart`, `pip_iter2_fixes_test.dart` |
| **BUG-3** apostrophe | `"Pip's wardrobe"` (ASCII) | BUG-3 + the byte oracle | nothing needed; both green |
| **BUG-4** nest art | box 230 × 206, `BoxFit.contain` | the BOX, and that the art box is centred | the **FIT** (`BoxFit.contain`) and a **paint-level** probe: the bowl measures ~173 px wide and centred, which a right-box/`fill` draw would fail — `pip_iter2_fixes_test.dart` |
| **BUG-5** care heights | `IntrinsicHeight` + stretch | equal heights at 390/1.3× | equal heights at **320 and 430** and at both scales, the design's **91 px at 1.0×** (the regression the fix could cause), and a **held press** not feeding layout back — `pip_iter2_fixes_test.dart` |
| **BUG-6** dashed border | `CustomPaint.foregroundPainter` | light + dark pixel probes, painter wiring, art insets | nothing needed; green |
| **`4_review.md` #11** | progress label = the design's aria wording | two assertions moved | the label is now compared against the **HTML's own `aria-label`** with only the number generalised — the oracle gap §6 of iteration 1 documented is closed — `pip_iter2_fixes_test.dart` |

## 2. Tests added this stage

Two new files, 30 tests (29 green, 1 parked), both inside
`app/test/features/pip/` (RULES §1). No existing K06 test file was edited.

### `pip_atomic_writes_test.dart` (17) — the rewrite's own branches

`Future.wait` bursts over the real repository, because the whole point of the
fix is concurrency. Plain `test`s, never `testWidgets`: awaiting a Drift stream
inside the fake-async zone never completes (an iteration-1 lesson).

* **Affordability is part of the write** (7): 7 coins and three Feeds → exactly
  one charge, 2 coins left, happiness clamped; 2 coins and four care taps →
  *nothing at all* moves (both prices are over the balance — my first attempt
  used 4 coins and wrongly expected Bath to be refused too, which the test
  caught); 5 coins buys exactly one Feed (the price is inclusive); Play is
  still free at 0; a mixed burst spends every coin it is entitled to (120 →
  107); an unknown child no-ops on all three actions; two children bill
  independently.
* **The wardrobe transaction** (7): 40 coins buys the 40-coin wellies, 39 buys
  nothing, an unknown child/item buys nothing, a same-item burst pays once, a
  two-item burst on 120 can afford exactly one, an already-owned item is never
  re-charged, buying leaves the equip path untouched.
* **A refused write must not move the screen** (2): this is the part the
  iteration-1 suite could not see. Drift's `customUpdate` notifies the tables it
  is given **even when the statement changed zero rows** (it cannot know), so a
  refused write *does* push an identical nest down `watchNest()`. That is
  harmless only because `copyWithLoaded` of an unchanged nest is an `==`-equal
  state and flutter_bloc drops it — so that collapse is now pinned from both
  sides: a refused care emits **no** state at all, and a refused buy leaves the
  tile locked. If a future change makes the refused write produce a *distinct*
  state, the screen would rebuild and could re-announce a toast nobody earned.

### `pip_iter2_fixes_test.dart` (13, 1 parked) — the fixes at their own layer

* **BUG-4**: the art is `BoxFit.contain` (a box-only assertion cannot tell
  `contain` from `fill`, which *was* the bug), plus a pixel probe inside a
  `RepaintBoundary`: sampled against the sky at x = 2 (the letterbox strip) in
  the rows **below** the Pip, the bowl measures 173 ± 8 px and sits on the
  slot's axis. A stretched draw measures ~194 px.
* **BUG-5**: equal heights at 1.0× and 1.3×, at 390/320/430; exactly the
  design's 91 px at 1.0× (the metric `IntrinsicHeight` could have moved); and a
  **held press** keeps the row height — a press is a 4 px translate inside an
  `AnimatedContainer`, and if that animation ever fed back into layout the row
  would lose its one height.
* **#11**: the progress label is matched against the HTML's own
  `aria-label="Pip is 70% of the way to Songbird"` with only `70%` generalised
  to `\d+%`, plus the exact seeded number (175/250 = 70 %), plus the two
  wordings that must not return ("way to a Songbird", an article).
* **The fixes did not disturb the rest**: four tiles in design order; the three
  care buttons keep their own semantics.

## 3. Two authoring traps, both mine, both fixed (recorded, not findings)

1. `await repo.watchNest().first` inside a `testWidgets` body **never
   completes** under fake async — it wedges the whole file. Kept out of both
   new files (plain `test`s, or a literal fixture).
2. `find.bySemanticsLabel('some string')` cannot match the progress node: the
   shared `NestProgress` puts a `value` on the same node *and* the node sits
   inside the growth card's merged semantics node, so an exact or `^`-anchored
   match never hits. Measured, then written as an unanchored pattern built from
   the design source.

## 4. Bugs

### Found this iteration: none

I did reach one real defect independently — **a purchase the database refuses
answers the tap with silence** — and stage 6 had already filed it as
**K06-BUG-7** (`6_bugs.md`, parked in `k06_bugs_test.dart`). Their proof is
bloc-level (`bloc.state.actionError` must be `kPipNotEnoughCoins`); mine drives
the **real taps** and asserts the **toast the child actually sees**, which their
proof would pass even if the view's `BlocListener` were broken. Both are parked;
mine is the view half of the same finding:

```
flutter test test/features/pip/pip_iter2_fixes_test.dart --run-skipped \
  --plain-name K06-BUG-7
  → Expected: exactly one matching candidate
    Actual: Found 0 widgets with text "Not enough coins yet — keep going!"
```

Caveat I want on record: both proofs assert the exact constant
`kPipNotEnoughCoins`, so a legitimate fix that words the refusal differently
would fail them. That is the right default (the design's copy exists and should
be reused), but whoever fixes it should read both before editing.

### Inherited, still open

| # | Severity | Status |
|---|---|---|
| K06-BUG-7 | minor | OPEN — a buy refused by the fresh balance is silent. 2 proofs, both parked |
| `ORCHESTRATOR_NOTES` item 2 · glyphs (`5_ui` D2) | was major | **Not a K06 finding** per `ORCHESTRATOR_NOTES` **13:52**: `SHARED_REQUEST.md` §5 is being fixed on `shared/shared_batch7`. My 3 parked proofs fail for exactly that reason and nothing else — verified again this iteration (`--run-skipped`: scarf/wellies/sunhat path data still differ from the HTML's) |
| `ORCHESTRATOR_NOTES` item 3 · prices | data ruling | **Not a K06 finding** per the same note: the seed moves to the design's 30/60 on that batch. New parked proof below |
| `kPipNotWearable` | copy | Still the only on-screen string not in the design, still awaiting ratification (`2_build.md` §5.2). Unchanged since iteration 1 |
| `NestProgress`'s kid highlight spans the whole track | shared component | Carried over; core's, not K06's, and deliberately **not** pinned green by me |

### The iteration-1 findings: all fixed, verified live

BUG-1…BUG-6 run **un-skipped** now (`k06_bugs_test.dart` has no `skip:` left,
and neither has `pip_copy_parity_test.dart`). `flutter test test/features/pip`
→ `+193 ~6` with those six proofs inside the green count.

## 5. Coverage against the stage brief

| Required | Where | Status |
|---|---|---|
| bloc_test for every event/state path | `pip_bloc_test.dart` (18) + `pip_bloc_actions_test.dart` (22) + the refusal group in `pip_atomic_writes_test.dart` | ✅ |
| light + dark | every group; dark × 320/430 for the loaded body, failure card and no-child card | ✅ |
| widths 320 / 390 / 430 | real surfaces, asserted inside every `_pumpNest` | ✅ |
| text scale 1.0 / 1.3 | fit matrix on the loaded body, failure/no-child cards, and the new care-height proofs at all six width × scale combinations | ✅ |
| empty / loading / error | `pip_nest_states_test.dart` (19) — unchanged and still green | ✅ |
| every tap → right route | Back → `/kid-home` (loaded, failure, no-child), lock → `/parental-gate`, Choose → `/who-is-playing`, six non-navigating taps proven to stay on `/pip` | ✅ |
| semantics labels on icon buttons | Back / Grown-ups from the HTML `aria-label`s; every control asserts `hasAction(tap)`; disabled care buttons assert `enabled: false` + no tap; `performAction` drives the real DB | ✅ |
| tap targets ≥ 44 parent / ≥ 56 kid | ≥ 56 both axes for all 9 controls + hit test 5 px inside every corner; the new height proofs keep ≥ 56 at 320/430 and 1.3× | ✅ |
| in-memory Drift, Seed.demo / empty | all twelve K06 files | ✅ |

Standing rules: no `google_fonts`/`GoogleFonts`, no `DateTime.now()`, no new
rows, no `letterSpacing` added, `NestBalancedText` on the `.kid-title` intact,
one shared `KidScope` + meadow, no bottom bar, `disposeApp` inside every pumped
test's body.

## 6. Hand-off — what moves when `shared_batch7` merges

That batch moves the seed's wardrobe prices to the design's **30/60** and lands
the design glyphs. Both are watched by parked proofs that go green on their own:

```
flutter test test/features/pip/pip_orchestrator_notes_test.dart --run-skipped
  → the three glyph proofs and K06-BATCH7 flip green
```

Every **green** assertion that names a seeded price moves with the merge, and
each of my files now says so in its header. The complete list, so nobody has to
grep:

* `pip_atomic_writes_test.dart` — the wardrobe group (40-coin wellies, 120-coin
  crown, the 39/40 boundary, the "120 balance" burst).
* `pip_nest_interactions_test.dart` — `'Wellies, 40 coins'`, `'Crown, 120
  coins'`, the balances after a buy (80, 72), the equip/buy flows.
* `pip_orchestrator_notes_test.dart` — the two green item-3 tests.
* Not mine, but they move too: `pip_nest_view_test.dart`,
  `pip_repository_test.dart`, `k06_bugs_test.dart`.

The design numbers themselves are read from `K06-pip.html` inside
`pip_orchestrator_notes_test.dart`, so the parked proof cannot drift from the
source.

## 7. Files changed by this stage

* `app/test/features/pip/pip_atomic_writes_test.dart` (new, 17 tests)
* `app/test/features/pip/pip_iter2_fixes_test.dart` (new, 13 tests, 1 parked)
* `app/test/features/pip/pip_orchestrator_notes_test.dart` (edited: the 13:52
  header, the parked `K06-BATCH7` end-state proof, and the design-price parser)
* `app/test/features/pip/pip_nest_interactions_test.dart`,
  `app/test/features/pip/pip_atomic_writes_test.dart` (header notes only)
* `docs/screens/K06/3_test.md` (this file)

No `app/lib/**` file was touched. The other modified paths in
`git status` (`k06_bugs_test.dart`, `4_review.md`, `5_ui.md`, `6_bugs.md`,
`ORCHESTRATOR_NOTES.md`, `ui/*.png`) belong to the review/bugs/UI stages running
in parallel in this worktree.

VERDICT: PASS
