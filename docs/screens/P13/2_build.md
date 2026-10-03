# 2 — INTEGRATE (iteration 3) — P13 Payout

Loop stage: combine the two parallel builder halves (`2a_build_logic.md` +
`2b_build_ui.md`) and run the three gates. Scope: **compile + green suite**.

## VERDICT: FAIL — one shared-code test fails, and I may not edit it

`dart format` and `flutter analyze` are clean and **P13's own 439-test suite
passes**, but the **whole-repo gate is red**:

```
dart format .                                 → Formatted 493 files (0 changed)   exit 0
flutter analyze                               → No issues found! (ran in 5.0s)    exit 0
flutter test                                  → 01:49 +2534 ~1 -1: Some tests failed.  exit 1
flutter test test/features/pocket_money      → 00:17 +423 … → 00:17 +439 ~1: All tests passed!  exit 0
```

The single failure:

```
test/core/family_time_test.dart:319
  seed + repository zone plumbing kid_home completions are stamped with the family zone
  Bad state: Too many elements
  dart:core   List.single
```

Exactly **one** `[E]` in the whole run; every other test passes
(`+2534 ~1 -1`). This stage's rule is explicit — *"VERDICT: PASS only if analyze
is clean and the full suite passes"* — so the verdict is FAIL. I did **not**
skip the test, add an ignore, or weaken `analysis_options` to get there, and I
did not edit the failing file, because I am not allowed to (see below).

## Why this is not P13's fault (proved, not assumed)

**1. The failing path contains no P13 code, and is byte-identical to HEAD.**

```
git diff --name-only HEAD -- app/
  app/lib/features/pocket_money/presentation/views/payout_view.dart
  app/lib/features/pocket_money/presentation/widgets/payout_sheet.dart
  app/test/features/pocket_money/p13_bugs_test.dart
  app/test/features/pocket_money/p13_iter2_audit_test.dart
  app/test/features/pocket_money/payout_responsive_test.dart
  app/test/features/pocket_money/payout_widget_geometry_test.dart
```

Everything the failing test exercises is unchanged from `HEAD`:

| File | vs HEAD |
|---|---|
| `app/test/core/family_time_test.dart` | identical to HEAD |
| `app/lib/core/data/seed.dart` | identical to HEAD |
| `app/lib/features/kid_home/data/kid_home_repository_impl.dart` | identical to HEAD |
| `app/lib/core/data/london_time.dart` | identical to HEAD |
| `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart` | identical to HEAD |
| `app/test/test_scope.dart`, `app/test/flutter_test_config.dart` | identical to HEAD |

The failing test body (`family_time_test.dart:307-320`) exercises `Seed.demo`,
`Seed.movedToDubai` and `KidHomeRepositoryImpl.completeQuest`. None of my six
changed files is on that path.

**2. It is the wall clock, not a code change.** Verified against source:

- `seed.dart:392` seeds a `to_do` completion for `['q-plants', 'leo', '10']`
  stamped `utc(10, 3, 6)` = **2026-10-03T06:00Z**.
- `KidHomeRepositoryImpl.completeQuest`
  (`kid_home_repository_impl.dart:157-182`) computes
  `now = DateTime.now().toUtc()` — the **real wall clock**, *not* the
  `Seed.anchorOverride` that `test/flutter_test_config.dart` pins — then keeps
  only rows where `countsForCurrentPeriod(repeatRule, c.createdAt, now, zone)`.
  If none is in period it **inserts a second row**.
- The test calls `Seed.movedToDubai(db)`, so the period is evaluated in **Dubai
  (UTC+4)**: the seeded `06:00Z` row is *2026-10-03 10:00 Dubai*, while the run
  happened at **UTC 2026-10-03 21:52 = 2026-10-04 01:52 Dubai** — a different
  Dubai day. The seeded row is therefore "yesterday", a second row is inserted,
  and `leoRows.single` throws `Too many elements`.
- Independent confirmation from this loop's own history: iteration 2's
  whole-repo run reported `02:14 +2495… +2499 ~1: All tests passed!` at
  **20:45 BST = 19:45 UTC**, i.e. before the 20:00 UTC trigger, on the same
  shared code that is failing now.

