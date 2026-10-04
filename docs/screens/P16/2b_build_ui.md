# P16 Settings — 2b build, UI chunk (iteration 1)

Scope: presentation layer only — `presentation/views/**`,
`presentation/widgets/**`, and `app/test/features/settings/*view*` /
`*widget*`. No domain/data/bloc edits.

## Files changed

- `app/lib/features/settings/presentation/views/settings_view.dart`
  (rewritten): full Family & settings screen per `1_plan.md` §(a) and
  the HTML source. Sections Family / Children / Subscription / Time zone /
  Notifications / Privacy / About with the design's spacing
  (24 above section labels, 8 below, 16 between scroll children, 20 px
  side gutters, bottom pad 32). Rows, toggles, subcard, lock hint,
  move banner, and delete-confirm modal render from `SettingsState`.
  Static subscription copy; toggles/zone-row/banner write through bloc
  events; rows navigate with `context.push` to child-profile,
  add-children, paywall, privacy. Failure surface = static copy +
  `Try again` (`SettingsLoadRequested`); loading = spinner. Chevrons
  and `›` use the shared token styles; danger row via SettingsRow.
- `app/lib/features/settings/presentation/widgets/settings_rows.dart`
  (new): `SettingsRow` — a NestListRow-metric row (identical padding,
  min-height 56, title 16/600, subtitle caption) that takes an arbitrary
  leading widget (32 px `NestAvatar`) and optional danger title colour,
  which shared `NestListRow` cannot express. Plus `settingsChevron` and
  `settingsAvatarColor` glue.
- `app/lib/features/settings/presentation/widgets/zone_picker_sheet.dart`
  (new): `openZonePickerSheet` (NestBottomSheet, device zone first with
  `IANA · Current location`, curated list with `IANA · GMT±n` subtitles,
  check on the stored family zone; pick → `SettingsTimeZonePicked`) and
  `settingsZoneSummary` (`London (GMT+1)` formatting via the bloc's
  `gmtOffsetLabel`).
- `app/lib/features/settings/presentation/widgets/settings_placeholder_card.dart`
  (deleted): unused placeholder.
- `app/test/features/settings/settings_view_test.dart` (new, 8 tests):
  char-exact copy (`—`, `·`, `–`, `&`, `›`), DB-driven child rows
  (Maya 7–9 / Fledgling / 120; Leo 4–6 / Hatchling / 45), time-zone row
  short label + GMT offset, toggle semantics tap action flips the real
  Setting row, move banner Switch stores the device zone and clears the
  banner, Not now hides it without touching the DB, picker lists the
  device zone first and picking writes the zone, delete modal Cancel
  keeps data. Bloc built with a fake `deviceZoneReader` so the host
  timezone never leaks in; `BlocProvider.value` pattern like P14.

## Items done (plan §a + §c + §e widget half)

- Whole widget tree from the plan built against the 2a bloc contract
  (state fields, event names, `gmtOffsetLabel`); no contract changes
  needed beyond 2a's documented placement note.
- Copy verified character-by-character against the HTML source in the
  widget tests (em/en dashes, middle dots, curly apostrophe in the move
  banner: `Looks like you’re in …`).
- Notifications toggles: `NestToggle` mirrors `settings.notif*`; the
  tap semantics node carries the HTML aria-labels; a `performAction(tap)`
  drives the real DB write (test).
- Move banner: leaf-tint card below the title, Switch →
  `SettingsMoveConfirmed`, Not now → `SettingsMoveDismissed` (bloc-local).
- No google_fonts import anywhere in the feature.
- `NestSpacing`/`NestRadii`/`tokens` only — no hard-coded colours or
  pixel sizes outside the shared design tokens.

Verified: `flutter analyze` (app) → No issues found; `dart format` clean;
`flutter test test/features/settings` → 31/31 pass; no simulator used.

## LEFT FOR NEXT ITERATION

- Stage 5 UI check owns the simulator shot/compare work.
- Real co-parent invite + help & feedback are toast placeholders by plan
  (no routes exist yet).

VERDICT: PASS
