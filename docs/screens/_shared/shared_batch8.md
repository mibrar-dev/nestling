Shared batch 8.

1. PLACEHOLDER-TITLE ASSERTIONS, ALL AT ONCE (you MAY edit any app/test/** file for this item).
   Merged tests still assert foundation placeholder titles such as `find.text('K08 Reward shop')`, `'K06 Pip'`, `'P0x …'`. Every time the real screen lands, they break: this has happened 5+ times.
   Find them all: grep app/test for find.text('K0…/P0… placeholder copy (≈28 hits: kid_home_view_test.dart 16, k03_bugs_test.dart 9, router_push_test.dart 1, paywall tests 2).
   Replace each with a ROUTE assertion: `pushedPath(tester)` / `currentPath(tester)` == the route, the idiom already used in these files. Keep each test's intent. Run the whole suite green.
   Add a guard test (e.g. app/test/meta/no_placeholder_titles_test.dart) that scans app/test/**.dart and fails if any `find.text('<Kxx|Pxx> …` placeholder pattern appears.
2. NestKidButton muted colourway (read-only: ../nestling-screens/K08/docs/screens/K08/SHARED_REQUEST.md first section).
   `.k8-get.off { background: surface-2; color: ink-2 }` at FULL opacity, same 3 px ink border, sh-kid shadow and 17 px w900 label.
   Add `NestKidButtonColor.muted` that renders at full opacity and keeps disabled semantics when onPressed is null.
   Tests: the colours, opacity 1.0, and semantics isEnabled false.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test --timeout 120s green, docs/screens/_shared/shared_batch8_REPORT.md, committed.
