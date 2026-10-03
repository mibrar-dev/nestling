# 3 — TEST (iteration 3) — P13 · Payout (parent)

Route `/payout`, feature `pocket_money`, build `d5e3d82`. In-memory Drift via
`test_scope.setUpTestScope` + `Seed.demo()`, day pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. **No simulator was booted, installed on,
screenshot or driven** (stage rule — only `5_ui` may).

## Headline

```
dart format --output=none --set-exit-if-changed .  → Formatted 493 files (0 changed)   exit 0
flutter analyze                                     → No issues found! (3.7s)         exit 0
flutter test test/features/pocket_money             → +461 ~1: All other tests passed!  exit 0
flutter test                                        → +2556 ~1 -1: Some tests failed!    exit 1
```

**P13's own suite is green** — 461 passed, 1 skipped, 0 failed — and, for the
first time in this loop, **no P13 test is skipped**: the only `skip: true` in
the whole tree is `p12_bugs_test.dart:320`, which is pre-existing P12. The
iteration-1 majors (P13-BUG-01…03) and minors (04, 05) and the iteration-2
finding (BUG-06) are all retired into live assertions.

**The whole-repo gate is still red**, on exactly one shared test —
`test/core/family_time_test.dart:319` — which is the item I filed as
SHARED_REQUEST #2 at the end of iteration 2 and which is still unfixed on
`main`. Root cause re-verified below; it is not P13's code.

**No new P13 bug was found this iteration**, which is a real result rather than
a formality: iteration 3 changed three pieces of product behaviour and I
attacked each one directly. Two of my three attacks initially "failed" and
turned out to be my own wrong assertions — recorded below, because the
corrections are the useful part.

## VERDICT: FAIL

Not because P13 regressed. The stage rule is *"PASS only if all tests pass and
no bugs were found"*; `flutter test` does not pass, and the reason is a shared
test I am not permitted to edit. `SHARED_REQUEST.md` #2 is marked
`Blocks: yes for the repo-wide gate` and has now been open across two
iterations.

---

## ORCHESTRATOR_NOTES — still mandatory, still satisfied

`ORCHESTRATOR_NOTES.md` is unchanged since 19:48 (items 1–3 + the pinning
request). All three remain pinned and green; I re-verified each against the
tree rather than assuming iteration 3 kept them.

| # | Requirement | Pinned at | Verified this iteration |
|---|---|---|---|
| 1 | Scrim covers the whole screen, incl. status-bar + header | `payout_widget_geometry_test.dart:261` — `Rect.fromLTRB(0, 0, 390, 844)` on the painted `ColoredBox` | ✅ still green, and **I added the dark-theme counterpart** (see gap G2) |
| 2 | Amounts inline, bold 13 px, after `Weekly + quests · ` | `payout_widget_geometry_test.dart:206` — one `RichText`, `toPlainText() == 'Weekly + quests · £4.20'`, amount span 13 px / w700 / ink2 / tabular | ✅ still green; **dark counterpart added** |
| 3 | Row text y within ±1, both rows | `payout_widget_geometry_test.dart:242-252` — name 458, subtitle 480, Leo 544/566, heights 22/18 | ✅ still green; **dark counterpart added** |
| — | Real fonts via `FontLoader` | `:42-54` loads the bundled Inter + Nunito | ✅ my new dark pins reuse the same loader, so they measure real glyphs, not Ahem |

## Tests added this stage

New file **`app/test/features/pocket_money/p13_iter3_audit_test.dart`** — 19
tests, all green, zero skips. It attacks the three things iteration 3 changed
and the gaps around them.

