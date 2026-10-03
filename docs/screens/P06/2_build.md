# P06 Pocket money setup — integration build (Stage 2 INTEGRATE, iteration 7)

Two parallel builders worked on P06 against the merged main (`c20e368`); this stage
integrated the combined result. Route `/pocket-money-setup` · feature `pocket_money` ·
parent mode.

## 2a — logic builder (`2a_build_logic.md`, iteration 7)

- **CONTRACT CHANGES: none** — same events, `PocketMoneyState.setup`, same
  `watchSetup/setMode/setPayoutDay/setWeeklyBasePence` signatures; all feature fakes
  compile untouched.
- **Files changed:** `data/pocket_money_repository_impl.dart` only.
  - Review #4 (MINOR) — deleted the feature-private `_watchChildrenInsertionOrder`
    (raw `customSelect … ORDER BY rowid` plus its now-false "orders by nickname"
    rationale) and subscribed `watchSetup` to the canonical
    `AppDatabase.watchChildren(Seed.familyId)`, which implements the CHILD ORDER ruling
    (`ORDER BY createdAt, rowid`). Behaviour unchanged (seed `createdAt` order == `rowid`
    order) and the insertion-order tests pin it, now via the canonical query.
- Left alone by design: #1 (coin alignment), #2/#3 (semantics tap action — #3 is shared
  core), #5 (`_FailureBody` watch), #6 (radio semantics), #7 (copy ratification), #8
  (spacing token as size) — all view/shared/orchestrator territory.

## 2b — UI builder (`2b_build_ui.md`, iteration 7)

- **Files changed:** `presentation/views/pocket_money_setup_view.dart`,
  `pocket_money_setup_view_test.dart` (+2 tests), `p06_bugs_test.dart` (BUG-13 un-skipped).
- Finding 1 / ORCHESTRATOR 09:30 — the trailing coin value was a **loose** `Flexible`
  (flex:1, intrinsic child), so its ink ended at ≈322 instead of the card's content edge
  354 shared with the `+` buttons and the Sun pill. Now a tight `Expanded` with
  `textAlign: TextAlign.end`; the three red geometry tests are green in light, dark and at
  430.
- P06-BUG-13 — `Expanded` + `TextAlign.end` alone left the row splitting 50/50, so at
  320 × 1.3 the *label* truncated to `Coin val…`. The label now wraps
  (`softWrap: true, maxLines: 2`) so the value — the one text `1_plan.md` §5 sanctions
  for ellipsis — takes the shortfall. Two rejected layouts (non-flex label → overflow
  under the test fallback font; a 320-only wrap branch → would have contradicted the
  design) are recorded in the report so they are not re-attempted.
- Finding 2 / ORCHESTRATOR 09:42 — `_PocketOptionCard` and `_DayCell` wrapped a
  `GestureDetector(onTap:)` in `Semantics(excludeSemantics: true)`, which dropped the
  tap action along with the subtree (`tap=false actions=0` for all ten controls — the
  money-style and payout-day choices were inoperable by a screen reader). One line per
  widget restores `onTap:` on the `Semantics` node; two new tests assert
  `hasAction(SemanticsAction.tap)` for all ten and prove the action is wired by
  `performAction`-ing it and checking the selection actually moves.
- Finding 6 — the option cards now add `checked:` + `inMutuallyExclusiveGroup:` so the
  HTML's `role="radiogroup"`/`role="radio"` maps faithfully.
- Finding 5 — `_FailureBody` takes its message from the builder instead of a nested
  `context.watch`, so it no longer defeats `buildWhen`.
- Finding 8 — the selected radio's dot diameter is a private `_RadioDot._dotDiameter = 10`
  constant (CSS derivation in the comment) rather than `NestSpacing.gap10`.

## Integration actions (this stage)

None required. 2a declared no contract change and its repository edit is view-independent;
2b's view edits and new tests compile against the unchanged logic layer. The worktree
analyzed clean and the whole suite passed on the first run, so the integrator made **no
source edits** — only the stage gates.

## FIXES_6 items

| Item | Owner | Status |
|---|---|---|
| #1 (MAJOR) coin value not right-aligned (P06-BUG-13's cause) | 2b | DONE — `Expanded` + `TextAlign.end`; ink right edge now `card.right − s4` (±1px) in light, dark, 430 |
| #2 (MAJOR) option cards / day cells announce but carry no tap action | 2b | DONE — `onTap:` on the `Semantics` node; action asserted for all ten and `performAction` proven to write |
| #3 (MAJOR) shared `NestButton` / `NestChip` drop the tap action | shared track | OUT OF SCOPE (core, RULES §1) — being fixed on `shared/semantics_tap` per the 09:42 note, which must not fail P06; no SHARED_REQUEST filed |
| #4 (MINOR) hand-rolled child-order query with a stale rationale | 2a | DONE — canonical `AppDatabase.watchChildren` |
| #5 (MINOR) `_FailureBody` re-subscribes, defeating `buildWhen` | 2b | DONE — message passed in from the builder |
| #6 (MINOR) options announce as generic buttons, not radios | 2b | DONE — `checked` + `inMutuallyExclusiveGroup` |
| #7 (MINOR) screen-authored empty-state copy | orchestrator | **LEFT OPEN** — `Add children to set weekly amounts.` unchanged for the third iteration, awaiting a yes/no |
| #8 (MINOR) `NestSpacing.gap10` used as a size | 2b | DONE — private `_RadioDot._dotDiameter` |
| P06-BUG-13 (coin label truncation at 320 × 1.3) | 2b | DONE — un-skipped and green; **zero skips remain** in the feature |

Shared-track follow-ups (non-blocking): `SHARED_REQUEST` item 4 (`NestStepper` U+2212 →
retire `p06_weekly_stepper.dart`), item 5 (`NestChip` day variant → retire `_DayPill`),
and the `shared/semantics_tap` fix for #3.

## ORCHESTRATOR_NOTES

04:05 items 1–6 hold; 07:22/07:58 items hold (real-font geometry pins light **and** dark,
`−` glyph pinned by code unit, two-line H1 through `NestBalancedText`, the y anchors
pinned). The new 09:30 item (coin-value trailing alignment) and 09:42 item (semantics tap
actions on the screen's own controls) are both closed and test-covered.

## Analyze / test tails

- `dart format .` → `Formatted 409 files (0 changed) in 1.77 seconds.`
- `flutter analyze` (full app) → `No issues found! (ran in 8.0s)`
- `flutter test` (full app) → `All tests passed!` (`+1518`, EXIT 0, ~29s). Zero `skip:` and
  zero `google_fonts`/`GoogleFonts` references anywhere in
  `app/{lib,test}/features/pocket_money/`.

## Scope compliance

No integrator edits. Worktree changes are the two builders' files —
`app/lib/features/pocket_money/{data,presentation}/**` and
`app/test/features/pocket_money/**`, plus this screen's docs (RULES §1). No shared code,
no `analysis_options` change, no simulator used.

VERDICT: PASS