# P10 · Quest library (`/quests`) — Stage 3 TEST (iteration 3)

Route `/quests` · feature `quests` · parent mode · in-memory Drift DB ·
tests pinned to Sat 3 Oct 2026 by `test/flutter_test_config.dart`.
Tree tested: `325e93e` "P10: checkpoint after build (iteration 3)" on
`screen/P10` (which includes the shared merge
`0cdb53c Merge shared/segmented_semantics`).

**No screen code was changed.** The one finding below is a failing proof in
`app/test/features/quests/`, left in place.

---

## 0. Where iteration 2 left things

Iteration 2 ended at **170 pass / 5 fail**. The shared `segmented_semantics`
merge and the iteration-3 build closed four of the five:

| Iteration-2 failure | Now |
|---|---|
| BUG-P10-10 · `NestSegmented` announced every option twice (3 tests) | **fixed** by the shared merge — `quest_library_a11y_test.dart` 20/20 |
| BUG-P10-12 · the applied search filter went invisible after a tab trip | **fixed** — `p10_bugs_test.dart` 10/10 |
| BUG-P10-13 · the search field's accessible name was its hint | **fixed** — `quest_library_a11y_actions_test.dart` 11/11 |
| BUG-P10-13/§10 · `NestTextField.search` floats its hint to the top | **open** (shared) — 1 test red |

So the stage opened at **176 pass / 1 fail**. The brief carries no new
orchestrator rules this iteration, so the work went into closing the two
coverage gaps I had explicitly deferred earlier rather than into more of the
same.

---

## 1. Tests added

### 1a. `quest_library_seed_empty_test.dart` (**new**, 6 tests)

Iteration 1 proved "no active quests" with a **mocked empty stream** because
driving the real router with `Seed.empty()` hung the test, and I recorded that
as a known deferral. This brief says *"Use the in-memory Drift DB with
Seed.demo/empty"*, so the real seed is now covered:

- `/quests` stays on route with `Seed.empty()` — no trial or onboarding
  redirect (`Seed.empty` writes `subscriptionStatus: 'trial'`,
  `trialStart: now`, so the trial guard must not fire);
- the Active tab reports the database's real count, `Active (0)`, and shows
  `No active quests` / `Add one from Ideas.`;
- **the Ideas tab still lists the static templates** with an empty database —
  `QuestsRepository.ideas()` are never stored rows, so `Seed.empty()` must not
  empty the Ideas tab (DATA OVER MOCKS). This is the assertion the mock could
  not make honestly, since the mock returned the real templates itself;
- the search field and the chip row still work, including the AND combination
  (`pet` + `Kitchen` → empty state; `Kitchen` alone → its two templates);
- no overflow and no exception on the empty tree;
- and with `Seed.demo()`, deactivating `q-bed` moves `Active (12)` → `Active
  (11)`, proving the label tracks the stream rather than a literal.

The earlier hang was not the seed: it was my own chain of
`setUpTestScope` → `AppSession.refresh()` → `watchItems().first` → pump, which
left a Drift timer pending. Calling `setUpTestScope`/`Seed.empty` and then
`pumpAppRoute` (which ends with `disposeApp`) is clean.

### 1b. `quest_library_view_test.dart` (extended, 27 → 34 tests)

