# K03 Kid home — QA code review (Stage 4, iteration 10)

Scope: feature `kid_home`, route `/kid-home`, kid mode, designs
`design/screens/{light,dark}/K03-kid-home.png` (1170×2532 @3x). Reviewed
`git diff main...HEAD` against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 K03 (`docs/DESIGN_SPEC.md:192`),
`docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, `1_plan.md`, `FIXES_9.md`, `SHARED_REQUEST.md`
and **every item in `ORCHESTRATOR_NOTES.md`**, including the 10:14 iteration-10
mandate and the 10:52 iteration-11 QA note added while this review ran.

**This stage edited no code** — only this file. **No simulator was booted,
installed on, screenshot or driven** (SIMULATORS rule: only stage 5 may).

## Method note — the worktree moved during this review

At 10:43–10:52 sibling stages (test, UI, bugs) wrote into this same worktree:
`k03_bugs_test.dart`, `kid_home_view_test.dart`, `3_test.md`, `5_ui.md`,
`6_bugs.md`, `ORCHESTRATOR_NOTES.md` and the `ui/*_10.png` captures. Per the
PROCESS ITEMS rule that in-flight work is not a finding. So:

* the gates below were run against the committed tree (`4c56fac`, K03's own
  code), and re-run afterwards on the feature suite once the in-flight test
  files had settled;
* the two brand-new in-flight view tests (bowl outline 198×86, feet 23 px) are
  assessed on content only, from the working tree;
* the pixel measurements below use `ui/app_light_10.png` / `ui/app_dark_10.png`,
  the captures the UI stage took at 10:44 after this iteration's build — i.e.
  they measure the shipped `_kNestBoxHeight: 188`.

## Gates

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none .` | ✅ `Formatted 412 files (0 changed)` |
| analyze | `flutter analyze` | ✅ `No issues found!` |
| test (whole app) | `flutter test` | ✅ **`+1579: All tests passed!`** |
| test (feature) | `flutter test test/features/kid_home` | ✅ **`+178: All tests passed!`** |
| skipped proofs | `grep -rn "skip:" test/features/kid_home/` | ✅ zero matches |
| suppressions | `grep -rn "ignore_for_file\|// ignore:" lib/features/kid_home/ test/features/kid_home/` | ✅ none |
| fonts | `grep -rn "google_fonts\|GoogleFonts" lib/ test/ (feature)` | ✅ none (one comment reference only) |
| tracking | `grep -rn "letterSpacing" lib/features/kid_home/` | ✅ none |

## Independently verified (measured, not taken on trust)

**Pixel geometry, design vs `ui/app_light_10.png` (logical px, PNG ÷3).**

| element | design | app (iter 10) | verdict |
|---|---|---|---|
| nest ink bbox x | 95.7…294.0 (198.3) | 95.7…294.0 (198.3) | ✅ exact |
| nest outline height | 107.4 (y 276…384) | 86.2 (y 277…363) | ⚠️ **finding 2** |
| Pip ink above the rim | y 197.0 | y 199.3 | ✅ (2 px) |
| Pip body bbox | y 213.7…332.3 | y 203.3…323.7 | ⚠️ body sits ~9 px high (same nest cause) |
| nest inner white ellipse (x=195) | y 304…335 | y 298…324 | ⚠️ same 0.8 vertical squash |
| ground shadow | y 374…393 | y 356…375 | ⚠️ same, ~19 px high |
| speech bubble body | white to y 165, solid-ink tail to y 174 | white to y 166, **hollow** tail to y 179 | ⚠️ **finding 3** |
| hearts row | ink y 441…458 | y 441…458 | ✅ exact |
| "Today's quests" ink bbox | x 20…218, y 483…508 | x 20…218, y 483…507 | ✅ exact (`.kid-title` 28/34 = `NestType.kidTitle`) |
| section chip pill | x 266…369, y 478…509 (32 tall) | x 266…369, y 478…509 | ✅ exact (SHAPES rule: background rect, not text) |
| progress bar | x 24…365 | x 24…366 | ✅ (±1 px rounding) |
| card 1 borders | x 35…355 / y 561, 645 | x 34…356 / y 561, 645 | ✅ (±1 px) |
| dock top border | y 719 (ink) | y 719 (ink) | ✅ exact |
| dock buttons | x 29…120 / 150…240 / 270…361 | x 29…119 / 150…240 / 270…361 | ✅ (±1 px, 20 px gutters) |
| bottom edge, light | green strip y 810…843 | dock surface (255,255,255) to y 843 | ✅ owner override |
| bottom edge, dark | teal (30,65,56) y 810…843 | dock surface (31,28,46) to y 843 | ✅ owner override |
| dark meadow grade | (36,52,87)@540 → (33,63,72)@700 at x=10 | (35,51,86)@540 → (32,63,71)@700 | ✅ within 1–2 levels (see §5) |

Row-level diff of the two captures: worst runs are y 810…843 (the mandated
bottom-edge override, 34 rows), y 349…381 (the nest squash, 33 rows), then
card interiors and the bubble tail. Everything the screen lays out is on the
design's rows.

**Other checks re-run this iteration.**

* **RULES §1** — `git diff main...HEAD --name-only` touches only
  `app/lib/features/kid_home/**`, `app/test/features/kid_home/**`,
  `docs/screens/K03/**`. No `core/`, no `app/`, no other feature, no
  `tools/screens/`, no `analysis_options.yaml`.
* **ARCHITECTURE** — feature-first; `kid_home_di.dart` / `kid_home_routes.dart`
  untouched, so DI/routes stay per-feature. One bloc per feature
  (`KidHomeBloc`), `domain/` = entities + abstract repo (one objection, carried
  as finding 4).
* **PIP rule** — every Pip is the active child's own `PipAvatar` built from the
  DB row (`kid_home_view.dart:760` stage, `:305`/`:313` failure, `:949` empty
  state) via `_pipStyle/_pipSkin/_pipAccessory`. No `pip_stage_*.svg`, no
  `PipRive`, no `riveEnabled` in the feature.
* **PERIODS** — `countsForCurrentPeriod(q.repeatRule, c.createdAt, now, zone)`
  on the read path (`kid_home_repository_impl.dart:80-82`) and inside the write
  transaction (`:158-168`), both with the family zone; `createdAtTz: Value(zone)`
  on the flip (`:178`) and the insert (`:195`). It calls the 4-arg
  `family_time.dart` overload rather than the 3-arg `london_time.dart` one the
  ruling names — same rule, and the zone argument is the more correct behaviour
  for a family that has moved (`london_time.dart:49` delegates to it).
* **DATA OVER MOCKS** — counts come from the stream (`state.doneCount`), so the
  header/chip/progress read 4 of 6, not the PNG's stale 3.
* **BOTTOM EDGE (owner)** — the dock's `Container(color: tokens.surface)` wraps
  its `SafeArea(top: false)`, so the inset sits *inside* the surface box
  (`kid_home_view.dart:610-704`). Verified in both captures: the dock surface
  runs to y 843 with no coloured strip and nothing around the home indicator
  (which is a no-op on device, `nest_chrome.dart:225`).
* **ALIGNMENT (owner)** — 20 px gutters on header, hearts, section row, cards,
  progress and dock; every measured edge above is on the same 20/370 lines.
* **ACCESSIBILITY** — the iteration-9 gap is closed: `k03_bugs_test.dart:1453+`
  and `kid_home_view_test.dart:1922+` assert `hasAction(SemanticsAction.tap)`
  for the lock, all six card bodies, the to-do checks and the three dock
  buttons, assert `hasAction(tap)` is **false** for the display-only nodes, and
  `performAction(tap)` is asserted to change the **real** outcome (DB row +
  pushed route). Both K03 `excludeSemantics: true` sites (header `:438`, hearts
  `:487`) are display-only, so they correctly carry no `onTap`.
* **COPY** — compared glyph by glyph against
  `design/html-source/screens/K03-kid-home.html`: `"Let's do some quests!"`,
  `"Today's quests"`, `"Waiting for Mum's thumbs-up"` carry the straight
  `'` (U+0027) the HTML uses, in both files. The only non-ASCII in
  `lib/features/kid_home/presentation` is in comments (`—`, `…`, `·`, `×`,
  `→`, `≈`); `KidQuest.detail`'s `·` is never rendered on K03. UK spelling
  (`Mum`), coins only, never `£`.
* **DESIGN-SYSTEM usage** — no hex literals, no `Colors.*` except
  `Colors.transparent` on the four `Scaffold`s, no `google_fonts`, no
  `letterSpacing`, no re-implemented components: `NestAvatar`, `NestCoinPill`,
  `NestLockButton`, `NestHeart`, `NestPetStage`/`PipAvatar`, `NestProgress`,
  `NestKidQuestCard`, `NestKidButton`, `NestEmptyState`, `NestBalancedText`,
  `showNestToast` are all the shared ones. `.kid-title` renders through
  `NestBalancedText` (`:530`) and nowhere else, per BALANCED HEADINGS.
  CHIP ROWS: n/a (both chips are the display-only `KidStatusChip`).
* **BALANCED / FONTS / TRIAL** — no `subscription_status` anywhere in the
  feature.
* **Children's Code** — no analytics, ads, SDK, network, `print` or
  `debugPrint` in `lib/features/kid_home`. Only the **active** child's row is
  read (`watchAppState().activeChildId` → `watchChild(id)`), the quest list is
  filtered to `assigneeChildId == childId`, and writes touch only that child's
  own completion rows. No other child is reachable from this screen.
* **Error handling** — `errorMessage` is never rendered; the failure card uses
  fixed copy and a failed completion shows the fixed toast. A raw
  `error.toString()` cannot reach a child.
* **Lifecycle / streams** — `_onLoadRequested` owns exactly one
  `StreamSubscription<KidHomeData>`, guards against stacking a second
  never-ending handler, releases it on stream error and in `close()`
  (`kid_home_bloc.dart:26, 41, 47-53, 119-124`); no `await` between the guard
  and the assignment.
* **Performance** — one `BlocBuilder` over a ≤6-item list; `_MeadowPainter`
  has `shouldRepaint` on its two colours; `PipAvatar` honours
  `kDisableAnimations`/`MediaQuery.disableAnimations` for its Rive path
  (RULES §6); `NestHomeIndicator` reserves no height on device.
* **Test discipline** — 178 feature tests, zero `skip:`, no suppression, and
  every `pumpWidget` site is paired with `disposeApp(tester)` (RULES §7).

---

## Iteration-9 findings — status

| # | Iteration-9 finding | Status |
|---|---|---|
| 1 | no `SemanticsAction.tap` assertion pinned any control | ✅ **closed** — 7-test matrix in `k03_bugs_test.dart` + `kid_home_view_test.dart`, all green |
| 2 | `_kQuestCardShadowRoom = 6` duplicated `NestSpacing.gap6` | ✅ **closed** — now `NestSpacing.gap6` (`kid_home_view.dart:117`) |
| 3 | `switchMapStream` in `domain/` | ⏳ **carried** — finding 4 below |
| 4 | geometry pin measured the nest box, not the painted outline | ✅ **closed on the assertion side** — `kid_home_geometry_test.dart:117-127` now pins the painted outline, rim and bowl bottom. (The *value* it pins is finding 2.) |

---

## Findings

### 1. [minor] The dock's ink border hard-codes `3` where `context.nestKid.borderWidth` exists

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:613`

```dart
border: Border(top: BorderSide(color: tokens.ink, width: 3)),
```

`NestKidTheme.borderWidth` is exactly this value — it is documented as "Chunky
ink outline width on kid surfaces" (`tokens/nest_tokens.dart:101,110-111`) —
and every other kid surface in the app reads it: `nest_pet_stage.dart:359`
(bubble), `nest_keypad.dart:90,135`, `nest_quest_card.dart:181,330`. K03's dock
is the **only** `Border(top: BorderSide(color: tokens.ink, …))` in the codebase
that spells the width itself (`grep -rn "Border(top: BorderSide" lib/`).

This is the same class of drift as iteration-9 finding 2, which was fixed this
iteration; it is the last bare `3` left in the view.

**Fix:** `BorderSide(color: tokens.ink, width: context.nestKid.borderWidth)`.
No visual change (the token is 3), and the revert-free.

### 2. [minor] The pet block still paints a ~20 %-flat bowl; the mandate's "198×86" target is not what the design PNG shows

`kid_home_view.dart:80-82` (`_kNestBoxHeight = 188`) ·
`kid_home_geometry_test.dart:117-127` · `kid_home_view_test.dart:547-548,563-564`

`ORCHESTRATOR_NOTES` 10:14 mandates `nestWidth: 236, nestHeight: 188,
fixedPipHeight: 152` and states the targets "visible nest 198×86, top 278".
The code implements that call **byte-for-byte**, so this is not an instruction
defect. But the target number itself does not match the design:

* `design/screens/light/K03-kid-home.png`, ink bbox of the nest: **198.3 wide ×
  107.4 tall**, spanning y 276…384 (widest at y 329-331, ellipse fit
  `cy 330, ry 53.7`; centre column ink run 378.7…384.7).
* That is `assets/illustrations/nest.svg` at its **natural aspect**: outline
  `202×110` of a 240-space box ⇒ a box of `198.3×240/202 = 236` wide by
  `107.4×240/110 = 234` tall, i.e. **≈236×236, square**.
* `ui/app_light_10.png`: **198.3 × 86.2**, spanning y 277…363 — the same art
  stretched into the 236×**188** box (`188/236 = 0.797`). The inner white
  ellipse is 31 px tall in the design and 26 px in the app, and the ground
  shadow sits at y 374…393 (design) vs 356…375 (app): the same 0.8 vertical
  squash seen from three independent features.
* Consequence: the bowl's floor is ~21 px above the design's and Pip's body
  ends ~9 px high (bbox 213.7…332.3 design vs 203.3…323.7 app). Pip's head/seat
  is right (ink y 197.0 vs 199.3, feet 23 px below the rim as mandated), and
  every row below the block is exact, so this is purely the bowl's silhouette.

The shared component cannot host the design's box: `PipNestFallback`'s
explicit mode fixes the slot at `_explicitSlotH = 236` and derives
`nestTop = 236 − nestH − _explicitBleed` (`pip_rive.dart:520,527,552`), so any
`nestHeight` big enough to paint a 107 px outline (≈234) puts the nest box ~30 px
above the slot and shifts the pinned rows below by ~10 px. **K03 must not
change the value** — it is mandated and the lever belongs to `core/`.

**Fix (shared):** file `SHARED_REQUEST #18` with these numbers — *the design
paints the bowl at the art's natural aspect (outline 198.3 × 107.4, floor
y 384) inside a ≈236×236 box; the explicit slot's fixed 236 height with a
31.4 bleed compresses it to 198.3 × 86.2 (floor 363). The explicit slot needs
either a taller slot or `BoxFit`-preserving (aspect-locked) nest art.* When it
lands, update `kid_home_geometry_test.dart:118-127` and
`kid_home_view_test.dart:547-548,563-564` from 86/364 to the design's
107/384 — and only then, so the suite never goes red.

**Do not** treat the current pins as design truth: their `reason:` strings
("the design paints an 86 px tall bowl (y 278…364)") state the mandate's number
as if it were measured from the PNG. That wording is what let `5_ui` iteration
10 close this item.

### 3. [minor] `SHARED_REQUEST #17` describes the speech-bubble tail backwards; implementing it as written would make the tail worse

`docs/screens/K03/SHARED_REQUEST.md:289-304`

The request says the tail's *"white interior is ~10 px shorter than the design's"*
— design white y 152→174 (23 px) vs app white y 152→164 (13 px) — and asks the
shared component to *"make the tail's inner fill reach the tail's tip"*.

Measured on the two PNGs at the bubble's centre column:

| | design | app (iter 10) |
|---|---|---|
| bubble body (white) | to y 165 | to y 166 |
| tail | **solid ink** y 166…174, tip ≈175 | ink y 167…169, then a **white interior** y 170…175 inside an ink V, tip y 179 |

`components.css:192` (`.speech::after`) is a solid ink wedge
(`border: 9px solid transparent; border-top-color: var(--ink)`), so the design
has **no interior fill at all**. The app's `_TailPainter`
(`core/design_system/components/nest_pet_stage.dart:391-417`) draws the ink
wedge and then paints a white triangle over it, which reads as a hollow V — the
deviation is in the opposite direction to the one filed, and it *is* visible at
1:1 (I read both captures zoomed; `5_ui` iteration 10's "invisible without
overlay" is not accurate).

**Fix (docs, in scope, no code):** correct item 17 to state the measured truth
— design = solid 9 px ink wedge, app = hollow 13 px V with a `tokens.surface`
interior — and change the ask to *"remove the inner `fillColor` triangle so the
tail paints as one solid ink wedge of the design's 9 px drop; keep
`NestSpeechBubble`'s public API"* (the current `Size(18, 10)` CustomPaint with
only the ink path is within a pixel). Shared-owned: `core/`, so K03 files rather
than patches.

### 4. [minor, carried since iteration 6] `switchMapStream` lives in `domain/`

`app/lib/features/kid_home/domain/kid_home_repository.dart:54-82`

A generic stream combinator, not a domain abstraction. `ARCHITECTURE.md:71`
restricts `domain/` to "entities + abstract `<feature>_repository.dart` ONLY",
and `core/data/stream_combine.dart` already owns `combineLatest2/3/4`. The
explanatory comment (why `asyncExpand` cannot be used) is good and must travel
with the function. Already filed as SHARED_REQUEST #14; the three call sites
(`kid_home_repository.dart:24`, `kid_home_repository_impl.dart:23,38`) are
mechanical import swaps. Nothing available inside K03 — unchanged, unblocked.

### 5. [minor, informational] K03's repository is now the only place that re-sorts quests

`app/lib/features/kid_home/data/kid_home_repository_impl.dart:73`
(`..sort((a, b) => a.title.compareTo(b.title))`)

Main's `shared_batch4` (schema v4) made `watchActiveQuests` return **creation
order**; K03 still sorts alphabetically, so it is the only screen that
overrides the app-wide convention. Recorded, **not raised**: the integrator
flagged it at `2_build.md` §2 and the orchestrator ruled at 10:52 ("Quest order
and '4 done today' come from the database — not findings"). Worth noting that
the design's own card 2 is "Reading – 20 minutes", which is creation order, so
the convention and the design agree and K03 is the odd one out. `1_plan.md` §(a)
mandates the current behaviour, so no code change now; the in-flight test pins
it with a "NOTE for the next iteration" comment, which is the right way to keep
it deliberate.

---

## Carried, shared-owned, deliberately NOT counted against K03

* **The bowl squash** (finding 2) and **the speech-bubble tail** (finding 3)
  both live in `core/design_system/`, which RULES §1 forbids this screen from
  editing, and finding 2's value is explicitly mandated by
  `ORCHESTRATOR_NOTES` 10:14. Failing K03's review for either would contradict
  the loop's division of labour; both are filed with measured numbers so the
  shared batch can act on them.
* **The dark pet glow** (the hard lilac disc) is shared and owned by
  `shared/pet_glow` per `ORCHESTRATOR_NOTES` 10:52 item 2.
* **The feature-local `_MeadowPainter`** (`kid_home_view.dart:776-829`) stays
  carried behind SHARED_REQUEST #6's two missing `KidScope` gradient stops. The
  interim band measures within 1–2 levels of both design PNGs (table above),
  so the interim is faithful.
* **The five baseline placeholder views** of this feature still render
  `state.errorMessage` verbatim into child-facing UI (`kid_pin_view.dart:21`,
  `profile_picker_view.dart:21`, `quest_detail_view.dart:21`,
  `quest_complete_view.dart:21`, `kid_home_done_view.dart:21`). None is in
  `git diff main...HEAD` and K03's own view never renders it, so it is not a K03
  finding — but K03 owns the bloc that fills that field with
  `error.toString()`, and it is a Children's Code issue the moment those screens
  go live. Unchanged from iteration 9's cross-screen note.

---

## Data for the orchestrator's iteration-11 note (item 1, dark meadow)

Before iteration 11 churns on "DARK MEADOW … the app is still flat navy",
here is the measurement of the shipped dark capture at x = 10 (the meadow band,
left of the cards):

| row | design | app (iter 10) |
|---|---|---|
| 520 | (44,52,113) | (36,44,100) |
| 540 | (36,52,87) | (35,51,86) |
| 600 | (35,56,81) | (34,56,80) |
| 700 | (33,63,72) | (32,63,71) |
| 718 | (32,65,70) | (31,63,69) |

The grade and both endpoints match the design within 1–2 levels per channel
(the row-520 gap is the design's progress-bar area, not meadow). The dark
per-row diff shows no flat-navy band either — its worst runs are the same nest
(336…366) and card-interior bands as light mode. Whatever the 10:52 QA saw, it
is not visible in `ui/app_dark_10.png` at x = 10; a colour pin at (10, 600) and
(10, 700) would pass today. Flagging so iteration 11 does not "fix" something
that is already right — or, if the QA meant a different region (e.g. inside the
12 px inter-card gaps at 320 width), that region should be named.

---

## Verdict

The screen is in good shape and every gate is green on the committed tree:
format clean, `flutter analyze` clean, `+1579` app / `+178` feature tests,
zero skipped proofs, no suppressions, no font regressions.

What this iteration actually changed is one constant (`_kNestBoxHeight`
156 → 188, mandated), one token fix (finding 2 of iteration 9), and stronger
geometry pins — and all three are correct with respect to their instructions.
The screen holds up on every rule I could check mechanically or measure: RULES §1
paths, ARCHITECTURE ownership, PIP, DATA + PERIODS, COPY, BALANCED HEADINGS,
BOTTOM EDGE, ALIGNMENT, TOKEN-ONLY, TRIAL, CHIP ROWS and Children's Code.
Accessibility is no longer just correct but *pinned*: every interactive control
advertises `SemanticsAction.tap` and performing it is asserted to change real
state, and the display-only nodes correctly advertise none. The design's shapes
match to a pixel for every pill, card, bar and button I measured — including the
dark meadow, which matches within 1–2 levels.

Five findings, all **minor**, none of which K03 can or should fix in product
code this pass:

1. the dock's border width should read `context.nestKid.borderWidth`
   (one-line, no visual change);
2. the bowl is still ~20 % flat and its floor ~21 px high — shared-owned,
   needs SHARED_REQUEST #18 with the measured 198.3 × 107.4 outline; the
   geometry pins must not be read as design truth until it lands;
3. SHARED_REQUEST #17 (bubble tail) states the defect backwards and must be
   corrected before the shared batch implements it;
4. `switchMapStream` in `domain/` (carried, SHARED_REQUEST #14);
5. the local alphabetical quest sort is the only one in the app — recorded,
   ruled out of scope at 10:52.

VERDICT: PASS