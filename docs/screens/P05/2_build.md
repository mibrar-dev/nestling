# P05 · Add children — build notes (STAGE 2, iteration 3)

Route `/add-children` (feature `family`, parent mode). Iteration 2 record is
superseded below. Every item in `docs/screens/P05/FIXES_2.md` is addressed;
the skipped P05-BUG-8 proof is un-skipped and green; zero skips remain. New
this iteration: the standing CHILD ORDER ruling (creation order, never
alphabetical) and the COPY rule (design typography, character-exact).

## Files changed (RULES §1 only)

- `app/lib/features/family/presentation/widgets/kid_card_grid.dart` —
  `padding: EdgeInsets.zero` on the inner `GridView.builder` (P05-BUG-8;
  without it the grid re-applies the 47/34 device insets as its own
  SliverPadding and pushes the form under the CTA); `TODO(P05)` behind which
  P05 consumes the repository order until the shared creation-order fix
  lands.
- `app/lib/features/family/presentation/bloc/family_state.dart` —
  `lastSavedNickname` now uses the `_keepLastSavedNickname` sentinel, so
  copyWith can clear it like `nicknameError` (finding 7).
- `app/lib/features/family/presentation/widgets/child_display.dart` —
  unknown `avatar_colour` keeps the neutral fallback but logs
  `debugPrint('P05 unknown avatar colour: …')` (finding 8).
- `app/lib/features/family/presentation/views/add_children_view.dart` — h1
  uses the design's `’` (U+2019) instead of ASCII `'` (COPY rule; the HTML
  source has `Who&rsquo;s`).
- `app/test/features/family/add_children_test.dart` — 9 `find.text`
  references updated to `’`; nothing else changed.
- `app/test/features/family/p05_bugs_test.dart` — BUG-8 `skip:` removed;
  BUG-1 swatch proof renamed to `… are selectable after scrolling`
  (finding 3 — it scrolls before tapping); header comment updated.
- `docs/screens/P05/SHARED_REQUEST.md` — new BLOCKING creation-order
  request (CHILD ORDER ruling); nav-crash/nav-height items already marked
  LANDED.
- `docs/screens/P05/2_build.md` — this file.

No files outside RULES §1 touched. No `domain/` interface changes, no core
changes, no signature changes to existing members.

## What was done about each fix item

- **Finding 1 / P05-BUG-8 (major) — grid re-applies device insets.**
  One-line fix exactly as prescribed: `padding: EdgeInsets.zero` on the
  inner `GridView.builder`. The un-skipped proof (device insets via
  `tester.view.padding` + `viewPadding`, gaps asserted 14.0 / 12.0) passes.
  The review's `Wrap` rewrite was not taken: it would change card heights
  and churn passing geometry tests for no functional gain beyond this line.
- **Finding 2 — single-row chips only proven on simulator.** No build
  action (mitigation + shared request already in place); the UI stage
  re-asserts the row on-device.
- **Finding 3 — proof name promised no-scroll visibility.** Renamed to
  `… are selectable after scrolling`; body unchanged.
- **Finding 4 — Continue dropped mid-save.** Accepted explicitly as
  intended: the buttons disable for the whole save, the window is one
  frame, and the design has no "still saving" state — a pending-navigation
  flag would invent behaviour the design never shows.
- **Finding 5 — `onSaved` callback in the bloc.** Deferred again (P15 has
  not landed; removing it would change a shared member's signature). The
  double-fire root cause stays closed by the BUG-2 guard.
- **Finding 6 — `child_display.dart` holds no widgets.** Accepted:
  ARCHITECTURE forbids extra *folders*, not feature-private files, and a
  mapper module is a normal Dart idiom; attaching the functions to widgets
  would couple them to widget classes they don't need.
- **Finding 7 — `copyWith` kept `lastSavedNickname` forever.** Sentinel
  added, mirroring `_keepNicknameError` ten lines above.
- **Finding 8 — unknown avatar colour invisible.** Fallback kept (DS-safe),
  one-line `debugPrint` added, same pattern as the save-error log.
- **Finding 9 — raw exception string to a parent.** Left as-is and noted:
  `error.toString()` in state is the codebase-wide pattern (P08 identical)
  and the failure test pins it; changing it here would fork one screen off
  the app-wide convention — orchestrator decision if it should change.
- **Finding 10 — 1 px pencil offsets.** Signed off again as a faithful
  mirror of `.edit { top: 1px }` (core tokens read-only, no 1 px step);
  requesting a whole new scale step for one CSS-faithful pixel would be
  noise, so no new shared entry.
- **CHILD ORDER ruling — creation order, Maya before Leo.** Cannot be done
  in RULES §1: `watchChildren` orders by `nickname` in core, the table has
  no creation marker, and the entity carries none, so no local sort can
  recover insertion order. Filed as BLOCKING shared request (createdAt
  column or rowid ordering — every roster screen inherits it at once).
  Meanwhile P05 consumes the repository order behind `TODO(P05)` and the
  order-locking test keeps documenting the current behaviour; it flips with
  the shared fix.
- **COPY ruling — `’` (U+2019).** Compared every P05 string against
  `design/html-source/screens/P05-add-children.html` character by
  character: the h1 was the only ASCII-where-design-has-typographic miss
  (`&rsquo;`). Fixed in the view; all test references updated. Everything
  else already exact (em dash, en-dashes, `colour`, ellipsis-free copy).

## Verification tails

`dart format .` — clean (re-ran after every edit).

`flutter analyze` — `No issues found!` (full-app run, exit 0).

`flutter test` (full suite) — `00:10 +586: All tests passed!` (exit 0,
zero skips — `grep -c "skip:"` returns 0 in both family test files).
Every widget test that pumps the app ends with `disposeApp(tester)`.

VERDICT: PASS
