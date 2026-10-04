# P16 · Family & settings — Stage 6 adversarial bug hunt (iteration 3)

Route `/settings` · feature `settings` · parent mode · design
`design/html-source/screens/P16-settings.html` + light/dark PNGs
(1170×2532 ÷ 3). This stage changed **nothing** in `app/lib/**`; it added two
open-bug proofs to `app/test/features/settings/p16_bugs_test.dart` (P16-B10,
P16-B11) and this report. No simulator was booted, installed on, screenshotted
or driven.

Tree tested: iteration-3 checkpoint `7160fff` plus the concurrent test stage's
files that landed during the run (`p16_transient_guard_test.dart`, updated
`settings_a11y_test.dart`). `main` has moved on since the checkpoint (keypad
merge) but has not been merged into this branch — process item, not a finding.

## Result

* **P16-T02 is fixed.** The three switch rows now give the toggle room
  (`SettingsRow` 6 px vertical padding + a 44-high wrapper): taps ±6 px
  outside the 51×31 track flip the switch, ±7 miss, rows stay 56 px. Proof
  live and green (`settings_a11y_test.dart`).
* **P16-B08 is fixed for its picker repro** (`P16TransientGuard`, 300 ms,
  `clock.now()`), but the guard **does not fence the delete row** — filed as
  **P16-B10** below.
* **P16-B09 remains open** (minor, shared): the fix is genuinely unreachable
  from the feature (raw id never reaches the bloc); `SHARED_REQUEST.md` §5
  carries it.
* **P16-B11 is new and major:** the T02 wrapper's `Center` expands into the
  120 px trail cap, so all three switches render **34.5 px left** of the
  design's right-edge position (they matched in iteration 2). The owner
  ALIGNMENT/UI rules make this a UI-verdict failure.
* Verdict: **FAIL** — B11 is a major, open.

| id | severity | status | proof |
|---|---|---|---|
| P16-B11 | **major** | **open (new)** | `[P16-B11] the three switches sit on the row’s right edge` (skipped) |
| P16-B10 | minor | **open (new)** | `[P16-B10] a double tap on Cancel cannot re-open the delete dialog` (skipped) |
| P16-B09 | minor | open (carried, shared §5) | `[P16-B09] the picker shows the device zone for a linked IANA id` (skipped) |
| P16-T02 | major | **fixed iter-3** | `settings_a11y_test.dart` `[P16-T02] …` unskipped, green |
| P16-B08 | minor | fixed iter-3 (picker repro) | `[P16-B08] …` unskipped, green |
| P16-B01…B07 | — | fixed iter-1/2 | all unskipped, green |

## P16-B11 · major · the switches moved 34.5 px off the right edge

**What.** The T02 fix wraps each toggle in
`SizedBox(height: 44, child: Center(child: NestToggle(...)))`
(`settings_view.dart`, Notifications rows). `SettingsRow` caps its trailing
at `NestListRow.trailMaxWidth` (120 px). A `Center` with a finite max width
**expands** to it, so the wrapper becomes 120 px wide and centres the 51 px
track inside it: 34.5 px left of the row's right content edge.

**Measured** (real app, `probe Q`, 390×844 and 320×844):

| row | track | row box | gap to row.right − 16 |
|---|---|---|---|
| Approvals waiting | 268.5–319.5 | 20–370 | **34.5** |
| Payout day reminder | 268.5–319.5 | 20–370 | **34.5** |
| Weekly family summary | 268.5–319.5 | 20–370 | **34.5** |
| at 320 px | 198.5–249.5 | 20–300 | **34.5** |

The design (`components.css:107` `.list-row` padding `10px 16px 10px 12px`,
`:136` `.toggle` 51×31 `flex-shrink: 0`) puts the track's right edge flush at
the row's 16 px right padding — x 303–354 at 390 wide, which iteration 2
matched and the UI stage's iteration-2 remeasure accepted.

**Failing proof:** `[P16-B11] the three switches sit on the row’s right edge`
(skipped) — `Actual: [34.5, 34.5, 34.5]`, expected ≤ 2.

**Suggested fix (screen-local, one line):** make the wrapper shrink-wrap
horizontally so the trailing stays 51 px wide, e.g.

```dart
SizedBox(width: 51, height: 44, child: Center(child: NestToggle(...)))
// or: Align(widthFactor: 1, child: SizedBox(height: 44, child: NestToggle(...)))
```

Then the track's right edge is the row's content edge again and the text
column gets its 69 px back. Re-run the T02 proof after the change (the ±5/±6
slop must stay live).

## P16-B10 · minor · the guard does not fence the delete row

**What.** `P16TransientGuard` fences the picker/nav/toggle rows but not
`_confirmDelete`'s row (Delete family account) nor the Invite co-parent row.
The B08 fall-through therefore still reaches them:

* `/settings` → Delete family account → **Cancel**, then tap Cancel again
  60 ms later → the second tap falls through to the delete row and the dialog
  **re-opens** (`dialog=1`). Same with Delete (toast + re-open).
* Picker double tap on a row whose screen position overlaps the delete row
  (repro: **New York**) → the delete dialog opens (`dialog=1`).

**Failing proof:** `[P16-B10] a double tap on Cancel cannot re-open the delete
dialog` (skipped) — `dialog=1`, expected 0.

**Suggested fix:** wrap the delete row's and the invite row's `onTap` in
`P16TransientGuard.run`, exactly like every other row.

## P16-B09 · minor · linked IANA ids (carried, shared)

Unchanged from iteration 2: `Europe/Amsterdam` (a tzdb link) reads as an
unknown zone, so those phones get no move prompt and no “Current location”
row. ORCHESTRATOR_NOTES item 3 asks for B09 to be closed, but there is no
feature-side hook — `FamilyZoneService.deviceZoneId()` returns null before
the feature sees anything. Fix belongs in `isKnownZoneId`/`normalizeZoneId`
(core `family_time.dart:37-78`), filed as `SHARED_REQUEST.md` §5. The proof
stays skipped with the reason inline.

## Mandatory-item status (`ORCHESTRATOR_NOTES` 06:58)

1. **Revert `_P16Sect` → `NestSectionLabel`, subcard → `NestCard` — NOT
   actioned.** The iteration-3 build deliberately left the three local forks
   and flagged the sequencing: the shared label's 18 px line box and
   `NestCard`'s 24 px radius are exactly what the design does not match, so
   reverting today re-opens the iteration-1 UI drift (`5_ui` measured +1–2 px
   per section). `SHARED_REQUEST.md` §2/§3 carry the measured numbers; the
   reverts become safe once the shared components land. Compliance item for
   the orchestrator, not a screen bug.
2. **44×44 switch target — done.** T02's proof taps 5 px outside the track
   and passes; my measurement shows ±6 live / ±7 dead.
3. **B08 — done** (picker repro). **B09 — blocked** (see above).

## Verified clean this iteration

* T02: ±6 px outside the track flips the switch, ±7 does not; rows stay 56 px
  at 390 and 320; no overflow at 320 @1.3.
* B08: the picker double tap no longer navigates (London/Paris/Karachi/Sydney
  repros stay on `/settings`); the guard window arithmetic and release are
  pinned by the test stage's `p16_transient_guard_test.dart` under an
  advancing clock, and `pumpSettingsApp` resets the static between tests.
* The guard fences rows only: the move banner's Switch / Not now still work
  right after a sheet closes (test stage's proof).
* All iteration-1/2 regression guards still green in
  `p16_bugs_test.dart` (21 unskipped tests): deep links, back nav, empty
  seed, 6 children/long names/coin extremes at 320 @1.3 dark, persistence,
  same-frame double taps, a11y contract, BST offsets, dark contrast.
* `dart format .` 0 changed; `flutter analyze` No issues found; settings
  suite `+131 ~3` on re-run; full suite green apart from the two flakes
  below.

## Observations (not numbered)

1. **Two one-off flakes while the concurrent test stage was editing:** the
   guard file's “the move banner stays operable right after a sheet closes”
   failed in one full-settings run, then passed 3/3 in isolation and on the
   suite re-run; `[P16-B01]` failed in one `--run-skipped` run while the tree
   was mid-edit and passed in the next two. Both are timing-sensitive
   (`scrollSettingsTo` + `pumpAndSettle`), not product races.
2. `payout_view_test.dart` (P13, another feature) failed once in the full
   suite and passes alone — behind-main noise while the branch is unmerged
   (process item).
3. `settings_a11y_test.dart`'s T02 block still opens “P16-T02 open (major…)”
   before saying “FIXED in iteration 3” — stale comment, noted by the build.
4. The B08/B09 header block in `p16_bugs_test.dart` was refreshed this
   iteration; B09's skip is now the only one besides the new B10/B11.

## Gates (snapshot, `app/`)

```
$ dart format .                     # 0 changed
$ flutter analyze                   # No issues found!
$ flutter test test/features/settings/p16_bugs_test.dart
                                    # +21 ~3 (B09/B10/B11 skipped)
$ flutter test test/features/settings/p16_bugs_test.dart --run-skipped
                                    # +21 -3 — all three proofs fail with the
                                    # messages recorded above
$ flutter test test/features/settings
                                    # +131 ~3 on the final run (one flake on
                                    # an earlier parallel run, see obs 1)
$ flutter test                      # +2857 ~4; two one-off failures, both
                                    # green in isolation (obs 1-2)
```

VERDICT: FAIL
