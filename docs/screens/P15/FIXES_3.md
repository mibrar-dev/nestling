# Fix list after iteration 3

## From 2_build.md
# P15 · Child profile — Stage 2 INTEGRATE (iteration 3)

Route `/child-profile` · parent mode · feature `family` · light+dark designs.
Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`ORCHESTRATOR_NOTES.md` (exists — all 4 items mandatory, unchanged since 18:13),
`FIXES_1.md`, `FIXES_2.md`, `SHARED_REQUEST.md`, `2a_build_logic.md`,
`2b_build_ui.md`.
`main` was merged before this stage (`b2a8b8f`); the uncommitted tree and the
merge order are loop bookkeeping, not findings.
No simulator was booted, installed on, driven or screenshotted (stage 2 must not).

## Outcome in one line

**P15's own work is complete and green (272/272, analyze clean, format clean),
but the full-suite gate fails on a pre-existing shared/core test that P15 may
not edit — so this stage cannot PASS. Filed as `SHARED_REQUEST.md` §6.**

## Summary of 2a (logic) + 2b (UI)

Again a clean parallel split, and again **CONTRACT CHANGES: none** from both
halves — so there was nothing to reconcile, no mismatched state/event, no
renamed member, no import to rewire. 2a's closing line is "Nothing in the logic
layer is unfinished".

**2a — logic** (`bloc/`, `data/`, `family_routes.dart`):

- **P15-BUG-9 (major)**: a *second* `?childId=` was ignored on the live branch
  page. `BlocProvider.create` runs once per provider element and go_router keys
  the page by matched path, so a later `/child-profile?childId=…` re-rendered
  the page without re-running it. 2a added a private stateful
  `_ChildProfileRoute` wrapper that re-dispatches `FamilyChildSelected` in
  `didUpdateWidget` when the query id changes; the create-time dispatch stays
  so first entry is still selection-before-load. Both skipped proofs
  (BUG-9a/9b) un-skipped and green.
- **Review 3 (minor)**: `watchProfile` could double-subscribe the ledger when a
  multi-table transaction emitted several base events in one `await`. The
  handler now claims the slot synchronously and only the newest run may
  (re)subscribe — an older run can no longer orphan a listener.
- **Review 4/5/8 (minor)**: repoint query cites the shared roster ordering;
  new `SHARED_REQUEST.md` §5 asks for a one-shot
  `childrenInCreationOrder(familyId)`; the two P15 `debugPrint` lines are
  `kDebugMode`-gated; §2 wording refreshed.
- Un-skipped the last `p15_bugs_test.dart` markers.

**2b — UI** (`views/`, `widgets/`, `child_profile_view_test.dart`):

- **P15-BUG-9 (major, view half)**: `ChildProfileView` is now stateful and
  re-dispatches on the router state via `didChangeDependencies` — the same
  mechanism 2a put in the route wrapper, one layer lower, on the widget that
  actually reads the route. Both halves agree; the proofs are green.
- **Cross-feature import removed** (minor): `child_profile_copy.dart` no longer
  imports `moneyPounds` from `pocket_money/presentation/`, which broke the
  per-feature boundary (`ARCHITECTURE.md:75`). It now uses the design-system
  barrel's `formatPounds`; rendered copy (`£3.00 a week · Owed £4.20`) is
  unchanged.
- `ProfileRow` bare geometry (`12/10/16/10`, `40`) → `NestSpacing` tokens.
- `SHARED_REQUEST.md` numbering corrected; §2 corrected to the code's actual
  `leading: (fg) => …` builder form.

## Mandatory ORCHESTRATOR_NOTES items — still satisfied

Both items 2b fixed in iteration 2 are intact (verified in the code, not just
the notes): item 1 — `ProfileRow` keeps the trail outside the flex distribution
so subtitles render in full; item 2 — Quests uses `NestIcons.quests`,
Pocket money the coloured `coin.svg` via a bare `SvgPicture`. Items 3 ("their")
and 4 (DB quest counts) remain deliberate orchestrator rulings, not findings.

## FIXES

