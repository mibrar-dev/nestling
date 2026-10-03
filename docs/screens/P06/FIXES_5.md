# Fix list after iteration 5

## From 4_review.md
# P06 Pocket money setup — QA code review (Stage 4, iteration 5)

Reviewed `git diff main...HEAD` per `docs/ARCHITECTURE.md` (feature-first,
domain = entities + abstract repo only, BLoC per screen, DI/routes per
feature), `docs/screens/RULES.md` (edited only allowed paths), the design
system in `app/lib/core/design_system/` (no hard-coded colours/sizes/fonts;
components reused), `docs/DESIGN_SPEC.md §5 P06` (all elements, copy
verbatim, UK spelling), accessibility, performance (no rebuild storms, const
widgets, streams disposed), error handling and Children's Code hygiene. No
code was edited.

## Method

| Check | Result |
|---|---|
| `git diff --name-only main...HEAD` | 11 files, all inside `app/lib/features/pocket_money/**` and `app/test/features/pocket_money/**` ✔ |
| `dart format --output=none --set-exit-if-changed` on the 11 files | 0 changed |
| `flutter analyze` (full app) | **No issues found** (rerun this stage) |
| `flutter test test/features/pocket_money/` (iteration 4 state, 8271af9) | `+136 ~1: All tests passed!` |
| Stage-6 probe `app/test/features/pocket_money/zz_p06_s6_probe_test.dart` (root-cause only) | passed, numbers quoted below |
| design PNG re-scan (`design/screens/light/P06-pocket-money.png`, ÷3) | exactly as iteration 4 |

Design hooks (logical px, ÷3): scroll top 107 · H1 68 tall (107–175) ·
option cards 191/263/335, each 64 · settings card **415–684** · `Payout day`
431–449 · **chips 455–486 (32)**, x 36–353 · divider 495 · `Weekly base`
503–521 · Maya 523–567 · Leo 567–611 · divider 620 · coin row 628–672 ·
CTA top border **685**.

## Findings

### 1. MAJOR — the H1 renders one line + ellipsis (`How does pocket mone…`) in both themes, instead of the design's two balanced lines
`app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:143-147`

`_SetupTitle` invokes `NestBalancedText('How does pocket money work in your
house?', style: context.nestText.h1, textAlign: TextAlign.left)` with the
widget's **defaults** `overflow: TextOverflow.ellipsis`, `maxLines: null`.
Those defaults are what break it:

* `NestBalancedText.build` (`nest_balanced_text.dart:115`) first calls
  `lineCountFor`, which hard-codes `ellipsis: '…'`
  (`nest_balanced_text.dart:52`). With an ellipsis painter, any text wider
  than one line yields *one* line and `didExceedMaxLines=true`, so
  `minLines` comes back **1** — the guard at `nest_balanced_text.dart:123`
  then returns the plain `_text()` immediately.
* That plain `_text()` itself carries the same defaults
  (`overflow: TextOverflow.ellipsis`, `maxLines: null`), so the rendered
  paragraph also marks the line as exceeded and draws `…` after the first
  fitted line.

Probe evidence at 390×844 (`zz_p06_s6_probe_test.dart` probes, run this
stage, passing): `PROBE h1 widget: softWrap=true maxLines=null
overflow=TextOverflow.ellipsis textAlign=TextAlign.left`;
`PROBE h1 paragraph size=Size(350.0, 34.0)`; a plain painter at the same
width yields 2 lines; `lineCountFor` returns 1; the real H1 rect is
`Rect.fromLTRB(20.0, 107.0, 370.0, 141.0)` — 34 tall, one line, ellipsized.
Everything below is shifted up one line-height (34 px): the settings card
measures `Rect(20, 381, 370, 651)` instead of the design's 415–684. Both
`app_light_5.png` and `app_dark_5.png` (8271af9) show the exact artifact,
and `5_ui.md` deviation 1 flags it as BLOCKER.