- **Every tap navigates to the right route** — the brief's wording covers the
  shell too, and the four parent tab-bar items had no coverage on P10. Each is
  now proved: `Today` → `/today`, `Money` → `/money`, `Family` →
  `/child-profile`, `Quests` → `/quests`, plus a round-trip through all four
  that ends with the library intact. Taps are scoped to `NestTabBar` via a
  `_tab()` helper, because the library's own heading is also labelled
  `Quests` (the same collision P08's tests hit).
- A tab round-trip does not disturb the applied category filter.
- **`/quests` is parent-only** — with `AppModeController.selectMode(AppMode.kid)`
  the router lands on `/parental-gate`. P10 is a parent screen, so the 56 px
  kid tap floor from the brief never applies to it; this test makes that
  explicit rather than implicit.
- The Active tab now runs at **widths 320/390/430 × text scale 1.0/1.3**
  (it previously covered the widths at 1.0 only).

### Audited and already complete, so unchanged

- **bloc_test for every event/state path** — `QuestsState` gained `ideas` in
  iteration 2 and the suite was updated then: `copyWith` per field, the
  "null means keep" rule, equality, `hashCode`, `props` order
  (`[status, items, ideas, errorMessage]`), plus every status path including
  "a failure keeps the last ideas" and the empty-ideas case. 17/17.
- **Semantics labels + `performAction`** — `quest_library_a11y_test.dart` 20/20
  and `quest_library_a11y_actions_test.dart` 11/11.
- **Empty / loading / error states** — `quest_library_states_test.dart` 19/19.
- **Tap targets ≥ 44 (parent)** — chips, `+ Add`, segmented, search field, in
  the responsive matrix and the a11y suite.
- **Design geometry** — `quest_library_design_geometry_test.dart`, 10/11.

---

## 2. Results

```
$ dart format --set-exit-if-changed .
Formatted 439 files (0 changed) in 1.18 seconds.

$ flutter analyze
Analyzing app...
No issues found! (run in 3.0s)

$ flutter test
+1966 -1: Some tests failed.
```

| File | Result |
|---|---|
| `quest_library_view_test.dart` | 34/34 |
| `quest_library_states_test.dart` | 19/19 |
| `quest_library_filter_test.dart` | 20/20 |
| `quests_bloc_test.dart` | 17/17 |
| `quest_idea_meta_test.dart` | 16/16 |
| `quest_library_widget_test.dart` | 16/16 |
| `quest_library_a11y_test.dart` | 20/20 |
| `quest_library_a11y_actions_test.dart` | 11/11 |
| `p10_bugs_test.dart` | 10/10 |
| `quests_repository_test.dart` | 10/10 |
| `quest_library_seed_empty_test.dart` (**new**) | 6/6 |
| `quest_library_design_geometry_test.dart` | 10/11 ✗ |

`test/features/quests/` is now **189 tests**, 1 failing. The whole app is
**1967 tests, 1 failing**, and the single failure is P10's. No other feature's
tests broke. No test is skipped anywhere in `test/features/quests/`.

---

## 3. Bug found

### The one red test — MAJOR (shared) — the search hint floats to the top of the field

`app/test/features/quests/quest_library_design_geometry_test.dart:276-293`
→ `the hint is centred in the field, not floated to the top`.

**File** `app/lib/core/design_system/components/nest_text_field.dart:167-193`
(shared; already filed by the build stage as `SHARED_REQUEST.md` §10, which I
re-measured independently and confirm).

**Measured**, 390×844 with the 47/34 device insets and the bundled Inter face:

```
FIELD     173.0 … 225.0   centre 199.0   (52 tall)
ICON      187.0 … 211.0   centre 199.0   ← the magnifier IS centred
TEXTFIELD 177.0 … 221.0   centre 199.0   (44 tall — the design's `input`)
HINT      177.0 … 201.0   centre 189.0   ← 10 px high
```

**Independent confirmation from the design PNG** (I re-measured rather than
trusting the earlier note): the `--line` ring spans device rows 519–521 and
678–680 ⇒ the field is **y 173.0 … 227.0**, centre **200.0**; the hint's
non-white pixels run **y 194.0 … 206.3**, centre **200.2** — the same centre as
the magnifier's ink band (191.0 … 209.0). So the design really does centre the
hint on the field, and the pin's expected value (200) is the design's, not the
app's.

**Cause.** The `SizedBox(height: 44)` around the `TextField` is tight, and
`textAlignVertical: TextAlignVertical.center` only centres the text inside the
editable's own box, which measures 24 (Inter 16 × `height: 1.5`) — the
intrinsic line box, not the 44. The hint therefore paints at the top of the
slot.

**Repro.** `/quests` → look at the search field: the magnifier sits vertically
centred, the placeholder sits 10 px above centre.

**Fix.** Shared — the editable needs the 44 px box, not a line box
(`strutStyle`/`textHeightBehavior`, or `contentPadding` vertical
`(44 − 24) / 2 = 10`, or wrapping so `TextField` fills the slot and
`TextAlignVertical.center` does the work). P10 must not re-pad the shared field
locally, so it stays unfixed here — same rule as §1.

The pin is written against the design's absolute numbers, so it turns green on
its own once §9 (field 52 → 54) and this fix land together.

---

## 4. Owner rules checked

- **No skipped tests** — `grep 'skip:'` over `test/features/quests/` finds only
  a comment recording that the markers were removed.
- **No `lib/` change** — `git status` shows only `test/features/quests/` and
  `docs/screens/P10/`.
- **google_fonts** — 0 occurrences in `lib/features/quests` and
  `test/features/quests`.
- **BOTTOM-EDGE / ALIGNMENT / UI VERDICT RULE** — the geometry suite pins the
  20 px gutters, the bar surface reaching 844 and the design y for the title,
  every control and every card top, in light and dark; unchanged and still
  green apart from the shared hint pin.
- **ACCESSIBILITY ACTIONS** — unchanged, all green: `hasAction(tap)` and
  `performAction` with a real state/route/DB effect for every control.
- **Simulators** — none booted, installed on, screenshotted or driven.

---

## 5. Verdict

One proof fails. It is a genuine defect in shared `NestTextField.search`, not
in P10's screen code, and it is already filed as `SHARED_REQUEST.md` §10. The
suite cannot be green until that shared fix lands, so the verdict is FAIL — with
every P10-local issue from iterations 1 and 2 now closed and verified.

VERDICT: FAIL