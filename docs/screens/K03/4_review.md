# K03 Kid home — QA code review (Stage 4, iteration 11)

Scope: feature `kid_home`, route `/kid-home`, kid mode. Reviewed
`git diff main...HEAD` (merge-base `4dc08ad`) against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K03
(`docs/DESIGN_SPEC.md:192`), `docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, `docs/screens/K03/1_plan.md`, `FIXES_10.md`,
`SHARED_REQUEST.md` and **every item in `ORCHESTRATOR_NOTES.md`**, including the
10:14 (pet seating) and 10:52 (iteration-11 dark-meadow) mandates.

**This stage edited no code** — only this file. **No simulator was booted,
installed on, screenshot or driven** (SIMULATORS rule: only stage 5 may). The
pixel numbers below come from reading the design PNGs and the stage-5 captures
with a pixel probe (`PIL`, ÷3 to logical px) — no device was used by me.

## What is in this iteration's diff

```
 app/test/features/kid_home/kid_home_geometry_test.dart | 158 ++++++++++
 app/test/features/kid_home/kid_home_view_test.dart      |  56 +++++
 docs/screens/K03/…                                      | notes/notes only
```

No `lib/` file changed this iteration (the pet block and the dark meadow were
already at their shipped values from iterations 10 and 9). The review therefore
has two jobs: (a) review the two new test files properly, and (b) re-verify the
whole K03-owned feature against every rule, because that is what the screen
ships. Findings 1–4 are carried items from iterations 9–10 that are still open;
5–9 are new this iteration.

## Gates

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none .` | ✅ `Formatted 422 files (0 changed)` |
| analyze (K03-owned tree) | `dart analyze lib/features/kid_home <the 4 tracked test files>` | ✅ `No issues found!` |
| analyze (whole worktree) | `flutter analyze` | ⚠️ 5 issues, **all** from the untracked scratch `test/features/kid_home/probe_temp_test.dart` (1 × `undefined_identifier` + 4 × ignore hygiene) that a sibling stage had on disk at 14:19 — see *Process items*. It was deleted again by 14:22 and is not in git. |
| test (whole app) | `flutter test` | ✅ **`+1793: All tests passed!`** |
| test (feature) | `flutter test test/features/kid_home` | ✅ **`+185: All tests passed!`** |
| skipped proofs | `grep -rn "skip:" test/features/kid_home/` | ✅ zero matches |
| suppressions | `grep -rn "ignore_for_file\|// ignore:" lib/features/kid_home test/features/kid_home` | ✅ none |
| fonts | `grep -rn "google_fonts\|GoogleFonts" lib/features/kid_home test/features/kid_home` | ✅ none (one comment mention only) |
| tracking | `grep -rn "letterSpacing" lib/features/kid_home/` | ✅ none |
| colours | `grep -rn "0x[0-9A-Fa-f]\{6\}\|Colors\." lib/features/kid_home/` | ✅ only `Colors.transparent` ×4 (the `Scaffold` backgrounds under `KidScope`) |

A first whole-app `flutter test` run reported two `loading …` failures
(`kid_home_geometry_test.dart`, `probe_temp_test.dart`). Both were the
enumeration window of files a sibling stage was writing/deleting at that
instant — the same two files compile and pass in isolation and in the re-run
(`+1793`). Treated as a process item, per the PROCESS ITEMS rule.

## Independently measured (design vs the iteration-11 device captures)

`design/screens/{light,dark}/K03-kid-home.png` vs
`docs/screens/K03/ui/app_{light,dark}_11.png`, logical px. Ink = any pixel with
mean channel < 110; the dark rows below the horizon use an explicit
colour probe, because the dark navy background is itself below that threshold.

**Positions (light; the dark capture is identical row-for-row below the horizon
flip).**

