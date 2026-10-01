[0m
> build · space-bunny-free
I'll verify the disputed claims before ruling.
[0m⚙ [0mexecute {"code":"const urls = [\n  [\"kanka\", \"https://kanka.io/premium\"],\n  [\"wa\", \"https://www.worldanvil.com/features\"],\n  [\"apple23\", \"https://developer.apple.com/app-store/review/guidelines/\"],\n  [\"bgg\", \"https://boardgamegeek.com/wiki/page/XML_API_Terms_of_Use\"],\n  [\"bggcom\", \"https://boardgamegeek.com/wiki/page/BGG_XML_API_Commercial_Use\"],\n];\nconst out = await Promise.all(urls.map(async ([k,u]) => {\n  try {\n    const r = await tools.webfetch({url: u, format: \"text\", timeout: 45});\n    return k + \" OK len=\" + (typeof r === \"string\" ? r.length : JSON.stringify(r).length);\n  } catch (e) { return k + \" ERR \" + e.message; }\n}));\nreturn out.join(\"\\n\");"} 
> build · space-bunny-free
[0m% [0mWebFetch https://kanka.io/premium 
> build · space-bunny-free
[0m% [0mWebFetch https://kanka.io/pricing 
> build · space-bunny-free
[0m% [0mWebFetch https://boardgamegeek.com/wiki/page/XML_API_Terms_of_Use 
> build · space-bunny-free
[0m% [0mWebFetch https://boardgamegeek.com/wiki/page/BGG_XML_API_Commercial_Use 
> build · space-bunny-free
[0m% [0mWebFetch https://developer.apple.com/app-store/review/guidelines/ 
> build · space-bunny-free
[0m$ [0mgrep -n -o -E "5\.1\.[0-9]+[^\"]{0,400}" "/Users/ibrar/.local/share/opencode/tool-output/tool_0f05c8967001livgjBLWuVU4oO" | head -40
grep: maximum repetition exceeds 255
> build · space-bunny-free
[0m$ [0mF="/Users/ibrar/.local/share/opencode/tool-output/tool_0f05c8967001livgjBLWuVU4oO"; grep -n "5.1.2" "$F" | head -20; echo "-----5.1.4-----"; grep -n "5.1.4" "$F" | head -20
1231:									5.1.2 Data Use and Sharing
-----5.1.4-----
1251:									5.1.4 Kids
> build · space-bunny-free
[0m→ [0mRead /Users/ibrar/.local/share/opencode/tool-output/tool_0f05c8967001livgjBLWuVU4oO [90m[offset=1231, limit=30][0m
> build · space-bunny-free
[0m% [0mWebFetch https://support.google.com/googleplay/android-developer/answer/9893335?hl=en-GB 
> build · space-bunny-free
[0m$ [0mfor id in 1482225056 892542000; do curl -s "https://itunes.apple.com/lookup?id=$id&country=gb" | python3 -c "
import sys,json
d=json.load(sys.stdin)
r=d['results'][0] if d['resultCount'] else None
if not r: print('NOT FOUND'); raise SystemExit
print(r['trackName'],'|',r.get('formattedPrice'),'|',r.get('price'),'|',r.get('averageUserRating'),'|',r.get('userRatingCount'),'|',r.get('currentVersionReleaseDate','')[:10],'|',r.get('genres'))
"; done
echo "=== Joon IAP tier (US site) ==="
curl -s "https://itunes.apple.com/lookup?id=1482225056&country=gb&entity=software" >/dev/null; echo ok
Joon: Behavior Improvement App | Free | 0.0 | 4.46102 | 449 | 2026-09-15 | ['Health & Fitness', 'Productivity']
Board Game Stats | £4.99 | 4.99 | 4.79012 | 81 | 2026-09-22 | ['Lifestyle', 'Utilities']
=== Joon IAP tier (US site) ===
ok
> build · space-bunny-free
[0m$ [0mecho "=== WA features ==="; curl -sL --max-time 40 "https://www.worldanvil.com/features" | sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -o -i -E ".{80}(million|3\.5m|users|worldbuilders).{80}" | head -8
echo "=== WA pricing ==="; curl -sL --max-time 40 "https://www.worldanvil.com/pricing" | sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -o -i -E ".{100}(Master|Sage|Essential|per month).{100}" | head -8
=== WA features ===
=== WA pricing ===
> build · space-bunny-free
[0m% [0mWebFetch https://www.worldanvil.com/pricing 
> build · space-bunny-free
[0m$ [0mecho "=== KANKA HOME ==="; curl -sL --max-time 30 "https://kanka.io/" | sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -o -i -E ".{60}(400,?000|users|GMs|worldbuilders|registered).{60}" | head -6
echo; echo "=== NEWSROUND ==="; curl -sL --max-time 40 -A "Mozilla/5.0" "https://www.bbc.co.uk/newsround/articles/cyvmd48rr9zo" | sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -o -i -E ".{110}(30 per cent|30%|30 per cent|pocket money|9\.13|chores).{110}" | head -12
=== KANKA HOME ===
a-calendar-upload{--fa:"";--fa--fa:""}.fa-calendar-users{--fa:"";--fa--fa:""}.fa-calendar-week{--fa:"";-
 maps, timelines, and lore — all in one place. Trusted by 400,000+ worldbuilders and game masters.","applicationCategory":"Ga
d keep track of your ideas, your creations, and your world. 400,000+ game masters and worldbuilders call Kanka their home. Star
core features, unlimited campaigns, unlimited entries. Most GMs never need to pay, and we&#39;d rather you stay because you
ld. Run it with your whole table Invite your players and co-GMs, then control exactly what each person sees and edits. Your
 more about Kanka&#39;s features You&#39;re in good company 400,000+ game masters and worldbuilders trust Kanka for their world

=== NEWSROUND ===
-16T08:20:02.040Z","dateModified":"2025-06-16T08:20:02.040Z","description":"Fewer children are getting weekly pocket money, with parents favouring rewarding for doing chores or getting a good school report.","headline":"Pocket money
 Bitesize CBeebies CBBC on TV CBBC Help Close menu Home Menu Home Shows Games Quizzes Watch Join In Newsround Pocket money - how do you earn it and how do you spend it? Image source, Getty Images Published 16 June 2025 125 Comments 
earn it? And if you do extra chores do you get extra pay? A survey looking into how kids earn and spend their pocket money says fewer parents are giving it out weekly. Instead, more kids are being rewarded with cash for things like 
d what you like to spend it on. Let us know in the comments below! More like this How do you like to get your pocket money? Published 11 October 2022 Meet the girl who&#x27;s saved her pocket money to help other kids Published 7 Nov
350,000 children aged six to 17-years-old that use NatWest Rooster. It found on average kids in the UK earn £9.13 per week, which is down slightly on 2023. But children are earning more for chores, with a 7p increase for wa
o\",\"locators\":{\"canonicalUrl\":\"https://www.bbc.com/newsround/articles/cyvmd48rr9zo\"},\"seoHeadline\":\"Pocket money: How do you earn it and what do you spend it on? \",\"promoHeadline\":{\"blocks\":[{\"type\":\"text\",\"model
oney - how do you earn it and how do you spend it?\",\"blocks\":[{\"type\":\"fragment\",\"model\":{\"text\":\"Pocket money - how do you earn it and how do you spend it?\",\"attributes\":[]}}]}}]}}]},\"indexImage\":{\"blocks\":[{\"ty
\"type\":\"text\",\"model\":{\"blocks\":[{\"type\":\"paragraph\",\"model\":{\"text\":\"A child holds a jar of pocket money. In the corner is a graphic which says join in\",\"blocks\":[{\"type\":\"fragment\",\"model\":{\"text\":\"A c
-e380f647874e.jpg\",\"isEditorialImage\":true,\"height\":1080,\"width\":1920,\"alt\":\"A child holds a jar of pocket money. In the corner is a graphic which says join in\"},\"type\":\"article\",\"options\":{\"includeComments\":true,
,\"description\":\"Fewer children are getting weekly pocket money, with parents favouring rewarding for doing chores or getting a good school report.\",\"lastUpdated\":1751192516000,\"firstPublished\":1750062002040,\"lastPubli
"model\":{\"blocks\":[{\"type\":\"text\",\"model\":{\"blocks\":[{\"type\":\"paragraph\",\"model\":{\"text\":\"Pocket money - how do you earn it and how do you spend it?\",\"blocks\":[{\"type\":\"fragment\",\"model\":{\"text\":\"Pock
odel\":{\"image\":{\"alt\":\"A child is holding a jar with coins in it. There is a label on the jar that says pocket money\",\"copyright\":\"Getty Images\",\"height\":1080,\"width\":1920,\"src\":\"https://ichef.bbci.co.uk/ace/standa
> build · space-bunny-free
[0m$ [0mcurl -sL --max-time 40 -A "Mozilla/5.0" "https://www.bbc.co.uk/newsround/articles/cyvmd48rr9zo" | sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' > /tmp/nr.txt; echo "LINES:$(wc -l </tmp/nr.txt)"; grep -o -i -E ".{200}(per cent|percent|%).{200}" /tmp/nr.txt | grep -i -E "pocket|money|weekly|parent" | head -6
LINES:       9
adow:none;}@media all and (min-width: 48em){.ssrcss-1rbozls-StyledLink{padding-top:0;box-shadow:none;background-color:transparent;border-left:none;border-right:none;border-bottom-width:0rem;height:100%;display:-webkit-box;display:-webkit-flex;display:-ms-flexbox;display:flex;-webkit-align-items:center;-webkit-box-align:center;-ms-flex-align:center;align-items:center;max-width:8.125rem;}.ssrcss-1rbo
s-1uqdwtw-Promo{font-family:ReithSans,Helvetica,Arial,freesans,sans-serif;font-weight:400;font-feature-settings:'ss01' on;font-size:0.875rem;line-height:1.2857142857142858;position:relative;height:100%;background:#FFFFFF;outline:solid transparent;color:#606060;}.ssrcss-1uqdwtw-Promo a:not(.exn3ah94){z-index:2;position:relative;}@media (max-width: 18.74875rem){.ssrcss-1u1fh10-PromoSwitchLayoutAtBrea
s-oy6q75-Promo{font-family:ReithSans,Helvetica,Arial,freesans,sans-serif;font-weight:400;font-feature-settings:'ss01' off;font-size:0.875rem;line-height:1.2857142857142858;position:relative;height:100%;background:#181818;outline:solid transparent;color:#A8A8A8;}.ssrcss-oy6q75-Promo a:not(.exn3ah94){z-index:2;position:relative;}@media (max-width: 18.74875rem){.ssrcss-ebh4fe-PromoSwitchLayoutAtBreakp
> build · space-bunny-free
[0m◈ [0mWeb Search via Tinyfish "NatWest Rooster Money 2025 survey "30%" parents weekly pocket money children chores" 
> build · space-bunny-free
[0m◈ [0mWeb Search via Tinyfish "Rooster Money survey 2025 pocket money weekly percentage parents NatWest children 6-17" 
> build · space-bunny-free
[0m$ [0mcurl -sL --max-time 35 -A "Mozilla/5.0" "https://roostermoney.com/the-pocket-money-essentials-2024-2025/" | sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -o -i -E ".{150}(27%|regular pocket money|chores).{150}" | head -5
echo "=== FFNEWS ==="
curl -sL --max-time 35 -A "Mozilla/5.0" "https://ffnews.com/news/natwest-rooster-money-pocket-money-index-reveals-industrious-kids-are-working-harder-than-ever-as-generous-parents-increase-rewards-for-chores" | sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -o -i -E ".{130}(chores|9\.13|reward).{130}" | head -5
3.67 12 &#163;4.05 13 &#163;4.55 14 &#163;5.08 15 &#163;5.73 16 &#163;6.59 17 &#163;8.31 Kids overall income, which includes payments for doing extra chores and one-off rewards and treats follows a similar pattern, rising steadily as kids get older &#8211; starting at £4.99 per week for six-year-olds and
ng the lawn &#163;3.68 Cleaning the car &#163;3.33 Gardening &#163;1.66 Cleaning the windows &#163;1.54 Dusting &#163;1.11 As well as capitalising on chores, today&#8217;s kids are showing a good measure of entrepreneurial spirit too. Side hustles such as reselling possessions, tutoring, babysitting and p
=== FFNEWS ===
> build · space-bunny-free
[0m% [0mWebFetch https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026 
> build · space-bunny-free
[0m$ [0mcurl -sL --max-time 30 -A "Mozilla/5.0" "https://www.gohenry.com/uk/pocket-money-chores" | sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -o -i -E ".{100}(chores|million|billion|£1\.8|84).{100}" | head -6
y: 'a43027174d370050',cTplB: '0',cTplC:0,cTplO:0,cTplV:5,cType: 'managed',cUPMDTk:"/uk/pocket-money-chores?__cf_chl_tk=0zNIWAbZAqBpDwwrrmr3xY3DvFu3hsBts.lE5vHqIfM-1790739065-1.0.1.1-zbb61TwB_drRI_asiKH7baeU
f_chl_opt.cOgUQuery + window._cf_chl_opt.cOgUHash;history.replaceState(null, null,"/uk/pocket-money-chores?__cf_chl_rt_tk=0zNIWAbZAqBpDwwrrmr3xY3DvFu3hsBts.lE5vHqIfM-1790739065-1.0.1.1-zbb61TwB_drRI_asiKH7b
> build · space-bunny-free
# R2 Cross-Examination — UK Market & Compliance

## 1. Three points in your report I now accept

1. **Retention, not compliance, is my #1 risk.** RevenueCat 2026: **~72% of annual subscribers cancel in Year 1** (35% in Month 1). My R1 assumed "8 months paid." My £10–13k year-1 falls to **£5–7k**. [revenuecat.com](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026)
2. **Apple 5.1.4(b) bites outside the Kids Category.** Verified verbatim: apps *"in the Kids Category **or those that collect, transmit, or have the capability to share personal information… from a minor** must include a privacy policy and must comply with all applicable children's privacy statutes."* You cannot dodge kids-compliance by avoiding the category. [guidelines](https://developer.apple.com/app-store/review/guidelines)
3. **BGG non-commercial clause is real**, plus mandatory "Powered by BGG" logo, no data modification, no AI training, terminable at will. [XML API ToU](https://boardgamegeek.com/wiki/page/XML_API_Terms_of_Use)

## 2. Two points you got wrong

- **"Ship 17+" is self-defeating nonsense.** Apple's July 2025 tiers are 4+/9+/13+/16+/18+ — **there is no 17+**. And 17+/18+ kills the parent audience the whole thesis needs. [Apple, 24 Jul 2025](https://developer.apple.com/news?id=ks775ehf)
- **"GoHenry: 84M chores + £1.8B" is UNVERIFIED** at source (Cloudflare-gated). Your load-bearing moat number is uncheckable, and "chores = family life" rests on one Mumsnet thread, not data.

*Self-correction:* my R1's quote of 2.3.8 ("cannot include any terms… that imply the main audience… is children") is **not current text**. 2.3.8 reserves only the literal strings **"For Kids" / "For Children"** and requires 4+-appropriate imagery. I overstated it.

## 3. Rulings

**(a) TTRPG — no, but they set the ceiling.** Kanka free is real: "Unlimited entries. Unlimited campaigns… free forever", 400,000+ GMs, $4.99–$24.99/mo ([kanka.io/pricing](https://kanka.io/pricing), [kanka.io](https://kanka.io/)). World Anvil is a **weaker rival than I said**: free tier is 2 worlds / **5 articles** / 100MB; 3.5m = registered accounts ([pricing](https://www.worldanvil.com/pricing)). One real competitor, not two — and it's desktop-first, build-oriented, not recall-oriented. Not fatal; capped at ~£4–6k/yr.

**(b) Chore app — none of your four options.** *Apple:* **do not** take Kids Category (1.3 baggage is real but optional); rate 4+/9+; never write "For Kids"/"For Children". *Play:* **13+** — Families Policy triggers only *"if one of the target audiences for your app is children"*, **but** Play *"reserves the right to conduct its own review"* and misrepresentation → suspension ([Families](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en-GB)). So: no mascots, no "kids" wording. Real cost is **not** the listing — it's the **ICO Children's Code** (statutory, applies regardless of store rating) + DPIA + parental gate + **zero third-party analytics in the child path** (no Firebase). ~+2–3 weeks, +40% of a 6-week core.

**(c) Board game — not unviable.** BGG: licences *"case-by-case"* and *"we will **often** offer a commercial license **for free** for up to some specified number of users"* ([Commercial Use](https://boardgamegeek.com/wiki/page/BGG_XML_API_Commercial_Use)). A negotiation, not a veto — a veto only if you're a BGG substitute. BG Stats is live: **£4.99, 4.79★, 81 GB ratings** ([lookup](https://itunes.apple.com/lookup?id=892542000&country=gb)). #3 dies on the £4.99 ceiling, not the licence.

**(d) Not fatal — it's the product.** My "~30%" is **UNVERIFIED** in the BBC piece; the real figure is **27% of parents set up regular pocket money via Rooster at £3.85/wk** ([Rooster Essentials](https://roostermoney.com/the-pocket-money-essentials-2024-2025/)) — a *biased* sample. But direction of travel kills your thesis: parents are **"stepping up and rewarding more for chores"** (mowing £3.68, car £3.33) while total income *fell* 1% to £9.13 ([BBC, 16 Jun 2025](https://www.bbc.co.uk/newsround/articles/cyvmd48rr9zo)). UK is already migrating flat → chore-linked. That's the wedge.

## 4. Verdict

**#1 Chore & Allowance. Ranking unchanged.**

Must be true: (1) money never moves — internal ledger only, no top-ups/gifting; (2) zero third-party analytics/ads in the child path; (3) listing passes 2.3.8 first time + live DPIA before submission.

**Kill-criterion:** if, within **90 days** of launch, GB **trial→paid < 1.5%** *or* net paying subs **< 5,000**, kill and ship #3.
