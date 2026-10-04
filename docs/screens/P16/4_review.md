# P16 Settings — QA code review (iteration 4)

Reviewed `git diff main...HEAD` and the iteration 3→4 delta
(`git diff 7160fff...HEAD`) against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, the design system in
`app/lib/core/design_system/`, `docs/DESIGN_SPEC.md` §5 P16,
`docs/screens/P16/ORCHESTRATOR_NOTES.md` (incl. the 08:12 update), and
the HTML source.

## Iteration-3 finding disposition

1. **Literal sizes/typography — STILL OPEN (minor, carried).**
   `settings_view.dart:235` (`SizedBox(2)`), `:252` (`height: 52`),
   `:528`/`:588` (`fromLTRB(14, 12, 14, 12)`), `:541`/`:601`
   (`fontSize: 14` overrides) all remain.
2. **`_P16Sect` — STILL PRESENT (promoted to major, finding 1).**
3. **Legacy `SettingsItem`/`watchItems()`/`getItems()` — STILL PRESENT
   (minor, carried).** `settings_repository.dart:9-10`, impl, two test
   doubles; no bloc consumer.
4. **Stale docs — PARTIALLY FIXED (minor, carried).**
   `p16_bugs_test.dart` header was rewritten for B10/B11, but the B10
   block comment (`// P16-B10 open (minor) — ...`), the B11 block in
   `p16_bugs_test.dart`, and the `settings_responsive_test.dart` B11
   comment still describe live, unskipped proofs as "open / pinned
   skip-marked".
5. **NestToggle tap-target + fork reversion — see below.**

## Findings this iteration

1. **major** — ORCHESTRATOR_NOTES 08:12 item 3 is not honored. The
   screen still forks three shared components:
   - `_P16Sect` (`settings_view.dart:69`) replaces `NestSectionLabel`.
   - The subscription card is a local `Container(key: p16_subcard, …)`
     (`settings_view.dart:215-219`) instead of `NestCard`.
   - The toggle rows, delete row, member rows and child rows use the
     local `SettingsRow` fork (`settings_view.dart:290, 313, 333, 373,
     475, 497`) instead of the shared `NestListRow`.
   The note is explicit: record the measured delta in SHARED_REQUEST.md
   and keep the shared widget. The forks are also UI debt that the next
   design-system change silently diverges from.
   Fix: revert to `NestSectionLabel`, `NestCard`, `NestListRow`; where a
   design metric genuinely differs, add the measurement to
   `SHARED_REQUEST.md` and wait for main.

2. **minor** — B11 is fixed in code but the docs/tests still call it
   open. The delta adds `width: 51` to the toggle wrapper
   (`settings_view.dart:298,316,337`), and the B11 proofs
   (`p16_bugs_test.dart` B11, `settings_responsive_test.dart` B11) are
   `skip: false`. Their comments, however, still say
   "OPEN BUG — pinned skip-marked ... run with --run-skipped".
   Fix: update the two comments to record B11 as fixed with the
   wrapper change.

3. **minor** — The iteration-4 delta's B10 fix is in but its own stale
   header remains: `p16_bugs_test.dart` B10 comment reads "P16-B10 open
   (minor) — ... Fix: wrap both row handlers ..." while `skip: false`
   and the code now wraps the handlers. Same stale-comment pattern as
   finding 2.

4. **minor** — P16-B09 still `skip: true`
   (`p16_bugs_test.dart:530`). The note at 08:12 asks to un-skip all
   four proofs, but the root cause (`latest_10y` dataset drops linked
   IANA ids; `isKnownZoneId`) is core shared code on main —
   SHARED_REQUEST §5 already records it and there is no feature-side
   workaround. Escalate to the orchestrator to land §5, then un-skip.

5. **minor (carried)** — Owner row still renders the literal
   `sarah@example.co.uk` (`settings_view.dart:468`). SHARED_REQUEST #4
   asks for `members.email`; 08:12 item 2 accepts that as the path.
   Once the column lands, the row should read it (TODO(P16) tracking).

6. **minor** — `P16TransientGuard` remains process-wide static state
   (no ownership of its lifetime outside this route). Every row now goes
   through it, so it works, but cross-screen reuse is still blocked by
   its design; tracked here for a future shared variant.

## Verified clean this iteration

- B10 fix present: the invite toast row (`:185`) and delete row (`:377`)
  now route through `P16TransientGuard.run` like every other row.
- T02 target is 51×31 track inside a 44 px wrapper; the a11y proof
  asserts a 56 px row, 6 px padding and 44 px hit box and is unskipped.
- `p16_transient_guard_test.dart` (new) pins the 300 ms window, the
  cross-test reset, and that the banner buttons are deliberately NOT
  fenced.
- No path edits outside `app/lib/features/settings/**`,
  `app/test/features/settings/**` and `docs/screens/P16/**` in the
  iteration-4 delta, except the earlier `dart format` nits on the
  shared `list_row_trailing_test.dart`; no app/lib/core or app/lib/app
  changes.
- CLOCK rule still holds (`appNowUtc()` only); no analytics/ads;
  parent-only route; architecture layering unchanged.

VERDICT: FAIL
