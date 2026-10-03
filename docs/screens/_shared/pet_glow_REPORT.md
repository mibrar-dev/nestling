# Shared fix: dark-mode pet glow matches `--pet-glow` — REPORT
(branch `shared/pet_glow`)

The dark-mode pet glow was a solid `Color(0x1AFFFFFF)` disc (~245 px at
K03) with a hard edge; the design token is almost nothing — a soft radial
fade. All three disc sites now share one `PetStageGlow` widget built from a
nullable token. Backward-compatible (additive only: no renames, no screen
edits, light rendering unchanged); screen branches merge without edits.

Evidence read first: `design/html-source/tokens.css` (`--pet-glow: none`
light line 54; dark `radial-gradient(circle 110px at 50% 45%,
rgba(255,255,255,.10), transparent 70%)` lines 135/191),
`design/html-source/components.css` line 188 (`.pet-stage::before`:
230×230 box, `left: 50%; top: 42%`, `translate(-50%,-50%)`,
`border-radius: 50%`, `background: var(--pet-glow)`),
`app/lib/core/design_system/components/nest_pet_stage.dart` (both `_PetScene`
discs), `app/lib/core/design_system/motion/pip_rive.dart`
(`PipNestFallback` disc — the third site, see §3),
`app/lib/core/design_system/tokens/colors.dart` + `nest_tokens.dart`,
`app/test/core/design_system/nest_pet_stage_test.dart`.

## Files changed

- `app/lib/core/design_system/tokens/colors.dart` — new nullable
  `NestSchemeColors.petGlow` (`--pet-glow` → `petGlow`, the file's own
  naming rule). Dark = `Color(0x1AFFFFFF)` (0x1A = 26/255 ≈ 0.102);
  light defaults to null (no glow). `lerp` via nullable-safe
  `Color.lerp`; `copyWith` takes a sentinel default so an explicit null
  clears the token instead of reading as "not passed".
- `app/lib/core/design_system/tokens/nest_tokens.dart` — new
  `Color? get petGlow` delegate (`tokens.petGlow`; null in light).
- `app/lib/core/design_system/motion/pip_rive.dart` — new shared
  `PetStageGlow(stageW:, stageH:)` + its disc replaced: 230×230 box at
  x = stage centre / y = 42% of the stage height, `DecoratedBox`
  (`petStageGlow` key, `BoxShape.circle`) painted with
  `RadialGradient(center: (0, -0.1))` (= 45% of the box),
  `radius: 110/230`, `stops: [0, 0.7]`,
  `colors: [tokens.petGlow!, transparent]`; builds a shrink-wrapped
  nothing when the token is null (light).
- `app/lib/core/design_system/components/nest_pet_stage.dart` — both
  `_PetScene` discs (explicit slot + legacy Rive box) replaced with
  `PetStageGlow`; dead locals (`glowD`, `nestCx/nestCy`, `tokens`) removed.
  The legacy Rive `Stack` gained `clipBehavior: Clip.none` (the 230 box
  bleeds past short stages; the other two stacks already clip none — a
  clipped fade would re-introduce a hard edge).
- `app/test/core/design_system/nest_pet_stage_test.dart` — `_pumpSlot`
  gained a defaulted `mode:` param; new `pet glow` group (5 tests, below).
- `docs/design/SPACING_SPEC.md` — §0 token table gained the `--pet-glow`
  row (§7 already specified the 230×230 `::before` box).
- Docs: this report.

## What / why

1. Token, not a hard-coded alpha. The 10% white now lives in
   `NestSchemeColors.petGlow` (null = `none` in light); widgets only build
   the fade from it. The three `Color(0x1AFFFFFF)` literals are gone.
2. Geometry matches `::before` on every path: box 230×230 (was
   `nestW × 1.04` ≈ 245 at K03), x = stage centre, y = 42% of the stage
   height (the legacy Rive disc sat at the nest centre, ~53.5% — now 42%
   like the other two).
3. The fallback had to change too. The brief named the two `_PetScene`
   sites, but `PipNestFallback.build` painted the same solid disc — that is
   the SVG / reduced-motion / Rive-missing path (i.e. every screenshot-loop
   frame and every widget test), so leaving it would have kept the bug
   where it is most visible. One shared widget serves all three sites so
   they can never drift apart.
4. Deliberate deviation — `radius: 110/230`, not the brief's `110/115`.
   `RadialGradient.radius` is a fraction of the *whole shortest side*
   (`gradient.dart` `createShader`: `radius * rect.shortestSide`; docs:
   "a radius of 1.0 will place the 1.0 stop at 100.0 pixels" on a
   100 px-wide box). In the 230 box, `110/115` puts the 1.0 stop at 220 px
   (transparent at 154 px) — twice the token's `circle 110px`
   (transparent at 77 px). `110/230` is the exact CSS equivalent; the
   brief's test criteria (DecoratedBox + RadialGradient, 230×230, centre,
   stops, alpha) are all met as written.

## Tests added (`app/test/core/design_system/nest_pet_stage_test.dart`)

Group `pet glow matches --pet-glow (soft fade, not a solid disc)` — every
glow is found by `PetStageGlow.glowKey` and checked as a `DecoratedBox`
with a `RadialGradient`: 230×230, centre x = stage centre, centre y = 42%
of its own stage height ±2%, `center == (0, -0.1)`,
`radius == 110/230`, `stops == [0, 0.7]`, first colour
`Color(0x1AFFFFFF)` (alpha ≈ 0.10), second transparent:

- `token: null in light, white@10% in dark` — `tokens.petGlow` contract.
- `dark explicit SVG path: one 230×230 radial fade` — K03 params, single.
- `dark legacy SVG path: one 230×230 radial fade` — default params, single.
- `dark Rive boxes: every glow is the fade` — explicit + legacy Rive boxes;
  the Rive runtime is absent in tests so each paints twice (box + degraded
  fallback); each glow is validated against its own stage params (the
  `Positioned.fill` stretch means the fallback's render rect must not be
  used for its 42% line — see the helper comment).
- `light: no glow in explicit or legacy paths` — key finds nothing.

Verification on this branch: `dart format .` → 0 changed;
`flutter analyze` → No issues found!;
`flutter test` → +1409 All tests passed (16 in this file: 11 existing,
5 new, 0 modified elsewhere).

## Follow-ups screens must do

- Nothing required — no public API changed (only additions:
  optional `NestSchemeColors.petGlow`, `NestTokens.petGlow`,
  `PetStageGlow`). Merge is clean.
- K03: re-capture the dark UI shot (`DISABLE_ANIMATIONS=1`): expect the
  hard lilac disc gone, replaced by a barely-visible soft fade; no
  geometry test changes (nest 278, Pip 301, hearts 448 untouched).
- K06/K08/P17 + `design_system_gallery` (both embed `NestPetStage`):
  no action — light rendering is pixel-identical (no widget), dark just
  loses the hard edge.
- Known pre-existing layering (unchanged by this fix, still true):
  with Rive missing/reduced-motion the explicit/legacy Rive boxes paint
  the fade twice (box + inner fallback, ≈19% peak instead of 10%);
  production Rive-live paints once. A future `glow:` flag on
  `PipNestFallback` could suppress the inner one if the orchestrator wants
  byte-exact parity in reduced motion — out of scope here.

VERDICT: PASS
