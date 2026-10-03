# K03 Kid home — bug hunt (Stage 6, iteration 6)

Adversarial pass over `kid_home` K03 after the iteration-6 merges (fonts
bundled, `NestType` kid styles, child order by `createdAt`, explicit
`NestPetStage` size mode): data edges, rapid double taps, back navigation,
deep links, restart persistence, mode guards, dark contrast, 320px + 1.3
scale, async gaps, Europe/London periods, integer money, the owner rules,
CHILD ORDER and COPY. No screen code was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 47 tests:
  43 run green, 4 skipped (`K03-BUG-13` at 320/390/430, `K03-BUG-14`).
- Run the skipped proofs:
  `cd app && flutter test --run-skipped --plain-name "K03-BUG-1"`.
- Note: a concurrent iteration-6 stage briefly ran the two pet-slot proofs
  un-skipped; this stage restores the `skip: true` convention so the plain
  suite stays green until the build fixes them.

## Fixed and re-verified this iteration

- **K03-BUG-12 (Moderate, CHILD ORDER) — FIXED on main.** Shared
  `watchChildren` now orders by `createdAt` then `rowid`; the seed staggers
  Maya/Leo. `watchProfiles()` returns `['Maya', 'Leo']`; the proof runs
  un-skipped and a new probe adds four more children in the same second and
  still gets insertion order (`Maya, Leo, Zoe, Adam`). SHARED_REQUEST #12
  closed.
- **Fonts migration — verified.** No `google_fonts` import anywhere in the
  feature or its tests; K03 uses `NestType.kidName/kidCaption/kidTitle/
  kidChipLabel/kidBody` and a new probe asserts the bundled Nunito family
  with `letterSpacing: 0` (no Material tracking).
- **COPY — verified** again character-for-character against the HTML
  (`Let's`, `Today's`, `Mum's`, en dash in the seed quest title).
- All earlier bugs (1–11) remain fixed; every proof is green.

## Open bugs (iteration 6)

### K03-BUG-13 — The pet slot is off-centre at every width and clipped at 320

**Severity: Major (owner ALIGNMENT rule; the screen's main art is visibly
displaced).**
Where: the iteration-6 `NestPetStage` explicit size mode
(`app/lib/core/design_system/components/nest_pet_stage.dart`) combined with
K03's `nestWidth: 260, fixedPipHeight: 152` call. The component computes
`stageW = nestW / 0.62 = 419.35` and lays the nest/Pip scene out against that
nominal width, but the parent content box is only 350 px (390 − 2×20 gutters)
— so every child shifts right by `(419.35 − 350) / 2 = 34.68 px`; at a 320 px
screen (content 280) the shift is 69.68 px and the nest overflows its slot by
59.68 px, where the `Stack`'s `Clip.hardEdge` cuts it (≈40 px past the
physical screen edge).

Repro (widget, current tree, no device insets):
- 390 px: slot centre 195.0, nest/Pip centre 229.68 → **+34.68 off-centre**.
- 320 px: slot centre 160.0, nest/Pip centre 229.68 → **+69.68 off-centre**;
  nest right edge 359.7 vs slot right 300 → **+59.68 overflow**.
- 430 px: slot centre 215.0 vs 229.68 → +14.68 off-centre.

Failing tests (skipped so the suite stays green):
- `K03-BUG-13: the pet slot stays centred at 320px`
- `K03-BUG-13: the pet slot stays centred at 390px`
- `K03-BUG-13: the pet slot stays centred at 430px`

Suggested fix (shared, SHARED_REQUEST #13): in explicit mode, clamp the scene
to the available width (`scale = min(1, maxW / nominalStageW)` applied to
`stageW`/`nestW`/`pipH`) and centre it in the box — the legacy sizing path
already scaled down instead of overflowing, so this is a regression of that
guard. Alternatively the view can pass a responsive `nestWidth` from a
`LayoutBuilder` (260 cap at ≥390, proportionally smaller below).

### K03-BUG-14 — The pet block is 40 px taller than the design slot

**Severity: Moderate (layout knock-on; pushes the whole lower stack).**
Where: the same explicit mode renders a 260 px **square** nest (plus the
stage's own top offset/shadow bleed), so `PipNestFallback` is 276 px tall
instead of the design `.k3-pet` 236 px. The hearts row then sits at ~505 px
instead of the orchestrator target ≈443, and everything below (section title,
progress, cards, dock interplay) shifts down ~40 px.

Repro: `flutter test --run-skipped --plain-name "K03-BUG-14"` →
`Expected within 2 of 236, Actual 276`.

Failing test (skipped):
- `K03-BUG-14: the pet block keeps the design 236 px slot height`

Suggested fix: fix the slot height as part of the K03-BUG-13 change — the
shared size mode should honour the design box (nest 260×236 with Pip 152,
feet at the rim) and scale/centre inside the parent; then re-run the
orchestrator QA rows (hearts ≈443, progress ≈520, card-1 ≈560, dock ≈720).

## Status of all K03 bugs

| ID | Severity | Area | Status |
|---|---|---|---|
| K03-BUG-1..6 | Major..Minor | iteration-1 defects | fixed, proofs green |
| K03-BUG-7 | Major | motion flag (`DISABLE_ANIMATIONS=1`) | fixed (shared), proof green in both modes |
| K03-BUG-8/9 | Minor | celebration swallow, lock route stacking | fixed, proofs green |
| K03-BUG-10 | Major (owner) | bottom edge surface | fixed (light + dark proofs) |
| K03-BUG-11 | Minor | silent no-op latch | fixed, proof green |
| K03-BUG-12 | Moderate | child order | fixed (shared), proofs green |
| K03-BUG-13 | **Major** | pet slot off-centre + clipped at 320 | **open (shared size mode)** |
| K03-BUG-14 | Moderate | pet block +40 px height | **open (same fix family)** |

## Verified clean (probes in the same file)

| Category | Probe | Result |
|---|---|---|
| child order | `watchProfiles()` = Maya, Leo; six children in one second keep insertion order | pass |
| fonts | kid styles: bundled `Nunito`, `letterSpacing: 0`, no `google_fonts` | pass |
| copy | visible strings match the HTML character-for-character | pass |
| bottom edge | light + dark surface to the physical edge under a 34px inset | pass |
| alignment | 20px gutters on progress bar, cards and dock | pass |
| periods | day/week boundaries, daily/weekly/once, BST switch days | pass |
| taps | same-frame double taps → one row / one route; silent no-op retry | pass |
| data edges | 0 / 1 / 6 children; long name + 9999 coins at 320/1.3; no `£` | pass |
| back nav / deep links / restart / guard / contrast / money / async gap | all earlier probes | pass |

## Observations

1. **Period rollover without a DB change** (no injectable clock; not
   provable here).
2. **Test wall-clock coupling** — the seed anchor is pinned, `DateTime.now()`
   is not; deterministic only inside the pinned day/week.
3. Parent-mode `/kid-home` reachable by deep link; PIN not enforced
   (K01/K02 placeholders); debug gallery routes unguarded.
4. Accessories in the static `PipAvatar` fallback are not drawn (no seed
   child equips one today).

## Summary

The iteration-6 feature work is sound (child order, fonts, copy, tap and
period behaviour all verified), but the newly adopted explicit pet-slot size
mode introduced two real layout defects: the nest/Pip scene is off-centre at
every width and visibly clipped at 320 px (major, owner ALIGNMENT), and the
pet block is 40 px taller than the design, shifting the whole lower stack.
Both are proven by skipped tests and filed with a shared fix path.

VERDICT: FAIL
