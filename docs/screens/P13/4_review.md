# 4 — QA code review (iteration 2) — P13 Payout (parent)

Scope reviewed: `git diff main...HEAD` as of `bf9f239` (iteration-2 build
checkpoint, main merged at `882d835`). Diff paths: `data/
pocket_money_repository_impl.dart`, `presentation/bloc/{pocket_money_bloc,
pocket_money_event}.dart`, `presentation/views/payout_view.dart`,
`presentation/widgets/payout_sheet.dart`, 8 test files under
`test/features/pocket_money/`, `docs/screens/P13/**`. All inside the RULES §1
allow-list for `pocket_money` (the `data/**` edit is in the feature's own
repository impl, which §1 lists; no new fields/methods, no schema change).
`analysis_options.yaml` untouched, no `core/`, no `app/`, no other feature.

`docs/screens/P13/ORCHESTRATOR_NOTES.md` now exists — **all three of its
items are mandatory** and each is verified below against the code, the CSS
and my own pixel measurements of the design PNGs.

## Gates run by this stage (no simulator, no code edited)

```
flutter analyze                          → No issues found! (4.7 s)
dart format --set-exit-if-changed .      → Formatted 492 files (0 changed)
flutter test test/features/pocket_money  → +440 ~1: All tests passed!
flutter test p13_iter2_audit_test.dart   → +11 ~1: All tests passed!
```

(`+440` = the committed `+423` plus a concurrent stage-3 scratch audit file;
see *Out-of-scope observations* §B. The one skip is pre-existing P12
`p12_bugs_test.dart:320`.)

## Iteration-1 findings — re-verification (all 10 + 5 bugs + 2 UI deviations)

Every item from my iteration-1 review, the 6_bugs list and the 5_ui
deviations was independently re-checked against the merged tree:

| Iter-1 item | Status | Evidence |
|---|---|---|
| R#1 / BUG-03 / UI dev 1 — scrim not `inset: 0` | **fixed** | `_DimmedLedger` is now chrome `Stack` + full-bleed `Positioned.fill` scrim (`payout_view.dart:334-348`); geometry test pins the scrim rect `Rect(0,0,390,844)` (`payout_widget_geometry_test.dart:261-283`); regression test asserts a tap over the title dismisses (`payout_view_test.dart:512-540`) |
| R#2 / BUG-01 — double-tap double-write | **fixed, three layers** | view `_submit` re-entry guard (`payout_view.dart:210-214`), sheet `busy` → `loading:` CTA (`payout_sheet.dart:165-168, 243-247`), bloc per-child `_payoutInFlight` (`pocket_money_bloc.dart:30-38, 265`) with `finally` re-arm. Regression: gated double-tap writes exactly one payout/move and goal 1550→1650 (`p13_bugs_test.dart:290-355`, `payout_view_test.dart:567-602`, `payout_bloc_test.dart:220-273`) |
| R#3 — ticked £0.00 child writes "Paid £0.00" | **fixed, two layers** | view skips `owed <= 0` (`payout_view.dart:217-221`); repository no-ops `amountPence <= 0` (`pocket_money_repository_impl.dart:337-339`). Regression: `payout_view_test.dart:604-645`, `payout_repository_test.dart:104-119` |
| R#4 — leftover `zz_probe_test.dart` broke analyze | **fixed** | deleted; probes promoted to real assertions; analyze clean |
| R#5 — `_prime` mutated State in build | **fixed** | priming moved to a dedicated `BlocListener` + `initState` (`payout_view.dart:53-76, 161-173`); `build` is pure |
| R#6 / BUG-05 — dimmed chrome not `ExcludeSemantics` | **fixed** | `ExcludeSemantics` around the chrome column (`payout_view.dart:287`); tests assert `'Pocket money'` and the summary text are absent from the semantics tree (`payout_view_test.dart:542-565`, `p13_bugs_test.dart:532-567`) |
| R#7 — saverow hard-codes "her Lego fund" | **fixed with one residual minor** | data-driven `PayoutSaveRow.label` (`payout_sheet.dart:412-431`): verbatim design string for a Lego-titled goal, neutral `"… money to their {title} fund"` otherwise; tested (`payout_view_test.dart:647-671`). Residual pronoun edge = new finding 1 below |
| R#8 — grabber height duplicated | **fixed** | `NestSpacing.gap5` (`payout_sheet.dart:57-59`); `PayoutCheck.grabberHeight` deleted |
| R#9 — title announced twice; scrim unreachable by AT | **fixed** | container `label:` dropped (single header announcement, `payout_sheet.dart:170-176`); scrim has `Semantics(button: true, label: 'Close payout', onTap:)` (`payout_view.dart:337-341`) with `hasAction(tap)` asserted (`payout_view_test.dart:556-561`) |
| R#10 — `_FailureBody` missing status-bar reserve | **fixed** | `NestStatusBar()` added (`payout_view.dart:426`) |
| BUG-02 — £1.00 move not clamped to payout | **fixed, two layers** | view `min(100, owed)` (`payout_view.dart:224-227`); repository `clamp(0, amountPence)` (`pocket_money_repository_impl.dart:340-345`). Regression: `p13_bugs_test.dart:359-424`, `payout_repository_test.dart:121-156` |
| BUG-04 — repeated identical failure gives no feedback | **fixed** | bloc clear-before-write (`pocket_money_bloc.dart:269-278`); toast fires on every repeat (`p13_bugs_test.dart:477-528`, `payout_bloc_test.dart:275-304`) |
| UI dev 2 — Leo row text ≈ 2 px high | **fixed** | root-caused to the 18 px amount making `.who` 44 tall instead of 40; with the inline 13 px amount the block is 40 and centres exactly (see orchestrator item 3 below) |

