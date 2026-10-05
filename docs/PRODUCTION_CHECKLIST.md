# Nestling — Production Checklist (app readiness)

**Date:** 5 Oct 2026 · **Scope:** what stands between the current app
(all 30 screens built, local-only Drift backend, launch icons + animated
splash done) and a public App Store + Google Play release in the UK.
**Companion doc:** [`SETUP_CHECKLIST.md`](./SETUP_CHECKLIST.md) covers owner
accounts, legal identity, keys and vendor setup — this doc links to it for
those items and does not repeat them. Tech decisions live in
[`TECH_STACK.md`](./TECH_STACK.md); store copy in
[`business/MARKETING.md`](./business/MARKETING.md);
pricing in [`business/PRICING.md`](./business/PRICING.md).

**How to read:** every item has a status
✅ done / ⚠️ partial / ❌ missing / 👤 owner action,
one line of evidence (`file:line` or command output), and the concrete next
step. UK English throughout.

---

## 1. Release build & signing

| Item | Status | Evidence | Next step |
|---|---|---|---|
| Version (versionName / versionCode, CFBundleShortVersion / Build) | ⚠️ | `app/pubspec.yaml:26` is template default `1.0.0+1`; `Info.plist` correctly wires `$(FLUTTER_BUILD_NAME/NUMBER)` | Bump to release version (e.g. `1.0.0+1` → real `1.0.0+N` per submission) and tag; drive from CI `--build-name/--build-number` |
| Android applicationId | ✅ | `app/android/app/build.gradle.kts:20` = `uk.co.getnestling.app`, matches SETUP_CHECKLIST Phase 1/2 | None (keep identical to iOS bundle id) |
| Android release signing | ❌ | `app/android/app/build.gradle.kts:33-37` signs release with **debug** keys ("Signing with the debug keys for now") | 👤 Owner generates upload keystore; wire `key.properties` + GitHub secrets, switch `signingConfig` to release, verify with `flutter build appbundle --release` on CI |
| iOS signing (team / profiles) | 👤 | `project.pbxproj:486,499` bundle id `uk.co.getnestling.app`, `CODE_SIGN_STYLE = Automatic`, no Team ID in repo (correct) | Owner: Team ID + App Store profile via `fastlane match` per SETUP_CHECKLIST Phase 1; CI holds `MATCH_PASSWORD` |
| Flavours / env (dev/stg/prod) | ❌ | No flavours, no `.env*`, no `.env.example` (`find . -name ".env*"` empty); only compile-time `--dart-define` launch flags (`app/lib/app/launch_flags.dart:15-29`) | Add 3 flavours or `--dart-define` env (API URLs, RevenueCat keys, Sentry DSN) per TECH_STACK §1; commit only `.env.example` with empty values |
| Minify / obfuscation + split-debug-info | ❌ | No `minify/shrink/proguard/R8/obfuscate/split-debug` in `app/android/`, `tools/`, or `docs/` (grep empty) | Add `--obfuscate --split-debug-info=<dir>` to release CI; upload symbols to Sentry; keep a mapping file per release |
| Android targetSdk 36 (Play rule, 31 Aug 2026) | ✅ | `build.gradle.kts:23` uses `flutter.targetSdkVersion`; Flutter 3.47.5 pins `targetSdkVersion = '36'` (`gradle_utils.dart:65`), `compileSdk 36` | Confirm on the built AAB (`aapt dump badging`) before submission; re-check after every Flutter upgrade |
| iOS deployment target | ✅ | `project.pbxproj:462,593,645` = `15.0` for all Runner configs | None (above Apple minimum); optionally uncomment/pin `platform :ios, '15.0'` in `Podfile:2` |
| `flutter build appbundle --release` | ⚠️ | **Not run in this pass** (release signing is debug keys; binary would build but is not shippable) | Run on CI after keystore wiring; record size + `bundletool`-reported download sizes |
| `flutter build ipa` (`--no-codesign` dry run) | ⚠️ | **Not run in this pass** | Run `flutter build ipa --no-codesign` on CI (or full signed build with match); record size |
| App size | ❌ | No release binary measured | Record AAB/IPA + install/download sizes; set a budget (e.g. < 60 MB download) and track per release |

