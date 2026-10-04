# P16 Settings — QA code review (iteration 1)

Reviewed `git diff main...HEAD` against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, the design system in
`app/lib/core/design_system/`, `docs/DESIGN_SPEC.md` §5 P16 and
`design/html-source/screens/P16-settings.html`.

## Findings

1. **major** — Device zone is dropped from the picker after the banner is
   dismissed. `zone_picker_sheet.dart:48` derives the device zone from
   `state.pendingZone`, which the bloc nulls out on
   `SettingsMoveDismissed` (`settings_bloc.dart`, `_onMoveDismissed`) and
   everywhere the banner is hidden. ORCHESTRATOR_NOTES is mandatory and
   says the picker always shows "the device zone first when it differs".
   Once the user taps "Not now", the device zone loses its first-position
   row and its `· Current location` marker.
   Fix: keep the device zone in its own `SettingsState.deviceZoneId`
   field (populated by the same one-shot read), and have the picker order
   by that field instead of `pendingZone`. The comment at
   `zone_picker_sheet.dart:44-47` already concedes this gap.

2. **major** — Subscription card corner radius deviates from the design.
   `settings_view.dart:172` uses `NestCard.standard`, which decorates with
   `NestRadii.allL` (24 px, `nest_card.dart:34-38`), but the HTML design
   pins `.subcard{border-radius:var(--r-m)}` (16 px, tokens.css:77). Every
   other card on this screen (`NestList`, `_MoveBanner`, `_LockHint`)
   correctly uses 16 px, so the subcard will be visually off.
   Fix: render the subscription card with the same inline surface
   container as `_LockHint` (`color: tokens.surface`, `NestRadii.allM`,
   `tokens.cardShadow`, padding 14/16), or add a radius override to
   `NestCard` via SHARED_REQUEST.

3. **major** — Edit outside the feature's allowed paths.
   `app/test/features/today/today_view_test.dart` was modified
   (lines 522-530). RULES.md §1 allows a screen agent to edit only
   `app/lib/features/settings/**`, `app/test/features/settings/**` and
   `docs/screens/P16/**`. The intent (assert `/settings` via
   `pushedPath` after the placeholder title was replaced) is right, but
   the edit must be orchestrated onto `main` as a shared change.
   Fix: revert the hunk in this branch and file it as a SHARED_REQUEST
   (or ask the orchestrator to apply it); note the repo already has
   `docs/screens/_shared/router_push_test_fix_REPORT.md` covering this
   pattern.

4. **minor** — Orchestrator CLOCK rule deviation. `settings_view.dart:115`
   and `zone_picker_sheet.dart:85` call `DateTime.now().toUtc()`, and the
   widget tests (`settings_view_test.dart:174, 272`) compute expectations
   from real wall-clock time, so the asserted GMT offset changes with the
   season (e.g. London is GMT+1 in October but GMT+0 in January). The
   rule says app code uses `clock.now()` / `appNowUtc()` and tests never
   assert real-wall-clock copy. This mirrors existing shared code
   (`today_bloc.dart:56`, `family_zone_service.dart:94`), so it is a
   repo-wide inconsistency, but P16 should not extend it.
   Fix: inject the "now" (bloc field or `AppSession`-style clock) and use
   it in both the row and the picker; pin test expectations to the
   pinned Sat 3 Oct 2026.

5. **minor** — Legacy `items` state is now dead code. The replaced
   `SettingsView` no longer reads `state.items` (grep confirms no
   consumer), yet `settings_bloc.dart:73` still builds
   `settingsItemsFor(settings)` on every emission and
   `SettingsItem`/`settingsItemsFor` are kept "while the UI builder
   replaces the view" — it has been replaced in this same diff.
   Fix: delete `SettingsState.items`, `settingsItemsFor`, and the
   `items` branch from `SettingsStatus.loaded` handling, or keep them
   only behind an explicit TODO if a consumer is planned.

6. **minor** — Owner row hard-codes `sarah@example.co.uk`
   (`settings_view.dart:374`). Any `role == 'owner'` member renders that
   email regardless of the stored row, so a renamed/deleted Sarah would
   still display it. `SettingsMemberEntry` carries no email.
   Fix: extend the entity/repository to surface the stored email (or a
   generic subtitle such as `Owner`), or drop the hard-coded string to a
   token-driven placeholder.

7. **minor** — Hard-coded dimensions/typography in the new widgets.
   `settings_view.dart:431, 491` use `EdgeInsets.fromLTRB(14, 12, 14, 12)`,
   `height: 52` (line 198), banner text `fontSize: 14` / `height: 20 / 14`
   overrides, and `const SizedBox(height: 2)`; `_MoveBanner`/`_LockHint`
   hand-roll `BoxDecoration` instead of a design-system card. The
   spacing/typography values match tokens where they exist
   (`s3` = 12, `s4` = 16), but 14/52/2 are magic numbers and the hand-rolled
   containers duplicate `NestCard` internals.
   Fix: add the missing steps to `NestSpacing` (or reuse `s3`/`s4`) and
   expose the card shell via the design system rather than copying its
   decoration.

8. **minor** — Double semantics on the subscription manage row.
   `settings_view.dart:188-196` nests `Semantics(button: true, onTap: …)`
   inside an `InkWell(onTap: …)`, which already contributes a button
   semantics node; the composed node can duplicate the tap action for
   assistive tech.
   Fix: put the label on the InkWell's semantic child via a single
   `Semantics` wrapper (or use `MaterialButton`-style built-in labelling)
   and assert one `SemanticsAction.tap` node per control in tests.

## What checked out OK

- Feature-first structure respected inside settings: entities + abstract
  repo in `domain/`, Drift impl in `data/`, BLoC per screen in
  `presentation/bloc/`, DI via `registerSettings` wiring
  `FamilyZoneService` (settings_di.dart).
- Bloc uses a single `emit.forEach` over combined streams; write handlers
  do not emit (state follows the watched streams), matching house pattern
  and preventing re-subscription leaks; `_closeOnError` mirrors the
  P08-B08 leak fix.
- Roster ordering Maya → Leo via creation order; members via insertion
  order; both documented.
- Copy is char-exact vs HTML (em dashes, · separators, `›`, `Family &
  settings`, curly `’` in the banner); IANA ids only appear in the
  picker; kid mode cannot reach the route (parent shell).
- Toggle semantics asserted with `SemanticsAction.tap` performing the
  real DB write; banner Switch/Not now and picker paths covered by
  widget tests.
- No `google_fonts` imports, no analytics/ads, no child data leaks in
  the new code; `NestToggle`/`NestListRow`/`SettingsRow` metrics match
  the shared rows; bottom edge left to `ParentShell`.

VERDICT: FAIL
