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

VERDICT: FAIL
