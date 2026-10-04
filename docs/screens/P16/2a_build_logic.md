# P16 Settings — 2a build, logic chunk (iteration 4)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
`settings_di.dart`, plus unit/bloc tests. No view/widget file touched.

## CONTRACT CHANGES

None. No state/event/entity/DI shape changed this iteration.

## FIXES_3 triage (logic layer)

Every open item was audited for a logic-layer hook; none has one:

- **P16-B11** (switches 34.5 px off the right edge): the wrapper
  `SizedBox(height: 44, Center(...))` expands to the 120 px trail cap in
  `settings_view.dart`. The fix (`width: 51` shrink-wrap / `Align`) applies
  in views. The bloc only supplies toggle state — no hook.
- **P16-B10** (guard misses delete/invite rows): the fix wraps two view
  `onTap`s in `P16TransientGuard.run`. Navigation and dialog opens originate
  in view tap handlers; the bloc cannot fence them.
- **P16-B09** (IANA link ids): shared `family_time.dart`
  (`isKnownZoneId`/`normalizeZoneId`), SHARED_REQUEST §5. The raw id never
  reaches the bloc — no feature-side hook exists.
- T02 stays fixed and proved; CLOCK stays clean — `grep DateTime.now()`
  over domain/data/bloc → 0 hits (re-verified this iteration).

Accordingly no skipped proof in my layer needed un-skipping: B09/B10/B11
proofs live in `p16_bugs_test.dart` (views/shared) and stay skipped pending
the UI builder / orchestrator.

## Files changed

None in `app/`. Owned paths are byte-identical to the iteration-3
checkpoint (`git status` clean).

## Verification (this iteration)

- `flutter analyze lib/features/settings` → No issues found.
- `flutter test` on my files (`settings_bloc_test.dart`,
  `settings_repository_test.dart`) → 39/39 pass.
- No simulator booted, screenshotted or driven.

## LEFT FOR NEXT ITERATION

- Nothing outstanding in the logic layer. Open FIXES_3 items (B09, B10,
  B11) are views/shared-owned as triaged above.

VERDICT: PASS
