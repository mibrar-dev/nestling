# K04 Quest detail — Stage 3 test (iteration 3)

Scope: add the coverage the new **ICONS** rule requires, re-verify the suite, and
report bugs. Inputs: `ORCHESTRATOR_NOTES.md` (14:28 + 15:08), `6_bugs.md`,
`k04_bugs_test.dart` header (stage 6, iteration 3), `RULES.md`.
**No simulator was booted, installed on or driven** (stage 5 only).

## Verdict: FAIL

Two independent reasons, one of which is an outright incomplete deliverable:

1. **A real bug is open on this screen — K04-BUG-5 (Minor).** The brief's bar is
   *"PASS only if all tests pass **and no bugs were found**"*. I re-ran its proof
   un-skipped and it fails today (output below). I did **not** patch the screen.
2. **This stage did not deliver its main new test.** I wrote **no new tests this
   iteration** — see the honesty note below. The ICONS audience coverage is still
   missing.

Everything that exists is green: `flutter analyze` clean, **3707** suite tests
pass. But a green suite is not a pass here, because one green is a *skipped* test
whose body currently fails.

## Honesty note — what I did and did not do

I investigated, verified and reported, but I did **not** write the icon test I had
planned. Concretely, this iteration produced **0 new test cases**; the 69 K04
cases are unchanged from iteration 2. I had established everything needed to
write it (see "The gap I left" below for the finished design), then ran out of
stage before writing the file. I am stating that plainly rather than dressing up
the verification work as test coverage — a report claiming I added icon tests
would be false.

## What I did verify this iteration (real runs)

```
$ flutter analyze
No issues found! (ran in 3.4s)

$ flutter test --timeout 120s test/features/kid_home
00:13 +545 ~3: All tests passed!

$ flutter test --timeout 120s
01:37 +3707 ~5: All tests passed!
```

The shared `questIconFor(key, audience:)` helper that iteration 2 flagged as
absent **has landed** (`core/design_system/components/quest_icons.dart`, plus
`components/audience.dart` with `enum NestAudience { parent, kid }`), and the
view was migrated: `quest_detail_view.dart:85` is now

```dart
String _iconFor(String raw) {
  return questIconFor(raw, audience: NestAudience.kid);
}
```

That satisfies the ICONS rule's *substance* for this screen (kid audience), and
`k04_bugs_test.dart`'s K04-BUG-3 proof asserts the kid assets un-skipped. So the
code is right; what is missing is my own independent regression guard.

Also verified: the **K04-BUG-4 fix landed** and its proof is now **un-skipped**
(the skip is gone from the file). Re-running it confirms the fix is real:

```
$ flutter test --timeout 120s --run-skipped --plain-name K04-BUG-4 \
    test/features/kid_home/k04_bugs_test.dart
00:00 +1: All tests passed!
```

Skip inventory for K04 is now exactly one: `k04_bugs_test.dart:383`
(`// skip: K04-BUG-5 (open)`). Iteration 2's K04-BUG-4 skip is closed.

## Bug found / open — K04-BUG-5 (Minor, OPEN, shared asset)

**Where:** `app/assets/icons/ic_quest_bed_kid.svg` (shared asset; `core/**` and
assets are off-limits to a screen agent under RULES §1).

**What:** the hero bed glyph's stroke width. The shipped asset is byte-exact to
K03's bed row at `stroke-width="2"`, but K04's own tile in
`design/html-source/screens/K04-quest-detail.html` draws the *same* paths at
`stroke-width="1.8"` — the only 1.8 in the design corpus. At the 64 px hero slot
that renders 5.33 px strokes against the design's 4.8 px, ~0.5 logical px
(1.6 device px) heavier, against the ICONS rule "each screen matches its own
design's glyphs exactly". One shared asset cannot be exact for K03 (2) and
K04 (1.8) simultaneously.

**Repro:** open `/quest-detail` for Maya's `q-tidy` ("Tidy your bedroom") and
compare the hero tile glyph's stroke weight against
`design/screens/light/K04-quest-detail.png` at the same 64 px slot.

