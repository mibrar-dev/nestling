[0m
> build · muse-spark-1.3-contributor-free
## Score table (1-10, 10 = best)

| Idea | Build feasibility | Store-approval safety | Unit economics | Retention durability | Founder-skill fit | Mean |
|---|---|---|---|---|---|---|
| 1. Family Chore & Allowance | 4 | 3 | 7 | 5 | 8 | 5.4 |
| 2. TTRPG Campaign Memory | 5 | 7 | 4 | 6 | 9 | 6.2 |
| 3. Board Game Night Companion | 8 | 9 | 3 | 5 | 7 | **6.4** |

Higher = easier / safer / better. Judged for UK solo part-time launch, first-time pass + must make money.

---

### 1. Family Chore & Allowance Gamification (~210 words)

**a) v1:** Screens: parent onboarding + consent, RevenueCat paywall, family board, quest builder, kid mode (quests + pet + coins), weekly payout ceremony, settings/data-delete. Stack: `go_router`, Riverpod, `supabase_flutter`, `purchases_flutter`, Rive for pet, `local_notifications`. Backend: Supabase Auth + Postgres RLS (families/quests/completions/wallets) + Storage. No real-money rails — allowance is virtual promise only. Paywall: annual-only ~£44.99/yr after 14-day trial, parent-gated. AI cost: **£0–£0.10/active/mo** if no LLM; static pet + rules engine. Any per-quest LLM praise pushes to ~£0.30.

**b) Build: 12–16 weeks** part-time. Hardest: (1) dual parent/kid UX + approve/anti-cheat flow, (2) pet progression content that survives week 3, (3) family multi-device sync + offline + parental gate done right.

**c) Rejection:** Do NOT tick Kids Category — it bans third-party analytics/ads and invites scrutiny. Position as parent productivity (4+, not "made for kids"), add parental gate on paywall/payout/settings, zero ads, zero third-party SDKs, privacy policy + data-delete, UK Age Appropriate Design Code compliance. Guideline 3.1.1: real-money allowance via IAP = reject + FCA trouble; keep payouts offline. Play Families policy + Data safety form applies if under-13 appeal.

**d) Red-team:** Fails on retention + CAC. Joon's "$49.99 proven WTP" is a Launch HN vendor claim, not audited revenue. Kids love pet for 10 days, then labour falls on mum to invent quests. UK pocket-money culture is weaker than US allowance. "Parent buys, kid uses" = parent pays but kid churns = refund/1-star.

### 2. TTRPG Campaign Memory (~200 words)

**a) v1:** Screens: campaigns, session editor, entity cards (NPC/quest/loot), timeline, "what do we know about X?" search. Stack: `super_editor`/`flutter_quill`, `supabase_flutter`, `purchases_flutter`. Backend: Supabase + pgvector + Edge Function calling Haiku/4o-mini for extraction + embeddings. Paywall: free 1 campaign/50 entities, then ~£4.99/mo or £39.99/yr via RevenueCat. AI cost: **£0.70–£1.80/active/mo** at weekly play (5k-token session + extraction + ~10 Q&As on mini-class models); flagship models = £3+ and kill margin.

**b) Build: 10–12 weeks.** Hardest: (1) alias/dedup ("Innkeeper's daughter" = "Elsa" = "she"), (2) RAG without hallucinating canon — trust dies after one false NPC, (3) fast offline editor at the table + post-session sync.

**c) Rejection:** Relatively safe. Must disclose AI content, add report/block for AI output, keep human-verify ("suggest, don't apply"). IP: no SRD blocks, no "D&D/Dungeons & Dragons" in title, screenshots or keywords; user-entered IP is user's, but provide takedown path. 5.1.1: minimal data, export/delete.

**d) Red-team:** Tiny UK TAM. Only the DM pays; 4–6 players free-ride. Weekly frequency cannot carry £5/mo — campaigns pause, groups die, winter churn. Table Canon's 4pts/2 comments is not "early", it's no-demand signal. WTP for books/dice ≠ WTP for SaaS notes. Obsidian + Discord already good enough.

### 3. Board Game Night Companion (~190 words)

**a) v1:** Screens: collection, add via barcode/BGG search, night setup, live pass-and-play scores, per-game win/loss + leaderboards, Pro paywall. Stack: Drift (offline-first), `mobile_scanner`, `purchases_flutter`, `fl_chart`. Backend: local-first + optional Supabase sync; BGG XML API2 only via cached proxy Edge Function. Paywall: free + £9.99 one-time Pro (or £14.99/yr if you want LTV). AI cost: **£0.**

**b) Build: 6–8 weeks**, shortest. Hardest: (1) BGG throttling/flaky XML + barcode-to-BGG matching, (2) generic scorer covering 1,000s of scoring systems without per-game code, (3) offline pass-and-play that is instant with greasy fingers.

**c) Rejection:** Safest of the three. Risks are BGG terms + trademarks, not Apple. Cache BGG, respect rate limits, attribute "Data: BoardGameGeek", no scraping. Don't use Catan/Ticket to Ride art or names in title/subtitle/keywords; text-only game names user-entered is fine. No kids, AI, or IAP traps.

**d) Red-team:** Fails on money, not build. Monthly reality, not weekly; paper/Notes is free and good enough. Zero WTP evidence — report admits Etsy/Gumroad blocked. £9.99 one-time never repays UK CAC; OSS path = stars, not rent. BGG indifference is worse than competition: nobody cares enough to switch.

---

**Ranking: 3 > 2 > 1. #1 pick: Board Game Night Companion — it is the only one a solo dev ships store-safe in weeks with £0 marginal cost.**
