# UI polish report — shared/polish_ui (BACKLOG)

Scope: three shared fixes only (P12-BUG-04 segmented, Money tab icon, splash
blank beat) + 390 px no-move proof for P08/P12/P16. Minimal,
backward-compatible, no screen code touched (`app/lib/features/**/presentation/**`
untouched), no settings/auth/paywall/privacy/database changes. Branch
`shared/polish_ui` from main.

## Files changed

- `app/lib/core/design_system/components/nest_segmented.dart` — narrow-width
  scrollable track (P12-BUG-04). `StatefulWidget` + `LayoutBuilder` +
  `ScrollController`: fits → old `Expanded` row byte-for-byte (390 dp
  unchanged); narrow (`viewport < n*44 + gaps`) → `SingleChildScrollView`
  horizontal with fixed 44×44 segments, minimal horizontal-only `jumpTo` to
  reveal the selected segment (never touches vertical scrollers). Shared
  `_optionSemantics`/`_expandedChildren`/`_scrollableChildren` keep thumb,
  shadow/border, text style, semantics (button/selected/enabled/label/
  `excludeSemantics`+`onTap`) identical in both branches.
- `app/assets/icons/ic_money.svg` — wallet/card glyph (exact design path:
  `rect x=3 y=6 w=18 h=13 rx=3` + `M3 10h18` + `M7 15h4`), replacing the
  banknote (centre disc + medallions). Both themes via `currentColor` tint.
- `app/lib/core/design_system/assets/nestling_assets.dart` — `money` doc
  comment updated to wallet/card with exact path (no API change).
- `app/lib/app/launch_splash.dart` — blank-beat fix: both stages preload
  from first frame in a `Stack` (egg opaque below, hatchling
  `AnimatedOpacity` on top, `hatchFade` 200 ms at `evolve`), egg stays until
  hatchling opaque so green never shows. New `LaunchSplashTimings.hatchFade`.
  Total 1600 ms, hard timeout, skip, Reduce Motion single-still unchanged.
  Header + build comments updated.
- Tests (shared + un-skipped proof):
  - `app/test/features/pocket_money/p12_bugs_test.dart` — P12-BUG-04
    un-skipped; asserts 6×44×44 `InkWell` layout + semantic tap + horizontal
    drag to Ethan + no overflow (semantics rect not used off-screen: a
    scrollable clips it to the viewport by design).
  - NEW `app/test/core/design_system/nest_segmented_narrow_test.dart`
  - NEW `app/test/core/design_system/money_tab_icon_test.dart`
  - `app/test/app/launch_splash_test.dart` — new `hatch preload` group.
- Screenshots (simulator 604697A9-11DA-462F-9837-396E9CA2493A only,
  SEED=demo, parent/maya): `docs/screens/{P08,P12,P16}/ui/*_polish.png`
  (app + cmp, light+dark; last accepted `*_4/*_3/*_6` untouched).
- Brand (same simulator, SEED=demo): `docs/brand/splash_hatch.mp4` (5.76 s
  cold start, trimmed 34–40 s raw), `docs/brand/splash_reduce_motion.mp4`
  (2.11 s, app flag `DISABLE_ANIMATIONS=1` — `simctl ui` has no
  reduce-motion switch), `docs/brand/splash_frames.png` (1170×506 5-frame
  strip: launch/egg/hatchling/Today×2, times 0.0/0.4/0.8/2.0/4.0 s).

## What / why

1. P12-BUG-04: 6 options at 320 dp need 292 px track but P12 gives 280
   (20 px gutters) → 42 px each <44. Scrollable 44 px segments fix it with
   zero change at 390 (350 track, 342 viewport ≥284 needed → Expanded).
   Manual `jumpTo` (not `ensureVisible`) avoids vertical-list interference
   (which clipped semantics to 32 px tall in tests).
2. Money icon: parent designs all draw wallet/card; app drew banknote.
   Exact design path now, tinted leaf/ink3 in `NestTabBar` both themes.
   P08 band-7 diff drops ~2.3–2.6% (tab bar now matches).