| element | design | app (iter 11) | Δ |
|---|---|---|---|
| avatar "M" ink | x 43…60, y 74…90 | x 43…60, y 74…90 | 0 |
| coin-pill ink | x 255…293, y 77…87 | x 255…293, y 77…87 | 0 |
| lock glyph ink | x 333…350, y 73…92 | x 333…350, y 73…92 | 0 |
| "Today's quests" ink | x 20…218, y 483…508 | x 20…218, y 483…507 | 1 (antialias) |
| card 1 bottom border ink (x=195) | y 644…646 | y 644…646 | 0 |
| card 2 top border ink (x=195) | y 659…661 | y 659…661 | 0 |
| dock top border ink (x=195) | y 719…721 | y 719…721 | 0 |
| nest ink width | 198 (x 96…294) | 198 (x 96…294) | 0 |
| nest ink bottom | y 384 | y 364 | **−20 → finding 2** |
| speech-bubble tail, column x=195 | white to y 165, solid ink 166…174, sky 175 | white to 166, ink 167…169, **white 170…175**, ink 177…179 | **→ finding 3** |

**Dark meadow at the gutter column x=10 — the 10:52 "still flat navy" claim,
re-measured from scratch:**

| row | design | app (iter 11) | Δ |
|---|---|---|---|
| 535 | 37,52,88 | 38,53,89 | ≤1 |
| 560 | 36,53,85 | 35,53,84 | ≤1 |
| 600 | 35,56,81 | 34,56,80 | ≤1 |
| 650 | 34,60,76 | 33,58,75 | ≤2 |
| 700 | 33,63,72 | 32,63,71 | ≤1 |
| 715 | 33,65,71 | 34,66,71 | ≤1 |

A monotone navy → teal run, ≤2/255 off the design at **every** sampled row in
both themes (light: ≤2 as well, e.g. (10,600) 223,243,214 vs 223,242,213). There
is no flat navy on this screen; the orchestrator's item 1 is a repeat of an
observation first filed four iterations ago. The new geometry pin
(`kid_home_geometry_test.dart:222+`, 4 tests, light+dark × rows 600/700) plus a
direction guard ("green must move off `kidHorizon` toward `kidMeadow` by >2/255")
now makes a regression there impossible to land silently.

**Bottom edge (owner rule), x=195, rows 810/830/843:** design `(204,237,192)`
light / `(30,65,56)` dark (meadow green, as the PNGs show); app `(255,255,255)`
light / `(31,28,46)` dark — the dock's own surface, unbroken, in both themes, to
the last row. **PASS**, and it must stay that way: no coloured strip, nothing
around the home indicator.

**One thing I specifically looked for and did not find:** at rows 700–718 the
capture shows a pale-green rounded pill with dark-green text inside card 2
(`x 96…286`). That is card 2's `KidStatusChip('Done')` on DB content ("Hoover
the stairs", approved in the seed) — **not** a hole in the card's white surface
and **not** a meadow-band z-order bug. It is the accepted A2 content difference
(quest order comes from the DB).

## Rule-by-rule

