# K07 · Pip evolves (`/pip-evolution`) — Stage 6 bug hunt (iteration 2, second pass)

Adversarial pass over K07 **as it stands after the iteration-2 build `34abefa`**
and the stage-3/4/5 work that followed it (`3_test.md`, `4_review.md`,
`5_ui.md`, plus the orchestrator's 23:55 ruling). **This stage changed no
product code** — RULES §1 lets a bug hunt add only `app/test/features/pip/**` and
`docs/screens/K07/**`, and `git status app/lib` is empty at the end of it (the
one fix below was applied to verify it, then reverted from the index — evidence
in its own section). No simulator was booted, installed on or driven: only
`5_ui` may touch `BC440E48-B3A3-43BC-971B-0EF5DB621874`, and the screenshots
quoted below are the ones `5_ui.md` already captured. No `flutter clean`, no
`analysis_options` change, no skipped gate, no `google_fonts`, no
`DateTime.now()`.

Deliverable: `app/test/features/pip/k07_bugs_test.dart` — **1 skipped failing
proof** (K07-BUG-5, the new finding) on top of **23 tests that pass**: the four
iteration-1 proofs, now un-skipped because the build fixed them, and **9 new
controls** added by this pass.

## Verdict summary

| # | Severity | Status | Summary | Proof |
|---|---|---|---|---|
| **K07-BUG-5** | **MAJOR** | **OPEN** (orchestrator-mandated, fix specified) | In DARK the whole `svg.sparks` layer is stroked and filled from the **dark** theme's tokens, so every one of the four sparkles and every dot gets a `#F3F0FA` white ring and lighter fills. The design's `<g stroke="#1E1B3A">` and its literal fills are theme-invariant by construction; the dark design PNG paints them at their light values. This is `5_ui.md` **D4** / `cmp_dark_2.png`, `4_review.md` finding 9, now ruled **mandatory** by `ORCHESTRATOR_NOTES.md` (23:55). | `k07_bugs_test.dart` → `K07-BUG-5: in DARK the sparkles are stroked and filled from the DARK theme's tokens…` (real app shell, palette sampled off the painter's own raster) |
| K07-BUG-4 | ~~MAJOR~~ | **FIXED** (re-verified) | Every sparkle used to lose its `M` tip vertex (`moveTo` + `addPolygon`), painting as a flat-topped blob — `5_ui.md` D2. | now green: `K07-BUG-4: …` + `k07_sparkles_bug_test.dart` (3 proofs) |
| K07-BUG-1 | ~~MAJOR~~ | **FIXED** (re-verified) | A *pending* evolution stream used to render the load-failure card "Oh no! Pip got lost.", with a dead "Try again". 5 of 5 cold opens. | now green: `K07-BUG-1: …` (widget) + `K07-BUG-1 (real repository, no fakes)…` (state level) |
| K07-BUG-3 | ~~minor~~ | **FIXED** (re-verified) | The `quests done` card counted completion **rows**, inflating a milestone that is about quests. | now green: `K07-BUG-3: …` + `K07-BUG-3 (repository, no widget tree)…` |
| K07-BUG-2 | ~~minor~~ | **FIXED** (re-verified) | At 320 px the grown 240 px Pip covered the 68 px "before" Pip and the 30 px arrow. | now green: `K07-BUG-2: at 320 px …` (the slot now downscales as one piece below 350 px) |

**VERDICT: FAIL** — one major bug, **K07-BUG-5**, which the orchestrator has
already ordered fixed (3 lines in one feature file, verified green by this
stage). Everything else in the brief's hunt matrix is clean.

---

## K07-BUG-5 — MAJOR — the dark-mode sparkles are painted from the wrong palette

**Where** `app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart`
— `_SparksPainter.paint` (`:151`, the `stroke` paint) and `_Spark.colorOf`
(`:74-80`).

```dart
final stroke = Paint()
  ..color = tokens.ink          // ← dark theme: #F3F0FA
  ..style = PaintingStyle.stroke
  ..strokeWidth = EvolutionSparksGeometry.strokeWidth
  ..strokeJoin = StrokeJoin.round;
…
Color colorOf(NestTokens tokens) => switch (fill) {
  _SparkFill.lilac => tokens.lilac,      // ← dark theme: #A89BFF
  _SparkFill.success => tokens.success,  // ← dark theme: #3CC98A
  _SparkFill.coin => tokens.coin,        // ← same in both themes: #F4B400
  _SparkFill.peach => tokens.peach,      // ← dark theme: #FF9E78
  _SparkFill.sky => tokens.sky,          // ← dark theme: #7FA9FF
};
```

**Repro (deterministic, ~2 s, no simulator)**

1. `pumpAppRoute(tester, '/pip-evolution', theme: ThemeMode.dark)` — the real
   app shell, because `context.nest` is
   `Theme.of(context).extension<NestTokens>()!` and a painter wrapped in its own
   `MaterialApp` can resolve the *light* palette.
2. Take the `CustomPaint`'s painter under `PipEvolutionSparks`, rasterise it at
   `EvolutionSparksGeometry.artSize` (350 × 220) and read single pixels at the
   design's own `viewBox` coordinates.

**Evidence — sampled off the painter's own raster (RGB, alpha dropped; every
sample is a solid fill or a solid stroke pixel)**

| sample (art coords) | design `K07-evolution.html:36-44` | app LIGHT | app DARK | |
|---|---|---|---|---|
| stroke on sparkle 1's left point `(13, 49)` | `<g stroke="#1E1B3A">` | `#1E1B3A` | **`#F3F0FA`** | ✗ white ring |
| sparkle 1 fill `(32, 49)` | `#7C6CF2` | `#7C6CF2` | **`#A89BFF`** | ✗ |
| sparkle 2 fill `(312, 43)` | `#1F9D63` | `#1F9D63` | **`#3CC98A`** | ✗ |
| sparkle 3 fill `(18, 167)` | `#F4B400` | `#F4B400` | `#F4B400` | ✓ (same token) |
| sparkle 4 fill `(334, 169)` | `#FF8A5B` | `#FF8A5B` | **`#FF9E78`** | ✗ |
| gold dot `(86, 10)` | `#F4B400` | `#F4B400` | `#F4B400` | ✓ |
| sky dot `(268, 8)` | `#3D7FF0` | `#2563D6` | `#7FA9FF` | `5_ui.md` D5, see below |

This is byte-for-byte what the UI stage measured on the device
(`5_ui.md` D4's table: `#7C6CF2 → #A89BFF`, `#1F9D63 → #3CC98A`,
`#FF8A5B → #FF9E78`, `#3D7FF0 → #7FA9FF`) and what `cmp_dark_2.png` shows. The
proof just makes it reproducible in CI, with no simulator.

**Why the ruling flipped.** `5_ui.md` filed D4 as *"the app is on the right side
of the rules — never hard-code colours, tokens only"* — correct against the
19:10 note ("token fills"). Six minutes later the orchestrator overrode its own
earlier wording:

> `ORCHESTRATOR_NOTES.md` (23:55, iteration 3, **mandatory**): *"D4 sparks in
> DARK mode: the design's `svg.sparks` uses FIXED hex colours, not theme
> variables … The app currently strokes with the dark theme's `ink` (#F3F0FA) and
> uses the dark accent fills, so every sparkle and dot gets a white ring in dark
> mode (cmp_dark_2.png). Fix in `pip_evolution_sparks.dart` only … Verify each
> fill hex equals the HTML's literal. Add a widget/painter test under dark theme
> asserting the stroke colour is 0xFF1E1B3A. UI check: re-measure dark sparkles;
> they must show no light outline."*

**Impact.** 100 % of dark-mode sessions on the celebration screen. The confetti
is the thing that makes the moment read as a celebration, and in dark it is drawn
as bright, white-ringed stars instead of the design's flat coloured ones — a
designer comparing the two PNGs rejects it, and the loop's own UI check already
did. It is confined to decorative art: no data, state, a11y or copy impact.

**Failing test** — `cd app && flutter test --timeout 120s --run-skipped test/features/pip/k07_bugs_test.dart`

```
K07-BUG-5: in DARK the sparkles are stroked and filled from the DARK theme's tokens,
so all four sparkles and every dot get a light ring on the night sky — the design's
`svg.sparks` is a fixed, theme-invariant palette
  Expected: <1973050>            ← 0x1E1B3A
    Actual: <15986938>           ← 0xF3F0FA
```

**Suggested fix** — feature-local, RULES §1-legal, exactly the orchestrator's
recipe (`pip_evolution_sparks.dart` only, 6 lines):

```dart
// `_Spark.colorOf` — the design's fills are inline hexes, so they come from the
// LIGHT palette in both themes (it is still tokens-only, no literal hex).
Color colorOf(NestTokens tokens) => switch (fill) {
  _SparkFill.lilac => NestColors.light.lilac,
  _SparkFill.success => NestColors.light.success,
  _SparkFill.coin => NestColors.light.coin,
  _SparkFill.peach => NestColors.light.peach,
  _SparkFill.sky => NestColors.light.sky,
};
// `paint()`: ..color = NestColors.light.ink
// `shouldRepaint` no longer depends on the theme (the layer is now invariant).
```

**Fix verified, then reverted** (this stage may not fix the screen): with the
patch applied, `flutter test --timeout 120s --run-skipped
test/features/pip/k07_bugs_test.dart test/features/pip/k07_sparkles_bug_test.dart`
→ `+27: All tests passed!` — K07-BUG-5 goes green **and** the three D2 shape
proofs stay green, i.e. the fix does not disturb the verified sparkle geometry.
The working tree was then restored from the index
(`git status --porcelain app/lib` → empty, `tokens.ink` back at line 151), so the
shipped code still fails the proof. The next build stage only has to drop
`skip: true`.

**One honest loose end in the ruling.** "resolve every fill from `NestColors.light`
… verify each fill hex equals the HTML's literal" agree for lilac / success /
coin / peach (the light tokens *are* the HTML's hexes). They cannot both hold for
the **sky dot**: `#3D7FF0` is not a token in either theme (`--sky` is `#2563D6`
light, `#7FA9FF` dark — `5_ui.md` D5, a design-source bug for whoever owns the
HTML). After the mandated fix the sky dot is `#2563D6` in both themes: theme-
invariant, which is the ruling's intent, but not the HTML's literal. The proof
therefore asserts the four token-backed accents **and** asserts that the whole
dark palette equals the light one (the design's real invariant, and it covers any
accent added to `_sparks` later), while *reporting* the sky dot's hex in the
failure reason instead of pinning a value the rules forbid.

---

## Iteration-1 bugs — disposition (all four closed by build `34abefa`)

The product code changed under this stage's feet since iteration 1's hunt, so
every id was re-measured rather than assumed. All four proofs are now
**un-skipped and green** (the build stage dropped `skip:` in the fix commit, the
repo convention), and the values below are today's, not iteration 1's.

| id | what the build did | what this stage re-verified |
|---|---|---|
| **K07-BUG-1** (major) | `PipState` grew per-stream arrival + error slots (`nestSettled`/`nestError`, `evolutionSettled`/`evolutionError`) with `nestStatus`/`evolutionStatus` getters; the view switches on `state.evolutionStatus` only; the sibling branch that painted the false failure card is gone. | Cold open against the shipped `PipRepositoryImpl`: **0 of 5** publishes a "nest but no evolution" state (was 5 of 5). A still-pending stream shows the spinner with **no** retry button; when the gate opens the celebration replaces it. A **nest** failure can no longer blank the celebration (the mirror of the deleted branch) — pinned in `pip_evolution_stream_contract_test.dart`. A **mid-session evolution failure after the data is on screen keeps the celebration** (no card, CTA still working) — measured this pass. |
| **K07-BUG-2** (minor) | The `.k7-stage` slot is wrapped in `FittedBox(scaleDown, bottomRight)` below 350 px of slot width; at 390 px the geometry is byte-identical (scale 1.0). | 320 px: arrow 96..126 / old Pip 22..90 / grown Pip 54..294 → the grown Pip no longer reaches the arrow or the silhouette (the proof's `≥ -2 px` overlap holds). 280 px: old Pip 21.4..68.0, arrow 72.1..92.7, grown Pip 91.3..255.9 → a 1.4 px tuck, the design's own relationship. 430 px: still scale 1.0 (pinned in `pip_evolution_stream_contract_test.dart`). |
| **K07-BUG-3** (minor) | `PipEvolution` gained `questsFinished` (distinct) beside `questsDone` (rows); `watchEvolution` reports both; the card is fed `questsFinishedCount`, the sub-line keeps the row count. | A second `approved` row for `q-bins` leaves the card at **4** (4 distinct quests) while the sub-line honestly says "Because you helped 5 times" — the two sentences no longer contradict. `questsFinished: 0` is a count, not a missing value (pinned in the contract suite). |
| **K07-BUG-4** (major) | `_sparkPath` hands every vertex, the `M` pair included, to one `Path.addPolygon`; the four paths are parsed once and cached. | `5_ui.md` D2 measures 0.00 px at all four spots on device; in CI, `k07_sparkles_bug_test.dart`'s three proofs pass (the silhouette is pixel-identical to a reference built independently from the HTML's `d` strings, the tip rows 29..33 carry ink, and every inked row is centred on the design's x = 32 axis). |

---

## The brief's hunt matrix — what this pass measured

Every item is now pinned by a permanent test; the numbers are this pass's.

| item | result | pinned by |
|---|---|---|
| **0 children** | `Seed.empty()` (onboarded family, no children, `active_child_id` null) → "Who's playing?" + `Choose` → `/who-is-playing`, **no** retry button, no spinner. A ghost `active_child_id` behaves identically. | `control: no active child offers the picker, not a failure`; `Seed.empty()` also in `pip_evolution_view_test.dart` / `_a11y_` / `_stream_contract_` |
| **a child picked afterwards** | The no-child card **live-updates** into the celebration (`Pip grew into a Hatchling!`, "Because you helped 2 times", `Meet Hatchling Pip`) with no reload and no dead end. | `control: the no-child card live-updates…` |
| **1 child / 6 children** | Deleting Leo keeps Maya on screen with no picker prompt; with four extra children inserted, K07 still follows the ACTIVE child (`quests 4`, "Maya's Pip, a fledgling") — the roster never leaks onto this screen. | `control: one child, six children and a deleted sibling…` (new) |
| **active-child switch** | Maya → Leo retitles the hero, sub, coins, CTA and the Pip's VoiceOver image label together, with no stale frame. | `control: switching the active child Maya -> Leo…` |
| **long UK names** | "Maximilian-Alexander" (19 chars) at 320 px / scale 1.3 / dark: no overflow, no exception. The name is only ever in the a11y label, never painted. | `control: 9999 coins and a 19-character name hold…` |
| **9999 coins / 0 / 999999999** | All survive the card (`0`, `9999`, `999999999`) with no elision and no overflow. | `control: 0 and 999999999 coins…` (new) + the 9999 control |
| **empty lists** | 0 completions → card `0` + `Because you helped 0 times`; 1 completion → card `1` + `Because you helped 1 time` (singular branch intact). K07 has no list of its own to be empty. | `control: 0 and 999999999 coins…` (new) |
| **`pip_stage` out of range** | 0, 5 and 99 all clamp into the 1..4 artboards (no `PipAvatar` assert), and the copy follows the clamped stage ("Pip grew into an Egg!" / "…a Songbird!", CTA and stat card included). | `control: pip_stage 0, 5 and 99…` (new) |
| **repeated quest completion** | Distinct-quest milestone + honest per-completion sub-line (K07-BUG-3, fixed). | `K07-BUG-3` ×2 |
| **rapid double taps** | CTA → `/pip` once; lock → one gate, pop returns and the CTA still works; retry → exactly **one** re-subscription per tap (`evolutionCalls` 1 → 3 for two taps), never a stacked pair; no-child `Choose` → the picker. | `control: a rapid double tap…` ×3 (one new) |
| **back navigation / deep links** | CTA → `/pip`, then a deep link back to `/pip-evolution` re-loads cleanly (new bloc, celebration back, no exception). Lock → gate → system back → `/pip-evolution`. 12-iteration interaction storm (theme flips, 320/390 px resizes, CTA taps, deep links, gate push/pop, data churn): **zero** exceptions. | measured this pass; the CTA/lock round-trips are pinned in the existing controls |
| **state after app restart** | File-backed DB: write `pip_stage = 4`, `pip_total_coins = 260`, close, reopen → `{questsDone 4, distinct 4, stage 4, coins 260}`. Nothing on K07 is cached in memory. | `control: the screen's numbers survive a database reopen…` (new) |
| **parent/kid mode guard** | Kid mode + an aged `trial_start` (expiry derived by `AppSession`, never by writing `subscription_status`) → cold deep link lands on `/parental-gate`, K07 never paints. No bypass. Parent mode may open `/pip-evolution` — it is not on the router's `parentOnly` list, which is intended (a grown-up may inspect the child's moment). | `control: kid mode with an EXPIRED trial…` + `control: PARENT mode may open…` (both new) |
| **dark-mode contrast** | Every text pair clears 4.5:1 — and note the screen's text sits on the **glow**, not on `--surface` (`radial-gradient(118% 62% at 50% 36%, --lilac-tint …)`), so `ink2` on `lilacTint` measures **7.59** (light `#4A4668` on `#EEEBFF`) and **8.36** (dark `#C9C4DC` on `#2B2550`); the CTA pair `onAccent`/`lilacStrong` is 5.03 light / 7.74 dark. The stat cards paint on `--surface` and the merged a11y sentence carries the same numbers. What does **not** clear is the sparkle palette — **K07-BUG-5**. | measured this pass (iteration 1 measured the surface pairs) |
| **text scale 1.3 + width 320** | No overflow at 320/1.3 or 320/2.0. Widened to a matrix: **280×360, 320×568, 390×844, 768×1024 and 844×390 landscape**, all at text scale **2.0** — zero overflow exceptions, the CTA is never dropped, and the caption (the last line of the design's copy) is reachable by scrolling and comes to rest above the bar rather than under it. | `control: no overflow from a 280x360 phone…` (new) + the 9999-coins control |
| **async gaps** | A pending evolution stream shows the spinner, not the card (K07-BUG-1, fixed). A late emission after the whole app is torn down throws nothing. A DB write committed mid-load is tolerated. Rapid active-child flips emit a clean alternating sequence with no stale or duplicated value (`[Maya/4, Leo/2, Maya/4, Leo/2, Maya/4, Leo/2]`). | K07-BUG-1, `control: a late stream emission after…`, plus the contract suite |
| **timezone / BST** | Not applicable, and provably so: `watchEvolution` counts rows and reads **no clock** (`pip_repository_impl.dart:92-99` says so in a comment); K07 shows coins, never `£` (the jar screens own money), so there is nothing to round. The demo's four Maya completions sit inside the current London week, so the numbers are period-independent and a BST change cannot move them. The PERIODS ruling (`countsForCurrentPeriod`) governs a quest's *current-period* status on K03/P08; K07's card is a lifetime milestone on purpose (`1_plan.md` §(b), and `pip_evolution_data_test.dart` pins "a month-old completion still counts"). | `pip_evolution_data_test.dart` (the lifetime decision) + this stage's read of `watchEvolution` |

## Carried from stage 4 (not re-reported as this stage's findings)

`4_review.md` (iteration 2) already owns three minors; this stage did not
duplicate them and did not fix them:

1. `toLoading()` clears both arrival flags while a retry only re-subscribes the
   stream that died, so a surviving subscription reports `loading` forever until
   an unrelated table write. Latent, not user-visible, because each route builds
   a fresh `PipBloc` (GetIt factory) and the retry button only exists on the
   branch whose stream actually died. **This stage re-derived the same
   conclusion independently** — neither view reads the sibling's status, so it is
   still latent — and K07-BUG-1's fix does not make it worse.
2. `evolutionSub(0)` renders "Because you helped 0 times" (the zero branch is
   missing; wording needs the orchestrator's sign-off). The new
   `control: 0 and 999999999 coins…` pins today's behaviour with a comment
   saying it moves when finding 2 lands, so the copy fix cannot silently move
   the assertion.
3. A test header in `pip_evolution_sparks_test.dart:12` names
   `pip_evolution_sparks_bug_test.dart`; the file is `k07_sparkles_bug_test.dart`
   (still true today, verified).

## Observations (not findings)

1. **The screen has no in-app entry point.** `PipRoutePaths.evolution` has no
   call site outside `pip_routes.dart`; the only ways in are
   `--dart-define=INITIAL_ROUTE=/pip-evolution` or a deep link. `1_plan.md` §(c)
   does not require one (the CTA *leaves* to `/pip`), so it is not a K07 defect —
   but if the intended flow is "K06 celebrates a stage-up by opening K07", that
   entry point does not exist yet and belongs to the K06/flow owner.
2. **K07 opens K06's stream.** The one `PipLoadRequested` subscribes
   `watchNest()` (three tables) even though `/pip-evolution` only needs
   `watchEvolution()`, because K07-BUG-1's fix made each stream's status
   independent but did not make the load screen-scoped. `SHARED_REQUEST.md`
   item 2 asks for a screen-scoped load event. Cost only — a cold open pays for
   one extra Drift watch — and it is the same structural cause as the review's
   finding 1.
3. **The `#3D7FF0` sky dot** is off-token in the design source (`5_ui.md` D5).
   Whatever D4's fix decides for it, the HTML is what needs the new token.
4. **`flutter test test/features/pip` can stall** inside
   `pip_buy_result_test.dart` when the whole directory runs at once (iteration 1
   measured 7 minutes of no progress; that file alone is green in 3 s). Not
   caused by, and not fixable from, K07's screen. This stage ran the directory
   as a whole (`+415 ~1`) and it completed in 10 s.

## Harness notes (cost this stage time; recorded so the next one does not repeat it)

1. **A real Drift READ inside a `testWidgets` body deadlocks** unless it is
   wrapped in `tester.runAsync` (`watchEvolution().first` hung the probe for
   240 s). Writes are the same class and worse: a write to a table a live watch
   sits on (INSERT into `quest_completions` with `watchCompletionsForChild`
   live) hangs at the `await`, and `--timeout` cannot fire inside the fake-async
   zone. So every write in this file happens **before the first pump**, and the
   repository-level proofs are plain real-async `test`s with no widget tree.
2. **`pumpAppRoute` forces 390×844**, so any other surface must be applied
   *after* the first pump (the established K06/K07 width-matrix pattern). Setting
   `physicalSize` before it is silently overwritten — three probes measured
   390×844 while claiming to measure 280 px.
3. **Widget tests render text in a test font**, which is wider than Nunito: at
   390 px the hero wraps to three lines and the stat cards' `FittedBox`
   scaleDown shrinks them to ~74 %, so **text-driven geometry measured in a
   widget test is not the device's geometry**. Only shapes that do not depend on
   glyph advances (the stage slot, the bar, the caption's reachability) and
   painted COLOURS are safe to assert here; line counts and font metrics belong
   to the UI stage's pixel measurements.
4. **A bare `MaterialApp(theme: NestTheme.dark())` can resolve the LIGHT
   tokens** for a painter inside it (measured: identical palettes), because
   `context.nest` reads the nearest `Theme`. Any palette proof must pump the real
   app shell — this is why K07-BUG-5's proof does.
5. `ScrollPosition.jumpTo(double.maxFinite)` asserts (it must be finite);
   `jumpTo(position.maxScrollExtent)` is the bounded call.

## Gates

```
$ dart format --set-exit-if-changed .
Formatted 642 files (0 changed) in 1.87 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.6s)

$ flutter test --timeout 120s test/features/pip/k07_bugs_test.dart
00:02 +23 ~1: All tests passed!        (23 green, K07-BUG-5 parked)

$ flutter test --timeout 120s --run-skipped test/features/pip/k07_bugs_test.dart
  → +23 -1:  exactly one proof fails, and it fails on the dark stroke colour:
      K07-BUG-5  → Expected: <1973050> (0x1E1B3A), Actual: <15986938> (0xF3F0FA)

# the whole feature, stage-3/4/5 suites included:
$ flutter test --timeout 120s test/features/pip
00:10 +415 ~1: All tests passed!

# the whole app:
$ flutter test --timeout 120s
01:39 +4470 ~11: All tests passed!
```

The 11 skips are this stage's one plus the repo's own parked proofs, unchanged
by it: `k01_bugs` 1, `k03_bugs` 2, `k09_bugs` 6, `p12_bugs` 1. Inside
`test/features/pip` the only skip is **K07-BUG-5** — `k06_bugs_test.dart` and
`pip_copy_parity_test.dart` mention `skip:` in their headers only. Every gate ran
with a per-test timeout, nothing was waited on for more than ten minutes, and
nothing hung. The stage-3/4/5 K07 suites (`pip_evolution_*_test.dart`,
`pip_iter2_fixes_test.dart`, `pip_evolution_stream_contract_test.dart`,
`k07_sparkles_bug_test.dart`) were read and run but **not edited** by this stage.

Scratch probes (`zz_probe*_k07_test.dart`, 8 files, ~40 measurements) were
exploratory and are **deleted**; every number they produced is either quoted
above or pinned by a permanent test in `k07_bugs_test.dart`.

`SHARED_REQUEST.md` stays as filed. K07-BUG-5's fix is in-feature
(`pip_evolution_sparks.dart`), which RULES §1 puts in this branch's scope — no
shared change is needed for it.

## Verdict

Iteration 1's four bugs are all closed, and this pass re-measured rather than
assumed it: the false "Oh no! Pip got lost." card is gone (0 of 5 cold opens),
the sparkles have their tips back (0.00 px against both PNGs), the milestone
card counts quests and not rows, and the 320 px slot tells its before → after
story again. The whole brief matrix — 0/1/6 children, out-of-range stages, 0 to
999999999 coins, one and zero completions, rapid double taps on every control,
back navigation and deep links, Drift persistence across a reopen, both mode
guards, contrast, the 280→844 px matrix at text scale 2.0, async gaps — is clean
and now pinned by permanent tests.

One major bug remains: **K07-BUG-5**, the dark-mode sparkle palette. The
design's `svg.sparks` is a fixed, theme-invariant inline SVG, and the app
re-themes it, so every sparkle and dot on the night-sky background gets a
`#F3F0FA` white ring — a visible deviation in one of the two themes, already
photographed by the UI check (`cmp_dark_2.png`) and already ruled **mandatory** by
the orchestrator at 23:55. The fix is six lines in
`pip_evolution_sparks.dart`, the orchestrator has written the recipe, and this
stage verified it green (with the D2 shape proofs unaffected) and then reverted
it, because a bug hunt may not fix the screen.

VERDICT: FAIL