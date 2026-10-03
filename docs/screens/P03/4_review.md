# P03 Create account — QA code review (Stage 4, iteration 6)

Scope reviewed: `git diff main...HEAD`, commit `520cd82` (iteration-6
integration) on `screen/P03`. Reference set: `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P03/§0.9,
`docs/design/SPACING_SPEC.md`, `design/html-source/screens/P03-create-account.html`,
`design/html-source/components.css:129-135`, `ORCHESTRATOR_NOTES.md`
(mandatory), the standing COPY / FONTS / LETTER SPACING / CHIP ROWS rules,
`1_plan.md`, `FIXES_1…4`, `2_build.md` (iter-6 INTEGRATE), `3_test.md` (iter-5),
`SHARED_REQUEST.md`.

Evidence gathered by this stage:

- `flutter analyze` → `No issues found!` (from `app/`, ran in 4.9s). (Running
  it from the repo root sweeps the design asset pack and errors — that is the
  `design/` folder, not shipped code, and is never CI's scope.)
- `flutter test test/features/auth` → **+147: All tests passed!**, 0 skipped,
  0 failed. Per the build note, the full suite is `+841` green.
- Copy bytes: the subtitle now ships U+2019 (`342 200 231` on disk), the legal
  sentence carries exactly one U+00A0 inside "Privacy Notice", and
  `copy_audit_test.dart` is green.
- Device geometry, measured from `ui/app_light_6.png` vs the design PNGs:
  - subtitle line 1 ink x 21–368 vs design 21–368; line 2 x 22–128 vs 22–128 —
    the §6 drift is gone and the break is exactly the design's;
  - helper ink 21–145 vs 21–145, note x 24–287 vs 24–288;
  - CTA hairline y=678 vs 677; submit button 694–745 in both; the two legal
    runs x 262–300 / 149–241 vs 258–297 / 150–240.
- Bottom edge (OWNER rule): both themes paint `tokens.surface` to y=844
  (`ui/app_dark_6.png` column scan is uniform `(31,28,46)` from 631 to 843;
  `ui/app_light_6.png` is uniform `(255,255,255)`).
- Shared changes verified landed and in scope: `nest_text_field.dart:120-175`
  now takes `errorText` with `errorBorder` forced and a gutter-aligned row
  pinned by `shared_batch1_test.dart`; `:208-216` now wraps that row in
  `Semantics(liveRegion: true, label: errorText, …)` (§8 landed);
  `typography.dart` has `letterSpacing: 0` by default and the device metrics
  confirm it. `git status` touches only `app/lib/features/auth/**`,
  `app/test/features/auth/**`, `docs/screens/P03/**` (plus loop metadata).

## Iteration-5 findings — all three addressed

| # | Iteration-5 finding | Status |
|---|---|---|
| 1 | BLOCKER — red suite (BUG-16) pending §5/§8 decision | **closed**: Decision B recorded in `SHARED_REQUEST.md` §5 — the shared row wins; §5 and §8 are both marked RESOLVED, no skip markers remain |
| 2 | MINOR — double-fire in the button/link overlap | **closed**: `_RenderHitTestExpand.hitTest` now suppresses the fallback whenever `entry.path` already contains a gesture target (`RenderPointerListener`/`RenderSemanticsGestureHandler`); BUG-18's gap/gap-replacement overhang taps are ungated and stay green, and BUG-22's overlap is guarded; proofs green |
| 3 | MINOR — stale §5/§8 wording | **closed**: §5 records the final disposition, §8 records the landed shape |

## Verified-as-correct changes this iteration

- **BUG-16/20/21 together resolved by the shared batch**: `create_account_view.dart:175`
  and `:200` now pass `errorText` to both fields, and the owned live-region rows are
  deleted. The announcement is preserved because the shared field's error row is now
  itself `Semantics(liveRegion: true, label: errorText, child: ExcludeSemantics(...))`.
  Danger border forced, border state correct in both themes (`errorBorder` while
  `errorText != null`, reset when cleared). All three proofs green.
- **BUG-22 (overlap double-fire)** — the gesture-target gate is the right
  implementation: the in-panel empty area claims nothing from a pointer listener
  (only the bar's opaque `DecoratedBox`), so overhang points still reach the
  fallback's children; the button's strip already sits on a gesture target, so it
  suppresses the fallback. I also checked the iteration-4 suggestion (`if (!hit …)`)
  and the build was right to reject it — `hit` is non-false over every in-panel
  point because the bar's own decoration claims them — so a `!hit` gate would have
  killed the overhang, not the overlap.
- **BUG-17** resolved shared-side: `ui/app_light_6.png` measures the subtitle ink at
  x 21–368 on line 1 and x 22–128 on line 2, matching the design exactly; no local
  override needed.
- **No-skip suite**: the feature suite runs 147/147 green and the files carry zero
  `skip:` markers; the only open items are owned shared requests (§6, §7).

## Checked and clean (no finding)

- **Architecture** — feature-first; `domain/` = abstract repository + entity folder only;
  bloc per screen; `registerAuth` owns the repository + factory bloc; cross-feature
  navigation via route-path constants; no use-case classes, no `utils` folder.
- **RULES §4 data contract** — password never persisted; owner row idempotent; `Seed.familyId`
  respected; legacy `name:` alias only for the one shared caller.
- **RULES §1** — only allowed paths touched.
- **Design-system usage** — all DS components and tokens; caption line-height is
  `NestSpacing.s5 / 13` with §7 documented as the remaining 13/20 token request;
  no `GoogleFonts` left anywhere; letter-spacing inherits `NestType`'s zero-tracking
  default; no hard-coded colours, radii or text sizes remain in the view.
- **A11y** — headline is the only `header:`; glyphs, shield and the `or` row excluded;
  the brand labels announce once each (shared doubled-label bugs 2/4 landed in
  `7eaa1f7` and proofs green); error rows live-region-announce their exact message;
  all interactive boxes ≥44dp at every tested size/scale.
- **Performance / rebuilds** — fields rebuild only on `errorText` change, brand buttons
  only on `isSubmitting`, the CTA only on `canSubmit`/`isSubmitting`; a keystroke
  cannot rebuild the static rows; controllers disposed; no timers or polling; the
  verify chain is bounded (12) and re-armed only per dependency change.
- **Error handling** — both submit handlers `on Object catch` + `addError`, so any
  non-`Exception` surfaces a `formError` and never strands a spinner; failure is
  announced.
- **Children's Code / privacy** — parent mode; no analytics, ads, child data,
  photo/location capture; the copy states the privacy position.

## Remaining

None open on this screen. `SHARED_REQUEST.md` §6 and §7 are both non-blocking,
owned shared items (fonts bundled; 13/20 legal-caption token pending). The
`ORCHESTRATOR_NOTES` filled-state simulator capture remains UI-stage work.

VERDICT: PASS