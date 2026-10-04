# P16 Settings — 2b build, UI chunk (iteration 3)

Scope: views + widgets only; `FIXES_2.md` triage of the bug-fix items,
limited to assets I own. This document supersedes the iteration-2 copy.

## FIXES_2 triage (views/widgets owned items)

- **P16-T02 (major, switch tap target 51×31, not 44): FIXED.** Screen-local
  recipe from the bug stage, applied verbatim: the three switch rows render
  with P16's own `SettingsRow` at 6 px vertical padding (content box
  56 − 12 = 44) and each `NestToggle` is wrapped in
  `SizedBox(height: 44, Center(...))`. Padding alone did not restore the
  slop; the 44-high wrapper around the toggle is what makes the overhang
  hittable (verified by the failing proof, now un-skipped and green).
  `settings_a11y_test.dart` `[P16-T02]` is `skip: false`.
- **P16-B08 (minor, double tap during a modal close falls through): FIXED.**
  New `P16TransientGuard` (`presentation/widgets/p16_transient_guard.dart`):
  every modal/sheet close (`openZonePickerSheet`'s completion, the delete
  dialog's completion, and each picker row's close tap) records the instant;
  every page-level row tap (`onTap`/`onChanged` handlers on the settings
  list) runs through `P16TransientGuard.run`, which ignores taps for the
  next 300 ms. `p16_bugs_test.dart` `[P16-B08]` un-skipped, green.
- **P16-B09 (minor, IANA link ids rejected): NOT FIXED — out of scope.**
  `isKnownZoneId` lives in `app/lib/core/data/family_time.dart` (core
  data). Fixing it is a shared change tracked as SHARED_REQUEST §5; the
  screen-side proof stays skip-marked, and no feature-side workaround was
  attempted.
- **3_test §2.1/§4.4: `_P16Sect` runs a `TextPainter.layout()` per build.**
  Left as-is; no measurable cost. It is now intentional and documented.
- **3_test §4.4 #2 (Family list announces as ONE button):** not edited —
  the merge happens in shared `NestListRow`'s no-`onTap` branch; a local
  Semantics label on static rows was tried and rejected because it broke
  the tappable-node test contract over the whole Family section. Kept
  for the orchestrator's shared-batch pass.
- **Observation #5 (hard-coded `sarah@example.co.uk`):** unchanged, per
  plan §(g) static copy; members table still has no email column.
- **Review "three local re-implementations" (SettingsRow, p16_subcard,
  _P16Sect):** all three remain with the workarounds above and stay
  covered by dedicated tests; removing them needs the shared changes in
  SHARED_REQUEST §1/§2/§3.

## Contract notes

- `SettingsState.deviceZoneId` batched by 2a (unchanged by this pass);
  `SettingsSessionStore` un-skipped B02's proof earlier.
- No new imports of `google_fonts`; no `DateTime.now()` in feature code
  (B04 proof green); statics: quick work.
- `p16_test_support.dart` / `p16_bugs_test.dart` reset the static
  `P16TransientGuard` between tests (`P16TransientGuard.reset()`),
  because the guard is process-level state; the failing-in-full-run /
  passing-alone `[P16-clean]` picker test was exactly that leak.

## Verified

- `flutter analyze`: No issues found (full app).
- `dart format`: clean.
- `flutter test test/features/settings`: **+124 ~1** green (the single
  skip is P16-B09 — shared data-layer request, documented). B08 and T02
  are now live regression guards, un-skipped and passing.
- No simulator used.

## LEFT FOR NEXT ITERATION

- P16-B09 waits for SHARED_REQUEST §5 (`isKnownZoneId` link-id support)
  before its proof can be un-skipped.
- T02's screen-local recipe mirrors the exact bounds; if the shared fix
  in SHARED_REQUEST §1 lands, the local `SettingsRow` padding +
  `SizedBox(height: 44, Center(...))` wrapper for the three toggle rows
  should be retired in favour of the shared component.

VERDICT: PASS
