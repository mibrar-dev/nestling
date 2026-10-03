# 2b — Build, UI chunk (iteration 2) — P13 Payout

Every UI item in `FIXES_1.md` (3 test findings + 10 review findings + 5 bug
findings) and all three `ORCHESTRATOR_NOTES.md` items are implemented. No
simulator was booted (stage rule); geometry is pinned by real-font widget
tests instead.

## Files changed (UI chunk only)

| File | Change |
|---|---|
| `app/lib/features/pocket_money/presentation/views/payout_view.dart` | scrim `inset: 0` + `ExcludeSemantics` + labelled dismiss, `_FailureBody` status-bar reserve, priming out of `build`, submit guards (re-entrancy / zero-owed skip / clamped savings move) |
| `app/lib/features/pocket_money/presentation/widgets/payout_sheet.dart` | `busy` CTA, single sheet-title announcement, grabber on `NestSpacing.gap5`, **row amount inline 13 px bold ink-2**, data-driven `.saverow` copy, `PayoutCheck.grabberHeight` deleted |
| `app/test/features/pocket_money/payout_view_test.dart` | +5 regression tests (`P13 payout — iteration-1 regressions`) |
| `app/test/features/pocket_money/payout_widget_geometry_test.dart` | +2 real-font tests: amount style + row text y (±1), scrim barrier `(0,0,390,844)` |
| `app/test/features/pocket_money/p13_bugs_test.dart` | **all 5 skipped reproducers un-skipped** (`skip: false`, reasons rewritten as "fixed") |

Gates: `flutter analyze lib/features/pocket_money test/features/pocket_money`
→ **No issues found**; `dart format --set-exit-if-changed` → 0 changed;
`flutter test test/features/pocket_money` → **423 passed / 1 pre-existing skip
(P12-BUG-04) / 0 failed** (was 366 + 6 skipped). No simulator, no whole-app
`flutter test`, no `flutter clean`, no `google_fonts`.

## ORCHESTRATOR_NOTES (mandatory — all three)

1. **Scrim covers the whole screen.** `_DimmedLedger` is now a `Stack`: the
   P12 chrome column, then a full-bleed `Positioned.fill` scrim layer
   (`GestureDetector` → `_goBack`) between the ledger and the `.pay` sheet —
   design `components.css:164` (`inset: 0; z-index: 20`) with the sheet's 30
   above it. The status-bar reserve, the "Pocket money" title and the summary
   card all render dimmed, and a tap at `(195, 60)` now dismisses. Measured
   rect `(0, 0, 390, 844)`; the 152–169 px bright band the UI stage measured
   is gone. Pinned by the new geometry test **and** by a view test.
2. **Row amounts are part of the subtitle line.** P13's markup puts
   `<span class="money">` **inside** the `.caption` line
   (`P13-payout.html:25`), so `.money` only adds `tabular-nums` +
   `font-weight: 700` — the page rule `.child .am { font-size: 18px }` is
   never applied by this screen's HTML. The amount is now
   `NestType.money(ink2).copyWith(fontSize: 13, height: 18/13)`: **13 px bold
   tabular `--ink-2`, inline** after `Weekly + quests · ` (U+00B7). Pixel
   proof from `design/screens/light/P13-payout.png` ÷3, row 1: the caption
   glyphs and the amount glyphs are both `(74,70,104)` = `--ink-2`
   (`colors.dart:276`), and the amount's ink is 9.4 px tall — a 13 px cap, not
   an 18 px one. (The old 18 px ink rendering was neither.)
3. **Row text y.** `.who` = name 22 + caption 18 = **40** (was 44), centred in
   the 48 px content box by `.child { align-items: center }`, so the block
   starts 4 px below the padding instead of 2: name line box **458…480**,
   subtitle **480…498** (design ink: name `463.3…477.7`, digits
   `484.3…493.7`). Pinned at **±1 px** for both rows (Leo 544 / 566). This
   also retires the UI stage's "Leo ≈ 2 px high" deviation, which was the
   18 px amount's extra 2 px of line height pushing the block up. Row height
   stays 76 — the 48×48 `.check` drives it, not the text.

## FIXES_1.md — what I fixed

### From 4_review.md (code review, iteration 1)

| # | Sev | Fix |
|---|---|---|
| 1 | major | Scrim is its own `Positioned.fill` layer over the whole ledger (`inset: 0`); the misleading `Expanded` comment and the doc comment that claimed a behaviour the code did not have are both gone. |
| 2 | major | `_submit` is non-reentrant and the sheet's CTA is `loading:` (disabled, DS spinner, label kept so the pill geometry does not move) while a write is in flight. |
| 3 | major | `_submit` skips a ticked child who owes `0` — no `Paid · £0.00` ledger row for money that never moved. Regression test: pay Maya, re-open, tick Maya beside Leo, submit → only `leo:-210` is written. |
| 4 | major | `zz_probe_test.dart` was already deleted by the bug stage; its probes are now real assertions (the double-submit and zero-owed tests above). `flutter analyze` is clean. |
| 5 | minor | `_prime` no longer mutates `State` inside the `BlocBuilder`: it runs in a dedicated `BlocListener` on the first `loaded` emission, plus `initState` for the route-pumped-onto-an-already-loaded-bloc case (deep link / pre-loaded bloc). `build` is pure. |
| 6 | minor | The dimmed chrome is `ExcludeSemantics`-wrapped (plan §e and the code's own comment are now true). |
| 7 | minor | `.saverow` copy is data-driven: verbatim design string while the goal names the Lego set (the seeded `goal-lego`), and a neutral sentence (`Move £1.00 of {nick}'s money to their {goal} fund`) for any other goal, instead of hard-coding "her Lego fund" for an arbitrary family. No SHARED_REQUEST needed — no cross-screen/core change. |
| 8 | minor | `PayoutCheck.grabberHeight` deleted; the pill is `NestSpacing.gap5` like `NestBottomSheet`'s. |
| 9 | minor | The sheet's `Semantics` container keeps `container`/`explicitChildNodes` but drops `label:` (the title was announced twice); the scrim now carries `Semantics(button: true, label: 'Close payout', onTap: onDismiss)` so a screen-reader user can dismiss it (with `onTap:` passed, per the brief's `excludeSemantics` rule). |
| 10 | minor | `_FailureBody` mounts the same `NestStatusBar()` reserve as the other two bodies. |

