# P07 Paywall — test report (Stage 3, iteration 3)

## Summary

The iteration-3 build fixed P07-BUG-10 (the close trap), P07-BUG-11 (announced
`·` separators), P07-BUG-12 (a trial tap downgrading an active subscriber) and
the stacked legal row, and it un-skipped their proofs. **This stage's suite is
green**: `flutter test` reports `+770 ~3`, `dart format` is clean and the
analyzer is clean for every committed file.

Six tests were added this iteration for the behaviour the build introduced.
None of them found a new defect — but one **major bug is open in the screen**:
Stage 6's hunt filed P07-BUG-13 (the legal-link labels are top-aligned instead
of vertically centred, so the links no longer share the separators' baseline).
I reproduced and confirmed it below. Per the stage brief the screen is **not**
patched here, and `VERDICT: PASS` requires no bugs found, so this iteration is a
FAIL with a green suite — same shape as iteration 2.

| Run | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 370 files, 0 changed |
| `flutter analyze` (`paywall_view_test.dart`, `paywall_bloc_test.dart`) | **No issues found!** |
| `flutter analyze` (whole app) | 3 infos, all in `probe_iter3.dart` — see Notes |
| `flutter test test/features/paywall/paywall_bloc_test.dart` | **+30** all passed |
| `flutter test test/features/paywall/paywall_view_test.dart` | **+59** all passed |
| `flutter test test/features/paywall/p07_bugs_test.dart` (stage 6) | **+17 ~3** all passed |
| `flutter test test/features/paywall/` | **+106 ~3: All tests passed!** |
| `flutter test` (whole app) | **+770 ~3: All tests passed!** |

The 3 skips are recorded defects with proof tests (`6_bugs.md` convention:
skipped while the defect is open, un-skipped when fixed): `[P07-BUG-8]` and
`[P07-BUG-9]` (shared code — `SHARED_REQUEST.md`) and `[P07-BUG-13]`.

## Tests added this iteration (6)

All in `paywall_view_test.dart` and `paywall_bloc_test.dart`; no screen code
touched. The build stage had already added the event-level BUG-12 guard tests
and a legal-row geometry test; those were verified green, not rewritten.

| Test | What it pins |
|---|---|
| `the nav keeps its balance spacer while the trial is live` | with a live trial the nav holds **two** 44-wide boxes — the close tile and the balance spacer that mirrors it — so the bar stays visually centred |
| `an expired trial drops the close tile and its spacer` | P07-BUG-10's fix removes **both**: zero 44-wide boxes in the nav, so no dangling 44px of nothing behind the omitted control (ALIGNMENT owner rule). Also asserts the bottom bar and both working exits are untouched, and nothing was written |
| `Start free trial on a paying family never downgrades them to trial` | P07-BUG-12 end to end through the **real** Drift `readSubscription()`: `Seed.demo` is `active`; after tapping the CTA the status is still `active`, `trial_start` has not moved, `onboarding_complete` is true, and the family lands on `/today`. The `before` assertion proves the setup is genuinely active, so the assertion is not vacuous |
| `the legal separators are decoration, not links` | P07-BUG-11: `·` is painted twice (`find.text` → 2) but announced **zero** times, while all three links are still labelled — the first half is not vacuously true |
| `readSubscription is a one-shot read that never waits on a stream` | the mechanism BUG-12's guard depends on: the read completes inside a 1s budget (the interface default is `watchSubscription().first`, which stays pending inside a widget test — a regression fails on the budget instead of hanging), and the next read sees a write immediately. Complements the build's per-seed status test instead of duplicating it |
| (support) `_expireSubscription(db)` + `_navSpacers(tester)` helpers | write `subscription_status = 'expired'` and re-read the session — the only input the `trialExpired` guard reacts to (P07-BUG-8: nothing in the app writes it yet) — and a finder for 44-wide boxes inside the nav subtree |

Coverage note from writing them: the existing `parent tap targets are at least
44dp` test measures the **semantics node**, which the `ConstrainedBox` keeps at
44 even while the label inside it is mispositioned. That is exactly why BUG-13
slipped past the tap-target contract — target size and label geometry are two
different assertions.

