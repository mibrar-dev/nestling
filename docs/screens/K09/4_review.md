# K09 · My jar — QA code review (stage 4, iteration 1)

Scope: `git diff main...HEAD` (26 files, +3135/−75) reviewed against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 K09
(line 206), `docs/design/SPACING_SPEC.md`, the orchestrator rulings in the stage
brief and the design sources (`design/html-source/screens/K09-jar.html`,
`design/screens/{light,dark}/K09-jar.png`). No code was edited. No simulator was
booted, installed on or driven (stage 5 only). PNGs were read with the file
reader / a pixel probe, never attached.

## Scope + hygiene — clean

`git diff main...HEAD --name-only` touches only
`app/lib/features/kid_jar/{data,domain,presentation}/**`,
`app/test/features/kid_jar/**` and `docs/screens/K09/**` — inside RULES §1.
Nothing in `app/lib/core/**`, `app/lib/app/**`, another feature or
`tools/screens/**`. `SHARED_REQUEST.md` and `ORCHESTRATOR_NOTES.md` are both
absent (correct — see finding 1 for the one that is now needed).

Independent re-verification of the committed diff:

- `flutter analyze lib/features/kid_jar` + the four committed test files →
  **No issues found!**
- `flutter test --timeout 120s` on the four committed `kid_jar` files →
  **40/40 pass** (00:05). `test/core/data/repositories_test.dart` is unaffected
  by the snapshot refactor (build stage: 22/22).
- No `DateTime.now()` and no `google_fonts` / `GoogleFonts.*` anywhere in
  `app/lib/features/kid_jar` or `app/test/features/kid_jar` (the only two hits
  are the words inside comments). Clock is `appNowUtc()` /
  `londonWeekStartUtc()`; ids come from the DB, none derived from the clock.
- Every pumped widget test ends with `disposeApp(tester)`. The Drift
  "created the database class multiple times" warning in
  `my_jar_view_geometry_test.dart:69` is Drift's multi-in-memory-DB notice for
  the 320/390/430 loop, matching the repo-wide pattern; it does not fail.

## Findings

No blocker. No major. Six minor.

### 1. minor — `NestProgress`'s kid gloss spans the whole track, not the fill (shared code)

`app/lib/core/design_system/components/nest_progress.dart:43-58` — the kid
variant paints the white 55 % gloss in a `Stack` with
`Positioned(left: s1, right: s1)`, i.e. across the **entire** track width, not
inside the `FractionallySizedBox` fill.

Measured on `design/screens/dark/K09-jar.png` at log y 562: the fill (leaf
`#3CC98A`) runs x 43.7…229.3 and the gloss (leaf + 55 % white, `#A7E7CA`) runs
x 45.3…227.7 — it stops at the fill's right edge, exactly like
`components.css:160` (`span::after` inside `span`). In the app the track is
`--surface` `#1F1C2E` in dark, so a 55 %-white band will render over the empty
38 % of the bar (≈ x 232…345) where the design shows plain dark surface. In
light mode it is invisible (white on white), which is why the light PNG looks
clean.

This is **not** K09 code and K09 may not edit `core/**` (RULES §1), and it
reuses `NestProgress` exactly as the "never re-implement components" rule
requires — so it is not a defect in this diff. `kid_home_view.dart:495` and
`pip_growth_card.dart:83` already ship the same `kid: true` bar, so the
deviation is pre-existing app-wide.

Fix (shared, one line): move the gloss inside the fill, e.g. wrap the fill
`Container` in a `Stack` and put the `Positioned` gloss there, or clip the
gloss to `FractionallySizedBox(widthFactor: f)`.

**Action:** file `docs/screens/K09/SHARED_REQUEST.md` for it, and in stage 5 do
**not** attribute this band to K09 — it will show in the dark comparison and is
not fixable in this branch.

### 2. minor — an over-saved goal would tell the child a false "£X to go"

`app/lib/features/kid_jar/presentation/widgets/jar_goal_card.dart:37`
(`int get remainingPence => targetPence - savedPence;`) combined with
`jar_amounts.dart:16` (`jarPounds` applies `.abs()`) means `savedPence >
targetPence` renders a positive "£1.20 to go" — a claim that is simply untrue on
a screen whose whole job is to tell a child their money is safe. The demo seed
(1550/2499) never hits it, which is why no test catches it.

