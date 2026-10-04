# P16 Settings — QA code review (iteration 3)

Reviewed `git diff main...HEAD`, plus the iteration 2→3 delta
(`git diff 29b2e2d...HEAD`), against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, the design system in
`app/lib/core/design_system/`, `docs/DESIGN_SPEC.md` §5 P16,
`docs/screens/P16/ORCHESTRATOR_NOTES.md` and the HTML source.

## Iteration-2 finding disposition

1. **Literal sizes/typography — STILL OPEN (minor, carried).**
   `settings_view.dart:231` `SizedBox(height: 2)` (token: `NestSpacing.gap2`),
   `:244` `height: 52`, banner/lockhint `fromLTRB(14, 12, 14, 12)`
   (`:480`, `:540`, tokens `gap14`/`s3`), `:493`/`:553` `fontSize: 14`
   overrides all remain. Banner/lockhint had a token path available in
   iteration 2 and it was only used for the subcard.
2. **`_P16Sect` TextPainter probe — STILL PRESENT (minor, accepted).**
   The shim is unchanged and still needed until SHARED_REQUEST #2 lands
   on main; it is clearly labelled.
3. **Legacy `SettingsItem`/`watchItems()`/`getItems()` — STILL PRESENT
   (minor, carried).** No bloc consumes them; they remain in
   `settings_repository.dart:9-10`, `settings_repository_impl.dart:21-25`
   and two test doubles (`settings_bloc_test.dart:749`,
   `settings_states_test.dart:229`).
4. **NestToggle tap-target gap (P16-T02) — FIXED in iteration 3.** The
   three switch rows now use the P16-local `SettingsRow` with 6 px
   vertical padding (content box 56 − 12 = 44) and each `NestToggle` is
   wrapped in `SizedBox(height: 44, Center(...))`
   (settings_view.dart:288-348). The guard test
   `[P16-T02] a switch is live 5 px above and 5 px below its track` is
   unskipped and asserts the real behaviour. Note: SHARED_REQUEST #1
   still describes T02 as a shared fix only — it is now stale; see
   finding 1 below.
5. **P16-B08 (double tap while a modal closes) — FIXED in iteration 3.**
   `P16TransientGuard` (`p16_transient_guard.dart`) suppresses row taps
   for 300 ms after a modal/sheet close (`zone_picker_sheet.dart:36,100`,
   `settings_view.dart:443`), every row's `onTap`/`onChanged` routes
   through `P16TransientGuard.run`, the B08 proof is `skip: false`, and
   tests reset the static via `P16TransientGuard.reset()`
   (p16_test_support.dart:96).
6. **P16-B09 (linked IANA ids rejected) — CARRIED as shared.** Repro is
   `skip: true` by design with the root cause filed as SHARED_REQUEST
   §5; feature-side has no workaround.

## Findings this iteration

1. **minor** — Stale documents left after the iteration-3 fixes.
   - `p16_bugs_test.dart:6-9` and `:483` still describe P16-B08 as
     "open (minor)", but line 489 sets `skip: false` after the fix.
   - `settings_a11y_test.dart:296` still says the T02 test is
     "pinned skip-marked", but line 342 runs it unskipped.
   - `SHARED_REQUEST.md` #1 still tells the orchestrator T02 can only be
     fixed in the shared toggle; iteration 3 fixed it screen-locally.
   Fix: update the three comments/SHARED_REQUEST entries to say fixed
   and drop the "NestToggle shared fix" ask (or narrow it to an
   optional hardening).

2. **minor** — `P16TransientGuard` is static mutable state used for
   per-app behaviour. It works because every tap routes through
   `run(...)` and tests reset it, but any future route that forgets to
   guard, or a test that misses `reset()`, silently changes behaviour.
   Fix: acceptable for a screen-local fence; if more screens need it,
   promote it to a shared helper (with the same reset hook) via
   SHARED_REQUEST.

3. **minor** — Format-only edits outside the allowed paths.
   `app/test/design_system/list_row_trailing_test.dart` was reformatted
   (`pumpNest` call sites compacted). RULES.md §1 gives a screen agent
   only `app/lib/features/settings/**`, `app/test/features/settings/**`
   and `docs/screens/P16/**`. Formatting of shared test files belongs on
   main, not in a screen branch.
   Fix: revert that hunk (or land a repo-wide `dart format` on main).

4. **minor (carried)** — Owner row still renders the literal
   `sarah@example.co.uk` (settings_view.dart:422) with no
   `members.email` column behind it; tracked in SHARED_REQUEST #4. Any
   other owner/DB drift would also show the literal; the row should
   either read a real column or display a role-derived subtitle.

## Verified clean this iteration

- Feature-first architecture preserved: entities + abstract repo in
  `domain/`, Drift impl in `data/`, bloc per screen, DI wiring in
  `settings_di.dart` (now also registering `SettingsSessionStore`).
- Bloc unchanged in shape: one `emit.forEach` over combined streams,
  write handlers never emit directly, session dismissals merged from the
  session store; `_closeOnError` still present for the retry path.
- Every tappable row/toggle passes through `P16TransientGuard.run`, the
  picker sets the guard at close time, and the delete dialog seeds it at
  `settings_view.dart:443` — B08 test pins this.
- No `DateTime.now()` in feature code (B04 guard still green); no
  `google_fonts` imports introduced; tests still pin Sat 3 Oct 2026.
- No new path edits outside settings/`docs/screens/P16` except the
  formatting nit in finding 3.
- Children's Code: parent-only route; no analytics/ads; kid mode cannot
  reach the screen.

VERDICT: PASS
