# Fix list after iteration 2

## From 3_test.md
# P16 Settings — Stage 3 TEST (iteration 2)

Job: re-prove the screen after iteration 2's build, cover the behaviour that
build introduced, and audit the iteration-1 suite for tests that had quietly
stopped testing anything.

**Outcome: FAIL — every gate is green and no new defect was found, but P16-T02
(the 44 px switch tap target I reported in iteration 1) is still open, and the
concurrent bug stage's P16-B08/B09 are open too. All three are skip-marked
proofs that still fail under `--run-skipped`.**

Numbers: **+17 tests** (105 → 122 in `test/features/settings`), **0 new
failures**, **0 new bugs**, **1 of my 2 iteration-1 findings fixed and proved
fixed**, **1 still open**.

---

## 1. What iteration 2 changed, and what that means for the tests

The build stage (see `2_build.md`) landed six bug fixes and three review fixes.
The parts a test suite has to notice:

| change | where | test consequence |
|---|---|---|
| `deviceZoneId` added to the state | `settings_state.dart` | new state contract to pin |
| `SettingsSessionStore` (session-scoped "Not now") | `settings_session_store.dart`, `settings_di.dart` | new DI wiring to prove end to end |
| `_P16Sect` replaces `NestSectionLabel` | `settings_view.dart:63-98` | the shared component is gone from this screen |
| subcard leaves `NestCard` for a `p16_subcard` `Container` (16 px radius) | `settings_view.dart:206-224` | geometry is now found by key, not by type |
| `Semantics(excludeSemantics: true)` on the Manage-subscription row | `settings_view.dart:238-242` | one node instead of two — needs a non-vacuous count |
| coin pluralisation, `appNowUtc()`, picker scroll, root-navigator pop | various | covered by the bug stage's proofs, re-verified live |

### 1.1 A dead assertion in my own iteration-1 suite (fixed)

`settings_responsive_test.dart`'s gutter check iterated
`find.byType(NestSectionLabel)` to assert the ALIGNMENT rule on every section
label. Iteration 2 replaced the shared label with the local `_P16Sect`, so that
finder matched **nothing** and the loop body — and therefore the assertion —
silently stopped running. The ALIGNMENT check still passed, on zero elements.

Fixed: the labels are addressed by their rendered copy
(`kP16SectionLabels` = FAMILY / CHILDREN / SUBSCRIPTION / TIME ZONE /
NOTIFICATIONS / PRIVACY / ABOUT), and the helper now **fails if no label is on
screen**, so a future component swap cannot quietly empty the finder again. The
new typography test below covers the same labels in both themes.

This is the "UI CHECK MEASURES SHAPES" rule biting a test rather than a screen:
a green assertion over an empty finder is the cheapest false PASS there is.

## 2. Tests added in iteration 2

| File | +tests | What it pins |
|---|---|---|
| `settings_responsive_test.dart` | 3 | section-label typography in both themes and both scales (and that the box scales with the text scaler); the `p16_subcard` surface card (16 px radius, `surface`, `sh-1`, 14/16 padding); move-banner gutter + `leafTint` surface now in dark as well as light |
| `settings_a11y_test.dart` | 2 | "Manage subscription" is exactly **one** labelled node with **one** tap action and still navigates; all seven section labels announce a **heading** |
| `settings_navigation_test.dart` | 5 | the zone row is DB-driven (picking Dubai re-renders the subtitle, the old one disappears, no raw IANA id leaks out of the picker); the "Not now" session scope end to end |
| `settings_states_test.dart` | 5 | coin pluralisation driven from the database (0 / 1 / 2 / 120) plus the seeded 120 / 45 |
| `settings_bloc_test.dart` | 2 | `deviceZoneId` survives a dismissal; state equality semantics for the device zone and the dismissal set |

### 2.1 The new local section label, in both themes

`_P16Sect` measures Inter's natural line box with a one-off `TextPainter`,
because the shared `NestSectionLabel` pins an 18 px line box and drifted every
card below it by ~2 px. What a test can and must hold:

- the copy is the design's — upper-cased `.sect` labels, 13 px, w700,
  `letter-spacing: .06em` (0.78 px at 13 px), `ink-2`, one line + ellipsis;
- every label shares the 20 px gutter (the ALIGNMENT rule, now non-vacuous);
- **the box grows with the text scaler**: measured 16 px at scale 1.0 and 21 px
  at 1.3, i.e. ×1.3. A probe measured *without* the scaler would pin the label
  to its unscaled box and clip the glyphs at 1.3 — the exact risk a one-off
  `TextPainter` introduces, so it is now asserted rather than assumed;
- dark mode uses the dark `ink-2`.

### 2.2 Accessibility of the two local re-implementations

- **"Manage subscription"** was wrapped in `Semantics(excludeSemantics: true)` to
  kill the double announcement. The owner rule allows that **only** because the
  wrapper passes `onTap:` itself, so the test asserts all three halves: exactly
  one node announces it, that node exposes `SemanticsAction.tap`, and
  activating it lands on `/paywall`. A regression to two nodes (the old shape)
  or to a wrapper without `onTap:` both fail here.
