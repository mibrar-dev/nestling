# K03 Kid home — build notes (Stage 2, iteration 3)

Implements `1_plan.md` as overridden by `ORCHESTRATOR_NOTES.md` (PipAvatar
mandate, DB counts, PERIODS ruling, iteration-3 bottom-inset note) and fixes
every item in `FIXES_2.md` that is fixable inside the feature (RULES §1).

## Files changed (all inside RULES §1)

- `app/lib/features/kid_home/presentation/views/kid_home_view.dart`
  - Bottom chrome owns the OS inset (ORCHESTRATOR_NOTES #8, FIXES_2 UI
    #1/#2): dock container + `NestHomeIndicator` wrapped in
    `SafeArea(top: false)`. The shared indicator renders shrink since main
    `763192d` (OS draws the real pill; reserving 34 + mock pill would
    reintroduce P01 BUG-2's double-count), and the kid dock is not inside
    `NestBottomCta`, so the inset lives here. On the 390x844 iPhone the
    dock moves up by the 34px home inset and the KidScope hill shows
    through the transparent zone (green to the bottom edge, both themes);
    in widget tests (zero view padding) layout is byte-identical, so the
    whole suite is unaffected. No mock pill is rendered (OS draws the real
    one — same doctrine as the STATUS BAR rule).
  - Meadow band tone (iteration-2 follow-up): the panel now paints uniform
    `kidHorizon`. Pixel measurement of both design PNGs lands exactly on
    that token (light `#EAF7E2`; dark within a few levels), while the
    shared KidScope hill stays `kidMeadow`. No hard-coded colours.
  - (Iteration-2 work, kept:) `PipAvatar` pet slot (152 over the 260x236
    nest, HTML geometry), local `.speech` bubble, `_HeartIcon` two-tone
    hearts, explicit dock-icon token tints, success-driven celebration nav,
    per-card `_busy` latch + `_GateLockButton` latch, period-scoped repo.
- `app/lib/features/kid_home/data/kid_home_repository_impl.dart`,
  `presentation/bloc/*` — unchanged since iteration 2 (period scoping,
  idempotent transaction, celebration-on-flip, nonce).
- `docs/screens/K03/SHARED_REQUEST.md` — #4 DONE (PERIODS ruling adopted
  locally, proof green); #5 updated: main `5eea2ad` wired the flag into
  `MediaQuery`, but `=1` still parses false — parsing fix still needed.
- Deleted `app/test/scratch_define_test.dart` (untracked scratch probe
  debris, not part of any feature; it broke `analyze` with a
  `document_ignores` info).

## Fix-item ledger (FIXES_2)

- UI #1 home-strip background: FIXED as above. Band 7: 27.7% → ~11% light
  (verify below), dark likewise. Root cause found during the fix: the
  white/navy strip was the dock surface extended to the screen edge after
  main removed the 34px reserve — proven via widget-tree dump
  (`NestHomeIndicator` → `SizedBox.shrink`).
- UI #2 dock height (+28): FIXED by the same SafeArea — the +28 was the
  missing bottom inset, not content height (card-1 top already matched at
  +3). Dock top now ≈713-719 vs design 719-721 (verify below).
- UI #3 green start / #4 hearts +12: NO GAP CHANGES, deliberately, with
  evidence. A positions probe on the live tree proves every inter-block
  gap is exactly the specified 16 (pet→hearts, hearts→section verified to
  the pixel; progress/panel/card chain matches the model to ±3). Absolute
  rows therefore follow only from block heights, and the iteration-2
  captures' larger offsets are live-Rive variance: with BUG-7's `=1`
  parsing still broken on main, `shot.sh` captures the ANIMATED `PipStage`
  artboard (never stabilises — both runs warn), whose frame geometry moves
  pixels around between captures (card-1 top measured +3 in one capture,
  +22 in another with identical code). Trimming spec gaps to match random
  animation frames would break the still-frame geometry, which models at
  hearts 441-443 vs design 443 (in tolerance). Re-verify with stable
  frames once the `=1` parsing lands.
- Stage-3 K03-BUG-7/8 (v1 art in empty/failure states): already fixed in
  iteration 2 (`PipAvatar` in both states); suite green, verified below.
- Stage-6 K03-BUG-7 (motion flag): still OPEN (shared parsing). Proof run
  with the documented flag still fails as expected; stays conditionally
  skipped; SHARED_REQUEST #5 updated. Pre-existing pip_fallback asset
  failures seen mid-loop were transient (concurrent art edits); green now.
- Stage-6 K03-BUG-8/9: fixed in iteration 2, proofs green, verified below.

## Verification (in `app/`)

- `dart format .` — clean (0 changed).
- `flutter analyze` — `No issues found!`
- `flutter test` — full suite: `+461 ~1, All tests passed!` (1 skip =
  K03-BUG-7 motion proof, conditional on the dart-define by design;
  run separately with the flag to confirm the shared failure).
- Screenshots: `shot.sh /kid-home` light + dark (kid/maya/demo) →
  `docs/screens/K03/ui/app_light_5.png`, `app_dark_5.png`; `compare.py` →
  `cmp_light_5.png`, `cmp_dark_5.png` (both runs warn "never stabilised",
  the known K03-BUG-7 cause: live Rive frames; layout chrome is static).
  - light mean diff 13.15% — bands: 0:3.00 · 1:4.85 · 2:10.84 · 3:13.18 ·
    4:13.20 · 5:23.28 · 6:25.80 · 7:11.02 (was 27.72 in iter2)
  - dark mean diff 11.86% — bands: 0:3.04 · 1:4.47 · 2:8.96 · 3:9.71 ·
    4:12.90 · 5:23.12 · 6:23.37 · 7:9.30 (was 26.87 in iter2)
  - dock top border measured at y≈715 (design 719-721); home strip green
    in both themes ((191,232,176) light hill); green band behind
    progress/cards in the horizon tone; hearts stroked; dock icons match
    (light white/dark/white, dark all dark).
  - Remaining bands 5/6 are the accepted set: live counts copy, repo card
    order/content, tile tint + title size (shared), mandated Pip art swap.
    (One dark capture in this round caught SpringBoard instead of the app
    and was discarded; re-taken valid.)

VERDICT: PASS
