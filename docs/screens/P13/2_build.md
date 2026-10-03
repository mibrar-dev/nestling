# 2 — INTEGRATE (iteration 4) — P13 Payout

Loop stage: combine the two parallel builder halves (`2a_build_logic.md` +
`2b_build_ui.md`) and run the three gates. Scope: **compile + green suite**.

## VERDICT: FAIL — analyze clean, P13 green, but the whole-repo gate has 35 failures

```
dart format .                             → Formatted 494 files (0 changed)   exit 0
flutter analyze                           → No issues found! (ran in 8.3s)    exit 0
flutter test                              → 01:54 +2522 ~1 -35: Some tests failed.  exit 1
flutter test test/features/pocket_money   → 00:29 +461 ~1: All tests passed!    exit 0
```

`dart format` and `flutter analyze` are clean. **P13's own 461-test suite
passes with zero failures.** But the full suite has **35 failures**, and
`ORCHESTRATOR_NOTES.md`'s 23:55 exemption does **not** cover this situation:

> `test/core/family_time_test.dart` › 'kid_home completions are stamped with
> the family zone' fails since the date rolled to 4 Oct. … **If it is the ONLY
> failing test in the full suite, treat the gate as green for this screen.**

It is **not** the only failing test — there are 35. I am not going to widen an
exemption that was explicitly conditioned on "ONLY", especially when the 34
extra failures appeared *after* that note was written and the orchestrator had
carved out that exact case by writing "only". The stage rule stands: *"VERDICT:
PASS only if analyze is clean and the full suite passes."*

I did not skip a test, add an ignore, or weaken `analysis_options` to reach a
green run. Details and the one-line unblock below.

## The 35 failures: same root cause, zero of them P13

Stable across two consecutive full runs (identical count and distribution), so
this is not flake. All are **date-rollover casualties on `main`**, and none is
in `pocket_money`:

| File | Failures | Symptom |
|---|---|---|
| `features/kid_home/kid_home_view_test.dart` | 20 | `Expected "4 of 6 done", Found 0 widgets` — the *done today* count |
| `features/kid_home/k03_bugs_test.dart` | 8 | completing a quest finds `0` in-period completions, expected 1 |
| `features/approvals/approvals_view_states_test.dart` | 3 | seeded pending-approval semantics labels not found |
| `features/today/p08_bugs_test.dart` | 2 | P08-B11 "a daily completion from the previous London day is to do" → got `approved` |
| `features/approvals/approvals_view_test.dart` | 1 | copy test |
| `core/family_time_test.dart` | 1 | `Bad state: Too many elements` (`List.single`) |

