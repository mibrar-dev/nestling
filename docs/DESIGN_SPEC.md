# Nestling — Master UI/UX Spec (v1, UK launch)

Working title: **Nestling**. A family chore & pocket-money app. Parents set "quests"; children complete them to earn coins, grow a pet bird called **Pip**, and watch their pocket-money jar fill. Parent is the buyer (subscription), child is the player.

Market: UK only. Platforms: iOS + Android (Flutter later). These designs are **high-fidelity HTML mobile screens** built in an Open Design project.

---

## 0. Hard deliverable rules (every sub-agent)

1. Write files ONLY via the **open-design MCP** (`write_file` / `create_artifact`) into project id **`nestling-uk-family-chores-mobile-ui-e9c1`**. Never write elsewhere.
2. **One screen = one HTML file** at `screens/<ID>-<slug>.html` (exact names are in §6). Each file is standalone, links `../tokens.css` and `../components.css`, and may add a small `<style>` block for screen-specific layout only.
3. **Device frame:** `<body>` is exactly **390 × 844 px** (iPhone 15/16). `html,body{width:390px;height:844px;margin:0;overflow:hidden}`. Inside, a `.screen` root fills it. Use the status-bar mock (47px) at top and home-indicator safe area (34px) at bottom from components.css.
4. **No horizontal overflow, ever.** Nothing may extend beyond x = 0…390. Long text wraps or truncates with ellipsis. If content is taller than the viewport, the middle region scrolls (`.scroll` class, `overflow-y:auto`) — headers, tab bars and bottom CTAs stay fixed and must not overlap content (add bottom padding = CTA height + 16px).
5. **No external images.** Illustrations = inline SVG or files under `assets/`. Pip the bird ONLY from `assets/pip-stage-{1,2,3,4}.svg` (created in phase 1). Icons: inline SVG, 24px, 2px stroke, round caps (Lucide-style). No emoji as UI icons (emoji allowed only inside quest template names if desired—prefer SVG).
6. Fonts via Google Fonts only: **Nunito** (700/800/900) for display & kid mode, **Inter** (400/500/600/700) for parent-mode body/UI. Already imported in tokens.css — do not import others.
7. Use **tokens only** (CSS variables). No hard-coded hex in screen files except inside SVG art.
8. Realistic UK content — never lorem ipsum. Family used everywhere: parent **Sarah** (co-parent **James**), children **Maya (9)** and **Leo (6)**. Currency `£` with two decimals (`£2.50`). Dates `Sat 4 Oct`. UK spelling (colour, favourite, tidy, hoover, bins, pocket money, Mum/Dad).
9. Accessibility: text contrast ≥ 4.5:1 (≥3:1 for ≥24px bold), tap targets ≥ 44×44 px parent mode, ≥ 56×56 px kid mode, every icon-only button has `aria-label`, body text ≥ 15px parent / ≥ 17px kid.
10. When done, reply with a table: file path | screen title | notes. Then list anything you could not do.

---

## 1. Product principles

