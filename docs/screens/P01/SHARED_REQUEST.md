# Shared request — P01 Welcome (Stage 6, iteration 3)

Supersedes the stale request about `router_redirect_test.dart` (that test
passes — route-location based since `2f723db`).

**All blocking shared defects are now closed on main, verified here with
enforced proofs** in `app/test/features/onboarding/p01_bugs_test.dart`:

- BUG-2 bottom inset counted twice — fixed `763192d`.
- BUG-3 kid-mode gate skipped the onboarding flow — fixed `71d2400`,
  completed for `/today-empty` / `/quest-editor` by `ded8eb9`.
- BUG-4 fresh install never created the `app_state` row — fixed `045d190`
  (`MigrationStrategy.beforeOpen` insert-if-missing); persistence and
  end-to-end restart proofs pass.
- BUG-1 / BUG-5 (P01-owned) — fixed in `welcome_view.dart`.

**No blockers remain.** Two non-blocking shared items, for a future polish
pass (both already recorded by the review):

1. **Bundle Inter + Nunito and warm the first-frame SVGs.** Fonts load from
   the Google-Fonts CDN at first paint (`no fonts:` block in `pubspec.yaml`,
   no `allowRuntimeFetching = false` in `lib/main.dart`), which is also the
   only remaining cause of the `shot.sh` "frame never stabilised" warning.
   Nothing calls `NestlingImages.precache` and it lists the webp rasters while
   screens render the SVG paths — warm P01's first-frame SVGs from the app
   shell with `precachePicture` instead.
2. **Inset-0 bottom band (low priority).** With `NestHomeIndicator` a no-op
   and no OS bottom inset, `NestBottomCta`'s panel is flush with the screen
   edge instead of ending 34dp above it, unlike the design. Exact on
   home-indicator devices (the reference); optional shared floor:
   `max(viewPadding.bottom, NestDevice.homeH)` in `nest_bottom_cta.dart`,
   symmetric with `NestStatusBar`'s top-reserve.

**Files:** `app/pubspec.yaml` + `lib/main.dart` + the app shell (1) ·
`app/lib/core/design_system/components/nest_bottom_cta.dart` (2).

**Blocks:** **no** — nothing P01-owned is waiting on either item; the screen
is complete, tested and visually verified.
