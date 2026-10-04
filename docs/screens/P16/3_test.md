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

VERDICT: FAIL