- **Two worlds, one app.** *Parent mode* = calm, trustworthy, data-clear (think Monzo/Starling: warm neutrals, lots of white space). *Kid mode* = playful, big, tactile, joyful (think Duolingo/Toca: rounded, bouncy, colourful) — but never frantic.
- **Kind motivation, not pressure (ICO Children's Code std 13).** No loss-aversion, no guilt, no countdown timers, no "streak will be lost", no red badges nagging children, no variable/random rewards (no loot boxes, no spin wheels). Streaks are framed positively ("Pip's happy week: 4 days") and never reset visibly with shame.
- **No real money moves.** The app is a *ledger*. Parents pay pocket money in real life and tap "Mark as paid". Never show card numbers, bank links, "top up", "send money".
- **Privacy by default.** Child profiles = nickname + age band + avatar colour. No child photos, no child email, no chat, no social, no location, no ads. Photo proof of chores is **not** in v1.
- **Parental gate** guards: parent mode entry from kid mode, paywall, settings, any external link, subscription management.
- Store-listing rule (Apple 5.1.4(b)): marketing copy inside onboarding speaks to **parents** ("family habits", "your children"), never "For Kids".

---

## 2. Design tokens (phase 1 writes `tokens.css`)

```
Colour — neutrals
--ink:        #1E1B3A   primary text (plum-navy)
--ink-2:      #4A4668   secondary text
--ink-3:      #6E6A8A   tertiary / captions (check ≥4.5:1 on --paper)
--paper:      #FBF7F0   parent app background (warm cream)
--surface:    #FFFFFF   cards
--surface-2:  #F3EEE5   inset / chips
--line:       #E7E0D4   hairlines

Colour — brand & semantic
--leaf:       #1F9D63   brand primary (buttons, active tab)
--leaf-ink:   #0B5C38   text on leaf-tint
--leaf-tint:  #E3F5EC
--coin:       #F4B400   coins
--coin-ink:   #6B4E00
--coin-tint:  #FFF4D1
--sky:        #3D7FF0   info / links
--sky-tint:   #E6EFFE
--lilac:      #7C6CF2   pet/evolution accents
--lilac-tint: #EEEBFF
--peach:      #FF8A5B   kid-mode warmth accents
--peach-tint: #FFEDE4
--success:    #1F9D63
--warning:    #C97800
--danger:     #C93A3A   destructive only (delete) — never used in kid mode

Kid-mode backgrounds
--kid-sky-top:    #CFE6FF
--kid-sky-bottom: #F2FAFF
--kid-meadow:     #BFE8B0

Type (parent: Inter; kid & display: Nunito)
--font-ui:      'Inter', system-ui, sans-serif
--font-display: 'Nunito', system-ui, sans-serif
Scale (px/line-height): display 34/40 · h1 28/34 · h2 22/28 · h3 18/24 · body 16/24 · body-s 15/22 · caption 13/18 · kid-body 18/26 · kid-title 28/34 · kid-hero 40/44
Weights: Inter 400/500/600/700 · Nunito 800/900 for headings

Space (4pt grid): --s1 4 · --s2 8 · --s3 12 · --s4 16 · --s5 20 · --s6 24 · --s8 32 · --s10 40
Screen side padding: 20px parent, 20px kid
Radius: --r-s 10 · --r-m 16 · --r-l 24 · --r-xl 32 · --r-pill 999
Shadow: --sh-1 0 1px 2px rgba(30,27,58,.06), 0 2px 8px rgba(30,27,58,.06)
        --sh-2 0 6px 24px rgba(30,27,58,.10)
        --sh-kid 0 6px 0 rgba(30,27,58,.12)  (chunky "pressable" kid buttons)
Motion (for notes only): 180ms ease-out standard, 320ms spring for kid rewards; respect prefers-reduced-motion.
Device: --status-h 47px · --home-h 34px · --tab-h 84px (incl. home area) · --w 390px · --h 844px
```

## 3. Components (phase 1 writes `components.css` + `design-system.html` showcase)

Class names are the contract — screen agents must use them.

- `.screen` (390×844 flex column, bg per mode: `.screen.parent` = --paper, `.screen.kid` = sky gradient)
- `.status-bar` (47px, time "9:41", signal/wifi/battery SVGs; `.on-dark` variant)
- `.home-indicator` (34px bottom safe area with 134×5 pill)
- `.nav-bar` (large-title iOS style: back chevron button 44×44, centred or large title, optional right action) and `.nav-bar.compact`
- `.scroll` (flex:1; overflow-y:auto; padding 0 20px; padding-bottom var(--s8))
- `.tab-bar` (parent only, 4 tabs: **Today, Quests, Money, Family**; icon 24 + label 11px Inter 600; active = --leaf)
- `.btn` + `.btn-primary` (leaf bg, white text, 52px high, r-pill, full width) / `.btn-secondary` (surface, ink, 1px line) / `.btn-ghost` / `.btn-danger-ghost` / `.btn-kid` (Nunito 900, 64px high, r-l, --sh-kid, pressable look; colour modifiers `.leaf .coin .sky .peach .lilac`)
- `.bottom-cta` (fixed bottom container above home indicator, surface bg + top hairline, 16px padding)
- `.card` (surface, r-l, sh-1, 16px padding), `.card.inset` (surface-2, no shadow)
- `.list` / `.list-row` (min-height 56, leading icon tile 40×40 r-m, title + subtitle, trailing value/chevron; hairline dividers inset 72px)
- `.chip` (pill 32px, surface-2) + `.chip.selected` (leaf-tint, leaf-ink, 1.5px leaf border)
- `.segmented` (2–3 options, 36px)
- `.toggle` (51×31 iOS switch; on = --leaf)
- `.field` (label 13px 600 ink-2, input 52px r-m, 1px line, focus 2px leaf ring; helper & error text)
- `.stepper` (− value +, 44px buttons)
- `.avatar` (circle with initial, colour modifiers `.a-lilac .a-peach .a-sky .a-leaf .a-coin`; sizes 32/44/64/96)
- `.coin-pill` (coin icon SVG + number, coin-tint bg, coin-ink text, Nunito 800)
- `.money` (tabular-nums, "£12.50")
- `.progress` (8px track, r-pill; `.progress.kid` 16px with inner highlight)
- `.badge-count` (small leaf dot/number; not red)
- `.sheet` (bottom sheet: grabber, r-xl top corners, 20px padding) + `.scrim`
- `.modal` (centred dialog r-xl)
- `.toast`
- `.empty-state` (illustration slot 160px, title h3, body, 1 CTA)
- `.quest-card` (parent variant: icon tile, title, assignee avatars, coin reward, repeat label; kid variant `.quest-card.kid`: 72px min height, big icon 48, title kid-body, coin-pill, big round check target 56px)
- `.pet-stage` (container that centres Pip SVG with soft ground-shadow ellipse)
- `.keypad` (3×4 numeric keypad, 72px keys — used by parental gate & kid PIN)

Assets (phase 1 creates as SVG, flat vector, 2–3 tones + ink outline 3px, friendly round shapes, facing viewer):
- `assets/pip-stage-1.svg` Egg (cream egg with lilac speckles, tiny crack, little eyes peeking)
- `assets/pip-stage-2.svg` Hatchling (round yellow chick, half eggshell on head)
- `assets/pip-stage-3.svg` Fledgling (plumper, leaf-green wing tips, small tuft)
- `assets/pip-stage-4.svg` Songbird (confident, lilac/leaf plumage, tiny scarf in peach)
- `assets/coin.svg` (gold coin with embossed leaf)
- `assets/nest.svg` (twig nest for ground under Pip)
- `assets/app-icon.svg` (1024 rounded square: leaf-green bg, Pip stage 3 head)

---

## 4. Navigation map

```
Launch → P01 Welcome → P02 Value tour (3 cards, one screen w/ pager) → P03 Create account
 → P04 Privacy & consent → P05 Add children → P06 Pocket money setup → P07 Paywall (trial)
 → P08 Parent Today (home)
Parent tabs: Today(P08) · Quests(P10/P09) · Money(P12/P13) · Family(P15/P16)
Parent → "Hand to child" → K01 Who's playing? → K02 PIN (optional) → K03 Kid home
Kid: K03 → K04 quest detail → K05 done celebration; K03 → K06 Pip; K07 evolution; K08 Reward shop; K09 My jar; K10 Payout day; K11 Badges
Kid → parent: lock icon → P17 Parental gate → P08
```

---

## 5. Screen specs

### Group A — Onboarding, account, paywall, gate (sub-agent A)

**P01 Welcome** (`screens/P01-welcome.html`) — parent mode but brand-forward. Top 55%: illustrated scene — nest.svg with Pip stage 2 on a soft leaf-tint circle, 3 floating coin.svg. Title (Nunito 900, 34px): "Chores that feel like a game." Body: "Nestling turns family jobs into quests your children actually want to finish — and keeps pocket money fair and tidy." Buttons: primary "Get started", secondary ghost "I already have an account". Footer caption: "Made in the UK · No ads, ever".

**P02 Value tour** (`screens/P02-value-tour.html`) — show card 1 of 3 with pager dots (3 dots, first active) + "Skip" top-right. Card 1: illustration of quest list; title "Set quests in seconds"; body "Pick from 40+ ready-made jobs like 'Put the bins out' or make your own." Beneath, show small preview thumbnails of cards 2 ("Pip grows as they help" ) and 3 ("Pocket money, sorted — no bank card needed") peeking at 16px from the right edge BUT CLIPPED inside the frame (no overflow). CTA "Next".

**P03 Create account** (`screens/P03-create-account.html`) — nav back. Title "Create your family account". Subtitle "You're the grown-up in charge. Children never need an email." Buttons: "Continue with Apple" (black, Apple logo SVG), "Continue with Google" (white w/ border, G logo SVG), divider "or", fields Email + Password (show/hide eye), helper "At least 8 characters". Primary "Create account". Caption: "By continuing you agree to our Terms and Privacy Notice" (links styled --sky, underlined).

**P04 Privacy & consent** (`screens/P04-privacy.html`) — Title "Your family's privacy". Friendly shield illustration. 4 list-rows with icons: "No ads or tracking — ever", "Children only need a nickname", "Data stored in the UK (London)", "Delete everything anytime". Then a card "Optional: help improve Nestling" with toggle **OFF by default** + text "Share anonymous crash reports". Buttons equal weight (ICO nudge rule): primary "Continue" only (no manipulative yes/no). Link "Read the full Privacy Notice".

**P05 Add children** (`screens/P05-add-children.html`) — Title "Who's in your nest?" Show 2 already-added children as cards (Maya · 9 · lilac avatar "M"; Leo · 6 · peach avatar "L") with edit pencil. Below, an open "Add a child" form card: Nickname field, age band chips (4–6, 7–9, 10–12, 13+), avatar colour swatches (5 circles, 44px), caption "We only ask for an age range so quests suit them." Secondary "+ Add another child". Bottom CTA "Continue".

**P06 Pocket money setup** (`screens/P06-pocket-money.html`) — Title "How does pocket money work in your house?" Three selectable option cards (radio): (1) "Weekly amount" – "A set amount every week" (2) "Earn per quest" – "Coins turn into pence at payout" (3) "Both" – "Weekly base + bonus for extra quests" (SELECTED). Then settings card: Payout day chips Mon–Sun (Sat selected); "Weekly base" stepper per child (Maya £3.00, Leo £1.50); "Coin value" row "10 coins = 10p". Caption: "Nestling never holds or moves money. You pay your way; we keep score." CTA "Continue".

**P07 Paywall** (`screens/P07-paywall.html`) — Close X (top-left, 44px, clearly visible). Hero: Pip stage 4 on nest, coins. Title "Try Nestling free for 14 days". Benefits (4 check rows): Unlimited children & quests · Pip's full evolution & seasonal outfits · Pocket money ledger & payout day · Co-parent sharing. Plan card (single annual plan, selected): "Annual — £29.99/year" with sub "Just £2.50 a month, billed yearly". Trial timeline (3 steps, vertical): "Today – full access", "Day 12 – we'll remind you", "Day 14 – £29.99 billed, cancel anytime before". Primary CTA "Start free trial". Under it caption "£29.99/year after 14-day trial. Cancel anytime in Settings." Row of small links: Restore purchases · Terms · Privacy. Family Sharing note: "One subscription covers the whole family." No fake urgency, no countdown.

**P17 Parental gate** (`screens/P17-parental-gate.html`) — shown over kid mode (kid sky background dimmed with scrim) as a centred `.modal`. Lock icon. Title "Grown-ups only". Instruction: "Type the answer in numbers: **seven times six**". Input display boxes (2 digits) + `.keypad`. Cancel ghost button "Back to Pip". Caption: "This keeps settings and purchases safe."

### Group B — Parent core (sub-agent B)

**P08 Today (home)** (`screens/P08-today.html`) — tab bar (Today active). Header: "Good morning, Sarah" + date "Sat 4 Oct"; right: avatar button S. **Approvals banner card** (leaf-tint): "3 quests waiting for your thumbs-up" + button "Review". **Children summary**: horizontal 2-up cards (each 170px wide, fitting within 350px content width with 10px gap — NO overflow): Maya — Pip stage 3 small, "4 of 6 quests", progress bar, coin-pill 120; Leo — stage 2, "2 of 4", coin-pill 45. **Today's quests** list grouped by child (quest-card parent variant): Maya — "Empty the dishwasher" (done, awaiting approval chip), "Reading – 20 minutes" (to do), "Put the bins out" (done ✓ approved). Leo — "Make your bed" (done), "Feed Biscuit the cat" (to do). Floating primary "+ New quest" pill above tab bar at right (must not cover content: add bottom padding). Big secondary button "Hand to Maya or Leo" (opens kid mode).

**P08b Today — empty** (`screens/P08b-today-empty.html`) — same chrome; empty-state with Pip stage 1 egg: "Your nest is quiet" / "Add your first quest and Pip will start to hatch." CTA "Add a quest" + link "Browse ideas".

**P09 New / edit quest** (`screens/P09-quest-editor.html`) — presented as full-height sheet: grabber, nav "Cancel" | "New quest" | "Save" (Save leaf). Fields: Quest name (filled "Hoover the stairs"); Icon picker row (6 SVG icons in 48px tiles, one selected); "Who's it for?" avatar chips (Maya selected, Leo, "Anyone"); "Reward" coin stepper (15 coins) + helper "= 15p at payout"; "Repeats" segmented (Once / Daily / Weekly — Weekly selected) + day chips M T W T F **S** S; toggle "Needs my approval" ON; "Due by" row "Before tea (5pm)". Delete not shown for new.

**P10 Quest library** (`screens/P10-quest-library.html`) — tab Quests active. Title "Quests". Segmented: "Active (12)" / "Ideas". Show *Ideas* selected: search field; category chips (All, Bedroom, Kitchen, Outdoors, Pets, School, Kindness); list of templates with icon, name, suggested coins, suggested age band, "+ Add" button 44px: Make your bed (5 · 4+), Lay the table (10 · 5+), Put the bins out (15 · 8+), Empty the dishwasher (15 · 7+), Hoover the stairs (20 · 9+), Feed the pet (5 · 4+), Pack school bag (5 · 5+), Water the plants (10 · 5+), Help with the washing (15 · 7+), Read for 20 minutes (10 · 5+).

**P11 Approvals** (`screens/P11-approvals.html`) — nav back "Today", title "Waiting for you (3)". Cards: each shows child avatar+name, quest, time "Today 8:12am", coins, and two equal-size buttons "Not yet" (secondary) and "Approve" (primary). Include friendly helper: "'Not yet' sends a kind note — no coins are taken away." Bulk action at bottom: "Approve all (3)".

**P12 Money (ledger)** (`screens/P12-money.html`) — tab Money active. Title "Pocket money". Segmented Maya | Leo (Maya). Balance hero card: "Maya is owed" **£4.20**; breakdown "Weekly base £3.00 + quests £1.20"; next payout "Sat 4 Oct"; primary "Payout time" button. Savings goal card: "Lego Friends set — £24.99", progress 62%, "£15.50 saved". History list: "Paid £3.80 · Sat 27 Sep", "Quest bonus +12p · Put the bins out", "Birthday money +£10.00 (added by Mum)", "Spent £2.00 · Comic". Row buttons: "Add money", "Record spending". Caption: "Nestling keeps track — the real money stays with you."

**P13 Payout (parent)** (`screens/P13-payout.html`) — sheet/modal: "Saturday payout" for Maya & Leo with per-child rows (avatar, amount £4.20 / £2.10, checkbox "Paid in cash"), option "Move £1.00 of Maya's to her savings goal" toggle, primary "Mark as paid & start the celebration", caption "Your children will see a payout celebration next time they open Nestling."

**P14 Rewards manager** (`screens/P14-rewards.html`) — nav back, title "Reward shop". Intro "Things coins can buy — you decide." List of rewards with coin price & edit: "30 min extra screen time – 50", "Pick Friday film – 80", "Stay up 15 min later – 60", "Baking together – 100", "Trip to the park café – 150". Toggle per reward "Needs my OK". Button "+ New reward".

**P15 Child profile** (`screens/P15-child-profile.html`) — Family tab active. Header: large avatar M (lilac) "Maya", "Age 7–9 · Pip is a Fledgling". Stats row 3 tiles: Quests this week 18 · Coins 120 · Happy days 4. Sections: "Pip" (stage 3 art small, next stage progress 70%, "Evolves at 250 total coins"); "Kid PIN" row (On, change); "Quests" row (6 active); "Pocket money" row (£3.00/week); danger ghost "Remove Maya from family".

**P16 Settings** (`screens/P16-settings.html`) — Family tab. Title "Family & settings". Sections: Family (Sarah – you, James – co-parent (invited), "+ Invite co-parent"); Children (Maya, Leo, + Add child); Subscription ("Nestling Annual · renews 18 Oct 2027", "Manage subscription"); Notifications (toggles: Approvals waiting ON, Payout day reminder ON, Weekly family summary ON); Privacy ("Download our data", "Privacy Notice", "Delete family account" in danger ghost); About (Help & feedback, Version 1.0.0). Lock icon hint row "Kid mode needs parent gate — On".

### Group C — Kid mode (sub-agent C)

Kid-mode rules: Nunito everywhere, kid-body 18px min, `.btn-kid` chunky buttons, tap targets ≥56, sky gradient bg with soft meadow hill at bottom (SVG), no tab bar, no prices in £ (coins only) EXCEPT My Jar (K09). Top-right on every kid screen: small lock button (44px, aria-label "Grown-ups") that leads to P17. No red, no nagging.

**K01 Who's playing?** (`screens/K01-profile-picker.html`) — Title "Who's playing?" Two huge profile tiles (160×180, r-xl, avatar 96, name 24 Nunito 900, mini Pip stage below): Maya, Leo. Caption bottom "Grown-ups: tap the lock".

**K02 Kid PIN** (`screens/K02-pin.html`) — avatar M + "Hi Maya! Enter your secret code". 4 big dots (2 filled), `.keypad` with 72px keys, playful. "Forgot? Ask a grown-up."

**K03 Kid home** (`screens/K03-kid-home.html`) — top: avatar M + "Hi Maya!" + coin-pill 120. **Pet stage** (~260px tall): Pip stage 3 on nest, speech bubble "Let's do some quests!", happiness hearts row (4/5, no negative framing). Section "Today's quests" (3 of 6 done, kid progress bar): quest-card.kid list: "Empty the dishwasher" (done ✓, "Waiting for Mum's thumbs-up" chip), "Reading – 20 minutes" (to do, +10), "Tidy your bedroom" (to do, +15). Bottom dock (fixed, above home indicator): three `.btn-kid` round-rect buttons: "Pip" (lilac), "Shop" (coin), "My jar" (leaf). Content scrolls behind with bottom padding so nothing is hidden.

**K03b Kid home — all done** (`screens/K03b-kid-home-done.html`) — same layout; Pip celebrating with confetti (SVG, static), bubble "You did everything today! Pip is so proud." Quests all ticked. CTA "Visit Pip".

**K04 Quest detail** (`screens/K04-quest-detail.html`) — big icon tile 120px, title "Tidy your bedroom" (kid-title), reward coin-pill "+15", steps checklist (kid size): "Clothes in the basket", "Toys in the box", "Books on the shelf". Primary huge `.btn-kid.leaf` "I did it!" at bottom. Secondary "Back".

**K05 Quest complete** (`screens/K05-quest-complete.html`) — celebration: coins burst (SVG static), Pip stage 3 jumping, title "Brilliant, Maya!", "+15 coins", sub "Mum will give it a thumbs-up soon." Progress to next Pip stage bar "Pip needs 75 more coins to grow". CTA "Yay! Back home".

**K06 Pip's nest** (`screens/K06-pip.html`) — big Pip stage 3 (280px), name "Pip · Fledgling", growth progress to Songbird (175/250). Care actions row 3 × `.btn-kid`: "Feed (5)", "Play", "Bath" (cost in coins shown). Wardrobe strip: 4 items (scarf, sunhat, wellies, crown) as 72px tiles — 2 owned, 2 locked with coin price. Note: all free choices, no timers.

**K07 Pip evolves!** (`screens/K07-evolution.html`) — full-screen moment: lilac radial glow, Pip stage 3 → stage 4 (show stage 4 large, faint stage-3 silhouette left), title "Pip grew into a Songbird!", sub "Because you helped 25 times", CTA "Meet Songbird Pip".

**K08 Reward shop** (`screens/K08-shop.html`) — title "Reward shop", coin-pill 120 top. Grid 2 columns (each 167px wide with 16px gap — fit 350px exactly, no overflow) of reward cards: icon, name, coin price, button "Get it" (disabled style + "Save up!" when too expensive — not shaming). Items: 30 min extra screen time (50), Pick Friday film (80), Stay up 15 min later (60), Baking together (100), Park café trip (150 — locked, "30 more to go"), Choose dinner (90).

**K09 My jar** (`screens/K09-jar.html`) — the only kid screen with £. Illustration of a glass jar filled 62% with coins. "£4.20 coming on Saturday". Savings goal card: "Lego Friends set", "£15.50 of £24.99", kid progress bar, "£9.49 to go". Recent: "+£3.80 last Saturday", "+12p Put the bins out", "+£10 Birthday money from Mum".

**K10 Payout day** (`screens/K10-payout-day.html`) — celebration: jar with coins raining, title "It's payout day!", "Mum marked £4.20 as paid", "£1.00 went into your Lego fund", CTA "Thanks Mum!".

**K11 Badges** (`screens/K11-badges.html`) — title "My badges". Grid 3 columns (each ≥ 104px, fitting 350px): earned (colourful SVG medals): "First quest", "Bed maker ×7", "Kind helper", "Bookworm"; not yet earned shown as soft outlines with "Keep going!" (no "locked" negativity). Happy-week tracker: 7 day dots Mon–Sun, 4 filled leaf, text "4 happy days this week".

---

## 6. File manifest (exact paths)

Phase 1 (Design system agent): `tokens.css`, `components.css`, `design-system.html`, `index.html` (gallery), `assets/pip-stage-1.svg`, `assets/pip-stage-2.svg`, `assets/pip-stage-3.svg`, `assets/pip-stage-4.svg`, `assets/coin.svg`, `assets/nest.svg`, `assets/app-icon.svg`

Group A: `screens/P01-welcome.html`, `screens/P02-value-tour.html`, `screens/P03-create-account.html`, `screens/P04-privacy.html`, `screens/P05-add-children.html`, `screens/P06-pocket-money.html`, `screens/P07-paywall.html`, `screens/P17-parental-gate.html`

Group B: `screens/P08-today.html`, `screens/P08b-today-empty.html`, `screens/P09-quest-editor.html`, `screens/P10-quest-library.html`, `screens/P11-approvals.html`, `screens/P12-money.html`, `screens/P13-payout.html`, `screens/P14-rewards.html`, `screens/P15-child-profile.html`, `screens/P16-settings.html`

Group C: `screens/K01-profile-picker.html`, `screens/K02-pin.html`, `screens/K03-kid-home.html`, `screens/K03b-kid-home-done.html`, `screens/K04-quest-detail.html`, `screens/K05-quest-complete.html`, `screens/K06-pip.html`, `screens/K07-evolution.html`, `screens/K08-shop.html`, `screens/K09-jar.html`, `screens/K10-payout-day.html`, `screens/K11-badges.html`

Total: 30 screens.

`index.html` gallery: grid of all 30 screens as `<iframe src="screens/…" width=390 height=844>` scaled 0.5 via CSS transform inside 195×422 wrappers, grouped under headings "Onboarding", "Parent", "Kid mode", each labelled with ID + title. Must render fine even if a screen file doesn't exist yet.
