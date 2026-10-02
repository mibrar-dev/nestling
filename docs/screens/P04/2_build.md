# P04 · Privacy consent — build notes (STAGE 2, iteration 5)

Feature `privacy_consent` · route `/privacy` · parent mode.
Built per `docs/screens/P04/1_plan.md`, fixing every item in
`docs/screens/P04/FIXES_4.md`, and un-skipping the bug proofs the fixes
turn green. The shared batch (`7eaa1f7`, merged in `ce89889`) supplied
`ic_trash.svg` + `NestIcons.trash`, `NestPrivacyShield` and the shared
`NestList` overlay — all three P04 wire-ups below consume them.

## Files changed (all inside RULES §1)

Production (`app/lib/features/privacy_consent/**`):

- `presentation/views/privacy_consent_view.dart`
  - Row 4 now passes `leadingAsset: NestIcons.trash` (peach tile +
    `aPeach` ink = the design's red-ink glyph); the stale `TODO(P04)` is
    deleted (FIXES_4 finding 1 / P04-2).
  - The shield block is now `const Center(child: NestPrivacyShield(
    semanticLabel: 'A shield with a leaf and a heart, protecting your
    family'))` — token disc/body/heart, `image: true` with the same label,
    so the manual `Semantics`/`ExcludeSemantics` wrapper and the
    `flutter_svg` import are gone (finding 2 / P04-7).
  - The four rows are four direct `NestList` children again; the local
    `showDivider` flag, `Stack` wrapper and single-`Column` are deleted now
    that shared `NestList` paints the identical overlay (finding 3).
- No bloc/repository/domain changes needed this iteration.

Tests (`app/test/features/privacy_consent/**`):

- `p04_bugs_test.dart` — un-skipped `[P04-2]` and `[P04-7]` (both green);
  header index marks all nine `[FIXED]`. Zero skipped proofs remain.
- `privacy_consent_view_contract_test.dart`
  - Glyph group covers all four rows (trash + `aPeach` added; row-4 gap
    block flipped to `findsOneWidget` with asset/color checks); tint loop
    covers four glyphs in both themes.
  - Separator helpers now target the shared mechanism (overlay `Container`
    with `color != null` inside each row's `Stack`); row 1 asserts
    `dividerOf(0)` finds nothing (finding 4's result check, replacing the
    `find.byType(Stack)` mechanism pin).
  - Shield test asserts `NestPrivacyShield` size 84 + label instead of an
    `SvgPicture` descendant.

Docs (`docs/screens/P04/**`): new screenshots `ui/app_{light,dark}_5.png` +
`ui/cmp_{light,dark}_5.png`.

## What happened to each FIXES_4 item

- Finding 1 (MAJOR, row-4 tile) — FIXED: one-line wire-up now that the
  asset is in the tree; `[P04-2]` un-skipped and green; orchestrator item 1
  met (four glyphs proven asset + tint + painted SVG, light and dark).
- Finding 2 (MAJOR, dark shield) — FIXED: `NestPrivacyShield` renders the
  token disc/body/heart; dark band 2 drops 9.14% → 1.94%; `[P04-7]`
  un-skipped and green.
- Finding 3 (MINOR, local overlay duplication) — FIXED: local mechanism
  deleted; `[P04-4]` still green because it asserts the result (list ==
  row sum), and device probes stay Δ0 (list 288–509, opt card 532–616).
- Finding 4 (MINOR, mechanism assertion) — FIXED as described above.
- Finding 5 (MINOR, test-tail quote) — this note quotes the runner's real
  strings verbatim below.
- P04-9 (transactional upsert) — untouched and still green; no regression.
- Open items from earlier iterations: none remain in P04 scope. The two
  remaining shared records (`SHARED_REQUEST.md` §2 themed shield, §6 list
  dividers) are now consumed-by-P04 history; §4's P16 half was never P04's
  to fix.

## Analyze tail (app/)

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent test/features/privacy_consent
→ 17 files, 0 changed (final re-run; one intermediate run reformatted 2 files)
flutter analyze → No issues found!
```

## Test tail (app/, `flutter test`)

P04 scope: `00:07 +120: All tests passed!` — 120 passed, 0 skipped,
0 failed, including the newly un-skipped `[P04-2]` and `[P04-7]`.
Whole app: `00:29 +673: All tests passed!` — 673 passed, 0 skipped,
0 failed.

## UI check (iteration 5)

`shot.sh /privacy` light + dark (`SEED=fresh`, parent, iPhone 16e) +
`compare.py` vs the design PNGs:

- Light mean diff **4.08%** (was 4.10%) — bands: 0: 1.57% · 1: 6.02% ·
  2: 1.98% · 3: 7.94% · 4: 5.62% · 5: 4.19% · 6: 0.40% · 7: 4.84%
- Dark mean diff **3.96%** (was 5.15%) — bands: 0: 1.55% · 1: 6.29% ·
  2: 1.94% · 3: 7.87% · 4: 5.57% · 5: 4.44% · 6: 0.39% · 7: 3.55%

Row 4 shows the rust trash glyph in both themes; the dark shield disc is
navy. Remaining drift is simulator font raster (~1 px doubling on H1/row
titles, bands 1/3) plus the ignored status-bar clock; header/list/CTA
positions are Δ0, gutters share 20 px, and the CTA surface reaches the
physical edge in both themes (the strip difference vs the PNG is the
intended OWNER-rule behaviour).

VERDICT: PASS
