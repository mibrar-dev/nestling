# R2 — Lottie & sprite asset scout (Pip v2)

**Scope:** candidate animated bird/chick characters, sprite sheets, Lottie animations and celebration effects for Pip (idle, happy, eating, sleeping, evolve, celebration) in a **paid UK consumer app**.
**App reality check:** `app/pubspec.yaml` already declares `lottie: ^3.6.1`, `rive: ^0.14.11` and folders `assets/animations/lottie/` + `assets/animations/rive/` — so Lottie/dotLottie/`.riv` files drop straight in with no dependency work.
**Method:** licence pages fetched and read directly; per-asset pages checked. Anything not proven from a primary source is marked **UNVERIFIED**. No third-party file was downloaded.
`dotLottie` (`.lottie`) carries no licence of its own — the underlying file's terms apply.

---

## Ranked candidates

`Fit`/`Qual` = style fit / quality, 1–5. `Comm` = commercial use. `Attr` = attribution required. `Mod` = modification allowed. `Mascot` = any restriction on using the asset as a brand mascot / logo / trademark.

| # | Asset / author | URL | Format | Moods | Fit | Qual | Licence (exact name) + evidence | Comm | Attr | Mod | Mascot |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **Custom Pip (own art, A1 design)** | internal `design/pip-v2/` | SVG → Lottie/Rive | all | 5 | 5 | **Owned work** — all rights reserved | Y | N | Y | **None — registrable** |
| 2 | **Animal Pack** — Kenney | kenney.nl/assets/animal-pack | vector + PNG + sheets | parrot/penguin; no moods | 3 | 4 | **Creative Commons CC0 1.0** (kenney.nl/support: "all game assets… are public domain licensed (CC0)") | Y | N | Y | No clause; only their logo reserved |
| 3 | **Animated Birds (32×32)** — MoikMellah | opengameart.org/content/animated-birds-32x32 | sprite sheet PNG | flap/fly | 2 | 3 | **CC0** (page: "License changed to CC0 — do as you wish") | Y | N | Y | none |
| 4 | **(Update) Animated Birds character sheet** — OGA | opengameart.org/content/update-animated-birds-character-sheet | sprite sheet | flap/fly | 2 | 3 | **CC0** (listed on CC0 resources page) | Y | N | Y | none |
| 5 | **SunnyLand** — ansimuz | ansimuz.itch.io/sunny-land-pixel-game-art | PNG sheets + Aseprite | idle/run/hit; pixel | 1 | 5 | **Creative Commons Zero v1.0 Universal** (itch asset-license field) | Y | N | Y | none |
| 6 | **Monsters Creatures Fantasy / Wizard Pack** — LuizMelo | luizmelo.itch.io/monsters-creatures-fantasy | PNG sheets + Aseprite | idle/run/attack/hit/death | 2 | 4 | **CC0** (page: "can be used in commercial and non-commercial projects… Credits are not required") | Y | N | Y | none |
| 7 | **Chick Hatching** — Swap Motions | lottiefiles.com/free-animation/chick-hatching-k4Af66JNix | Lottie JSON / dotLottie | **evolve / hatch** | 4 | 4 | **Lottie Simple License (FL 9.13.21)** — lottiefiles.com/page/license | Y | N | Y | no clause; **no trademark grant** |
| 8 | **flying bird** — modor | lottiefiles.com/free-animation/flying-bird-42V3cjeSpH | Lottie JSON / dotLottie | flap / happy | 3 | 3 | Lottie Simple License (FL 9.13.21) | Y | N | Y | no clause; no trademark grant |
| 9 | **Owl Flying Animation** — Faiq Ahmed | lottiefiles.com/free-animation/owl-flying-animation-VvKz34OS0H | Lottie JSON / dotLottie | flap / sleep? | 2 | 3 | Lottie Simple License (FL 9.13.21) | Y | N | Y | no clause; no trademark grant |
| 10 | **Interactive Bunny Character** — raivu (Rive Marketplace) | rive.app/marketplace/24876-46460-interactive-bunny-character | `.riv` (state machine) | idle/happy/interactive | 4 | 5 | **CC BY** — rive.app/docs/community/marketplace-overview: "Marketplace files are all shared under a CC BY license" | Y | **Y** | Y | CC grants no trademark rights |
| 11 | **Animated Login Character** — JcToon (Rive) | rive.app/marketplace/2244-7248-animated-login-character | `.riv` | idle/happy | 3 | 4 | **CC BY** (badge on asset page + Rive docs) | Y | **Y** | Y | CC grants no trademark rights |
| 12 | **Cute Fowl Animal Chicken Character** — segel (GDM) | gamedevmarket.net/asset/cute-fowl-animal-chicken-character | 2D sprites | idle/happy/eat | 4 | 4 | **GDM Pro Licence** — terms-conditions cl. 4 | Y | N | Y | **T&C 4.2(a) forbids logo/trademark/service mark** ⚠ |
| 13 | **Free Top-Down Animals Farm Pixel Art** — CraftPix | craftpix.net/freebies/free-top-down-animals-farm-pixel-art-sprites | PNG/PSD sprites | walk/idle | 2 | 3 | **CraftPix "FREEBIE PRODUCTS" licence (§2)** — craftpix.net/file-licenses/ | Y | N | Y | no logo clause; forbids source redistribution (§2.2.1) + **AI-training ban (§3)** |
| 14 | **useAnimations** — Patrik Svoboda | useanimations.com/licencing-and-terms.html | Lottie JSON + SVG | micro-UI only | 2 | 4 | **CC BY** for files ("distributed under Creative Commons (CC) Attribution (BY) unless stated otherwise"); GitHub wrapper is MIT — *not* the widely-quoted "MIT", which contradicts the site | Y | **Y** | Y | none stated |
| 15 | **Lottieicon paid library** — Lottieicon | lottieicon.com/license | Lottie JSON | idle/happy/celebration | 4 | 4 | LottieIcon **Paid Licence** (free tier is **non-commercial only**) | Y | N | Y | no logo clause stated |
| 16 | **IconScout Birds/Chick lotties** — IconScout | iconscout.com/lottie-animations/birds | Lottie JSON / dotLottie / GIF | all | 3 | 3 | **IconScout Digital License** — iconscout.com/licenses | Y | N | Y | ❌ **"No Use in Trademark and Logo… can not use the content as part of a trademark, design mark, business name, service mark, or logo" — even on paid plans** |
| 17 | **Storyset / Freepik illustrations** — Freepik | storyset.com/terms | animated SVG / Lottie | idle | 2 | 3 | **Freepik/Storyset Terms cl. 5** | Y | Y (free tier) | Y | ❌ **"Does not use the Storyset Content… in any trademark, logo or part of the same"** |
| 18 | **Flaticon animated icons** — Freepik | flaticon.com/legal §8.1 | Lottie / SVG | micro | 2 | 3 | **Flaticon License (Free tier)** | Y | **Y** | Y | ❌ logo/mark restriction via Freepik terms |
| 19 | **Birds (37 sprites)** — Onocentaur (itch) | itch.io (search "Birds — Onocentaur") | sprite sheet PNG | various | 3 | 4 | **UNVERIFIED** — per-asset itch licence not read | ? | ? | ? | ? |
| 20 | **Big Chickies — Art Assets** — Alex Pandaroo (itch) | itch.io (search title) | sprite sheets, 300+ | various | 3 | 3 | **UNVERIFIED** — licence not stated on listing | ? | ? | ? | ? |

