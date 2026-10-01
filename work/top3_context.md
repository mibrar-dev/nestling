Consumer App
Discovery Sprint
Six parallel research lanes · Scoring matrix · Top-3 recommendations
Prepared for: Senior Flutter Engineer (fintech / marketplace / dating background)
Goal: Fun, everyday consumer app — paid or open source
Date: September 28, 2026
CONFIDENTIAL — FOR INTERNAL USE

=== PAGE ===
Consumer App Discovery Sprint — September 2026 — Page 2 of 41
Executive Summary
This report consolidates findings from six parallel research lanes covering revenue proof, incumbent
backlash, hobby communities, friends/couples/family, "I wish there was an app" requests, and AI-
powered fun utilities. After deduplication and scoring, three candidates emerge as the strongest bets for
a solo Flutter developer seeking a fun, daily-useful consumer app with real monetization potential.
Top 3 Recommendations:
1. Family Chore & Allowance Gamification — Proven $49.99/yr WTP (Joon). Parent is the
buyer, kid is the user — cold-start solved. Daily ritual. Paid-path score: 25/30.
2. TTRPG Campaign Memory — Genuinely unsolved AI problem. Weekly ritual that compounds
over months. Passionate niche with proven WTP culture. Combined score: 24/30.
3. Board Game Night Companion — Weekly ritual, high fun factor, BGG owns data but not the
mobile experience. Strong OSS path. Combined score: 24/30.
Key monetization insight: Annual subscriptions dominate fun categories (59–68% of revenue). Hard
paywalls convert 5× better than freemium (10.7% vs 2.1%). The subscription app market is winner-take-
more: top 25% of apps grew 80% YoY while bottom 25% shrank 33%. Distribution — not product quality
— is the #1 killer.
Key retention insight: Habit-tracking apps prove that emotional engagement ≠ revenue. One
developer's users "would cry if the app disappeared" — yet zero paying users. The winning formula
combines genuine fun with a clear, immediate value proposition that justifies a hard paywall.
Methodology
Research date: September 28, 2026
Sources: Hacker News (Algolia API), iTunes Search API (live App Store data), AlternativeTo, RevenueCat
State of Subscription Apps 2026, IndieHackers, Starter Story, Product Hunt, Etsy/Gumroad (where
accessible), HN Ask HN threads.
Source quality notes:
Reddit was blocked in most lanes (403/JS shell). Fallbacks: HN Algolia API, iTunes Search API,
AlternativeTo, direct forum fetches.
Etsy and Gumroad were blocked in the hobby lane. WTP evidence there is inference-based.
TrustMRR returned 404. IndieHackers product database contained obvious spam entries.
RevenueCat 2026 report was the single most valuable source: 115,000+ apps, $16B revenue dataset.

Local-First Note-Taking 3 3 3 3 3 3 4 18 19 19
AI Kids' Stories (Offline) 3 4 3 2 3 3 3 18 18 18
Scores are judgment calls based on the evidence gathered. "Reach" reflects how easily a solo dev can find these users
(community, subreddit, hashtag, word of mouth). "Build" reflects solo 4–8 week Flutter-first feasibility. "Diff" reflects real
gap vs incumbents.

