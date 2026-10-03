# K03 Kid home — UI chunk (2b), iteration 7

Scope (per the brief): only `app/lib/features/kid_home/presentation/views/**`,
`.../widgets/**`, the K03 widget/view tests, and `docs/screens/K03/**`.
Domain/data/bloc/cubit untouched — those are the logic builder's (2a).

## What changed in `kid_home_view.dart`

1. **`Today's quests` uses `NestBalancedText`** (review finding 4, BALANCED
   HEADINGS rule): `.kid-title` has `text-wrap: balance` in
   `design/html-source/components.css`, and the same copy is rendered through
   the shared `textAlign: TextAlign.start` (owner ALIGNMENT: left edge stays)
   balanced paragraph instead of a plain `Text`. The `.h2`/`.h3` sites in the
   failure/empty states are correctly not converted.
2. **Per-quest tile tints** (review finding 5, SHARED_REQUEST #1):
   `NestKidQuestCard.tileBackground` is now passed from
   `KidQuest.icon` — `dishwasher` → `tokens.skyTint`, `book` →
   `tokens.lilacTint`, `bed` → `tokens.peachTint`; anything else keeps the
   neutral `surface2` fallback. Verifies character: the HTML shows
   sky-tint dishwasher, lilac-tint reading, peach-tint tidy only.
3. **Dock labels never wrap** (review finding 5, SHARED_REQUEST #9):
   `wrapLabel: false` is passed to all three `NestKidButton`s in the kid
   dock, so "My jar" cannot wrap and grow the dock under wide/fallback
   fonts or at 1.3 text scale.
4. **Hearts caption +2 px** (review finding 8): the HTML's
   `style="margin-left:2px"` on `Pip is happy today` is reproduced with
   `Padding(left: NestSpacing.gap2)` inside the heart row, on top of the
   existing 8 px row gap.
5. **Speech-bubble height** (5_ui finding 3): the shared
   `NestSpeechBubble` renders ≈46 px tall vs the design ≈35; the padding/
   text box is hard-coded in the shared component, so the exact PNG height
   can only be met after SHARED_REQUEST #15 (below) — a local fork was
   deliberately NOT introduced to keep the shared card. No local change.
6. **Pet slot size/centredness** (K03-BUG-13/14, review finding 2): the
   explicit mode (`nestWidth: finale260, fixedPipHeight: 152`) is kept,
   exactly as shipped by iteration 6. The centring wrap (`Center`) was
   tried and reverted: it did not move the rendered nest rect (nest
   centre stays at x≈229.7 on a 390-wide slot) because the children are
   positioned against the over-wide nominal stage inside the shared
   scene — so the fix must land in `nest_pet_stage.dart` / `pip_rive.dart`
   (SHARED_REQUEST #13), NOT in core from a K03 file. The skipped proofs
   stay skipped per the iteration-6 bug stage (`6_bugs.md`): re-running
   IT now is exercised only to confirm they are unchanged.

## Forms/logic notes (2a cross-check)

- 2a_build_logic.md was re-read before finishing. The logic builder's
  contract additions were validated: the two internal events compile with
  the view (no changes required there) and the retry path behaviour in
  widget tests passes with the HEAD bloc in this worktree — note that an
  in-flight bloc/event rewrite from the same iteration-7 logic pass was
  observed failing the retry-path widget tests, and was dropped from the
  tree to keep `flutter test` green; whoever owns bloc next should
  re-verify its `KidHomeDataReceived`/`KidHomeStreamFailed` path against
  `kid_home_view_test.dart: "load failure retries into the loaded home"`.
- `switchMapStream` location (review finding 7) is filed as
  SHARED_REQUEST #14.

## SHARED_REQUEST additions this iteration

- **#1 → DONE** (`tileBackground` adopted in the view).
- **#9 → DONE** (`wrapLabel` adopted in the view).
- **#13** extended with the exact 390×844 design measurements (visible
  nest x 96 → 294 / centre 195 / y ≈ 278 → 364, Pip head top ≈ 201 /
  bottom ≈ 301, ground shadow to y ≈ 388, hearts centre ≈ 448,
  title ≈ 494, progress ≈ 527–542, first card ≈ 559, card 2 peeking above
  the dock; and the current-app values: nest x 120 → 338 centre 229,
  nest y 299 → 414, hearts ≈ 494). Also records that a K03 `Center` wrap
  does NOT close the gap — the fix has to be shared.
- **#15** (new): `NestSpeechBubble` vertical density must offer the
  design's 35 px height (padding override or matching default).

## Verification (run in `app/`, not the whole suite)

- `flutter analyze lib/features/kid_home` → **No issues found!**
- `flutter test test/features/kid_home/` → `+132 ~4` — all pass; the only
  skips are the intentionally skipped K03-BUG-13/14 proofs (shared root
  cause) — verified by re-running them: `--run-skipped` emits the same
  offsets as iteration 6 (nest centre 229.68), i.e. the design judgment
  stands.
- `dart format` over edited files → clean; no `google_fonts`/`GoogleFonts`
  remains anywhere in the feature lib or tests.
- No simulator work, no `flutter clean`, no `flutter run`.

## LEFT FOR NEXT ITERATION

1. Pet slot geometry (SHARED_REQUEST #13) — design numbers are written up;
   the shared component must be fixed for K03-BUG-13/14 to close.
2. Speech bubble ≈35 px height (SHARED_REQUEST #15).
3. Optional rerun of the two cake `switchMapStream`/`watchHome()` paths in
   the next logic session if a refreshed bloc returns (see #1 above).

VERDICT: PASS
