# K04 quest detail — Stage 6 bug hunt (iteration 3)

Scope: `kid_home` · route `/quest-detail` · kid mode. Third adversarial pass
over the iteration-3 build (audience glyphs, ellipsis fix and shared merges),
against `docs/screens/RULES.md`, the orchestrator rules — including the new
ICONS rule and `ORCHESTRATOR_NOTES.md` (14:28 + 15:08) — and the K03 bug
history.

**Result: every earlier finding is fixed and verified; one new Minor found
(the hero glyph's stroke width). No major bug is open in K04's code.**

| # | Severity | Status (iter 3) | Area |
|---|---|---|---|
| K04-BUG-1 | was Major | **FIXED iter 2 · verified iter 3** | `.kid-title` / `NestBalancedText` + `maxLines` |
| K04-BUG-2 | was Minor | **FIXED iter 2 · verified iter 3** | `_resolveQuest` extra handling |
| K04-BUG-3 | was Major (mandated) | **FIXED iter 3** | hero glyphs via `questIconFor(audience: kid)` |
| K04-BUG-4 | was Minor | **FIXED iter 3 · verified** | over-cap title ellipsis |
| K04-BUG-5 | Minor | **OPEN** | hero bed glyph stroke width 2 vs design 1.8 |

All proofs live in `app/test/features/kid_home/k04_bugs_test.dart`. The four
fixed proofs run **un-skipped** as regression guards; the new K04-BUG-5 proof
is skipped by default (`// skip: K04-BUG-5 (open)` next to `skip: true`; the
test name carries the id) so the plain suite stays green.

Commands (iteration 3):

```
$ flutter test --timeout 120s test/features/kid_home/k04_bugs_test.dart
00:01 +14 ~1: All tests passed!      # 14 live probes + 1 skipped (BUG-5)

$ flutter test --timeout 120s --run-skipped --plain-name K04-BUG-5 \
    test/features/kid_home/k04_bugs_test.dart
Expected: contains 'stroke-width="1.8"'
  Actual: '… stroke-width="2" …'   (ic_quest_bed_kid.svg)
1 test failed                        # the bug is real

$ flutter test --timeout 120s test/features/kid_home
00:13 +545 ~4: All tests passed!
$ flutter analyze
No issues found! (ran in 3.7s)
```

---

## K04-BUG-5 — the hero bed glyph's strokes are ~11% heavier than the K04
tile (Minor, OPEN)

**Where:** `app/assets/icons/ic_quest_bed_kid.svg`, rendered by
`questIconFor('bed', audience: NestAudience.kid)` at the 64 px K04 hero slot
(`quest_detail_view.dart` → `NestIcon`).

**What happens.** The kid bed asset's path data is an exact match for the
K04 tile (`M2 18v-7`, `M2 14h20v4`, `M22 18v-4a3 3 0 0 0-3-3h-9v3`,
`M6 11V8h4v3`) — but its `stroke-width` is **2**, while the K04 tile in
`design/html-source/screens/K04-quest-detail.html` (line 40) draws those very
paths at **1.8**. Measured: the asset is byte-exact to K03's bed row
(`stroke-width="2"`), and `1.8` occurs **nowhere else in the whole design
corpus** — it is K04's hero-specific stroke. At the 64 px slot the app paints
`2 × 64/24 = 5.33 px` strokes where the design has `1.8 × 64/24 = 4.8 px`:
**+0.53 px (≈1.6 device px at @3x)** heavier, against the new ICONS rule
“each screen matches its own design's glyphs exactly”.

This is a single-source conflict, not a K04 coding error: one shared kid
asset must be exact for both K03's bed row (2, matching K03's HTML) and K04's
hero (1.8). `test/design_system/audience_glyphs_test.dart:70-80` asserts
`stroke-width="2"` and calls the asset “the exact K03/K04 bed glyph”, so the
K04 half of that claim is what is off.