## Bugs found

### P07-BUG-13 — major (confirmed, open) — legal-link labels are top-aligned, not centred

Found by Stage 6's hunt in iteration 3 and **confirmed by me** with the same
proof; recorded, not patched (stage 3 may not edit the screen).

**Where:** `app/lib/features/paywall/presentation/views/paywall_view.dart:818-829`
— `_LegalLink`'s `Padding(horizontal: 6)` → `ExcludeSemantics` → `Text`. The
iteration-3 fix for the stacked legal row removed the expanding `Center` that
used to sit between the `InkWell` and the text, and with it went the vertical
centring. The design
(`design/html-source/screens/P07-paywall.html`, `.legal-row .link`) is
`display: inline-flex; align-items: center; justify-content: center;
min-height: 44px` — the label is centred in its 44px target.

**Repro:**
```
cd app
flutter test test/features/paywall/p07_bugs_test.dart \
  --run-skipped --plain-name 'P07-BUG-13'
```
→ `Expected: 757.25 (±1.0) / Actual: 744.25` — the label sits 13px above where
the design puts it (design label box 767–780, app 754–766), so the three
underlined links and the two `·` separators do not share a baseline.

**Rule impact:** the owner's ALIGNMENT rule ("nothing a few px off") — 13px is
far more than a few, and the row is the last thing on the screen.

**Suggested fix (build stage):** centre the label inside the target without
letting it expand the `Wrap` run — `Align(alignment: Alignment.center)` (not
`Center`) or `Padding` with symmetric vertical insets inside the existing
`ConstrainedBox`, keeping `softWrap: false` so the link still sizes to its text.
Then un-skip `[P07-BUG-13]`.

## Verified clean this iteration

- Everything iteration 2 proved still holds: the design surface and its copy
  character-by-character, `PipAvatar(mochi, sunny, stage 4, inNest)` on the
  120px slot, light + dark × 320/390/430 × text scale 1.0/1.3 with no overflow,
  20px gutters, the bottom edge reaching the physical edge in both themes
  (painted-pixel proof, including a 34px home-indicator inset), every tap
  navigating to the right route (`/pocket-money-setup`, `/today`), the
  ORCHESTRATOR_NOTES 1 handoff on both paths, `initial`/`loading`/`loaded`/
  `failure` + Retry, an empty plan list that is never an empty state, and an
  identical screen under `Seed.demo`/`empty`/`fresh` with no seeded child names.
- The action paths: failure toasts in place and retries, `working` disables the
  CTA and the restore link, a second tap never starts a second trial, and a
  restore never shows the trial spinner.
- `google_fonts` / `GoogleFonts.*` appear nowhere in this feature's `lib/` or
  `test/` (the FONTS rule).

## Notes

1. **Open shared findings.** `[P07-BUG-8]` (the trial never expires) and
   `[P07-BUG-9]` (kid-mode guard order) live in `core/` and `app/` — outside
   RULES §1, filed in `docs/screens/P07/SHARED_REQUEST.md`. P07-BUG-10's fix is
   the screen half of that pair, so it is ready for the day they land.
2. **Concurrent stages in this worktree.** Stage 6 (bugs) is running
   concurrently: `app/test/features/paywall/probe_iter3.dart` is its temporary
   scratch file (its own header says it is deleted before that report lands; it
   has no `_test` suffix so `flutter test` never collects it, but it accounts
   for all 3 `flutter analyze` infos), and `p07_bugs_test.dart` is being edited
   mid-run — an unused-import info there appeared and cleared during this
   stage. Neither is a P07 defect and neither was touched here.

## Verdict basis

All tests pass (`+770 ~3`), formatting is clean and the committed test files
analyze clean, but a major defect is open in the screen — P07-BUG-13, a 13px
vertical misalignment of every legal link, confirmed here with a repro. Stage 3
may only pass when no bugs are found, so the build stage should centre the
legal-link labels and un-skip `[P07-BUG-13]`.

VERDICT: FAIL