# 2 — INTEGRATE (iteration 2) — P13 Payout

Loop stage: combine the two parallel builder halves (`2a_build_logic.md` +
`2b_build_ui.md`) after the iteration-1 QA sweep, then re-run the gates.
Scope: **compile + green suite**. No redesign, no simulator (rule: only
`5_ui` may drive `BC440E48-B3A3-43BC-971B-0EF5DB621874`).

`docs/screens/P13/ORCHESTRATOR_NOTES.md` now exists (added 19:48, after the
builders started). **All three of its items are mandatory** and I verified each
one against the merged tree, not just against the builders' notes — see
"ORCHESTRATOR_NOTES verification" below.

## Headline

Again **zero integration breakages**, and again **I changed no source file**.
`2a` and `2b` both report `CONTRACT CHANGES: None`, and their work is
complementary rather than overlapping: the bloc drops a duplicate in-flight
event and the repository refuses a non-positive payout, while the view never
sends one and never re-enters. Nothing needed renaming, re-importing or
patching.

```
dart format .                                        → Formatted 491 files (0 changed)  exit 0
flutter analyze                                      → No issues found! (ran in 4.2s)   exit 0
flutter test                                         → 02:14 +2499 ~1: All tests passed! exit 0
flutter test test/features/pocket_money             → 00:17 +423  ~1: All tests passed! exit 0
```

Iteration 1 was `+2165 ~1`; iteration 2 is `+2499 ~1` — **+334 tests, same
single pre-existing skip, zero failures.**

## Summary of 2a (logic)

- `pocket_money_bloc.dart` — `_onPayoutSubmitted` gains a per-child
  `_payoutInFlight` re-entrancy guard (the synchronous `Set.add` runs in event
  order, so a duplicate is dropped *before* its write while a ticked sibling
  still proceeds; the entry is removed in `finally` so a retry stays
  reachable), plus a clear-before-write so a repeated identical failure is a
  state change again and the view's toast returns.
- `pocket_money_repository_impl.dart` — `recordPayout` is now a **no-op when
  `amountPence <= 0`** (no `Paid · £0.00` rows) and clamps
  `savingsMovePence` to `min(move, amount)` with the goal bumped by the
  clamped value.
- `payout_bloc_test.dart` (+3) and `payout_repository_test.dart` (+2).
- No change to the `PocketMoneyPayoutSubmitted` shape or `recordPayout`'s
  signature.

## Summary of 2b (UI)

- `payout_view.dart` — `_DimmedLedger` is now a `Stack` with a full-bleed
  `Positioned.fill` scrim layer between the chrome column and the sheet;
  chrome `ExcludeSemantics`; `_prime` moved out of `build` into a dedicated
  listener + `initState`; `_submit` gains the re-entrancy / zero-owed-skip /
  clamped-savings-move guards; `_FailureBody` gains the `NestStatusBar()`
  reserve.
- `payout_sheet.dart` — `busy` CTA, single title announcement, grabber on
  `NestSpacing.gap5`, **row amount inline 13 px bold `--ink-2`**, data-driven
  `.saverow` copy, `PayoutCheck.grabberHeight` deleted.
- `payout_view_test.dart` (+5 regression tests),
  `payout_widget_geometry_test.dart` (+2 real-font tests),
  `p13_bugs_test.dart` — **all 5 skipped reproducers un-skipped**
  (`skip: false`, reasons rewritten as "fixed").

## FIXES items

### Done (by the two builders; verified by me)

Every item in `FIXES_1.md` is accounted for. I walked the list against the
merged tree:

