Shared batch 4 (from P10's SHARED_REQUEST). READ FIRST (read-only): ../nestling-screens/P10/docs/screens/P10/SHARED_REQUEST.md and 6_bugs.md. They contain measured numbers and proofs (BUG-P10-5/6/7).

1. NestTextField search prefix (§1). Design `.search`: flex, gap 10, padding 4px 16px, min-height 52, 24 px icon at field x+16, hint at x+50.
   - Add a supported way to get that geometry: pass-through `prefixIconConstraints`, or a `NestTextField.search` / `leading` option, whichever is simpler and token-based.
   - Existing NestTextField uses must not change.
   - Test with real fonts: icon at x+16 ±1, 24×24; hint at x+50 ±1; field height 52 ±1.
2. NestSegmented (§2). Design: track 52 (padding 4) with 44 px buttons; the selected pill keeps r-pill + sh-1. Today the component is 44/36.
   - Change it to 52/44, matching `.segmented`.
   - grep every usage in app/lib/features. Merged screens must still match their designs: if a merged screen's geometry test breaks, compare against its design PNG and update the test ONLY if the new size is the design's. List each in the report.
3. NestTabBar / ParentShell (§3). Design bar: 84 px content block (icon centre 748, label centre ≈ 772, bar top 726 at 390×844 with a 34 px home inset). The owner rule says the bar's SURFACE runs to the physical bottom edge.
   - Content keeps the design position; the surface extends under the home inset. The app currently puts the content in the bottom 84 px (icon 783).
   - Handle real device insets: test with 47/34 and 0/0.
   - CHECK P08 (Today, merged, uses ParentShell): compare against design/screens/light/P08-*.png that the P08 tab bar content lands at the design position after the change. Run its tests.
   - Test: with bottom inset 34 at 390×844, icon centre 748 ±1 and label centre 772 ±2, and the surface colour fills down to y 844.
4. Test hygiene (§4): move the two today_view_test.dart assertions (~286-289, ~335) to `pushedPath(tester)` / currentPath. You MAY edit app/test/features/today/** and app/lib/features/quests/presentation/views/quest_library_view.dart to delete the hidden `Text('P10 Quest library')` anchor and its Stack wrapper.
5. Quest order (§5, orchestrator decision): the Active list is ordered by quest CREATION order (oldest first), matching the owner rule "listed in the order they were added", not by title.
   - Change `AppDatabase.watchActiveQuests` to order by created_at, then id.
   - If quests have no created_at, add it via a schema v4 migration (backfill in seed order; mirror docs/research/DATETIME_STORAGE.md: UTC + `created_tz`), with a migration test.
   - Update quests_repository_test.dart, and any merged screen test that relied on title order: check P08's quest list against its design.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/shared_batch4_REPORT.md (per item: files, tests, merged screens affected), committed.
