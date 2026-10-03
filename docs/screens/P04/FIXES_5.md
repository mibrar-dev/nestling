# Fix list after iteration 5

## From 5_ui.md
# P04 · Privacy consent — UI check (STAGE 5, iteration 4)

Route `/privacy` · SEED=fresh · parent mode · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A.
Shots: `docs/screens/P04/ui/app_light_4.png`, `docs/screens/P04/ui/app_dark_4.png`
(absolute OUT path — relative OUT breaks because `shot.sh` `cd`s to `app/` before copying).
Compares: `docs/screens/P04/ui/cmp_light_4.png`, `docs/screens/P04/ui/cmp_dark_4.png`.
Mandatory context: `docs/screens/P04/ORCHESTRATOR_NOTES.md` (items 1–4 + 12:03 + 13:42 updates).

## Mean diff

- Light: **4.10%** (was 4.57%) — bands: 0 (0–105) 1.58% · 1 (105–211) 6.02% ·
  2 (211–316) 1.98% · 3 (316–422) 7.94% · 4 (422–527) 5.78% · 5 (527–633) 4.19% ·
  6 (633–738) 0.40% · 7 (738–844) 4.84%
- Dark: **5.17%** (was 5.61%) — bands: 0 (0–105) 1.56% · 1 (105–211) 8.50% ·
  2 (211–316) 9.14% · 3 (316–422) 7.87% · 4 (422–527) 5.75% · 5 (527–633) 4.44% ·
  6 (633–738) 0.39% · 7 (738–844) 3.67%

Band 6 ≈ 0.4% confirms pipeline alignment. Status-bar glyphs ignored per STATUS BAR rule;
bottom-edge strip is the OWNER-rule override (app correct). Bands 4–5 improved vs iteration 3
(7.31→5.78, 6.52→4.19 light) — intra-list heights converging on the HTML.

## Shared state (read-only check)

- `app/assets/icons/ic_trash.svg` now exists on main (shared batch 1, `4751c52`, merged).
  The P04 view in this working tree still carries the `TODO(P04)` reserved-tile path
  (`privacy_consent_view.dart:126-130`) — wiring the glyph is build-stage work, not this stage's.
- Themed privacy-shield asset likewise landed on main; the view still renders the old asset.

## Verified matching (no action)

- Presence/order/copy exact (curly ’, em dashes per COPY rule); header at design y;
  20 px gutters; 40 px tiles r12; divider indent 72; opt-card 13 v/16 h; toggle OFF 51×31;
  CTA anchored; surface-to-edge panel both themes; no overflow/clipping/ellipsis.
  No Pip → PIP rule N/A.

## Deviations

1. Row-4 tile still has no trash glyph (both themes) — ORCHESTRATOR_NOTES item 1, still open.
   Design value: rust glyph pixels inside the peach tile.
   App value: plain tile — light `#FFEDE4`, dark `#3E261D` (tile tint correct, glyph absent).
   Fix (build stage, now unblocked): replace the `TODO(P04)` reserved tile with
   `NestIcons.trash` in the design's red-ink colour + widget test that all four row icons
   render. Designer-visible; blocks PASS.
2. Dark-mode shield disc still renders light (dark only; explains dark bands 1–2 at 8.50/9.14%
   vs light 6.02/1.98% — the 84 px disc sits across both bands).
   Design value: `#1A2A4A` (patch (160,228)).
   App value: `#E6EFFE`.
   Fix (build stage, now unblocked): point the shield at the themed asset from shared batch 1.
   Designer-visible in dark mode.
3. Residual glyph-level drift, bands 1/3 ≈ 6–8% both themes.
   App value: H1/row-title strokes show ~1 px doubling — consistent with HTML-vs-Flutter font
   raster (Nunito 900) rather than layout error; all measured tops/edges match within ±2 px
   logical (chevron 66/66, H1 113/113 per iteration-2 probes; CTA at design y).
   Fix: none required unless the build stage can attribute it to a concrete metric; re-probe
   after deviations 1–2 land. Not independently designer-visible.

No code edited in this stage (UI check is read-only).


## From 6_bugs.md
# P04 · Privacy consent — bug hunt (Stage 6, iteration 4)

Route `/privacy` · feature `privacy_consent` · parent mode · seeds `demo` and
first-run. **No screen code was changed.** Re-hunted the iteration-4 tree
after the shared batch 1 merge (`ce89889`: `ic_trash.svg` + `NestIcons.trash`,
`NestPrivacyShield`, migration-guaranteed settings row, shared `NestList`
overlay dividers) and the iteration-4 build (transactional upsert, local
separator overlay).

