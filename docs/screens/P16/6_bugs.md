# P16 · Family & settings — Stage 6 adversarial bug hunt (iteration 2)

Route `/settings` · feature `settings` · parent mode · design
`design/html-source/screens/P16-settings.html` + light/dark PNGs
(1170×2532 ÷ 3). This stage changed **nothing** in `app/lib/**`; it updated
`app/test/features/settings/p16_bugs_test.dart` (B01–B07 proofs unskipped as
regression guards + two new skipped proofs, B08/B09) and this report. No
simulator was booted, installed on, screenshotted or driven. Tests are pinned
to Sat 3 Oct 2026 by `test/flutter_test_config.dart`.

Tree tested: iteration-2 checkpoint `29b2e2d` with `main` merged in (the
shared `list_row_trailing` fix and `appNowUtc` are in-tree). The concurrent
iteration-2 test/review/UI stages had finished their pass by the snapshot
(`4_review.md` iteration 2 PASS, `5_ui.md` iteration 2 PASS, settings suite
green, `flutter analyze` clean).

## Result

* **All seven iteration-1 findings (P16-B01…B07) are fixed**, each pinned by
  a proof that now runs **unskipped and green** (regression guard).
* **One major remains open: P16-T02** (carried from `3_test`, shared request
  §1). My independent measurement is *stronger* than the recorded one: taps
  1 px above/below the switch track are already dead — the effective target
  is exactly the 51×31 track, against the 44 px owner/spec minimum.
* **Two new minors:** P16-B08 (double tap during a modal's close falls
  through to the row underneath) and P16-B09 (IANA *link* ids like
  `Europe/Amsterdam` are treated as unknown — shared, request §5).
* Verdict: **FAIL** — T02 is a major and is still open.

| id | severity | status | proof |
|---|---|---|---|
| P16-T02 | **major** | open (carried, shared §1) | `settings_a11y_test.dart` `[P16-T02] a switch is live 5 px above and 5 px below its track` (skipped; fails with `--run-skipped`) |
| P16-B08 | minor | **open (new)** | `[P16-B08] a double tap while the picker closes cannot open another screen` (skipped) |
| P16-B09 | minor | **open (new, shared §5)** | `[P16-B09] the picker shows the device zone for a linked IANA id` (skipped) |
| P16-B01 | major | fixed iter-2 | `[P16-B01] …` unskipped, green |
| P16-B02 | minor | fixed iter-2 | `[P16-B02] …` unskipped, green |
| P16-B03 | minor | fixed iter-2 | `[P16-B03] …` unskipped, green |
| P16-B04 | minor | fixed iter-2 | `[P16-B04] …` unskipped, green |
| P16-B05 | minor | fixed iter-2 | `[P16-B05] …` unskipped, green |
| P16-B06 | major | fixed iter-2 | `[P16-B06] …` unskipped, green |
| P16-B07 | blocker | fixed iter-2 | `[P16-B07] …` unskipped, green |

## P16-T02 · major · the switch tap target is 51×31, not 44 px

`NestToggle` is designed as a 51×31 track with a 59×44 hit area
(`_ToggleHitSlop`, `nest_toggle.dart:96-169`), but the hit never reaches it
inside P16's rows. The row is
`ConstrainedBox(minHeight 56) > Material > InkWell > Padding(12,10,16,10) >
Row > ConstrainedBox(maxWidth 120) > NestToggle`; the Row's content box is
36 px, the `ConstrainedBox` around the toggle shrink-wraps to 51×31, and both
gate hits by their own size before `_ToggleHitSlop` runs.

**Measured this iteration** (`probe F2`, `/settings`, Notifications):

| tap | centre | top−5 | top−3 | top−2 | top−1 | bottom+1 | +2 | +3 | +5 |
|---|---|---|---|---|---|---|---|---|---|
| flips? | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

Hit-test path at `track.top − 1` (`probe F3`) contains the row's
`RenderPointerListener/_RenderInkFeatures/RenderFlex` chain and **no toggle
render object**; only the exact 51×31 track reaches
`RenderSemanticsGestureHandler`. Effective target = the track.

**Repro:** real app at `/settings` → Notifications → tap 5 px above the
Approvals track: the DB value does not change.

**Failing proof:** `settings_a11y_test.dart:216`
`[P16-T02] a switch is live 5 px above and 5 px below its track`
(`skip: true`; `flutter test test/features/settings/settings_a11y_test.dart
--run-skipped` fails: `Expected: <false> Actual: <true>`).

**Suggested fix.** The shared fix (SHARED_REQUEST §1) is the clean one: make
the slop live at a box that spans the row, or give `NestListRow` a row-native
44 px minimum tap height. A **screen-local recipe is verified to work** if the
shared change is not merged first: render the three switch rows with P16's
`SettingsRow` at 6 px vertical padding *and* wrap each `NestToggle` in a
44-high box —

```dart
SizedBox(height: 44, child: Center(child: NestToggle(...)))
```

so both the Row (44 px) and the wrapper contain the hit point while the row
stays 56 px. A synthetic replica of the row with that recipe made taps
±6 px live (padding alone does not work — the `ConstrainedBox` around the
toggle still gates).

## P16-B08 · minor · double tap during a modal close falls through

**Repro (real app).** `/settings` → tap **Time zone** → the picker opens →
tap the current-zone row (`London`) → tap the same spot again 60 ms later
(an impatient double tap). The closing sheet stops absorbing pointers before
its exit animation ends, so the second tap lands on the settings row beneath
(the Privacy section at that scroll position) and navigates to `/privacy`.
The same defect on the delete dialog: double-tap **Cancel** 20–260 ms apart
re-opens the dialog (the tap falls through to the “Delete family account”
row); double-tap **Delete** shows the toast *and* re-opens the dialog.
Same-frame double taps are fine (the second pop is absorbed).