- **Section labels as headings**: `tester.getSemantics(find.text('FAMILY'))`
  reports `isHeader == true` for all seven. A local component that dropped the
  shared component's `Semantics(header: true)` would leave a screen-reader user
  unable to skim the page by heading, and nothing else would notice.

### 2.3 The move prompt is once per session, proved through the real route

Iteration 1 could only test "Not now" inside one bloc's lifetime; iteration 2
moved the dismissal into a DI singleton, which is a wiring claim, not a logic
claim. Three tests close that gap:

1. **"Not now" survives leaving and re-entering `/settings`** — dismiss, assert
   the banner is gone and the family zone is untouched (nothing is written),
   assert the zone landed in `GetIt.instance<SettingsSessionStore>()`, then
   `go('/paywall')` and `go('/settings')` (which rebuilds the page and therefore
   builds a **new** route-scoped bloc) and assert the prompt has not returned.
2. **A bloc built the way the route builds it inherits the dismissal** —
   `GetIt.instance<SettingsBloc>()..add(SettingsLoadRequested())` with no store
   passed in, exactly as `settingsRoute`'s `BlocProvider` does. Asserts
   `pendingZone == null` *and* `deviceZoneId == 'Asia/Dubai'`: the banner is
   quiet while the picker still knows where the phone is (P16-B01's two halves
   in one state).
3. **The picker still leads with the device zone after a dismissal** —
   `Asia/Dubai · Current location` plus exactly one `Dubai` row.

### 2.4 Data-driven rows (DATA OVER MOCKS)

The coin noun was pluralised in iteration 2. The bug stage pins the singular;
the suite now pins the **rule** from the database — write 0, 1, 2 and 120 coins
to Leo and assert `Pip: Hatchling · 0 coins` / `1 coin` / `2 coins` /
`120 coins` — and separately that the demo seed keeps the design's 120 / 45
(RULES §4).

The zone row is pinned the same way: after picking Dubai the subtitle must
re-render to `Dubai (GMT+4)` **and** the old `London (GMT+1)` must be gone (two
subtitles would be a stale row, not a live one), and `Asia/Dubai` must not
appear outside the picker (ORCHESTRATOR_NOTES copy rule).

### 2.5 State-level contracts

- `copyWith(clearPendingZone: true)` must keep `deviceZoneId` — the picker reads
  it after a dismissal; losing it with the banner is P16-B01.
- states differing only in `deviceZoneId` are unequal (props carry it), while
  two states with equal-content `dismissedZones` **are** equal — Equatable uses
  a deep collection comparison, so the Set in `props` is not compared by
  identity. I probed this before writing it down: my first hypothesis (identity
  comparison causing needless rebuilds) was wrong, and nothing is reported.

## 3. Results

```
$ dart format .
Formatted 524 files (0 changed) in 3.41 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 7.2s)

$ flutter test test/features/settings
00:15 +122 ~3: All tests passed!

$ flutter test
02:37 +2850 ~4: All tests passed!
```

| tree | `test/features/settings` | full suite |
|---|---|---|
| iteration-2 build checkpoint (`29b2e2d`) | `+105 ~1` | `+2833 ~2` |
| after this stage | `+122 ~3` | `+2850 ~4` |

`+17` passing tests, **zero failures**. The two extra skips are the concurrent
bug stage's newly pinned P16-B08 / P16-B09, not mine. No behind-`main` noise
left this iteration (the loop merged `main`), so unlike iteration 1 there is no
baseline to subtract — the suite simply runs green.

Honesty check on the skips — `flutter test test/features/settings --run-skipped`
fails **exactly** on the three open proofs and nothing else:

```
[ P16-T02 ] a switch is live 5 px above and 5 px below its track   (settings_a11y_test.dart, mine)
[ P16-B08 ] a double tap while the picker closes cannot open another screen   (p16_bugs_test.dart)
[ P16-B09 ] the picker shows the device zone for a linked IANA id            (p16_bugs_test.dart)
```

## 4. Bugs

### 4.1 Still open — P16-T02 (major, owner rule: parent tap targets ≥ 44 px)

`app/lib/features/settings/presentation/views/settings_view.dart:237`, `:248`,
`:258` (a `NestToggle` in the shared `NestListRow`) with
`app/lib/core/design_system/components/nest_list_row.dart:53`
(`EdgeInsets.fromLTRB(12, 10, 16, 10)`).

Unchanged from iteration 1: `NestToggle` extends its hit area 6.5 px above and
below the 31 px track via `_ToggleHitSlop`, but the row's 10 px vertical padding
leaves the switch inside a 36 px content box, and a padded ancestor forwards no
hit outside its own box. Measured live range: `track.top − 2 … track.bottom + 2`
— an effective target of ≈ 36 px against the 44 px rule.

