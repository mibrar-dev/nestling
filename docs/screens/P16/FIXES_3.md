# Fix list after iteration 3

## From 3_test.md
# P16 Settings — Stage 3 TEST (iteration 3)

Job: re-prove the screen after iteration 3's build, cover the code that build
introduced (`P16TransientGuard`, the T02 row rework), and audit my own suite
for blind spots.

**Outcome: FAIL — every gate is green and my two iteration-1 findings are both
closed, but the iteration-3 build introduced a new major defect (P16-B11, the
switch alignment regression) which I reproduced independently, and two
bug-stage findings (B09, B10) are open. All four open proofs are skip-marked
and all four fail under `--run-skipped`.**

Numbers: **+8 tests** (my files: 110 passing + 1 skip), **0 new failures**,
**0 new bugs of my own**, **1 new major bug confirmed** (found by the bug
stage, reproduced here), **both my earlier findings proved fixed**.

---

## 1. What iteration 3 changed

| change | where | what a test has to say about it |
|---|---|---|
| **P16-T02 fixed** — switch rows use `SettingsRow` at 6 px padding + `SizedBox(height: 44, Center(…))` | `settings_view.dart:286-345` | the ±5 px taps now pass; the recipe needs pinning so it can't be half-applied |
| **`P16TransientGuard`** — new widget-fencing helper (B08) | `p16_transient_guard.dart` | brand-new code that shipped with **no test of its own** |
| every page row's `onTap` now routes through `P16TransientGuard.run` | `settings_view.dart` (7 rows + 3 toggles) | a static, process-wide 300 ms window is the easiest thing in the feature to break silently |
| B09 linked-IANA ids | — | correctly not fixed (shared); still skip-marked |

## 2. Tests added (8)

### 2.1 `p16_transient_guard_test.dart` (new file, 7 tests)

The guard is a `static DateTime?` plus a 300 ms window — two failure modes no
existing test can see:

- **the window never expires** → every row on /settings goes dead for the rest
  of the session, and no other test notices because each one opens the screen
  fresh;
- **the guard leaks into the next test** → the next test's first row tap is
  silently swallowed and looks like a broken screen.

Three unit tests drive it through an injected clock (`Clock(() => now)`), so
the boundaries are exact rather than animation-dependent:

- the window is 300 ms and expires **inclusively**: true at +299, true at
  exactly +300, false at +301;
- `run()` swallows inside the window and passes outside it — and an unarmed
  guard is a pure pass-through;
- `reset()` clears it (the cross-test leak).

This doubles as the CLOCK-rule proof: the guard reads `clock.now()`, which is
why the test can move time at all.

Four widget tests on the real screen:

- **closing the picker arms the guard** — asserted **one frame** after the tap,
  before any settle. `_ZoneRow.onTap` arms synchronously before popping; a
  `pumpAndSettle` lets the exit animation push the fake clock past 300 ms and
  the window is legitimately over again, so asserting after a settle tests
  nothing. (I got that wrong first and the failure was correct.)
- **a fenced row tap does nothing, and the row works again once the window
  passes** — the "stuck guard" regression, end to end on a real row.
- **an unarmed screen navigates on the first tap** — the control case, so the
  test above can't pass by accident.
- **the move banner stays operable inside the window** — `Not now` works
  immediately after a sheet closes. The guard fences page rows only; fencing
  the banner's Switch / Not now would strand the prompt and break
  ORCHESTRATOR_NOTES' "never switch without the confirm tap".

### 2.2 `settings_responsive_test.dart` — `[P16-B11]`, +1 test

**The switch alignment regression.** The iteration-3 T02 fix wrapped each
`NestToggle` in `SizedBox(height: 44, Center(…))`. A `SizedBox` with only a
height takes the full width the parent allows — `NestListRow.trailMaxWidth`
(120) — so the `Center` parks the 51 px track in the middle of that box.