**Failing proof:** `[P16-B08] a double tap while the picker closes cannot
open another screen` (skipped) — measured `path=/privacy`, expected
`/settings`.

**Suggested fix (screen-local):** keep a “modal just closed” guard
(e.g. timestamp set when `showNestModal`/`showNestBottomSheet` completes) and
ignore row taps for ~300 ms; or absorb pointers during a route's exit
transition in the shared modal/sheet helpers.

## P16-B09 · minor · linked IANA ids read as “unknown zone”

**Repro.** A phone reporting `Europe/Amsterdam` (a tzdb *link* to
`Europe/Brussels`) gets no move prompt and no picker “Current location” row:
the bundled `package:timezone` `latest_10y` dataset has 341 locations and no
backward links, so `isKnownZoneId('Europe/Amsterdam')` is false and
`FamilyZoneService.deviceZoneId()` returns null. Same for `Asia/Calcutta`,
`US/Pacific`, `Europe/Kiev`, `Asia/Saigon`, … Canonical ids (`Europe/Berlin`,
`Asia/Kolkata`, `Australia/Sydney`) work.

**Failing proof:** `[P16-B09] the picker shows the device zone for a linked
IANA id` (skipped) — measured `deviceRow=0`, expected 1.

**Suggested fix:** resolve backward links to their canonical zone inside
`isKnownZoneId`/`normalizeZoneId` (`app/lib/core/data/family_time.dart:37-78`)
— shared, recorded as SHARED_REQUEST §5. No feature-side workaround exists:
the raw id never reaches the bloc.

## Verified clean this iteration

* **Iteration-1 regressions:** all B01–B07 proofs green unskipped — picker
  keeps the device zone after “Not now”; dismissal survives a rebuilt bloc
  (session store); picker scrolls at 320×568 @1.3; no `DateTime.now()` in
  feature code; “1 coin” singular; subcard r-m 16; delete dialog Cancel
  closes the dialog and keeps `/settings`.
* **New attacks held:** same-frame double taps on the picker row open one
  sheet and never double-pop the branch; the picker at 320×568 @1.3 (light
  and dark) scrolls to every row and Sydney writes; the move banner at
  320 @1.3 lays out (20 px gutters, no overflow); the delete dialog at
  320×568 @1.3 does not overflow; canonical-but-unlisted device zones
  (`Europe/Berlin`) lead the picker; toggle state survives a restart;
  all 13 controls expose a tap action and activation writes the DB; BST
  boundary offsets (`GMT+1`→`GMT+0`); dark-mode text pairs ≥ 4.5:1; 6
  children/long names/0 & 9999 coins at 320 @1.3 dark; deep-link guards
  (kid → gate, onboarding → welcome, trial → paywall); Back pops a pushed
  `/settings`.
* **UI iteration 2** independently re-measured the fixed rows/subcard and
  passed (`5_ui.md`); the shared `list_row_trailing` fix resolved the
  iteration-1 truncation.

## Observations (not numbered)

1. At 320×568 @1.3 the delete dialog's **Cancel** label wraps to two lines
   while **Delete** stays one line (buttons 62 px vs 52 px). Cosmetic, inside
   the `NestButton` wrap-by-design contract; a smaller `horizontalPadding`
   for dialog buttons would even them out.
2. The subcard's `Manage subscription` `InkWell` paints its ripple on the
   Scaffold's Material *behind* the card (no local `Material` between the
   decorated `Container` and the ink) — pre-existing pattern, cosmetic.
3. T02's shared request text records “~36 px (live `track.top − 2`)”; the
   iteration-2 measurement above shows even ±1 px is dead, i.e. exactly
   51×31. The shared fix is unaffected; the write-up is conservative.

## Gates (snapshot, `app/`, ~05:45)

```
$ dart format .                     # 524 files, 0 changed
$ flutter analyze                   # No issues found!
$ flutter test test/features/settings/p16_bugs_test.dart
                                    # +20 ~2 (B08/B09 skipped)
$ flutter test test/features/settings/p16_bugs_test.dart --run-skipped
                                    # +20 -2 — both open proofs fail with the
                                    # messages recorded above
$ flutter test test/features/settings/settings_a11y_test.dart --run-skipped
                                    # +5 -1 — the T02 proof fails as recorded
$ flutter test test/features/settings
                                    # +120 ~3: all non-skipped green
$ flutter test                      # +2848 ~4: all non-skipped green
```

The four skips are exactly: P16-T02, P16-B08, P16-B09 and the pre-existing
`pocket_money/p12_bugs_test.dart` skip (another feature).

## Appendix — iteration-1 findings, all closed

| id | severity | fixed in | live proof |
|---|---|---|---|
| P16-B01 | major | 2a `deviceZoneId` + 2b picker ordering | `[P16-B01] the picker keeps the device zone after “Not now”` |
| P16-B02 | minor | 2a `SettingsSessionStore` | `[P16-B02] “Not now” hides the move prompt for the whole session` |
| P16-B03 | minor | 2b `Flexible` + `SingleChildScrollView` | `[P16-B03] the zone picker scrolls instead of overflowing on 320×568 @1.3` |
| P16-B04 | minor | 2b `appNowUtc()` + main merge for the repo | `[P16-B04] feature code never calls DateTime.now()` |
| P16-B05 | minor | 2b singular copy | `[P16-B05] a single coin reads “1 coin”, not “1 coins”` |
| P16-B06 | major | 2b local `allM` surface container | `[P16-B06] the subscription card uses the design’s 16 px corner radius` |
| P16-B07 | blocker | 2b `rootNavigator: true` pops | `[P16-B07] Cancel closes the delete dialog, never the settings page` |

VERDICT: FAIL
