# Shared request — P07 trial expiry + kid-mode guard order

Need: two P07 bug-hunt findings live in shared code that screen agents may
not touch, with skipped proof tests in
`app/test/features/paywall/p07_bugs_test.dart` (`[P07-BUG-8]`, `[P07-BUG-9]`).

1. P07-BUG-8 (major): the 14-day trial never expires. Nothing in `app/lib`
   ever writes `subscription_status = 'expired'`, so the router guard
   (`app/lib/app/router.dart`, onboarded + `trialExpired` → `/paywall`) is
   dead code and the paywall never returns. Suggested fix from the bug hunt:
   compute `trialExpired` from `trialStart + 14 calendar days` in the family
   zone using `core/data/london_time.dart` (a UTC `+ Duration(days: 14)` is
   wrong across the October BST→GMT change), or persist `'expired'` at
   launch. Owner files: `app/lib/core/data/app_session.dart` (and
   `app/lib/app/launch.dart` if expiry is persisted there).
2. P07-BUG-9 (minor): for a kid-mode app that is not yet onboarded, a deep
   link to `/paywall` ends on `/welcome` instead of the parental gate:
   `/paywall` redirects to the gate, the gate is re-evaluated by the
   onboarding rule back to `/welcome`, and `/welcome` is itself parent-only.
   Suggested fix: evaluate the kid-mode branch before the onboarding branch
   in `app/lib/app/router.dart`, or exempt the gate path from the onboarding
   redirect. Low reachability (`APP_MODE=kid` during onboarding), hence
   minor.

Files: `app/lib/core/data/app_session.dart`, `app/lib/app/launch.dart`,
`app/lib/app/router.dart`
Blocks: partially — the P07 screen, its trial/restore handoff and the full
`flutter test` suite land without this (the two proofs stay `skip: true`
until the shared fix lands, and skips keep the suite green). The expired-trial
redirect itself cannot work until item 1 lands.
