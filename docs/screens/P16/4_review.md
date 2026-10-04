# P16 Settings — QA code review (iteration 2)

Reviewed `git diff main...HEAD` (branch now based on main with the
kid_meadow merge in) against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, the design system in
`app/lib/core/design_system/`, `docs/DESIGN_SPEC.md` §5 P16,
`docs/screens/P16/ORCHESTRATOR_NOTES.md` and
`design/html-source/screens/P16-settings.html`.
Iteration-1 findings were checked for resolution first.

## Iteration-1 finding disposition

1. **Device zone lost from the picker after banner dismissal — FIXED.**
   `SettingsState.deviceZoneId` keeps the one-shot device-zone read
   independently of `pendingZone` (settings_state.dart:40,
   settings_bloc.dart:108/167); the picker now orders by that field
   (zone_picker_sheet.dart:46-52) and the banner still clears on
   dismissal. P16-B01 regression test unskipped and passing.
2. **Subscription card corner radius — FIXED (local) with shared debt
   tracked.** The card is now an explicit surface container with
   `NestRadii.allM` (16 px, matching `.subcard`) and `NestSpacing.gap14`
   padding (settings_view.dart:211-221); SHARED_REQUEST #3 asks for a
   `NestCard` radius variant.
3. **Today-test path edit outside allowed dirs — ACCEPTED BY DOC.**
   The 2-line `pushedPath` swap remains in the diff and is explicitly
   documented in SHARED_REQUEST ("Also worth the orchestrator's
   attention") with a note that the main merge delivers it cleanly; no
   longer classed as a defect of this diff.
4. **CLOCK rule — FIXED.** No `DateTime.now()` remains in
   `app/lib/features/settings`; views and repo use `appNowUtc()`
   (app_clock.dart on main), and the guard test
   `[P16-B04] feature code never calls DateTime.now()` (p16_bugs_test.dart:291)
   is `skip: false` and green.
5. **Dead legacy `items` in bloc — FIXED.** `SettingsState.items` and
   the `settingsItemsFor` call in the bloc are gone. (`watchItems()` /
   `SettingsItem` remain in the repository surface — see finding 3
   below.)
6. **Hard-coded owner email — CARRIED TO SHARED_REQUEST #4** (schema has
   no `members.email`); literal copy retained behind a documented debt.
7. **Hard-coded sizes — PARTIALLY FIXED.** Subcard padding now uses
   `NestSpacing.gap14`/`s4`; banner/lockhint paddings, `52`, `2` and the
   `fontSize: 14` overrides remain literal (see finding 1 below).
8. **Double semantics on subscription row — FIXED.** The explicit
   `Semantics` now carries `excludeSemantics: true` and a real `onTap:`
   (settings_view.dart:238-245), satisfying the accessibility-action
   rule.

## Findings this iteration

1. **minor** — Remaining literal sizes/typography.
   `settings_view.dart:480` and `:540` use
   `EdgeInsets.fromLTRB(14, 12, 14, 12)` (tokens exist:
   `NestSpacing.gap14`, `NestSpacing.s3`); `:231` uses
   `SizedBox(height: 2)` (`NestSpacing.gap2` exists); `:244` uses
   `height: 52` (no token — candidate for SHARED_REQUEST or a token);
   `:493`/`:553` override `fontSize: 14` / `height: 20/14` on banner
   and lockhint text rather than a named style.
   Fix: swap literals for the matching `NestSpacing` steps and give the
   two 14 px texts a named `NestType` style (or a local labelled one).

2. **minor** — `_P16Sect` TextPainter probe (settings_view.dart:68-94)
   duplicates `NestSectionLabel` with a one-off layout pass on every
   build. It exists only to work around the shared label's 18 px line
   box, is documented in SHARED_REQUEST #2, and keeps
   `header: true`. Acceptable as a temporary shim; delete it once the
   shared label lands.

3. **minor** — `SettingsItem` / `settingsItemsFor` / `getItems()` /
   `watchItems()` no longer feed any bloc state now that the view was
   rebuilt, yet remain in the repository interface
   (settings_repository.dart:9-10), impl
   (settings_repository_impl.dart:21-25) and two test doubles
   (settings_bloc_test.dart:749, settings_states_test.dart:229).
   Fix: delete the legacy rows surface (entity was kept only "while the
   P16 UI builder replaces it" — that is done), or mark it clearly as
   public API with a consumer.

4. **minor (cross-cutting, documented)** — `NestToggle`'s hit slop does
   not extend the 44 px tap target (P16-T02), and the picker sheet's
   max-height overflow is guarded by a `Flexible` +
   `SingleChildScrollView` local fix (P16-B03). Both were root-caused to
   shared components and filed in SHARED_REQUEST; the toggle proof stays
   `skip: true` in settings_a11y_test.dart:264 until the shared fix
   lands on main. Not a defect of this diff, but the screen's tap-target
   contract is not yet enforced.

## Verified clean this iteration

- Architecture: feature-first layout unchanged; bloc still one
  `emit.forEach`; write handlers emit only when the watched DB/zone
  streams re-emit, except the session-scoped dismissal store
  (`SettingsSessionStore`, registered in `registerSettings`) which is
  bloc-independent and DB-free — a fair reading of "dismissals live in
  the bloc, not the DB" across route rebuilds.
- No path edits outside settings/`docs/screens/P16` in lib code; no
  `app/lib/core/**` or `app/lib/app/**` diffs in this branch's settings
  work (only the pre-existing `appNowUtc` was reused).
- `flutter analyze` level ownership: new tests
  (`p16_test_support.dart`, `p16_bugs_test.dart`,
  `settings_a11y_test.dart`, etc.) are self-contained; stage-6 reports no
  `skip:false` regressions and 7 open-bug proofs failing as intended
  during iteration 1, now fixed (B01, B02, B04, B05, B06 + more in
  FIXES_1.md).
- Children's Code: parent-only route; no analytics/ads/child data
  leakage introduced; kid mode cannot reach `/settings`.
- Copy / glyphs / £ / en-dashes unchanged from the HTML source.

VERDICT: PASS
