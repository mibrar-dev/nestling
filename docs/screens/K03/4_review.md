# K03 Kid home — QA code review (Stage 4, iteration 9)

Scope: feature `kid_home`, route `/kid-home`, kid mode, designs
`design/screens/{light,dark}/K03-kid-home.png`. Reviewed `git diff main...HEAD`
against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 K03, `docs/design/SPACING_SPEC.md`, the design system
in `app/lib/core/design_system/`, `1_plan.md`, `FIXES_8.md` and every item in
`ORCHESTRATOR_NOTES.md`.

**This stage edited no code.** No simulator was booted, installed on,
screenshot or driven (SIMULATORS rule: only stage 5 may).

## Method note — gates were run against the committed tree

At 10:14 a sibling loop stage (`tools/agents/run_agent.sh K03_test_i9`) began
writing `app/test/features/kid_home/{k03_bugs,view}_test.dart` into this same
worktree, so the working tree stopped being a stable object mid-review (at one
moment `flutter analyze` reported 10 errors from a half-written file). Per the
PROCESS ITEMS rule that in-flight work is not a finding — but it did mean the
gates had to be run somewhere stable.

So all gates below were run in a **detached `git worktree` at HEAD
(`fdfcc24`)**, which I removed afterwards. `git status -- app/` is unchanged by
this stage: it still shows only the test stage's two in-flight files.

## Gates (in `app/`, committed `fdfcc24`, isolated worktree)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none .` | ✅ `Formatted 408 files (0 changed)` |
| analyze | `flutter analyze` | ✅ `No issues found!` |
| test | `flutter test` (full suite) | ✅ **`+1544: All tests passed!`** |
| skipped proofs | `grep -rn "skip:" app/test/features/kid_home/` | ✅ **zero matches** |
| suppressions | `grep -rn "ignore_for_file\|// ignore:" app/lib/features/kid_home/` | ✅ none |
| fonts | `grep -rn "google_fonts\|GoogleFonts" app/{lib,test}/features/kid_home/` | ✅ none |

## Independently verified (not taken on trust)

I wrote throwaway probes in the isolated worktree, ran them, and deleted them,
because several claims in the iteration notes are load-bearing and I did not
want to inherit them unchecked.

**Accessibility — `SemanticsAction.tap`, end to end.** A census of every
labelled semantics node at 390×844 gives 18 nodes: all **12 interactive** ones
expose `SemanticsAction.tap` and all 6 display-only ones correctly do not.

| node | `hasAction(tap)` |
|---|---|
| `Grown-ups` (lock), 6 × quest card body, 2 × `Mark done` check, `Pip`/`Shop`/`My jar` | **true** |
| `Hi Maya, 4 done today`, `120 coins`, `Let's do some quests! / Pip the Fledgling…`, `Pip is happy today, 4 of 5 hearts`, `Today's quests / 4 of 6 done`, `4 of 6 of today's quests done` | false (correct — non-interactive) |

And the actions drive real behaviour, not just a flag:
`performAction(tap)` on the `Mark done` check took `q-reading` from `to_do` to
`done_pending` **in the database** and pushed `/quest-complete`; on a card body
it pushed `/quest-detail`; on dock `Shop` it pushed `/reward-shop`. A real
`tester.tap` on the same check gives byte-identical results, so the semantics
path and the pointer path agree.

*(My first two probe runs reported these actions doing nothing. That was a
probe bug, not a code bug: cards 3–6 sit below the 125…753 ListView viewport, so
the nodes are laid out but unreachable until scrolled. With
`scrollUntilVisible` they work. Recording it so the next reviewer does not
re-derive a phantom defect from it.)*

**Layout — 320 wide.** No overflow at 320×844 while scrolling the whole quest
list; the 20 px gutters hold (`card1 = 20…300`), the dock still fits three
buttons, and the lock stays pinned at 314…370.