**Fix** — on the screen, stop relying on the collapsing defaults: hand the
heading a wrap-safe overflow so it wraps like the design, e.g.

```dart
NestBalancedText(
  'How does pocket money work in your house?',
  style: context.nestText.h1,
  textAlign: TextAlign.left,
  overflow: TextOverflow.clip, // no ellipsis → wraps to the design's 2-line break
),
```

(With the ellipsis painter suppressed the 390 dp break is the design's
`How does pocket money / work in your house?`; probe `variant=none lines=2`
is the same input.) Also add a SHARED_REQUEST for the shared component:
`NestBalancedText.lineCountFor` must not hard-code `ellipsis: '…'` (it makes
every long text measure as one line), and the widget's default overflow
should not turn a wrap-shaped heading into an ellipsized single line.

### 2. MAJOR — the mandated real-fonts geometry test that pins the drift-fixed y values is absent
`ORCHESTRATOR_NOTES.md` "UPDATE (07:22)" requires literally: *"Add a geometry
test with real fonts (FontLoader, as app/test/features/privacy_consent/privacy_consent_geometry_test.dart
does) that pins these y values at 390×844."*

No file in `app/test/features/pocket_money/**` mentions `FontLoader`
(grep returns empty). Only fuzzy widths/relationships are asserted under the test
font (`pocket_money_setup_view_test.dart:1146-1250`), which cannot catch an
Ahem-fallback drift. The exact vertical anchors that had to be repaired
(`Payout day` label → chip row gap 6, `Weekly base` label, divider spacing,
coin row, card bottom ≈ 684, CTA border ≈ 685) are nowhere pinned.
`zz_p06_s6_probe_test.dart` currently in the worktree (probe, deleted
before the stage's end) *does* produce the numbers — fold them into
`app/test/features/pocket_money/pocket_money_setup_geometry_test.dart`
(Inter/Nunito via `FontLoader('Inter')`/`('Nunito')` as
`privacy_consent_geometry_test.dart:24-37`, `setUpTestScope`,
`pumpAppRoute(tester, '/pocket-money-setup')` with the
`onboarding_kids` shoot seed, then pin `Rect` heights/y-values to the design
table above).

### 3. MAJOR — stepper minus glyph is the wrong character; the mandatory fix is missing entirely (even as a shared request)
`app/lib/core/design_system/components/nest_stepper.dart:32` still renders a
plain `'-'` (ASCII 45, short hyphen) for the minus button, and the feature
neither overrides the glyph (the `NestStepper` constructor exposes only
labels/onDecrease/onIncrease/valueText) nor filed a SHARED_REQUEST.
`design/html-source/screens/P06-pocket-money.html:73` uses `&minus;`, i.e.
`−` (U+2212). The probe renders `stepper glyphs: minus=- ([45])`.
The 07:22 orchestrator note is explicit: *"Stepper glyphs: the design's minus
is '−' (U+2212)… Use the same icon/glyph source for − and + so they match in
weight and width; check the HTML for the exact glyph."*

**Fix** — add a SHARED_REQUEST item asking `NestStepper` to emit `−`
(U+2212) for the minus button so both stepper arrows share weight/width, and
link it to a geometry check. Do **not** paste a custom glyph into the view.

### 4. MINOR — the `Semantics(container: true, label: 'Payout day')` group label was dropped
In iteration 4 the day row wrapped its chips in a group
(`Semantics(container: true, label: 'Payout day')` at
`pocket_money_setup_view.dart`'s old `_DayRow`) matching the HTML's
`<div class="day-row" role="group" aria-label="Payout day">`. The
iteration-5 rewrite returns `NestChipWrap` directly from `_DayRow`
(`pocket_money_setup_view.dart:~507-524`) to free the `±6 px` tap slop from
the `RenderProxyBoxWithHitTestBehavior` wrapper — understandable — but the
cells now announce as bare `Mon`, `Tue`, …. Fix: give each day-cell
`Semantics` a label that carries the section, e.g.
`label: 'Payout day: Mon' … 'Payout day: Sun'` (`_DayCell` at
`pocket_money_setup_view.dart:~560-571`), or merge the section label into
each chip's `button` + `selected` announcement. Either restores the grouping
without reintroducing the hit-test container.

### 5. MINOR — invented empty-state copy still unratified
`'Add children to set weekly amounts.'` (`pocket_money_setup_view.dart:455-459`)
has no source in `DESIGN_SPEC.md §5` / the HTML source. Iteration-5
`2_build.md` says it is "FLAGGED — needs orchestrator ratification" and the
orchestrator note no longer mentions it. Keep as a finding-to-be-ratified,
not a fix.

## Verified OK (no action at this review)

* **RULES §1 scope** — every diff file is inside the feature + its test
  folder + `docs/screens/P06/**`. No `core/`, `app/`, `tools/screens`,
  `analysis_options.yaml`, no `flutter clean`, no `flutter run` by any stage
  (screenshots via `shot.sh` on the allowed simulator `BC440E48-…`).
* **ARCHITECTURE** — feature-first with the prescribed split; domain holds
  `pocket_money_setup.dart` (entity) + `pocket_money_repository.dart` (abstract
  with only stream/Future + entity types); one `PocketMoneyBloc` per screen;
  DI/routes per feature unchanged.
* **Copy / UK spelling** — `How does pocket money work in your house?`,
  `Weekly amount`, `A set amount every week`, `Earn per quest`,
  `Coins turn into pence at payout`, `Both`,
  `Weekly base + bonus for extra quests`, `Payout day`, `Weekly base`,
  `Coin value`, `10 coins = 10p`, `Nestling never holds or moves money. You pay
  your way; we keep score.`, `Continue`, `Back` — character-exact vs the HTML
  (5_ui also confirms end-to-end).
* **Data over mocks + child order** — the supposed authoritative figures still
  come from the seeded DB (`Seed.onboardingKids`, UI-checked `£3.00`/`£1.50`),
  children combineLatest2 `watchSetup` in insertion order via the new
  `ORDER BY rowid` customSelect (which reverted the unused `settings`
  subscription — review #9 fixed).
* **Tokens-only colours/sizes** — no hard-coded colour literals in the diff;
  every pill/card/border/text style routes through `context.nest` /
  `NestType`/`NestSpacing`/`NestRadii`/`NestDevice`; new literals (13/22/200/60/300/50/2000)
  are carried in `SHARED_REQUEST.md` #2 + doc notes, i.e. blocked on shared work
  rather than forking.
* **CHIP ROWS / re-render contract** — the day strip is now a direct
  `NestChipWrap` child of the card `Column` (no `Padding`/`SizedBox`/
  `Semantics` compressor above it), the tight wrap that once blocked the 5-px
  slop taps is gone, and the 5-px-above/below tap guards (view_test :870/:902)
  stay green.
* **BOTTOM EDGE (owner)** — CTA panel surface reaches the physical edge in
  both themes; `NestHomeIndicator` paints no area; no page-colour strip
  (inherent to `NestBottomCta`'s `SafeArea(top: false)` + paper scaffold
  unchanged).
* **Performance / lifecycle** — `BlocBuilder.buildWhen` (setup/status/
  errorMessage only) means ledger-only emissions no longer rebuild the form —
  review #14 fixed; review #10 `emit.isDone` guards are in; review #5/#6
  `w600` 16/22 `.amount-name` metrics and a `tokens.leaf` spinner are in;
  review #12 `ArgumentError` past `assert` is in; review #13's stale
  `P06-BUG-04` skip was replaced by a deleted proof so the feature contains no
  real `skip:`; review #4's six real-DB teardowns now call
  `disposeApp(tester)` (45 call-sites, no `pumpWidget(SizedBox.shrink())` left).
* **ERROR HANDLING / privacy** — load failure shows the message + `Retry`; a
  failed write keeps the form, paints `danger`, clears on recovery; no
  network, no `print`/`debugPrint` in the feature or its tests, no child
  identifiers outside the local DB, no kid-mode surface, `google_fonts` /
  `GoogleFonts` absent.

## Notes on the worktree (not findings; process owned elsewhere)

* `zz_p06_s6_probe_test.dart` is a raw "`PROBE`" dump from stage 6's
  frontier and is uncommitted alongside edits to
  `pocket_money_setup_view.dart` / `…_view_test.dart` (it dumps the exact
  numbers being reported above). It is process state, not a diff item; its
  numbers are the *evidence* for findings 1 and 2 and should be folded into
  the real geometry test, then the file must be deleted before branch merge.
* `SHARED_REQUEST.md` item 3 (BALANCED HEADINGS blocked on a main merge) is
  now stale in wording — the component *is* merged (`88c2132` is now an ancestor
  of `HEAD`) — but the *reason* is real: that component's own defaults are the
  breaking part, so item 1's fix becomes the request above.


## From 5_ui.md
# P06 Pocket money setup — UI check (Stage 5, iteration 5)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode ·
seed `onboarding_kids` · child `maya` (populated: Maya £3.00, Leo £1.50).
Simulator UDID `BC440E48-B3A3-43BC-971B-0EF5DB621874` (390×844, same as designs).
No Pip on this screen (P01–P07 onboarding rule). No `ORCHESTRATOR_NOTES.md` exists.

## Shots (per stage)

- `bash tools/screens/shot.sh "$PWD/app" /pocket-money-setup "$PWD/docs/screens/P06/ui/app_light_5.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light onboarding_kids parent maya` → stable frame saved.
- Same with `dark` → `docs/screens/P06/ui/app_dark_5.png`.
  (Absolute `OUT` paths: `shot.sh` `cd`s into the app dir before copying, so a
  relative `OUT` resolves inside `app/` and the copy fails.)

## Compares

- `python3 tools/screens/compare.py design/screens/light/P06-pocket-money.png docs/screens/P06/ui/app_light_5.png docs/screens/P06/ui/cmp_light_5.png`
- `python3 tools/screens/compare.py design/screens/dark/P06-pocket-money.png docs/screens/P06/ui/app_dark_5.png docs/screens/P06/ui/cmp_dark_5.png`

Mean diff: light **6.11%**, dark **6.08%** (up from 2.22%/2.14% in iteration 4).

Band tables (8 horizontal bands, 0 = top):

Light:

```text
mean diff: 6.11%
band  y-range    diff%
  0      0-105    1.62%
  1    105-211    8.71%
  2    211-316   10.47%
  3    316-422   10.32%
  4    422-527    7.49%
  5    527-633    5.28%
  6    633-738    2.76%
  7    738-844    2.25%
```

Dark:

```text
mean diff: 6.08%
band  y-range    diff%
  0      0-105    1.59%
  1    105-211    8.81%
  2    211-316    9.87%
  3    316-422   10.99%
  4    422-527    6.61%
  5    527-633    5.18%
  6    633-738    3.21%
  7    738-844    2.38%
```

Read `docs/screens/P06/ui/cmp_light_5.png`, `cmp_dark_5.png`,
`app_light_5.png`, `app_dark_5.png` against
`design/screens/light|dark/P06-pocket-money.png` and
`design/html-source/screens/P06-pocket-money.html`. Bands 1–4 heat is dominated
by deviation 1 (H1 collapse shifts every row below it).

## Element-by-element (design vs app, light + dark unless noted)

Checked: presence, order, copy (character-by-character vs HTML source),
spacing (±2 px logical), sizes, 20 px gutters / alignment, colours, radii,
shadows, icon choice, overflow/clipping/ellipsis, dark-mode colours, bottom
edge, status-bar rule. Pill/chip/button/card BACKGROUND/BORDER rects compared,
not just text.

- H1: design shows 2-line `How does pocket money / work in your house?`;
  app shows 1-line `How does pocket mone...` + ellipsis in BOTH themes.
  FAIL — see deviation 1.
- Option cards ×3: presence, order, copy, selected `Both` state, colours,
  radii, shadows all match; rects sit ~one line-height higher than design as a
  consequence of deviation 1 (not an independent defect).
- Settings card: structure, 16/16/12 insets, full-bleed dividers, radius 24
  match; vertical position shifted up (consequence of deviation 1).
- `Payout day` chips `Mon…Sun`, `Sat` selected: order, labels, selection,
  pill rects, 44-tall tap boxes, 6 px gaps all correct. Glyph size differs —
  see deviation 3.
- `Weekly base` rows: `M` lilac + `Maya` + `− £3.00 +`, `L` peach + `Leo` +
  `− £1.50 +`, Maya-then-Leo order (CHILD ORDER ✓), amounts match seeded DB
  (DATA OVER MOCKS ✓). Copy exact incl. `£`.
- `Coin value` row: `40×40` coinTint tile + `Coin value` + `10 coins = 10p`,
  copy exact, no overflow. Glyph differs — see deviation 4.
- Caption + `Continue`: copy exact, centred 2-line caption, 52-high pill CTA,
  dense 14 px vertical padding all match.
- Bottom edge: CTA surface runs to the physical edge in light and dark — no
  coloured strip. OWNER BOTTOM EDGE rule ✓.
- Gutters/alignment: 20 px side edges consistent; ignoring the deviation-1
  vertical shift, nothing is a few px off horizontally.
- Dark mode colours: selected-option deep-green tint, Sat pill, coin tile,
  CTA mint/black-text all match the dark PNG.
- `google_fonts`/`GoogleFonts`: absent.

## Numbered deviations (element, design value, app value, fix)

1. H1 truncated to one line (BLOCKER — designer-rejectable) — design: 2-line
   heading `How does pocket money` / `work in your house?`; app (both
   themes): single line `How does pocket mone...` with ellipsis, cutting off
   the screen title and pulling every row below it ~one line-height up
   (this is what inflates bands 1–4 to 7–11%). Read-only pointer for the
   bugs stage (code NOT edited here): `_SetupTitle`
   (`app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:136-149`)
   now renders the copy through `NestBalancedText` with no `maxLines`, where
   iteration 4 rendered plain 2-line `Text`; suspect the shared balanced-text
   default/algorithm constraining to one line. Fix: make the H1 wrap to the
   design's 2-line balanced break (e.g. `maxLines: 2`, no ellipsis) in the
   feature view and/or fix `NestBalancedText` via SHARED_REQUEST if the
   default is shared-owned.
2. Status bar time/icons — design `9:41` + mocks; app real OS time/icons.
   Fix: none (STATUS BAR rule: ignore; band 0 ~1.6% is this only).
3. Day-chip glyph size — design 13 px labels filling ~45.7 px cells; app
   `NestChip` (14 px + padding) via `FittedBox(scaleDown)` renders ~10–11 px.
   Pill/border rects, order, selection, 44 tap targets, gaps, colours correct.
   Fix (shared): optional `labelStyle` override (SPACING_SPEC conflict #6,
   pre-flagged in `1_plan.md` §7 — do not fork the component). Not
   designer-rejectable at screen scope.
4. Coin-tile glyph — design `assets/coin.svg`; app `NestIcons.poundCoin` in
   the same 40×40 radius-16 coinTint tile. Fix: none (token equivalent).
5. Bottom strip / home indicator — design shows a paper/cream strip under the
   CTA; app runs CTA surface to the edge in both themes. Fix: none (OWNER
   BOTTOM EDGE override; app is correct).
6. Text/stepper-edge heat — glyph rasterization after 1170→390 LANCZOS
   rescale; no positional/colour deviation underneath. Fix: none (artifact).

Copy is otherwise character-exact vs the HTML source (ASCII + `£` only);
no misalignment, no clipping, no ellipsis failures outside deviation 1.


## From 6_bugs.md
# P06 Pocket money setup — Stage 6 adversarial bug hunt (iteration 5)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). `ORCHESTRATOR_NOTES.md` (including the 07:22 and 07:58
updates) is verified item by item below. No screen code was changed by this
stage — only `app/test/features/pocket_money/p06_bugs_test.dart` and this
report.

Suite state: `flutter test test/features/pocket_money/p06_bugs_test.dart` →
**+25 ~2: All tests passed!** The two skips are this iteration's new findings;
delete the skips to watch them fail:

```text
P06-BUG-11  Expected: a value greater than or equal to <60>   Actual: <34.0>
P06-BUG-12  Expected: '−' (U+2212)                            Actual: '-'
```

## Open bugs

### P06-BUG-11 (MAJOR) — the balanced H1 collapses to one ellipsized line

**Where:** `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:143`
(`_SetupTitle` calls `NestBalancedText` with no `maxLines`) +
`app/lib/core/design_system/components/nest_balanced_text.dart:37-55` /
`:98-105` (defaults `overflow: TextOverflow.ellipsis`, passes `maxLines: null`).

**Repro / evidence (real bundled fonts, 390×844):**
- The H1 `RenderParagraph` is **350×34, `didExceedMaxLines = true`** — one line,
  ellipsized ("How does pocket money work in your hou…"), while the design
  (`design/screens/light/P06-pocket-money.png` ÷3) draws the H1 at
  **107–175 = two 34 px lines**.
- `NestBalancedText.lineCountFor` returns **1** for the H1 (it lays out with
  `ellipsis: '…'` and `maxLines: null`), so the component takes its
  `minLines <= 1` early-out and never balances.
- Minimal control probe (Flutter 3.47.5): the same text/style at width 200 —
  `overflow: clip, maxLines: null` → 136 tall (4 lines);
  `overflow: ellipsis, maxLines: null` → **34 tall (1 ellipsized line)**;
  `overflow: ellipsis, maxLines: 2` → 68 tall. Under this engine,
  `ellipsis + maxLines: null` collapses the paragraph instead of wrapping.
- Knock-on: the collapsed H1 is 34 px shorter, so the settings card sits at
  **381–651** instead of the design's **415–684** — every y in
  ORCHESTRATOR_NOTES (07:22) is 34 px high even though the card's internal
  gaps are now exactly right.

**Failing test:** `P06-BUG-11: the H1 must wrap to the design's two lines, not
one ellipsized line` (skipped; asserts paragraph height ≥ 60, no
`didExceedMaxLines`, card top 415 ± 1).

**Fix:** shared, per the orchestrator's 07:58 update: `shared/balanced_text_ellipsis`
fixes `NestBalancedText` on main (ellipsis must not collapse a null-`maxLines`
heading) and main is merged before the next build. Keep using
`NestBalancedText` on this screen and **do not work around it** (no local
`maxLines: 2`); after the merge the title must be two lines with the screen
back at the iteration-4 positions. P07 passes `maxLines: 3`
(`paywall_view.dart:411`) so it is unaffected — P06 is the only
null-`maxLines` caller today.

### P06-BUG-12 (minor, mandatory-note item) — stepper minus is a hyphen, not U+2212

**Where:** `app/lib/core/design_system/components/nest_stepper.dart:32`
(`label: '-'`, U+002D) used by `pocket_money_setup_view.dart:_BaseStepper`;
the design HTML (`P06-pocket-money.html:73`) uses `&minus;` (U+2212), a
full-width bar matching the `+` in weight and width.

**Repro:** on the screen, the Maya/Leo decrease buttons render `-`
(`codeUnits [45]`) next to a `+` (`[43]`) — visibly narrower and lighter than
the design's minus. ORCHESTRATOR_NOTES (07:22) explicitly asks for the same
glyph source for `−` and `+`; it is unaddressed by the iteration-5 build.

**Failing test:** `P06-BUG-12: the stepper minus must be the design's U+2212
(&minus;)` (skipped). The orchestrator's 07:58 update asks for "a test that the
minus button's glyph is not U+002D"; this asserts the stronger positive form
(`== '\u2212'`), which also fails on U+002D today.

**Fix:** shared — `NestStepper` should render `'\u2212'` (keeping the existing
semantics labels), or the screen needs a glyph override on `NestStepper`
(forking the component is not allowed). File a `SHARED_REQUEST` if the shared
change is not made in the next build.

## Earlier findings — all still green

The unskipped guards cover: P06-BUG-01/01b/01c (stepper accumulation),
02/02b (day guard), 03 (pill 32 px), 05 (inline write error),
06 (stale message), 07 (unknown child), 08 (day-row align), 09 (pending-day
confirmation), the iteration-4 note guards (seed `onboarding_kids`, chip rects
inside the 16 px inset at 390/320/430, `NestChipWrap` ±5 px and gap taps,
option-card 22/20 line heights, gold coin tile), and the attack holds
(kid-mode guard, restart persistence, 6 children at 320 × 1.3, £0.00/£20.00,
async gap, contrast).

## ORCHESTRATOR_NOTES (07:22) verification

| Target | Result |
|---|---|
| "Payout day" label y 524 (sheet) | app label box 397, card top 381 → **34 px high** (BUG-11 knock-on) |
| day-chip row centre +6 → 0 | **fixed inside the card**: label→pill 6.0, pill 32.0 |
| "Weekly base" +12 → 0 | **fixed**: pill→weekly 17.0 (8+1+8) |
| Maya/Leo/coin +12 → 0 | **fixed**: weekly→Maya 13.0, Maya→Leo 22.0, Leo→coin 39.0, card→bottom 23.0, card height **270.0** |
| real-font geometry test | added in `p06_bugs_test.dart` ("the payout card keeps the design's 270 height and gap chain", `FontLoader` like the P04 test); absolute-y pins tied to BUG-11 |
| stepper glyphs − (U+2212) like + | **not done** → P06-BUG-12 |
| FIXES_4 items | #1 (32 px row / card height) fixed; #3 (`NestBalancedText`) adopted but broke the wrap (BUG-11); #2/#4–#6, #9–#10, #12–#14 fixed by the build; #7/#8 parked on `SHARED_REQUEST.md`; #11 empty-state copy still needs orchestrator ratification (screen-authored `Add children to set weekly amounts.` renders only for `Seed.empty`/`Seed.fresh`) |

### UPDATE (07:58) rows

| Target | Result |
|---|---|
| #1 the title truncates to one line; shared fix lands on main, keep `NestBalancedText` | independently reproduced as **P06-BUG-11** (paragraph 350×34, `didExceedMaxLines`, card 34 px high); skipped failing test in place; no local workaround added |
| #2 minus glyph must not be U+002D; add a test | asserted `== U+2212` in **P06-BUG-12** (fails on `-` today) |
| #3 card targets measured from the two-line title's bottom: chip row centre 555, Weekly base 597, Maya 630, Leo 674, Coin value 735 (±1) | title-anchored guard added and green today (296 / 329 / 359 / 403 / 464 logical offsets, ±1); the absolute positions return once BUG-11's fix merges |

## Verdict rationale

The iteration-5 build fixed the card's internal vertical drift exactly, but the
mandated `NestBalancedText` adoption regressed the H1: under Flutter 3.47.5 the
component's `ellipsis` + `maxLines: null` lays the heading out as **one
truncated line** and drags the whole card 34 px above the design — a visible,
screen-level defect with a deterministic repro. The stepper minus glyph from
the same notes update is also still open. Two findings, one major, both with
skipped failing tests, so the stage fails.

