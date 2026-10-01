# Nestling — UK Go-to-Market Plan

> Working context: `docs/DESIGN_SPEC.md`, `docs/research/*.md`, `design/store/*`. App: family chores + pocket-money **ledger** (no money movement) with pet chick Pip; parent pays **£29.99/yr** (14-day trial draft); child plays; no ads; data in UK (London).

## Exec summary

- **Positioning:** the anti-bank pocket-money app — *chores they actually want to do, money you can actually track*, for £29.99/yr vs GoHenry £47.88+/yr/child and Rooster Card £19.99–24.99/yr — ledger-only so no FCA rails, no card to lose.
- **Who first:** UK parents of 5–11s drowning in nagging; ADHD/neurodivergent families as high-need niche via charities (ADHD UK, ADHD Foundation, ADHD Embrace), never via targeted ads to children.
- **Where to win as a solo founder:** Mumsnet/Reddit/school newsletters + parenting micro-creators + Search Ads; skip Netmums paid (from £10k) and broad paid social until trial→paid ≥2.5% is proven.
- **Compliance is the moat:** speak only to parents, never put "for kids" in metadata (Apple 2.3.8), honour CAP Code §5 (no direct appeal/pester power) and the ICO Children's Code (no child data for targeting).
- **90-day bet:** launch for back-to-school Sept; target UNVERIFIED 1,500–2,500 trials, ≥2.5% trial→paid, CPI ≤£2.50 (Search) / ≤£1.50 (Meta/TikTok test); kill/scale decision at day 90.

---

## 1) Positioning

**Statement:** For UK parents of 5–11s who nag about jobs and lose track of pocket money, Nestling is the family-quests app that turns jobs into quests children choose to do — with Pip the chick, a fair ledger, and no bank card, no ads, no money movement.

**3 selling points (with proof):**

