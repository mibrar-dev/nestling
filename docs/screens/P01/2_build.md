# P01 Welcome — build notes (Stage 2, iteration 3)

Plan `1_plan.md` + every item in `FIXES_2.md` (review findings 1–7,
UI deviations 1–3, bug table, `ORCHESTRATOR_NOTES.md` #1–5).
Only RULES §1 paths touched.

## Files changed

- `app/lib/features/onboarding/presentation/views/welcome_view.dart`:
  **headline cap** (ORCHESTRATOR_NOTES #3, UI dev 1) — headline `Text` wrapped
  in `ConstrainedBox(maxWidth: _headlineW = 300)` so "like" falls to line 2
  at 390dp; a cap, never a hard `\n`, so 320dp (content 280 < cap) and text
  scale 1.3 still wrap naturally with no overflow. No other product change.
- `docs/screens/P01/SHARED_REQUEST.md`: added the inset-0 bottom-band floor
  as a low-priority shared item (review finding 4).
- `docs/screens/P01/2_build.md` (this file).

## Fix items (FIXES_2 disposition)

1. BUG-2 proof rewrite + doc correction — **already in tree**: proof asserts
   the shipped contract and passes; `3_test.md` Correction § already records
   BUG-2 fixed (the stale numbered item is explicitly superseded there).
   Verified, no edit needed.
2. Narrow SHARED_REQUEST item 2 — **already narrowed** (verified: the file
   records `AppSession._write` upserting since `763192d` and asks only for
   the repo-writer/bootstrap fix). No edit needed.
3. BUG-4 — stays skipped, still reproduces, filed. Un-skip belongs to the
   shared-fix change per the review.
4. Inset-0 bottom band — shared floor item added (low priority).
5. Explicit Pip `skin`/`mood` — **declined with evidence**: tried it, then
   reverted. `mood: PipMood.idle` is a compile error (ambiguous import:
   `pip_avatar` and `pip_rive` via the barrel both define `PipMood`), and
   `skin: PipSkin.sunny` trips `avoid_redundant_argument_values`, breaking
   the analyze gate. Defaults kept + rationale comment; resolved values
   stay pinned by the PipAvatar widget test (style/skin/mood).
6. Rive-idle vs static PNG — info, no action (§6 compliant by construction).
7. Cosmetics — info, no action (harmless duplication).
- UI dev 1 headline break — fixed via the ≈300 cap above (stage-5 pixel
  check owns verification; test fonts can't measure Nunito wrap).
- UI dev 2 home pill — per ORCHESTRATOR_NOTES #4, do not chase (iOS-drawn).
- UI dev 3 frame instability — investigated: `shot.sh` always passes
  `DISABLE_ANIMATIONS=1`, so `PipAvatar` takes its static SVG path and P01
  owns zero animation widgets (§6 compliant). Remaining repaint source is
  the runtime Google-Fonts fetch (no `fonts:` block in `pubspec.yaml`) —
  already in SHARED_REQUEST. Nothing P01-owned repaints.
- Bug table — BUG-1/2/3/3b/5 proofs enforced and passing; BUG-4 open,
  skipped, filed. Headline item done above.

## Checks (`app/`)

- `dart format .` — 342 files, 0 changed.
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — all pass (BUG-4 the only skip).
- `flutter test` (full) — **353 passed, 1 skipped, 0 failed**
  (`+353 ~1: All tests passed!`). The single skip is the shared-blocked
  BUG-4 proof; every P01-owned test passes.

## Correction (Stage 6, iteration 3)

`045d190` (`beforeOpen` creates the `app_state` row on open) landed after this
note was written, and Stage 3 rewrote + un-skipped the BUG-4 proof in the same
pass. Final state: **BUG-4 fixed on main, proof enforced and passing**, suite
**`+355: All tests passed!` (0 skipped, 0 failed)**; the "BUG-4 the only
skip" / "353 passed, 1 skipped" lines above are superseded. The Stage-6
iteration-3 pass adds a `BUG-4b` end-to-end proof (fresh install → complete
onboarding → restart lands on `/today`).

VERDICT: PASS
