[0m
> build · muse-spark-1.3-contributor-free
[0m◈ [0mWeb Search via Parallel "RevenueCat State of Subscription Apps 2026 hard paywall conversion" 
[0m◈ [0mWeb Search via Parallel "Apple App Store Review Guidelines Kids Category parental gate 2025" 
[0m◈ [0mWeb Search via Parallel "Apple Guideline 3.1.1 in-app purchase subscription 2025" 
[0m◈ [0mWeb Search via Parallel "ICO UK Age Appropriate Design Code children's app privacy" 
[0m◈ [0mWeb Search via Parallel "Google Play Families policy requirements 2025 UK" 
[0m◈ [0mWeb Search via Parallel "Joon chore app subscription price $49.99 reviews" 
> build · muse-spark-1.3-contributor-free
[0m◈ [0mWeb Search via Parallel "BoardGameGeek BGG API terms of use licence XML" 
[0m◈ [0mWeb Search via Parallel "Mumsnet chore app allowance kids pocket money UK" 
[0m◈ [0mWeb Search via Parallel "Wizards of the Coast Fan Content Policy Dungeons Dragons IP app" 
[0m◈ [0mWeb Search via Parallel "TTRPG D&D market size UK players 2024 2025" 
[0m◈ [0mWeb Search via Parallel "Apple App Store AI generated content guideline review 2025" 
[0m◈ [0mWeb Search via Parallel "UK board games market size 2025 Games Expo hobby" 
> build · muse-spark-1.3-contributor-free
[0m% [0mWebFetch https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-code 
[0m% [0mWebFetch https://www.joonapp.io/ 
[0m✗ [0mWebFetch https://boardgamegeek.com/wiki/page/XML_API_Terms_of_Use failed
[91m[1mError: [0mStatusCode: non 2xx status code (403 GET https://boardgamegeek.com/wiki/page/XML_API_Terms_of_Use)
[0m% [0mWebFetch https://support.google.com/googleplay/android-developer/answer/9893335?hl=en-GB 
[0m% [0mWebFetch https://company.wizards.com/en/legal/fancontentpolicy 
[0m% [0mWebFetch https://developer.apple.com/app-store/review/guidelines 
> build · muse-spark-1.3-contributor-free
[0m% [0mWebFetch https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/ 
[0m% [0mWebFetch https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026 
[0m% [0mWebFetch https://www.gohenry.com/uk/pocket-money-chores 
[0m◈ [0mWeb Search via Parallel "Supabase pricing 2026 Pro Firebase Blaze cost per active user UK" 
[0m◈ [0mWeb Search via Parallel "OpenAI API pricing GPT-4o mini per 1k tokens 2026 GBP cost" 
[0m◈ [0mWeb Search via Parallel "RevenueCat pricing commission UK 2025 free paid" 
> build · muse-spark-1.3-contributor-free
# Build-Feasibility & Red-Team — Top 3 (UK solo launch)

| Idea | Build | Store safety | Unit econ | Retention | Founder fit |
|---|---|---|---|---|---|
| 1. Family Chore & Allowance | 7 | 3 | 5 | 4 | 7 |
| 2. TTRPG Campaign Memory | 6 | 8 | 5 | 8 | 9 |
| 3. Board Game Night | 8 | 6 | 3 | 5 | 6 |

> All scores author judgment UNVERIFIED. Higher = better/safer.

## 1. Family Chore & Allowance Gamification

**a) v1:** 6 screens: parent onboarding/paywall, quest create/approve, family board, kid home/pet, payout ledger, settings/privacy. Flutter: `purchases_flutter`, `supabase_flutter`, `local_auth`, `notifications`. Backend: Supabase Pro $25/mo (https://supabase.com/pricing) in London `eu-west-2` (https://supabase.com/regions). Paywall: RevenueCat free to $2,500 MTR then 1% (https://www.revenuecat.com/pricing), hard paywall 14-day trial — hard paywalls convert 10.7% vs freemium 2.1% (https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026). AI cost: £0.00–£0.02/active/mo UNVERIFIED — no LLM needed; use bundled art.

**b) 10–14 weeks store-ready UNVERIFIED.** Hardest: 1) dual parent/kid auth without child email + shared-device switching, 2) parental-gate + approval flow that actually satisfies review, 3) anti-cheat/anti-tap-spam reward economy.

**c) Rejection:** Kids Category bans links/purchases outside parental gate and bans third-party analytics/ads transmitting IDFA/identifiers (https://developer.apple.com/app-store/review/guidelines). Play Families demands accurate target-audience declaration, no AAID/location from kids, certified ad SDKs + neutral age screen for mixed audiences (https://support.google.com/googleplay/android-developer/answer/9893335?hl=en-GB). ICO Children's Code: 15 standards, high-privacy default, applies if likely accessed by under-18s (https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-code). Digital unlocks must use IAP 3.1.1 (https://developer.apple.com/app-store/review/guidelines). Avoid: ship 17+, parent-account-only, no Kids Category, no third-party analytics in kid flow, IAP-only, DPIA + privacy policy.

**d) Fail case:** Report's $49.99/yr is stale vendor claim from Launch HN 2022-01-19 (date: 2022). Joon now charges $12.99/mo or $89.99/yr (https://www.joonapp.io/) with 4.7 stars (https://www.joonapp.io/) and only ~6,559 iOS ratings at 4.68 (https://www.appbrain.com/appstore/joon-kids-adhd-chore-tracker/ios-1482225056) — niche, not mass. UK parents pay £9.90/week pocket money avg Jan-Apr 2026 (https://prod-mw.independent.co.uk/money/children-britain-england-cpi-b2991456.html) and Mumsnet threads show £3–£5/week norms + “chores = family life, not paid” resistance (https://www.mumsnet.com/talk/_chat/5264469-how-much-pocket-money-do-your-kids-get). GoHenry already did 84M chores + £1.8B pocket money (https://www.gohenry.com/uk/pocket-money-chores) with card + FCA-regulated rails. You lose on trust, CAC, and kid churn in weeks.

## 2. TTRPG Campaign Memory (AI)

**a) v1:** 5 screens: campaigns, session capture, entity cards/graph, ask-memory search, export/settings. Flutter: `purchases_flutter`, `supabase_flutter`, `sqlite` offline queue, audio `record` optional. Backend: Supabase as above. Paywall: RevenueCat, freemium 1 campaign/50 entities then $4.99/mo or $39.99/yr UNVERIFIED proposal; note hard paywalls earn $3.09 vs $0.38 RPI day-60 (https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026). AI cost: ~£0.02–£0.08/active/mo UNVERIFIED assuming 4 sessions/mo × 8k in + 1k out on gpt-4o-mini at $0.15/$0.60 per 1M (https://pricepertoken.com/pricing-page/model/openai-gpt-4o-mini).

**b) 9–12 weeks UNVERIFIED.** Hardest: 1) fantasy-name entity extraction without hallucinating NPCs/quests, 2) offline-first at-table capture + conflict merge, 3) long-campaign recall (pgvector + confidence + human-approve UX).

**c) Rejection:** Low. Main risks: 5.1.1 data + Nov 2025 rule — disclose sharing personal data with third-party AI + explicit permission (https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/). Avoid by on-device redaction, opt-in toggle, zero-training DPA. Wizards Fan Content Policy (date: 2017) mandates FREE, no logos/trademarks, no IP in other games (https://company.wizards.com/en/legal/fancontentpolicy). Avoid: system-agnostic, no D&D trademark, no SRD verbatim, user-owned notes only + report/block per 1.2 UGC (https://developer.apple.com/app-store/review/guidelines).

**d) Fail case:** Global TTRPG market only $2,058.46M in 2025 (https://www.marketreportsworld.com/market-reports/tabletop-role-playing-game-ttrpg-market-14722144) — UK slice tiny. Players already tolerate Notion/Obsidian free; Table Canon HN 4pts shows apathy, not demand. AI paradox: AI apps earn 41% higher LTV ($30.16 vs $21.37) but retain 36% worse over 12mo (https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026). One hallucinated innkeeper's daughter kills DM trust; Discord word-of-mouth cuts both ways.

## 3. Board Game Night Companion

**a) v1:** 4 screens: collection, night setup/score entry, stats/leaderboards, settings/BGG import. Flutter: `mobile_scanner`, `sqlite/drift` offline-first, `supabase_flutter`, `purchases_flutter`. Backend: Supabase free→$25/mo; no realtime needed. Paywall: $9.99 one-time Pro UNVERIFIED — weak; annual subs retain only ~27–28% at 1yr (https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026) and one-time is worse. AI cost: £0 UNVERIFIED — no LLM.

**b) 8–11 weeks UNVERIFIED.** Hardest: 1) fast pass-and-play scoring with zero friction + offline sync, 2) barcode→correct edition matching, 3) BGG sync throttling/auth + local cache invalidation.

**c) Rejection:** Medium. BGG XML API is strictly non-commercial; commercial use needs licence, must show Powered by BGG, no modifying data, no AI training (https://boardgamegeek.com/wiki/page/XML_API_Terms_of_Use); commercial licences case-by-case, competitors can be refused (https://boardgamegeek.com/wiki/page/BGG_XML_API_Commercial_Use); registration + auth token now required (https://boardgamegeek.com/using_the_xml_api). Trademark: BGG logos require permission. IAP 3.1.1 still forces Pro upgrade via IAP (https://developer.apple.com/app-store/review/guidelines). Avoid: launch without BGG sync, manual + barcode only, add BGG later with licence + attribution, no scraped images.

**d) Fail case:** UK board games only $669.2M in 2025 (https://www.imarcgroup.com/uk-board-games-market) — and app WTP is UNVERIFIED, zero proven payer. OSS + $9.99 lifetime cannot fund Apple 15–30% + RevenueCat 1% + support. BGG owns data and can deny licence; weekly use = 4x/month唇 engagement, collection entry is one-and-done, leaderboards amuse once. 10 years of HN clones with no winner signals graveyard, not gap.

**Ranking: 2 > 1 > 3. Pick #1 TTRPG Campaign Memory — the only one that can pass review first time without fighting ICO/Families kids-compliance and GoHenry's regulated money moat.**

## Sources
https://developer.apple.com/app-store/review/guidelines
https://support.google.com/googleplay/android-developer/answer/9893335?hl=en-GB
https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-code
https://www.joonapp.io/
https://www.appbrain.com/appstore/joon-kids-adhd-chore-tracker/ios-1482225056
https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026
https://www.revenuecat.com/pricing
https://supabase.com/pricing
https://supabase.com/regions
https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/
https://company.wizards.com/en/legal/fancontentpolicy
https://boardgamegeek.com/wiki/page/XML_API_Terms_of_Use
https://boardgamegeek.com/wiki/page/BGG_XML_API_Commercial_Use
https://boardgamegeek.com/using_the_xml_api
https://www.gohenry.com/uk/pocket-money-chores
https://prod-mw.independent.co.uk/money/children-britain-england-cpi-b2991456.html
https://www.mumsnet.com/talk/_chat/5264469-how-much-pocket-money-do-your-kids-get
https://www.mumsnet.com/articles/lunch-money-for-school
https://www.imarcgroup.com/uk-board-games-market
https://www.marketreportsworld.com/market-reports/tabletop-role-playing-game-ttrpg-market-14722144
https://pricepertoken.com/pricing-page/model/openai-gpt-4o-mini
https://www.aimodelcalc.com/guides/openai-api-pricing