| rule | verdict | evidence |
|---|---|---|
| RULES §1 (paths) | ✅ | `git diff main...HEAD --name-only` = `app/test/features/kid_home/**` + `docs/screens/K03/**` only. No `core/`, no `app/`, no other feature, no `tools/screens/`, no `analysis_options.yaml`. |
| ARCHITECTURE (feature-first) | ✅ | `kid_home_di.dart` / `kid_home_routes.dart` untouched; DI + routes stay per-feature; one bloc per feature with `initial/loading/loaded/failure`; `domain/` = entities + abstract repo (+ finding 4). |
| PIP | ✅ | Every Pip is the active child's own `PipAvatar` built from the DB row: `kid_home_view.dart:760` (stage), `:305`/`:313` (failure), `:949` (empty). No `pip_stage_*.svg`, no `PipRive`, no local fork of `NestPetStage`. |
| PERIODS | ✅ | `countsForCurrentPeriod(q.repeatRule, c.createdAt, now, zone)` on the read path (`kid_home_repository_impl.dart:80-82`) and inside the write transaction (`:158-168`); `createdAtTz` written on both paths (`:178`, `:195`). Uses the 4-arg `family_time` overload — same rule plus the family zone. |
| DATA OVER MOCKS | ✅ | Counts, coins, happiness and quest set all come from the stream (`state.doneCount`, `child.coins`); no design number is hard-coded in the view. |
| CHILD ORDER | ✅ | `watchProfiles` → `watchChildren`, which orders by `createdAt` then `rowid` (`app_database.dart:487-496`). K03 never re-sorts children. |
| BOTTOM EDGE (owner) | ✅ | `kid_home_view.dart:610-704` — the `Container(color: tokens.surface)` wraps its `SafeArea(top: false)`, so the inset sits *inside* the surface box; measured above in both themes. |
| ALIGNMENT (owner) | ✅ | 20 px gutters on header, pet stage, hearts, section row, progress and dock; every measured edge lands on the same 20/370 lines. |
| COPY | ✅ | Compared glyph-by-glyph with `design/html-source/screens/K03-kid-home.html`: `"Let's do some quests!"`, `"Waiting for Mum"` (chip) and `"Waiting for Mum's thumbs-up"` (a11y label) all use the straight `'` (U+0027) the HTML uses. The **only** non-ASCII in `lib/features/kid_home/presentation` is inside comments (`— § × ≈`). UK spelling (`Mum`), coins only, never `£`. |
| FONTS / LETTER SPACING / CHIP ROWS | ✅ | No `google_fonts`/`GoogleFonts`, no `letterSpacing`, no interactive chip rows (both chips are display-only). |
| BALANCED HEADINGS | ✅ | `.kid-title` renders through `NestBalancedText` (`kid_home_view.dart:530`) and nowhere else; no `.h2/.h3/.body/.caption` uses it. |
| TRIAL | ✅ | No `subscription_status` write anywhere in the feature. |
| ACCESSIBILITY ACTIONS | ✅ | Every control asserts `hasAction(SemanticsAction.tap)` and `performAction(tap)` changes real state (DB row + pushed route): `k03_bugs_test.dart:1466+` ("every interactive control exposes SemanticsAction.tap") and `kid_home_view_test.dart:2061+`. The two `Semantics(excludeSemantics: true)` sites in the view (header `:438`, hearts `:487`) are display-only and correctly carry no action. |
| Performance | ✅ | One `BlocBuilder` over a ≤6-item list; `_MeadowPainter.shouldRepaint` compares its two colours only; no `Timer`/`AnimationController`/`Future.delayed` anywhere in the feature (RULES §6); `const` where the subtree is constant. |
| Error handling | ✅ | `errorMessage` is never rendered on K03 — `_KidFailure` uses fixed child-safe copy and a failed completion shows the fixed `showNestToast` line, so a raw `error.toString()` cannot reach a child. |
| Streams disposed | ✅ | Exactly one `StreamSubscription<KidHomeData>` per load (`kid_home_bloc.dart:26,41`), guarded against stacking, released on stream error (`:47-53`) and in `close()` (`:119-124`). |
| Children's Code | ✅ | No analytics, ads, SDK, network, `print`/`debugPrint` in `lib/features/kid_home`. Only the **active** child is read (`watchAppState().activeChildId` → `watchChild(id)`); the quest list is filtered to `assigneeChildId == childId`; writes touch only that child's completion rows. |

---

## Findings

