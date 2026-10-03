# P10 · Quest library (`/quests`) — Stage 3 TEST (iteration 4)

Route `/quests` · feature `quests` · parent mode · in-memory Drift DB with
`Seed.demo()` and `Seed.empty()` · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`.
Tree tested: `60f34fe` "P10: checkpoint after build (iteration 4)" on
`screen/P10` (includes `4dc08ad Shared brief: search field`).

**No screen code was changed. No bug was found this iteration.**

---

## 0. Where iteration 3 left things

Iteration 3 ended at **191 pass / 1 fail**, the single failure being the shared
`NestTextField.search` hint-centring pin (`SHARED_REQUEST.md` §10). The shared
"search field" brief and the iteration-4 build closed it:

- `NestTextField.search` now renders 54 high (SHARED_REQUEST §9) with the hint
  vertically centred in the 44 px input slot (§10). Both pins in
  `quest_library_design_geometry_test.dart` are green, including the hint
  centre, which now sits on the design's 200.

So this stage opened green and stayed green: **202 tests in
`test/features/quests/`, all passing.**

---

## 1. Tests added

With the whole suite green, the remaining value was **hardening** — owner rules
that nothing in the repository would catch if they regressed. I audited the
brief's list and every item is covered; what I could not find was coverage for
three rules whose breakage is invisible to copy and geometry assertions.

### `quest_library_typography_test.dart` (**new**, 11 tests)

| Group | Why it exists |
|---|---|
| **LETTER SPACING** — every text style on the library, and on the Active tab, has `letterSpacing` 0 | The rule says `NestType` defaults to 0 because the P10 CSS carries no tracking, and no call site may add it back. Re-adding Material's default tracking would reflow every line without failing one existing assertion — `grep letterSpacing test/features/quests/` returned **nothing** before this file. |
| **BALANCED HEADINGS** — no `NestBalancedText` anywhere on the screen; the title is a plain single-line `Text` | `4_review.md` finding 7 flagged that `.ptitle` sets no `text-wrap: balance`, and the build replaced the wrapper with a plain `Text`. Because one word at `maxLines: 1` short-circuits inside `NestBalancedText`, putting the wrapper back is **invisible** — no geometry or semantics test changes. Now pinned, along with the title's Nunito 28/34 w900 and its CSS line-height (`34/28`). |
| **Type roles** — Nunito display only for the title, Inter everywhere else; `.trow .nm` 16/22 w700 and `.trow .mt` 13/18 keep the CSS line-heights rather than the type scale; `.chip` Inter 14 w600 and `.addbtn` Inter 14 w700 | The two text styles that override the scale are the easiest thing to "tidy" into `NestType.body`/`.caption`, which would change both line heights and the card's 68 px height. |
| **COPY** — `Reading – 20 minutes` carries **en dash U+2013** on the Active tab (not a hyphen, not an em dash); the meta line's separator is **middot U+00B7** (not U+2022, not ` - `); the hint and its accessible name are the design's two strings | The orchestrator's COPY rule is character-for-character, and the en-dash title is the one seeded string with a typographic dash on this screen. |
| **Filter row** — all seven chips can be scrolled to and selected at **320**, the narrowest width the brief names | The chip row is a horizontal scroller with a 44-high pill, so the last chips sit off-screen. Nothing previously proved a user can reach `Pets`, `School` and `Kindness` at 320 and that the tap really selects. The test scrolls to each chip in turn, taps it, and ends on `Kindness`'s `No ideas found`. |

### Audited, already complete, unchanged

`bloc_test` for every event/state path (17) · light+dark × 320/390/430 × text
scale 1.0/1.3 (34) · empty/loading/error states and `Seed.empty` (19 + 6) ·
every tap navigates to the right route, including the four shell tabs (34) ·
semantics labels + `performAction` with a real effect (20 + 11) · tap targets
≥ 44 parent, with the parent-only guard proving the 56 px kid floor is N/A
(20 + 34) · design geometry within ±2 px with the measured y of the title,
every control and every card top (12) · shapes not just text — radii, borders,
paddings, the 40 px tile, the 1.5 px leaf strokes (16) · pure filter and
metadata units (20 + 16) · repository over Drift (10).

---

## 2. Results

```
$ dart format --set-exit-if-changed .
Formatted 441 files (0 changed) in 1.19 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.9s)

$ flutter test
+1988: All tests passed!
```

| File | Tests |
|---|---:|
| `quest_library_view_test.dart` | 34 |
| `quest_library_filter_test.dart` | 20 |
| `quest_library_a11y_test.dart` | 20 |
| `quest_library_states_test.dart` | 19 |
| `quests_bloc_test.dart` | 17 |
| `quest_idea_meta_test.dart` | 16 |
| `quest_library_widget_test.dart` | 16 |
| `quest_library_design_geometry_test.dart` | 12 |
| `quest_library_typography_test.dart` (**new**) | 11 |
| `quest_library_a11y_actions_test.dart` | 11 |
| `p10_bugs_test.dart` | 10 |
| `quests_repository_test.dart` | 10 |
| `quest_library_seed_empty_test.dart` | 6 |

`test/features/quests/`: **202 tests, 0 failures, 0 skips.** Whole app: **1988
tests, all passing.** Every bug raised in iterations 1–3 (BUG-P10-1 … 13) is
now closed and its proof green.

The `dart format` / `flutter analyze` / `flutter test` figures above come from a
run with the review stage's `test/features/quests/zz_review_probe_test.dart`
scratch file set aside — it is a self-described "TEMPORARY review probe" and
accounts for 4 of the 5 `analyze` issues while the review stage is running. It
was restored immediately afterwards so that stage keeps working, and it must
not be committed.

---

## 3. Bugs found

**None.** No test exposed a defect this iteration, and no screen code was
patched.

---

## 4. Owner rules checked

- **No skipped tests** — `grep 'skip:'` over `test/features/quests/` finds only
  a comment recording the removals.
- **No `lib/` change** — `git status app/lib` is empty; this stage added one
  test file and touched nothing else.
- **google_fonts** — 0 occurrences.
- **LETTER SPACING** and **BALANCED HEADINGS** — pinned for the first time
  this iteration (see §1).
- **COPY** — character-for-character, now including the en dash and the middot.
- **UI VERDICT RULE / ALIGNMENT / BOTTOM-EDGE** — the geometry suite keeps the
  measured design-vs-app y table and the bar reaching the physical edge.
- **ACCESSIBILITY ACTIONS** — unchanged, all green.
- **DATA OVER MOCKS** — `Active (N)` tracks the stream (12 → 11 on a
  deactivation); the Ideas tab is never emptied by an empty database.
- **Simulators** — none booted, installed on, screenshotted or driven.

---

## 5. Verdict

All 1988 tests pass, nothing is skipped, `flutter analyze` is clean, and this
stage found no defect. Both conditions the brief sets for PASS are met.

VERDICT: PASS