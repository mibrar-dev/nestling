# 3 — TEST (iteration 2) — P13 · Payout (parent)

Route `/payout`, feature `pocket_money`, build `bf9f239`. In-memory Drift via
`test_scope.setUpTestScope` + `Seed.demo()`, day pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. **No simulator was booted, installed on,
screenshot or driven** (stage rule — only `5_ui` may).

I did not take `2_build.md`'s word for anything: I re-derived every claim from
the source and from the rendered widget. The build was honest — but the gate is
still red and one open bug survives.

## Headline

```
dart format --output=none --set-exit-if-changed .   → Formatted 492 files (0 changed)  exit 0
flutter analyze                                      → No issues found! (10.3s)        exit 0
flutter test test/features/pocket_money              → +436 ~3: All other tests passed! exit 0
flutter test                                         → +2511 ~3 -1: Some tests failed!   exit 1
```

Two things to read carefully:

1. **P13's own suite is green** — 436 passed, 3 skipped, 0 failed. All five
   iteration-1 reproducers really do run now (`grep -rn "skip: true" test/`
   matches only `p12_bugs_test.dart:320` — pre-existing P12 — plus the two
   finding reproducers below).
2. **The whole-repo run is red**, on `test/core/family_time_test.dart` — shared
   code, not P13. Root cause found and filed as SHARED_REQUEST #2; see
   *Gate failure outside this screen*.