### 1. [minor, carried from iteration 10] The dock's ink border spells `3` where `context.nestKid.borderWidth` exists

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:613`

```dart
border: Border(top: BorderSide(color: tokens.ink, width: 3)),
```

`NestKidTheme.borderWidth` is documented as "Chunky ink outline width on kid
surfaces" (`core/design_system/tokens/nest_tokens.dart:105,114-115`) and every
other kid surface in the app reads it (`nest_pet_stage.dart:359`,
`nest_keypad.dart:90,135`, `nest_quest_card.dart:181,330`). K03's dock is the
only `Border(top: BorderSide(color: tokens.ink, …))` in `lib/` that hard-codes
the width (`grep -rn "Border(top: BorderSide" lib/`).

**Fix:** `BorderSide(color: tokens.ink, width: context.nestKid.borderWidth)` —
identical pixels (the token is 3), one line, and the probe finder
`kid_home_view_test.dart:264-274` keeps matching, because it reads the *painted*
border width rather than the literal.

### 2. [minor, shared-owned] The bowl is painted ~20 % short: design floor y 384, app floor y 364

`kid_home_view.dart:80-82` (`_kNestBoxHeight = 188`) · the pins in
`kid_home_geometry_test.dart:181-191` (committed line numbers)

The 10:14 mandate (`nestWidth: 236, nestHeight: 188, fixedPipHeight: 152`) is
implemented call-for-call, so this is not an instruction defect — but the
mandate's own target number is not what the design PNG shows, and the pins state
it as if it were measured:

* my measurement on `design/screens/light/K03-kid-home.png`, window y 265…400:
  nest ink **x 96…294 (198 wide), y 265…384**; on `ui/app_light_11.png`:
  **x 96…294 (198), y 265…364**. Width and top agree exactly; the floor is 20 px
  higher in the app.
* `assets/illustrations/nest.svg` is a `202×110` outline in a 240-space box, so
  the art's natural aspect inside a 236-wide box is **≈236×234**; a 236×**188**
  box squashes it to 236×188 (`0.80`), which is exactly the 20 px seen from the
  floor.
* `PipNestFallback`'s explicit mode fixes the slot height at 236 and derives
  `nestTop` from `nestHeight`, so the only way to paint the art's own aspect is
  in `core/` — RULES §1 forbids K03 from touching it.

**K03 must not change the mandated value.** The fix is the shared one already
drafted as SHARED_REQUEST #18: give the explicit slot a taller box, or give
`PipNestFallback` an aspect-locked `BoxFit` for the nest art; then move
`kid_home_geometry_test.dart:183-191` from `86`/`364` to the design's
`107`/`384`.

**Do not** keep the pins worded as "the design paints an 86 px tall bowl (y
278…364)" — that is the mandate's number, not the PNG's, and it is what let
`5_ui` iteration 10 close this item.

### 3. [minor, docs in a K03-owned file, carried since iteration 10] `SHARED_REQUEST #17` describes the speech-bubble tail backwards

`docs/screens/K03/SHARED_REQUEST.md:289-303`

The request states *"design white y 152→174 (23 px), app white y 152→164
(13 px)"* and asks the owner to *"make the tail's inner fill reach the tail's
tip"*. That is inverted. Measured by me just now, at the tail's centre column
x=195 of the very two images it cites:

| rows | design | app (iter 11) |
|---|---|---|
| ≤165/166 | white bubble body | white bubble body |
| 166…174 | **solid ink** (30,27,58), tip at 175 | ink 167…169 only |
| 170…175 | — | **white interior** (255,255,255) |
| 177…179 | — | ink again (hollow V, 13 px tall) |

`components.css:192` (`.speech::after`) is a 9 px **solid** ink wedge
(`border: 9px solid transparent; border-top-color: var(--ink)`) — the design has
no interior fill at all. The app's shared `_TailPainter`
(`core/design_system/components/nest_pet_stage.dart:362-392` — an 18×10
`CustomPaint` at `:355`, `fillColor: tokens.surface` at `:353`, the inner fill
triangle at `:379-381`) paints the wedge and then a white triangle over it, so
the tail reads as a hollow V that is 4 px *taller* than the design's and hollow
inside it. Implementing #17 as written would push white further down and make
every `NestSpeechBubble` on every screen worse.

This is the same pixels `5_ui` iteration 11 recorded as its single deviation
("white extends +10 px"); both measurements agree, only the direction differs.