---

## 2. Developer-only surfaces

| Item | Status | Evidence | Next step |
|---|---|---|---|
| Design-system gallery / motion lab / pip lab excluded from release | ❌ | Routes always registered (`app/lib/app/router.dart:172`); default initial location is the **gallery** when no `INITIAL_ROUTE` is passed (`router.dart:73-79`) | Gate gallery + motion-lab + pip-lab behind `kReleaseMode` (release: unreachable + removed from route list) or strip from release routes |
| `SEED` reseed path | ✅ | Only runs when `LaunchFlags.hasSeed` (`app/lib/app/launch.dart:27`); empty by default | None (inert without `--dart-define`) |
| `INITIAL_ROUTE` / `APP_MODE` / `THEME` / `CHILD` | ✅ | `String.fromEnvironment`, empty by default (`launch_flags.dart:16-20`) | None; release builds pass no dart-defines |
| `DISABLE_ANIMATIONS` / `SKIP_SPLASH` | ✅ | Empty by default; `skipSplash` getter only true with explicit flag or forced route (`launch_flags.dart:27-35`) | None |
| `MOTION_AUTOPLAY` / `PIP_LAB_AUTOPLAY` | ✅ | Empty by default; only redirect to labs when non-empty (`router.dart:70-79`) | None (dies with the §1 lab-route gate) |
| Debug banners | ✅ | `debugShowCheckedModeBanner: false` (`app/lib/app/app.dart:90`) | None |
| `debugPrint` / logging of personal data | ⚠️ | `pip_rive.dart:293,302` inside `assert` (debug-only, fine); `family_bloc.dart:132,155` guarded by `kDebugMode` ✅; but `child_display.dart:18` and `family_bloc.dart:108` call unguarded `debugPrint`, `quests_bloc.dart:125` calls unguarded `log()` | Wrap the three unguarded calls in `kDebugMode`; keep messages error-only (never nicknames, emails, PINs) |

---

## 3. Data & backend (local-only Drift today)

Works offline today (✅): all 30 screens read/write the on-device SQLite
database (`AppDatabase.open()` → `nestling.db`), reactive `watch…()` streams,
six seed variants (`Seed.demo/empty/fresh/newFamily/onboardingKids/kidAllDone`,
`app/lib/core/data/seed.dart:3`), family-zone time math (Europe/London),
trial-expiry enforcement at launch/resume. No network calls exist in `lib/`.

