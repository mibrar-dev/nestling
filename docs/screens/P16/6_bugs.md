# P16 · Family & settings — Stage 6 adversarial bug hunt (iteration 4)

Route `/settings` · feature `settings` · parent mode · design
`design/html-source/screens/P16-settings.html` + light/dark PNGs
(1170×2532 ÷ 3). This stage changed **nothing** in `app/lib/**`; it refreshed
the open-bug comments in `app/test/features/settings/p16_bugs_test.dart`
(no skip changes — the build had already unskipped B10/B11) and rewrote this
report. No simulator was booted, installed on, screenshotted or driven.

Tree tested: iteration-4 checkpoint `bf1772a` (`main` merged at `6b0346c`).
The concurrent test stage was editing settings test files during the run
(08:30–08:35), so repo-wide numbers below are a snapshot; every P16 gate was
re-run after its edits.

## Result

**No open major bugs.** The iteration-4 build closed both remaining
P16-owned findings and I independently re-attacked the fixes:

* **P16-B11 (major) — fixed.** The switch wrapper is now
  `SizedBox(width: 51, height: 44, Center(...))`; the track sits flush with
  the row's 16 px right inset — gap **0.0** on all three rows at 390 and 320
  (was 34.5). The T02 slop survived: ±6 px outside the track flips, ±7 does
  not; rows stay 56 px; no overflow at 320 @1.3.
* **P16-B10 (minor) — fixed.** The delete and invite rows route through
  `P16TransientGuard.run`. Cancel ×2 no longer re-opens the dialog
  (`dialog=0`), Delete ×2 shows the toast with no re-open
  (`dialog=0, toast=1`), and the picker New York double-tap no longer opens
  the dialog (`dialog=0`, zone written, stays on `/settings`). First taps
  still work (dialog opens; invite toast).
* **P16-T02 / P16-B08 — still fixed**, proofs live and green.
* **P16-B09 is the single open finding** (minor, shared): IANA link ids
  (`Europe/Amsterdam`, …) read as unknown because the bundled tz dataset has
  no backward links; the raw id never reaches the feature, so there is no
  screen-side hook. `SHARED_REQUEST.md` §5. Proof skipped, fails as
  documented.
* Verdict: **PASS** — B09 is minor and shared-blocked.

| id | severity | status | proof |
|---|---|---|---|
| P16-B11 | major | fixed iter-4 | `[P16-B11] the three switches sit on the row’s right edge` — live |
| P16-B10 | minor | fixed iter-4 | `[P16-B10] a double tap on Cancel cannot re-open the delete dialog` — live |
| P16-T02 | major | fixed iter-3, re-verified | `settings_a11y_test.dart` `[P16-T02] …` — live |
| P16-B08 | minor | fixed iter-3, re-verified | `[P16-B08] …` — live |
| P16-B01…B07 | — | fixed iter-1/2, no regression | all live |
| P16-B09 | minor | **open (shared §5)** | `[P16-B09] …` — skipped, fails |

## Verification of the iteration-4 fixes

**B11 — switch position** (`probe S1`, real app, all three rows):

| width | gaps to `row.right − 16` |
|---|---|
| 390 | [0.0, 0.0, 0.0] |
| 320 | [0.0, 0.0, 0.0] |

**T02 — slop after the `width: 51` change** (`probe S2`, Approvals track
303–354): `top±1/5/6 LIVE, ±7 dead`, centre LIVE. The 44×44 contract holds
and the design rect is restored; the two fixes coexist on the same layout.

**B10 — guard coverage** (`probe S3/S4`): Cancel ×2 → `dialog=0`; Delete ×2 →
`dialog=0, toast=1`; picker New York ×2 → `dialog=0`, `path=/settings`,
`zone=America/New_York`. First taps unaffected (`probe T`: dialog opens;
invite toast shows).

**320 @1.3** (`probe S6`): no overflow, track 233–284, row 56 px, gap 0.

## Open items for the orchestrator (not screen bugs)

1. **08:12 mandate item 2 — parent email from the DB.** The ruling's premise
   (“the seed holds that value”) is false: `grep -i email` over the schema and
   `lib/core/data/*.dart` returns 0 hits; `auth_repository_impl.dart:38`
   documents that `members` has no email/password columns and uses the signup
   email only to derive the owner name. The ruling's own fallback applies and
   `SHARED_REQUEST.md` §4 now carries the measurement plus the two ways to
   close it (role-derived subtitle = no schema change; or persist the email).
   Four P16 tests assert the literal, so they follow the decision.
2. **08:12 mandate item 3 — un-fork `_P16Sect`, the subcard and
   `SettingsRow`.** The measured numbers are recorded (`SHARED_REQUEST.md`
   §2 line box ~15.7 vs 18 px; §3 radius 16 vs 24 plus the `Material` loss).
   The build declined to force the reverts because they change the rendered
   geometry of the whole screen and the tests that pin it, and the mandate
   never reached either builder's brief (dispatch gap: notes touched 08:10,
   briefs generated 08:08). It needs a build stage whose brief carries the
   mandate. The test stage is currently measuring the shared components'
   output for exactly this decision.
3. **UI remeasure owed** after the B11 toggle-x change (stage 5 owns; the
   iteration-3 UI pass predates it and measured the below-the-fold toggles
   only indirectly).

## Verified clean this iteration

* All iteration-1–3 regression guards in `p16_bugs_test.dart` (23 unskipped
  tests) green: deep links (kid → gate, onboarding → welcome, trial →
  paywall), back nav, real-app loading, `Seed.empty`, 6 children/long
  names/0 & 9999 coins at 320 @1.3 dark, toggle persistence, same-frame
  double taps, the a11y tap contract, BST offsets, dark contrast.
* The guard's 300 ms window/release and its reset between tests remain pinned
  by the test stage's `p16_transient_guard_test.dart` (green).
* CLOCK rule: 0 `DateTime.now()` hits in the feature; the guard reads
  `clock.now()`.
* No regression in the shared components: the switches use the shared
  `NestToggle` unchanged; `SettingsRow` carries only the padding override
  the T02 contract needs.

## Observations

1. **Snapshot caveat:** the full suite was run twice while the concurrent
   test stage was editing `settings_states_test.dart` (08:34) and
   `settings_a11y_test.dart` (08:30); one run hit a mid-edit load error, one
   hit a one-off T02 failure. Both files pass 3/3 in isolation and the
   settings suite is green; the build checkpoint's own full suite was
   `+3025 ~3`.
2. Cosmetic leftovers, unowned: dialog Cancel wraps at 320/1.3 (shared
   `NestButton`); the subcard ripple paints behind the card (a symptom of the
   un-fork item); the Family list announces as one node (`NestListRow`'s
   no-`onTap` branch, shared).

## Gates (snapshot, `app/`)

```
$ dart format .                     # 537 files, 0 changed
$ flutter analyze                   # No issues found!
$ flutter test test/features/settings/p16_bugs_test.dart
                                    # +23 ~1 (B09 skipped)
$ flutter test test/features/settings/p16_bugs_test.dart --run-skipped
                                    # +23 -1 — only B09 fails (deviceRow=0)
$ flutter test test/features/settings
                                    # +134 ~1: all non-skipped green
```

Full-suite note: the build checkpoint measured `+3025 ~3` green; my two
full-suite runs were disturbed by the concurrent edits (observation 1).

VERDICT: PASS