**3. I am not permitted to fix it.** RULES §1 allows editing only
`app/lib/features/<feature>/**`, `app/test/features/<feature>/**` and
`docs/screens/<ID>/**`. `app/test/core/family_time_test.dart` and
`app/lib/core/data/seed.dart` are shared. `SHARED_REQUEST.md` **#2** already
files exactly this, with the same root cause, and is marked
`Blocks: yes for the repo-wide gate`.

**What unblocks it** (shared `core`, for the orchestrator — any one of the three
suggested fixes in the request works):

- assert the row the call created instead of `.single`
  (`leoRows.where((r) => r.status == 'done_pending')`, or `.last`); or
- use a quest the seed leaves with **no** completion row (the test only needs
  something to complete); or
- make `completeQuest`'s period test read the same pinned clock the seed uses —
  the real fix, since a repository whose period logic reads the wall clock
  cannot be tested deterministically after 20:00 UTC.

## Summary of 2a (logic)

**No files changed this iteration** — and none could be. `2a` reports
`CONTRACT CHANGES: None` and walks all four `FIXES_2` item groups to confirm
none is in the logic layer: the saverow pronoun lives in
`PayoutSaveRow.label` (widgets), both 5_ui deviations are view/sheet, and the
whole-repo gate failure is shared `core`. Its 13 owned tests pass; neighbour
logic suites (101 total) pass.

## Summary of 2b (UI)

| File | Change |
|---|---|
| `payout_view.dart` | summary caption `textAlign: TextAlign.center` → `TextAlign.start` — `.caption` sets no `text-align` in the CSS, so the design glyphs start at the card's padding edge (5_ui deviation 1). `1_plan.md` §(a) said "centered"; the HTML overrides the plan. |
| `payout_sheet.dart` | `PayoutSaveRow.label` gates the verbatim design string on the **exact seeded shape** (`childId == 'maya'` AND title `'Lego Friends set'`); any other shape gets the neutral data-driven sentence, never the design's gendered "her Lego fund" (P13-BUG-06 / P13-I2-01). |
| `payout_widget_geometry_test.dart` | +2 real-font pins: summary text start-aligned at x ≈ 36; saverow toggle track 51×31 at (305, 633). |
| `payout_responsive_test.dart` | 3 toggle assertions migrated to main's new `NestToggle` contract (51×31 laid-out pill + 59×44 hit overhang), verified functionally with `tapAt` 6 px outside the pill. |
| `p13_bugs_test.dart`, `p13_iter2_audit_test.dart` | BUG-06 and I2-01 reproducers un-skipped and green. |

## FIXES items

### Done

| Source | Item | Where | Verified |
|---|---|---|---|
| `5_ui` dev. 1 | summary text centred in both themes | `textAlign: TextAlign.start` | geometry test pins x ≈ 36 ± 1.5 |
| `5_ui` dev. 2 | saverow toggle 4 px left | **not reproducible on current build** — the 301–351 track belongs to build `bf9f239`, whose `NestToggle` had `ConstrainedBox(minWidth: 59, minHeight: 44)`; merge `87cf5d4` ("NestToggle 51x31 + hit slop") moved it to `size = child.size` with the overhang in `hitTest`. Real-font measurement is now `(305, 632.5, 356, 663.5)` vs design 305–355 @ 633–663 = correct | pinned by a new test at (305, 633) |
| `3_test` P13-I2-01 / P13-BUG-06 | `Move £1.00 of Leo's to her Lego fund` for a goal-bearing Leo | `label()` seeded-shape gate | both reproducers un-skipped, green, assert the negative (no ` her ` for Leo) |
| `3_test` / `2a` | `recordPayout` guards (BUG-02) | already correct | audit file re-verified: amount 0 / negative / clamp / `goalId == null` / `0` with a move |
| `3_test` | submit guards (BUG-01/04/05) | untouched | audit file's same-frame double-tap and sibling tests still pass |
| `2a`/shared | three `payout_responsive_test.dart` assertions red after main's `NestToggle` rework | migrated to the current contract, `NestDevice.tapParent` still 44, no `Skip:`/ignore added | suite green |
| ORCHESTRATOR_NOTES 1–3 | scrim / inline amounts / row text y | already landed in iteration 2 | no regression; still pinned |

**Skips:** `grep -rn "skip: true" app/test` matches exactly one file,
`p12_bugs_test.dart:320` (pre-existing P12). All P13 reproducers are
un-skipped (`skip: false`, 6 in `p13_bugs_test` + 1 in `p13_iter2_audit_test`).