| Item | Status | Evidence | Next step |
|---|---|---|---|
| Accounts / sign-in | ❌ (by design, pre-backend) | `auth_repository_impl.dart:40-63` has `TODO(P03): real backend auth`; creates a local owner row only; password never stored | Supabase Auth (Apple + Google + email) per SETUP_CHECKLIST Phase 3–4 |
| Co-parent sync / invites | ❌ | Owner/co-parent rows are local-only; no deep-link, no Edge Function | Invite row + `https://getnestling.co.uk/invite/<token>` App/Universal Links per TECH_STACK §3/§9 |
| Email via Resend | ❌ | No Resend/SMTP code in `lib/` | SETUP_CHECKLIST Phase 3 (SMTP for Auth + API for DMCC/co-parent mail) — 👤 owner creates domain + key |
| Subscriptions / receipt validation | ❌ | Local `app_state.subscription_status` only; no RevenueCat SDK (`pubspec.yaml` deps list) | RevenueCat + webhook → `families.plan` per TECH_STACK §4 — 👤 owner creates products first |
| Push | ❌ | `notifApprovals/Payout/Summary` are local booleans (`app_database.dart:257-259`); no `firebase_messaging` / `flutter_local_notifications` dep | FCM messaging-only + local notifications per TECH_STACK §5; payloads carry IDs only, parent devices only |
| Schema migrations path (current v7) | ✅ | `schemaVersion => 7` + documented v1→v7 path (`app_database.dart:340-373`); `beforeOpen` guarantees `app_state`/`fam1` rows | Keep the per-version `onUpgrade` discipline; never squash before a release without a tested path |
| Migration test | ✅ | `test/core/data/time_migration_test.dart` (v1→v2), `members_email_test.dart:82` (v6→v7), `children_order_test.dart:88`, `quest_order_test.dart:117`, `rewards_order_test.dart:134`, `completion_note_test.dart:82`, `migration_first_run_test.dart` | Add a v7→v8 test with every future migration |
| Backup / restore | ❌ | Single file DB, no export/import, no cloud backup wiring | Decide v1 story (OS auto-backup of `nestling.db` only?) + Edge-Function CSV/JSON export for the "Download our data" row; see §5 |
| "Delete everything" (P04 promise) | ❌ | Mechanism exists (`clearAll()` deletes every table, `app_database.dart:331`) but Settings → Delete shows toast `Family account deletion is not available yet` (`settings_view.dart:399`) | Wire confirm dialog → `clearAll()` + reset `app_state` + (post-backend) cancel store subscription + confirm by email ≤ 30 days per TECH_STACK §11 |

---

## 4. Payments (P07 paywall vs real StoreKit / Play Billing)

| Item | Status | Evidence | Next step |
|---|---|---|---|
| Store-backed purchases | ❌ | No `purchases_flutter` / `in_app_purchase` in `pubspec.yaml`; `PaywallRepositoryImpl` returns static `_plans` and writes local `app_state` only (`paywall_repository_impl.dart:22-50`) | Integrate RevenueCat (`nestling_annual`, £29.99, 14-day trial) per SETUP_CHECKLIST Phase 1–2; entitlements drive `app_state`, never the reverse |
| Trial logic (14 days from AppSession) | ✅ | `trialLength = 14 days` elapsed from `trialStart` (`app_session.dart:40-48`); persisted to `expired` at launch/resume; router funnels expired parents to `/paywall`, kids to the gate (`router.dart:127-138`) | Keep; add server-side entitlement check post-RevenueCat (device clock must not grant access) |
| Trial copy / DMCC readiness | ⚠️ | Plan line `£29.99/year after the 14-day trial. Cancel anytime in Settings.` (`paywall_repository_impl.dart:99-102`); timeline row `Day 14 — £29.99 billed` (`paywall_view.dart:596`) | Add the five DMCC pre-contract facts + renewal/cooling-off notices before Jan 2027 (SETUP_CHECKLIST Phase 5); "Cancel in Settings" must deep-link to store subscription management once live |
| Restore purchases | ⚠️ | Button dispatches `PaywallRestoreRequested` → local `setSubscription('active')` (`paywall_view.dart:46-47,768-771`) — correct stub, not a store restore | Wire to `Purchases.restorePurchases()`; keep the active-never-downgrades rule (`paywall_bloc.dart` P07-BUG-12 guard) |
| Family Sharing | 👤 | Nothing in code (store-side toggle) | Owner enables Family Sharing on `nestling_annual` (SETUP_CHECKLIST Phase 1) and states the household scope in the paywall + listing |

---

## 5. Privacy & children (UK — Age Appropriate Design / Children's Code)

Code posture today: no analytics/ads/tracking SDKs in the dependency tree
(`pubspec.yaml:30-56` — no Aptabase/PostHog/Firebase/Adjust/AppsFlyer/AdMob),
no location/camera/contacts/microphone permissions
(`AndroidManifest.xml`, `Info.plist` grep empty), no network code in `lib/`.
The schema holds no child email/photo/location columns by design.

