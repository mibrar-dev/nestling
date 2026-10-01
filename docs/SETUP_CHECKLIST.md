# Nestling — Pre-Development Setup Checklist

**Date:** 30 Sep 2026 · **What the owner must set up BEFORE backend development starts.** Decisions are final in [`TECH_STACK.md`](./TECH_STACK.md), [`PRICING.md`](./business/PRICING.md) and [`MARKETING.md`](./business/MARKETING.md). Order = dependency order, then longest lead time. Phases 0–2 gate the backend schema; Phase 3+ runs in parallel once Phase 0 lands.

## Secret-handling rules

- **Never** paste a key, `.p8`, JSON service account, password or token into the repo, a commit, an issue or Slack.
- Local: `app/.env.dev|stg|prod` as real files, gitignored; commit only `.env.example` with empty values.
- CI: GitHub **Settings → Secrets and variables → Actions** (encrypted, log-masked). Never repository *variables*.
- Key files live in the owner's password manager, shared by time-limited secure share. CI gets only what it needs (App Store Connect `.p8`, `MATCH_PASSWORD`). Any key pasted in error → revoke, replace, re-issue.

---

## Phase 0 — Legal identity, domain, money (longest lead; blocks everything)

- [ ] **Decide: UK limited company vs sole trader.** Upstream of everything — sets the Apple seller name, Play account type, bank account, tax forms, privacy-controller name. Ltd: Companies House online registration ≤24h ([gov.uk](https://www.gov.uk/get-information-about-a-company)), ~£50–£500 one-off. Sole trader: £0, no limited liability, and Making Tax Digital for Income Tax bites from Apr 2026 (>£50k) / Apr 2027 (>£30k) ([GOV.UK](https://www.gov.uk/government/publications/extension-of-making-tax-digital-for-income-tax-self-assessment-to-sole-traders-and-landlords/making-tax-digital-for-income-tax-self-assessment-for-sole-traders-and-landlords)). **Recommendation: incorporate.** Hand over: entity name, registered address, company number, director, VAT status.
- [ ] **Free D-U-N-S number** — request it *inside* the Apple/Google enrolment form, never buy a third-party expedite. Apple 1–5 business days, up to ~30 for UK entities ([enrol](https://developer.apple.com/programs/enroll), [membership](https://developer.apple.com/help/account/membership/program-enrollment)); Google adds 5–10 business days. Name/address/phone must match the D-U-N-S record **exactly** or enrolment stalls. £0. Lead **1–4 weeks — start today.**
- [x] **DONE: `getnestling.co.uk` purchased.** `nestling.co.uk` was taken, so the shipped domain is **`getnestling.co.uk`** — deep links, `assetlinks.json`, `apple-app-site-association`, DKIM and the privacy policy all hang off this one domain. **Remaining:** point DNS at the host and add the Resend + DMARC records below. Optional, recommended: register **`heynestling.com`** defensively (~£10/yr) so a typo or a competitor cannot intercept a support email or a deep link.
- [ ] **`support@getnestling.co.uk`** on a human inbox (Fastmail ~£5–8/mo), with **`hello@getnestling.co.uk`** as the public/general alias. Apple, Google and the DMCC regime all require a working support/cancellation address. Keep transactional mail strictly separate: `noreply@mail.getnestling.co.uk` is send-only and must never receive replies.
- [ ] **ICO registration, Tier 1 fee £52/yr (£47 Direct Debit)** — £5,000+ penalty for non-payment ([ICO](https://ico.org.uk/for-organisations/data-protection-fee/faqs-data-protection-fee-payment-and-online-registration)). Use a PO box if you don't want a home address on the public register. 15 minutes.

## Phase 1 — Apple (gates the product id and subscriptions)

- [ ] **Enrol in the Apple Developer Program — $99/yr** ([enrol](https://developer.apple.com/programs/enroll)). **Individual:** personal name as store seller, 1–3 days. **Organisation:** company name as seller, needs the D-U-N-S number, **≥7 days, often 1–2 weeks**. Apple contracts only with a legal entity, not a trading name.
- [ ] **Register the App ID, bundle id `uk.co.getnestling.app`**, with **Sign in with Apple + Push Notifications + Associated Domains** enabled at creation — retrofitting forces a new profile. Hand over bundle id + **Team ID**.
- [ ] **Create the App Store Connect app record:** SKU `NESTLING`, category **Parenting** (never "Kids"). Must exist before subscriptions and TestFlight.
- [ ] **Sign the Paid Apps Agreement, then banking + tax.** Order is fixed — banking can't be entered until the agreement is signed, and all tax forms must be filed first ([Apple](https://developer.apple.com/help/app-store-connect/manage-banking-information/enter-banking-information)); status runs Pending → Processing → Active. **This is the step that blocks all revenue.** Entity details must match Phase 0 and D-U-N-S.
- [ ] **Enrol in the Small Business Program** — 15% not 30% under $1M/yr, re-qualified annually, no year-2 cliff ([SBP](https://developer.apple.com/app-store/small-business-program/)). ~10 min; skipping costs ~£4.5k/yr at PRICING.md Option A volume.
- [ ] **Subscription group + product + 14-day trial.** Group `Nestling Annual`; product `nestling_annual`, level 1; **Introductory Offer → free trial, 14 days, GB storefront** ([Apple](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions)). Price **£29.99** (a confirmed live GB point, PRICING.md §3). **Family Sharing on.** One intro offer per group — this is also the Step-1 price-test lever, so build it once, correctly.
- [ ] **Generate the three one-time-download `.p8` keys** (Keys → +; **each downloads once**, max two per app — [Apple](https://developer.apple.com/documentation/signinwithapple/configuring-your-environment-for-sign-in-with-apple)): **Sign in with Apple**; **Apple Push Notifications** ([APNs](https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns) — one key serves all apps, tokens don't expire); **App Store Connect API** at **App Manager**+ ([RC](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/app-store-connect-api-key-configuration)). Record each **Key ID**, plus **Issuer ID** and **Vendor number**.
- [ ] **Signing certificates + profiles** (Apple Development, Apple Distribution, App Store profile for the bundle id). For CI use `fastlane match` in a private git repo with `MATCH_PASSWORD` in GitHub secrets, not exported `.p12`s ([match](https://docs.fastlane.tools/actions/match/)).
- [ ] **Recruit 20–30 testers now** for TestFlight and the Play closed track.

## Phase 2 — Google Play (longest calendar wait on a personal account)

- [ ] **Choose the account type — near-irreversible, and it decides the launch date.** **Personal:** $25 once, no D-U-N-S, your name as store developer, but new personal accounts (created after 13 Nov 2023) must pass **device verification** (non-rooted physical Android, Android 10+, Play Console mobile app, <1 min — [Play](https://support.google.com/googleplay/android-developer/answer/14316361)) **and a closed test of ≥12 testers opted in continuously for 14 days** before they may even *apply* for production; review then takes **≤7 days, occasionally longer** ([rules](https://support.google.com/googleplay/android-developer/answer/14151465)). **Organisation:** same $25, needs D-U-N-S + business docs + org website/phone, and is **exempt from the 12-tester rule**. If Phase 0 incorporated → **Organisation**; personal adds a hard **4-week** gate, and the clock only starts when the 12th tester *accepts* and stays opted in.
- [ ] **Pay the $25 one-time fee** with a non-prepaid card. Non-refundable.
- [ ] **Identity/contact verification + payments (merchant) profile.** Legal name/address must match D-U-N-S. Payouts on the 15th for the prior month; wire adds 5–7 working days ([schedule](https://support.google.com/paymentscenter/answer/7159355?hl=en-GB)). Lead 2–10 business days.
- [ ] **Create the app record** — package `uk.co.getnestling.app` (matches the iOS bundle id, so one support email and one deep-link story work), category Parenting. Confirm the **target API level: new apps and updates must target Android 16 / API 36**, effective **31 Aug 2026**, extensions only to 1 Nov 2026 ([Play](https://support.google.com/googleplay/android-developer/answer/11926878)). Verify Flutter 3.47.5's Android target before the build pipeline is written.
- [ ] **Subscription product** mirroring Apple: `nestling_annual`, auto-renewing 12-month base plan, £29.99 GBP, **14-day free trial offer**, then **activate** (Play subscriptions must be active, not just saved, to be purchasable).
- [ ] **Data safety form, target-audience declaration, content rating, privacy-policy URL.** Declare **parent-directed** — kids are users, not the audience.
- [ ] **Google Cloud service account + JSON key** for Play revenue: grant it the app plus the permissions RevenueCat lists, download the JSON (**one download**). Play service credentials can take **up to 36 hours to activate** — create early ([RC](https://www.revenuecat.com/docs/service-credentials/creating-play-service-credentials)).

## Phase 3 — Backend and vendors (per TECH_STACK)

- [ ] **Three Supabase projects in West Europe (London) `eu-west-2` — dev/stg/prod.** Not the "Europe" general region, which may land in Zurich ([regions](https://supabase.com/docs/guides/platform/regions)). Free at launch; Pro ($25/mo) for dev/stg so staging can hold real migrations. Hand over project URL + **anon key** each; the **service-role key** is a secret for Edge Functions only, never the app.
- [ ] **RevenueCat project + both stores.** Upload the App Store Connect `.p8` + Issuer ID + Vendor number; upload the Play service-account JSON; create entitlement **`nestling_annual`**; create the **webhook** to the Supabase Edge Function (auth header secret in RevenueCat + Edge Function env, never the repo). Free to $2,500/mo MTR ([pricing](https://www.revenuecat.com/pricing)). ~45 min + up to 36h for Play credentials to go green.
- [ ] **Firebase project, messaging only.** Upload the APNs `.p8` + Key ID + Team ID under Project Settings → Cloud Messaging. Enable **only** Cloud Messaging — no Analytics, no Crashlytics, no Ad ID ([FCM](https://firebase.google.com/docs/cloud-messaging/ios/get-started)). Generate a service-account JSON for backend sends via FCM HTTP v1. £0. **DPIA note:** FCM processes on US infrastructure — payloads carry IDs only, never child names.
- [ ] **Sentry org with data storage location = European Union (Frankfurt).** **Permanent** choice — changing it needs a new org, and account/2FA/DSN metadata still lives in the US ([Sentry](https://docs.sentry.io/organization/data-storage-location/)). Free tier covers launch. Hand over **DSN**.
- [ ] **Aptabase app**, confirming **EU hosting** before wiring (TECH_STACK marks this verify-at-setup). Must stay inert until the P04 consent toggle. £0 to 20k events/mo. Hand over base URL + API key.
- [ ] **Resend account** + verified sending domain **`mail.getnestling.co.uk`** ([pricing](https://resend.com/pricing) — Free: 3,000 emails/mo, 100/day, 3 domains; Pro $20/mo / 50k). **£0 at launch**: volume is <1k emails/mo. Create the domain with the sending region set to **`eu-west-1` (Ireland)** — this is chosen per domain at creation and is on the free plan ([regions](https://resend.com/docs/dashboard/domains/regions), [multi-region for everyone](https://resend.com/changelog/multi-region-for-everyone)). **Read the residency caveat into the privacy notice:** the region controls only where mail is *routed*; account data, logs and email metadata are stored in the **US** regardless. Add the records Resend shows you, copied exactly ([add a domain](https://resend.com/docs/add-a-domain)): **DKIM** (TXT), **SPF** (TXT on the sending subdomain — `v=spf1 include:amazonses.com ~all`), **Return-Path MX** on the same subdomain, then add **DMARC yourself** on the root (`_dmarc.getnestling.co.uk`, e.g. `v=DMARC1; p=none; rua=mailto=dmarc@getnestling.co.uk`) — Resend does not create DMARC for you. Because the SPF record sits on a subdomain, keep DMARC at **`aspf=r`** (relaxed); strict alignment can never pass. Verification usually completes in ~15 min, but DNS propagation can take up to 72h ([verification](https://resend.com/docs/add-a-domain)). DMCC reminder emails depend on this working. Then wire both paths: **SMTP** for Supabase Auth (`smtp.resend.com`, port **465**, username `resend`, password = the API key — [Resend](https://resend.com/docs/send-with-supabase-smtp), [Supabase](https://supabase.com/docs/guides/auth/auth-smtp)), and the **API from Supabase Edge Functions** for DMCC reminders and co-parent invites. From address `noreply@mail.getnestling.co.uk`. Hand over the **`RESEND_API_KEY`**.
- [ ] **Sign each processor DPA** (Supabase, RevenueCat, Resend, Sentry, Aptabase) and list them all in the privacy notice (TECH_STACK §11). £0, but it must be *done*. Resend's DPA is self-service and already carries the **UK SCCs + UK Addendum** for the ex-UK transfer and the EU SCCs, so accept it rather than negotiating ([DPA](https://resend.com/legal/dpa)); also file the sub-processor list at [resend.com/legal/subprocessors](https://resend.com/legal/subprocessors).

## Phase 4 — Auth providers

- [ ] **Apple OAuth for web/Supabase.** **Services ID** `uk.co.getnestling.app.web`, return URL `https://<project-ref>.supabase.co/auth/v1/callback`; use the Phase-1 `.p8` + Key ID + Team ID to mint the client-secret JWT. Native iOS returns the idToken directly, but Flutter **web** needs the Services ID — and any OAuth-flow use means **6-month secret rotation** ([Supabase](https://supabase.com/docs/guides/auth/social-login/auth-apple)). Set a recurring reminder.
- [ ] **Google OAuth clients — iOS, Android, Web** ([Cloud console](https://console.cloud.google.com/apis/credentials)). iOS client id = bundle id, no SHA. Web client id = `uk.co.getnestling.app`; add the landing page and Supabase callback as JS origins. Android client id = package name plus **both** the **upload-key** SHA-1 (debug/internal) **and** the Play **app-signing-key** SHA-1 + SHA-256 from Release → Setup → App signing — the wrong one is the classic "works in dev, broken in production" bug ([Play app signing](https://vmobify.com/blog/play-app-signing-sha1-google-sign-in)).

## Phase 5 — Compliance (before launch, not after)

- [ ] **DPIA.** Mandatory *before launch* for any service likely to be accessed by children; embedded in design, not a rubber stamp ([ICO](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/2-data-protection-impact-assessments)). Contents per TECH_STACK §11: lawful basis, 15-standard walk-through, data-flow map, **empty kid-flow SDK inventory**, retention, deletion path. 1–2 days.
- [ ] **ICO Children's Code self-assessment**, filed with the DPIA; record the justification that children are users but never the account-holding audience ([ICO](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources)). Half a day.
- [ ] **Publish privacy policy + terms** on `getnestling.co.uk` — **[https://getnestling.co.uk/privacy](https://getnestling.co.uk/privacy)** and **[https://getnestling.co.uk/terms](https://getnestling.co.uk/terms)** (required by both stores; DMCC "easy exit" must name a real address, i.e. `support@getnestling.co.uk`), plus landing page and press kit ([MARKETING.md §7](./business/MARKETING.md)). 1 day.
- [ ] **DMCC note:** subscription rules commence **Jan 2027** ([gov.uk](https://www.gov.uk/government/news/pm-starts-roll-out-of-everyday-fixes-on-the-cost-of-living-ending-rip-off-discounts-and-subscription-traps)); the five pre-contract facts and the post-billing cooling-off notice ship in v1.

## Phase 6 — Delivery infrastructure and assets

- [ ] **Private GitHub repo** + developer as owner. Pre-load CI secrets (`MATCH_PASSWORD`, App Store Connect `.p8` + Key ID + Issuer ID, `SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, `SENTRY_AUTH_TOKEN`, `APPTABASE_KEY`, Firebase service-account JSON). Branch-protect `main`. £0. Note `RESEND_API_KEY` doubles as the Supabase Auth SMTP password, so it is needed in both Supabase and Actions.
- [ ] **Host the deep-link files** on `getnestling.co.uk`: [https://getnestling.co.uk/.well-known/apple-app-site-association](https://getnestling.co.uk/.well-known/apple-app-site-association) (Team ID + bundle id `uk.co.getnestling.app`) and [https://getnestling.co.uk/.well-known/assetlinks.json](https://getnestling.co.uk/.well-known/assetlinks.json) (app-signing-key SHA-256). Developer builds the app side; owner owns DNS. Both must be served over HTTPS with `Content-Type: application/json` and **no redirect**.
- [ ] **Confirm store assets:** 1024×1024 icon master, iOS screenshots per device class, Play feature graphic + phone screenshots, and the exact metadata strings in MARKETING.md §3. Pip art is already in `design/`. 1 day, parallel.

---

## Critical path

`Incorporate → D-U-N-S (1–4 wks) → Apple enrolment (≥7 d) + Play org verification (5–10 d) → 14-day Play closed test → production access (≤7 d)`. Everything else is **hours, not weeks**. The first TestFlight build needs beta review ([Apple](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview)); App Store review runs ~15h waiting / ~2h in review on average ([Runway, Sept 2026](https://www.runway.team/appreviewtimes)), longer for kids/finance apps.

## Day 0 hand-off — every identifier and secret

Non-secret IDs by document; secrets only via password manager or GitHub Actions secrets. **Never the repo.**

| # | Item | Secret | Phase | Handed over as |
|---|---|---|---|---|
| 1 | Supabase refs (dev/stg/prod, `eu-west-2`) + anon keys | No | P3 | Document |
| 2 | Supabase service-role key | **Yes** | P3 | Actions secret → Edge Functions only |
| 3 | DB passwords (×3) | **Yes** | P3 | Actions secret |
| 4 | Apple Team ID | No | P1 | Document |
| 5 | Bundle id `uk.co.getnestling.app` | No | P1 | Document (= Play package) |
| 6 | Services ID `uk.co.getnestling.app.web` | No | P4 | Document |
| 7 | Sign in with Apple `.p8` + Key ID | **Yes** | P1 | Password mgr → Supabase |
| 8 | App Store Connect API `.p8` + Key ID + Issuer ID + Vendor no. | **Yes** | P1 | `.p8` → Actions; IDs → doc |
| 9 | In-App Purchase `.p8` + Key ID | **Yes** | P1 | Password mgr → RevenueCat |
| 10 | APNs `.p8` + Key ID | **Yes** | P1 | Password mgr → Firebase |
| 11 | Product `nestling_annual`, group `Nestling Annual` | No | P1 | Document |
| 12 | Play developer account id | No | P2 | Document |
| 13 | Play app-signing-key SHA-1 + SHA-256 | No | P2 | Document → OAuth Android |
| 14 | Android upload-key SHA-1 | No | P2 | Document → OAuth Android (debug) |
| 15 | Google Cloud service-account JSON (Play) | **Yes** | P2 | Actions secret + RevenueCat |
| 16 | Google OAuth client ids (iOS/Android/Web) + web secret | Partly | P4 | IDs → doc; secret → Supabase |
| 17 | RevenueCat public SDK keys (iOS, Android) | No | P3 | `--dart-define` |
| 18 | RevenueCat webhook auth header | **Yes** | P3 | Actions secret + Edge Function |
| 19 | Firebase service-account JSON + project id | **Yes** (JSON) | P3 | Actions secret; id → doc |
| 20 | Sentry DSN (dev/stg/prod) | No | P3 | Document |
| 21 | Aptabase base URL + API key | **Yes** (key) | P3 | Actions secret; URL → `--dart-define` |
| 22 | Resend API key (`RESEND_API_KEY`) — also the Supabase Auth SMTP password | **Yes** | P3 | Actions secret + Supabase Auth SMTP |
| 23 | `fastlane match` repo access + MATCH_PASSWORD | **Yes** | P1/P6 | Private repo + Actions secret |
| 24 | `getnestling.co.uk` DNS access (or pre-added records) | **Yes** (account) | P0 | Owner edits DNS on request |
| 25 | `support@getnestling.co.uk` (public alias `hello@getnestling.co.uk`) | No | P0 | Document |

*All figures verified 30 Sep 2026. Identity verification is the least predictable item here — start Phase 0 before writing any backend code.*
