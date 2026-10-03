# K03 Kid home — build notes (Stage 2 INTEGRATE, iteration 6)

Two builders worked in parallel on `kid_home`. This stage is the integrator:
it made the merged tree compile and pass, and fixed the breakages the two
halves produced together. No redesign, no scope widening.

**Gate: PASS** — `dart format .` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → *`+980 ~1: All tests passed!`*

## What the two halves delivered

### 2a — logic (`2a_build_logic.md`, domain/data/bloc)

- New entity `KidHomeData {child, items}` and `KidHomeRepository.watchHome()`,
  so a load watches the child row **once** instead of twice (review finding 4).
  The Drift impl overrides it with a single `app_state` subscription; the
  abstract default combines `watchActiveChild()` + `watchItems()` through a
  feature-internal `switchMapStream`.
- `kid_home_bloc.dart` load path now `emit.forEach(_repository.watchHome())`;
  celebration/error handling (`_awaitingCelebration`, BUG-8/BUG-11) untouched.
- `K03-BUG-12` un-skipped (CHILD ORDER now correct on main); all 8 test fakes
  changed `implements` → `extends` so they inherit the new default member.
- Public BLoC contract unchanged — same events, same state fields, so the UI
  half needed no state/event changes.

### 2b — UI (`views/`, `widgets/`) — reconstructed from the tree

`2b_build_ui.md` was **not** written (the chunk exited after a nudge without
producing it), so the summary below is read back off the code:

- `google_fonts` removed from the feature; the four typography call sites now
  use the shared `NestType.kidName` / `kidCaption` / `kidChipLabel`
  (review finding 3 + the FONTS rule; SHARED_REQUEST #7 landed on main).
- `_MeadowPainter` gained the vertical gradient UI dev 1 asked for:
  `kidHorizon` at the band top grading to `Color.lerp(kidHorizon, kidMeadow, .5)`
  at the bottom, so the dark lower content is no longer flat navy
  (the light band was already correct).
- Pet slot reworked against review finding 1 — `nestWidth: 260` +
  `fixedPipHeight: 152`, `_kNestWidth`/`_kPipSlotSize` constants,
  `_pipStage()` helper dropped as unused.

## Integration breakages found and fixed (my changes)

Three distinct breakages, all caused by the two halves meeting:

1. **Pet slot had been forked away from the shared component.** 2b had replaced
   `NestPetStage` with a feature-local `Column → Semantics → SizedBox → Stack`
   holding `SvgPicture.asset(nest.svg)` plus a positioned `PipAvatar`. That is
   a design-system re-implementation (forbidden) *and* it broke 5 view tests
   that pin the shared contract (`find.byType(NestPetStage)`, `slot.speech`,
   `slot.pip`, `slot.pipSize`, `getSemantics(NestPetStage).label`). The cause
   was benign: SHARED_REQUEST #11 **landed on main** during the merge, and
   `NestPetStage` now has the exact explicit size mode 2b was waiting for
   (`nestWidth:` / `fixedPipHeight:`). Fix: the local fork was reverted and the
   slot now composes through the shared component —
   `NestPetStage(pip: PipAvatar(...), speech:, pipSize: 152, nestWidth: 260,
   fixedPipHeight: 152, semanticLabel:)`, which lands the design slot (260 px
   nest, 152 px Pip) *and* satisfies the 5 tests. The now-dead
   `_kNestHeight`/`_kPipHeight`/`_kNestLayoutHeight` constants and the
   `flutter_svg` + `nest_assets` imports were removed with it.
   No test was changed to accommodate the fork.
2. **`switchMapStream` closed its result on outer done** — which silently
   truncated every load driven by the repository's *default* `watchHome()`.
   `watchActiveChild()` is `Stream.value(child)` in the test fakes, so
   `onDone: controller.close` fired one tick in, tore down the inner quest
   subscription, and ended `emit.forEach` — every later completion flip was
   dropped, so nothing was ever celebrated. This broke 3 proofs
   (`K03-BUG-8`, `retry after a failed completion still celebrates`,
   `double-tapping the check completes once`). Fix: outer completion no longer
   closes the controller (which is what its own doc comment already claimed —
   "Never close: the next outer emission replaces the inner"); the live inner
   keeps forwarding. Production is unaffected either way — the Drift override
   emits from one never-closing subscription — so this only removed the
   landmine for every fake and future default.
3. **A leftover scratch test was failing analyze.** The UI chunk left
   `app/test/features/kid_home/zz_measure_test.dart` — print-only, no
   assertions, 22 lint hits (`avoid_print`, `unnecessary_string_escapes`,
   `unused_local_variable`, `avoid_catches_without_on_clauses`). It was a
   layout-measurement scratch pad, not a test; it was **moved out of the repo**
   (kept at a temp path, not deleted outright) so `flutter analyze` is clean.

## FIXES_5 items

### Review findings (from `4_review.md`)

| # | Item | Status |
|---|---|---|
| 1 | [major] pet slot size must reach `ORCHESTRATOR_NOTES` #1 | **DONE** — SHARED_REQUEST #11's target-size API landed; slot now `nestWidth: 260, fixedPipHeight: 152` through the shared component. Needs a capture to confirm pixels. |
| 2 | [minor] CHILD ORDER at shared `watchChildren` | **DONE** (2a) — fixed on main; `K03-BUG-12` un-skipped and green. |
| 3 | [minor] unmarked typography fork | **DONE** (2b) — four call sites on `NestType`, `google_fonts` gone from the feature. |
| 4 | [minor] child stream watched twice per load | **DONE** (2a) — `watchHome()`; plus my `switchMapStream` outer-done fix. |
| 5 | [minor] shared `DISABLE_ANIMATIONS=1` parse | **DONE** on main (`4751c52`) — re-verified here: `flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name K03-BUG-7` → *All tests passed*. |
| 6 | [minor] dock label can wrap | **LEFT** — shared `NestKidButton`; tracked as SHARED_REQUEST #9, no screen-local fix. |

### UI deviations (from `5_ui.md`)

| # | Item | Status |
|---|---|---|
| 1 | dark meadow tint behind the lower content (FAIL driver) | **DONE in code** (2b) — gradient `kidHorizon` → `lerp(horizon, meadow, .5)`. Visual confirmation is the UI stage's call; this stage ran no simulator. |
| 2 | residual +10–13 px in the hearts→progress span | **LEFT** — the UI chunk changed no spacing in that block (verified: the view diff contains no `EdgeInsets`/`SizedBox` change). A layout probe in the test viewport could not settle it either way (test viewport ≠ 390×844 and the section title wraps to two lines), so it is honestly recorded as not done rather than guessed. |
| 3 | dock top −6 px (ALIGNMENT) | **DONE** — dock bottom air is `NestSpacing.s1` (not the HTML `gap10`), so the dock owns the OS inset and lands on design y≈720. Already at HEAD before this stage. |

### Skipped bug tests

Only **K03-BUG-7** is skipped, and only by design: it asserts a
compile-time `--dart-define`, so it is gated on `bool.hasEnvironment`
(`skip: !const bool.hasEnvironment('DISABLE_ANIMATIONS')`). It passes when run
the documented way (verified above). **K03-BUG-12** was un-skipped by 2a.
No test is skipped to make the suite green.

## Verification (in `app/`, this stage)

```
$ dart format .
Formatted 381 files (0 changed) in 1.27 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.7s)

$ flutter test
00:51 +980 ~1: All tests passed!
```

- `+980 ~1` — the 1 is the conditional K03-BUG-7 skip above.
- `flutter test test/features/kid_home` alone → `00:06 +118 ~1: All tests passed!`
- RULES §1 respected: `git status --porcelain` outside
  `app/lib/features/kid_home/`, `app/test/features/kid_home/` and
  `docs/screens/K03/` is empty — no `core/`, no other feature, no `tools/`.

## Notes for the next stages

- The pet slot now goes through the shared component again, so the UI stage
  should re-measure nest width / Pip band against
  `design/screens/*/K03-kid-home.png` and confirm finding 1 is closed
  (previously nest 182 vs 198, Pip band 25 px short).
- UI dev 2 above is still open and is the only unaddressed `5_ui.md` item.
- Not run here, by design: simulator captures and `compare.py` sheets. The
  meadow gradient (UI dev 1) and the re-composed pet slot both change pixels
  the next UI check will measure.

VERDICT: PASS