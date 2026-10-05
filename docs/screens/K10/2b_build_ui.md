# K10 Payout day — 2b build UI (iteration 2)

Screen: `/payout-day` (`KidJarRoutePaths.payoutDay`), kid mode, light + dark.
Scope: `app/lib/features/kid_jar/presentation/views/**` and
`presentation/widgets/**`, plus view/widget tests. No simulator was booted,
installed on or driven (only `5_ui` may use one). No whole-app `flutter test`
run. No `flutter clean`, no `google_fonts`, no `DateTime.now()`.

## Contract used (1_plan.md re-read + 2a re-read before finishing)

- `KidJarState.payout: PayoutCelebration?` + `copyWithPayout`;
  `KidJarPayoutRequested` on `payoutDayRoute`; guarded `_payoutSub`.
- This iteration the parallel logic builder has uncommitted WIP in the same
  worktree (`kid_jar_bloc.dart`, `payout_celebration.dart` and their tests per
  `git status`). No CONTRACT CHANGES section had been published in
  `2a_build_logic.md` at the time of writing, so the UI codes against the
  plan unchanged. The UI diff below touches no event/state/entity signature,
  so it is compatible with either side of the logic builder's fix.
- DATA OVER MOCKS holds: seeded DB copy (`Mum marked £3.80 as paid`,
  `£5.50 went into your Lego Friends set`, `£15.50` / `£9.49 to go` /
  `62% there!`) is the spec; mock numbers are never hard-coded.

## FIXES_1.md items — UI/layout/copy only

| # | Item | Owner | Status |
|---|---|---|---|
| K10-BUG-3 (major) | 320 px / 1.3× ellipsizes the note-2 title (`…Lego Friends…`) and the `£9.49 to go` money string mid-word | UI (mine) | **FIXED** — see below; skipped proof flipped live |
| K10-BUG-1 (minor, latent) | payout handler missing same-tick close guard (`kid_jar_bloc.dart`) | logic builder | untouched (not my layer) |
| K10-BUG-2 (minor) | `goalPercent` unclamped past target (`payout_celebration.dart`) | logic builder | untouched (not my layer) |
| 4_review finding 1 | truncated `_PayoutPip` doc comment | UI (mine) | **FIXED** |
| 4_review finding 2 | write-only `_PayoutFailure.message` param | UI (mine) | **FIXED** |
| 4_review findings 3–4 | bloc reload `errorMessage`, repo companion-move hardening | logic builder | untouched (not my layer) |

### K10-BUG-3 fix (two sites, both layout — never shorter copy)

1. `presentation/widgets/payout_note.dart` — dropped the `maxLines: 2` cap
   on the `.k10-t` title. The HTML sets no max-lines/line-clamp anywhere on
   this screen, so the title now wraps freely (3 lines at 320/1.3×) and the
   card grows with content exactly like the CSS box model. At 390/1.0 the
   seeded title still takes exactly 2 lines, so the recorded geometry bands
   (note 2 top 509, fund top 613) are unchanged.
2. `presentation/widgets/payout_fund_card.dart` — wrapped each `.k10-amts b`
   amount in `FittedBox(fit: BoxFit.scaleDown)` (left-aligned /
   right-aligned). The seeded `£9.49 to go` needs ~4 px more than the
   `spaceBetween` row offers at 320/1.3×; the box shrinks it to fit instead
   of cutting a money string mid-word. Cells that already fit render at
   scale 1.0, pixel-identical (geometry bands + dark-rect-equality hold).
   The `maxLines: 1` + ellipsis stay as a last resort for absurd values;
   `didExceedMaxLines` is false at every supported cell.

### Review findings 1–2

- `_PayoutPip` doc comment restored to a full lead line.
- `_PayoutFailure`: dropped the write-only `message` param/field and the
  `message: state.errorMessage` call-site arg (now `const _PayoutFailure()`);
  noted in the doc comment that the fixed kid-voice copy deliberately does
  not render the bloc error.

## Tests

- `payout_day_matrix_test.dart` — un-skipped K10-BUG-3 per the brief: added
  `(320, 1.3)` to the green copy-fit cells (now 6 widths/scales × 2 themes,
  all asserting `didExceedMaxLines == false` for all twelve strings) and
  deleted the parked `skip: true` proof. (File-name note: this file carries
  no `view`/`widget` in its name, but FIXES_1 §3.4 explicitly assigns the
  flip to the build stage and the logic builder owns no UI matrix file, so
  the flip is recorded here, not left dangling.)
- Results (`--timeout 120s`, every pumped test ends with `disposeApp`):
  - `payout_day_matrix_test.dart` → **+78, all pass** (was +76 ~1; the two
    new 320/1.3 theme cells are live and green, zero skipped).
  - `payout_day_view_test.dart` + `payout_day_view_geometry_test.dart` →
    **+12, all pass** (copy, Pip look, navigation, tap-action semantics,
    empty/failure frames, ±2 px bands, gutters, bottom edge — unchanged).
  - `my_jar_view_test.dart` + `my_jar_view_states_test.dart` +
    `my_jar_view_geometry_test.dart` → **+67, all pass** (K09 neighbour
    regression check; K10 widgets are not shared with K09).
- `dart format` clean on all four touched files (1 auto-fixed);
  `flutter analyze lib/features/kid_jar` + the three K10 test files →
  **No issues found!** (analyze covers the logic builder's concurrent WIP
  too — clean at the time of writing).

## LEFT FOR NEXT ITERATION

- Nothing UI-side. K10-BUG-1 and K10-BUG-2 plus review findings 3–4 are with
  the parallel logic builder (their WIP is uncommitted in this worktree);
  the integrator merges and runs the whole-app suite + simulator UI check.

VERDICT: PASS
