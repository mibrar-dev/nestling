Shared batch 3: trial expiry, router guard order, balanced headings, paywall co-parent name.
Read docs/screens/P07/SHARED_REQUEST.md and docs/screens/P07/6_bugs.md first. P07 is merged on main.

1. TRIAL EXPIRY (P07-BUG-8, major) — SHARED_REQUEST §1.
   - Nothing writes `subscription_status = 'expired'`, so the router's trialExpired → /paywall redirect never fires.
   - Implement expiry at launch/resume (core/data/app_session.dart + app/launch.dart). Trial length is ELAPSED time: 14 days from the `app_state.trialStart` UTC instant (see docs/research/DATETIME_STORAGE.md).
   - Never expire an active subscriber.
   - Use an injectable clock so tests can pin time.
   - Un-skip `[P07-BUG-8]` in app/test/features/paywall/p07_bugs_test.dart; it must pass.
2. ROUTER GUARD ORDER (P07-BUG-9, minor) — SHARED_REQUEST §2.
   - A kid-mode + onboarding-incomplete deep link to /paywall must end on /parental-gate, not /welcome.
   - Fix the guard order in app/lib/app/router.dart without breaking the other router tests.
   - Un-skip `[P07-BUG-9]`.
3. BALANCED HEADINGS (CSS `text-wrap: balance` on `.display` and other heading classes; check design/html-source/components.css for every class that sets it).
   - Add a shared `NestBalancedText` (core/design_system/components). It keeps the minimum line count but picks the narrowest width that still fits that many lines (TextPainter search), then centres or aligns the text as given.
   - P07 title must render "Try Nestling" / "free for 14 days" like the design. Today it renders "Try Nestling free for 14" / "days".
   - Use it in P07's title (you MAY edit app/lib/features/paywall/presentation for this item and item 4).
   - Tests:
     - The P07 title has two lines and the widths of its two lines differ by less than one word.
     - With the real Inter/Nunito fonts loaded via FontLoader (see app/test/features/privacy_consent/privacy_consent_geometry_test.dart), "Try Nestling free for 14 days" breaks after "Nestling".
   - In the report, list other features whose CSS headings use balance, so screens can adopt it.
4. PAYWALL CO-PARENT NAME (owner rule: the database is the source of truth, no mocks). `paywall_view.dart` hard-codes "Co-parent sharing, so James sees the same".
   - Read the family's co-parent (the second parent member) from the DB through the paywall bloc/repository.
   - If there is one: "Co-parent sharing, so <Name> sees the same".
   - If there is none: "Co-parent sharing, so everyone sees the same".
   - Tests: the demo seed shows the seeded co-parent's name; the fresh seed shows the fallback.