**Fix (docs only, in K03's own folder — no core edit):** rewrite #17 to
"design = one solid 9 px ink wedge, ink 166…174 with the tip at 175; app =
ink 167…169, white 170…175, ink 177…179 — a hollow 13 px V. Remove the inner
`fillColor` triangle from `_TailPainter` and size the wedge to the design's 9 px
drop; keep `NestSpeechBubble`'s public API (K03 passes only `text`)."
*Escalation:* this is the second iteration this wording has stayed wrong, and
the fix is a three-line docs edit in a file K03 owns. If it is still wrong after
iteration 12 the orchestrator should treat it as a shared-batch blocker, because
as written it is an instruction to make a cross-screen visual worse.

### 4. [minor, carried since iteration 6] `switchMapStream` lives in `domain/`

`app/lib/features/kid_home/domain/kid_home_repository.dart:54-82`

A generic stream combinator, not a domain abstraction; `ARCHITECTURE.md:71`
restricts `domain/` to "entities + abstract `<feature>_repository.dart` ONLY",
and `core/data/stream_combine.dart` already owns `combineLatest2/3/4`. The
explanatory comment (why `asyncExpand` cannot be used) is good and must travel
with the function. Already filed as SHARED_REQUEST #14; the three call sites
(`kid_home_repository.dart:24`, `kid_home_repository_impl.dart:23,38`) are
mechanical import swaps. Nothing is available inside K03.

### 5. [minor, new] `kid_home_di.dart` documents a file that does not exist

`app/lib/features/kid_home/kid_home_di.dart:7-9`

```
/// Registers the KidHome feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
```

There is no `kid_home_fake_data_source.dart` anywhere under
`app/lib/features/kid_home/` (nor, apart from the design-system gallery, in any
other feature). The comment sends the next reader looking for a file that is not
there, and implies a dead-code risk that does not exist.

**Fix:** delete the second clause, e.g. "Registers the KidHome feature: the
Drift-backed repository as a lazy singleton and `KidHomeBloc` as a factory."

### 6. [minor, new] Quest cards are built without a key

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:588-593`

```dart
for (final item in state.items)
  _QuestCard(child: child, item: item, completionToken: state.actionNonce),
```

`_QuestCard` is a `StatefulWidget` whose `State` carries the tap latch `_busy`
and whose `didUpdateWidget` only resets it when `status` or `completionToken`
changes. Without a key, `State` is matched **by position**: if the list ever
reorders (a parent renames a quest, so the repository's title sort changes, or a
quest is removed and the list closes the gap) the latch migrates to a different
quest, and `didUpdateWidget` sees an unchanged status and leaves it there.

**Fix:** `key: ValueKey(item.questId)` on `_QuestCard`. One line, no visual
change, and the list becomes identity-correct for the whole pipeline.

### 7. [minor, new] `_kStageToHearts = 10.75` is the screen's only un-tokenised size

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:97`

Every other gap on this screen is a token or a design-slot value passed as a
component parameter; `10.75` is neither — it is a sub-pixel compensation for
padding the shared `NestPetStage` paints inside its own box. The reasoning in
the doc comment is sound and the measurement (hearts centre 447.75 vs the
design's 448) is reproducible, so this is not a bug; it is the one place where a
shared-component change would silently move every row below the pet block with
no token to break.

**Fix:** nothing now; when SHARED_REQUEST #6 lands (the two missing `KidScope`
gradient stops) delete the constant and restore `NestSpacing.s4`. Until then,
keep the constant and its comment together — and when #6 lands, remove the
number in the same commit that removes the `_MeadowPainter`.

### 8. [minor, new] Duplicated comment block in the new meadow pin

`app/test/features/kid_home/kid_home_geometry_test.dart:262-265` (committed line
numbers; the test stage's in-flight edits have since moved the same block to
`:382-385` in the working tree)

The copy/paste left two consecutive paragraphs that both start "The regression
this pins: flat navy" — the first (lines 262-265) was superseded by the second
(266-271) and never deleted. It is in the file that is the *proof* for the
orchestrator's item 1, so a reader has to work out which half is current.

**Fix:** delete the first paragraph (4 lines); keep the second.

### 9. [minor, new] The new pixel probe does not emulate the device's bottom inset

`app/test/features/kid_home/kid_home_geometry_test.dart:100-110`
(`_pumpForPixels`)

It sets `physicalSize` and `devicePixelRatio` but not
`tester.view.padding` / `viewPadding`, so the probe runs on a screen with a
0 px bottom inset, while the design — and the pin the sibling geometry group in
the same file now emulates (the test stage's in-flight
`tester.view.padding = const FakeViewPadding(bottom: 34 * 3)`) — assume 34 px.
The assertions still hold today (the painter's gradient is expressed in absolute
rows, `gradeSpan / h`, so the painted colour at row *y* is inset-independent),
but that is a coincidence of one painter's maths: if the band or the dock
geometry changes, the probe silently keeps testing a layout the device never
shows.

**Fix:** add the two `FakeViewPadding(bottom: 34 * 3)` lines to
`_pumpForPixels`, so both geometry groups in the file emulate the same device.

---

## Carried, shared-owned, deliberately NOT counted against K03

* **The bowl squash (finding 2) and the speech-bubble tail (finding 3)** live in
  `core/design_system/`, which RULES §1 forbids this screen from editing, and
  finding 2's value is explicitly mandated by `ORCHESTRATOR_NOTES` 10:14.
  Failing K03's review for either would contradict the loop's division of
  labour. Both are filed with measured numbers for the shared batch.
* **The dark pet glow** is shared and owned by `shared/pet_glow` per
  `ORCHESTRATOR_NOTES` 10:52 item 2; the new tests in
  `kid_home_view_test.dart:647+` pin that K03 renders the shared fade and no
  local disc, so that regression cannot land here either.
* **The feature-local `_MeadowPainter`** (`kid_home_view.dart:786-829`) stays
  carried behind SHARED_REQUEST #6's two missing `KidScope` gradient stops. The
  interim is faithful — measured ≤2/255 off both design PNGs at every sampled
  row (table above) — so it is a filed debt, not a defect.
* **The five baseline placeholder views** of this feature still render
  `state.errorMessage` verbatim into child-facing UI (`kid_pin_view.dart:21`,
  `profile_picker_view.dart:21`, `quest_detail_view.dart:21`,
  `quest_complete_view.dart:21`, `kid_home_done_view.dart:21`). None is in this
  diff and K03's own view never renders it, so it is not a K03 finding — but
  K03 owns the bloc that fills that field with `error.toString()`, and it is a
  Children's Code issue the moment those screens go live. Unchanged from
  iteration 9's cross-screen note.

## Recorded, not raised

* **Alphabetical quest sort** (`kid_home_repository_impl.dart:73`) is the only
  re-sort left in the app (`watchActiveQuests` returns creation order since main
  `shared_batch4`), and the design's own card 2 is creation order — but
  `1_plan.md` §(a) mandates the current behaviour and the orchestrator ruled at
  10:52 that quest order comes from the database. Recorded, not a finding; the
  in-flight test pins it with a "NOTE for the next iteration" comment, which is
  the right way to keep it deliberate.
* **`KidQuestModel`** (`data/models/kid_quest_model.dart`) has no references in
  `lib/` or `test/` — but all 18 features carry the same ARCHITECTURE-mandated
  `fromJson`/`toJson` model, so it is the foundation's shape, not K03's debt.
* **`verifyPin` returns `true` when a child has no PIN hash** (Leo in the demo
  seed), i.e. kid mode is open for a child whose parent never set a code. That
  is deliberate foundation behaviour on `main`, it is K02's screen that consumes
  it, and the K03 screen is only reachable after the picker/PIN — noted for the
  gate screens, not a K03 finding.

## Process items (explicitly not findings)

* Sibling stages (test, UI, bugs) wrote into this worktree while the review ran:
  `k03_bugs_test.dart` and `kid_home_geometry_test.dart` were being edited at
  14:18/14:23, `5_ui.md` / `6_bugs.md` and the `ui/*_11.png` captures landed, and
  `probe_temp_test.dart` appeared (14:19) and was deleted again (14:22). The two
  transient `loading` failures in the first whole-app run are that churn, not the
  tree. Per the PROCESS ITEMS rule none of this is reported as blocker/major.
* The branch is behind `main` by the shared batches it has not merged yet, and
  the loop owns the commit/merge order.

## Verdict

No blocker or major finding in K03-owned code. The shipped screen meets
`ARCHITECTURE.md`, RULES §1/§6/§7/§8, `DESIGN_SPEC.md` §5 K03, the design
system's tokens-only rule and the Children's Code bar; format, analyze and both
test runs are green; and every position I could measure against the design PNGs
is exact except the two shared-owned items above. Findings 1, 5–9 are small and
local; 2–4 are already filed with the numbers the shared batch needs.

VERDICT: PASS