**Shapes at 390.** Dock buttons `20…128.7`, `140.7…249.3`, `261.3…370`,
72 tall; lock `314…370 × 56`; coin pill `208…306 × 36` — 20 px gutters and the
design's 56 px lock hold.

## Verified clean (no finding)

- **RULES §1 paths** — diff and working tree touch only
  `app/lib/features/kid_home/**`, `app/test/features/kid_home/**`,
  `docs/screens/K03/**`. No `core/`, no `app/`, no other feature, no
  `tools/screens/`, no `analysis_options.yaml`.
- **ARCHITECTURE** — feature-first; `kid_home_di.dart` and
  `kid_home_routes.dart` are **untouched by this branch** (verified: they do
  not appear in the diff), so DI/routes stay per-feature and the screen did not
  reach into shared wiring. `KidHomeBloc` is registered by `registerFactory`
  (no shared-across-routes hazard). One `domain/` objection, carried as
  finding 3.
- **PIP rule** — every Pip is the active child's own `PipAvatar` built from the
  DB row (`kid_home_view.dart:298, 306, 753, 942`) via
  `_pipStyle/_pipSkin/_pipAccessory`; the failure, empty-quests and
  no-child states all do the same (neutral look only when no child is known).
  No `pip_stage_*.svg`, no `PipRive`, no `riveEnabled` anywhere in the feature.
- **PERIODS ruling** — `countsForCurrentPeriod` on the read path
  (`kid_home_repository_impl.dart:80-82`) and inside the write transaction
  (`:158-168`), both with the family zone, and `createdAtTz: Value(zone)` on the
  flip (`:178`) and the insert (`:195`). Worth noting explicitly: K03 calls the
  **4-arg `family_time.dart`** overload rather than the 3-arg `london_time.dart`
  one the ruling names. Same function, same rule, and the zone argument is the
  more correct behaviour for a family that has moved — `london_time.dart:49`
  simply delegates to it with `londonZoneId`. Not a deviation in substance.
- **CHILD ORDER** — `watchProfiles()` (`:98-102`) passes the shared
  `watchChildren` straight through, and that query orders by `createdAt` then
  `rowid` (`app_database.dart:436-440`), so children are listed in the order
  they were added, not alphabetically.