The mechanism is the one `ORCHESTRATOR_NOTES` 23:55 already named. Tests are
pinned to **Sat 3 Oct 2026** (`test/flutter_test_config.dart`) while the real
clock is now **Sun 4 Oct 00:10 BST / 03 Oct 23:10 UTC**. Every seeded completion
is stamped Oct 3, so it is no longer inside the *current* London day and the
period rule (the orchestrator's own PERIODS ruling) correctly reclassifies it.
`family_time_test` shows the rollover advancing even inside its own body: it now
fails at **line 313** (`rows.single` after Maya/`q-reading`, previously passing)
rather than line 319 as it did yesterday — the same test, one assertion earlier,
because London has rolled too.

**None of it can be P13.** My only `lib` change this iteration is
`presentation/widgets/payout_sheet.dart`. All six failing test files import
**zero** `pocket_money/presentation` symbols (verified by grep), and the whole
diff is confined to `app/lib/features/pocket_money/` +
`app/test/features/pocket_money/` (RULES §1 clean).

**What unblocks it** — for the orchestrator. `SHARED_REQUEST.md` #2 is already
open and `shared/family_time_test_fix` is already in flight; it now needs to
cover the **whole date-rollover set**, not just `family_time_test`. The durable
fix is the one already listed third in that request: make the period logic read
the same pinned clock the seed uses, so no screen's suite breaks at midnight.
Until then every screen loop is red for the same reason.

Re-issuing the exemption as **"if every failing test is a date-rollover casualty
outside `pocket_money`"** would make this screen green immediately, and on the
evidence above that would be correct. I am flagging rather than assuming, because
the written condition is false.

## Summary of 2a (logic)

**No files changed** — and none could be. `CONTRACT CHANGES: None`. `2a` walks
`FIXES_3` and confirms nothing in it is logic-layer: the `recordPayout` guards
(BUG-02/review #3) and the submit guards (BUG-01/04/05) are untouched since
iteration 2 and re-verified by grep; the saverow copy gate is a widgets file;
the gate failure is shared `core`; no P13 skips remain. Its 13 owned tests and
101 neighbour-logic tests pass.

## Summary of 2b (UI)

One P13 change this iteration, and it implements the orchestrator's 23:25
mandate in full:

| File | Change |
|---|---|
| `payout_sheet.dart` | `PayoutSaveRow.label` rewritten: the `childId == 'maya'` seed-id gate is **deleted, not relocated**. One ungendered sentence for every goal-bearing child — `"Move $amount of $name's to their $goalTitle fund"` — and `"Move $amount of $name's money to savings"` when there is no goal. The `childId` parameter is gone, so `label()` cannot see a seed id at all. |
| `payout_view_test.dart`, `payout_responsive_test.dart`, `payout_widget_geometry_test.dart` | copy constants updated to the mandated sentence. |
| `p13_bugs_test.dart`, `p13_iter2_audit_test.dart`, `p13_iter3_audit_test.dart` | expectations updated; the audit group A is now the **ungendered matrix** — every shape yields the mandated sentence and **zero** shapes may produce `" her "` (was "exactly one may"); group B pins the mandated seeded copy and asserts the design's `" her "` string appears nowhere at runtime. |

### ORCHESTRATOR_NOTES verification (all items mandatory)

**23:25 pronoun / no seed ids — DONE, verified in the tree.** `grep` over
`lib/features/pocket_money/presentation/` finds no `'maya'`, `'leo'`,
`'goal-lego'` or `'Lego Friends set'` branch — the only match left is a doc
comment. `her Lego` survives only as documentation and in test *assertions that
it is absent*. The seeded row now renders `Move £1.00 of Maya's to their Lego
Friends set fund`; a goal-bearing Leo renders `Move £1.00 of Leo's to their Lego
City fund`. Row geometry kept: the saverow card stays `(20, 612, 370, 684)` and
the toggle track 51×31 at `(305, 633)`, both still pinned and green; the longer
sentence wraps to two lines like the design.

**19:48 items 1–3 (scrim `inset: 0`, inline 13 px amounts, row text y ±1)** —
still landed and still green from iteration 2; no regression.

**23:55 gate exemption** — see above: condition not met (35 failures, not 1).

## FIXES items

### Done

| Source | Item | Where | Verified |
|---|---|---|---|
| ORCH 23:25 | `childId == 'maya' && title == 'Lego Friends set'` gate must go; one ungendered data-driven sentence | `PayoutSaveRow.label` | no seed id in product code; mandated sentence at every shape |
| ORCH 23:25 | update the copy tests — the design's "her Lego fund" is NOT a finding | 6 pocket_money test files | suite green; audit asserts ` her ` appears in **no** shape |
| ORCH 23:25 | keep the row geometry (toggle track at the design rect) | untouched | `(20,612,370,684)` + `(305,633)` pins still green |
| FIXES_3 | `recordPayout` guards (BUG-02, review #3) | already correct since iteration 2 | re-verified live (amount 0 / negative / clamp / `goalId == null`) |
| FIXES_3 | submit guards (BUG-01/04/05) | untouched | `_payoutInFlight` + `finally` + clear-before-write intact; audit passes |
| FIXES_3 | no P13 skips left | — | `grep "skip: true"` over P13 bug/audit files is empty |

**Skips tree-wide:** `grep -rn "skip: true" app/test/` matches exactly one file,
`p12_bugs_test.dart:320` — pre-existing P12. Nothing was skipped or ignored by me.

### Left

| # | Item | Why left | Owner |
|---|---|---|---|
| 1 | **The 35 date-rollover failures (the gate).** | Shared `core` + other features' tests, all outside RULES §1. The orchestrator's exemption is conditioned on "the ONLY failing test"; that condition is false. | orchestrator — widen the exemption to the date-rollover set, or land `shared/family_time_test_fix` for all 35 |
| 2 | **SHARED_REQUEST #1** — `pumpAppRoute` hard-codes `physicalSize = 390×844`, overwriting any size a test sets first, so two `payout_view_test.dart` cases pass while running at 390. | `app/test/test_scope.dart` is shared. Non-blocking; the real 320/430/320×568 probes pump `NestlingApp` directly. | orchestrator `shared/` |
| 3 | **Design PNG / HTML still say `… to her Lego fund`.** The app intentionally differs there by mandate. | Copy is a design artefact I may not edit (`design/` is outside RULES §1). | design pass — worth doing so the `compare.py` diff returns to zero |
| 4 | `shot.sh` + `compare.py` for this iteration. | Stage rule: no simulator here. | 5_ui — it should **not** fail the mandated copy diff |

## Integration checks I ran (beyond the three graded commands)

- **Format/analyze**: clean; `dart format --set-exit-if-changed` → 0 changed.
- **P13 suite green**: `00:29 +461 ~1: All tests passed!`, matching `2b`.
- **Whole-repo gate run twice**: identical result both times (`+2522 ~1 -35`),
  so the report above is stable rather than a flake.
- **No P13 code on any failing path**: my only `lib` change is
  `payout_sheet.dart`; all six failing test files import zero
  `pocket_money/presentation` symbols.
- **Scope (RULES §1)**: `git status --porcelain` outside
  `docs/screens/P13/`, `app/lib/features/pocket_money/` and
  `app/test/features/pocket_money/` is **empty**; `analysis_options.yaml`
  byte-identical. No `flutter clean`, no `flutter run`, no simulator booted,
  installed on or screenshotted.
- **Contract between the halves**: `2a` reports no contract changes and changed
  nothing; `2b` coded against the same BLoC / `MoneyLedgerData` / `MoneyChild`
  shapes as iteration 3. **No mismatched states/events, no renamed members, no
  import breakages** — nothing to fix. I made **no code edit** this iteration.

### Orchestrator-rule spot-checks on the merged tree

- **FONTS** — no `google_fonts` / `GoogleFonts` in the feature's lib or tests.
- **LETTER SPACING** — none added; the only `letterSpacing` in the feature is
  P12's documented `-0.4`.
- **CHILD ORDER** — untouched; rows and the saverow still iterate
  `data.children` (creation order).
- **COPY** — the saverow's only runtime wording is the mandated sentence at
  every shape; `£1.00` remains design-fixed; ASCII `0x27` apostrophes
  throughout. The intentional divergence from the PNG is documented above.
- **DATA OVER MOCKS** — `$goalTitle` is interpolated straight from the database
  row; any fixture title renders that title.
- **BOTTOM EDGE / ALIGNMENT / ACCESSIBILITY / BALANCED HEADINGS / CHIP ROWS /
  TRIAL / PERIODS / PIP** — untouched by this iteration and still green.
- **SKIPS** — one pre-existing P12 skip only; no new `skip:` or `@ignore`.

## Left for the next stages

- **orchestrator**: the gate. Either widen the 23:55 exemption to "all
  date-rollover casualties outside `pocket_money`", or land
  `shared/family_time_test_fix` across all 35. P13 itself is complete and green
  and needs nothing further.
- `5_ui`: `shot.sh` light + dark + `compare.py` with the ±2 px position table;
  it should **pass** and must not fail the mandated `their Lego Friends set`
  copy as a design mismatch.

VERDICT: FAIL
