# P04 · Privacy consent — STAGE 2b UI build (iteration 8)

Scope: `presentation/views/**` + view/widget tests in
`app/test/features/privacy_consent/`. No edits to `domain/`, `data/`,
`presentation/bloc/` (logic builder's layer).

## FIXES_7 items — UI-layer triage

FIXES_7 carries exactly one UI defect; everything else was already fixed and
pinned in earlier iterations.

### P04-10 — opt-card title wraps to two lines (MAJOR) — FIXED locally

- **Root cause (from the bug hunt's measurements):** the design sets no
  tracking on `.opt-title`, but `NestType` styles are `inherit: true` with no
  `letterSpacing`, so Material's `DefaultTextStyle` (0.3px) leaks in. With
  the newly bundled Inter the title needs 250.2px in the 247px text column
  and wraps; the card grows 22px (116 vs the design's 94). Both themes.
- **Shared fix status:** SHARED_REQUEST §7 (core `letterSpacing: 0` default,
  or `NestToggle` minWidth 59→51) has **not** landed — verified
  `tokens/typography.dart` still passes a nullable `letterSpacing` straight
  through and `nest_toggle.dart` still reserves `minWidth: 59`. Core is
  outside RULES §1 for a screen agent.
- **Local fix (the fix the bug report sanctions for P04):**
  `privacy_consent_view.dart` opt-card title style now sets
  `letterSpacing: 0` (the design's own value — its CSS has no tracking),
  with a comment pointing at SHARED_REQUEST §7. Title renders one 22px line;
  card back to the design's 94px (13 + 22 + 2 + 44 + 13). Toggle tap target,
  card padding and row gap untouched, per the UI check's instruction.
- **Proof un-skipped:** `[P04-10] the opt-card title stays on one 22px line`
  in `p04_bugs_test.dart` — `skip: true` dropped; it loads the bundled
  `Inter-*.ttf` faces, measures title height 22 and card height 94, and is
  **green**. File header/index updated to `[FIXED]`.
- **SHARED_REQUEST.md §7 status updated:** P04 half resolved locally; the
  shared half (leak on every other screen) stays open for core.

### Everything else in FIXES_7 — verified, no action

UI check's "verified matching" list (header offsets, 84px shield, trash
glyph, toggle, gutters, CTA-to-edge, copy) re-confirmed by the green view /
contract / copy / bug suites below. No other deviation was reported.

## Files changed (all inside RULES §1)

- `app/lib/features/privacy_consent/presentation/views/privacy_consent_view.dart`
  — one style property + comment (the P04-10 fix above).
- `app/test/features/privacy_consent/p04_bugs_test.dart` — un-skipped
  `[P04-10]`, refreshed header/index/fix comments. (Bug-proof file: my brief
  directs me to un-skip and pass the bug tests FIXES_7 references.)
- `docs/screens/P04/SHARED_REQUEST.md` — §7 status note (local half landed,
  shared half open).

## Logic-builder contract check

Re-read `docs/screens/P04/2a_build_logic.md` (iteration 8) before finishing:
**CONTRACT CHANGES: none** — the fix needed no bloc/state/event adaptation.

## Verification (feature scope only — no whole-app run, no simulator)

```
dart format --set-exit-if-changed lib/features/privacy_consent \
  test/features/privacy_consent        → 19 files, 0 changed
flutter analyze lib/features/privacy_consent
                                     → No issues found!
flutter test … view_test + view_contract_test + copy_test + p04_bugs_test
  → 00:06 +88: All tests passed!   (88 passed, 0 skipped, 0 failed)
```

The 88 include the un-skipped `[P04-10]`, which measures the real bundled
Inter metrics (title 22px, card 94px) — the same measurement the device made
when it reported 44/116.

## LEFT FOR NEXT ITERATION

- **Shared (not P04's):** the app-wide `letterSpacing: 0.3` leak stays until
  core typography or `NestToggle` is fixed — tracked in SHARED_REQUEST §7.
  When it lands, the view's local `letterSpacing: 0` becomes a harmless no-op
  that can be deleted.
- The integrator owns this iteration's whole-app `flutter test` and the
  simulator re-shoot (band 5/6 should fall back to the iteration-6 baseline).

VERDICT: PASS