- **COPY** — checked glyph by glyph against
  `design/html-source/screens/K03-kid-home.html`. `"Let's do some quests!"`,
  `"Today's quests"`, `'Waiting for Mum'`, `"Waiting for Mum's thumbs-up"`,
  `"Who's playing?"` all carry the straight `'` the HTML uses; the seed title
  renders `Reading – 20 minutes` with U+2013, matching the HTML's `&ndash;`;
  `Hi Maya!`, `Grown-ups`, `Pip`/`Shop`/`My jar`, `Pip is happy today`,
  `120 coins`. The only non-ASCII in `lib/features/kid_home` is `·` in
  `KidQuest.detail` and em-dashes in comments; `detail` is never rendered on
  K03. `4 done today` / `4 of 6 done` are the live DB values (DATA OVER
  MOCKS overrides the PNG's stale `3`). UK spelling (`Mum`); coins only, never
  `£`.
- **BOTTOM EDGE (owner rule)** — the dock's `Container(color: tokens.surface)`
  wraps its `SafeArea(top: false)`, so the inset sits *inside* the surface box
  (`kid_home_view.dart:603-697`). The bar's own surface therefore runs from
  y 720 to the physical edge in both themes with no meadow or sky strip and
  nothing coloured around the home indicator. This deliberately overrides the
  design PNGs, per the owner rule.
- **ALIGNMENT (owner rule)** — 20 px gutters on header, section row, cards and
  dock; measured dock button edges and card edges are on the same 20/370 lines.
- **DESIGN-SYSTEM usage** — no hex literals, no `Colors.*` except
  `Colors.transparent` on the four `Scaffold`s, no `google_fonts`, no
  `letterSpacing` override. `.kid-title` renders through `NestBalancedText`
  (`:523`) per the BALANCED HEADINGS rule; `tileBackground` and `wrapLabel:
  false` are used; the shared `NestPetStage` is called with the mandated
  `pip:`/`speech:`/`nestWidth:`/`nestHeight:`/`fixedPipHeight:` arguments and no
  local fork of the stage, bubble or hearts remains. The design-slot numbers
  (`_kNestBoxWidth/Height`, `_kPipSlotSize`, the crest constants, the `0.62`
  gradient stop) have no token equivalent and are each cited to the HTML/PNG in
  place; `NestDevice.height` replaced the hard-coded `844`
  (`kid_home_view.dart:797`). One number that *does* have a token is finding 2.
- **BALANCED HEADINGS** — `NestBalancedText` is used for `.kid-title` and
  nowhere else on the screen, as required.
- **TRIAL** — no `subscription_status` anywhere in the feature.
- **CHIP ROWS** — no interactive `NestChip` on this screen; both chips are the
  display-only `KidStatusChip`, so `NestChipWrap` does not apply.
- **Children's Code** — no analytics, ads, SDK, network, `print` or
  `debugPrint` in `lib/features/kid_home`. Only the **active** child's nickname,
  coins, happiness and Pip look are read (`watchAppState().activeChildId` →
  `watchChild(id)`); `watchActiveQuests(...).where(assigneeChildId == childId)`
  keeps the list to that child; writes touch only that child's own completion
  rows. No other child's data is reachable from this screen.
- **Error handling** — `errorMessage` is never rendered on K03. The failure
  card is fixed copy ('Oh no! Pip got lost.' / "Let's try again." / 'Try
  again') and a failed completion shows the fixed toast 'Hmm, that did not
  work. Try again.'. A raw `error.toString()` never reaches a child.
- **Lifecycle / streams** — `_onLoadRequested` owns exactly one
  `StreamSubscription<KidHomeData>`, guards against stacking a second
  never-ending handler on reload, and releases it on stream error and in
  `close()` (`kid_home_bloc.dart:26, 41, 47-53, 119-124`). Between the
  `if (_homeSub != null) return;` guard and the assignment there is no `await`,
  so two loads cannot interleave.
- **Performance** — one `BlocBuilder` over a ≤6-item list; `_MeadowPainter`
  carries `shouldRepaint` on its two colours so scrolling does not repaint it
  (the viewport moves the RenderObject); `PipAvatar` honours
  `kDisableAnimations`/`MediaQuery.disableAnimations` for its Rive path
  (`pip_avatar.dart:386, 431`), satisfying RULES §6. No rebuild storm: the
  heaviest rebuild is the 6-card column on a completion, and `_QuestCardState`
  keeps its own tap latch rather than rebuilding the list.
- **Test discipline** — 56 view tests / 34 bug tests / 15 bloc tests, 58 pump
  sites against 58 `disposeApp` calls (RULES §7 teardown drain honoured
  everywhere), zero `skip:` markers, and `analysis_options.yaml` untouched.

---

## Findings

### 1. [minor] No `SemanticsAction.tap` assertion pins any K03 control

`app/test/features/kid_home/*.dart` — zero matches for `SemanticsAction`,
`hasAction` or `performAction`.

RULES §8 and the orchestrator's ACCESSIBILITY ACTIONS rule both require this of
the *tests*: "Tests assert `getSemantics(f).getSemanticsData().hasAction(
SemanticsAction.tap)` for every control, and that `performAction(SemanticsAction
.tap)` changes the real state or DB." `2_build.md` §2 already named this as the
next stage's file to write; at HEAD it is still unwritten.

The behaviour itself is correct — I verified all 12 controls and all three
action paths above — so nothing is broken for a child today. What is missing is
the regression net: a future edit that drops an `onTap` from `NestKidButton`,
`NestLockButton` or the card wrapper would turn a silent VoiceOver dead zone
into a green suite.

**Fix (in scope, no code change needed):** add to
`app/test/features/kid_home/k03_bugs_test.dart` (or the view test) a test that
calls `tester.ensureSemantics()`, scrolls the quest list until the first
`Mark done` node is on screen, and asserts `hasAction(SemanticsAction.tap)` for
the lock, all six card bodies, both to-do checks and the three dock buttons;
then `performAction(tap)` on one check and assert both the `done_pending` write
via `GetIt.instance<KidHomeRepository>().getItems()` and the `/quest-complete`
push. **Scrolling first is required** — the to-do nodes sit at y 1133/1259,
below the 125…753 viewport, and an unscrolled tap silently does nothing (this is
the probe trap recorded above). The test stage is writing these assertions as I
review; they must be committed before the next verdict.

### 2. [minor] `_kQuestCardShadowRoom = 6` duplicates the existing `NestSpacing.gap6`

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:110`
(`const double _kQuestCardShadowRoom = 6;`), consumed at `:579`
(`spacing: NestSpacing.s3 - _kQuestCardShadowRoom`).

`NestSpacing.gap6` is exactly this value (`tokens/spacing.dart:35`), and the
companion test already asserts the same reserve against the token
(`kid_home_view_test.dart:472`, `closeTo(NestSpacing.gap6, 0.5)`). So the view
and its own test name the same 6 px two different ways, and the view is the only
place in the file that spells a bare `6` where a token exists — which is exactly
the drift the "tokens only" rule exists to prevent. The integrator flagged this
judgement call in `2_build.md` §5 and deferred it; it is right to defer, but the
token is unambiguous.

**Fix:** `const double _kQuestCardShadowRoom = NestSpacing.gap6;` (keeping the
doc comment and the SHARED_REQUEST #16(b) revert rule intact — the value must
stay exactly 6 until the shared card drops its own `EdgeInsets.only(bottom: 6)`,
at which point both this line and the test's `closeTo(NestSpacing.gap6, 0.5)`
assertion come out together).

### 3. [minor] `switchMapStream` still sits in `domain/` (carried since iteration 6)

`app/lib/features/kid_home/domain/kid_home_repository.dart:54-82`.

A generic stream combinator, not a domain abstraction. `ARCHITECTURE.md:71`
restricts `domain/` to "entities + abstract `<feature>_repository.dart` ONLY",
and `core/data/stream_combine.dart` already owns `combineLatest2/3/4`. The
comment explaining why `asyncExpand` cannot be used is genuinely good and must
travel with the function, not be lost.

**Fix (shared):** move it to `core/data/stream_combine.dart` next to the other
combinators; the three call sites are mechanical import swaps. Already requested
as SHARED_REQUEST #14, unchanged since iteration 6. Nothing available inside
K03.

### 4. [minor] The geometry pin measures the nest BOX, not the painted outline (carried, pet-gated)

`app/test/features/kid_home/kid_home_geometry_test.dart:101-105` asserts
`nest.width closeTo(236, 2)` — the `SvgPicture` box — and expresses the
design's real intent (a 198 px *visible* outline) only in the `reason:` string.
A widget test cannot sample painted alpha, so the pin stays green if
`PipNestFallback.visibleNestRatio` changes and the design's 198 px outline drifts
underneath it.

**Fix (in scope, no core change):** pass `visibleNestWidth: 198` instead of
`nestWidth: 236` — `nest_pet_stage.dart:135-136` divides by `visibleNestRatio`,
so the outline is then 198 *by construction*, immune to ratio drift — and
assert `nest.width * PipNestFallback.visibleNestRatio closeTo(198, 2)`. The
236-wide box that yields (235.3) still satisfies the existing ±2 box assertion,
so nothing else moves.

**Currently gated.** `ORCHESTRATOR_NOTES` line 79 forbids changing the
`NestPetStage` call until the `shared/pet_stage_seat` branch's report says so,
and I confirmed that branch has **not** landed (`pip_rive.dart:581` is still
`fit: BoxFit.fill`). Take this fix in the same pass as the pet-stage landing.

---

## Carried, shared-owned, deliberately NOT counted against K03

**The nest is stretched to 66 % of the design's vertical scale and sits ~26 px
low** (iteration-8 finding 1). I re-confirmed the cause is still present in
shared code — `PipNestFallback` renders the `nest.svg` art with
`fit: BoxFit.fill` (`app/lib/core/design_system/motion/pip_rive.dart:581`) into
the 236×156 box that `ORCHESTRATOR_NOTES` line 68 mandates K03 to pass
verbatim, giving `156/236 = 0.661` vertical scale. K03 passes the mandated call
byte-for-byte and has no local lever: `ORCHESTRATOR_NOTES` line 79 says "Do NOT
adjust the pet block locally and do not change the `NestPetStage` call unless
that branch's report says so."

Failing K03's review for a defect that lives in `core/`, that K03 was
explicitly ordered not to work around, and whose fix is already filed as
SHARED_REQUEST #16(a), would contradict the orchestrator's standing
instruction. It stays on the record, owned by `shared/pet_stage_seat`, and must
be re-measured by stage 5 once that branch lands. Likewise the feature-local
`_MeadowPainter` (finding 4 last iteration) stays carried behind SHARED_REQUEST
#6's two missing `KidScope` gradient stops — the interim band is within 1 level
of both design PNGs.

## Cross-screen note for the orchestrator (not a K03 finding)

The five baseline placeholder views of this feature still render
`state.errorMessage` verbatim into child-facing UI — `kid_pin_view.dart:21`,
`profile_picker_view.dart:21`, `quest_detail_view.dart:21`,
`quest_complete_view.dart:21`, `kid_home_done_view.dart:21`, all
`Text(state.errorMessage ?? 'Something went wrong')` — and K03's bloc fills
that field with `error.toString()` (`kid_home_bloc.dart:96`).

None of those files is in `git diff main...HEAD` (they are untouched baseline
scaffolding from `f912ef0`), and K03's own view correctly uses fixed copy
throughout, so this is not K03's screen and not counted above. But K03 owns the
bloc that feeds it, and a Drift/Dart exception string surfacing in a kid-facing
UI is a Children's Code issue the moment those screens go live. Whoever builds
K01/K02/K03b/K04/K05 should render fixed copy only; the cheap structural fix is
to stop putting raw exception text in a state field a view can render, or to
give the kid views a dedicated `kidErrorCopy` getter. Flagging it so it is not
rediscovered five screens from now.

---

## Verdict

The committed tree is green on every gate — format clean, `flutter analyze`
clean, `+1544: All tests passed!`, zero skipped proofs, no suppressions, no
fonts regressions — and the screen holds up on every rule I could check
mechanically or measure: RULES §1 paths, ARCHITECTURE ownership, the PIP, DATA +
PERIODS, CHILD ORDER, COPY, BALANCED HEADINGS, BOTTOM EDGE, ALIGNMENT and
TOKEN-ONLY rules, TRIAL, and Children's Code. Accessibility is not merely
present but correct end to end: all 12 interactive nodes expose
`SemanticsAction.tap`, all three action paths drive real state, the real DB and
real navigation, and the display nodes correctly claim no action. Layout holds at
320 wide with 20 px gutters intact and no overflow, and the shape measurements
match the design's 56 px lock and dock edges.

Four findings, all **minor**, none requiring a code change to the screen's
behaviour:

1. the mandated `SemanticsAction.tap` assertions are not yet written (behaviour
   verified correct; the test stage is adding them now — they must be committed
   before the next verdict);
2. `_kQuestCardShadowRoom` should read `NestSpacing.gap6`;
3. `switchMapStream` in `domain/` (carried, SHARED_REQUEST #14);
4. the nest-box pin should become a `visibleNestWidth: 198` pin once the pet
   branch allows the call to change.

The one visual deviation still open — the squashed, low nest — lives in
`core/`, is explicitly fenced off from K03 by `ORCHESTRATOR_NOTES`, and is
already filed as SHARED_REQUEST #16(a); it is recorded above rather than charged
to this screen.

VERDICT: PASS