| Group | Tests | What it pins |
|---|---|---|
| **A. `PayoutSaveRow.label` gate** | 7 | The gate is new product logic and the whole BUG-06 fix rests on it, so it is pinned as a **matrix**, not left implicit: the exact seeded shape still yields the design sentence byte-for-byte; a goal-bearing Leo never gets it for `Lego City` / `Lego Friends set` / `Lego Star Wars`; no nickname gets the pronoun from a bare `Lego` title; a Maya goal that is not the seeded one falls back; a **case-different** title (`lego friends set`) falls back (the gate is exact on purpose — a case-insensitive match would smuggle the gendered string back in); a null/whitespace title reads as plain savings; and a final count — **exactly one** of seven shapes may use the design sentence. |
| **B. Seeded path end to end** | 1 | `Seed.demo()` still renders `P13-payout.html:29` verbatim, *and* the neutral fallback is absent. This is the tripwire for the iteration-3 risk: `label()` now keys on `childId == 'maya'`, so if that id ever stops being the seeded child the design copy silently becomes neutral and the UI check is the only thing that would notice. |
| **C. Alignment** | 3 | The summary caption starts at x ≈ 36 (card padding) and is provably left-aligned (its left edge is left of the surface midpoint, so it cannot also be centred). Two contrast cases keep the fix honest: the closing caption is still `TextAlign.center` (`.cap`, `P13-payout.html:26`), and the sheet title + subtitle are still centred (`.pay h2`, `.pay .sub`). Without these, "make everything start-aligned" would pass. |
| **D. Long fallback copy** | 2 | The neutral sentence is far longer than the design string, so it is probed at **320×568 @ text scale 1.3** after rewriting the seeded goal title to `Lego Star Wars Galactic Empire Imperial Ship`: no overflow exception, no ` her `, and the toggle is reachable (the sheet scrolls) and still flips. Plus an **empirical 44 px tap-target test** on every edge. |
| **E. ORCHESTRATOR 1 + 3 in dark** | 3 | Dark scrim is `Rect(0,0,390,844)`; dark row text sits at 458/480/544/566; dark amount span is 13 px w700 **ink-2** (not ink). |
| **F. Regression sweep** | 3 | CTA pill still exactly 350×52 at x 20…370; the saverow toggle paints 51×31 at (305, 633) — re-pinning `5_ui` deviation 2; every payout control still exposes `SemanticsAction.tap` (both checks, `Close payout`, and the toggle **by its label**, after main's `NestToggle` rework). |

### My three wrong assertions, and what each actually proved

Worth recording, because in all three cases the screen was right and I was
wrong — and in two of them the correction turned into a *stronger* test.

1. **`NestToggle` height is 31, not ≥44.** I asserted
   `getRect(find.byType(NestToggle)).height >= 44` and it failed with
   `Actual: <31.0>`. That looked like a tap-target regression. It is not: main's
   rework (merge `87cf5d4`, "NestToggle 51x31 + hit slop") moved the 44 px
   parent target out of the laid-out size and into a custom `RenderBox.hitTest`
   overhang (`nest_toggle.dart:143-167`, `size = child.size` plus a
   `minWidth`/`minHeight` slop). A rect assertion measures the *pill*, not the
   touch area — which is why `payout_responsive_test.dart` already tests it
   functionally with `tapAt`. Replaced with the functional form, and extended:
   the new test probes **5 px outside each painted edge (must land) and 20 px
   outside (must not)**, so the ≥44 rule is now measured empirically and
   survives the next `NestToggle` rework.
2. **`center.dy - 20` is not "20 px above the pill".** The toggle's hit-target
   probe failed with `Expected: false, Actual: <true>`. The toggle was
   correct: 20 px above the pill's *centre* is only 4.5 px above its top edge,
   i.e. legitimately inside the 44 px target. Fixed to measure from
   `pill.top` / `pill.bottom` and added the bottom-side negative probe.
3. **The toggle's Semantics is not on `find.byType(NestToggle)`.** I got a node
   with no tap action. The label lives on a descendant
   (`semanticLabel: "Move one pound of $name's money to savings"`), matching
   the design's `aria-label`; the rest of the suite finds it by label. Re-queried
   by label, and it does expose `SemanticsAction.tap` — the ACCESSIBILITY
   requirement holds after the `NestToggle` rework.

## Verification of iteration 3's changes

**The `textAlign` flip is correct, and `1_plan.md` was wrong.** `2b` overrode
`1_plan.md` §(a) ("centered") with `TextAlign.start`. I checked the design
source rather than accepting the note: `components.css:34` defines
`.caption` with **no** `text-align` (so `start`), while `.cap
{ text-align: center }` lives in the page's own `<style>` and is applied only
to the closing caption (`P13-payout.html`, `<div class="caption cap">`). The
summary card is a bare `<div class="caption">`. The plan's "centered" had no
CSS behind it. Confirmed, and pinned as a contrast pair (group C).

**BUG-06 / I2-01 is genuinely fixed.** The rendered copy for a goal-bearing Leo
no longer contains ` her `, and the seeded path is byte-identical to the
design. Both reproducers are live assertions now, not skips.

**No regressions from the `NestToggle` migration.** `2b` migrated three
`payout_responsive_test.dart` assertions to main's new contract. I checked the
migration is not a weakening: the pill is still 51×31, the target still ≥44
functionally (verified empirically), no `Skip:` was introduced, and
`NestDevice.tapParent` is still 44.

**Residual concern, reported not inflated.** `label()` gating on
`childId == 'maya'` puts a **demo-seed identity into product copy logic**.
`2_build.md` flagged this itself (Left #3) and it is a genuine smell: nothing
about "maya" implies a girl. It is not a runtime bug today — real families get
generated ids, so the gate is false and the neutral copy renders; the design
sentence only ever appears for the demo child. I have pinned that seeded path
(group B) so a seed change fails loudly instead of silently shipping neutral
copy. This is a product decision for the orchestrator, not a screen defect.

## Gate failure outside this screen (shared code) — SHARED_REQUEST #2

Unchanged and still red. Re-verified this iteration, same line, same cause:

```
test/core/family_time_test.dart:319
  seed + repository zone plumbing kid_home completions are stamped with the family zone
  Bad state: Too many elements
  dart:core   List.single
```

- **Not P13.** P13 writes only `ledgerEntries` (`payout`, `savings_move`) and
  the savings-goal bump; it never touches `questCompletions`. The failing
  files (`test/core/family_time_test.dart`, `lib/core/data/seed.dart`,
  `lib/features/kid_home/.../kid_home_repository_impl.dart`) are byte-identical
  to `HEAD` and are outside RULES §1.
- **Still the wall clock.** `seed.dart:392` seeds a `to_do` completion for
  `['q-plants', 'leo', '10']` at `utc(10, 3, 6)` = 2026-10-03T06:00Z. The test
  calls `Seed.movedToDubai(db)`, so `completeQuest`'s
  `countsForCurrentPeriod(..., now, zone)` is evaluated in **Dubai** with
  `now = DateTime.now().toUtc()` — the real clock, *not* the
  `Seed.anchorOverride` that `test/flutter_test_config.dart` pins. Measured
  during this run: `UTC 2026-10-03 22:33`, `Dubai 2026-10-04 02:33`. The
  seeded row is 2026-10-03 10:00 Dubai — the previous Dubai day — so the
  in-period update branch is skipped, a second row is inserted, and `.single`
  throws.
- It reproduced at 19:45 UTC (Dubai still 3 Oct, test passed) and fails from
  20:00 UTC onward, which is why it looks intermittent.

This is the second consecutive iteration blocked by it. Three suggested fixes
remain in the request; the smallest is asserting the row the call created
(`leoRows.where((r) => r.status == 'done_pending')`) instead of `.single`.

## Coverage against the stage brief

| Required | Where |
|---|---|
| bloc_test for every event/state path | `payout_bloc_test.dart` (7) — submit forwards/zero-save/rejected/optimistic-silence plus the iteration-2 guard paths; `pocket_money_ledger_bloc_test.dart` (36) covers the load/step/day/mode events P13 shares |
| light + dark | every group runs both; dark geometry pins added this iteration (group E) |
| widths 320 / 390 / 430 | `payout_responsive_test.dart` (9, real surfaces) + `p13_bugs_test.dart` (real 320 dp, 320×568) + my 320×568@1.3 case |
| text scale 1.0 / 1.3 | `payout_responsive_test.dart` matrix + my group D |
| empty / loading / error states | `payout_states_test.dart` (8): never-emits spinner, first emission, failure copy, retry, VoiceOver retry, repeat failure, dark, 320 dp; empty body in `payout_view_test.dart` |
| every tap navigates to the right route | `payout_view_test.dart`: scrim tap → `/money`, system back → `/money`, `Add a child` → `/add-children`, CTA → `/money`; deep links + kid-mode guard in `p13_bugs_test.dart` |
| semantics labels on icon buttons | group F above + `p13_bugs_test.dart` P13-BUG-05 |
| tap targets ≥ 44 parent | `payout_responsive_test.dart` + my **empirical** 44 px test on all four edges |
| in-memory Drift with Seed.demo/empty | all files; `setUpTestScope(seedDemo: false)` for the fresh/empty paths |

## Suite hygiene

- `dart format` clean (493 files, 0 changed); `flutter analyze` →
  **No issues found!**; no ignore added; `analysis_options.yaml` untouched.
- The only skip in `app/test` is `p12_bugs_test.dart:320` (pre-existing P12).
  Every P13 finding reproducer is a live assertion.
- `disposeApp(tester)` ends every test that pumps the app (RULES §7.1), which
  drains Drift's deferred stream-close.
- **FONTS** — no `google_fonts|GoogleFonts` in the feature's lib or tests.
- **LETTER SPACING** — none added by iteration 3 or by me.
- **CHILD ORDER** — rows and the saverow child both iterate `data.children`.
- **BOTTOM EDGE / ALIGNMENT (owner)** — unchanged and still pinned by
  `payout_responsive_test.dart`'s rendered-pixel probe across both themes and
  all three widths; my group C adds the gutter/alignment pins at the text level.
- **BALANCED HEADINGS / PIP / NestChipWrap / TRIAL / PERIODS** — untouched by
  P13; `NestBalancedText` is correctly absent (`.pay h2` sets no
  `text-wrap: balance`, and the rule forbids it on `.h2`).

## Scope (RULES §1)

`git status --porcelain` outside `docs/screens/P13/` and
`app/test/features/pocket_money/` is **empty**. No `core/`, no `app/`, no other
feature, no `tools/screens/`, no `analysis_options.yaml`. No `flutter clean`,
no `flutter run`, no simulator.

I touched exactly two paths: the new
`app/test/features/pocket_money/p13_iter3_audit_test.dart` and this file.
`p13_bugs_test.dart`, `4_review.md` and `docs/screens/P13/ui/*_3.png` show as
modified/untracked in `git status`, but those are the parallel stage 4/5/6 and
5_ui agents' writes.

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **461 passed / 1 skipped /
  0 failed** (16 s).
- `flutter test` → **2556 passed / 1 skipped / 1 failed** (1:05). The single
  failure is shared `test/core/family_time_test.dart` — SHARED_REQUEST #2,
  open for a second iteration.
- **P13 has no open findings.** SHARED_REQUEST #1 (`pumpAppRoute` surface size)
  is still open and non-blocking. The only P13 decision left is the
  `childId == 'maya'` copy gate, which is a product call, not a defect.
- For `5_ui`: `shot.sh` + `compare.py` light and dark on
  `BC440E48-B3A3-43BC-971B-0EF5DB621874`. Report the measured y of the screen
  title, the first control and each card top. Iteration 2's UI stage failed on
  the scrim and the summary alignment; both are now addressed and pinned, and
  the toggle position is pinned at (305, 633).

VERDICT: FAIL