Fix: `int get remainingPence => targetPence > savedPence ? targetPence - savedPence : 0;`
and add a `JarGoalCard` widget test with `savedPence: 2600, targetPence: 2499`
asserting `£0.00 to go` (and no overflow). Do **not** "fix" it by dropping
`.abs()` in `jarPounds` — a negative hero would break the `£x.xx` contract.

### 3. minor — the money formatter is split across layers, and one of the two homes is in the wrong folder

- `app/lib/features/kid_jar/domain/entities/jar_snapshot.dart:30` —
  `formatJarAmount(pence)` is *presentation* formatting (`+£3.80` / `+12p`)
  sitting in a domain entity file. ARCHITECTURE §"Per-feature contract" says
  `domain/` is "entities + abstract `<feature>_repository.dart` ONLY".
- `app/lib/features/kid_jar/presentation/widgets/jar_amounts.dart` — a file in
  `presentation/widgets/` ("feature-private widgets") that contains **no
  widget**; its only member is `jarPounds`, the sibling formatter doing the
  same job for `£x.xx`.

Two formatters for one screen, one of them misfiled. Fix: fold both into one
feature-private formatter next to the entity that produces the pence
(`jar_snapshot.dart`, or a `JarMoney` class in the same file), delete
`jar_amounts.dart`, and update the two call sites
(`my_jar_view.dart`, `jar_goal_card.dart`). Pure refactor, no visual change.

### 4. minor — `watchJar()`'s doc comment contradicts the code it documents

`app/lib/features/kid_jar/data/kid_jar_repository_impl.dart:28-30` says the
stream "fans out to exactly one entries query plus one summary query". It does
not: `_jarFor` (line 39-59) opens **one** `watchLedger` subscription and derives
both the list and the summary from it — which the comment eight lines below
(line 40-42) states correctly. The atomicity argument only holds for the version
that is actually implemented, so the wrong sentence is the one a future editor
would trust. Fix: make lines 28-30 say "one `watchLedger` query that feeds both
the list and the summary" and drop the redundant restatement at line 40.

### 5. minor — `watchItems()` silently changed meaning for the sibling screen

`kid_jar_repository_impl.dart:23-26` now serves **money-in rows only** with
`This/Last {weekday}` details; it used to serve every ledger row with
`formatDay(...)`. `PayoutDayView` (K10) shares `KidJarBloc`
(`kid_jar_routes.dart`, unchanged) and renders `state.items`, so K10's data
changes shape. Nothing shipped is broken — K10 is still the foundation
placeholder — and the new behaviour is documented in the doc comment, but K10's
own loop has not been told.

Fix: no code change; add one line to `docs/screens/K09/2_build.md` (or the
handover section) naming K10 so the K10 loop does not assume the old contract.

### 6. minor — the loading frame's label is not a live region

`app/lib/features/kid_jar/presentation/views/my_jar_view.dart:290-293` —
`Semantics(label: MyJarCopy.loading, child: CircularProgressIndicator(...))`
with the default `container: false` and no `liveRegion: true`. The frame swaps
in silently for a screen reader, so a child waiting on a slow stream gets no
announcement.

Fix: `Semantics(liveRegion: true, container: true, label: …)`, and assert
`tester.getSemantics(find.byType(CircularProgressIndicator))` carries the label
in the loading-state test.

## Verified correct (no finding)

- **Architecture.** One bloc per feature, `BlocProvider` + `KidJarLoadRequested`
  at the route (`kid_jar_routes.dart`), DI in `kid_jar_di.dart`, both untouched
  and both already correct. Domain = entities (`JarEntry`, `JarSummary`, new
  `JarSnapshot`) + abstract `KidJarRepository` only; no use-case classes, no
  extra folders, no utils dump, all imports `package:nestling/...`.
  `watchJar()` is on the abstract interface, not smuggled past it.