| Item | Status | Evidence | Next step |
|---|---|---|---|
| High privacy defaults | ✅ | `crashReportConsent` defaults OFF (`app_database.dart:263-264`); `kidGateEnabled` defaults ON; `onboardingComplete` false; `appMode` parent | None; keep OFF/ON as the tested defaults |
| No nudges (incl. to share) | ⚠️ | Crash toggle OFF by default ✅; no streak-shame/loot copy (grep empty); but `notifApprovals/Payout/Summary` default **true** (`app_database.dart:257-259`) | Set notification defaults to OFF until runtime permission + in-app explainer; notifications are local-only today so risk is low, but defaults must be defensible |
| No profiling / behavioural targeting | ✅ | No analytics SDK; `KidAnalytics`-style separation is structural (nothing to call) | When Aptabase lands (parents only, consent-gated, never kid flows) per TECH_STACK §6, re-audit this row |
| No ads / tracking | ✅ | No ads SDK; P04 promise rows + `privacy_consent_view.dart:97` | None |
| Geolocation off | ✅ | No geolocator/permission deps; only IANA zone math (`family_time.dart`), not device location | Never add location columns/permissions without a DPIA update |
| Parental controls / gate (P17) | ✅ | Arithmetic challenge gate (`parental_gate_repository_impl.dart:24,43-46`, e.g. 7×6=42), kid PIN is salted SHA-256 never stored (`pin_hash.dart`), router blocks kid mode from all parent routes (`router.dart:107-109`) | Manual reviewer pass (see §8 review notes) |
| Crash reporting OFF by default | ✅ | P04 toggle wired to `settings.crashReportConsent` (`privacy_consent_repository_impl.dart:41-100`); OFF default proven by repo tests | None on the default |
| Where crash data would go | ⚠️ | **Nowhere** — no Sentry/Crashlytics SDK is wired, so the toggle persists locally and sends nothing | Either wire Sentry EU (DSN, `beforeSend` PII scrub, screenshots OFF in kid flows) behind the toggle per TECH_STACK §7, or remove the toggle before release so the UI never promises a pipeline that does not exist |
| Privacy notice + terms links | ⚠️ | P04 "Read the full Privacy Notice" opens an in-app modal with the 4 promise lines (`privacy_consent_view.dart:346-392`), not the hosted policy; P03 Terms/Privacy links are inert `onTap: () {}` with `TODO(P03)` (`create_account_view.dart:720-721`); P07 Terms toasts "available in the full app" | Link to live `https://getnestling.co.uk/privacy` + `/terms` (👤 owner publishes per SETUP_CHECKLIST Phase 5) via `url_launcher` or in-app webview; keep the P04 modal as summary only |
| App Store privacy "nutrition label" (draft from code) | ⚠️ | Derived from code: **Data Not Collected** for the local-only build (no server transmission, no third-party SDKs, crash toggle sends nothing) | 👤 Owner answers in Connect; **re-answer the moment** Sentry/Aptabase/Supabase/Resend ship (then: diagnostics + identifiers, linked to user, with purposes) |
| Play Data safety (draft from code) | ⚠️ | Derived from code: **no data collected, no data shared** (on-device only); no location, photos, contacts, or ad ID | 👤 Owner answers in Console with "parent-directed" target audience (kids are users, not the audience); re-answer when the backend lands |
| Kids category NOT used (Parenting) | ✅ | No Kids-category flags in code; SETUP_CHECKLIST Phase 1–2 prescribes **Parenting** (never "Kids") | 👤 Owner selects Parenting + completes age-rating questionnaire honestly (no UGC/chat, no loot, no ads) |

---

## 6. Accessibility