**Repro.**
1. Open the bed quest (`q-tidy` / `q-bed`) on K04.
2. Compare the 120×120 tile against `design/screens/light/K04-quest-detail.png`
   (or the HTML tile): the app's line weight is one notch heavier; the drawing
   itself (headboard post, pillow bump, long base, legs) is correct.

**Failing test.** `K04-BUG-5: the kid bed glyph must match the K04 hero tile
stroke` (reads the asset and the K04 HTML; actual `stroke-width="2"`, expected
`"1.8"`; also pins the two distinctive tile paths).
Run: `flutter test --timeout 120s --run-skipped --plain-name K04-BUG-5
test/features/kid_home/k04_bugs_test.dart`

**Severity rationale.** Cosmetic: half a logical pixel of stroke weight at the
hero size, shape and position exact, far inside the ±2 px UI tolerance. Minor.

**Suggested fix (shared — orchestrator decision).** Either:
(a) accept the 0.5 px and record it (the shared K03-exact asset stays; the
`audience_glyphs_test.dart` comment should drop its K04-exact claim), or
(b) add a K04-hero variant (e.g. `ic_quest_bed_kid_hero.svg`, 1.8) and have
K04 pick it at the call site while the shared kid table keeps 2 for K03.
A screen-local override is not expressible through `questIconFor`, so (b) is
a shared change.

---

## Earlier findings — fixed and verified in iteration 3

| bug | fix landed | proof (un-skipped, passing) |
|---|---|---|
| **K04-BUG-1** (was Major) | Iter 2: `NestBalancedText` probes **natural** line counts and returns full-width text above the cap (`SHARED_REQUEST.md`). Verified again this iteration. | `K04-BUG-1: balancedWidthFor …` (unit) + `…a long quest title measures ~0 px…` (widget) |
| **K04-BUG-2** (was Minor) | Iter 2: `_resolveQuest` returns null (→ “Pick a quest”) for any explicit `questId` that does not resolve for the playing child. | `K04-BUG-2: an extra naming another child must not show a different quest` |
| **K04-BUG-3** (was Major, mandated) | Iter 3: `_iconFor` now delegates to the shared `questIconFor(key, audience: NestAudience.kid)`, so the bed hero is the K04-faithful `questBedKid`, dishwasher/reading the K03/K04 kid glyphs; `hoover`/`bins` keep the shared parent glyphs (no kid design draws them). | `K04-BUG-3: the hero tile uses the kid design glyphs` (loops q-tidy/q-dishwasher/q-hoover/q-bins) |
| **K04-BUG-4** (was Minor) | Iter 3: the K04 call site passes `overflow: TextOverflow.ellipsis`, so an over-cap title ends in an ellipsis instead of a mid-word clip. | `K04-BUG-4: an over-cap title must ellipsise, not clip` |

## Checked clean (running un-skipped)

- **Over-cap titles** (the K04-BUG-1 path): full content width, ellipsis, at
  390 px and 320 px / 1.3× text, no overflow exception.
- **Quest deleted mid-view**: falls to “Pick a quest” with no exception.
- **Back navigation**: double-tapping either Back pops exactly one route.
- **Deep link with `Seed.empty`**: offers the picker.
- **Persistence**: a completed quest stays disabled after a fresh app pump
  on the same Drift database.
- **Data edges**: 9999 coins at 320 px / 1.3× fits the pill; a 30 h-old daily
  completion reads “to do” again (London period ruling).
- **Dark mode / owner rules**: the dark bar surface reaches the physical edge
  under a 34 px inset; every K04 token pair ≥ 4.5:1 in both themes.
- **Accessibility / async**: every control exposes a tap action; the
  completion latch and gate latch are `mounted`-checked; bloc 9.2.1 drops
  emits after close (no post-close throw).

## Not findings

- Completing and pressing Back in the same frame ends on `/quest-complete`
  with the row saved and no exception (celebration wins; acceptable).
- A staggered second tap during a slow write dispatches a second event, but
  `completeQuest`'s transaction is idempotent: one row, one celebration.
- Only `k04_bugs_test.dart` and this file were written; the screen was not
  modified. No simulator used; all proofs run in `flutter test`.

VERDICT: PASS