- **Design-system reuse.** `KidScope`, `NestStatusBar`, `NestIconButton`,
  `NestLockButton`, `NestProgress`, `NestKidButton`, `NestIcon`,
  `NestBalancedText`, `SvgPicture.asset(NestlingIllustrations.coin)`. Every
  colour/size/radius/font comes from tokens (`NestSpacing`, `NestDevice`,
  `NestRadii`, `NestTokens.colors`, `context.nestKid.borderWidth`,
  `tokens.kidShadow`, `NestType.kidTitle/kidHero/kidBody/kidCaption`). The only
  literals are per-design geometry constants (`_backIconSize = 26`,
  `_artSize = 34`, `_rowMinHeight = 60`, `_discSize = 40`, `_dividerInset = 66`,
  the `fontSize`/`height` `copyWith`s), each with the HTML line it comes from —
  the sanctioned call-site pattern.
- **The transcribed jar palette is right in BOTH themes.** `_JarPalette`
  hard-codes the SVG's own fills, which the rules otherwise forbid — but the
  design does the same, and I sampled both PNGs: light *and* dark show lid
  `#7C6CF2`, glass `#F2FAFF`, coin mass `#E09700`, coins `#F4B400`, outline
  `#1E1B3A` (dark sky is `#F3F0FA` behind it). Only the ground ellipse follows
  `tokens.groundShadow`. The 200×236 → 186×220 letterbox maths
  (`scale 0.93`, `offsetY 0.26`, `save`/`restore` balanced, coins clipped to the
  fill *and* the glass) reproduces the design's own geometry.
- **Geometry, measured off the PNG.** Ink bands read from
  `design/screens/light/K09-jar.png` agree with the code's asserted boxes:
  goal card exactly **465…618** (h 153 — and the CSS box model closes on it:
  3 + 14 + 34 + 12 + 23 + 6 + 16 + 8 + 20 + 14 + 3), list top **676**, progress
  **557…573 × x 39…351**, title ink 112.67…138, jar ink 153.33…354 (= box top
  151), amount ink 383.67…412.33 centred on 194.8, "coming on" ink 429.33…445.33,
  "What went in" ink 638.67…653, row-1 disc **689…729**, divider **739…741 ×
  x 89…367**. The scroll viewport really is 107…810 (below 810 the PNG is meadow
  green `#CCEDC0` with the home pill at 825…830), which is what
  `SafeArea(bottom: true)` gives. Internal gutters check out too: goal card
  content at x 39 / 351 (design ink 39.67 / 350.33), coin art 43.67…68.33,
  goal title ink from 84.33 (box 83 = 39 + 34 + 10).
- **Spacing.** The 10 px title→jar gap is the design's `.jar { margin: 10px auto 0 }`
  winning the cascade over `.scroll > * + *` (equal specificity, later rule) —
  not an off-by-6. Every other separator is `s4`/`s3`/`s2`/`gap2`/`gap6`/`gap10`
  exactly as the CSS box model computes. 20 px gutters on both sides at 320/390/430,
  cards and heading share one left edge.
- **`_JarEntryRow`'s 8 px before the value looks like a deviation** (`.k9-row`
  is `gap: 12px`) but is visually inert: the middle child is `Expanded`, so the
  value's box is pinned to the row's content edge (353) and the gap is absorbed
  — confirmed against the design, where `.k9-main { flex: 1 }` gives the same.
  Recorded so nobody "corrects" it to 12 in isolation.
- **Copy.** Character-exact against `K09-jar.html:45-101`: `My jar`, `Back`,
  `Grown-ups`, `coming on Saturday`, `What went in`, `£4.20`, `Lego Friends set`,
  `£15.50`, `£9.49 to go`, `of £24.99`, `62% there!`, `Pocket money`,
  `Quest bonus`, `From Mum`, `+12p`, `+£10.00`,
  `Mum keeps the real money. This jar just shows how well you have done.` —
  no straight quotes, no hyphen where the design has none. Non-design copy
  (loading / error / empty) is kid-voice UK English.
- **Cascade rulings held up.** `<span class="kid-hero money">` really is
  **w700**, not w900: `.money` (`components.css:155`) and `.kid-hero`
  (`:37`) are both (0,1,0) and `.money` comes later. And `.k9-v` *is* w900
  because the screen's own `<style>` block loads after `components.css`. So the
  hero's `fontWeight.w700` and the values' `w900` are both right.
- **`NestBalancedText`** on both `.kid-title` headings (`:47`, `:82`) — including
  the screen-local 20/26 override — and plain `Text` on the goal card's bare
  `h2` and on `.kid-body`/`.kcap`, i.e. never on a body/caption.