| # | Item | Where | Done |
|---|---|---|---|
| 1 | Contract reconciliation between the halves | — | none needed — both reported CONTRACT CHANGES: none |
| 2 | Compile errors / import breaks | — | none |
| 3 | Placeholder-anchor fixes from iteration 1 (`add_children_test.dart` ×4, `today_view_test.dart` ×1) | — | verified still green; `today_view_test.dart` swap recorded in `SHARED_REQUEST.md` §4 for ratification |
| 4 | `p15_bugs_test.dart` skips hiding proofs | 2a | done — every P15 skip removed; `grep -rn "skip" test/features/family/` returns only comments |
| 5 | 2b's hand-back: `child_profile_selection_test.dart` *"an explicit clock decides which period counts"* — 2b believed the expectation was wrong (would need `2` at +1 day, `0` at +8 days) and left it "for the test stage" | `app/test/features/family/child_profile_selection_test.dart:286` | **verified — already correct and green, no change needed** |
| 6 | **`test/core/family_time_test.dart` › *kid_home completions are stamped with the family zone* → `Bad state: Too many elements`** | shared core, **not editable by P15 (RULES §1)** | **left — filed `SHARED_REQUEST.md` §6** |

On #5: the test asserts `4` at the Sat 3 Oct anchor, `2` at +1 day (Sun 4 Oct)
and `0` at +2 days (Mon 5 Oct). That is exactly right under the PERIODS ruling
— the London week runs Mon 29 Sep–Sun 4 Oct, so Sunday's two dailies drop out
while the two weeklies still count, and Monday opens a new week. Ran it by name:
`00:01 +1: All tests passed!` 2b's flag came from the review's stale note, not
from a live red, so nothing was changed.

## The one blocking failure — detail

```
test/core/family_time_test.dart:319
  seed + repository zone plumbing › kid_home completions are stamped with the family zone
  Bad state: Too many elements
```

**It is not a P15 regression and not caused by this merge.** Proof:

- `git diff main HEAD -- app/test/core/family_time_test.dart app/lib/core/data/seed.dart`
  → **empty**. Both files are byte-identical to `main`.
- `git diff --name-only main...HEAD` → this branch touches **no**
  `lib/core/**` and **no** `test/core/**` file. Every changed file is under
  `app/lib/features/family/**`, `app/test/features/family/**`, the one
  recorded `today_view_test.dart` anchor, or `docs/screens/P15/**`.

Cause: the shared demo seed now pre-creates a `to_do` completion row for
`q-plants` (`seed.dart:392`), which this test predates. It then calls
`completeQuest('leo','q-plants')` and asserts `leoRows.single`;
`completeQuest` *flips* an in-period `to_do` row in place but *inserts* a new
one when `inPeriod` is empty, and after `Seed.movedToDubai` the seeded row no
longer satisfies `countsForCurrentPeriod(...)` under `Asia/Dubai` — so two
rows exist. The London leg (`q-reading`) still flips in place and passes,
which is why only the Dubai leg is red.

I did **not** edit it: `app/test/core/**` is shared (RULES §1) and the fix
belongs on `main`, where every other screen loop is hitting the same red. The
full diagnosis and a concrete one-line-intent fix are in
`SHARED_REQUEST.md` §6.

## Verification (run in `app/`, no simulator)

```
$ dart format .
Formatted 496 files (0 changed) in 2.09 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.5s)

$ flutter test
03:22 +2553 ~1 -1: Some tests failed.
Failing tests:
  app/test/core/family_time_test.dart: seed + repository zone plumbing
      kid_home completions are stamped with the family zone

$ flutter test test/features/family
00:39 +272: All tests passed!
```

Format clean. Analyze clean. Full suite **2553 pass / 1 skip / 1 fail** — the
skip is `p12_bugs_test.dart:320` (feature `pocket_money`, pre-existing,
unrelated), the fail is the core test above. **P15's own feature suite is
272/272.** No test was skipped, deleted, reworded or weakened to reach this
point; no `analysis_options.yaml` change; no `google_fonts` anywhere. Nothing
in this stage was edited except this note and `SHARED_REQUEST.md` §6 — I made
**no source change**, because there was no P15 breakage to fix.

## Left for the next stage

1. **Unblock `main`** — `SHARED_REQUEST.md` §6 needs the shared fix in
   `test/core/family_time_test.dart`. Until then the full-suite gate stays red
   for every screen loop, and P15 must not attempt the edit itself. Nothing
   else is outstanding from 2a or 2b.