### Celebration effects (all Lottie Simple License FL 9.13.21 — same commercial/no-attribution terms)

| Effect | Author | URL |
|---|---|---|
| Confetti | Shubh Dubey | lottiefiles.com/free-animation/confetti-3ofTs67sBx |
| confetti on transparent background | Sportbank Design | lottiefiles.com/free-animation/confetti-on-transparent-background-ajhx1TPBa7 |
| Celebration | Mathias Fiedler | lottiefiles.com/free-animation/celebration-mAnHKjVEgy |
| celebration_confetti.json | Ruben Lara | lottiefiles.com/free-animation/celebration-confetti-json-QIroMtQ1Or |
| Confetti – Full Screen | Rohith R Krishnan | lottiefiles.com/free-animation/confetti-full-screen-xgkBYevLrg |

Use the JSON/dotLottie export (transparent layer over live UI); GIF/MP4 flatten the background.

---

## Top 5 safest commercial picks

1. **Custom Pip, animated in-house (#1)** — sole ownership, no attribution, registrable as a UK trade mark, no upstream claims. The only *fully* safe option.
2. **Kenney Animal Pack (CC0) as rig reference (#2)** — public-domain vector source (parrot/penguin), clean shapes, zero licence strings. Recolour into Pip; don't ship Kenney's pixels.
3. **Swap Motions "Chick Hatching" (#7)** — Lottie Simple License: commercial, modifiable, **no attribution required**. Safe for the *evolve* beat; don't present it as "the Pip mascot" in brand materials.
4. **CraftPix freebie Top-Down Animals (#13)** — freebie licence permits commercial use, modification and no credit; forbids only reselling/redistributing source art (fine in a compiled app).
5. **LottieFiles confetti set** — LSL, commercial, no attribution, transparent-background JSON. Ideal celebration overlay.

Avoid entirely as Pip: **IconScout (#16), Storyset (#17), Flaticon (#18)** — all three carry an explicit logo/trademark/service-mark prohibition.

---

## Legal note — mascot & trademark restrictions

**Why stock art is legally weak as a brand mascot, even when "commercial use: yes".**

1. **The licence is non-exclusive.** LottieFiles LSL, GDM Pro, Storyset and CraftPix all grant *you* rights — none enjoins anyone else. The same bird is already on LottieFiles, Freepik and a dozen Shopify stores. A mascot is a *brand identifier*; sharing it with unlimited competitors destroys the one thing it is for.
2. **No stock licence grants trade mark rights.** Copyright covers the artwork; trade mark rights come from use as a source identifier. Creative Commons states it plainly: *"Creative Commons does not recommend using a CC license on a logo or trademark… the special purposes of trademarks make CC licenses an unsuitable mechanism for sharing them"* (creativecommons.org/faq). Rows 10, 11 and 14 are CC BY — commercial yes, trademark no.
3. **Three sources forbid it outright.** IconScout: *"No Use in Trademark and Logo — You can not use the content as part of a trademark, design mark, business name, service mark, or logo."* Storyset cl. 5 and Flaticon/Freepik carry the same ban. These survive paid plans.
4. **⚠ GameDev Market conflict.** Asset-page summary bullets appear to allow *"Use the asset or Derivative Works in a logo, trademark or service mark"*, but the binding Marketplace Terms **cl. 4.2(a)** says a Licence does **not** allow it. **Do not rely on GDM for a mascot** — if ever needed, get written clarification from GDN and archive it in `docs/legal/`.
5. **Provenance risk.** Many "cute bird/chick" packs are traced from protected characters (Angry Birds, Pokémon, Duolingo). Marketplace licence compliance does **not** cure a bad upstream chain — GDM cl. 6.9 leans on a seller warranty only, and their own forum discusses marketplace plagiarism.
6. **CraftPix §3 forbids using its assets for AI training/validation.** Not a shipping issue, but relevant if a Nestling pipeline ever ingests third-party art into a model tool.

**Why custom Pip is safest.** Copyright is ours from the outset, no third-party licensor to breach, no attribution string to ship, no competitor who can license the identical character, no upstream provenance question. That is what makes the art registrable as a UK trade mark (word mark on "NESTLING" plus a device mark on the Pip silhouette) and enforceable. Stock art can never give that, at any price.

---

## Recommendations

1. **Ship Pip custom.** Take the A1 design directions, then rig in Rive (already a dependency) for state-machine moods — idle (breathe + blink), happy (jump/flap), eating (peck + crumbs), sleeping (closed eyes + slow breath), evolve. One rig, 4 stages, all moods; reads at 48 px and 280 px; no licence strings in the app.
2. **Steal only *effects*, never the *character*.** Ship 2–3 Lottie Simple License confetti/celebration files plus a hatching-egg burst for the evolve beat. Generic effects, never presented as the brand, unambiguous terms.
3. **Use CC0 art strictly as construction reference** (Kenney Animal Pack, OGA bird sheets, ansimuz) — silhouette, rig topology, animation timing. Never ship the pixels.
4. **Keep an asset ledger.** For anything imported record: URL, exact licence name + version, date fetched, evidence URL, attribution decision → `docs/legal/ASSET_LEDGER.md`.
5. **If commissioning,** buy outright *assignment* (not CC BY, not "exclusive to you") with an originality warranty and a trademark-assignable clause. ≈£600–£2,000 for a 5-mood rig on existing vectors — cheaper than the legal risk of doing it wrong.
6. **Re-verify before any future purchase.** Licences drift — useAnimations' own terms contradict the "MIT" widely quoted for it. Re-read the primary page on the day of download and archive a screenshot.