1. **Nagging → choosing.** 40+ ready quests ("Put the bins out", "Hoover the stairs"), approvals with kind "Not yet", Pip evolves at milestones. Proof: store hero copy already tests "Chores they actually want to do" (`design/store/.../01-hero.png`); competitor Joon has only 449 GB ratings vs 6,559 US — UK game-layer gap is open ([lookup](https://itunes.apple.com/lookup?id=1482225056&country=gb), [AppBrain](https://www.appbrain.com/appstore/joon-kids-adhd-chore-tracker/ios-1482225056)).
2. **Pocket money, sorted — without a card.** Ledger with payout day, savings goals, "Mark as paid"; you pay cash/bank your way. Proof: Rooster kids earn £9.74/wk avg 2026 ([Index hub](https://roostermoney.com/pocket-money-index-hub)) yet only ~30% get regular money ([BBC Newsround](https://www.bbc.co.uk/newsround/articles/cyvmd48rr9zo)) — ad-hoc ledger fits reality; GoHenry is £3.99–£5.99/mo per child ([pricing](https://www.gohenry.com/uk/pricing)), Rooster Card £24.99/yr + £19.99 extra ([fees](https://roostermoney.com/pricing-fees-and-limits-v1-1)) — Nestling £29.99/yr covers the whole family.
3. **Privacy parents can defend.** Nickname + age band only, no child email/photos/chat/location/ads, UK hosting, parental gate. Proof: spec §1/§P04; maps to ICO Children's Code high-privacy-by-default ([ICO intro](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/introduction-to-the-childrens-code)) and Apple 1.3/5.1.4 (no third-party ads/analytics in kid flows) ([guidelines](https://developer.apple.com/app-store/review/guidelines)).

**Objections:**

- *"Chores should be unpaid / family life."* Agree — and say so. Position base duties as "family jobs" (no coins) vs paid "extra quests"; cite real Mumsnet resistance ([example](https://www.mumsnet.com/talk/teenagers/5255593-pocket-money-and-chores)). Copy: "Some jobs are just family. Nestling lets you mark which — and reward the rest."
- *"We already use Rooster/GoHenry."* "Keep the card; add the game." They own money movement; none owns pet + quests + annual GBP game layer. Nestling complements cards; costs less than one GoHenry child-month × 12.
- *"More screen time?"* 2-minute loop: do job offline → tap done → feed Pip. No feeds, no streak-shame, no loot boxes. "Less nagging, not more scrolling."

## 2) ICP / personas

**Primary — "Nag-tired Sarah", 32–44, mum of 2 (5–11), South East/London commuter belt.** Pays £3–5/wk pocket money ad-hoc (Mumsnet norm UNVERIFIED from threads e.g. [here](https://www.mumsnet.com/talk/_chat/5264469-how-much-pocket-money-do-your-kids-get)); tried star charts; fears fintech cards getting lost. Buys on Mumsnet/WhatsApp recommendation, back-to-school. Message: calm, fair, tidy.

**Secondary — "Co-parent James", 35–45.** Wants ledger truth ("owed £4.20, payout Sat") and co-parent sharing. Buys on fairness + price.

**Niche (strong) — ADHD/neurodivergent families.** Visual steps, immediate coins, kind approvals and Pip routine suit executive-function support — but never claim therapy. Sensitive route only: resources + lived-experience creators, charity links, opt-in. UK landscape: [ADHD UK](https://adhduk.co.uk) (parent Facebook groups, support letters), [ADHD Foundation](https://www.adhdfoundation.org.uk) (UK's leading neurodiversity charity per listings), [ADHD Embrace](https://adhdembrace.org) (20 yrs, parent/carer + schools), plus [YoungMinds parents guide](https://www.youngminds.org.uk/parent/parents-a-z-mental-health-guide/adhd) and [Contact](https://contact.org.uk) for families. Approach: offer free family licences to support groups, ask for feedback not endorsements, no diagnosis language, no child targeting. Reach via charity newsletters/communities only with permission — UNVERIFIED response rates.

Out of scope v1: under-5s, teens wanting real cards/Apple Pay (13+), schools (safeguarding overhead).

## 3) Messaging

**Taglines (pick one lead):** "Chores they actually want to do." / "Pocket money, without the faff." / "Family jobs, finished with a smile." / "Pip grows when they help."

**App Store (UK spelling; parent-directed; no "for kids" anywhere — Apple 2.3.8):**

- Title (23/30): `Nestling: Family Quests`
- Subtitle (28/30): `Chores, coins & pocket money`
- Keywords (82/100, no spaces): `chores,quests,habits,routine,pocket,money,ledger,allowance,family,reward,chart,pip`
- Notes: description + screenshots speak to "parents/families", never "your kids will love"; promo text (170 chars) for seasons, e.g. back-to-school. Limits per [metadata refs](https://appscreenshotstudio.com/tools/app-store-indexed-fields) ([Apple](https://developer.apple.com/app-store/review/guidelines)).

**Google Play:**

- Short description (62/80): `Family chore quests with Pip. Pocket money ledger for parents.`
- Avoid "free / no ads / #1 / best / download now" in short desc per [Play guidance](https://support.google.com/googleplay/android-developer/answer/13393723?hl=en) ([limits](https://playaudit.app/blog/google-play-listing-requirements)). Full description carries "no ads, no money movement, UK data" proof.

## 4) Channels (ranked: solo-founder CAC/feasibility)

1. **Mumsnet Talk (organic, £0).** 8m monthly reach, 1 in 2 UK households with <19s, 25k posts/day ([Media Kit 2026](https://static1.squarespace.com/static/650c32f7fd7986310556f3ce/t/6a0b2c544e93492343da5913/1779117141098/Mumsnet+Media+Kit+2026+-+Mumsnet+Advertising.pdf)). Rules: no spam/ads; fundraising only for registered charities; follow [Talk Guidelines](https://www.mumsnet.com/i/netiquette). Tactic: answer chore/pocket-money threads as a parent-founder, disclose, never drop links unasked. Paid Mumsnet Rated/Tested is effective but £££ — defer. UNVERIFIED: time-heavy, highest trust.
2. **School/PTA newsletters + WhatsApp (near-£0).** Offer "Back-to-school jobs chart" PDF + QR; PTA donation per trial (e.g. £1). Feasibility high; CAC £0–1 UNVERIFIED.
3. **Reddit UK (organic).** r/UKParenting (supportive UK space, small vs r/Parenting 5m+) ([r/UKParenting](https://www.reddit.com/r/UKParenting)), r/UKPersonalFinance for money angle, r/ParentingADHD (34k) for niche learning. No self-promo; AMA with mods, disclose founder. CAC £0.
4. **Parenting TikTok/Instagram micro-creators (5–50k).** Best creative/CAC lever. Brief: parent speaks to parents, home chaos, Pip payoff. **ASA/CAP:** `#ad`/`Ad:` upfront before any text, plus platform Paid-Partnership toggle (toggle alone insufficient); verbal + on-screen for video; each carousel item labelled ([Kolsquare 2026](https://www.kolsquare.com/en-gb/blog/the-complete-guide-to-influencer-post-disclosure-uk-rule), [GOV.UK creator guidance](https://www.gov.uk/government/publications/social-media-endorsements-guidance-for-content-creators/social-media-endorsements-being-transparent-with-your-followers), [ASA 2024 report](https://www.asa.org.uk/news/influencer-ad-disclosure-on-social-media-instagram-and-tiktok-report-2024.html)). Gifted = ad if brand controls content. Budget £50–150 + free annual per post UNVERIFIED.
5. **Facebook parent/ADHD support groups.** Join, help first, admin permission only; no scraping. ADHD UK parent groups ([support](https://adhduk.co.uk/support)) strictly permissioned.
6. **Apple Search Ads (UK).** Highest intent. UK CPT ~$1.31, median CPI ~$1.80 cross-category ([Adapty](https://adapty.io/apple-ads-for-subscription-apps), [AppTweak](https://www.apptweak.com/en/aso-blog/apple-ads-benchmarks)); UK index ~72 vs US 100 ([MBAdv](https://www.mbadv.agency/apple-ads/how-much-do-apple-ads-cost)). Start exact-match "pocket money chores / chore chart / star chart". CAC £1–3 UNVERIFIED.
7. **Google App Campaigns.** Volume workhorse; CPI $1.50–4.50 typical, finance/competitive $5–10 ([Adapty playbook](https://adapty.io/blog/google-app-campaigns-playbook-2025)), blended ~$2.41 ([DigitalApplied](https://www.digitalapplied.com/blog/mobile-app-marketing-statistics-2026-install-data)). Needs 50× CPI daily budget to learn — solo-founder unfriendly early. Test only after paywall converts.
8. **Netmums (defer paid).** Trusted but packages from £10k / 5k views ([overview PDF](https://advertisements.netmums.com/wp-content/uploads/netmums-advertisements/2024/08/netmums-overview-and-opportunities-2023.pdf)); organic Coffee House possible with disclosure. Not for £0–2k/mo.
9. **PR + seasonal.** Money-saving angle ("pocket-money ledger without a £48/yr card"). Newsjack **Rooster Pocket Money Index** — annual, mid/late June (16 Jun 2025 ([NatWest](https://www.natwestgroup.com/news-and-insights/news-room/press-releases/financial-capability-and-learning/2025/jun/annual-natwest-rooster-money-pocket-money-index-reveals-industri.html)); 30 Jun 2026 10th edition ([NatWest](https://www.natwestgroup.com/news-and-insights/news-room/press-releases/financial-capability-and-learning/2026/jun/mow-money-no-problems-great-out-chores-boost-kids-pay-packets-ac.html)), data Mar–Feb ([hub](https://roostermoney.com/pocket-money-index-hub)). Pitch early June + January habits + back-to-school Sept + Christmas gifting (grandparents gift annual). Solo tactic: 20 local press + parenting journalists, founder story + stat.

## 5) Compliance (marketing)

- **CAP Code §5 / ASA:** under-16 is "child". No direct exhortation to buy or pester-power ("ask Mum to buy Nestling"), no undermining parents, no unsafe emulation; even parent-targeted ads must be socially responsible if seen by children ([Targeting advice](https://www.asa.org.uk/advice-online/children-targeting.html), [Code](https://www.asa.org.uk/codes-and-rulings/advertising-codes/non-broadcast-code.html), [Taylor Wessing summary](https://www.taylorwessing.com/fr/interface/2020/protecting-children-in-the-online-and-social-media-age/advertising-and-marketing-to-children)). All claims substantiated; price "£29.99/yr after 14-day trial" upfront.
- **ASA app precedent:** use platform age-gating tools properly — ASA has upheld where advertisers failed to use them ([Lewis Silkin](https://www.lewissilkin.com/insights/2026/03/25/digital-commerce-creative-101-key-issues-when-targeting-ads-for-age-restricted-products-age-gating)). Target 25+ parents, exclude <18, family-safe placements only.
- **Children's Code → marketing:** applies if likely accessed by <18s ([ICO](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services)); 15 standards ([TrustArc](https://trustarc.com/resource/uk-age-appropriate-design-code)). For marketing: **never use child data for targeting/profiling** (profiling off by default), no behavioural ads to children, no nudge-to-share, DPIA before launch, age-assurance via parent-account-only. Landing + ads pixel only on parent surfaces; no SDKs in kid flow.

## 6) 90-day launch plan, budgets, KPIs, referral

**Plan (Sept back-to-school anchor):**

- W1–2: TestFlight + Play closed; landing + press kit live; 5 Mumsnet/Reddit answers/wk; recruit 10 micro-creators (gifted annual, #ad brief).
- W3–4: Public launch; Apple Search Ads £20/day exact; PTA PDF to 30 schools; first creator posts; fix paywall friction.
- W5–8: Double what trials (creators/PTA/Search); ship referral; pitch Christmas-gift press early; ADHD charity feedback round (no paid claims).
- W9–12: Cut losers; scale winner 2×; Jan-habits waitlist; decision: scale / iterate / kill.

**Budgets/mo:**

- £0: organic only; ~200–600 trials/mo UNVERIFIED; cost = time.
- £500: £300 Search Ads + 3–4 creators + £50 tooling; ~400–900 trials UNVERIFIED.
- £2,000: £1,000 Search + £500 Meta/TikTok test + 8 creators + PR freelancer half-day; ~1,500–3,000 trials UNVERIFIED.

**KPIs:** CPI (Search ≤£2.50, social test ≤£1.50 UNVERIFIED targets); trial-start rate (store→trial ≥15% UNVERIFIED); trial→paid ≥2.5% (kill <2% at 1,500 trials per research); D30 retention + renewal intent; payback: £29.99 × 0.7 net ≈ £21 → need CPI × (1/trial%) × (1/paid%) < £21.

**Referral:** "Give a friend a free month, get one." Parent-gated link, giver gets 1 mo credit on renewal, receiver 30-day (not 14-day) trial; capped 6 mo/yr; no child-visible incentives; fraud: one per family, Apple/Google-compliant (no cash).

## 7) Launch assets checklist + 30s demo script

**Checklist:** landing (parent hero, pricing, privacy/UK-data, FAQ objections, press-kit link); press kit (founder story, 3 stats, 8 screenshots, Pip art, logo); store listings (titles above, UK screenshots, 4+ rating-safe imagery); PTA one-pager; creator brief with #ad rules; DPIA + privacy notice ([getnestling.co.uk/privacy](https://getnestling.co.uk/privacy)) + terms ([getnestling.co.uk/terms](https://getnestling.co.uk/terms)) + support inbox (`support@getnestling.co.uk`, public alias `hello@getnestling.co.uk`).

**Demo video (30s):**

> [0–5s: frazzled kitchen, text "Tea-time jobs… again?"] Mum (V/O, warm British): "Jobs used to mean nagging." [6–12s: taps "Put the bins out +15", Pip hatches] "Now we set a quest in seconds." [13–20s: child ticks "I did it!", Mum approves, coins fly, Pip grows] "They do it. I thumbs-up. Pip grows." [21–26s: ledger "£4.20 owed · Payout Sat", savings bar] "Pocket money stays fair — no card needed." [27–30s: logo + "Nestling: Family Quests — 14-day free trial, £29.99 a year. No ads, ever."] End card: QR + "For parents."

---
*Word count ~1,900. UNVERIFIED = founder assumption or vendor benchmark, not Nestling data. Verify CPI/trial→paid in weeks 1–4 before scaling paid.*
