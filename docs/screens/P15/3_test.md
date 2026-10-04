# P15 · Child profile — Stage 3 TEST (iteration 4)

Route `/child-profile` · feature `family` · parent mode · light+dark designs.
Tree: branch `screen/P15` at `686bd69` ("P15: checkpoint after build
(iteration 4)").

Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md` (iteration 4), `2a_build_logic.md`, `2b_build_ui.md`,
`3_test.md` (iterations 1–3), `4_review.md`, `5_ui.md`, `6_bugs.md`,
`FIXES_1.md`, `FIXES_2.md`, `FIXES_3.md`, `SHARED_REQUEST.md` and
**`ORCHESTRATOR_NOTES.md`** (unchanged since 18:13; all four items still
mandatory and re-verified below).

**No simulator was booted, installed on, driven or screenshotted** (stage 3
must not). No `flutter clean`. No production file was touched: this stage's
diff is `app/test/features/family/**` plus `docs/screens/P15/**`.

> **Context for this iteration: the real date rolled from Sat 3 Oct to Sun 4 Oct
> 2026 during the loop.** The suite still pins the seed story day
> (`test/flutter_test_config.dart` → `Seed.anchorOverride = 2026-10-03`), and
> P15's own feature suite is green **on the new date** — 283/283, no test
> touched. §3 shows what the rollover did to features that do *not* have P15's
> injectable clock, which is why one of this stage's new tests exists.

---

## 1. Iteration 3 → 4: the red proof is green

The iteration-3 repro is unchanged and now passes —
`child_profile_view_test.dart` → *BUG P15-BUG-10: the view mounts without a
GoRouter*: 2b's `if (GoRouter.maybeOf(context) == null) return;` guard
(`child_profile_view.dart:61`) lets the view build outside a
`RouteBase.builder` while keeping the `GoRouterState.of` dependency that makes
the P15-BUG-9 live re-selection work. Both behaviours are proved below, so the
guard cannot be "fixed" by disabling the deep link.

---

## 2. Tests added this iteration (2 new) and 3 hardened

### `child_profile_view_test.dart` — +1: the guard is inert, not a silent skip

*the router-less guard selects nothing and keeps the view* — with a mock
repository counting `selectChild`: a route-less mount calls it **never**
(`verifyNever`) and still shows Maya; the same widget, with a router above it,
dispatches again (`?childId=leo`). This is the pair that pins the guard's two
halves — a bare pump must not select anything, and a routed pump must still
follow the route. Without this, a `return` placed too early (or the guard
removed and the crash "fixed" another way) would pass the bare-mount proof
while silently killing the deep link.

The double dispatch on a cold entry (route `create` + this view) is expected
and idempotent; the sibling test *the same id is not re-dispatched on rebuilds
or re-entry* already pins the upper bound (≤ 2 per entry, 0 afterwards).

### `child_profile_selection_test.dart` — +1: the default clock, on the new date

*the default clock is the seed anchor, not the wall clock* — the differential
proof that keeps P15-BUG-8 dead: with **no** `clock:` argument (what the app
runs) `questsThisWeek` must equal the answer produced by the anchor clock and
must be the demo tile's **4**; a clock 40 days ahead really does produce 0, so
the comparison is not vacuous; and nothing else in the profile moves. This test
only became load-bearing overnight: on Sun 4 Oct a wall-clock default would
put the two `daily` completions out of period and turn the tile from 4 to 2.

### `child_profile_bloc_test.dart` — 2 tests hardened (fixtures re-stamped)

The PERIODS fixtures in *questsThisWeek follows the PERIODS ruling* and
*rejected completions never count* were stamped with `DateTime.now()` while
the repository reads its **anchor** clock — a latent date dependency of
exactly the kind this stage exists to kill. They are now stamped
`Seed.anchorDay.toUtc()` (and anchor − 3 days for the out-of-period case), so
they are independent of the day the suite runs in both directions. Same
assertions, same numbers (4 → 5 → 5), no expectation weakened.

---

## 3. Gates (run in `app/`)

```
$ dart format .
Formatted 496 files (0 changed) in 1.99 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 8.4s)

$ flutter test test/features/family
00:13 +283: All tests passed!

$ flutter test
01:09 +2530 ~1 -35: Some tests failed.
```

| File | Result |
|---|---|
| `child_profile_view_test.dart` | +31 |
| `child_profile_selection_test.dart` | +21 |
| `child_profile_bloc_test.dart` | +23 |
| `child_profile_copy_test.dart` | +21 |
| `child_profile_theme_size_test.dart` | +17 |
| `child_profile_row_test.dart` | +15 |
| `child_profile_states_test.dart` | +12 |
| `p15_bugs_test.dart` (stage 6) | +8, no skips |
| `add_children_test.dart` / `p05_bugs_test.dart` / `p05_view_metrics_test.dart` | +119 / +12 / +4 |
| **family total** | **+283, 0 fail, 0 skip** |

**P15's own suite is fully green, with no failing and no skipped test in it.**
Nothing was skipped, deleted or weakened; no `analysis_options.yaml` change;
no `google_fonts`; `grep -rn "skip" test/features/family/` returns prose only.

### The 35 suite failures are all outside P15

| Feature | Failures | Why it cannot be P15 |
|---|---|---|
| `test/core/family_time_test.dart` | 1 | shared core; the known `SHARED_REQUEST.md` §6 blocker (2nd iteration), now escalated with a verified diff |
| `test/features/kid_home/**` | 28 | e.g. *"Found 0 widgets with text `4 of 6 done`"* — the date rollover: `kid_home_repository_impl.dart:70,158` still uses `DateTime.now().toUtc()`, the P15-BUG-8 twin |
| `test/features/today/p08_bugs_test.dart` | 2 | *"a daily completion from the previous London day is to do"* — same rollover class in a period-scoped proof |
| `test/features/approvals/**` | 4 | the seeded pending approvals are dated to the pinned story day |

Evidence that none of it is mine:

```
$ git diff main...HEAD --stat | grep -E "app/(lib|test)" | grep -v features/family
 app/test/features/today/today_view_test.dart       |    6 +-      # the recorded placeholder→hero anchor swap

$ grep -rln "family_repository_impl\|features/family/data" lib/
lib/features/family/family_di.dart                  # nothing else imports it
```

The branch's only app-code change outside `features/family/**` is the six-line
test anchor recorded in `SHARED_REQUEST.md` §4, and
`FamilyRepositoryImpl` is imported by exactly one file — the family DI. None of
the failing features can reach P15's code. All of them are outside this
screen's RULES §1 editable set, so they are recorded here and **not** counted
as P15 findings.

**Worth the orchestrator's attention (not a P15 finding):** the date rollover
took out ~34 tests in three features that still evaluate periods against the
wall clock. P15's own suite is immune *because* iteration 2 gave
`FamilyRepositoryImpl` the injectable clock — the same one-line pattern
`TodayRepositoryImpl` already has and `KidHomeRepositoryImpl` does not. That
belongs on `main` for the other features.

---

## 4. Bugs found

**None.** No new test exposed a defect in the screen this iteration. The
iteration-3 finding (P15-BUG-10, minor) is fixed and its proof is green; no
other bug was found in the 283-test suite, and every bug this stage has
recorded in iterations 1–3 (P15-BUG-1…9) is closed with its repro still in
place:

| Bug | Repro test (still in the suite) | State |
|---|---|---|
| P15-BUG-1 major · `?childId=` ignored | *BUG: `?childId=leo` must show Leo* + *BUG: tapping Leo on Today…* | ✅ green |
| P15-BUG-2 minor · failure reported twice | `child_profile_states_test.dart` · *BUG P15-BUG-2* | ✅ green |
| P15-BUG-3 minor · dead message after recovery | `child_profile_bloc_test.dart` · *BUG P15-BUG-3* | ✅ green |
| P15-BUG-4 minor · "Pip is a Egg" | `child_profile_copy_test.dart` · *BUG P15-BUG-4* | ✅ green |
| P15-BUG-5 major · subtitles ellipsised | `child_profile_theme_size_test.dart` · *no list-row paragraph is ellipsised at 390* | ✅ green |
| P15-BUG-6/7 major · orphan rows / stale `active_child_id` | `p15_bugs_test.dart` + `child_profile_selection_test.dart` cascade group | ✅ green |
| P15-BUG-8 major · wall-clock periods | `p15_bugs_test.dart` + *the default clock is the seed anchor* | ✅ green (and load-bearing today) |
| P15-BUG-9 major · second deep link ignored | *BUG P15-BUG-9: a SECOND deep link must switch the profile* | ✅ green |
| P15-BUG-10 minor · `GoError` on a route-less mount | *BUG P15-BUG-10: the view mounts without a GoRouter* | ✅ green |

---

## 5. Re-verified (no findings)

* **Every event/state path**: load, draft, add-child, remove-child, child-selected;
  `initial`/`loading`/`loaded`/`failure`; the `clearErrorMessage` sequence.
* **Every state of the screen**: demo, `Seed.empty()` (with and without a
  `?childId=`), loading, failure + retry, the remove flow and its toast
  (including a repeated identical failure), the empty-state CTA.
* **Every navigation**: PIN push, quests `go`, money `go`, `/add-children`,
  the Today → child deep links (first and second), and the kid-mode parental
  gate still swallowing `/child-profile`.
* **Light + dark, 320/390/430, scale 1.0/1.3**: 20 px gutters, token-only
  surfaces and type, the five design bands unmoved, no overflow, the scaler
  clamped at 1.3, and the design's own ellipsis fallback where the text
  genuinely cannot fit (recorded, not a finding).
* **Copy** character-exact against the HTML source (U+2013 / U+00B7 / U+203A /
  U+00A3), including the `formatPounds` path; **accessibility**: every control
  exposes `SemanticsAction.tap`, the hero name is a heading, every `isImage`
  node is labelled in both themes, tap targets ≥ 56 rows / ≥ 44 the rest.
* **P15's demo numbers are unchanged and date-independent** on the new date:
  4 quests this week, 120 coins, 4 happy days, 6 active · 4 daily / 2 weekly,
  £3.00 a week · Owed £4.20 (DATA OVER MOCKS; the design's mocked "18" and
  "3 daily, 3 weekly" stay ignored).

## 6. ORCHESTRATOR_NOTES.md — all four items, re-verified

1. **Subtitles in full; the trail at intrinsic width** — nothing cut at
   390 × 1.0, the trail is its intrinsic 70.71 px, the PIN row's column is
   exactly 187.29 px (`child_profile_row_test.dart`), and the citation in
   `child_profile_theme_size_test.dart` is green.
2. **Row icons** — `NestIcons.quests` proven to be the design's circled check
   (read off disk); the Pocket-money tile is the untinted
   `assets/illustrations/coin.svg`; both glyphs are 24 px boxes centred in
   their 40 px tiles.
3. **Pronoun "their"** — unchanged, per the note.
4. **DB quest counts** — unchanged, per the note.

---

## 7. Verdict

`dart format` clean, `flutter analyze` **No issues found**, **P15's own feature
suite 283/283 green with no failing and no skipped test**, every bug recorded
in iterations 1–3 closed with its repro still in place, and **no new bug found
this iteration**. The full suite is still red on 35 tests that all belong to
other features (34 of them the date-rollover wall-clock class, one the known
shared `family_time_test.dart` blocker) — outside this screen's RULES §1 set,
recorded in §3, not counted against P15. The brief's PASS bar — "all tests pass
and no bugs were found" — is met for this screen.

VERDICT: PASS