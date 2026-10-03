# P15 · Child profile — bug hunt (Stage 6, iteration 4)

Route `/child-profile` (`FamilyRoutePaths.childProfile`) · feature `family` ·
parent mode · designs `design/screens/{light,dark}/P15-child-profile.png` ·
tree tested: iteration-4 checkpoint **`686bd69`** ("P15: checkpoint after
build (iteration 4)").

**Live date note:** this stage ran at **00:03 BST on Sunday 4 October 2026** —
the first run where the real wall clock is past the pinned seed anchor
(Sat 3 Oct, `test/flutter_test_config.dart`). That makes this pass the live
end-to-end proof of the P15-BUG-8 injectable-clock fix: P15's suite is green
on a date that used to break it.

Sources re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md`, `FIXES_3.md`, `SHARED_REQUEST.md`, `ORCHESTRATOR_NOTES.md`
(exists — all four items re-checked below), plus the iteration-4 change
surface (`child_profile_view.dart`'s `GoRouter.maybeOf` guard).

Method: all eight prior proofs are un-skipped and green (regression guards);
this iteration's adversarial pass attacked the new guard, the date rollover
and the still-open edges. No new P15 bug was found, so this stage adds no new
tests and no skips.

**Result: no new P15 bugs; P15-BUG-10 verified fixed; all prior bugs pinned.
VERDICT: PASS.** (The repo-wide suite's single red is a shared/core test P15
cannot edit — see "The one repo-wide red".)

| Id | Severity | Status on `686bd69` | Evidence |
|---|---|---|---|
| P15-BUG-1 | major | **FIXED** (iter 2) | `P15-BUG-1a/b` green |
| P15-BUG-3 | minor | **FIXED** (iter 2) | `P15-BUG-3` green |
| P15-BUG-6 | major | **FIXED** (iter 2) | `P15-BUG-6` green |
| P15-BUG-7 | major | **FIXED** (iter 2) | `P15-BUG-7` green |
| P15-BUG-8 | major | **FIXED** (iter 2) | `P15-BUG-8` green **and** the suite is green on the real 4 Oct (below) |
| P15-BUG-9 | major | **FIXED** (iter 3) | `P15-BUG-9a/b` green |
| P15-BUG-10 | minor | **FIXED** (iter 4) | `child_profile_view_test.dart:698` proof green; independently re-probed (A/B below) |

## The live date rollover (the P15-BUG-8 fix, proven in the wild)

* Real today is **Sun 4 Oct 2026**; the tests pin `Seed.anchorOverride` to
  **Sat 3 Oct 2026**. Before the fix, `watchProfile` read `DateTime.now()`, so
  the demo's daily completions stopped counting the moment the clock passed
  midnight — the whole P15 suite would have gone red today.
* On `686bd69`: **family suite `+281` green** (including the proof that pins
  the anchor and the explicit-clock seam test), so the fix holds.
* Independent seam probe (`clock` injected): anchor **4** →
  Sun 4 Oct 00:03Z **2** (the two daily completions drop out; the two weekly
  ones stay, since the London week is Mon 29 Sep–Sun 4 Oct) → Mon 5 Oct
  **0** (new week). Exactly the PERIODS ruling.
* This also matches the shared test's wall-clock flakiness the build diagnosed
  (`SHARED_REQUEST.md` §6): that test does its own `DateTime.now()`-based
  period check without a seam — precisely the bug class P15 fixed.

## Iteration-4 adversarial probes (all green)

| Probe | Result |
|---|---|
| Router-less mount (bare `MaterialApp`, no `GoRouter`) + a theme swap that re-fires `didChangeDependencies` | builds, renders `Maya`, no `GoError`, no exception ✓ (P15-BUG-10) |
| Router-less mount with an empty family (`Seed.empty`) | `No children yet` renders, no exception ✓ |
| Clock seam across the rolled date (anchor / Sun 4 Oct / Mon 5 Oct) | 4 / 2 / 0 ✓ |
| Deep link to Leo, then switch theme light→dark→light | child stays `leo`, no exception (the `_seenChildId` guard never re-dispatches a stale id) ✓ |
| Deep-link switching on the rolled date (`maya` → `leo` → `maya`) | each switch lands, `active_child_id` follows ✓ |
| ORCHESTRATOR_NOTES item 1 (full subtitles) | holds (test stage's `didExceedMaxLines` proof green; UI PASS) ✓ |
| ORCHESTRATOR_NOTES items 2/3 (circled check, coin) | hold (assets verified; UI PASS) ✓ |
| ORCHESTRATOR_NOTES item 4 (pronoun, DB counts) | deliberate; not reported as findings ✓ |
| Simulator policy | no simulator was booted, installed on, screenshotted or driven in this stage ✓ |

The remaining brief checklist (0/1/6 children, long names, £0.00/£999.99,
9999 coins, empty lists, rapid double taps, back navigation, restart
persistence, kid-mode guard, dark mode, 320 × 1.3, emit-after-close, money in
integer pence) was probed green in iterations 1–3; the only source change since
is the two-line router guard, whose blast radius is covered by probes A/B and
the green 281-test suite.

## Cross-check with the parallel stages

* **`4_review.md` (iteration 3) — PASS**; its three minors stay tracked there:
  (1) `FamilyChildSelected` is dispatched twice per switch (harmless,
  idempotent, membership-gated `selectChild`; rapid-switch probes green),
  (2) a stale comment at `child_profile_view.dart:82-84`, (3) a comment naming
  the wrong token owner in `child_profile_row.dart`. Not duplicated here.
* **`5_ui.md` (iteration 3) — PASS**: mean diff 0.99% / 0.92%, every band
  within ±2 px; no visual delta expected from this iteration's router-guard
  change.
* **Test stage**: the family suite is `+281` green at this snapshot.

## The one repo-wide red (shared, not a P15 finding)

`flutter test test/core/family_time_test.dart` →
`seed + repository zone plumbing › kid_home completions are stamped with the
family zone` → `Bad state: Too many elements`. This branch touches no
`lib/core/**` or `test/core/**` file (`git diff main HEAD -- app/test/core
app/lib/core` is empty), and the build has now diagnosed it precisely: the
test is **wall-clock flaky** (its Dubai leg fails once the UTC evening makes
Dubai's "today" the 4th, so `completeQuest` inserts instead of flipping the
seeded row), while the behaviour it asserts is correct. `SHARED_REQUEST.md`
§6 carries a verified patch; it is the only thing keeping the full-suite gate
red, and it is not P15's to edit (RULES §1).

## Gates (run in `app/` on `686bd69`)

```
$ dart format test/features/family/p15_bugs_test.dart
Formatted 1 file (0 changed) in 0.01 seconds.

$ flutter analyze
No issues found! (ran in 3.4s)

$ flutter test --no-pub test/features/family/p15_bugs_test.dart
00:03 +8: All tests passed.          # all eight proofs, no skips

$ flutter test --no-pub test/features/family
00:13 +281: All tests passed.
```

No production file was changed by this stage: the only edit is the
iteration-4 header of `app/test/features/family/p15_bugs_test.dart` plus this
document. No `google_fonts`, no `analysis_options` change, no test weakened or
skipped.

VERDICT: PASS
