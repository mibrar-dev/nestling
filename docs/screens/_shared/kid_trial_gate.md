Router: fix the kid-mode + expired-trial redirect LOOP, and the 8 merged kid tests that assert P17's placeholder title.

READ (read-only): ../nestling-screens/P17/docs/screens/P17/SHARED_REQUEST.md (the two sections on the K03/K01 placeholder reds and the redirect loop), and ../nestling-screens/P17/app/test/features/parental_gate/p17_bugs_test.dart P17-BUG-1 (the repro).

1. LOOP (major): with AppSession.trialExpired in kid mode, router.dart sends everything to /paywall; /paywall is parent-only in kid mode, so it goes to /parental-gate; the gate hits the trial branch again and gets sent to /paywall. GoException "redirect loop", and go_router shows its error page. Kid mode is dead after the trial ends.
   ORCHESTRATOR DECISION:
   - In KID mode with an expired trial, every location redirects to /parental-gate, and the gate is EXEMPT from the trial branch (like the onboarding branch already exempts it). Kids never see the paywall.
   - Once the gate is passed (parent mode), the existing trial branch sends the parent to /paywall.
   - Parent mode is unchanged.
   Tests (router tests with currentPath/pushedPath):
   - Kid mode + expired: /kid-home → /parental-gate, no loop, no error page.
   - Passing the gate → /paywall.
   - Kid mode + active trial: unchanged.
   - Parent mode + expired → /paywall (unchanged).
2. MERGED TEST FIXES (you MAY edit app/test/features/kid_home/** for this item only):
   - k03_bugs_test.dart:1059,1531 and kid_home_view_test.dart:1247,1263,1279,1294,1993 assert `find.text('P17 Parental gate')`, a placeholder that P17 replaces. Assert the route instead: `pushedPath(tester) == '/parental-gate'` (or currentPath), as the shared rule says.
   - k01_bugs_test.dart ~697 'rapid lock double tap pushes exactly one gate' uses `tester.pageBack()`, which needs an AppBar back button the gate design does not have. Exit through the gate's own "Back to Pip" instead (tap it), then assert pushedPath == '/who-is-playing'.
   - These must pass against main now AND against the real P17 gate. Use only route/semantics assertions; never assert placeholder text.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/kid_trial_gate_REPORT.md, committed.