## ORCHESTRATOR_NOTES — mandatory items, independently verified

1. **Scrim covers the whole screen.** Confirmed in code (above) and pinned by
   a test asserting the barrier rect is `(0,0,390,844)`. I also re-sampled
   the design PNG: everything above the sheet top (343) — status area, title,
   card — is the scrim blend in both themes (light `(151,148,158)` =
   paper×45 % scrim; card `(154,152,166)` = surface×scrim; dark `(8,7,12)` /
   `(12,11,17)`). The new layering matches it; the OS status-bar glyphs on
   top are excluded per the status-bar rule. **Done.**
2. **Amounts inline at the subtitle's size.** Verified from the design PNG,
   not just the notes: the `£4.20` digits in row 1 render at `(74,70,104)` =
   **`--ink-2` `#4A4668`** (not `--ink`), with a glyph height ≈ 8.3–9.4 px —
   a 13 px cap, not 18 px — sitting on the caption baseline. And the CSS
   agrees: `P13-payout.html:25` puts `<span class="money">` *inside* the
   `.caption` line, and `components.css:155` shows `.money` adds only
   `tabular-nums` + `w700` (the page rule `.child .am{18px}` is never
   matched by this screen's markup). The code renders
   `NestType.money(ink2).copyWith(fontSize: 13, height: 18/13)`
   (`payout_sheet.dart:362-375`), i.e. 13 px w700 tabular ink-2 inline —
   exact. **Done.**
3. **Row text y within ±1.** Verified against the PNG: name ink starts
   463.3 (line box 458…480), subtitle ink 478…496 (line box 480…498), Leo's
   name ink 549.3 (line box 544…566) — matching the `.who` = 22 + 18 = 40
   centred in the 48 px content box. The geometry test pins
   `name.top ≈ 458 (±1)`, `subtitle.top ≈ 480 (±1)`, Leo `544`/`566`
   (`payout_widget_geometry_test.dart:206-255`). **Done.**
4. **Pinned in real-font geometry tests + a scrim-cover test.** Both exist
   and pass (same file, `FontLoader` on the bundled Inter/Nunito). **Done.**

## New findings (iteration 2) — minor only

1. **MINOR — the saverow pronoun is keyed off the goal title, so a boy's
   Lego goal still renders "her Lego fund".**
   `payout_sheet.dart:427-429`: `if (title.toLowerCase().contains('lego'))
   return "Move £1.00 of $name's to her Lego fund";` — the gendered design
   string is chosen for ANY Lego-titled goal, regardless of which child owns
   it. The seeded path (Maya + "Lego Friends set") is character-perfect and
   the non-Lego fallback is neutral, so this only bites a family where Leo
   (or any non-Maya child) owns a Lego goal — exactly the failure mode
   finding R#7 set out to remove. The iteration-2 test stage has already
   pinned this as **P13-I2-01 (OPEN, minor)** with a skipped reproducer in
   its audit file. Fix: gate the verbatim string on the goal *identity*
   (e.g. `id == 'goal-lego'` / exact seeded title) rather than a substring,
   or drop the pronoun from the fallback branch used for other children
   ("Move £1.00 of {nick}'s money to the Lego fund"). Needs an orchestrator
   copy ruling either way — do not silently reword the design string.
2. **MINOR — `_lastFailure` re-arm block has an unreachable branch.**
   `payout_view.dart:51, 210-214`: the failure listener always clears
   `_submitted` when it surfaces an error (`:86-89`), and every writer of
   `_submitted` also resets `_lastFailure` (`:239-240`), so whenever
   `_submitted.isNotEmpty` at `_submit` entry, `_lastFailure` is null and
   the bloc's `errorMessage` is too — meaning `:213 _submitted.clear()`
   can never execute and the `error != _lastFailure` comparison can never
   be false. The reachable half of the guard (drop a same-frame re-entry
   while a write is in flight) is correct and tested
   (`payout_view_test.dart:567-602`); the unreachable half is harmless but
   misleading. Fix: either delete `:210-214` and keep only the `busy` CTA +
   bloc guard as the documented mechanism, or keep the block with a comment
   stating it is belt-and-braces for a same-frame re-entry.
3. **MINOR — the scrim's dismiss node has no `performAction` test.**
   `payout_view_test.dart:556-561` asserts `hasAction(SemanticsAction.tap)`
   on `'Close payout'` and `p13_bugs_test.dart:455-464` dismisses via a
   physical `tapAt`, but nothing drives `performAction(SemanticsAction.tap)`
   on the node itself, which is what VoiceOver/TalkBack actually invokes
   (the ACCESSIBILITY ACTIONS rule's `performAction` half). The node is
   correctly wired (`onTap: onDismiss` on the `Semantics`,
   `payout_view.dart:337-341`), so this is a coverage gap, not a defect.
   Fix: three lines in `payout_view_test.dart` — `performAction` on the
   `'Close payout'` node, settle, assert `currentPath == '/money'`.
4. **MINOR — stale narrative comment in the BUG-01 regression test.**
   `p13_bugs_test.dart:304-306`: "the sheet has no in-flight state — the
   CTA stays enabled and looks untouched" describes the *pre-fix* behaviour
   in the present tense, directly above an assertion that now passes
   *because* the CTA is `loading:` and inert. A reader could mis-copy the
   comment as current behaviour. Fix: reword to past tense / "before the
   fix".

## Out-of-scope observations (NOT findings — recorded for the orchestrator)

A. **`test/core/family_time_test.dart:319` fails right now, and it is a
   main-side, time-of-day flake — not attributable to this diff.** Mechanism
   verified by reading and by running it standalone: the test seeds
   (anchored to 3 Oct 2026), moves the family to Dubai, then calls
   `completeQuest('leo', 'q-plants')`, which uses the **real** clock
   (`kid_home_repository_impl.dart:158`). Dubai (UTC+4) rolls to 4 Oct at
   20:00 UTC; after that, the seeded 3-Oct `to_do` row is outside the current
   Dubai day, so the period rule inserts a second row and
   `leoRows.single` throws `Bad state: Too many elements`. It passes before
   20:00 UTC (which is why iteration 1's `flutter test` was green at
   `+2217`) and fails after (my run at 21:49 BST = 20:49 UTC). P13's diff
   touches neither `core/` nor `kid_home`, and RULES §1 forbids me from
   fixing it here. Suggested orchestrator fix: pin the clock in
   `family_time_test` (the `clock` package / a `nowUtc` injectable on the
   repository) or query with a `status` filter instead of `rows.single`.
B. **Concurrent stage scratch files were mid-write in this worktree during
   my run.** `_probe2_p13_test.dart` (stage 6) was created and deleted while
   I worked; `p13_iter2_audit_test.dart` (stage 3) is still untracked and
   briefly failed to load/run while being edited — it now passes standalone
   (`+11 ~1`, one skip = the pinned P13-I2-01 above). Per the process rule,
   uncommitted work is the loop's concern, not a finding; I verified none of
   it is in `git diff main...HEAD`, and the committed feature suite is green.
C. **The Drift "database class created multiple times" debug warning** seen
   at the tail of test runs comes from `setUpTestScope`
   (`test_scope.dart:24`) constructing a second `AppDatabase` while the
   GetIt one lives — different executors, no shared connection, so the race
   the warning describes does not apply. Pre-existing across suites;
   informational only.

## Checked and found correct (no action)

- **Architecture.** Feature-first; domain untouched (entities + abstract
  repo only); the data-layer edit stays inside the feature's own impl; one
  BLoC with one new event + handler following the P12 write-through pattern;
  no DI/route changes (route + kid guard already on main). Bloc
  `_payoutInFlight` is instance state on a route-scoped bloc — no leak
  across routes.
- **Design system.** No literal colours anywhere; sizes from
  `NestSpacing`/`NestRadii`/`NestDevice`; the only numerics are the
  documented call-site overrides (`.pay h2` 24/30 w900, `.nm` 16/22, `.sub`
  14/20, amount 13/18, sheet 88 %, check 48/14/2) — none of which has a
  shared token, and `core/` is off-limits. No `google_fonts`; no
  `letterSpacing` added anywhere in the feature; `NestBalancedText`
  correctly absent (`.pay h2` sets no `text-wrap: balance`; the rule forbids
  it on `.h2`). `NestBottomSheet`/`NestModal` correctly not reused
  (documented mismatch), `PayoutCheck` has no DS equivalent.
- **Copy, character-for-character** on the seeded path against
  `P13-payout.html`: ASCII `0x27` in `you've`/`Maya's`, `&` in the CTA,
  U+00B7 separators, U+2014 spaced em dash in the toast, `£1.00` from
  `moneyPounds(100)`, and the saverow verbatim via the Lego branch. UK
  spelling throughout; no new visible strings except the a11y-only
  `'Close payout'` (design has the scrim `aria-hidden`, but the
  accessibility-actions rule requires the dismiss to be operable — correct
  call).
- **Owner rules.** Bottom edge: paper to the last pixel row (50 px bottom
  pad; rendered-pixel probe in `payout_responsive_test.dart` asserts it at
  320/390/430 × light/dark). Alignment: one 20 px gutter shared by title,
  rows, saverow, CTA and the check column, asserted on rendered rects.
  Child order: creation order everywhere (rows, saverow, summary, priming,
  saveChildId). Zero dark-mode branches.
- **Accessibility.** Every control exposes `SemanticsAction.tap`; all
  `excludeSemantics: true` wrappers (check, scrim, NestButton label) pass
  `onTap:`; `performAction` flips real state for checks and the toggle; the
  disabled/busy CTA exposes no tap and reports `enabled: false`
  (`NestButton` `loading` path); dimmed chrome is out of the tree; tap
  targets ≥ 44 (check 48, toggle 59×44 incl. the 6 px outside the painted
  pill — tested; CTA 52; scrim full-bleed).
- **Data over mocks / TRIAL / PERIODS / PIP / chips.** Amounts, weekday,
  goal, avatar tint from `Seed.demo`; no `subscription_status` writes; no
  quest-period logic on this screen; no Pip on this screen; no `NestChip`
  rows.
- **Performance.** No `Timer`/`AnimationController` (motion rule trivially
  satisfied); no owned streams; `buildWhen` narrows rebuilds to
  status/data/errorMessage; `_submitted`/`_ticked` churn is one `setState`
  per gesture; `mounted`-guarded `_goBack`; the concurrent-write path
  (two children, one tap) serialises through Drift transactions and is
  asserted to write exactly one row per child.
- **Error handling.** Failure keeps `loaded` + friendly toast + retry
  reachable (clear-before-write makes repeats a state change); success is
  announced only on the stream proof; `Try again` re-requests the stream
  (covered by `payout_states_test.dart`, 8 tests, after the stage-3 fix of
  the `bloc.close()`-on-live-stream hang).
- **Children's Code.** Parent-mode screen; no analytics/ads/tracking
  anywhere in `pubspec.yaml` or the diff; no child data leaves the device;
  kid-mode deep link to `/payout` stops at the parental gate (tested,
  `p13_bugs_test.dart:756-765`); no `£` surfaces in kid mode from here.
- **Test hygiene.** No skips introduced by P13 (the only feature-suite skip
  is pre-existing P12); the P12 `pageBack → handlePopRoute` change is
  mechanics-only with assertions intact; responsive coverage runs on real
  surfaces (the two harness-trapped `payout_view_test.dart` cases carry a
  `HARNESS TRAP` comment and the SHARED_REQUEST for `pumpAppRoute` is filed
  with `Blocks: no`).

## Verdict

No blocker and no major findings. Four minors: the goal-title-keyed pronoun
(already pinned by the test stage as P13-I2-01), an unreachable re-arm
branch, a missing `performAction` test on the scrim node, and one stale test
comment. All iteration-1 findings, all five P13-BUGs, both 5_ui deviations
and all three mandatory ORCHESTRATOR_NOTES items are fixed and pinned by
tests. Gates run by this stage are green; the one red test in the full suite
is a main-side, time-of-day flake in `test/core/family_time_test.dart:319`,
documented above for the orchestrator and not attributable to this diff.

VERDICT: PASS