| Source | Item | Where it landed | Verified |
|---|---|---|---|
| `3_test.md` T-1 | `payout_states_test.dart` hung 10 min/test (awaiting a never-completing Drift stream on `bloc.close()`) | test pumps the real `/payout` route over a GetIt-scripted repository instead of hand-building the bloc | file runs; `flutter test` exit 0 |
| `3_test.md` T-2 | 8 analyzer issues + 1 unformatted file in the test stage's own files | `data!` promotion fix, comment rewording, dropped redundant `async` | `dart format` 0 changed, `analyze` No issues found |
| `4_review` #1 / P13-BUG-03 | scrim not `inset: 0` | `Positioned.fill` scrim layer in `_DimmedLedger` | geometry test asserts `Rect(0,0,390,844)` |
| `4_review` #2 / P13-BUG-01 | double-tap double-write | view `_submit` guard + `busy` CTA **and** bloc `_payoutInFlight` | repro un-skipped and green |
| `4_review` #3 | ticked child owing £0 writes `Paid £0.00` | view skips `owed == 0` **and** repo no-ops `amountPence <= 0` | repro un-skipped and green |
| `4_review` #4 | leftover `zz_probe_test.dart` scratch file breaking analyze | deleted in iteration 1; probes became real assertions | `find … zz_*` → none |
| `4_review` #5 | `_prime` mutates State during build | dedicated `BlocListener` + `initState`; `build` is pure | analyze clean |
| `4_review` #6 / P13-BUG-05 | dimmed chrome not `ExcludeSemantics` | `ExcludeSemantics` around the chrome column | repro un-skipped and green |
| `4_review` #7 | saverow hard-codes a gendered, goal-specific noun | `PayoutSaveRow.label()` — verbatim design string for the seeded `goal-lego`, neutral data-driven sentence otherwise | — |
| `4_review` #8 | grabber height duplicated on the wrong class | `NestSpacing.gap5`; `PayoutCheck.grabberHeight` deleted | — |
| `4_review` #9 | sheet title announced twice; scrim not dismissible from the semantics tree | container `label:` dropped; scrim gets `Semantics(button: true, label: 'Close payout', onTap: onDismiss)` | — |
| `4_review` #10 | `_FailureBody` skips the status-bar reserve | `NestStatusBar()` added | — |
| `5_ui` | deviation 1 (scrim) and deviation 2 (Leo ≈ 2 px high) | = BUG-03 and ORCHESTRATOR item 3 | pinned at ±1 px |
| `P13-BUG-02` | £1.00 move not clamped to the payout | view `min(£1.00, owed)` **and** repo clamp | repro un-skipped and green |
| `P13-BUG-04` | repeated identical write failure gives no feedback | bloc clear-before-write + view `_lastFailure` re-arm | repro un-skipped, green over 3 runs |

**Skips retired.** `grep -rn "skip: true" app/test` now matches exactly one
file, `p12_bugs_test.dart:320` — pre-existing P12, not this screen. All five
P13 reproducers carry `skip: false` and run as real assertions.

### Left (deliberately — not integration defects)

| # | Item | Why left | Owner |
|---|---|---|---|
| 1 | **`SHARED_REQUEST.md`** — `test/test_scope.dart::pumpAppRoute` hard-codes `physicalSize = 390×844`, silently overwriting any size a test set before calling it, so two `payout_view_test.dart` cases (`320 px at text scale 1.3 overflows nothing`, `a short screen scrolls the sheet instead of overflowing`) pass while running at 390. | `app/test/test_scope.dart` is **shared** and outside RULES §1 — I may not edit it. The request itself says `Blocks: no`, and the real 320/390/430 and 320×568 probes in `payout_responsive_test.dart` / `p13_bugs_test.dart` pump `NestlingApp` directly and are genuine. Both trapped tests carry a `HARNESS TRAP` comment. | orchestrator (`shared/`) |
| 2 | **`shot.sh` light + dark + `compare.py`.** | Stage rule: this stage must not touch a simulator. The scrim barrier, the amount metrics and the row text y are all pinned numerically by real-font widget tests, so `5_ui` should confirm rather than hunt. | 5_ui |
| 3 | **`_EmptyBody` copy** (`No payouts yet`, `Add a child`) still has no design PNG to check against. | No design source exists for it; unchanged since iteration 1. | 4_review / 5_ui |

## ORCHESTRATOR_NOTES verification (all three mandatory items)

Checked against the merged tree, not just the builders' claims:

1. **Scrim covers the whole screen.** `_DimmedLedger` is a `Stack`: the chrome
   column, then `Positioned.fill` → `Semantics(button: true, label: 'Close
   payout', onTap: onDismiss)` → `GestureDetector` → `ColoredBox(tokens.scrim)`,
   with the sheet `Align`ed on top. Matches `P13-payout.html:21` /
   `components.css:164` (`inset: 0; z-index: 20` under the sheet's 30).
   `payout_widget_geometry_test.dart` finds that `ColoredBox` by its scrim
   token colour and asserts `Rect.fromLTRB(0, 0, 390, 844)`. **Done.**
2. **Amounts inline at the subtitle's size.** P13's markup puts
   `<span class="money">` *inside* the `.caption` line
   (`P13-payout.html:25`), and `components.css:155` shows `.money` adds only
   `tabular-nums` + `font-weight: 700` — the page rule `.child .am { font-size:
   18px }` is never applied by this screen's HTML. The code now uses
   `NestType.money(tokens.ink2).copyWith(fontSize: 13, height: 18 / 13)`, and
   `NestType.money` is already `w700` + tabular, matching the CSS exactly. The
   geometry test asserts `fontSize == 13`, `w700`, `color == ink2`, tabular
   features present, and `toPlainText() == 'Weekly + quests · £4.20'` (i.e.
   one inline line, U+00B7 preserved). **Done.**
3. **Row text y within ±1.** `.who` = name 22 + caption 18 = **40**, centred in
   the 48 px content box by `.child { align-items: center }` → row 1 name
   458…480, subtitle 480…498; row 2 (Leo) 544 / 566. The geometry test asserts
   `name.top ≈ 458 (±1)`, `height ≈ 22`, `subtitle.top ≈ 480 (±1)`,
   `height ≈ 18`, plus `leoName.top ≈ 544` and `leoSubtitle.top ≈ 566`.
   **Done.**

## Integration checks I ran (beyond the three graded commands)

- **Format/analyze/test**: as above, all green, twice.
- **Feature suite**: `flutter test test/features/pocket_money` → `00:17 +423
  ~1: All tests passed!` — matching `2b`'s number exactly. All five new/
  changed P13 files run: `p13_bugs_test`, `payout_bloc_test`,
  `payout_repository_test`, `payout_view_test`,
  `payout_widget_geometry_test` (plus `payout_responsive_test`,
  `payout_states_test` from the test stage, and the four P12 files).
- **Scope (RULES §1)**: `git status --porcelain` outside
  `docs/screens/P13/`, `app/lib/features/pocket_money/` and
  `app/test/features/pocket_money/` is **empty**. Nothing in `app/lib/core/**`,
  `app/lib/app/**`, another feature or `tools/screens/**` was touched.
  `analysis_options.yaml` is byte-identical (no `git diff`).
- **No skips used to reach green**: the single `~1` is `p12_bugs_test.dart:320`
  (pre-existing P12). Nothing new was skipped, ignored or `@`-disabled.
- **No `flutter clean`, no `flutter run`, no simulator** booted, installed on or
  screenshotted at any point in this stage.

### Orchestrator-rule spot-checks on the merged tree

- **FONTS** — `google_fonts|GoogleFonts` in `lib/features/pocket_money` +
  `test/features/pocket_money`: **no hits**.
- **LETTER SPACING** — `git diff lib/features/pocket_money | grep
  letterSpacing`: **no hits**. P13 adds no tracking (the only `letterSpacing`
  in the feature is P12's own documented `-0.4`, untouched).
- **CHILD ORDER** — the child rows and the `.saverow` child both iterate
  `data.children` (creation order). Still pinned by a test.
- **COPY** — unchanged from iteration 1 on the seeded path. The only string
  this screen builds itself is the new `.saverow` fallback, and it is
  deliberately *not* taken on the seeded `goal-lego` path, so the rendered
  design string stays character-for-character: ASCII `0x27` in `you've` /
  `Maya's`, U+00B7, `&`, U+2014 EM DASH in the toast.
- **BOTTOM EDGE (owner)** — mechanism unchanged: bottom-anchored sheet,
  `tokens.paper`, `homeH + s4` = 50 px bottom pad, so paper owns the last pixel
  row in both themes. Re-verified by `payout_responsive_test.dart`'s
  rendered-pixel probe (green).
- **ALIGNMENT (owner)** — 20 px gutters on the title, both rows, the saverow and
  the CTA, all pinned by `Rect.fromLTRB(20, …, 370, …)` assertions (green).
- **BALANCED HEADINGS** — correctly still absent: `P13-payout.html:5`
  (`.pay h2`) sets no `text-wrap: balance`, and the rule forbids
  `NestBalancedText` on `.h2`. The `.ptitle` behind the scrim is a separate
  CSS class from `.h1` with single-line copy, matching sibling P12.
- **ACCESSIBILITY ACTIONS** — every control still exposes
  `hasAction(SemanticsAction.tap)`. Both `excludeSemantics: true` wrappers
  (`PayoutCheck`, the scrim) pass `onTap:`; the new scrim node does too, and a
  new regression test asserts its tap action and that the dimmed title/summary
  are gone from the semantics tree.
- **TRIAL / PERIODS / PIP / NestChipWrap** — untouched by P13: no
  `subscription_status` write, no quest-period logic, no Pip on this screen, no
  `NestChip` row.

## Left for the next stages

- `5_ui`: `shot.sh` light + dark on `BC440E48-B3A3-43BC-971B-0EF5DB621874` +
  `compare.py`; report the measured y of the screen title, the first control
  and each card top, design vs app (UI-verdict rule ±2 px; a uniform vertical
  shift is a FAIL). It should now confirm the three orchestrator targets
  rather than hunt.
- `shared/`: the `SHARED_REQUEST.md` harness fix for `pumpAppRoute`.

VERDICT: PASS