| Item | Status | Evidence | Next step |
|---|---|---|---|
| Semantics / tap-target coverage | ⚠️ | 79 test files assert `hasAction(SemanticsAction.tap)`; shared `test/core/design_system/semantics_actions_test.dart`; `NestChipWrap` keeps 44 px targets; kid buttons ≥ 56 (`DESIGN_SPEC.md:19,186`) | Fix the 2 known shared issues in the cleanup pass: static `NestListRow`s merging into the next interactive announcement, and the `Semantics > InkWell` extra node pinned by P16 (`BACKLOG.md`) |
| Text scale 1.3 / 320 px | ⚠️ | Shell clamps scaler 1.0–1.3 (`app/lib/app/app.dart:20-21`) ✅; but BACKLOG lists 320 px × 1.3 overflows: K09-BUG-9 card overflow, K07-BUG-10 stat clip, K10-BUG-4 heading clamp, K05-BUG-5 4-digit ellipsis, P12-BUG-04 segmented < 44 px | Triage per §9: P12-BUG-04 is release-blocking; re-run the 320 px × 1.3 matrix on a small phone before submission |
| Reduce Motion | ✅ | `kDisableAnimations` → `MediaQuery.disableAnimations` (`app.dart` builder); Rive→SVG / Lottie-still fallback (RULES.md §6); splash still-hold 300 ms, no motion (`launch_splash.dart:100-106`) | Manual check with OS Reduce Motion ON on both platforms |
| VoiceOver / TalkBack manual pass | ❌ | Automated semantics tests only; no recorded manual pass | Walk all 30 screens with VoiceOver + TalkBack (focus order, labels, gate/keypad, dialogs, toasts); log in `docs/screens/_shared/` |
| Contrast | ⚠️ | Requirement `≥ 4.5:1` (≥ 3:1 large bold) in `DESIGN_SPEC.md:19`; no systematic token-pair contrast test found (only incidental mentions in feature bugs tests) | Spot-check all token pairs both themes (ink/paper, ink-2/surface, leaf/on-leaf, coin/coin-ink, sky/sky-tint, danger/surface) with a contrast tool; add a `tokens_contrast_test` pinning the ratios |

---

## 7. Quality

| Item | Status | Evidence | Next step |
|---|---|---|---|
| Unit/widget suite | ✅ | `flutter test --timeout 120s` → **All tests passed** (275 files; 5,231 passed, ~16 skipped — this pass) | Record wall-time on CI; keep the `--timeout 120s` discipline (RULES/common.md §30) |
| `flutter analyze` | ✅ | `flutter analyze` → **No issues found!** (6.7 s, this pass) | Gate `main` on it in CI |
| `dart format` | ✅ | `dart format --output=none --set-exit-if-changed .` → 681 files, 0 changed (this pass) | Gate in CI |
| Integration tests on real devices | ❌ | `integration_test/gallery_shots_test.dart` is a gallery screenshot harness (simulator via `tools/sim_shots.sh`), not an onboarding→paywall→today flow; no Test Lab / Firebase run exists | Add 1 smoke integration test (fresh → P01→P07 trial → Today → kid mode → gate) and run on a real iPhone + Android device (or Test Lab) per TECH_STACK §10 |
| Golden / visual coverage | ⚠️ | 1 golden (`app/goldens/pet_stage3.png`); per-screen `shot.sh` + `compare.py` ±2 px workflow on simulators, no CI gate | Pin goldens for Pip stages + hero money/ledger cards; fail CI on drift |
| Crash-free manual smoke script | ❌ | No script in repo | Use this script on both platforms (release candidate, fresh install + upgrade install): ① cold start ≤ splash 1.6 s, no jank; ② P01→P07 onboarding, start trial; ③ airplane mode — ledger/quests/payout all work; ③ kill + relaunch — state persists; ④ kid mode — picker → PIN → home → quest done → approvals → gate back to parent; ⑤ background 1 h — trial-expiry path sane; ⑥ reinstall over existing — v7 migration, no data loss; ⑦ 320 px + 1.3 text + Reduce Motion + dark mode sweep; ⑧ no crash, no ANR, no "Timer still pending" in logs |
| Startup performance (splash ≤ 1.6 s) | ⚠️ | In-app splash hard ceiling 1600 ms (`launch_splash.dart:37-49`) ✅ by construction; native→Flutter hand-off sized to avoid a jump (`kLaunchSplashEggSize = 256`) | Measure cold start to interactive (`--trace-startup`, Instruments, Macrobenchmark) on a low-end Android + older iPhone; publish the numbers here |
| Rive / Lottie jank | ⚠️ | Rive Pip ships in 3 styles × stages; still-frame fallback exists; no jank measurement found | Profile Pip-heavy screens (K03/K06/splash) at 60/120 Hz; record worst-frame times; reduce art if over budget |

