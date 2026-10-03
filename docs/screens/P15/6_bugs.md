# P15 · Child profile — bug hunt (Stage 6, iteration 3)

Route `/child-profile` (`FamilyRoutePaths.childProfile`) · feature `family` ·
parent mode · designs `design/screens/{light,dark}/P15-child-profile.png` ·
tree tested: iteration-3 checkpoint **`422e41e`** ("P15: checkpoint after
build (iteration 3)"), main merged through `b2a8b8f` (shared batch 5).

Sources re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
`2_build.md`, `FIXES_2.md`, `SHARED_REQUEST.md`, `ORCHESTRATOR_NOTES.md`
(exists — all four items re-checked below), plus the iteration-3 sources
(`family_routes.dart`, `child_profile_view.dart`, `family_repository_impl.dart`,
`family_bloc.dart`, `child_profile_row.dart`, `child_profile_copy.dart`).

Method: every prior bug's proof is un-skipped and green (regression guards);
this iteration's adversarial pass re-probed the fixed paths and attacked the
new ones — the route wrapper + view `didChangeDependencies` re-dispatch, the
re-entrant `watchProfile` ledger switch, the `formatPounds` copy swap and the
token-only `ProfileRow` change. No new P15 bug was found, so this stage adds
no new tests and no skips; the eight proofs stay green.

**Result: no new P15 bugs; all prior bugs verified fixed. VERDICT: PASS.**
(The one red in the repo-wide suite is a shared/core test P15 cannot edit —
see "The one repo-wide red" below.)

| Id | Severity | Status on `422e41e` | Evidence |
|---|---|---|---|
| P15-BUG-1 | major | **FIXED** (iter 2) | `?childId=` selects on entry; `P15-BUG-1a/b` green |
| P15-BUG-3 | minor | **FIXED** (iter 2) | clear-then-raise re-emits; `P15-BUG-3` green |
| P15-BUG-6 | major | **FIXED** (iter 2) | cascade removes all dependent rows + assigned quests; `P15-BUG-6` green |
| P15-BUG-7 | major | **FIXED** (iter 2) | stale `active_child_id` repointed; `P15-BUG-7` green |
| P15-BUG-8 | major | **FIXED** (iter 2) | injectable anchor-aware clock; `P15-BUG-8` green |
| P15-BUG-9 | major | **FIXED** (iter 3) | live branch page follows the new `?childId=`; `P15-BUG-9a/b` green |

## Iteration-3 adversarial probes (all green)

| Probe | Result |
|---|---|
| Two different `?childId=` in the same frame (`leo`, then `maya`) | last request wins; `maya` rendered ✓ |
| `leo` → no query → `maya` transition (selection persists through the tab root, then switches) | `maya` rendered, `active_child_id = maya` ✓ |
| Back-and-forth `leo/maya/leo/maya` switching on the live branch page | each switch renders the right child ✓ |
| Deep link after removing the deep-linked child (Leo removed → profile falls to Maya → link to Maya) | correct fallback then switch ✓ |
| Deep link to an already-removed child | falls back to the first child, no resurrection, no poisoned `active_child_id` ✓ |
| £0.00 and £999.99 money copy (`formatPounds` swap) | `£0.00 a week · Owed £0.00` and `£999.99 a week · Owed £999.99` exact ✓ |
| Long name (`Maximilian-Alexander`) at 320 × textScale 1.3 | no overflow exception ✓ |
| Repository-level rapid `selectChild` (single and double, the route's two dispatches) | stream emits `[maya, leo, maya]`, i.e. the switch always lands ✓ |
| Back from `/kid-pin`, restart persistence, unknown-id fallback, 6 children | green in iteration 2, unchanged by this build ✓ |
| ORCHESTRATOR_NOTES item 1 (full subtitles) | holds; test stage's `didExceedMaxLines` proof green, UI stage measured no `…` ✓ |
| ORCHESTRATOR_NOTES items 2/3 (circled check, coin) | hold; `ic_quests.svg` = design circle+check, `NestlingIllustrations.coin` = design `coin.svg`; UI PASS ✓ |
| ORCHESTRATOR_NOTES item 4 (pronoun "their", DB counts) | deliberately unchanged; not reported as findings ✓ |
| Simulator policy | no simulator was booted, installed on, screenshotted or driven in this stage ✓ |

**Timing-artifact note (not a finding).** A probe that asserted immediately
after one `pump()` following a real-async flush read the previous frame
(`leo`) while the router URI and `active_child_id` already said `maya`. With
the frame settled — as the shipped proofs do, and as the engine does
automatically in a real app — the bloc state, the rendered body and the DB all
agree (`maya`). The state was never lost; this is a widget-test pump artefact,
verified by subscribing to the bloc directly (`states=[maya]`,
`blocProfile=maya`).

## Cross-check with the parallel stages

* **`4_review.md` (iteration 3) — PASS**, three minors carried there and not
  duplicated here: (1) `FamilyChildSelected` is dispatched twice per child
  switch (`_ChildProfileRoute.didUpdateWidget` **and**
  `ChildProfileView.didChangeDependencies`) — harmless (idempotent,
  membership-gated `selectChild`; my rapid-switch probes are green) but
  redundant; (2) a stale comment at `child_profile_view.dart:76-78`; (3) a
  comment naming the wrong token owner in `child_profile_row.dart:91`.
* **`5_ui.md` (iteration 3) — PASS**: mean diff 0.99% light / 0.92% dark,
  every band within ±2 px, no deviations.
* **Test stage (iteration 3)**: the family suite is `+278` green at this
  snapshot; the earlier wrong clock expectation (Sunday 4 Oct still counts
  that week's weeklies → `2`, not `0`) was corrected by that stage.

## The one repo-wide red (shared, not a P15 finding)

`flutter test test/core/family_time_test.dart` →
`seed + repository zone plumbing › kid_home completions are stamped with the
family zone` → `Bad state: Too many elements`. Proof it is not P15's:
`git diff main HEAD -- app/test/core app/lib/core` is **empty** — this branch
touches no `lib/core/**` and no `test/core/**` file. The failure comes from
`main`'s shared seed (a pre-created `to_do` row for `q-plants` that this test
predates) and hits every screen loop; the iteration-3 build filed it as
`SHARED_REQUEST.md` §6 with a concrete fix. It keeps the **full-suite** gate
red until the orchestrator lands that shared fix; it does not make P15's own
suite or this stage's verdict fail.

## Gates (run in `app/` on `422e41e`)

```
$ dart format test/features/family/p15_bugs_test.dart
Formatted 1 file (0 changed) in 0.02 seconds.

$ flutter analyze
No issues found! (ran in 4.8s)

$ flutter test --no-pub test/features/family/p15_bugs_test.dart
00:03 +8: All tests passed.          # all eight proofs, no skips

$ flutter test --no-pub test/features/family
00:11 +278: All tests passed.
```

No production file was changed by this stage: the only edit is the
iteration-3 header of `app/test/features/family/p15_bugs_test.dart` plus this
document. No `google_fonts`, no `analysis_options` change, no test weakened or
skipped.

VERDICT: PASS