### Left

| # | Item | Why left | Owner |
|---|---|---|---|
| 1 | **`family_time_test.dart:319` — the whole-repo gate failure.** | Shared `app/test/core/**` + `app/lib/core/**`, outside RULES §1. Already `SHARED_REQUEST.md` #2, `Blocks: yes for the repo-wide gate`. I may not skip the test or weaken `analysis_options` to hide it. **This is what forces this stage's FAIL.** | orchestrator `shared/` |
| 2 | **`SHARED_REQUEST.md` #1** — `pumpAppRoute` hard-codes `physicalSize = 390×844`, overwriting any size a test sets first, so two `payout_view_test.dart` cases pass while running at 390. | `app/test/test_scope.dart` is shared. Non-blocking; the real 320/430/320×568 probes pump `NestlingApp` directly. | orchestrator `shared/` |
| 3 | **Saverow copy is a product decision, still open.** `label()` now branches on a hard-coded `childId == 'maya'`. That is a demo-seed identity in product copy logic — correct for the seeded path (the design string stays byte-identical to `P13-payout.html:29`) but the alternative is making the row fully data-driven and diverging from the design copy on the seeded path too. There is no gender/pronoun column to derive it from. | Product decision, not an integration defect. `2b` implemented the seeded-verbatim branch and documented the other. | orchestrator |
| 4 | **`shot.sh` light + dark + `compare.py`.** | Stage rule: no simulator here. | 5_ui |
| 5 | **`_EmptyBody` copy** (`No payouts yet` / `Add a child`) has no design PNG. | No design source exists; unchanged since iteration 1. | 4_review / 5_ui |

## Integration checks I ran (beyond the three graded commands)

- **Format/analyze**: clean; `dart format` 0 changed on the merged tree, so
  the two builders left it already formatted.
- **P13 suite green**: `flutter test test/features/pocket_money` → `00:17 +439
  ~1: All tests passed!` — exactly `2b`'s number. All eight P13 test files run
  (`p13_bugs`, `p13_iter2_audit`, `payout_bloc`, `payout_repository`,
  `payout_responsive`, `payout_states`, `payout_view`,
  `payout_widget_geometry`) plus the four P12 files.
- **Scope (RULES §1)**: `git status --porcelain` outside
  `docs/screens/P13/`, `app/lib/features/pocket_money/` and
  `app/test/features/pocket_money/` is **empty**; `analysis_options.yaml` is
  byte-identical. No `flutter clean`, no `flutter run`, no simulator booted,
  installed on or screenshotted.
- **Contract between the halves**: `2a` reports no contract changes and
  changed nothing; `2b` coded against the same BLoC / `MoneyLedgerData` /
  `MoneyChild` shapes as iteration 2. **No mismatched states/events, no
  renamed members, no import breakages** — nothing to fix. I made **no code
  edit** this iteration.

### Orchestrator-rule spot-checks on the merged tree

- **FONTS** — `google_fonts|GoogleFonts` in the feature's lib + tests: no hits.
- **LETTER SPACING** — no `letterSpacing` added by this iteration.
- **CHILD ORDER** — untouched; rows and the saverow still iterate
  `data.children`.
- **COPY** — the seeded saverow string stays byte-identical to
  `P13-payout.html:29` (`Move £1.00 of Maya's to her Lego fund`, ASCII `0x27`);
  the new fallback strings are only reachable for non-seeded shapes.
- **BOTTOM EDGE / ALIGNMENT / owner rules** — untouched by this iteration's
  edits and still green in the suite.
- **ORCHESTRATOR_NOTES 1–3** — still pinned by the iteration-2 geometry tests;
  no regression.
- **ACCESSIBILITY ACTIONS** — no `excludeSemantics` wrapper was added or
  changed this iteration.

## Left for the next stages

- **orchestrator `shared/`**: SHARED_REQUEST #2 — this is the only thing
  standing between this screen and a green whole-repo gate. Everything else in
  `FIXES_2` is closed.
- `5_ui`: `shot.sh` light + dark + `compare.py`; report the measured y of the
  screen title, the first control and each card top, design vs app (±2 px; a
  uniform vertical shift is a FAIL). The summary alignment and toggle track are
  now numerically pinned, so this should confirm rather than hunt.

VERDICT: FAIL