3. Splash: single-`PipAvatar` Stage1→Stage2 swap had to load/decode Stage2
   after the swap → 0.2–0.4 s green. Stacked preload during the 450 ms
   `evolveDelay` + egg-opaque-underneath cross-fade removes it by
   construction. Rive video: yellow egg/hatchling continuous 0.2–1.0 s, no
   green blank between burst and hatchling (one green frame before Today is
   the intentional 200 ms router fade, not the reported swap blank).
   `evolveDelay(450)+hatchFade(200)=650 ms < fadeStart(1400 ms)`.

## Test names added

`nest_segmented_narrow_test.dart` → `NestSegmented narrow`:

- `at 390dp six options fit with no scrollable`
- `at 320dp every segment keeps a 44x44 button`
- `narrow track scrolls and taps the last option`
- `narrow options expose tap semantics`

`money_tab_icon_test.dart` → `Money tab icon`:

- `NestIcons.money points at the tab-bar wallet asset`
- `ic_money.svg draws the exact design wallet path`
- `the tab bar renders the wallet glyph in both themes`

`launch_splash_test.dart` → `hatch preload`:

- `preloads the hatchling under the egg from the first frame`
- `animated path stacks, reduce path stays a single still` (split: animated
  `findsNWidgets(2)`, reduce `findsOneWidget` + only-stage-2 SVG)
- `the hatch completes well before the router fade`

Un-skipped: `P12-BUG-04: six children at 320dp…` (now asserts layout +
taps + drag, see above).

## 390 px no-move proof (same simulator, SEED=demo)

| Screen | Route | Last accepted mean (5_ui) | Polish mean | Δ |
|---|---|---|---|---|
| P08 light | /today | 5.03% (cmp_light_4) | 3.91% (cmp_light_polish) | −1.12 (wallet match, band 7 5.49→3.21) |
| P08 dark | /today | 4.83% (cmp_dark_4) | 3.64% (cmp_dark_polish) | −1.19 (band 7 5.27→2.67) |
| P12 light | /money | 1.92% (cmp_light_3) | 1.93% (cmp_light_polish) | +0.01 (bands ≤0.11) |
| P12 dark | /money | 1.90% (cmp_dark_3) | 1.84% (cmp_dark_polish) | −0.06 |
| P16 light | /settings | 0.94% (cmp_light_6) | 0.95% (cmp_light_polish) | +0.01 |
| P16 dark | /settings | 0.94% (cmp_dark_6) | 0.86% (cmp_dark_polish) | −0.08 |

P12 anchors (widget geometry tests, all pass): title/segmented/hero/goal/
history tops within ±1 px at 390; segmented track 52 high, buttons 44 high;
2-option roster still `Expanded` (no scroll). P08/P12/P16 shots all `stable
frame saved` (no stabilisation warning). Lower P08 mean = closer to design
(wallet), not a move: card/hero/gutter geometry unchanged per band tables
(bands 1–6 ≤0.5 except data-driven rows). No screen at 390 moves.

Reduce Motion recording: app flag `DISABLE_ANIMATIONS=1` (NOT `simctl`
accessibility — `xcrun simctl ui` offers only appearance/increase_contrast/
content_size, no reduce-motion switch; identical code path via
`kDisableAnimations`, same as prior `splash_REPORT.md`).

## Results

- `cd app && dart format .` clean (0 changed), `flutter analyze` →
  `No issues found!`
- `flutter test --timeout 120s` foreground: `All tests passed!`
  (5252 passed, ~15 skipped, 0 failed; P12-BUG-04 un-skipped and passing).
- Screen suites re-run: `pocket_money/`, `quests/`, `inputs/overflow/
  shared_batch4/semantics_actions` → all pass.

## Follow-ups for screen agents

- Nothing required to merge. `NestSegmented` API unchanged (same
  `const new(...)`); 2–3 option rosters (P10, quest editor, P12 default)
  still take the identical `Expanded` branch — no action.
- P08/P16 5_ui notes already list the Money wallet mismatch as shared; now
  fixed — no screen edits needed, screenshots prove closer match.
- If a test pumps bare `NestlingApp()` and counts `PipAvatar`/`SvgPicture`,
  note the animated splash now preloads 2 avatars (egg+hatchling) from the
  first frame; reduce path still 1. Assert router `currentPath`, never
  placeholder text.
- Do not edit `ic_money.svg` paths (exact design copy) or
  `LaunchSplashTimings` (hard ceiling 1600 ms).

VERDICT: PASS