### From 6_bugs.md (`p13_bugs_test.dart`)

| # | Sev | Fix |
|---|---|---|
| P13-BUG-01 | major | Re-entrancy guard + busy CTA. The guard **re-arms after a failure the parent actually saw** (`_lastFailure`), so a retry can never be met with a dead button. Repro un-skipped: 1 payout row, 1 `savings_move`, goal 1650. |
| P13-BUG-02 | major | `savingsMovePence = min(£1.00, owed)`, and 0 whenever the move is not paid. Repro un-skipped: at 50 p owed the ledger moves ≤ the payout and the goal moves exactly what the ledger moved. |
| P13-BUG-03 | major | Scrim `inset: 0` (see ORCHESTRATOR item 1). Repro un-skipped. |
| P13-BUG-04 | minor | The view records the message it surfaced (`_lastFailure`) and re-arms the submit for a retry. Repro un-skipped and green (stable over 3 runs). Root cause is logic-side and the logic builder closed it in the same iteration — the bloc now clears the stale `errorMessage` before the write, so the repeat failure is a state change again; my `_lastFailure` re-arm is the view-side belt to that braces, and it also covers the case where the emission is suppressed. |
| P13-BUG-05 | minor | `ExcludeSemantics` on the dimmed chrome (see finding 6). Repro un-skipped. |

### From 5_ui.md

Deviation 1 = BUG-03 (fixed). Deviation 2 (Leo ≈ 2 px high) = ORCHESTRATOR
item 3 (fixed and pinned at ±1).

### From 3_test.md

`SHARED_REQUEST.md` (`pumpAppRoute` has no `size` parameter) needs no action
from me — it is `test/test_scope.dart`, outside the UI chunk's paths, and the
request itself says it blocks nothing (P13's 320/390/430 and 320×568 probes
pump `NestlingApp` directly and are real). The `HARNESS TRAP` comments stand.

## Owner rules re-checked

- **Bottom edge** — unchanged mechanism (bottom-anchored sheet, `paper`,
  `homeH + s4` bottom pad, `sheet.bottom == 844.0`), re-verified by
  `payout_responsive_test.dart`'s rendered-pixel probe in both themes.
- **Alignment** — 20 px gutters on the title, both rows, the saverow, the CTA
  and the check column; pinned by rect assertions (unchanged, all green).
- **Child order** — creation order everywhere; unchanged.
- **Copy** — every string re-compared with `P13-payout.html`: ASCII 0x27 in
  `you've` / `Maya's`, U+00B7, `&`, U+2014 in the toast. The new saverow
  fallback is the only string this screen ever builds itself, and it is
  clearly documented at the call site.
- **Tokens only** — the sheet's grabber is now on `NestSpacing`; no literal
  colour or size was added. The amount's 13/18 is the `.caption` metric read
  through `NestType.money(...).copyWith` at the call site (the shared styles
  stay untouched, per the letter-spacing/spacing precedent).
- **DS not re-implemented** — `NestStatusBar`, `NestCard`, `NestButton`
  (`loading:`), `NestToggle`, `NestAvatar`, `NestIcon`, `NestEmptyState`,
  `NestToast` all shared. `PayoutCheck` stays feature-local (48×48/r14/2 px
  has no DS equivalent).
- **Accessibility** — every control still exposes `hasAction(tap)`; both
  `excludeSemantics: true` wrappers pass `onTap:`; the new scrim node does too;
  the new regression test asserts the scrim's `hasAction(tap)` and that the
  dimmed title/summary are gone from the semantics tree.
- **No `google_fonts`**, no Material tracking, no analysis_options changes.

## Contract with the logic builder

Re-read `2a_build_logic.md` after their edits landed: **no CONTRACT CHANGES**
(`PocketMoneyPayoutSubmitted` shape unchanged; their hardening is a per-child
in-flight set in the bloc, a clear-before-write on the error path, and
`amount > 0` / `move ≤ paid` in `recordPayout`). My view-side guards are
complementary, not contradictory: the bloc drops duplicate events and the
repository refuses a non-positive payout, the view never sends one and never
re-enters. The full feature suite (423 tests) passes with both layers in
place.

## LEFT FOR NEXT ITERATION

- `shot.sh` light + dark and `compare.py` — stage 5's job (this stage must not
  touch a simulator). The scrim, the amount metrics and the row text y are
  pinned numerically here, so 5_ui should confirm rather than hunt.
- `_EmptyBody` copy (`No payouts yet` / `Add a child`) still has no design PNG
  to check against; unchanged from iteration 1.
- Nothing in plan §a, §c, §d, §e or §f is outstanding for the UI chunk.

VERDICT: PASS