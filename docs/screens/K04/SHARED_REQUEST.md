# Shared request — K04 quest detail

Need: Upstream the K04-BUG-1 fix in the shared component
`app/lib/core/design_system/components/nest_balanced_text.dart`.
`NestBalancedText.balancedWidthFor` probed line counts with the caller's
`maxLines` cap applied, so any heading whose natural layout exceeded the cap
(DB-driven titles like P09 quest names) collapsed the binary search to
~0.085 px and rendered the heading invisible. The screen-loop iteration
applied the fix locally because the bug proofs in
`app/test/features/kid_home/k04_bugs_test.dart` had to go green:
`balancedWidthFor` now probes with the natural line count (`maxLines: null`),
and `build` returns the full-width `Text` (with its own maxLines ellipsis)
whenever the natural line count exceeds the requested cap. No public API
changed, so other callers (P07 headings, K03) are unaffected unless they hit
the same cap overflow, where they now get a readable full-width heading
instead of an invisible one.
Files: `app/lib/core/design_system/components/nest_balanced_text.dart`
Blocks: no — the fix is applied and covered by
`app/test/features/kid_home/k04_bugs_test.dart` (un-skipped, passing); this
entry just records it for the orchestrator to merge upstream deliberately.
