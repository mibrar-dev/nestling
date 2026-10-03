# K03 Kid home — Stage 3 (TEST), iteration 6

Scope: `kid_home` / `/kid-home`, kid mode. Tests in
`app/test/features/kid_home/` (`kid_home_bloc_test.dart`,
`kid_home_view_test.dart`, `k03_bugs_test.dart`). Per RULES §1 this stage only
touched `app/test/features/kid_home/**` and `docs/screens/K03/**` — **no screen
code was patched**; both findings below are recorded for the next build.

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → **381 files, 0 changed**.
- `flutter analyze` → **No issues found!** (`analysis_options.yaml` untouched;
  the two `// ignore: avoid_dynamic_calls` reads are documented in place).
- `flutter test` (whole app) → **exit 1, `+994 -4`** — 994 pass, **4 fail**, 0 skip.
- `flutter test test/features/kid_home/` → **exit 1, `+132 -4`** — 132 pass,
  4 fail, **0 skip** (the suite's last conditional skip is gone, see K03-BUG-7).

The 4 failures are exactly the two new pet-slot proofs of this stage
(K03-BUG-13 at three widths, K03-BUG-14). Nothing else regressed.

| File | Start of iteration 6 | Now |
| --- | --- | --- |
| `kid_home_view_test.dart` | 56 | **63** (+7, all pass) |
| `kid_home_bloc_test.dart` | 22 | **26** (+4, all pass) |
| `k03_bugs_test.dart` | 38 + 1 skip | **43 pass + 4 fail** |

Attribution of the bug-file delta: this stage added 4 proofs (K03-BUG-13 ×3,
K03-BUG-14) and un-skipped K03-BUG-7 (+1 pass, −1 skip). The iteration-6
**bugs stage was writing into the same file concurrently** (see
"Concurrency" below) and contributed 2 passing probes — "child order holds with
six children in the same second" and "kid type styles are bundled Nunito with
zero tracking" — plus a first, skipped draft of the centring proof.

## What the iteration-6 build changed (the surface under test)

1. **Pet slot in the shared explicit-size mode** (SHARED_REQUEST #11 landed):
   `NestPetStage(nestWidth: 260, fixedPipHeight: 152)` replaces the derived
   sizing, so the design's 260/152 slot is finally expressed (review finding 1).
2. **Typography fork closed**: `GoogleFonts.nunito(...)` → `NestType.kidName /
   kidCaption / kidChipLabel` (review finding 3; SHARED_REQUEST #7).
3. **One combined child subscription** (review finding 4): `KidHomeData` +
   `KidHomeRepository.watchHome()` + the `switchMapStream` helper; the bloc
   subscribes once per load.
4. **Meadow band gradient** (5_ui.md finding 1): `_MeadowPainter(top:
   kidHorizon, bottom: lerp(kidHorizon, kidMeadow, .5))`.
5. **CHILD ORDER fixed on main** (K03-BUG-12): `watchProfiles()` → [Maya, Leo].

## Tests added (this stage)

### `kid_home_view_test.dart` — new group `K03 pet slot (explicit size)`

1. **`the nest is 260 wide and the Pip exactly 152 tall`** — `nestWidth == 260`,
   `fixedPipHeight == 152`, the fallback's `nestW`/`pipH`, and the **rendered**
   shapes: `PipAvatar` 152×152 and the nest picture 260 wide (the derived
   sizing rendered a 217 px nest with a 119 px Pip on this same viewport).
2. **`the slot box keeps the 20 px gutters`** — the slot spans 20…370.

### `kid_home_view_test.dart` — new group `K03 typography (NestType, zero tracking)`

3. **`every K03 string uses the shared kid styles with tracking 0`** — for
   `Hi Maya!`, `4 done today`, `Pip is happy today`, `Today's quests`,
   `4 of 6 done`, `Let's do some quests!` and `120`: font size, line box and
   weight equal the design CSS (`.k3-name` 22/26 w900, `.k3-sub`/`.kcap`
   15/20 w700, `.kid-title` 28/34 w900, `.kchip` 15/15 w800, `.speech` 16 w800,
   `.coin-pill` 16/16 w800) **and `letterSpacing == 0`** — the K03 CSS sets no
   tracking anywhere, and main fd92d95 made NestType default to 0, so Material
   tracking must not creep back in. Also asserts the kid styles exist in the
   shared scale (`kidName`/`kidCaption`/`kidTitle`/`kidChipLabel`), i.e. no
   screen-local font fork.

### `kid_home_view_test.dart` — new group `K03 meadow band`

4. **`light/dark: the band grades horizon → meadow`** — the band's painter top
   is `kidHorizon` and its bottom `Color.lerp(kidHorizon, kidMeadow, 0.5)` **in
   both themes** (5_ui.md finding 1: dark used to render a flat navy block),
   and the band is full-bleed (0…390) behind the progress bar and the cards.

### `kid_home_view_test.dart` — new group `K03 shapes (pills and rects, not just text)`

5. **`the section chip is a 32 px leaf-tint pill`** — `.kchip` height 32,
   background `leafTint`, `NestRadii.allPill`, 12 px label inset (the existing
   alignment test already pinned its right edge to the 20 px gutter).
6. **`the card tile is 48 px and the check a 56 px ink circle`** —
   `.quest-card.kid .kid-icon` 48×48 with radius 16, `.quest-check` 56×56.

### `kid_home_bloc_test.dart` — new group `switchMapStream`

7. **`keeps forwarding the live inner stream after the outer completes`** —
   the exact hazard the helper's doc comment describes: `watchActiveChild` may
   end after one value, and closing there tore down the quest subscription one
   tick in (later completion flips were silently dropped).
8. **`a second outer emission replaces the inner subscription`** — a child
   switch detaches the old child's stream (the reason `asyncExpand` cannot be
   used: it would stall forever on never-closing watch streams).
9. **`forwards an inner error without closing the result`** — a load failure
   surfaces as an error event and the stream stays usable.
10. **`cancelling the result cancels the inner subscription`** — no leaked
    quest subscription when the bloc closes.

### `k03_bugs_test.dart` — K03-BUG-7 un-skipped

11. **`K03-BUG-7: DISABLE_ANIMATIONS is honoured in both directions`** — the
    shared parse landed (`env_flags.dart` also compares the literal `'1'`), so
    the proof no longer needs a conditional skip. It now runs in the plain suite
    (asserting motion stays **on** — a silent always-on flag would freeze the
    app) *and* under the documented flag (asserting `kDisableAnimations` and
    `MediaQuery.disableAnimationsOf` are true). Both directions verified:
    `flutter test --plain-name K03-BUG-7` and
    `flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name K03-BUG-7`
    → All tests passed. The suite now has **zero skipped tests**.

### `k03_bugs_test.dart` — two new proofs (these fail: real defects)

12. **`K03-BUG-13: the pet slot stays centred at 320/390/430px`**
13. **`K03-BUG-14: the pet block keeps the design 236 px slot height`**

## Bugs found

### K03-BUG-13 [major, OPEN] — the pet slot is off-centre at every width and clipped at 320

**Where:** `app/lib/core/design_system/components/nest_pet_stage.dart:105`
(`final stageW = nestW / 0.62;`) → `app/lib/core/design_system/motion/pip_rive.dart:482`
(`SizedBox(width: stageW)`) with children positioned at
`nestLeft = (stageW - nestW) / 2` (`pip_rive.dart:469`) and
`left: (stageW - pipH) / 2` (`pip_rive.dart:527`); reached from
`app/lib/features/kid_home/presentation/views/kid_home_view.dart:694-695`
(`nestWidth: _kNestWidth, fixedPipHeight: _kPipSlotSize`).

**Cause:** the explicit-size mode composes the scene in a **419.35 px** stage
(`260 / 0.62`). The `SizedBox` is clamped by the slot's 350 px content box
(390 − 2×20 gutters), but the `Positioned`s keep using the nominal 419.35, so
every child shifts right by `(419.35 − 350) / 2 = 34.7 px`. The composition no
longer responds to width at all (identical rects at 320/390/430).

**Measured (light, 390×844, no insets):**

| width | slot box | slot centre | nest rect | Pip rect | nest centre |
| --- | --- | --- | --- | --- | --- |
| 320 | 20…300 | 160 | 99.7…359.7 | 153.7…305.7 | **229.68** (+69.7) |
| 390 | 20…370 | 195 | 99.7…359.7 | 153.7…305.7 | **229.68** (+34.7) |
| 430 | 20…410 | 215 | 99.7…359.7 | 153.7…305.7 | **229.68** (+14.7) |

At 320 the nest's right edge is **59.7 px past the slot** and the `Stack`'s
default `Clip.hardEdge` cuts it off (no overflow error, so the matrix test's
`takeException` check cannot see it). This violates the owner ALIGNMENT rule and
`design/html-source/screens/K03-kid-home.html:24-26`, where `.k3-pet` is
centred (`margin: 14px auto 0`) and both `.nest` and `.pip` use
`left: 50%; transform: translateX(-50%)`.

**Repro:**
```
cd app && flutter test test/features/kid_home/k03_bugs_test.dart --plain-name K03-BUG-13
```
→ 3 failures: `Expected: a numeric value within <1> of <160.0/195.0/215.0>`,
`Actual: <229.67741935483872>`.

**Fix location:** the shared component (outside K03's edit scope) — clamp the
scene's coordinate space to the available width (`stageW = min(nestW / 0.62, maxW)`
and derive every `Positioned` from the *actual* box), or let a caller pass a
centred slot box. Filed as SHARED_REQUEST #13 by the iteration-6 bugs stage,
which measured the same +34.7/+69.7 px values and the 59.7 px clip.

### K03-BUG-14 [moderate, OPEN] — the pet block is ~40 px taller than the design, pushing the lower stack down

**Where:** same cause — `pip_rive.dart:461` (`final nestH = nestW;`, i.e. a
**square** 260×260 nest) plus the stage's own `nestTop` offset and shadow bleed
(`pip_rive.dart:470`), reached from `kid_home_view.dart:694-695`.

**Measured:** the pet stage box is **276 px** tall at 390 px width; the design's
`.k3-pet` is **236 px** (`.nest` 236 too). Consequence in the same viewport:
the hearts row top moved **462 → 505 px** versus iteration 5's verified
rendering, i.e. the orchestrator's QA position targets regress (iteration 5
closed with hearts +3 against the design's ≈443; this build puts the whole
lower stack ≈43 px lower).

**Repro:**
```
cd app && flutter test test/features/kid_home/k03_bugs_test.dart --plain-name K03-BUG-14
```
→ `Expected: a numeric value within <2> of <236>  Actual: <276.0>`.

**Fix location:** shared (the explicit-size mode should honour the design's
260×236 slot, or nest height should be a parameter rather than `nestW`); the
screen-side consequence is the pet block height feeding the whole list.

### Closed since iteration 5

- **K03-BUG-7** (shared motion flag) — fixed on main; the proof now runs in both
  directions and the suite has no skips left.
- **K03-BUG-12** (CHILD ORDER) — the shared ordering landed; the proof runs
  un-skipped and passes.
- Review findings 3, 4, 5 — typography fork closed (`NestType`), one child
  subscription per load, no stale `errorMessage`.

## Owner rules re-checked

- **BOTTOM EDGE:** the K03-BUG-10 proofs (light + dark, 34 px inset emulated)
  still pass — the dock surface runs to the physical edge with no coloured
  strip, and the owner's "no green under the dock" feedback still holds.
- **ALIGNMENT:** gutters, shared card/bar edges, equal-width dock buttons and
  the 3 px dock border all still pass; the *new* misalignment is the pet slot
  (K03-BUG-13).

## New orchestrator rules — coverage

| Rule | Status on K03 |
| --- | --- |
| FONTS (google_fonts removed) | No `google_fonts` import or `GoogleFonts.*` call remains in `app/lib/features/kid_home/` or its tests (verified by grep); the feature now uses `NestType.kidName/kidCaption/kidChipLabel`, pinned by the new typography test and the bugs stage's token probe |
| LETTER SPACING (default 0) | Pinned: every rendered K03 string asserts `letterSpacing == 0`, and the K03 CSS sets no tracking |
| UI CHECK MEASURES SHAPES | New `K03 shapes` group measures the chip (32 px pill, leaf-tint), the card tile (48×48) and the check (56×56) |
| CHIP ROWS (`NestChipWrap`) | Not applicable: K03's chips are the feature-private, non-interactive `KidStatusChip` (`.kchip`); there is no interactive `NestChip` row on this screen |
| BALANCED HEADINGS (`NestBalancedText`) | Not applicable **yet**: the section heading is `<h2 class="kid-title">`, which the CSS balances, but `NestBalancedText` (main 88c2132) is not in this worktree — a branch-behind-main process item, not a defect. When it merges, K03's only `.kid-title` must render through it (the copy never wraps at the supported widths, so there is no visible difference today) |
| CHILD ORDER | No child list on this screen; pinned at the repository level by K03-BUG-12 (`['Maya','Leo']`) plus the bugs stage's six-children probe |
| COPY | Re-verified character-by-character: the K03 HTML source has **0 curly / 4 straight** apostrophes (all screen sources: 0 curly / 25 straight), and the app matches; the source's only em dash is in `<title>`, not screen copy |
| TRIAL | No test writes `subscription_status`; the demo seed is the active subscriber |
| PERIODS | Unchanged and still green (daily/weekly/once, new-period completions) |

## Concurrency note

The iteration-6 **bugs stage was editing `k03_bugs_test.dart` at the same time**
as this stage (its mtime moved while my proofs were being added). Its first
draft of the centring proof was `skip: true`; this stage replaced that draft
with the un-skipped three-width matrix under the same number (K03-BUG-13, same
measured defect) so the defect shows in the plain suite, and added K03-BUG-14.
Its two passing probes were kept as-is. The file's header comment now lists
both findings. Nothing else in the repo was touched by this stage.

At 06:31 a concurrent write put `skip: true` back on all four proofs (making the
suite green and hiding both defects). RULES/brief forbid skipping tests to get
green, so the markers were removed again; the final verified state is
`+994 -4` for the app and `+132 -4` for the K03 folder, with the four failures
being exactly the K03-BUG-13/14 proofs. If the next stage re-skips them, the
defects are still real — the repro commands above work with
`--run-skipped --plain-name K03-BUG-13/14`.

VERDICT: FAIL
