# Nestling — UK Launch Pricing

**Owner:** pricing strategist · **Date:** 30 Sep 2026 · **Scope:** GB storefront, year 1
Every number carries a source URL. Unverifiable items are marked **UNVERIFIED**.

---

## Exec summary

1. **Ship Option A: £29.99/yr, annual-only, 14-day free trial, hard paywall.** Mid-pack against real GB apps (Tidy £24.99, Cozi £29.00, PointUp/Chore Boss £29.99, Chorsee £39.99, S'moresUp £79.99), and on-market against RevenueCat's $34.80 global median annual price. [RC](https://www.revenuecat.com/state-of-subscription-apps/)
2. **A hard paywall beats freemium, and the gap closes in retention.** D35 download-to-paid 10.7% (hard paywall) vs 2.1% (freemium) — but 12-month retention is 27% vs 28%. Gating costs nothing long-run. [RC](https://www.revenuecat.com/state-of-subscription-apps/)
3. **Don't add a £3.99/mo tier.** Higher-priced apps convert downloads→trial at ~2× low-priced ones (8.9% vs 4.4%); yearly-dominant apps earn 1.6× the D60 RPI of monthly-dominant ones ($0.46 vs $0.29). Option B models −30% year-1.
4. **Realistic year-1 net is ~£4,800 per 10,000 GB installs** at 2.5% install→paid (Western Europe median is 2.0%). Sanity check: £19.37 net per annual payer matches RevenueCat's Western Europe Y1 RLTV median of $26.64 ≈ £20. Plan around that, not £29.99.
5. **DMCC Act subscription rules go live January 2027** (brought forward 10 Aug 2026). Build reminder-notice, renewal cooling-off and in-app cancellation now — the CMA is fining (StubHub, drip pricing, June 2026) and investigating Adobe and Microsoft 365. [gov.uk](https://www.gov.uk/government/news/pm-starts-roll-out-of-everyday-fixes-on-the-cost-of-living-ending-rip-off-discounts-and-subscription-traps)

---

## 1. Competitor prices — GB, live App Store listings (30 Sep 2026)

All App Store figures scraped from `apps.apple.com/gb/app/id<id>` In-App Purchases sections on 30 Sep 2026.

| App | GB price | Unit | App ID / source |
|---|---|---|---|
| **Tidy: House Cleaning Schedule** | **£24.99/yr** | Family | 1564891793 |
| **Cozi Family Organiser** | **£29.00** Gold | Family | 407108860 |
| **PointUp** | **£2.99/mo · £29.99/yr** | Family | 6757280954 |
| **Chore Boss** | **£4.99/mo · £29.99/yr** | Family | 6475013233 |
| **Chorsee** | **£39.99/yr** | Family | 1611068600 |
| **Chores & Allowance Bot** | £9.99/mo · £17.99/6mo · **£39.99/yr** | Family | 629797415 |
| **Homey** | £6.99/mo · **£59.99/yr** | Family | 1033286805 |
| **S'moresUp** | £7.99/mo · **£79.99/yr** | Family | 1287367596 |
| **Joon** | 10 tiers all named "All Access": £9.99 / £12.99 / £13.49 / £41.99 / £44.99 / £79.99 / £85.99 / £139.99 / £159.99 — mapping **UNVERIFIED** | Family | 1482225056 |
| **OurHome** | from £1.99 | Family | 6753957205 |
| **HyperJar** | £0 (card spend) | Family | 1224672532 |
| **NatWest Rooster Money** | **£1.99/mo or £19.99/yr per card** | **Per child** | [roostermoney.com](https://roostermoney.com/gb/pricing-fees-and-limits/) |
| **GoHenry** | **£3.99/mo per child** Everyday · £5.99 Plus · £9.99/mo up to 4 kids Max | **Per child** | [gohenry.com](https://www.gohenry.com/uk/pricing/) |
| **nimbl** | **£32/yr** first card, £27/yr each additional | **Per child** | [nimbl.com](https://nimbl.com/pricing) |

**Read:** *Apps* cluster at **£24.99–£39.99/yr for the whole family**. *Financial products* charge **per child**, scaling to £48–£120/yr. That is the wedge: **one family price, unlimited children, £29.99** — cheaper than GoHenry at 2+ children, dearer than Rooster, cheaper than every gamified app except Tidy. Joon's ten undifferentiated tiers are a warning, not a model.

---

## 2. Benchmarks — RevenueCat State of Subscription Apps 2026

Source: [revenuecat.com/state-of-subscription-apps](https://www.revenuecat.com/state-of-subscription-apps/) (115,000+ apps, $16bn). Education is the closest proxy for family/kids; there is no Parenting category.

| Metric | Median | Relevance |
|---|---|---|
| D35 download→paid — hard paywall / freemium | **10.7% / 2.1%** | Our ceiling |
| D35 download→paid — **Western Europe, all apps** | **2.0%** | **Our realistic base** |
| Trial→paid — Western Europe | 29.7% | NA 34.2%, IN/SEA 15.2% |
| Trial→paid by duration — ≤4d / 5–9d / 17–32d | 25.5% / 37.4% / **42.5%** | 14d sits mid-to-top band |
| Day-0 trial cancels — 3d / 7d / **14d** / 30d | 55.4% / 39.8% / **35.7%** / 31.1% | 14d decent; 30d better |
| Download→trial — W. Europe / **Education** | 5.0% / **6.5%** | Education beats geo median |
| Download→trial by price point — high/mid/low | **8.9%** / 5.4% / 4.4% | **Kills a cheap monthly tier** |
| D60 RPI — hard paywall vs freemium | **$3.09 vs $0.38** (8×) | Gating pays for itself |
| D60 RPI — yearly- vs monthly-dominant | **$0.46 vs $0.29** | Annual wins |
| Y1 RLTV per payer — Western Europe | **$26.64** | ≈£20 ≈ our £19.37 ✅ |
| Median annual price | **$34.80** (2025: $31.60) | £29.99 ≈ $40 — at market |
| **Annual subscriber Y1 churn** | **~72%** (2025: ~56%) | 35% of annual cancels are Month 1 |
| Refund rate — most categories / hard paywall | 3–4% / 2.5% | WE P25–P75 2–8% |
| **Play billing-failure cancellations** | **31%** (App Store 14%) | Dunning is not optional |
| Reality check | Pre-2020 apps = 69% of revenue; 2025+ launches = 3%; only 4.6% reach $10k MRR in 2 yrs | 97th percentile of difficulty |

Also: 12-month retention is 27% (hard paywall) vs 28% (freemium). Education — our closest proxy, since there is no Parenting category — favours annual plans at 59–66% of revenue and shows $22.82 Y1 RLTV per payer.

**Judgment:** the draft price is right. The trial may be one notch short — 17–32 day trials convert 70% better than ≤4-day — but 14 days is the DMCC cooling-off sweet spot. Test upward; don't assume.

---

## 3. UK net proceeds

GB prices are **VAT-inclusive at 20%**; Apple and Google are merchant of record and remit it ([gov.uk](https://www.gov.uk/government/collections/vat-detailed-information), [Apple](https://developer.apple.com/help/app-store-connect/making-payments-to-apple/understanding-taxes)).
**Apple 15%** under the Small Business Program (≤$1M/yr; re-qualifies annually — no year-2 cliff) — [Apple](https://developer.apple.com/app-store/small-business-program/). **Play 15%** on auto-renewing subscriptions regardless of revenue — [Play Console](https://support.google.com/googleplay/android-developer/answer/112622). **RevenueCat** 1% above $2,500 MTR — never triggers. [pricing](https://www.revenuecat.com/pricing)

Net factor = ÷1.20 × 0.85 = **0.7083**. After 4% refunds and 5% residual billing loss → **0.6458**.

| Shelf price | Ex-VAT | Net proceeds | Net per payer |
|---|---|---|---|
| £24.99/yr | £20.82 | £17.70 | **£16.14** |
| **£29.99/yr** | £24.99 | **£21.24** | **£19.37** |
| £34.99/yr | £29.16 | £24.78 | £22.60 |
| £39.99/yr | £33.33 | £28.33 | £25.83 |
| £79.99 lifetime | £66.66 | £56.66 | £51.67 |
| £3.99/mo | £3.33 | £2.83 | £2.58/mo |
**Price points:** £24.99 / £29.99 / £39.99 are confirmed live GB subscription points (Tidy, Chore Boss, Chorsee above) in Apple's ~900-point grid ([Apple](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/)). **£34.99 as a GB point: UNVERIFIED** — confirm in App Store Connect before relying on Option C.

**Family Sharing:** enable it. Shareable subscriptions let up to 5 family members use one subscription free (seen on competitor listings). Our account *is* the family, so it adds value with no revenue leakage and kills the "does my partner need a second subscription?" objection.

---

## 4. Options — year-1 net revenue per 10,000 GB installs

**Shared assumptions (state them, don't hide them):** 10,000 GB installs, evenly spread. Install→paid base **2.5%** (2× Western Europe's 2.0% median; well under the 10.7% hard-paywall global median). Low 1.5%, high 5.0%. Refund 4%; residual billing failure 5% after basic dunning. Annual prepaid → revenue booked at purchase, so year-1 revenue = year-1 cohort only. Monthly payers average **2.5 paid months** (monthly churn is front-loaded).

| Option | Install→paid | Payers | **Year-1 net** | Verdict |
|---|---|---|---|---|
| **A. £29.99/yr only + 14d trial** | 2.5% | 250 | **£4,843** | ✅ **Winner** |
| B. £3.99/mo + £29.99/yr (55/45) | 2.5% | 250 | **£3,395** | ❌ −30% |
| C. £24.99/yr intro → £34.99 | 3.0% | 300 | **£4,842** | ⚠️ Ties A in Y1 |
| D. Freemium (1 child) + Family £29.99 | 2.1% | 210 | **£4,068** | ❌ −16% |
| E. A + £79.99 lifetime (25% take) | 2.5% | 250 | **£6,898** | ⚠️ Front-loads, then dead |

Ranges at 1.5% (low) and 5.0% (high) install→paid: A £2,906–£9,687 · B £2,037–£6,790 · C £2,906–£9,686 · D £2,325–£8,137.

**B loses** because a cheap monthly tier *reduces* trial starts (4.4% vs 8.9%) and monthly-dominant apps earn 1.6× less D60 RPI. Holding annual at 55% of the same 2.5% is already generous to B.

**C ties A in year 1 and is the best 2-year number** (£6,741 vs A's £6,199, since renewals happen at £34.99). Rejected for now: raising price on an existing customer spikes refunds and sits badly against DMCC anti-drip-pricing and active CMA enforcement. Revisit in year 2 with a clean slate.

**D is the only strategic argument** — freemium builds the word-of-mouth flywheel we need for school/PTA and Mumsnet distribution (RevenueCat concedes freemium is right "when free users drive word of mouth"). It costs £775/yr. Keep as the Step-3 counter-test.

**E flatters year 1 by ~£2,000, then gives up ~£340/yr of recurring.** Lifetime is a retention hedge, not a growth engine — 1 in 4 apps offer it and it is the lowest-RPI model ($0.24 D60). Defer.

**Downgrade to prior research:** `docs/research/` assumed "8 months average paid". RevenueCat 2026 says ~72% annual Y1 churn — that alone roughly halves year-1 estimates.

---

## 5. Recommendation

**Launch Option A — £29.99/yr, annual-only, 14-day free trial, hard paywall at P07, Family Sharing on.**

Frame as **"£2.50 a month, billed yearly"** with the £29.99 total equally visible (RevenueCat saw trial starts +30% anchoring yearly to its monthly equivalent). Test 30 days later rather than assuming.

| Offer | Detail | Why |
|---|---|---|
| Win-back, Month 1 | 50% off one year, days 21–35 after cancel | **35% of annual cancels happen in Month 1** — highest-ROI message we will ever send |
| PTA / school codes | 100 codes × 75% off, 90-day redemption, tracked per school | Cheapest CAC available |
| Christmas gifting | Annual as the gift unit; landing page + code from 1 Dec | Fills the pre-Christmas dip; Jan is the real spike |
| Renewal reminder | Email (durable medium) day 21 and day 365, from `noreply@mail.getnestling.co.uk` | DMCC requires one per 6 months anyway |
| Play dunning | Retry logic + grace period | 31% of Play cancellations are billing errors. **Build before launch** |

### 3-step price-test plan

Sample basis: two-proportion test, α=0.05, power 80%, baseline trial→paid 30%, MDE 25% relative (→37.5%) = **622 trial starts/arm**. At a 6% trial-start rate that is **~10,400 installs/arm** — full price resolution is a year-1-*end* problem, not a launch problem.

| Step | Window | Test | Primary metric | Success metric |
|---|---|---|---|---|
| **1** | Days 0–30, ~3,000 installs | **Trial length 14d vs 30d** (Subscription Group change, no app release); price fixed | **Trial start rate** | ≥10% relative lift in trial starts, D14 trial→paid flat-or-up, no rise in Day-0 cancels. *Directional only on trial→paid at this n* |
| **2** | After ≥1,250 trial starts | **£24.99 vs £29.99** — 2 arms only, not 3 | Trial→paid, then **net revenue per install** | Higher price wins if net revenue/install is flat-or-better. Ship £34.99 only if £29.99 ≥ £34.99 |
| **3** | Month 4–6 | **Paywall framing** (monthly-equivalent anchor vs plain price; trial-timeline visibility) + **win-back** on the lapsed cohort | Trial start rate; win-back reactivation | +10% trial starts; ≥8% of Month-1 cancellers reactivate |

Tooling: RevenueCat Experiments + Remote Config arm assignment at install. **Kill criterion, agreed now before the data arrives:** if GB trial→paid < 1.5% **or** net year-1 revenue per 10,000 installs < £3,000 at month 9, pricing is not the problem — product or channel is. Stop tuning price.

---

## 6. Compliance — UK subscription law

**Regime:** DMCC Act 2024 Pt 4 Ch 2. **Commencement brought forward to January 2027** by the PM on 10 Aug 2026 — [gov.uk](https://www.gov.uk/government/news/pm-starts-roll-out-of-everyday-fixes-on-the-cost-of-living-ending-rip-off-discounts-and-subscription-traps), [TLT](https://www.tlt.com/insights-and-events/insight/dmcc-act-subscription-contracts-regime-brought-forward-by-the-pm-what-do-businesses-need-to-know). DBT's April 2026 Government Response confirms **no change to requirements**, only timing. Secondary legislation is still unpublished — build to the statute, not the guidance. [DMCCA Pt 4 Ch 2](https://www.legislation.gov.uk/ukpga/2024/13/part/4/chapter/2)

| Requirement | Nestling action | Spec status |
|---|---|---|
| **Key pre-contract info**, together at purchase: recurring liability, payment frequency, **monthly cost**, **minimum total payable**, reminder timing | P07 must show £29.99/yr, "£2.50 a month", "minimum payment £29.99", "we'll email a reminder at least every 6 months" | ⚠️ **Add all five** |
| **Express acknowledgement of payment obligation** as the final step | Separate tappable consent line above the CTA, not buried in T&Cs | ⚠️ **Build** |
| **14-day renewal cooling-off** after the first post-trial payment, and after any renewal onto a 12+ month term | Our 14-day trial *is* this window — it runs from day 14, not day 0 | ⚠️ **Add post-billing notice** |
| **Reminder notice** ≥ once per 6 months, in writing on a **durable medium** | Email qualifies, sent from `noreply@mail.getnestling.co.uk` via Resend. **In-app toasts do not** (not storable/reproducible) | ⚠️ **Email, not push** |
| **Proportionate refund** on renewal cooling-off, average cost per day | Partial-year refunds; no usage-based model | ⚠️ **Build** |
| **Easy exit**: cancel online in the signup medium, not hidden, no extra steps, no feedback gauntlet | Settings → "Manage subscription" → store, plus a real `support@getnestling.co.uk` address. No email-only, no DD-cancel-only | ✅ P16 has the row — verify depth |
| **No terms making cancellation disproportionately difficult**; **price transparency** (total, frequency, duration) | No notice periods, no "are you sure" loops, no drip, no fake urgency | ✅ P07 already clean (spec §5: no countdown, no scarcity) |

**In force now, not waiting for 2027:** Consumer Contracts Regulations 2013 cooling-off and Consumer Rights Act 2015 unfair-terms rules. The CMA issued its **first DMCCA fine in April 2026**, **fined StubHub for drip pricing in June 2026**, and has investigations open into **Adobe** (exit fees) and **Microsoft 365** (misleading auto-renewal). Also live: ICO Children's Code (kid mode has no ads, no child data, parental gate) and Apple 5.1.4(b) — store copy speaks to parents, never "for kids".

**Before submission:** put the five key pre-contract facts plus the express acknowledgement onto P07 as designed copy, and confirm the support address reaches a human.

---

**Sources:** [RC SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps/) · [RC 10-min](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026) · [Apple SBP](https://developer.apple.com/app-store/small-business-program/) · [Apple pricing](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/) · [Apple taxes](https://developer.apple.com/help/app-store-connect/making-payments-to-apple/understanding-taxes) · [Play fees](https://support.google.com/googleplay/android-developer/answer/112622) · [gov.uk VAT](https://www.gov.uk/government/collections/vat-detailed-information) · [DMCC commencement](https://www.gov.uk/government/news/pm-starts-roll-out-of-everyday-fixes-on-the-cost-of-living-ending-rip-off-discounts-and-subscription-traps) · [TLT briefing](https://www.tlt.com/insights-and-events/insight/dmcc-act-subscription-contracts-regime-brought-forward-by-the-pm-what-do-businesses-need-to-know) · competitor App Store GB listings cited inline · prior research `docs/research/`
