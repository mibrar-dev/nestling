# UK Market & Compliance Analysis — Sub-Agent 1/2

**All iTunes/GBP figures below fetched live from the GB storefront, 30 Sep 2026. Web search was unavailable this session; everything is sourced from live API/store/regulator pages, or marked UNVERIFIED.**

## Scorecard

| Idea | UK demand | UK competition gap (10=open) | Compliance burden (10=trivial) | Monetisation | Solo-dev reachability | Total |
|---|---|---|---|---|---|---|
| 1. Chore & Allowance | 8 | 4 | 2 | 8 | 7 | 29 |
| 2. TTRPG Campaign Memory | 5 | 5 | 8 | 5 | 4 | 27 |
| 3. Board Game Companion | 6 | 3 | 9 | 2 | 5 | 25 |

---

## 1. Family Chore & Allowance Gamification

**Competitors the US report missed.** The UK market is dominated by *regulated*, not consumer, products. **NatWest Rooster Money** (World Learning Ltd) — 4.68★, 11,260 GB ratings, priced **£19.99/yr**, with a free "Virtual Tracker" tier that already does star charts and chores ([roostermoney.com/pricing](https://www.roostermoney.com/)). **GoHenry** 4.52★/40.5k ratings; **HyperJar** 4.75★/31.3k; **nimbl** 4.65★/3.3k; **Revolut Teen** 4.79★/31.7k. These own the *money*, not the ritual — but they prove UK parents will pay ~£20/yr in this exact category. **Cozi Family Organiser** 4.7★/22k GB ratings, 4+, IAP **Cozi Gold £29.00/£39.00/£49.99/£59.99, Cozi Max £79.99, 1-yr Gold £29.99**. A live GB review reads: *"£20 first year and then £39 a year after. Nope… won't pay that greedy amount."* **Joon is rated 13+ on the GB store** (4.5★, only **449** GB ratings) with All Access at £9.99–£159.99 — it is *not* in Kids Category and is barely visible in the UK. What they all lack: nobody in the UK combines deep chore tracking with gamification for under-13s. UNVERIFIED: I could not confirm Joon's exact current GB tier mapping.

**Demand.** ONS: 19.5m UK families (2023). Mumsnet's Chats/Chat boards are the realistic channel; Dedupe-style family-account acquisition is the standard play (UNVERIFIED for exact conversion). Seasonality is real and favourable: school-year routines drive Sept–Oct and Jan–Mar.

**Compliance — the heaviest of the three.** ICO Children's Code (15 standards, in force since 2 Sep 2021, applies to services "likely to be accessed by children" regardless of targeting) demands a DPIA, high-privacy defaults, data minimisation, no nudge techniques, parental controls ([ico.org.uk](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/)). Apple Kids Category (1.3) bars links-out, purchasing and distractions outside a parental gate. Google Play Families requires declared target audience, no AAID/IMEI transmission for child-directed apps, Families self-certified ad SDKs only, no interest-based ads. **Cost: ~3–5 weeks of extra build + compliance QA**, and it forecloses most analytics/ads SDKs. FCA/PSR: **avoid moving real money** — Rooster's model is a card issued by a bank, not an app. Keep allowance purely informational.

**Pricing & revenue.** £24.99/yr annual-only, hard paywall after 14 days. Assumptions: 25k UK downloads Y1, 4% trial→paid = 1,000 subs, £24.99 × 0.85 store cut = **≈ £18,000** net. Range £12k–£30k.

---

## 2. TTRPG Campaign Memory

**Competitors.** The US report's "unsolved" claim is overstated but not wrong. **D&D Beyond** (Wizards) 4.7★/8.5k GB ratings, 9+ with In-App Controls, IAP **Master Monthly £4.99, Hero Monthly £2.49, Master Annual £46.99, Hero Annual £21.99** — this is the proven UK price ceiling for TTRPG tooling. Direct rivals are near-dead: **RPG Notebook** 4.2★/6 ratings (£4.99), **SessionKeeper** 1★/1 rating, **DnD Campaign Notes** 0 ratings, **Quest Portal VTT** 4.25★/24. **PrismScroll: 5e Companion** 4.74★/239 ratings. The gap is real but so is the evidence that solo devs who build this don't get paid.

**Demand.** UKGE drew **87,837 attendees** at Birmingham NEC, 900+ exhibitors, 4,000+ open gaming seats, next edition 4–6 June 2027 ([Wikipedia](https://en.wikipedia.org/wiki/UK_Games_Expo)). That proves a large, concentrated, spend-happy UK hobby audience — and gives you a three-day concentrated acquisition window each June. But a TTRPG-campaign-notebook buyer is a *sub-segment* of that 87k, and heavily Discord-over-UKIE. UNVERIFIED: total UK TTRPG player count.

**Compliance — the lightest.** Adult-skewing users. No Children's Code exposure, no Kids Category, no Google Families targeting. D&D Beyond sets the precedent at 9+. AI disclosure under App Review 1.2 applies but is a labelling change, not an architecture change. **Cost: ~0.5 week.** The real risk is not regulatory — it's hallucinated campaign facts destroying trust, which is a product problem, not a compliance one.

**Pricing & revenue.** £4.99/mo / £34.99/yr. Assumptions: 3,000 UK downloads, 3% paid = 90 subs, £34.99 × 0.85 = **≈ £2,700** gross before AI inference costs; net realistically **≈ £1,200–£1,800**. Range £500–£2,500.

---

## 3. Board Game Night Companion

**Competitors — the US report is wrong here.** **Board Game Stats** already ships collection tracking, play tracking, per-player win statistics, graphs, offline mode, and **BoardGameGeek sync** at **£4.99**, 4.8★, 81 GB ratings. That is precisely idea #3's pitch. Also live in GB: **RoundsKeeper: Game Scorekeeper** (£2.99, June 2026), **GameShelf: Board Game Tracker**, **Board Game Scanner: BGG Sync** (Aug 2026), **Logg: Game Tracker** 4.74★, **Score Anything** 4.89★/105, **GameScore** 4.73★/64 (last updated 2020). A cheap, competent field already exists and updates in 2026.

**Demand.** Same UKGE gravity plus a large café/pub scene, but board gaming is more family/casual and far less Discord-obsessed — the report's community reach thesis transfers poorly. The "no BGG sync in v1" scope choice means you arrive with *less* than the incumbent on day one.

**Compliance — the lightest of all.** Adult audience, no Children's Code, no child-directed data, no Kids Category, no Google Families. **Cost: ~0.5 week.** Apple 3.1.1 forces IAP for the Pro unlock, and Barcode scanning needs a camera permission rationale only.

**Pricing & revenue.** £4.99 one-time Pro. Assumptions: 15,000 UK downloads, 2.5% Pro = 375 sales × £4.99 × 0.85 = **≈ £1,600**. Range £300–£2,000. The OSS-plus-donation route produces reputation, not income. UNVERIFIED: any UK WTP evidence — none found.

---

**Ranking: 1 > 2 > 3. Pick #1, Family Chore & Allowance — it is the only one where UK parents are demonstrably already paying for this exact category (Rooster £19.99/yr, Cozi Gold £29–£39, Joon All Access to £159.99) while the single strongest US player, Joon, is stranded at a 13+ rating with 449 UK ratings, leaving the gamified under-13s chore board empty — worth the ~4 weeks of Children's Code and store-policy build cost.**