`app/test/features/privacy_consent/p04_bugs_test.dart` has **16 proofs:
14 green + 2 skipped** (P04-2, P04-7 — both now one-line wire-ups). Run the
skipped ones with:

```
flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
→ 14 passed, 2 failed (P04-2, P04-7, by design)
```

Method: read the merged shared changes and the two build rewrites; re-ran
every proof; measured `ui/app_{light,dark}_4.png` against the design PNGs with
pixel probes; re-checked the guards, copy, semantics and concurrency edges.
**No new product bug was found.** The two open defects are unchanged in
nature but are now fully actionable inside RULES §1 — the deferral
precondition in the orchestrator's 13:42 UPDATE is satisfied. `VERDICT: FAIL`.

## Iteration state

| Id | Sev | Finding | Status |
|---|---|---|---|
| P04-1 | major | first-run opt-in silently dropped | **FIXED** (it. 2; migration now also guarantees the row) |
| P04-2 | major | row 4 empty peach tile | **OPEN — actionable now**: `NestIcons.trash` is in the tree; the view still has the `TODO(P04)` and no `leadingAsset` |
| P04-3 | major | compact nav 16 px short | **FIXED** (shared merge, it. 2) |
| P04-4 | major | dividers inflate the list by 3 px | **FIXED** (it. 4, local overlay; shared `NestList` also fixed). Device probes below are Δ0 |
| P04-5 | minor | double-tap wrote the same value twice | **FIXED** (it. 2) |
| P04-6 | major | failed OFF write claimed "it stays off" | **FIXED** (it. 2) |
| P04-7 | **major** | dark mode renders the light-baked shield | **OPEN — actionable now**: `NestPrivacyShield` is in the tree and exported; the view still renders `privacy_shield.svg` |
| P04-8 | minor | failed toggle reverted to an unpersisted value | **FIXED** (it. 3) |
| P04-9 | minor | overlapping first-run writes kept the earlier value | **FIXED** (it. 4, transaction; proof deterministic) |

## Open defects (both one-line wire-ups, next build)

### P04-2 — row 4 must use `NestIcons.trash` — MAJOR

- **State:** `ic_trash.svg` and `NestIcons.trash` landed in `ce89889`; the
  iteration-4 device shot still shows **0 glyph pixels** inside the peach
  tile (x 32–72, y 463–502.7, colour run continuous `#FFEDE4`). The view
  (`privacy_consent_view.dart:122-134`) still carries the stale
  `TODO(P04)`: "ic_trash.svg + NestIcons.trash … missing". The design tile
  is `tokens.peachTint` + `tokens.aPeach` (`#FFEDE4` / `#B44A1F`), exactly
  what `NestTileTint.peach` + `NestIcon(NestIcons.trash)` produce.
- **Proof:** `[P04-2]` now asserts **four** `NestIcon`s, that their asset
  names **contain `NestIcons.trash`**, and four drawn `SvgPicture`s. It
  fails only on the missing wire-up.
- **Fix (one line + cleanup):**
  1. `leadingAsset: NestIcons.trash` on the row-4 `_PromiseRow`; delete the
     `TODO(P04)` block.
  2. `privacy_consent_view_contract_test.dart` — "rows 1-3 render their own
     tinted glyph; row 4 is the gap" asserts `findsNothing` for row 4; flip
     it to `findsOneWidget` with `assetName == NestIcons.trash` and
     `color == NestColors.light.aPeach`, and extend the light/dark tint loop
     to four rows.
  3. Drop `skip: true` from `[P04-2]` (the proof needs no other change).

### P04-7 — dark mode must use `NestPrivacyShield` — MAJOR

- **State:** the shared batch shipped
  `app/lib/core/design_system/components/nest_privacy_shield.dart`
  (token disc `skyTint`, body `surface`, heart `leaf`, stroke `ink`; exported
  from the design-system barrel; covered by `shared_batch1_test.dart`). It
  has **no consumer**, and the view still renders the baked
  `privacy_shield.svg` (`privacy_consent_view.dart:74-86`). Device probes on
  `ui/app_dark_4.png`: disc `#E6EFFE` vs design `#1A2A4A`; body `#FFFFFF` vs
  `#1F1C2E`. Dark band 2 (9.14 %) is the worst band in the dark sheet and is
  entirely this disc.