---

## 8. Store listing

| Item | Status | Evidence | Next step |
|---|---|---|---|
| Icon | ✅ | `docs/brand/icon_preview.png` + `app/assets/brand/app_icon*.png` (1024 master, adaptive fg/bg, monochrome, Play 512) wired in `pubspec.yaml:149-157` | 👤 Owner uploads in Connect/Console; verify rendered on device + store |
| Screenshots per required size | ⚠️ | Designer art exists: iOS 6.5" (1284×2778) + 6.9" (1320×2868) × 8, Play phone (1080×1920) × 6, feature graphic (1024×500) in `design/store/` | Capture **from the release-candidate app** via `tools/screens/shot.sh` for every required class (Apple: 6.9" + 6.5" + iPad if universal; Play: ≥ 2 phone + 7" tablet + feature graphic); replace mock art where pixels differ |
| App name / subtitle / keywords | ✅ (draft) | MARKETING.md §3: `Nestling: Family Quests` (23/30), `Chores, coins & pocket money` (28/30), keywords `chores,quests,…` (82/100); parent-directed, no "for kids" (Apple 2.3.8) | 👤 Owner enters verbatim; never add "for kids" to metadata (rejection risk) |
| Support URL / email | 👤 | `support@getnestling.co.uk` + `hello@` alias specified (SETUP_CHECKLIST Phase 0, MARKETING.md §7); inbox/DNS not verifiable from this repo | Owner provisions inbox + publishes privacy/terms/landing; test an email round-trip before submission |
| Age rating questionnaire | 👤 | Code-derived answers: no UGC/chat/photos/location, no gambling/loot, no ads, parental gate on kid exit; expect 4+ / Everyone | Owner completes honestly in both consoles (answers must match the shipped binary, incl. §5 re-answers) |
| Review notes (parental gate) | ⚠️ | Gate is an arithmetic challenge (`parental_gate_repository_impl.dart:43-46`); demo seed ships an **active** subscriber (`seed.dart:73`) so screenshots bypass the paywall | Provide reviewers: ① a fresh-install path P01→P07 with the trial CTA; ② the gate format (answer the shown multiplication, e.g. 7×6=42) + kid PIN location; ③ a demo child profile; ④ state the subscription is annual £29.99 after 14 days. Ensure the **review build uses `Seed.fresh`**, never demo, so the paywall is reachable |

---

## 9. Open quality items (`docs/screens/_shared/BACKLOG.md` triage)

**Release-blocking (fix before submission):**

- P12-BUG-04 — `NestSegmented` with 6 options shrinks below the 44 px tap
  target at 320 dp (proof skipped in `p12_bugs_test.dart`). Accessibility
  gate: fix or constrain options per screen.
- `Seed.familyId` read directly in 10+ feature repos (fine local-only, one
  family per device). Any TestFlight/closed-track build that touches sync
  must first expose the current family from `AppSession`. If v1 ships
  local-only, file the migration as a launch-gated task, not a silent TODO.
- P15 `family_repository_impl.dart:41` reads `Seed.anchorOverride` in app
  code — replace with `clock.now()`/`appNowUtc()` (test-hook leak into
  product code).
- "Delete family account" + "Download our data" are stubbed (toast /
  navigation to `/privacy`, §3/§5). Either wire them or remove the rows
  before submission — a dead deletion control is a certain rejection + a
  Code issue.
- Dev routes reachable in release (§2) — gate or strip gallery/motion-lab/
  pip-lab.
- Release signing + flavours + obfuscation (§1) — no shippable binary exists
  until these land.

**Post-launch / polish (ship with known-issue log, fix in x.1):**

- Minor layout: K09-BUG-10 relative-day labels, K09-BUG-9 320 px overflow,
  K09-BUG-8 `moveToSavings` without a goal, K09-BUG-7/7b bloc-close leak,
  K05-BUG-5 4-digit ellipsis, K05-BUG-6 semantics-value mismatch,
  K07-BUG-10 5-digit stat clip, K10-BUG-4 long goal-name clamp, K03-BUG-16/17
  pet-stage geometry, K03B-BUG-2 `explicitGeometry` bleed, K01-BUG-7 orphaned
  selection lock, K05/K06 growth `%` floor-vs-round mismatch, Money-tab
  wallet glyph swap, K03 in-flow meadow → shared `kid_meadow`, P17 minor
  review items, K02 `kidAvatarInitial` → shared `nestAvatarInitial`,
  `NestPageTitle` extraction, the two shared semantics cleanups (§6).

---

## Release-blocking summary (ordered)

1. Owner identity + D-U-N-S + Apple enrolment + Play account (SETUP_CHECKLIST
   Phases 0–2) — longest lead, starts the clock. 👤
2. Release signing: Android upload keystore + iOS team/profiles via match. 👤 + dev.
3. Backend + products: Supabase projects, RevenueCat entitlement
   `nestling_annual` + webhooks, Apple/Google subscription products with
   14-day trial + Family Sharing, OAuth clients, Resend domain, Sentry EU +
   Aptabase wiring behind consent. Mostly 👤 + integration work.
4. Replace the local-only stubs in-app: real auth, receipt validation +
   server-side entitlement, restore purchases, co-parent invites, push,
   export + **working deletion**. (Code ❌ items in §3–§4.)
5. Kill or gate dev routes in release; wrap the 3 unguarded logs; set
   notification defaults OFF. (Code ❌/⚠️ in §2/§5.)
6. Privacy surface: publish `/privacy` + `/terms`, link them in-app (P03/P04/
   P07/Settings), re-take the nutrition-label + Data-safety answers for the
   exact shipping binary; DPIA + Children's Code self-assessment filed. 👤 + dev.
7. Accessibility: fix P12-BUG-04, re-run 320 px × 1.3 matrix, contrast
   spot-check, VoiceOver/TalkBack pass. (No submission with a known < 44 px
   control.)
8. Quality: real-device integration smoke + startup/jank numbers + crash-free
   script signed off on both platforms; app size recorded.
9. Listing: app screenshots from the release candidate per size class, support
   inbox live, age rating + review notes (gate answer, fresh-seed paywall
   path) submitted.

## Owner actions (👤 — from this doc; full list in SETUP_CHECKLIST)

- Company + D-U-N-S + ICO registration + `getnestling.co.uk` DNS +
  `support@` inbox (SETUP Phase 0).
- Apple Developer enrolment, App ID + bundle `uk.co.getnestling.app`, App
  Store Connect record (Parenting), Paid Apps Agreement + banking/tax, Small
  Business Program, subscription + trial + Family Sharing, 3× `.p8` keys,
  match profiles (Phase 1).
- Play account (organisation if incorporated), $25 fee, merchant profile,
  app record, subscription + trial, Data safety + target-audience + rating,
  service-account JSON (Phase 2).
- Supabase / RevenueCat / Firebase-messaging-only / Sentry-EU / Aptabase /
  Resend accounts + DPAs (Phase 3); Apple + Google OAuth clients (Phase 4).
- DPIA + Children's Code self-assessment; publish privacy/terms/landing.
- Enter listing metadata (MARKETING.md §3), upload icon + sized screenshots,
  complete age rating, file review notes.

*Complements [`SETUP_CHECKLIST.md`](./SETUP_CHECKLIST.md) — that doc is the
system of record for every account, key and legal step.*