- **Letter spacing** is 0 everywhere (`NestType` default), nothing added back.
- **DATA OVER MOCKS.** Seed wins on every number: `+£3.00` where the design's
  example row says `+£3.80`, nine rows where the design shows three, and the
  test says why. `_relativeDay` gives `This Saturday` for the anchored
  weekly base and `Last Sunday` for the previous week — correct under the
  PERIODS ruling (`londonWeekStartUtc` / `toLondon`, no wall clock).
- **Row filter.** Only `{weekly_base, quest_bonus, gift}` reach the jar;
  `payout`/`spend`/`savings_move` never do, and the `_summarize` `break` on the
  first `payout` still computes owed from the newest rows. `watchLedger` is
  already date-desc, so newest-first holds.
- **No Pip on K09** (the design shows a jar, not Pip), so the PIP rule does not
  bite; the screen takes no `pip_style`/`stage`.
- **Bottom edge.** K09 has no bar, so the shared meadow (KidScope, bottom 0,
  full width, 136) runs to the physical edge; nothing paints a coloured strip
  and the OS draws the home indicator.
- **Child order / £ / coins.** No child list on this screen (so no ordering
  risk); K09 is the one sanctioned £ screen.
- **Semantics.** Both controls expose `SemanticsAction.tap` and the tests
  assert it *and* `performAction` (the lock really pushes `/parental-gate`).
  No `Semantics(excludeSemantics: true)` wrapper hides a control — the one
  wrapper in the view is on a non-interactive amount/label pair. Rows correctly
  claim **no** tap (a test asserts `isFalse`, and the empty-row host repeats
  it). Header on the title, `image: true` + design label on the jar, progress
  carries the design's `62% of the Lego Friends set saved` + a value.
- **Performance.** `BlocBuilder` sits inside `Expanded`, so a snapshot emission
  rebuilds the body only — chrome and `KidScope` never re-run. The painter's
  `shouldRepaint` compares `fillFraction` and `groundShadow`. One `watchLedger`
  subscription per child (not two racing ones). `_switchMap` cancels the inner
  subscription on `onCancel`, so the Drift stream is disposed with the bloc;
  its documented deviation from `asyncExpand` (which would deadlock on
  never-closing watch streams) is correct and explained.
- **Error handling.** The old placeholder rendered `state.errorMessage` to a
  child; the new failure frame shows kid copy plus a `Try again` that re-adds
  `KidJarLoadRequested`, and `copyWithLoaded` clears the stale error on the
  first healthy emission while the retry spinner carries it (K03 precedent,
  and tested).
- **Children's Code.** No analytics, ads, tracking, network calls, `debugPrint`
  or PII output anywhere in the diff; nothing leaves the device; no red, no
  nagging, no streak or loss framing.

## Observations (loop-owned, explicitly NOT findings)

Per the orchestrator's PROCESS ITEMS rule these are uncommitted-work facts, not
blockers/majors — recorded only so the loop does not trip over them.

Four **untracked** files appeared in `app/test/features/kid_jar/` *during* this
stage (18:34–18:38, i.e. after this stage's marker) and are not part of
`git diff main...HEAD`: `_probe_probe_test.dart`, `_probe_probe2_test.dart`,
`_scratch_probe_test.dart`, `my_jar_view_states_test.dart`. They make
`flutter analyze` over the whole `app/` report 20 info-level issues (18
`document_ignores` + 2 `deprecated_member_use` + `eol_at_end_of_file` in the
states test, plus 5 real compile-level infos — 3
`undefined_identifier`/`non_type_as_type_argument`/`unchecked_use_of_nullable_value`
— in the scratch probes). The committed diff analyzes clean on its own
(`No issues found!`). The loop should delete the `_probe*`/`_scratch*` files and
either land `my_jar_view_states_test.dart` lint-free (RULES §7 forbids ignores)
or drop it, before the stage-5 build.

## Verdict

The diff is faithful to the design source (copy, cascade, spacing, geometry all
re-derived from the PNG and the HTML), reuses the shared design system instead of
re-implementing it, keeps the feature-first layering, and disposes its streams.
Nothing found rises above minor; none of the six is a blocker or a major, and
finding 1 is the only one that needs a hand-off (`SHARED_REQUEST.md`) rather
than an in-branch fix.

VERDICT: PASS