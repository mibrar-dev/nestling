# 3 — TEST (iteration 4) — P13 · Payout (parent)

Route `/payout`, feature `pocket_money`, build `ad85ec5`. In-memory Drift via
`test_scope.setUpTestScope` + `Seed.demo()`. **No simulator was booted,
installed on, screenshot or driven** (stage rule — only `5_ui` may).

Iteration 4 opens with a change I have to flag immediately: **the date rolled
over to Sun 4 Oct 2026 during this loop**, and the suite's seed is pinned to
Sat 3 Oct by `test/flutter_test_config.dart`. That has broken 35 tests across
five features. None of them is P13. Details below, because they drive the
verdict.

## Headline

```
dart format --output=none --set-exit-if-changed .  → Formatted 494 files (0 changed)   exit 0
flutter analyze                                     → No issues found! (3.0s)         exit 0
flutter test test/features/pocket_money             → +461 ~1: All other tests passed!  exit 0  (×3 runs)
flutter test                                        → +2522 ~1 -35: Some tests failed!  exit 1  (×3 runs, identical)
```

- **P13 is green and stable.** 461 passed, 1 skipped, 0 failed, reproduced over
  three consecutive runs of the feature directory and four of the whole repo.
- **The only skip in `app/test` is `p12_bugs_test.dart:320`**, pre-existing P12.
  No P13 finding reproducer is skipped.
- **The whole-repo gate has 35 failures**, zero in `pocket_money`. I verified
  each distribution myself rather than taking `2_build.md`'s table.

## VERDICT: FAIL

Because `flutter test` does not pass. I did not skip anything, add an ignore,
weaken `analysis_options`, or widen the orchestrator's exemption — see *The 23:55
exemption* for why that exemption does not apply and why I agree with the build
stage that it must not be stretched.

---

## ORCHESTRATOR_NOTES — both new updates are mandatory; both satisfied

### 23:25 — PRONOUN / NO SEED IDS IN PRODUCT CODE

> Remove the `childId == 'maya' && title == 'Lego Friends set'` special case.
> Product code must never branch on seed ids. Use ONE data-driven, ungendered
> sentence… Update the copy tests: the design's "her Lego fund" is NOT a
> finding.

| Requirement | Verified |
|---|---|
| Special case removed | `PayoutSaveRow.label(String name, String? goalTitle)` (`payout_sheet.dart:423`) no longer takes a `childId` **at all** — the branch is gone, not merely widened |
| One ungendered sentence | `"Move $amount of $name's to their $title fund"`; a missing/whitespace title reads `"Move $amount of $name's money to savings"` (`:427`, `:429`) |
| No seed ids in product code | `grep -rnE "'maya'|'leo'|'goal-lego'|Lego" lib/features/pocket_money/` → **no code hits**, only doc-comments describing the seed. (One real exception is recorded below, pre-existing and outside this ruling.) |
| Copy tests updated | All five expectations migrated to the new sentence: `payout_view_test.dart:41`, `payout_responsive_test.dart:48`, `payout_widget_geometry_test.dart:164`, `p13_iter2_audit_test.dart:266`, `p13_iter3_audit_test.dart:44`. No test asserts `her Lego fund` any more |
| Row geometry kept | `payout_widget_geometry_test.dart:159` still pins the saverow to `designSaveRow = Rect.fromLTRB(20, 612, 370, 684)` — the design's 72 px card — **with the longer copy in place**, and `:190-192` pins the toggle track to `left ≈ 305`, `top ≈ 633`. The label wraps to two lines (14 + 44 + 14 = 72), which is why the design row height still holds exactly |

