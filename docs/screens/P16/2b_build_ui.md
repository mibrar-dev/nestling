# P16 Settings — 2b build, UI chunk (iteration 4)

Scope: views + widgets only; `FIXES_3.md` triage, limited to assets I own.

## FIXES_3 triage (views/widgets owned items)

- **P16-B11 (major, switches 34.5 px off the right edge): FIXED.**
  The T02 wrapper is now `SizedBox(width: 51, height: 44, child:
  Center(child: NestToggle(...)))` for all three switch rows, so the
  wrapper no longer stretches to the row's 120 px trailing cap and the
  track sits flush with the row's 16 px right inset (x 303–354 at 390,
  233–284 at 320). `settings_responsive_test.dart` `[P16-B11]` is
  un-skipped and green; the T02 proof still passes with the new
  wrapper, so both findings are pinned together on the same layout.
- **P16-B10 (minor, guard did not fence delete row / invite row):
  FIXED.** `Delete family account` and the `Invite co-parent` toast row
  `onTap`s now route through `P16TransientGuard.run`, exactly like the
  other navigational rows. Un-skipped `[P16-B10]`: double-tap on Cancel
  no longer re-opens the dialog, and a picker double-tap landing on the
  delete row no longer opens it either.
- **P16-B09 (minor, IANA link ids): NOT FIXED — shared.** The root
  cause is in core `family_time.dart`/`isKnownZoneId` (treated as an
  unknown zone, which blocks the device-zone prompt). Carried via
  SHARED_REQUEST §5; the feature-side proof stays skip-marked.
- **3_test observations carried forward (iteration 2/3, not regressions):**
  Family list merges into one announcement (shared `NestListRow`
  no-`onTap` branch, blast radius pinned); `sarah@example.co.uk`
  hard-coded (SHARED_REQUEST §4); `_P16Sect` per-build `TextPainter`
  accepted; three local forks documented against SHARED_REQUEST §1/§2/§3.

## Test-harness coupling found while fixing B10

- `settings_view_test.dart` pumps a raw `SettingsView` without the
  route harness, so it never went through `P16TransientGuard.reset()`.
  Adding the guarded delete-row onTap broke its modal-open test by the
  stale guard window. Reset is now inserted into that test file's pump
  helper as well (`P16TransientGuard.reset()` after `addTearDown`).

## Verified

- `flutter analyze`: No issues found (feature lib + tests).
- `dart format`: clean.
- `flutter test test/features/settings`: **+134 ~1** green (only skip is
  P16-B09 — the shared data-layer request). T02, B08, B10 and B11 now
  have live un-skipped proofs; the delete-dialog toast and re-open path
  is covered by the full-app harness too.
- No simulator used; no new feature edits outside
  `presentation/{views,widgets}` + `app/test/features/settings`.

## LEFT FOR NEXT ITERATION

- P16-B09 waits for SHARED_REQUEST §5 (`isKnownZoneId` link-id
  support) before its proof can be un-skipped.
- If SHARED_REQUEST §1 ships the shared 44 px row-native fix for
  P16-T02, retire the local `SettingsRow` + `SizedBox(width: 51,
  height: 44, Center(...))` recipe.

VERDICT: PASS