Measured here, independently, at 390 px light: track at **x 268.5–319.5**, the
row's content edge at **354** (370 − 16) → a **34.5 px** gap; the same 34.5 px
at 320 px. My proof widens the bug stage's 390-only check to **320 / 390 / 430
× light / dark** (six measurements), so the eventual fix has to be right at
every width, not just the design width. Skip-marked with the reason inline; it
fails with `gaps={… 320 switch 0: 34.5, …}`.

**And the honest admission this forces.** My iteration-2 responsive sweep
asserted each switch's **size** (51×31) at every width but never its
**position** — so a 34 px horizontal regression passed green through two
iterations of UI checks. Trailing-slot x is now measured, and the owner's
ALIGNMENT rule is in the sweep rather than in someone else's file.

## 3. Existing tests strengthened (3)

1. **The T02 proof now pins the mechanism, not just the taps** — the switch row
   is still a **56 px** design row (same as every other row on the page), its
   padding is the 6 px variant, the track is 51×31, and the 44-high wrapper is
   really present. Padding alone was measured insufficient in iteration 2, so
   dropping either half must fail loudly. I also rewrote the stale comment the
   integrator flagged (it opened "P16-T02 open (major…)" and then said "FIXED
   in iteration 3") — that file is mine and the wording was mine.
2. **The subscription card is addressed by copy, not by key.** A new
   `subscriptionCard()` helper finds it through
   `Nestling Annual · £29.99/year`, so the ORCHESTRATOR_NOTES (06:58) item-1
   revert — subcard back to the shared `NestCard` — fails with a *design*
   message (24 px radius, 16 px padding) instead of "found 0 widgets with key
   `p16_subcard`". The assertions still carry the design numbers, because that
   is exactly the evidence `SHARED_REQUEST.md` §3 needs.
3. **`pumpSettingsSurface` clears the guard too.** The builder added
   `P16TransientGuard.reset()` to `pumpSettingsApp` when B08 landed; the
   direct-pump helper (used by the loading/failure tests) had been left out.
   Nothing failed today because those tests only read the screen — it is a
   latent trap, now closed. Also added `scrollSettingsUpTo` (see §6).

## 4. Results

```
$ dart format .
Formatted 526 files (0 changed) in 1.54 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.8s)

$ flutter test test/features/settings
00:12 +131 ~4: All tests passed!

$ flutter test
01:21 +2859 ~5: All tests passed!
```

| tree | `test/features/settings` | full suite |
|---|---|---|
| iteration-3 build checkpoint (`7160fff`) | `+124 ~1` | `+2852 ~2` |
| after this stage | `+131 ~4` | `+2859 ~5` |

Zero failures. My files now hold **110 passing + 1 skip**:

| file | passed | skipped |
|---|---|---|
| `p16_transient_guard_test.dart` (new) | 7 | 0 |
| `settings_responsive_test.dart` | 14 | 1 |
| `settings_a11y_test.dart` | 12 | 0 |
| `settings_navigation_test.dart` | 19 | 0 |
| `settings_states_test.dart` | 11 | 0 |
| `settings_bloc_test.dart` | 29 | 0 |
| `settings_view_test.dart` | 8 | 0 |
| `settings_repository_test.dart` | 10 | 0 |

The branch is 16 commits behind `main` at the time of writing (the loop's
merge-order item); it produces no test noise here, so there is no baseline to
subtract — the suite simply runs green.

**Skip honesty.** `flutter test test/features/settings --run-skipped` fails on
exactly the four open proofs and nothing else:

```
p16_bugs_test.dart         [P16-B09] the picker shows the device zone for a linked IANA id
p16_bugs_test.dart         [P16-B10] a double tap on Cancel cannot re-open the delete dialog
p16_bugs_test.dart         [P16-B11] the three switches sit on the row’s right edge
settings_responsive_test   [P16-B11] the switches sit flush with the row trailing edge   (mine, widened)
```

## 5. Bugs

### 5.1 Closed — P16-T02 (major, 44 px tap targets) — **mine, iterations 1-2**

`settings_view.dart:286-345`: the three switch rows now use `SettingsRow` at
6 px vertical padding (content box 56 − 12 = 44) with each `NestToggle` in a
`SizedBox(height: 44, Center(…))`. My proof is live (`skip: false`) and taps
**5 px** outside the track on both edges — stricter than the 4 px the
orchestrator's note asks for — asserting the **database row** flips, and it now
also pins the mechanism so the recipe cannot be half-applied. Confirmed.

### 5.2 Open — P16-B11 (major, owner ALIGNMENT rule) — **new in iteration 3**

`app/lib/features/settings/presentation/views/settings_view.dart:289-296`
(and the same shape at `:300-307` and `:311-318`).

`SizedBox(height: 44, Center(child: NestToggle(...)))` takes the full width the
Row's `Flexible` allows (`NestListRow.trailMaxWidth` = 120), so the 51 px track
is centred in a 120 px box: measured **x 268.5–319.5** where the design puts
it flush with the row's 16 px trailing inset (**x 303–354**), a 34.5 px gap at
both 320 and 390.

**Repro:** real app at `/settings` (any width), scroll to Notifications,
compare the switch's right edge with the row's content edge 16 px in from the
card's right edge — or run
`flutter test test/features/settings/settings_responsive_test.dart --run-skipped`.

Fix (the bug stage's): make the wrapper shrink-wrap horizontally —
`SizedBox(width: 51, height: 44, child: Center(child: toggle))`, or an
`Align(widthFactor: 1, …)`. Note the fix must keep the 44-high box, or T02
re-opens: the two findings are the same code.

### 5.3 Open, found by the bug stage (not this stage's tests)

- **P16-B10** (minor) — the B08 guard fences the nav rows but not the delete
  row's `onTap` (nor the Invite co-parent toast row), so the fall-through
  double-tap can still reach them.
- **P16-B09** (minor, shared) — linked IANA ids read as unknown against the
  links-less `latest_10y` dataset, so those phones get no prompt and no
  "Current location" row. Unreachable from the feature; `SHARED_REQUEST.md` §5.

### 5.4 Observations carried forward (not bugs)

Unchanged from iteration 2 and still open elsewhere: the Family list's two
static rows merge into the Invite button's announcement (shared
`NestListRow`); the shared `Semantics(label:) > InkWell` wart, blast radius
pinned by `settings_a11y_test.dart`; the hard-coded `sarah@example.co.uk`
(`SHARED_REQUEST.md` §4); `_P16Sect` / the subcard / `SettingsRow` local forks
and the ORCHESTRATOR_NOTES item-1 sequencing (`SHARED_REQUEST.md` §2, §3);
`_P16Sect`'s per-build `TextPainter` (accepted, documented); `.ptitle` declares
no `text-wrap: balance`, so the title is a plain `Text` by design.

One new observation, cosmetic: a fenced tap gives the user **no feedback at
all** — the `InkWell` ripples and the handler silently returns. Inside a
300 ms window after closing a modal that is defensible, but if the guard is
ever wired to a longer window it becomes a silent dead tap. Not filed.

## 6. Harness notes (additions to iterations 1-2 §5)

- **`Clock.fixed` takes a value, not a callback** — use `Clock(() => now)` for
  a mutable clock (`package:clock`).
- **A `ListView` row can be un-built by scrolling away from it.** After
  scrolling down and back up with a fixed drag, `ensureVisible` can throw
  `Bad state: No element` for a widget that "should" be near the top — the
  element was disposed. Added `scrollSettingsUpTo` (a negative delta flips
  `scrollUntilVisible`'s direction) instead of hand-rolled drags.
- **Never settle before asserting a time-windowed guard.** `pumpAndSettle`
  advances the fake clock past a 300 ms window; the guard is then correctly
  inactive and the assertion proves nothing.
- **`testWidgets(skip: …)` takes a `bool`**, so the reason goes in a comment.

---


## From 6_bugs.md
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