This closes out the concern I raised in iteration 3 ("a demo-seed identity in
product copy logic"). The orchestrator ruled, the code follows the ruling, and
the design-path copy now diverges from the PNG deliberately — as instructed.

### 23:55 — known red test on main

`family_time_test.dart` is being fixed by `shared/family_time_test_fix`. It is
still failing, but it is now **1 of 35**, so see below.

### Still satisfied from 19:48 — items 1, 2, 3

Scrim `Rect.fromLTRB(0, 0, 390, 844)`, inline 13 px `w700`/`ink2`/tabular
amounts, and row text y within ±1 (458/480/544/566) — all still pinned with
`FontLoader` fonts, light and dark, and all green.

## Tests added / changed this stage

I found **one real defect while verifying, and it was in my own test file**, not
in the screen.

### `p13_bugs_test.dart` — a load-dependent flaky test (fixed)

**Symptom.** During the first whole-repo run of this stage, `p13_bugs_test.dart`
— `P13-BUG-01: a second tap while the payout write is in flight double-writes
the payout, the savings move and the goal bump` — failed, giving **36** failures
where the build stage had measured 35. It then:

- passed in isolation (`--plain-name P13-BUG-01`, and 6 consecutive runs of the
  whole file),
- passed in three consecutive runs of the feature directory,
- passed in three further whole-repo runs.

So: intermittent, load-dependent, ~1 run in 4, and **never reproducible on a
quiet machine**. A green suite that is only green sometimes is a real problem,
so I fixed it rather than shrugging.

**Root cause.** `_pumpPastWrite` pumped a **fixed budget of fake time** (8 ×
120 ms) and then the test read the database:

```dart
Future<void> _pumpPastWrite(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) await tester.pump(const Duration(milliseconds: 120));
  await _settle(tester);
}
...
await _pumpPastWrite(tester);
final written = _newRows(await db.select(db.ledgerEntries).get(), seeded);
expect(written.where((r) => r.type == 'payout').length, 1);
```

`tester.pump(Duration)` advances the **fake** clock. The Drift write and the
`watchLedgerData` re-emission are **real** async work. A fixed fake-time budget
is therefore not a synchronisation point: on a loaded machine the row lands
after the budget, `written` comes back empty, and the assertion fails. The
screen was never involved — the guard it is testing behaved correctly every time.

**Fix.** `_pumpPastWrite` now takes the database and the pre-existing row ids
and **polls the ledger** until a new row appears (bounded at 60 × 50 ms),
instead of guessing a duration. `recordPayout` writes the payout, the savings
move and the goal bump in **one transaction**, so the first new row is a sound
barrier for all three. Nine call sites that read rows now pass `db`/`seeded`;
the single navigation-only call site (`:820`, asserts `currentPath`) keeps the
frame budget, since it reads nothing.

**Result.** Three consecutive whole-repo runs at exactly **35** failures with
`pocket_money` clean in all of them. Honest caveat: the machine was much quieter
during those runs than during the original failure, so 3 clean runs is weaker
evidence than I would like. The fix removes the *mechanism* rather than hoping
for quiet CPU, which is why I trust it; a loaded re-run would confirm it
outright.

The identical fixed-pump pattern exists in `payout_view_test.dart`,
`p13_iter2_audit_test.dart`, `money_ledger_view_test.dart`, `money_ledger_states_test.dart`
and `p12_bugs_test.dart`. None of those has flaked, but they share the design
flaw and are worth the same treatment.

### No new test file this iteration

The mandatory copy migration removed the need for the iteration-3 gate matrix;
my `p13_iter3_audit_test.dart` group A now pins the *new* single-sentence
behaviour, which is the correct thing to assert. Adding more tests for their own
sake this late would be noise.

## The 35 failures — all date-rollover, none P13

Distribution, from my own run (`+2521 ~1 -36` first, then 35 four times):

| File | Failures |
|---|---|
| `features/kid_home/kid_home_view_test.dart` | 20 |
| `features/kid_home/k03_bugs_test.dart` | 8 |
| `features/approvals/approvals_view_states_test.dart` | 3 |
| `features/today/p08_bugs_test.dart` | 2 |
| `features/approvals/approvals_view_test.dart` | 1 |
| `core/family_time_test.dart` | 1 |
| **`features/pocket_money/*`** | **0** |

I verified the mechanism myself rather than accepting the build's explanation.
`test/flutter_test_config.dart:9` pins the suite:

```dart
Seed.anchorOverride = DateTime.utc(2026, 10, 3);
```

so every seeded completion is stamped 3 Oct, while `countsForCurrentPeriod` —
the orchestrator's own mandatory PERIODS ruling — evaluates against the real
`DateTime.now()`. Measured this stage: `UTC 2026-10-03 23:22`, `London
2026-10-04 00:22`. Running `p08_bugs_test.dart` shows the smoking gun — its own
assertion message reads *"yesterday's daily completion is outside **today's**
London day"* and it gets `approved` instead of `to_do`. The fixture is relative
to the real clock; the seed anchor is a fixed date. They cannot both hold.

This is **SHARED_REQUEST #3**, which supersedes my earlier #2. #2 was written in
iteration 2 about a single test failing after 20:00 UTC (the Dubai rollover) —
that was the same defect seen through a narrower window. It now affects 35 tests
across five features, **recurs every midnight**, and will do so again in every
timezone whose day differs from UTC at run time. The durable fix is to inject the
clock (pass `now` into `countsForCurrentPeriod` and have the test config supply
`Seed.anchorDay`) or to derive the pin from the anchor instead of hard-coding a
calendar date. Bumping the date is not a fix; it needs a human every night.

All six failing files are outside RULES §1. P13 writes only `ledgerEntries`
(`payout`, `savings_move`) and the savings-goal bump.

## The 23:55 exemption

`ORCHESTRATOR_NOTES.md` (23:55):

> … If it is the **ONLY** failing test in the full suite, treat the gate as green
> for this screen.

It is not the only failing test — there are 35, and they appeared *after* that
note was written, and the note's author had deliberately written "only". I have
**not** treated the gate as green. The `2_build.md` stage reached the same
conclusion and I agree with it: an exemption conditioned on "ONLY" is not
satisfied by "only one of these is the one you already knew about". Widening it
would be exactly the kind of quiet gate-softening this loop exists to prevent.

## One observation, recorded not patched

`lib/features/pocket_money/data/pocket_money_repository_impl.dart:30`:

```dart
final childId = state?.activeChildId ?? 'maya';
```

`appState.activeChildId` is nullable (`app_database.dart:288`). When it is null,
`watchItems()` silently attributes the whole money history to the seeded child
`'maya'` instead of surfacing the problem — in a real family that would read as
an empty or wrong ledger rather than an error.

**It is not a P13 finding and I did not patch it**, for three reasons: it is
pre-existing foundation code (introduced in `3edace2`, untouched by every P13
iteration); it is on **P12's** path — I verified P13's view and sheet never call
`watchItems()`/`getItems()`; and the 23:25 ruling is specifically about the
saverow copy, which is now fully clean. It is reported so the orchestrator can
decide, because `pocket_money/` is inside a screen agent's allow-list and this
will not be fixed by a shared agent.

## Coverage against the stage brief

| Required | Where | Status |
|---|---|---|
| bloc_test for every event/state path | `payout_bloc_test.dart` (7) + `pocket_money_ledger_bloc_test.dart` (36) | ✅ |
| light + dark | every group; dark geometry pins in `payout_widget_geometry_test.dart` + my iteration-3 file | ✅ |
| widths 320 / 390 / 430 | `payout_responsive_test.dart` (real surfaces) + `p13_bugs_test.dart` | ✅ |
| text scale 1.0 / 1.3 | `payout_responsive_test.dart` matrix | ✅ |
| empty / loading / error | `payout_states_test.dart` (8); empty body in `payout_view_test.dart` | ✅ |
| every tap → right route | scrim tap → `/money`, system back → `/money`, `Add a child` → `/add-children`, CTA → `/money`, kid-mode deep link → `/parental-gate` | ✅ |
| semantics labels on icon buttons | `p13_bugs_test.dart` (P13-BUG-05) + my iteration-3 group F; every control asserts `hasAction(SemanticsAction.tap)` | ✅ |
| tap targets ≥ 44 parent | `payout_responsive_test.dart` + my **empirical** probe (5 px outside lands, 20 px outside does not) | ✅ |
| in-memory Drift, Seed.demo/empty | all files; `setUpTestScope(seedDemo: false)` for the fresh path | ✅ |

## Suite hygiene

- `dart format` clean (494 files, 0 changed); `flutter analyze` →
  **No issues found!**; `analysis_options.yaml` untouched.
- Only skip in `app/test` is `p12_bugs_test.dart:320` (pre-existing P12).
- `disposeApp(tester)` ends every test that pumps the app (RULES §7.1).
- **FONTS** no `google_fonts|GoogleFonts`. **LETTER SPACING** none added.
  **CHILD ORDER** rows and saverow iterate `data.children`.
  **BOTTOM EDGE / ALIGNMENT (owner)** still pinned by
  `payout_responsive_test.dart`'s rendered-pixel probe across both themes and
  all three widths.
- No simulator used.

## Scope (RULES §1)

`git status --porcelain` outside `docs/screens/P13/` and
`app/test/features/pocket_money/` is **empty**. No `core/`, no `app/`, no other
feature, no `tools/screens/`, no `analysis_options.yaml`.

I touched exactly three paths: `p13_bugs_test.dart` (the flake fix),
`SHARED_REQUEST.md` (#3), and this file.

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **461 passed / 1 skipped /
  0 failed**, stable over 3 runs.
- `flutter test` → **2522 passed / 1 skipped / 35 failed**, identical across 3
  runs. All 35 are date-rollover casualties in shared code; see SHARED_REQUEST
  #3, which supersedes #2.
- **P13 has no open findings and no skipped reproducers.** The 23:25 copy ruling
  is implemented, and the saverow keeps the design 72 px row with the toggle
  track at (305, 633) despite the longer sentence.
- For `5_ui`: the copy in the sheet now differs from the design PNG **by
  orchestrator instruction** ("Move £1.00 of Maya's to their Lego Friends set
  fund"). Expect that difference in `compare.py` output; it is intended, not a
  deviation to fix.

VERDICT: FAIL