**Repro:** real app at `/settings`, scroll to Notifications, tap 5 px above the
first switch's track → nothing happens; the same tap on the track flips the row.
Proof: `settings_a11y_test.dart`, `[P16-T02]`, run with `--run-skipped`.

Iteration 2 re-measured this rather than re-copying iteration 1: the build's
"6 px row padding" idea does not restore the slop for a title-only row either
(noted in the proof's comment), and the fix is filed as
`SHARED_REQUEST.md` §1 — the ownership is the shared `NestToggle` +
`NestListRow` pair, which RULES §1 forbids P16 from editing.

### 4.2 Fixed and proved fixed — P16-T01 (iteration 1 blocker)

Both delete-confirm buttons now pop the root navigator
(`settings_view.dart:381` and `:390`), where `showNestModal`'s `Dialog` lives.
My two proofs are live again (`skip: false`) and green, and they assert the fix
did not go green by accident: Cancel leaves the family zone, the children and
the settings row untouched and the path at `/settings`; Delete confirms, toasts
`Family account deletion is not available yet` and still writes nothing. The
stale "OPEN BUG" comments above both tests were rewritten to say so.

### 4.3 Open, found by the concurrent bug stage (not this stage's tests)

Listed so the picture is complete; both are skip-marked in `p16_bugs_test.dart`
and both fail under `--run-skipped`.

- **P16-B08** (minor) — a double tap during a modal's close animation falls
  through to the screen beneath; the picker repro lands on `/privacy`.
- **P16-B09** (minor, shared) — linked IANA ids (`Europe/Amsterdam`,
  `Asia/Calcutta`, …) are rejected by `isKnownZoneId` because the bundled
  `latest_10y` dataset ships no links, so those phones get no prompt and no
  "Current location" row. `SHARED_REQUEST.md` §5.

### 4.4 Observations carried forward (not bugs)

1. **CLOCK rule is now clean in the feature**: `grep DateTime.now()
   lib/features/settings/` → 0 hits (both view call sites read `appNowUtc()`),
   and the tests pin expectations to `p16PinnedNowUtc` rather than the wall
   clock. Nothing outstanding.
2. **The Family list is still one announcement.** Its two static rows (Sarah,
   James) have no `Semantics` node of their own, so a screen reader announces
   `"Sarah — you / sarah@example.co.uk / James — co-parent / Invited · awaiting
   reply / Invite co-parent"` as one button and cannot stop on Sarah alone.
   Unchanged by iteration 2; a `Semantics(container: true)` on the static rows
   fixes it, in the shared `NestListRow` no-`onTap` branch.
3. **Shared wart, blast radius still pinned** by
   `settings_a11y_test.dart`: the only unlabelled tappable nodes on the screen
   are the three switch tracks (the `Semantics(label:) > InkWell` construction
   that /today and P14 have too).
4. **`_P16Sect` runs a `TextPainter.layout()` on every build** — six labels per
   rebuild, and the bloc re-emits on every settings write. Not a correctness
   problem and not measured as a cost; a cached ratio would be free, so it is
   noted rather than filed.
5. **`sarah@example.co.uk` is still hard-coded copy** (`settings_view.dart:419`)
   — the `members` table has no email column (review 6, `SHARED_REQUEST.md` §4).
6. **Three local re-implementations of shared components** (`SettingsRow`, the
   `p16_subcard` `Container`, `_P16Sect`) remain — deliberate, because the
   shared defaults cannot express the design without editing `core/`
   (review 7, `SHARED_REQUEST.md` §2 and §3). The tests in §2.1 and §2.2 are
   what keep those local copies honest in the meantime.
7. **`.ptitle` declares no `text-wrap: balance`** in
   `design/html-source/screens/P16-settings.html:3` (`.h1` does, in
   `components.css:29`), so the title is a plain `Text` with `NestType.h1`,
   consistent with the CSS as written. Its metrics are pinned by
   `settings_responsive_test.dart`.

## 5. Harness notes (additions to iteration 1's §5)

- **`scrollUntilVisible` only scrolls down.** Asking it for a target above the
  current offset fails with `Bad state: No element` after its scroll budget
  runs out. Measure what you need before scrolling to it, or scroll to the row's
  *title* so the rest of the row comes with it.
- **`SemanticsFlags.isHeader` is a `bool` in this Flutter version, while
  `isToggled` / `isEnabled` are `Tristate`.** Comparing `isHeader` with
  `Tristate.isTrue` fails with `Expected: Tristate:<Tristate.isTrue> Actual:
  <true>`.
- **Walking the semantics tree from `rootSemanticsNode` misses nodes that have
  not been through a semantics pass yet** — it reported zero headings on a
  screen that has seven. Address nodes directly with
  `tester.getSemantics(find.text(...))`. (I nearly filed "no headings" as a
  bug on the strength of the walk; the direct query disproved it.)

---


## From 6_bugs.md
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

