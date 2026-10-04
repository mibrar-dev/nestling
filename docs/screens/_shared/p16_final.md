ROLE: Senior Flutter engineer (sub-agent). Working dir = the P16 worktree (branch screen/P16). Read docs/screens/P16/4_review.md findings 1–3 and 6 first.
FIX (P16 feature code only: app/lib/features/settings/** and app/test/features/settings/**):
1. MAJOR: `_MoveBanner` (settings_view.dart ~478, ~494) hard-codes "London". Pass the CURRENT FAMILY zone and use its short label: "History keeps {familyShort} times; future days follow {deviceShort}." Test with family Asia/Dubai + device Europe/London, and with family Dubai + device Asia/Karachi. The sentence must name the right zones.
2. minor: the `.lockhint` lock glyph colour token must match the CSS (finding 2).
3. minor: the `›` chevron uses the design's Inter style/token per the CSS, not a display-heading token (finding 3).
4. minor: the two static Family rows each get their own semantics node (finding 6).
Do NOT touch anything else; the layout already matches the design.
GATES: `cd app && dart format . && flutter analyze` must print "No issues found!", and `flutter test --timeout 120s` must be fully green. Commit "P16: final fixes (move banner zones, lockhint, chevron, row semantics)", ending with "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>".
Write docs/screens/P16/FINAL_REPORT.md, ending with `VERDICT: PASS` or `VERDICT: FAIL`.
NEVER: flutter clean, simulator, edit app/lib/core/**.