=== PAGE ===
Consumer App Discovery Sprint — September 2026 — Page 30 of 41
Phase 4 — Top 8 Detail
#1. Family Chore & Allowance Gamification — Paid-path score: 25/30
One-line pitch: Turn kids' chores and allowance into a game they actually want to play — quests,
rewards, and a pet to feed.
Evidence: Joon (YC W22) proves the model: $49.99/yr subscription, "kids who are asking their
parents for more tasks at home" (Joon creators, Launch HN 2022-01-19 — vendor claim). Cozi has
399,639 US App Store ratings at 4.81 ★  but is weak on chores: "when it comes to chores it lacks a lot
of the options that OH had" (AlternativeTo user, Aug 2024). OurHome had depth but died; Chorsee
is explicitly anti-gamification ("NO GAMIFICATION… a false motivator").
Competitor landscape: Joon ($49.99/yr) is the only proven player but is generic. Cozi
($29.97/yr) owns scheduling but not chores. OurHome (original) effectively delisted. Chorsee (free)
rejects gamification. Nobody owns "fun + deep chore tracking."
Platform: iOS + Android (Flutter). Kids use parents' phones or their own tablets. Parent is the
buyer, kid is the user.
v1 scope: Parent creates quests (chores, homework, habits). Kid completes them to earn coins/feed
a pet. Weekly allowance payout. Shared family board. That's it — no social, no messaging, no
complex gamification in v1.
Fun hook: The pet grows and evolves as quests are completed. Kids ask to do chores. Weekly
"payout" ceremony. Streak bonuses. The share/viral loop: kids show parents their pet progress;
parents invite other parents.
Recommended path: Paid subscription at $49.99/yr (matching Joon's proven price point). Hard
paywall after 14-day free trial. Annual-only — no monthly option (proves commitment, maximizes
LTV). The parent-is-buyer model solves cold start: one parent subscribes, kids use it for free.

=== PAGE ===
Consumer App Discovery Sprint — September 2026 — Page 31 of 41
#2. TTRPG Campaign Memory — Combined score: 24/30
One-line pitch: AI-powered campaign notebook that remembers your NPCs, quests, promises,
and loot — so session 30 feels as coherent as session 1.
Evidence: "standard meeting note-takers treat every session as an isolated island, butcher fantasy
terms, and don't know who is speaking" (Table Canon founder, HN Aug 2026). Campaigns run
weekly/monthly for months or years. Pain compounds over time. TTRPG players buy D&D books,
dice, and subscriptions (Roll20, Foundry) — strong WTP culture.
Competitor landscape: Notion/Obsidian are generic — no TTRPG entity tracking, no fantasy name
recognition. Table Canon (Aug 2026) is attempting AI extraction but is very early (4 points, 2
comments on HN). Roll20/Foundry are VTT-first, not campaign-memory-first.
Platform: iOS + Android (Flutter). Used at the table during sessions, between sessions for prep.
v1 scope: Session notes with AI extraction of NPCs, locations, quests, and items. Entity cards with
relationships. "What did we know about X?" search. Campaign timeline. That's it — no dice roller,
no character sheet, no VTT integration in v1.
Fun hook: The AI remembers things you forgot. "Wait, who was that innkeeper's daughter?" —
instant answer. The campaign grows richer over time. The share/viral loop: players show their
campaign wiki to other groups; DMs share templates.
Recommended path: Freemium with hard paywall at $4.99/mo or $39.99/yr. Free tier: 1
campaign, 50 entities. Paid: unlimited campaigns, AI extraction, export. The TTRPG community is
tight-knit — word of mouth spreads fast in Discord servers and subreddits.

=== PAGE ===
Consumer App Discovery Sprint — September 2026 — Page 32 of 41
#3. Board Game Night Companion — Combined score: 24/30
One-line pitch: Track your collection, keep score, and settle debates about who actually
wins the most — all in one app your whole game night can use.
Evidence: "track who has what game, how often we play different games, and who wins"
(Squire Discord bot, HN Jul 2025). "tracking scores during game nights without paper or
fumbling with Notes" (RoundsKeeper, HN Feb 2026). 4+ separate HN projects over 10+
years — persistent pain, no mobile winner.
Competitor landscape: BGG (BoardGameGeek) owns the data but UI is dated, not
mobile-first. BOXED (2014) appears defunct. No dedicated scorekeeper with analytics found.
BGG could build mobile but hasn't.
Platform: iOS + Android (Flutter). Used during game nights — needs to be fast, offline-
capable, and pass-and-play.
v1 scope: Collection tracker (barcode scan or BGG import). Game-night scorekeeper with
player stats. Win/loss history per game. That's it — no social feed, no marketplace, no BGG
sync in v1.
Fun hook: Stats and leaderboards. "Who actually wins Catan most often?" — data-backed
answer. The share/viral loop: game night groups share stats; BGG integration pulls in
collection data.
Recommended path: Open source (OSS path score: 24). Free app with optional $9.99 one-
time "Pro" upgrade for advanced stats and BGG sync. The board game community is active on
Reddit (r/boardgames), BGG forums, and Discord — strong word-of-mouth potential. OSS
builds reputation; Pro upgrade funds development.

=== PAGE ===
Consumer App Discovery Sprint — September 2026 — Page 33 of 41
#4. Modern Book Tracking — Combined score: 23/30
One-line pitch: A beautiful book tracking app that lets you leave Goodreads without losing
your reading history.
Evidence: "Goodreads is declining because its old tech was less attractive to younger

Top 3 Picks — Where I'd Bet My Weekends
Pick #1: Family Chore & Allowance Gamification
Why I'd bet on it: This is the strongest evidence-backed opportunity in the entire
sprint. Joon proves parents will pay $49.99/yr for chore gamification — that's real
revenue from real users, not inference. The parent-is-buyer, kid-is-user model solves
the cold-start problem that kills most consumer apps: one parent subscribes, the whole
family uses it. The daily ritual is built in (kids want to complete chores to feed their
pet), and the retention hook is emotional (kids love their pet, parents see behavior
change). The market gap is real: Cozi owns scheduling but is weak on chores,
OurHome had depth but died, and Chorsee explicitly rejects gamification. A polished,
ritual-first family board with Joon-style play and Cozi-style scheduling is the obvious
un-built product. My fintech background is directly relevant (allowance tracking,
parent-child financial flows), and my marketplace background applies to the
quest/reward economy design.
Biggest risk: Retention cliff when kids lose interest. The pet/quest mechanic needs to
be genuinely engaging enough to sustain weekly use for months, not days. Mitigation:
progressive pet evolution, seasonal events, and parent-controlled reward calibration.
The app-store discovery risk is moderate — "kids chores" is a competitive category, but
a beautiful, well-reviewed product can break through.

=== PAGE ===
Consumer App Discovery Sprint — September 2026 — Page 39 of 41
Pick #2: TTRPG Campaign Memory
Why I'd bet on it: This is the highest-delight candidate in the entire sprint. The
problem is genuinely unsolved — Notion and Obsidian butcher fantasy terms, and
Table Canon is the only HN-visible attempt at AI extraction (4 points, 2 comments —
nobody is paying attention yet). The weekly ritual compounds over months or years:
session 30+ becomes unmanageable in plain notes, and the pain intensifies with every
session. The TTRPG community has proven willingness to pay (D&D books, dice,
Roll20, Foundry subscriptions). The AI angle — auto-extracting NPCs, quests,
promises, and loot from session notes — is technically feasible with current LLMs and
genuinely delightful: "Wait, who was that innkeeper's daughter?" gets an instant
answer. My AI-orchestration background is directly relevant (entity extraction,
knowledge graphs, prompt engineering), and my marketplace background applies to
the entity-relationship design.
Biggest risk: Small market. TTRPG is a passionate but niche community — the total
addressable market is smaller than family apps or book tracking. The AI accuracy risk
is real: hallucinated NPCs or incorrect quest extraction would destroy trust. Mitigation:
human-in-the-loop verification, confidence scoring, and a "suggest, don't auto-apply"
UX. The reachability risk is moderate — the community is tight-knit (Discord servers,
subreddits like r/DnD), so word of mouth spreads fast within the niche but breaking
out is hard.
Pick #3: Board Game Night Companion
Why I'd bet on it: This is the highest-OSS-potential candidate with a strong fun
factor. The pain has persisted for 10+ years (4+ separate HN projects) with no clear
mobile winner — BGG owns the data but not the experience. The weekly ritual is built
in (game nights), and the stats/leaderboards angle is genuinely delightful: "Who
actually wins Catan most often?" gets a data-backed answer. The OSS path is strong
because the board game community values open data (BGG API is open), and a free,
beautiful collection tracker with optional Pro upgrade is a natural fit. My marketplace
background applies to the collection/trading features, and my fintech background
applies to the stats/analytics engine. The viral loop is organic: game night groups share
stats, and BGG integration pulls in collection data.
Biggest risk: Monetization is unproven — nobody has found WTP evidence for board
game apps (Etsy/Gumroad were blocked in research). BGG could build a mobile app
anytime and crush a solo dev. Mitigation: move fast, build a beautiful UX that BGG
won't prioritize, and use the OSS community to build defensibility. The retention risk is
moderate — game night is weekly, not daily, but the collection tracker provides daily
engagement ("add this game to my collection").

=== PAGE ===
Consumer App Discovery Sprint — September 2026 — Page 40 of 41
Appendix — Source Quality & Limitations
Sources Successfully Used
RevenueCat State of Subscription Apps 2026 — 115,000+ apps, $16B revenue
dataset. March 2026. The single most valuable source.
Hacker News (Algolia API) — 100+ queries across all lanes. Primary source for Lane
2, 3, 5, 6.
iTunes Search API — Live App Store ratings, counts, and pricing. Primary source for
Lane 4.
AlternativeTo — User reviews and competitor analysis. Lane 4.
Starter Story, IndieHackers — Revenue proof (partial — spam issues on IH).
Sources Blocked or Unreachable
Reddit — 403/JS shell in most lanes. r/boardgames, r/DnD, r/gardening, r/knitting,
r/homebrewing, r/birding, r/climbing, r/SomebodyMakeThis, r/AppIdeas,
r/relationships, r/parenting, r/artificial, r/LocalLLaMA — all inaccessible. This is a
significant gap: subreddit member counts and Reddit community sentiment would
strengthen WTP evidence for hobby lanes.
X/Twitter — Not directly searched in most lanes.
Etsy — 403 in hobby lane. Template sales counts were unavailable.
