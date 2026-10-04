# P16 Settings — 2a build, logic chunk (iteration 3)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
`settings_di.dart`, plus unit/bloc tests. No view/widget file touched.

## CONTRACT CHANGES

None. No state/event/entity/DI shape changed this iteration.

## FIXES_2 triage (logic layer)

Every open item was audited for a logic-layer hook; none has one:

- **P16-T02** (switch 44 px target): hit-test geometry lives in the row
  layout (`settings_view.dart` rows + shared `NestToggle`/`NestListRow`).
  The verified screen-local recipe (`SizedBox(height: 44)` wrapper) applies
  in views; the bloc already writes toggles through and already exposes the
  tap action. Nothing in domain/data/bloc/DI can move a hit-test rect.
- **P16-B08** (double-tap fall-through during modal close): the stray tap
  lands on a view row that calls `context.push`. The guard (modal-closed
  timestamp ignoring row taps ~300 ms) belongs in views, or in the shared
  modal/sheet helpers. The bloc cannot intercept route pushes.
- **P16-B09** (IANA link ids): explicitly shared (`family_time.dart`,
  `isKnownZoneId`); SHARED_REQUEST §5. The raw id never reaches the bloc —
  "no feature-side workaround exists" per the bug report.
- Observations §4.4 (Family-list announcement, shared semantics wart,
  `_P16Sect` TextPainter, hard-coded email, local components, `.ptitle`
  balance): all views/shared/schema. The CLOCK observation is clean —
  `grep DateTime.now() lib/features/settings/` → 0 hits (verified this
  iteration across domain/data/bloc).

Accordingly no skipped proof in my layer needed un-skipping: T02's proof is
in `settings_a11y_test.dart` (views), B08/B09's in `p16_bugs_test.dart`
(views/shared). All stay skipped pending the UI builder / orchestrator.

## Files changed

None in `app/`. My layer is byte-identical to the iteration-2 checkpoint
(`git status` clean for all owned paths).

## Verification (this iteration)

- `flutter analyze lib/features/settings` → No issues found.
- `flutter test` on my files (`settings_bloc_test.dart`,
  `settings_repository_test.dart`) → 39/39 pass, including the iteration-2
  additions (deviceZoneId-after-dismiss, session-store rebuild + DI fallback,
  app-clock write-stamp pin).
- No simulator booted, screenshotted or driven.

## LEFT FOR NEXT ITERATION

- Nothing outstanding in the logic layer. Open FIXES_2 items (T02, B08,
  B09) are views/shared-owned as triaged above.

VERDICT: PASS