- **Proof:** `[P04-7]` was rewritten to be fix-agnostic — in dark mode no
  `SvgPicture` may load `NestlingIllustrations.privacyShield`, and the
  `image` node keeps the design alt text. It fails on the current view and
  passes with any themed implementation, including the shared component.
- **Fix:**
  1. Replace the `Center(Semantics(… SvgPicture …))` block with
     `NestPrivacyShield(size: 84, semanticLabel: 'A shield with a leaf and a
     heart, protecting your family')` — the component emits `image: true`
     with that label itself, so drop the manual wrapper.
  2. **Companion test the review did not list:**
     `privacy_consent_view_contract_test.dart:1239` ("the shield illustration
     is 84x84 and labelled") finds an `SvgPicture` **descendant** of the
     semantics label — it will fail after the component swap. Change it to
     assert `find.byType(NestPrivacyShield)` with size 84 and the same label
     (the copy test's `find.bySemanticsLabel(shieldAlt)` stays green).
  3. Drop `skip: true` from `[P04-7]`.

### Cleanup carried from review iteration 4 (not product bugs)

- Review finding 3: revert the promise rows to four direct `NestList`
  children and delete the local `showDivider`/`Stack` mechanism — the shared
  `NestList` now paints the identical overlay, so the feature layer should
  not keep its own copy (design-system duplication, currently pixel-exact).
- Review finding 4: replace the one mechanism-pinning assertion
  (`find.byType(Stack)` on row 1) with the result check (`dividerOf(0)`
  finds nothing).
- Review finding 5: the `2_build.md` test-tail quote. Documentation only.

## Verified this iteration (no new bugs)

- **P04-4 on device:** `ui/app_light_4.png` tile tops **295 / 351 / 407 /
  463** exactly match the design (all four rows probed); opt card corner probe 531.7 vs
  531.3; Continue 675 vs 674–675; no double separator (one overlay per row
  2–4, first row none). The shared `NestList` overlay and P04's single-Column
  structure do not combine into double lines.
- **P04-9:** the transactional upsert proof is un-skipped and green;
  concurrent first-run `true`/`false` writes settle on the second value with
  exactly one row. `Seed.fresh` still deletes the migration-inserted row, so
  the insert path remains genuinely exercised.
- **Migration guarantee:** `beforeOpen` now inserts `fam1` family + settings,
  so a real first launch no longer depends on P04's fallback (the fallback
  still covers `SEED=fresh` and any deleted row).
- **All other proofs green:** P04-1/3/4/5/6/8 and the guards — kid-mode
  redirect, deep-link back, restart persistence (demo + first-run), first-run
  double-tap last-write-wins, async gap after leaving, single dialog on a
  double tap. Copy rule still locked by the HTML-source test; typography
  characters exact.
- **N/A / unchanged:** children/long names/coins/£ values, timezone, money
  rounding (no such data on P04); Pip rule (no Pip); 320 px / scale 1.3
  matrix; dark contrast on token pairs; 20 px gutters; CTA surface to the
  physical edge.

## Mandatory notes status

| Item | Status |
|---|---|
| 1 — row-4 bin glyph + all-four-glyph test | **Unmet but fully actionable**: asset + `NestIcons.trash` in the worktree; appendix fix above. Item defers to the wire-up now, not to the orchestrator |
| 2 — header 16 px offset | **Met** (probes Δ0) |
| 3 — row heights/dividers → opt card ≈528 | **Met** (device probes Δ0; shared `NestList` also fixed) |
| 4 — bottom edge + alignment | **Met** (both themes; gutters 20 px) |
| COPY / CHILD ORDER | Copy met (tested); child order N/A |

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → 362 files, 0 changed.
- `flutter analyze` → No issues found.
- `flutter test test/features/privacy_consent/` → **118 passed, 2 skipped,
  0 failed** (the two actionable wire-up proofs).
- `flutter test` (whole app) → **645 passed, 2 skipped, 0 failed**.
- `--run-skipped` on the bug file → 14 passed, **2 failed** (P04-2, P04-7),
  each with its repro above.

## Verdict

Seven of nine findings are fixed and pinned; no new defect surfaced. But two
majors remain visibly open on the screen — the empty row-4 tile (P04-2) and
the light-baked dark shield (P04-7). Both were blocked on the shared batch;
the batch has landed and both fixes are now one-line wire-ups with their
companion test updates spelled out above. Until they land, the screen has a
visible blank tile on its main content and the worst band in the dark sheet
is still the light disc.

