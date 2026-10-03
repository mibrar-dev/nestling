# K03 Kid home — build notes (Stage 2 INTEGRATE, iteration 8)

Two builders worked in parallel on `kid_home`. This stage is the integrator:
it confirmed the merged tree compiles and passes, and verified the work rather
than taking the builders' reports at face value.

**Gate: PASS** — `dart format .` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → *`+1361: All tests passed!`*

**Headline: the screen has zero skipped tests for the first time.** Iteration 7
closed at `+1149 ~5` — five proofs parked because their defects lived in
`core/`. The shared batch `shared/pet_stage_explicit` landed
(`797221c`, "explicit `NestPetStage` centred in its real box,
`nestHeight`/`visibleNestWidth`, Pip seated on the rim; speech bubble matches
`.speech`"), the builders closed the defects, and **all five proofs now run
un-skipped and green.** The integration work this stage was one stale comment.

## 1. The halves as delivered

### 2a — logic (`2a_build_logic.md`)

Verified present in the tree this time (last iteration 2a's work was reverted
mid-flight — that did not repeat):

- `kid_home_bloc.dart`: the load handler now owns a guarded
  `StreamSubscription<KidHomeData>` (early-return while live, cancel-before-
  reload, released on error and in a `close()` override) instead of
  `await emit.forEach(...)`. Stream output re-enters the bloc as two new
  **bloc-internal** events, `KidHomeDataReceived` / `KidHomeStreamFailed`
  (`kid_home_event.dart`, +23). The public event/state contract is unchanged,
  so no view change was needed — confirmed by 2b against the view.
- Mid-session stream errors keep the loaded list: `status` only drops to
  `failure` when `state.child == null`, so one failed watch tick no longer
  replaces the screen the child is looking at.
- `kid_home_bloc_test.dart`: +2 tests (cross-frame double-dispatch celebrates
  once; mid-session error keeps the list), 29 total.
- `k03_bugs_test.dart`: K03-BUG-15 un-skipped (one word).

### 2b — UI (`2b_build_ui.md`) — verified against the mandate

- **Pet slot**: the exact call the orchestrator's 08:32 UPDATE specified —
  `NestPetStage(pip: PipAvatar(child's own), speech: "Let's do some quests!",
  nestWidth: 236, nestHeight: 156, fixedPipHeight: 152, semanticLabel: …)`.
  Verified: `_kNestWidth = 260` is gone (now `_kNestBoxWidth = 236`,
  `_kNestBoxHeight = 156`, `_kPipSlotSize = 152`, each design-cited), and there
  is **no `Center` wrapper around the stage** (the three `Center(` in the file
  are the loading / empty / failure states, which is correct). `pipSize` is no
  longer passed, since explicit mode ignores it and leaving it would be a dead
  prop.
- `_kStageToHearts = 10.75` — the single lever left after the shared box landed,
  putting the hearts row on the design's y 448. Sanctioned sizing, not negative
  margins; every row below keeps the design's `s4` rhythm.
- **Meadow band**: now grades to `tokens.kidMeadow` (not `lerp(horizon,
  meadow, .5)`, which never reached the design tone) over the design's own
  span — `gradeSpan = 844 − 0.62 × 844 = 320.72` px, from
  `components.css:25` `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom
  62%, kid-horizon 62%, kid-meadow 100%)`. 2b measured the result against both
  PNGs with PIL: worst case **1 level per channel** across the visible band in
  both themes, versus the review's measured (21, 6, 24) light / (3, 12, 15) dark
  for the shipped behaviour. The band top sits on the design's 62 % horizon
  stop.
- Un-skipped `K03-BUG-13` (320/390/430), `K03-BUG-14` and the geometry pin; the
  nest finder follows the box to 236; the header comments were rewritten from
  OPEN to FIXED naming the shared fix.
- Three stale expectations corrected as consequences of the shared work, not of
  a defect: the Pip test pinned `pipSize == 152` (explicit mode ignores it),
  the typography proof pinned `.speech` 24/16 (the shared bubble now uses the
  browser default), and 2b's own grade probe sampled `t × h` — past the 320.7 px
  run, so it could only ever have proved the flat clamp.
- `kid_home_view_test.dart`: new painted-pixel proofs (light + dark) that run
  the real `_MeadowPainter` into a `ui.PictureRecorder` and read back the
  design's y 719 row, plus the `visibleNestRatio` assertion the review asked
  for.

## 2. Integration work done here

No breakage to repair: the tree arrived green and stayed green. One stale
comment was fixed, because it actively lies about the suite's state —
`k03_bugs_test.dart`'s header still announced *"K03-BUG-15 (OPEN, minor) …
Proof `skip: true`; run with `--run-skipped`"* after 2a had un-skipped and
greened that proof. It now records BUG-15 as FIXED with the mechanism (guarded
subscription + the two internal events), notes the mid-session-error rule, and
states plainly that the suite has no skipped tests. Stale `OPEN`/`skip: true`
markers are what made iterations 6–7 ambiguous about which proofs were parked,
so this was worth fixing even though it touches no code.

## 3. FIXES_7 items

### `4_review.md`

| # | Item | Status |
|---|---|---|
| 1 | [blocker] `K03-BUG-15` proof red + the retry subscription leak | **DONE** (2a) — guarded subscription; both proofs (bloc-level and this file) un-skipped and green |
| 2 | [minor] `cascade_invocations` made analyze red at HEAD | **DONE** — `flutter analyze` → No issues found! |
| 3 | [major] pet slot 34.7 px off-axis, block 40 px too tall | **DONE** — shared fix landed, exact mandated call adopted, all three width proofs + BUG-14 + the geometry pin now run un-skipped |
| 4 | [major] meadow is a local painter, flat navy in dark | **DONE in the interim the review itself allowed** (2b) — grades to `kidMeadow` over the design span, ≤1 level off both PNGs. Deleting the painter still needs the two shared pieces; SHARED_REQUEST #6 marked *partly landed* and re-scoped |
| 5 | [minor] one defect, two proofs with opposite conventions; missing cross-frame proof | **DONE** (2a) — duplicate un-skipped, cross-frame double-dispatch proof added at bloc level |
| 6 | [minor] mid-session stream error replaces the screen | **DONE** (2a) — keep-list rule |
| 7 | [minor] geometry pin measures the box, not the 198 outline | **DONE in the honest split** (2b) — box pin kept (it is the shared fix's contract) + `nest.width * visibleNestRatio ≈ 198 ±2` asserted; the painted outline stays the UI stage's capture measurement |
| 8 | [minor] `switchMapStream` in `domain/` | **CARRIED** — shared/architecture, SHARED_REQUEST #14; no K03 action available |

### `5_ui.md`

| # | Item | Status |
|---|---|---|
| 1 | pet-slot geometry wrong (+34 x, +46…+56 downstream) | **DONE** — root cause was shared and the fix landed; the geometry proofs now assert the design numbers instead of documenting the failure |
| 2 | dark lower-content meadow missing (3rd iteration) | **DONE in code** (2b), verified numerically against the dark PNG (≤1 level/channel) |
| 3 | speech bubble 46 vs design 35 | **CLOSED as no-change-wanted** — the orchestrator's 08:32 UPDATE settled it: 44 px is the design's full height and "35" was a misread of the inner white area; the shared bubble already matches `.speech`. SHARED_REQUEST #15 closed |
| 5 | adopt `NestBalancedText` | **DONE** (iteration 7, verified still in place) |

### `6_bugs.md` / `3_test.md`

- **K03-BUG-13** (pet slot off-centre at every width, clipped at 320) — **fixed
  (shared)**; proofs un-skipped.
- **K03-BUG-14** (pet block 276 vs 236) — **fixed (shared)** via `nestHeight`;
  proof un-skipped.
- **K03-BUG-15** (retry stacks live subscriptions) — **fixed** (2a); proofs
  un-skipped.
- BUG-1…12 remain fixed with green proofs.

I re-ran the three proofs this iteration rather than trusting the reports:
`flutter test --run-skipped --plain-name "K03-BUG-1"` → `+11: All tests
passed!` (now with nothing to un-skip), and the real-font geometry pin →
`+1: All tests passed!`.

### Skipped tests

**None.** The suite reports `+1361` with no `~N`. `grep -rn "skip: true"` over
`app/{lib,test}/features/kid_home` returns nothing.

## 4. Verification (in `app/`, this stage)

```
$ dart format .
Formatted 401 files (0 changed) in 1.43 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.8s)

$ flutter test test/features/kid_home
00:06 +154: All tests passed!

$ flutter test
00:23 +1361: All tests passed!
```

- RULES §1 respected: only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**` and `docs/screens/K03/**` are touched. This
  stage itself changed one file (`k03_bugs_test.dart`, comments only) plus this
  note. No `core/`, no other feature, no `tools/`, `analysis_options.yaml`
  untouched.
- No simulator was booted, installed on, or captured (SIMULATORS rule: only the
  UI-check stage may, and only `BC440E48-B3A3-43BC-971B-0EF5DB621874`).
- No `google_fonts`/`GoogleFonts` and no `// ignore:` suppression anywhere in
  the feature.

## 5. Handover

Nothing in K03's scope is outstanding. Three items are owned elsewhere and are
listed so the record stays complete:

- **SHARED_REQUEST #6 (partly landed)** — deleting `_MeadowPainter` needs
  `KidScope`'s flat 62 % horizon stop and the horizon→meadow grade; its
  background has only two stops (`kidSkyTop` → `kidSkyBottom`). The painter
  stays with a re-scoped `TODO(K03)` and matches both PNGs to ≤1 level.
- **SHARED_REQUEST #14** — `switchMapStream` belongs in
  `core/data/stream_combine.dart` with the other combinators, not in the
  feature's `domain/`. Adoption is mechanical when it lands.
- **SHARED_REQUEST #15** — closed, no change wanted.

Next real step is the UI check: with the pet slot, the lower stack and the dark
meadow all changed this iteration, the band table should be re-measured on the
designated simulator, and the **painted** 198 px nest outline confirmed from the
capture (the widget proofs pin the box and the ratio, which is as far as a
widget test can reach).

VERDICT: PASS