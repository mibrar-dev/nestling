# P15 · Child profile — Stage 2 INTEGRATE (iteration 2)

Route `/child-profile` · parent mode · feature `family` · light+dark designs.
Inputs re-read this stage: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`, `1_plan.md`,
**`ORCHESTRATOR_NOTES.md`** (exists — all 4 items mandatory), `FIXES_1.md`,
`SHARED_REQUEST.md`, `2a_build_logic.md`, `2b_build_ui.md`.
`main` was merged into `screen/P15` before this stage (`17a21b6`); the
uncommitted working tree is loop bookkeeping, not a finding.
No simulator was booted, installed on, driven or screenshotted (stage 2 must not).

## Summary of 2a (logic) + 2b (UI)

**Both halves landed coherently — the merge needed zero code changes.**
2a's summary line is "**Nothing in the logic layer is unfinished**"; 2b closed
every item it owned and left no contract for me to reconcile. The two builders
never collided: 2b explicitly confirmed it coded against 2a's shipped names and
had to bend nothing, and the split held (`2a` touched `domain/ data/ bloc/
family_routes.dart`; `2b` touched `views/ widgets/` and its own test file).

**2a — logic** (`presentation/bloc/**`, `data/`, `domain/`, `family_routes.dart`):

- Fixed **P15-BUG-1** (major): `?childId=` was ignored. `childProfileRoute`
  now reads `state.uri.queryParameters['childId']` and dispatches
  `FamilyChildSelected` before the load; the bloc persists valid ids via the
  new `selectChild`, so `watchProfile` and every sibling screen follow. It also
  records the request synchronously in a membership-gated `_pendingSelection`
  so the tight view proofs see the right child before the async persist lands.
- Fixed **P15-BUG-6** (major): `removeChild` cascades to
  `quest_completions / ledger_entries / savings_goals / reward_redemptions /
  earned_badges / pip_wardrobe`, its assigned `quests` (family-wide "Anyone"
  survive) and the `children` row — one transaction.
- Fixed **P15-BUG-7** (major): that same transaction repoints a stale
  `activeChildId` at the first remaining child in creation order, or NULL.
- Fixed **P15-BUG-8** (major): injectable `clock` on the repo, defaulting to
  `Seed.anchorOverride?.toUtc() ?? DateTime.now().toUtc()`; production
  behaviour unchanged.
- Fixed **P15-BUG-3** (minor, both variants): `copyWith(clearErrorMessage:)`
  clears on every load emission and on repeated identical remove failures, so
  a failure toasts again instead of being swallowed.
- Additive contract only: `FamilyChildSelected`, `selectChild`,
  `clearErrorMessage`, optional `clock` — every existing construction, event
  and test compiles unchanged. Un-skipped all six `p15_bugs_test.dart` proofs.

**2b — UI** (`presentation/views/**`, `presentation/widgets/**`):

- Closed **ORCHESTRATOR item 1 / P15-BUG-5** (major, subtitles ellipsised):
  new P15-local `child_profile_row.dart` (`ProfileRow`) puts the trailing
  **outside** the flex distribution so `Change ›` keeps its intrinsic 70.71 px
  and the subtitle column takes the rest, matching the design's
  `.list-main{flex:1}` / `.list-trail{flex-shrink:0}`.
- Closed **ORCHESTRATOR item 2 / 5_ui deviations 2+3** (major, two wrong row
  glyphs): Quests → `NestIcons.quests` (I verified `ic_quests.svg` really is
  the design's `<circle r="9"/>` + check); Pocket money → the coloured
  `NestlingIllustrations.coin` via a bare `SvgPicture` (the shared `NestIcon`
  would `srcIn`-tint it into a `£`).
- Caught and fixed an a11y regression of its own making: the `Stack`/`SvgPicture`
  glyphs briefly stopped merging into the row's `Semantics`, which would have
  announced a nameless image per row. Back to 8 labelled image nodes, both themes.
- Closed review 4/5/6/7 and P15-BUG-2/4; added the review-10 remove-failure test.

## Mandatory ORCHESTRATOR_NOTES items — verified landed

| Item | Status |
|---|---|
| 1 — subtitles in full, trail takes intrinsic width, main is `Expanded`, no `didExceedMaxLines` at 390 | **done** — `child_profile_row.dart:114` `Expanded` main, trail at `:140` outside flex; proof in `child_profile_theme_size_test.dart:360-402`, green |
| 2 — Quests row = circled check, Pocket money row = `coin.svg` | **done** — `child_profile_body.dart:398` (`NestIcons.quests`) and `:417-420` (`SvgPicture.asset(NestlingIllustrations.coin)`); both glyphs keep the same 24 px box in the 40 px tile, so no tile rect moved |
| 3 — keep "Maya knows *their* code" | **done** — deliberately unchanged by 2b; orchestrator ruling, not a finding |
| 4 — quest counts from the DB, not the design's mocks | **done** — 4 quests this week, 4 daily / 2 weekly rendered from bloc data |

## FIXES

| # | Item | Where | Done |
|---|---|---|---|
| 1 | Contract reconciliation (state/event/member names) between the two halves | — | none needed — additive contract only, nothing collided |
| 2 | Cross-feature anchor on the removed `'P15 Child profile'` placeholder (4 sites in `add_children_test.dart`) | closed by 2b in iteration 1 | verified green |
| 3 | Same placeholder anchor at `today_view_test.dart:541` (missed by 2b in iteration 1) | `app/test/features/today/today_view_test.dart` | fixed in iteration 1, still green; recorded in `SHARED_REQUEST.md` §3 for ratification |
| 4 | `p15_bugs_test.dart` six `skip:` markers hiding real proofs | 2a | done — all six un-skipped and green; `grep -rn "skip:" test/features/family/` is now empty |
| 5 | Compile errors / import breaks across the merge | — | none |

**This stage changed no source file.** The only edit in iteration 2 was the
stage note itself; every gate passed on the builders' output as delivered.

## Verification (run in `app/`, no simulator)

```
$ dart format .
Formatted 493 files (0 changed) in 3.23 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.9s)

$ flutter test
01:13 +2492 ~1: All tests passed!

$ flutter test test/features/family
00:10 +230: All tests passed!
```

Full suite: **2492 pass, 1 skip, 0 failed.** The single skip is
`p12_bugs_test.dart:320` (feature `pocket_money`, pre-existing, unrelated to
this merge and outside this screen's scope) — **no P15 test is skipped**.
No test was skipped, deleted, reworded or weakened to reach green; no
`analysis_options.yaml` change; `grep -rn "google_fonts\|GoogleFonts" lib test`
returns only a comment in `k03_bugs_test.dart`.

## Notes for the next stage (not findings)

- `presentation/widgets/child_profile_row.dart` is an explicitly temporary
  P15-local transcription of `NestListRow`, because the real fix is in
  `core/design_system/**` (RULES §1) and so is `SHARED_REQUEST.md` §1. It is
  built only from shared pieces (`NestList`, `NestTileTint`, `NestIcon`,
  `NestType`, `NestSpacing`, `Material`/`InkWell`, same `Semantics` contract)
  with no colour or spacing literal of its own. **Delete it and pass
  `NestListRow` again once §1 lands on `main`** (§2b's `leadingWidget` would
  then be needed for the coin).
- Open shared asks, none blocking: `SHARED_REQUEST.md` §1 (row flex),
  §2a/§2b (`NestIcons.quests` alias, a `leadingWidget` escape hatch on
  `NestListRow`), §3 (`NestPip.rowSlot = 84`).
- The orchestrator should still ratify the cross-feature anchor swap in
  `app/test/features/today/today_view_test.dart` (review finding 9).

## Left for the UI stage (5_ui)

1. **Re-shoot both themes** (`shot.sh` `/child-profile`, udid
   `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`) and `compare.py` against
   `design/screens/{light,dark}/P15-child-profile.png`. Band geometry is
   unchanged from iteration 1 (hero 47/164, stats 227/82, Pip 325/116, list
   457/180, danger 653/80), whose `5_ui` measured every edge within ±2 px, so
   only the two glyphs and the three subtitle strings need re-measuring.
   Per the UI VERDICT RULE, report measured y for the title, the first control
   and each card top, design vs app.
2. Confirm the three deviations 2b closed are actually gone on screen: Quests
   tile = circled check, Pocket-money tile = gold coin, and all three
   subtitles render in full with no trailing `…`.
3. Owner-rule sweep in both themes: bottom edge under the tab bar (shared
   `NestTabBar` code — a strip there is a SHARED_REQUEST, not a fix here),
   20 px gutters on every edge, DATA OVER MOCKS numbers, and Pip = the
   child's own `PipAvatar` (Maya mochi·sunny·stage 3 at 84 px; Leo
   bolt·sky·stage 2), never a `pip_stage_*.svg`.

VERDICT: PASS