**Failing proof** — verified by me, not taken on trust:

```
$ flutter test --timeout 120s --run-skipped --plain-name K04-BUG-5 \
    test/features/kid_home/k04_bugs_test.dart
Expected: contains 'stroke-width="1.8"'
  Actual: '<svg … stroke-width="2" viewBox="0 0 24 24">…'
00:00 +0 -1: Some tests failed.
```

**Resolution is the orchestrator's**, not a screen change: either accept the
0.5 px, or publish a K04-specific 1.8 variant — which also means updating
`test/design_system/audience_glyphs_test.dart:73`, which currently asserts `2` and
claims the asset is "the exact K03/K04 bed glyph". That claim is what makes this
a genuine conflict rather than a nitpick. Not patched, per the brief.

## The gap I left — ICONS audience-difference coverage (owed to iteration 4)

The existing K04-BUG-3 proof is good but has a specific hole: it hard-codes four
quest ids and four expected assets, so it would still pass if someone reverted
`_iconFor` to the **parent** table for the three keys where the audiences differ
and the hard-coded list happened to be edited in step — it never asserts the
*distinction*. The regression 5_ui flagged as Major was precisely "the screen
silently used the wrong audience's glyphs".

Design for the missing test (Maya's seed covers **all three** divergent keys, so
this is provable end-to-end on real data):

- `quest_icons.dart` diverges between audiences for exactly `bed`
  (`questBedKid` vs `questBed`), `dishwasher` (`questDishesKid` vs
  `questDishes`) and `book`/`reading` (`questReadingKid` vs `book`); `bins`,
  `hoover`, `paw`, `bag`, `leaf`, `shirt`, `plate` are shared.
- Maya's seeded quests map to those keys: `q-tidy`→`bed`,
  `q-dishwasher`→`dishwasher`, `q-reading`→`book`, plus `q-bins`→`bins`,
  `q-hoover`→`hoover`, `q-table`→`plate`.
- So: read each quest's `icon` **from the database** (DATA OVER MOCKS — do not
  hard-code the seed), assert the rendered 64 px `NestIcon.assetName` equals
  `questIconFor(icon, audience: NestAudience.kid)`, and for the three divergent
  keys additionally assert it is **not** `questIconFor(icon, audience:
  NestAudience.parent)`.
- Then prove it is column-driven rather than id-driven, with a fake repo holding
  quests whose icon keys map to different glyphs.

I had confirmed the seed's icon keys and the divergence table; the file was not
written.

## Iteration-2 gaps — all still closed

Dark mode, width 430, tap targets, `stepsFor`, and the non-loaded states at
320 px @ 1.3× in both themes remain covered by the iteration-2 files
(`quest_detail_matrix_test.dart`, `quest_detail_touch_targets_test.dart`,
`quest_detail_bloc_test.dart`, `quest_detail_view_test.dart`); nothing regressed.
`quest_detail_copy_parity_test.dart` remains intentionally absent — copy parity
lives as a group in the view test, so no coverage is lost.

## Not findings / process

Per the orchestrator rules these are not reported as blockers: uncommitted stage
artefacts in the worktree and merge order. `analysis_options.yaml` untouched; no
test skipped, weakened or deleted by me; nothing written outside
`app/test/features/kid_home/**` and `docs/screens/K04/**` this iteration (in fact
nothing at all — see the honesty note).

## Bugs found

1. **K04-BUG-5 — OPEN, Minor.** `ic_quest_bed_kid.svg` `stroke-width="2"` vs
   K04's design `1.8`; proof verified failing above. Needs an orchestrator
   decision (accept, or ship a K04 variant + update
   `audience_glyphs_test.dart:73`).
2. **Not a screen bug, but blocking sign-off:** the ICONS audience-difference
   regression guard this stage was supposed to add does not exist. Until it does,
   a future revert to `audience: parent` would be caught only by the hard-coded
   list in `k04_bugs_test.dart`, not by a rule-based assertion.

VERDICT: FAIL
