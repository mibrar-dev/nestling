# K07 · 2b BUILD UI (iteration 2) — views + widgets of feature `pip`

Scope owned and edited: `app/lib/features/pip/presentation/views/**` and
`presentation/widgets/**`, plus the K07 view/widget/bug/copy tests I had to keep
in step. No `domain/`, `data/` or `bloc/` file was edited (the 2a state file was
temporarily patched **only** to prove a defect, then restored byte-for-byte —
md5 `30843865b9248985a885b1e5f2c0acf1`, see §1). No simulator was booted,
installed on or driven; no `flutter clean`; no `analysis_options` change; no
skipped gate left behind that this stage owns.

Gates run by this stage:

```
flutter analyze lib/features/pip test/features/pip      → No issues found!
dart format --output=none --set-exit-if-changed \
    lib/features/pip test/features/pip                  → 0 changed
```

---

## 0. MANDATORY FOR THE INTEGRATOR — two red tests, one 2-line logic fix

`PipState.copyWithLoaded` / `copyWithEvolution` compute `status` from the
**sibling** stream's error slot but do not pass that slot into the new state, so
the error is silently dropped. `PipState` (`presentation/bloc/pip_state.dart`,
2a's file, ~lines 133-170 — **not mine to edit**) needs, in `copyWithLoaded`:

```dart
      nest: next,
      evolution: evolution,
      nestSettled: true,
      evolutionSettled: evolutionSettled,
      evolutionError: evolutionError,      // ← ADD: carry the sibling's slot
      actionError: actionError,
```

and, in `copyWithEvolution`:

```dart
      nest: nest,
      evolution: next,
      nestSettled: nestSettled,
      evolutionSettled: true,
      nestError: nestError,                 // ← ADD: and here
      actionError: actionError,
```

**Why it is real, not theoretical.** The evolution stream's `Stream.error` is
delivered in a microtask, while the nest's first emission needs real Drift I/O,
so on the real `PipRepositoryImpl` the **error lands first** and the healthy
sibling emission then wipes it. Measured state during
`pip_evolution_view_test.dart` → *"the nest stream healthy and this one
failing"* (fake: nest real, evolution `Stream.error`):

```
PipState(PipStatus.failure, PipNest(…Maya…), null, /*nestSettled*/true,
         /*evolutionSettled*/false, null, /*nestError*/null,
         /*evolutionError*/null, null, 0)
```

`evolutionStatus` reads `loading` from a settled-false / error-null pair, so the
celebration screen would sit on its spinner forever instead of showing the
failure card. Mirror symptom on K06 (`copyWithEvolution` dropping `nestError`),
which is why `pip_nest_states_test.dart` → *"the K07 stream healthy and this one
failing"* is red too.

**Proof it is exactly this and nothing else.** With the two lines applied,
`pip_nest_states_test.dart` + `pip_evolution_view_test.dart` → `+41: All tests
passed!`. The patch was then reverted and `pip_state.dart` verified restored
(identical md5 to 2a's version; `git status` still shows only 2a's own diff).

Currently red, and green the moment those two lines land:

- `test/features/pip/pip_evolution_view_test.dart` → *the nest stream healthy and
  this one failing: the failure card, not the who-is-playing card*
- `test/features/pip/pip_nest_states_test.dart` → *load failure the K07 stream
  healthy and this one failing: the failure card, not the who-is-playing card*

(`errorMessage`, the aggregate diagnostic, is dropped by the same two methods —
harmless, no view reads it, but it is the same oversight.)

---

## 1. Items from `FIXES_1.md` — UI / layout / copy, all closed

| item | where | what |
|---|---|---|
| **finding 1** = `5_ui.md` **D2** = `6_bugs.md` **K07-BUG-4** (MAJOR, mandatory via `ORCHESTRATOR_NOTES.md`) | `pip_evolution_sparks.dart` | `_sparkPath` hands **every** vertex, the `M` pair included, to one `Path.addPolygon`. `addPolygon` opens its own contour, so the old `moveTo(numbers[0], numbers[1])` before it was discarded and `close` returned to the polygon's own first vertex — every sparkle painted as a flat-topped 7-gon. Measured before: art rows 46..60, 14 px tall, 5 px off the design's centre line. After: rows 37..60, symmetric about the design's y 49, width unchanged. The `d` strings were already byte-exact; only the parser was wrong. |
| **finding 11** (MINOR) | same file | the four `Path`s are parsed once and cached (`_Spark.path` → `static final Map<String, Path>`), so a repaint no longer compiles a `RegExp`, re-runs `allMatches` and allocates four `Path`s. |
| **finding 5** (MINOR) | `pip_evolution_view.dart` `_EvolutionBar` | the `.kid-bar` 3 px ink rule is now built **only** when there is a CTA. On loading / failure / no-child the bar is a plain surface band instead of a full-width rule over an empty 53 px strip. The surface box stays, so the owner BOTTOM EDGE rule (same colour to the physical edge, no strip, light and dark) is untouched. |
| **finding 6** (MINOR) | `pip_evolution_view.dart` + copy header | one convention for the screen: the spinner label is now `"Loading Pip's big moment"` (ASCII), matching `"Let's try again."`, `"Who's playing?"` and the design's own `Pip's`. The reasoning is written into `pip_evolution_copy.dart`'s header instead of being implicit. |
| **finding 7** (MINOR) | `pip_evolution_copy.dart` | stage 1 no longer contradicts itself: the hero reads `Pip grew into an Egg!`, so the bubble reads `Psst… Pip is still an Egg!` (was `Shh... Pip is still growing!`) — and the ellipsis is `…`, never three ASCII dots. |
| **finding 8** (MINOR) | `pip_evolution_copy.dart` + `pip_evolution_stats.dart` | the three stat labels moved out of the widget into the copy table as `evolutionStatQuestsLabel()` / `evolutionStatCoinsLabel()` / `evolutionStatStagesLabel()`, so `pip_evolution_copy.dart` really is the screen's single copy table. |
| **finding 2** view half (K07-BUG-1) | `pip_evolution_view.dart` + `pip_nest_view.dart` | both views now switch on **their own** stream (`state.evolutionStatus` / `state.nestStatus`). The sibling-stream branches (K07's line 94-95, K06's `if (state.evolution != null) return const _PipFailure();`) are gone, exactly as `2a_build_logic.md` CONTRACT CHANGES §1 requires. `pip_evolution_view.dart`'s `failure` branch keeps `state.evolution?.profile ?? state.nest?.profile` for the last-known Pip. |
| **finding 12** = `6_bugs.md` **K07-BUG-2** (MINOR) | `pip_evolution_stage.dart` | below the design's 350 px of slot content the three fixed-size pieces no longer fit (352 px needed), so the right-anchored grown Pip slid 72 px over the arrow. The slot is now wrapped in `FittedBox(scaleDown, bottomRight)` **only** when `maxWidth < 350`: at 390 and above the geometry is byte-identical (scale 1.0, same Stack), at 320 everything scales by 0.8 and the arrow/old Pip are legible again (measured gap +6 / +27 instead of −72 / −36). Stage 1's centred single Pip is untouched. |
| **K07-BUG-3** widget half | `pip_evolution_view.dart` + `pip_evolution_stats.dart` | the `quests done` card now renders `evolution.questsFinishedCount` (distinct quests) while the sub-line keeps the row count it honestly calls "times" (`2a` CONTRACT CHANGES §2). Demo data is unchanged (4 rows / 4 quests) so the design still shows `4`. |

### Deliberately not actioned

- **finding 3** (red `dart format` on `k07_sparkles_bug_test.dart`) — done:
  that file is now formatted and both analyzers are clean.
- **finding 4** (K07 opens K06's stream it never renders) — 2a kept it as-is
  pending the orchestrator ruling; nothing view-side.
- **finding 9** (dark-mode sparkle fills differ from the dark PNG) — no code
  change, on purpose. The design's inline SVG hard-codes `#7C6CF2` / `#1F9D63` /
  `#FF8A5B` while the design system re-themes accents on dark surfaces, and
  "tokens only, never hard-code colours" wins. The token re-theme stands (the
  same trade every inline-SVG accent screen makes); **the orchestrator still owes
  the explicit ruling** — this stage did not file it, it is recorded in
  `4_review.md` finding 9.

## 2. Proofs un-skipped (every one green)

- `k07_sparkles_bug_test.dart` — all three `skip: true` flags dropped (the
  mechanism test, the "design's polygon, tip included" raster comparison and
  the symmetry proof). Two of them needed an honest repair, not a weaker
  assertion: the tip-band expectation was 6 rows in `28..33` where a **centred**
  3 px stroke caps the tip at `y = 28.5`, so rows 29..33 are solid and row 28 is
  the halo (measured: row 28 alpha 1..127, rows 29..33 > 200); and the reference
  raster drew only the four `<path>`s, so the screen's four `<circle>` dots —
  which the design has too — counted as 832 "differing" pixels. The reference now
  rasterises the whole `<g>` parsed from the HTML, and both assertions are
  stronger than before (exact tip row, halo present, 0 differing px).
- `k07_bugs_test.dart` — **K07-BUG-1** (widget half), **K07-BUG-2**,
  **K07-BUG-3** (widget half) and **K07-BUG-4** un-skipped; the file is now
  `+14: All tests passed!` with **zero** skips.
  - K07-BUG-1's widget proof needed restructuring to match the fix: the old
    second half demanded that a retry re-subscribe, which cannot hold now that a
    pending screen shows **no retry at all**. It asserts the honest rule instead
    (no `k07-retry` while pending, spinner instead of the false card), and then
    releases the gate with the real repository's evolution and proves the
    celebration appears — a stronger proof than the dead-button count. The
    "a REAL failure's retry really re-subscribes" half was already pinned by the
    file's passing `cleared:` test, so nothing is lost.
  - `_PendingEvolutionRepository` now takes the value the fake will deliver, and
    `closeGate()` delivers it before closing, so the release assertion is real.

## 3. Copy changes (character by character)

Only three strings moved, none of them design copy:

| string | before | after | why |
|---|---|---|---|
| stage-1 bubble | `Shh... Pip is still growing!` | `Psst… Pip is still an Egg!` | contradicted its own hero; three ASCII dots → `…` |
| spinner label | `Loading Pip’s big moment` | `Loading Pip's big moment` | one apostrophe convention (ASCII, like the design's `Pip's`) |
| stat labels | inline literals | `pip_evolution_copy.dart` | one copy table |

`pip_evolution_copy_test.dart` was updated for the bubble and gained two
assertions: no `...` in any stage line, and the stage-1 line must name what the
hero says it grew into; plus a test that the three labels come from the copy
table.

## 4. Test runs (all with `--timeout 120s`)

```
k07_sparkles_bug_test.dart + pip_evolution_sparks_test.dart   → +10  All passed
k07_bugs_test.dart                                             → +14  All passed (was 6 skipped)
pip_evolution_widget_test.dart + pip_evolution_a11y_test.dart
  + pip_evolution_copy_test.dart                              → +66  All passed
pip_nest_view_test.dart + pip_nest_widget_test.dart           → +22  All passed
pip_nest_interactions_test.dart + k06_bugs_test.dart          → +52  All passed
pip_orchestrator_notes_test.dart
  + pip_shared_component_fidelity_test.dart
  + pip_copy_parity_test.dart                                 → +28  All passed
pip_evolution_view_test.dart                                  → +20 -1  (the §0 logic defect)
pip_nest_states_test.dart                                     → +19 -1  (the §0 logic defect)
```

The 320 px fit matrix (light/dark × 320/390/430 × text scale 1.0/1.3) and the
`k07-bar` geometry suite (`top ≈ 721`, height 123, surface to the edge) still pass
inside `pip_evolution_widget_test.dart`, i.e. the `FittedBox` and the
`border: null` change moved nothing at 390.

## 5. For the next stages

- **`5_ui` must re-measure the sparkle band** (per `4_review.md` note 1). The
  sparkles' ink boxes now run 14 logical px higher, onto the design's own
  coordinates: design `y 407..528` / app was `449..528` / app is now `407..528`,
  same for all four. `D2` should clear; `D1` stays exempt (orchestrator-accepted
  DB-truth wrap, +34 px below the title), `D3` stays accepted.
- **The §0 two-line state fix** before the feature directory can be green.
- Nothing else in this layer.

## LEFT FOR NEXT ITERATION

- The §0 `pip_state.dart` carry-through (2a / integrator / review — not a UI
  item, and this stage may not edit bloc files).
- The orchestrator ruling on `4_review.md` finding 9 (dark-mode sparkle accents):
  accept the token re-theme (recommended) or file a literal-accent token. No
  code changes in this stage either way.

VERDICT: PASS