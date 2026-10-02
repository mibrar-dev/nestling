# P04 · Privacy consent — build notes (STAGE 2, iteration 6)

Feature `privacy_consent` · route `/privacy` · parent mode.
Built per `docs/screens/P04/1_plan.md` and `docs/screens/P04/FIXES_5.md`.
Situation on entry: iteration 5's build had already landed every FIXES_5
wire-up (the file describes the iteration-4 tree — its timing note says the
batch merged after that build was written, but the current worktree contains
the completed work, verified line by line below). This iteration's code
change is the one remaining open item; the rest is verification after the
`53c14a4` main merge, plus re-shoot.

## Files changed (all inside RULES §1)

- `app/test/features/privacy_consent/privacy_consent_view_test.dart` —
  replaced the stale header comment (FIXES_5 finding 1 of the iteration-5
  review cycle / FIXES_4 finding 3 lineage): it claimed row 4 reserves its
  tile behind `TODO(P04)` with no asserted glyph. Row 4 has rendered
  `NestIcons.trash` since iteration 5, pinned by
  `privacy_consent_artwork_test.dart` in both themes.
- `docs/screens/P04/SHARED_REQUEST.md` — marked items 1 (trash), 2 (dark
  shield) and 6 (list dividers) consumed/resolved for P04 (all landed on
  main and are wired in).
- `docs/screens/P04/ui/app_{light,dark}_6.png` +
  `ui/cmp_{light,dark}_6.png` — new screenshots + compares.

## What happened to each FIXES_5 item (all verified present, not re-done)

- Finding 1 (MAJOR, P04-2 wire-up) — already in the tree and verified:
  `leadingAsset: NestIcons.trash` on row 4, no `TODO(P04)` in the view,
  contract test asserts all four asset names + inks + painted SVGs,
  `[P04-2]` un-skipped and green, tint loop covers four rows both themes.
- Finding 2 (MAJOR, P04-7 wire-up) — already in the tree and verified:
  `const Center(child: NestPrivacyShield(semanticLabel: …))`, no
  `SvgPicture`/`flutter_svg` left in the view, contract shield test
  asserts size 84 + label, `[P04-7]` un-skipped and green.
- Cleanup finding 3 (revert to four direct children) — verified: no
  `showDivider`/`Stack`/single-`Column` in the view; `NestList` owns the
  overlay separators.
- Cleanup finding 4 (`dividerOf(0)` result check) — verified in place at
  two sites; no `find.byType(Stack)` mechanism assertion remains.
- Cleanup finding 5 (test-tail quote) — this note quotes the runner's real
  strings verbatim below.
- Un-skips — nothing left skipped: `grep "skip: true"` over the P04 tests
  returns nothing; the full suite runs with 0 skips.

## Analyze tail (app/)

```
dart format lib/features/privacy_consent test/features/privacy_consent
→ 18 files, 0 changed
flutter analyze → No issues found!
```

## Test tail (app/, `flutter test`)

P04 scope: `00:06 +131: All tests passed!` — 131 passed, 0 skipped,
0 failed.
Whole app: `00:24 +776: All tests passed!` — 776 passed, 0 skipped,
0 failed.

## UI check (iteration 6)

`shot.sh /privacy` light + dark (`SEED=fresh`, parent, iPhone 16e) +
`compare.py` vs the design PNGs:

- Light mean diff **4.08%** (unchanged) — bands: 0: 1.56% · 1: 6.02% ·
  2: 1.98% · 3: 7.94% · 4: 5.62% · 5: 4.19% · 6: 0.40% · 7: 4.84%
- Dark mean diff **3.97%** (was 3.96%) — bands: 0: 1.54% · 1: 6.29% ·
  2: 1.94% · 3: 7.87% · 4: 5.57% · 5: 4.44% · 6: 0.39% · 7: 3.67%

Read from the Review pane: row 4 shows the rust trash glyph in both
themes; the dark shield disc is navy. Remaining drift is simulator font
raster (~1 px doubling on H1/row titles, bands 1/3) plus the ignored
status-bar clock; header/list/CTA positions are Δ0, gutters share 20 px,
and the CTA surface reaches the physical edge in both themes (the strip
difference vs the PNG is the intended OWNER-rule behaviour).

VERDICT: PASS