2. **UI stage (5_ui)** — re-shoot `/child-profile` light + dark on udid
   `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`, `compare.py` against
   `design/screens/{light,dark}/P15-child-profile.png`. Band geometry is
   unchanged (hero 47/164, stats 227/82, Pip 325/116, list 457/180, danger
   653/80), whose iteration-2 `5_ui` measured every edge within ±2 px. Per the
   UI VERDICT RULE, report measured y for the title, the first control and
   each card top, design vs app. The one new thing to confirm: switching a
   child via `?childId=` (the BUG-9 fix) re-renders the body **without any
   vertical shift**.
3. `child_profile_row.dart` stays until `SHARED_REQUEST.md` §1 lands on
   `main`; then delete it and return to `NestListRow` (plus §2b's
   `leadingWidget` for the coin illustration). Open shared asks: §1 (row flex),
   §2b (`leadingWidget`), §3 (`NestPip.rowSlot = 84`), §5 (roster-order query),
   §6 (blocking, above).


## From 3_test.md
# P15 · Child profile — Stage 3 TEST (iteration 3)

Route `/child-profile` · feature `family` · parent mode · light+dark designs.
Tree: branch `screen/P15` at `422e41e8` ("P15: checkpoint after build
(iteration 3)"), `main` merged through `b2a8b8f`.

Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md` (iteration 3), `2a_build_logic.md`, `2b_build_ui.md`,
`3_test.md` (iterations 1–2), `4_review.md`, `5_ui.md`, `6_bugs.md`,
`FIXES_1.md`, `FIXES_2.md`, `SHARED_REQUEST.md` and
**`ORCHESTRATOR_NOTES.md`** (unchanged since 18:13; all four items still
mandatory and re-verified below).

**No simulator was booted, installed on, driven or screenshotted** (stage 3
must not). No `flutter clean`. No production file was touched: this stage's
diff is `app/test/features/family/**` plus `docs/screens/P15/**`.

---

## 1. Iteration 2 → 3: the red proof is green

The iteration-2 repro stays exactly as written and now passes —
`child_profile_view_test.dart` → *BUG P15-BUG-9: a SECOND deep link must switch
the profile*: `/today` → Leo → Today → Maya now really lands on Maya. The
whole feature suite is green apart from the one new repro in §4.

What iteration 3 changed, and where it is now proved:

| Iteration-3 change | New proof (this stage) |
|---|---|
| `_ChildProfileRoute.didUpdateWidget` + `ChildProfileView.didChangeDependencies` follow the live `?childId=` (P15-BUG-9) | the repro above, plus three lifecycle tests: no re-dispatch on rebuilds/re-entry, a stale `?childId=` cannot resurrect a removed child, dropping the query keeps the chosen child |
| `watchProfile` claims the ledger slot synchronously; only the newest run re-subscribes (review 3) | two real-DB tests: a cascading remove leaves one live subscription (a later ledger write still reaches the profile), and emptying/refilling the family re-subscribes cleanly |
| cross-feature `moneyPounds` import → the barrel's `formatPounds` (per-feature boundary, `ARCHITECTURE.md:75`) | a copy test pinning the exact rendering across magnitudes, zero, and negative balances, with no float noise |
| `ProfileRow` literals → `NestSpacing` tokens | the tile/padding test now also asserts the tokens equal the design's numbers and the padding is exactly `12/10/16/10` |
| repoint query repeats the roster ordering (review 4/5, `SHARED_REQUEST.md` §5) | a three-child test where the answer is only correct if the order is *createdAt, rowid* |
| `kDebugMode`-gated `debugPrint` (review 5) | not observable from a widget test — code-hygiene only, no proof possible |

---

## 2. Tests added this iteration (7 new + 1 strengthened)

### `child_profile_view_test.dart` — +5

* **the selection lifecycle** (the new P15-BUG-9 machinery):
  * *the same id is not re-dispatched on rebuilds or re-entry* — with a mock
    repository counting `selectChild`: a cold entry with `?childId=leo`
    dispatches at most twice (route + view, documented as idempotent), and a
    **theme flip, a text-scale change and a Today→Family round-trip add
    zero** calls. This is the guard that keeps `didChangeDependencies` from
    turning every rebuild into a write;
  * *a stale `?childId=` cannot resurrect a removed child* — deep-link to Leo,
    delete him through the UI, then re-enter the same stale URL: the screen
    falls through to Maya (ADDED order) and stays there;
  * *dropping the query keeps the child the deep link chose* — the Family tab
    root has no `?childId=`; the persisted selection wins, no reset, no crash.
* **the route still guards** — *kid mode still sends the profile to the
  parental gate*: `/child-profile?childId=leo` in kid mode redirects to
  `/parental-gate` and never builds the view (the shell's parent-only
  redirect, `router.dart:85-109`, must survive the new stateful wrapper).

### `child_profile_selection_test.dart` — +3

* *a cascading remove leaves one live subscription for the new child* — one
  transaction across five tables lands several base emissions while the
  handler awaits `cancel()`; after it the profile has switched to Leo with
  **his** money (210p, not Maya's leftovers) and a fresh `quest_bonus` row
  for Leo still reaches the profile (owed 460p). That is the observable proof
  the subscription was neither orphaned nor duplicated.
* *emptying and refilling the family re-subscribes cleanly* — the
  `selected == null` branch emits null, and a newly added child comes back
  with an empty ledger and zero quests (no stale rows from the deleted ones).
* *with three children the repoint picks the FIRST added survivor* — Maya, Leo,
  Robin (roster order asserted); remove Maya ⇒ `leo`, not `robin`; remove the
  never-selected Robin ⇒ the selection does not move.

### `child_profile_copy_test.dart` — +1

* *the `formatPounds` swap keeps the ledger's exact rendering* — £29.99 /
  £0.01 / £0.09 / £9.99 / £1000.00 / £2500.00, negative balances rendered as
  magnitudes (never `-£`, matching the ledger), and a regex sweep over eight
  magnitudes proving two decimals with no float artefacts.

### `child_profile_row_test.dart` — 1 strengthened

* the tile test now also pins `NestSpacing.s10 == 40`, `s3 == 12`, `s4 == 16`,
  `gap10 == 10` and the rendered padding `EdgeInsets.fromLTRB(12, 10, 16, 10)`
  — i.e. the token refactor did not move the design's geometry.

---

## 3. Gates (run in `app/`)

```
$ dart format .
Formatted 496 files (0 changed) in 3.62 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.4s)

$ flutter test test/features/family
00:11 +280 -1: Some tests failed.        # the one red is P15-BUG-10

$ flutter test
01:26 +2561 ~1 -2: Some tests failed.
```

| File | Result |
|---|---|
| `child_profile_view_test.dart` | **+29 −1** (red = P15-BUG-10) |
| `child_profile_selection_test.dart` | +20 |
| `child_profile_row_test.dart` | +15 |
| `child_profile_copy_test.dart` | +21 |
| `child_profile_bloc_test.dart` | +23 |
| `child_profile_states_test.dart` | +12 |
| `child_profile_theme_size_test.dart` | +17 |
| `p15_bugs_test.dart` (stage 6) | +8, no skips |
| `add_children_test.dart` / `p05_bugs_test.dart` / `p05_view_metrics_test.dart` | +119 / +12 / +4 |
| **family total** | **+280 −1** |

Nothing was skipped, deleted or weakened; no `analysis_options.yaml` change;
no `google_fonts`; `grep -rn "skip" test/features/family/` returns no
markers.

### The other suite failure is not P15's

```
test/core/family_time_test.dart › seed + repository zone plumbing
    › kid_home completions are stamped with the family zone
    Bad state: Too many elements
```

Evidence that it is outside this screen (and that I did not touch it):

```
$ git diff main...HEAD --stat -- app/test/core app/lib/core     → (empty)
$ git diff main HEAD --stat -- app/test/core/family_time_test.dart \
      app/lib/core/data/seed.dart                                 → (empty)
```

Both files are byte-identical to `main`; the branch edits no `core/**` file at
all. The cause is the shared demo seed pre-creating a `to_do` completion for
`q-plants`, which that pre-existing test predates — `2_build.md` §"The one
blocking failure" and `SHARED_REQUEST.md` §6 carry the diagnosis and the
one-line fix intent. RULES §1 forbids this screen from editing
`app/test/core/**`, so it is recorded here, **not** patched and **not**
counted as a P15 finding. The single `~` skip is `p12_bugs_test.dart`
(feature `pocket_money`, pre-existing).

---

## 4. Bug found

### P15-BUG-10 — minor — the view can no longer be mounted on its own

`app/lib/features/family/presentation/views/child_profile_view.dart:57` (the
`didChangeDependencies` added in iteration 3):

```dart
final requested = GoRouterState.of(context).uri.queryParameters['childId'];
```

`GoRouterState.of` **asserts** when there is no router ancestor, and
`didChangeDependencies` runs on every mount. So `ChildProfileView` throws

```
GoError: There is no GoRouterState above the current context.
This method should only be called under the sub tree of a RouteBase.builder.
```

whenever it is mounted outside a `RouteBase.builder` — a bare `MaterialApp`
pump in a widget test, a preview/storybook harness, or the design-system
gallery if it ever shows a feature view. Inside the app nothing is broken
(the only builder is `childProfileRoute`), so this is a fragility introduced
by the P15-BUG-9 fix, not a regression a parent can see. Classified **minor**
for that reason; it is still a trap, because the view used to be
self-contained.

**Proof.** `child_profile_view_test.dart` → *BUG P15-BUG-10: the view mounts
without a GoRouter* (red: `GoError` where `null` is expected). The same test
also asserts the screen still shows Maya once it builds, so a fix cannot
cheat by rendering nothing.

**Fix direction (P15-local, one line).** Read the router optionally while
keeping the dependency registration:

```dart
final requested = GoRouter.maybeOf(context)?.state.uri.queryParameters['childId'];
```

`GoRouter.of`/`maybeOf` look the router up through the inherited widget, so
`maybeOf` still re-fires `didChangeDependencies` on a router-state change —
the P15-BUG-9 behaviour survives — while a router-less mount simply skips the
selection, which is what a route-less screen wants anyway.

---

## 5. Re-verified (no findings)

* **`Seed.demo()` / `Seed.empty()`**, with and without a `?childId=`; every
  empty/loading/failure branch; the retry; the remove flow and its toast
  (including a repeated identical failure).
* **Light + dark, 320/390/430, text scale 1.0/1.3**: 20 px gutters, the
  stat grid `1fr 1fr 1fr` + 10 gap, token-only surfaces and type, the five
  design bands unmoved, no overflow anywhere, the danger card reachable by
  scrolling, the scaler clamped at 1.3.
* **Copy**: character-exact against the HTML source (U+2013 / U+00B7 / U+203A /
  U+00A3) including the new `formatPounds` path; no ASCII `-` in the age
  band; `NestType` tracking untouched; no hard-coded colours.
* **Accessibility**: every control exposes `SemanticsAction.tap`; the hero
  name is a heading; every `isImage` node is labelled in both themes;
  `performAction(tap)` drives the real navigation, modal and DB write; tap
  targets ≥ 56 rows / ≥ 44 the rest.
* **Design ellipsis**: at the design's 390 × scale 1.0 nothing in the rows is
  cut, and the column is the CSS arithmetic (`row − 12 − 16 − 40 − 24 −
  trail`); the remaining cuts at 320 and at scale 1.3 are the design's own
  `nowrap` + `ellipsis` fallback where the string cannot fit — recorded, not
  a finding.

## 6. ORCHESTRATOR_NOTES.md — all four items, re-verified in code and tests

1. **Subtitles in full; the trail takes only its intrinsic width** — nothing
   is cut at 390 × 1.0, the trail is its intrinsic 70.71 px and the PIN row's
   column is exactly 187.29 px (`child_profile_row_test.dart`), and the
   `2_build.md` citation in `child_profile_theme_size_test.dart` is green.
2. **Row icons** — `NestIcons.quests` is proven to be the design's circled
   check (read off disk) and the Pocket-money tile is the untinted
   `assets/illustrations/coin.svg`; both glyphs are 24 px boxes centred in
   their 40 px tiles.
3. **Pronoun "their"** — unchanged, per the note.
4. **DB quest counts** — unchanged, per the note.

---

## 7. Verdict

`dart format` clean, `flutter analyze` **No issues found**, P15's own feature
suite **280 tests, 1 red**, and the full suite **2561 pass / 1 skip / 2
fail** — one failure is the shared core test this screen may not edit, the
other is a new **minor** bug this stage found (P15-BUG-10: `ChildProfileView`
throws `GoError` when mounted outside a `RouteBase.builder`, a fragility
introduced by the iteration-3 deep-link fix). The brief's PASS bar is "all
tests pass and no bugs were found".

