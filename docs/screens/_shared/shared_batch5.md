Shared batch 5 (from P09's SHARED_REQUEST, read-only: ../nestling-screens/P09/docs/screens/P09/SHARED_REQUEST.md §2, §4, §5, §6; and 5_ui.md).

1. ICONS (§4, BLOCKER). The P09 icon picker needs the design's exact glyphs for bed, dishes (handled basket), hoover (canister vacuum + hose + wheels) and bins (handled case/clasp). §4 contains the exact SVGs copied from design/html-source/screens/P09-quest-editor.html.
   - Add them to app/assets/icons and NestIcons under unambiguous names. Do NOT silently change existing icons other screens use: check every NestIcons.bed / basket / dishwasher / hoover / bin usage in app/lib/features and the design PNGs of those screens.
   - If the existing glyph matches another screen's design, keep it and add a new name, e.g. `questBed`. Report the mapping P09 must use.
   - Test: each new icon loads and renders with the theme colour.
2. NestToggle (§2): make the 51×31 track the widget's laid-out box, so it aligns by normal layout. The 59×44 hit area overhangs it (padding/overflow hit test, like NestChip's hit slop) and does not shift the track.
   - Tests: the track's laid-out rect is 51×31, a tap 4 px outside the track still toggles, and the semantics have the toggle action.
   - List the screens currently compensating, e.g. P09's `toggleTrackOffset`, so they can remove the offset. Do NOT edit feature code.
3. NestStepper minus (§5): draw U+2212 "−" (or the same icon family as "+") so − and + have equal weight. Test that the glyph is not U+002D.
4. NestTextField default variant (§6): the text's horizontal inset must equal the design's: field x + 1 px border + 16 px padding, so the text starts 17 px from the field's left edge. The app is 3 px further in. Fix the default contentPadding.
   - Re-check every merged screen's geometry tests that use NestTextField (P03 email/password, P05 nickname, P10 search; search was already fixed) against their design PNGs.
   - If a merged test pinned the old inset, update it only if the new value equals the design. List each in the report.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/shared_batch5_REPORT.md (per item: files, tests, the icon names P09 must use, the screens to update), committed.