And a bug **was** found, so the stage rule ("PASS only if all tests pass **and**
no bugs were found") cannot be met either way.

**VERDICT: FAIL**

---

## ORCHESTRATOR_NOTES verification (all three items are mandatory)

`docs/screens/P13/ORCHESTRATOR_NOTES.md` (added 19:48). Checked against the
tree, not against the builders' summary.

| # | Requirement | Where it is pinned | Verified |
|---|---|---|---|
| 1 | Scrim covers the WHOLE screen incl. status-bar + header | `payout_widget_geometry_test.dart:261` asserts the painted `ColoredBox` (found by its `tokens.scrim` colour, not by text) is exactly `Rect.fromLTRB(0, 0, 390, 844)` | ✅ `_DimmedLedger` is now a `Stack` with a `Positioned.fill` scrim layer between the chrome column and the sheet (`payout_view.dart:284-345`). Matches `components.css:164` `inset: 0`. |
| 2 | Amounts inline at the **subtitle's** size — bold 13 px, after `Weekly + quests · ` | `payout_widget_geometry_test.dart:206` asserts one `RichText` with `toPlainText() == 'Weekly + quests · £4.20'`, the caption span `fontSize == 13`, the amount span `fontSize == 13` / `w700` / `ink2` / `tabularFigures` | ✅ I confirmed `NestType.money` (`core/design_system/tokens/typography.dart:108`) is Inter **w700** + tabular, so `copyWith(fontSize: 13, height: 18/13)` is exactly `components.css:155` `.money` on the `.caption` line. The old `.child .am { font-size: 18px }` page rule is markup this screen never emits. |
| 3 | Row text y within **±1** for **both** rows | `payout_widget_geometry_test.dart:242-252` asserts `name.top ≈ 458 ±1`, `subtitle.top ≈ 480 ±1`, `leoName.top ≈ 544 ±1`, `leoSubtitle.top ≈ 566 ±1`, with `height ≈ 22` / `18` | ✅ Real fonts, not Ahem: the file loads the bundled Inter + Nunito through `FontLoader` (`:42-54`). Without that the card heights would be meaningless. |

The note also asked for "a scrim test that the barrier's rect covers (0,0) and
the full screen size" — that is exactly the `:261` assertion. All four
requirements are met, and met with rendered **shapes**, per the
"UI CHECK MEASURES SHAPES" rule.

## Tests added this stage

New file **`app/test/features/pocket_money/p13_iter2_audit_test.dart`** — 12
tests (11 active, 1 skipped reproducer). It is an *independent* audit: it
re-derives the iteration-2 fixes from the database and the widget tree instead
of asserting them through the existing helpers.

| Group | Tests | What it pins |
|---|---|---|
| `.saverow` copy is data-driven | 3 | The seeded Lego goal still renders `P13-payout.html:29` verbatim; a **non**-Lego goal never borrows a gender pronoun; **`P13-I2-01` (skipped reproducer)** — a Lego goal for Leo. |
| `recordPayout` guards | 5 | `amountPence == 0` writes nothing at all; `0` **with** a savings move still moves nothing; the **clamp backstop** holds for a caller that does *not* clamp (payout −50 → move +50 → goal +50); a **negative** amount is a no-op, not a credit; a move with `goalId == null` moves nothing. |
| busy CTA | 2 | The CTA pill keeps its exact rect across the in-flight frame (`loading: true` adds a spinner prefix — a pill that resized mid-write would be a visible jump); a busy CTA has `onPressed == null`. Both use a gated repository, because on in-memory Drift the write lands inside the first frame. |
| submit guards | 2 | Unticking everyone still disables the CTA (no regression on `canSubmit`); **ticking a second child pays BOTH** — the anti-double-tap guard is per child, so it must not swallow a sibling in the same tap (maya −420 **and** leo −210, exactly 2 payout rows). |

### Of my own three mistakes, for the record

Three tests I wrote were wrong before they were right, and the corrections are
in the file:

- Reading Drift through `GetIt.instance<PocketMoneyRepository>().owed()` inside
  the fake-async zone **hung** for 10 minutes (the same class of trap as
  iteration 1's T-1). Fixed by reading the captured `db` directly, which is
  what `p13_bugs_test.dart` does.
- My first busy-CTA tests reported `Bad state: No element`. That was **my**
  finder being text-anchored while the write completed and popped the sheet
  before the second frame — not a screen defect. Fixed with `_GatedRepo`.
- My "pays BOTH" test measured Maya at **−800** because `Seed.demo()` already
  contains a historical payout row per child. Fixed by capturing seeded row ids
  first (`_newRows` pattern). Worth stating plainly: a wrong number in a new
  test is not evidence of a bug until you have checked the seed.

## Bugs found

### P13-I2-01 — a goal-bearing Leo still gets the design copy's "her" (minor, OPEN)

**Where:** `app/lib/features/pocket_money/presentation/widgets/payout_sheet.dart:421`
(`PayoutSaveRow.label`), specifically the branch at `:427`
`if (title.toLowerCase().contains('lego'))`.

**What happens.** `label()` selects the design's verbatim string by checking
whether the **goal title** contains "lego", and that string hard-codes the
feminine pronoun. The demo seed's goal is `Lego Friends set` for **Maya**, so
on the demo path the copy is correct. Give **Leo** a Lego goal and the sheet
renders:

```
Move £1.00 of Leo's to her Lego fund
```

**This is the same defect as P13-BUG-06, found independently** by this stage
and by stage 6 (which was running in parallel and added its reproducer at
`p13_bugs_test.dart:582`). I am counting it once. Both reproducers are kept
because they reach it by different routes: stage 6 goes through a real
`Seed.demo` database, mine renders a hand-built `MoneyLedgerData` with Leo's
goal.

**Repro (mine).**

```bash
cd app
sed 's/^      skip: true, \/\/ P13-I2-01/      \/\/ unskipped/' \
  test/features/pocket_money/p13_iter2_audit_test.dart \
  > test/features/pocket_money/_unskip_test.dart
flutter test test/features/pocket_money/_unskip_test.dart --plain-name P13-I2-01
rm test/features/pocket_money/_unskip_test.dart
```

Measured output:

```
P13-I2-01 rendered copy: Move £1.00 of Leo's to her Lego fund
Expected: not contains ' her '
  Actual: 'Move £1.00 of Leo\'s to her Lego fund'
```

**Why this cannot be fixed from the data.** There is no gender or pronoun
column — `Children` (`app/lib/core/data/app_database.dart:65-85`) has `id`,
`nickname`, `ageBand`, `ageYears`, `avatarColour`, `pinHash`, the pip fields and
the coin fields, and nothing else. The screen is being asked to render a
gendered noun with no gender available. The only data-safe answer is the
neutral fallback the helper already has
(`"Move £1.00 of $name's money to their $title fund"`), which means the seeded
design string and DATA OVER MOCKS are in genuine tension for any non-Maya goal
child. That tension is a product decision, not a screen bug, so it goes to the
orchestrator with the finding.

### Everything else: verified fixed

| Iteration-1 finding | Status | Independent evidence |
|---|---|---|
| P13-BUG-01 double submit | FIXED | `_payoutInFlight` is per child and cleared in `finally`; `busy: _submitted.isNotEmpty` reaches `canSubmit`. My gated test holds a write open and finds `onPressed == null`; my "pays BOTH" test proves the guard does not drop a sibling. |
| P13-BUG-02 unclamped move | FIXED | View clamps with `min(100, owed)`; repository clamps to `min(move, amount)` and credits the goal with the **clamped** value. My repo test proves the backstop alone (a caller that does not clamp) still yields move +50 / goal +50 on a £0.50 payout. |
| P13-BUG-03 scrim | FIXED | Rect `(0,0,390,844)`, pinned. |
| P13-BUG-04 silent retry | FIXED | `errorMessage` is cleared before the write, so an identical repeat is a state change again. |
| P13-BUG-05 semantics | FIXED | Chrome is `ExcludeSemantics`; the scrim keeps its own labelled `'Close payout'` node **with `onTap:`**, so the `excludeSemantics: true` wrapper still satisfies the ACCESSIBILITY rule. |
| review #3 `Paid · £0.00` row | FIXED | View skips `owed == 0`; repository no-ops `amountPence <= 0`. My test proves a **negative** amount is also a no-op rather than a credit. |
| review #5 `State` mutated in `build` | FIXED | `_prime` runs from a `BlocListener` + `initState`; `build` is pure. |
| review #10 `_FailureBody` reserve | FIXED | `NestStatusBar()` added. |

## Gate failure outside this screen (shared code)

`flutter test` (whole repo) fails on
`test/core/family_time_test.dart:319`, `Bad state: Too many elements`:

```
seed + repository zone plumbing kid_home completions are stamped with the
family zone
```

**This is not P13.** P13 writes only `ledgerEntries` (`payout`, `savings_move`)
and the savings-goal bump; it never inserts into `questCompletions`. The file is
`test/core/` and the seed is `lib/core/data/`, both outside RULES §1.

**Root cause (traced through source).** `lib/core/data/seed.dart:392` seeds a
`to_do` completion for `['q-plants', 'leo', '10']` stamped `utc(10, 3, 6)` =
2026-10-03T06:00Z. The test then calls `Seed.movedToDubai(db)` and
`completeQuest('leo', 'q-plants')` and expects `leoRows.single`.
`KidHomeRepositoryImpl.completeQuest`
(`lib/features/kid_home/data/kid_home_repository_impl.dart:145-182`) only
**updates** the seeded row when
`countsForCurrentPeriod(quest.repeatRule, c.createdAt, now, zone)` holds;
otherwise it **inserts** a second row. `now` there is the real wall clock, not
the `Seed.anchorOverride` that `test/flutter_test_config.dart` pins. Once real
UTC passes 20:00, the Dubai day has rolled over, the seeded 06:00Z row is
"yesterday" in the new zone, and `.single` sees two rows.

Measured on this machine at the time of the run:
`UTC 2026-10-03 21:10`, `Dubai 2026-10-04 01:10`, `London 2026-10-03 22:10`.
That is also why the same command **passed** earlier in this stage (before
20:00 UTC, Dubai was still 3 Oct) and fails now — the trigger is the clock, not
a code change.

Filed as **SHARED_REQUEST #2** with three suggested fixes. It makes
`flutter test` red for every screen loop from 20:00 UTC onward, so it is worth
the orchestrator's attention even though no screen is at fault.

## Suite hygiene

- `dart format` clean (492 files, 0 changed); `flutter analyze` → **No issues
  found!**; no ignore added, `analysis_options.yaml` byte-identical.
- Skips in the whole test tree: `p12_bugs_test.dart:320` (pre-existing P12),
  `p13_bugs_test.dart:621` (stage 6's P13-BUG-06 reproducer), and mine
  (`p13_iter2_audit_test.dart`, P13-I2-01). Every skip is a *finding
  reproducer with a written reason*, and each was run un-skipped to prove it
  fails for the recorded reason. No test was skipped, ignored or `@`-disabled to
  reach green.
- **FONTS** — `google_fonts|GoogleFonts` in `lib/features/pocket_money` +
  `test/features/pocket_money`: no hits.
- **LETTER SPACING** — `git diff fe8e296 bf9f239 -- lib/features/pocket_money |
  grep letterSpacing`: no hits.
- **CHILD ORDER** — rows and the saverow child both iterate `data.children`
  (creation order, Maya → Leo).
- **COPY** — the seeded path renders `P13-payout.html:29` verbatim, ASCII
  `0x27` in `you've` / `Maya's`, U+00B7, `&` in the CTA, U+2014 in the toast.
- **disposeApp** — every widget test that pumps the app ends with
  `disposeApp(tester)` (RULES §7.1) to drain Drift's deferred stream-close.
- **BALANCED HEADINGS / PIP / NestChipWrap / TRIAL / PERIODS** — untouched by
  P13. `NestBalancedText` is correctly absent: `P13-payout.html:5` (`.pay h2`)
  sets no `text-wrap: balance` and the rule forbids it on `.h2`.

## Scope (RULES §1)

`git status --porcelain` outside `docs/screens/P13/` and
`app/test/features/pocket_money/` is **empty**. No `core/`, no `app/`, no other
feature, no `tools/screens/`, no `analysis_options.yaml`. No `flutter clean`,
no `flutter run`, no simulator.

I edited exactly three paths this stage: the new
`app/test/features/pocket_money/p13_iter2_audit_test.dart`, the appended
SHARED_REQUEST #2, and this file. `p13_bugs_test.dart` and
`4_review.md` / `5_ui.md` / `6_bugs.md` show as modified in `git status`, but
those are the parallel stage 4/5/6 agents' writes, not mine.

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **436 passed / 3 skipped /
  0 failed** (33 s).
- `flutter test` → **2511 passed / 3 skipped / 1 failed** (4:04). The single
  failure is shared `test/core/family_time_test.dart`, SHARED_REQUEST #2.
- P13 itself has **one open minor**: P13-BUG-06 / P13-I2-01 (goal-title-keyed
  pronoun). It needs a product decision on gendered copy without a gender
  column, not just a code change.
- When BUG-06 is fixed, retire both reproducers (they guard the same fix;
  `p12_bugs_test.dart` is the precedent for retiring a finding).

VERDICT: FAIL
