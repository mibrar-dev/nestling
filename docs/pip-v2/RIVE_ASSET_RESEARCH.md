# Rive Asset Research — Pip v2

Scouted 2026-10-01. Links + notes only; **no third-party asset files were downloaded into this repo**.

---

## 1. Licensing model (verified)

**Rive Marketplace / Community default licence = CC BY 4.0.**

- Rive docs, Marketplace Overview: *"Marketplace files are all shared under a CC BY license."* → <https://rive.app/docs/community/marketplace-overview>
- Rive Terms of Service §D-6c (last updated 20 May 2026): *"Community Content that is marked as Community is accessible to all Users, and may be remixed, modified and used by all Users, including saving as their own User Content within their separate Rive account, under the creative commons license described at https://creativecommons.org/licenses/by/4.0/"* → <https://rive.app/docs/legal/terms-of-service>
- CC BY 4.0 deed (<https://creativecommons.org/licenses/by/4.0/>): Share *"for any purpose, even commercially"*; Adapt *"remix, transform, and build upon the material for any purpose, even commercially"*.

So for every file below: **commercial use in a paid app = YES. Attribution = REQUIRED. Remixing/modifying = YES.**

### CC BY 4.0 obligations (what we owe)
1. Credit the creator by name, link the licence, link the original file.
2. **Indicate that changes were made** (required in 4.0 even for minor edits).
3. No DRM / additional restrictions.
4. Cannot imply the creator endorses us.
5. ⚠️ CC BY covers **copyright only** — it grants no trademark or personality rights.

### Attribution plan for Nestling
Ship an in-app "Open Source Credits" screen (Settings → About → Credits) listing: creator handle, file title, file URL, "Licensed CC BY 4.0, modified by Nestling." That satisfies 1–2 for all Marketplace-derived Pip art.

### Pricing / paid tier in 2026
- **The Marketplace itself has no paid-asset tier.** Everything published there is CC BY 4.0. Monetisation is on the *editor*, not the assets.
- Editor plans (docs table, <https://rive.app/docs/account-admin/pricing>): Free $0 (3 collaborative files) · Cadet $17/seat/mo or $108/seat/yr (3 seats) · Voyager $39/seat/mo or $304/seat/yr (25 seats) · Enterprise $1,440/seat/yr. *(`rive.app/pricing` marketing page shows $9/$32/$120 per seat on its annual toggle — inconsistent with the docs table. Treat docs table as authoritative; UNVERIFIED which is current.)*
- ⚠️ **Critical constraint:** the **Free plan cannot export `.riv` for runtime** — the Exports row is empty on Free and checked from Cadet up. We need **Cadet ($108/seat/yr) minimum** to ship Pip in the app.
- Rive runtimes are **MIT** (e.g. <https://github.com/rive-app/rive-flutter>) → commercial embedding is fine.
- "**For Hire**" badge on a creator profile = the creator is open to commission work. It is **not** a licence tier and does not restrict CC BY use.
- Third-party "premium Rive" storefronts exist (RiveFiles.com / "Rillic", invite-only) but are **not Rive** and their terms are **UNVERIFIED — do not use**.

---

## 2. Ranked candidates

Style fit = match to Pip (flat vector, bold dark-navy outlines, yellow/orange, round chibi chick). Quality = richness of motion + rig.

| # | File | Author | URL | Contains | Style | Quality |
|---|------|--------|-----|----------|-------|---------|
| 1 | **Interactive Character Rig — Bones, Joysticks & Data Binding** | aln.omrv | [28370-53642](https://rive.app/marketplace/28370-53642-interactive-character-rig-bones-joysticks-and-data-binding) | Nested leaf bone chains, per-vertex weights, nested clipping for pupils/lower lid, **5 joysticks** (head XY, pupil XY as 2D blends; blink/lid/brows as 1D sliders), 2 parallel SM layers (idle↔look + independent blink), data-binding trigger. Author explicitly invites remixing. | 4 | **5** |
| 2 | **Owl Mascot Expression Pack** | AnggaMotion | [25712-48015](https://rive.app/marketplace/25712-48015-owl-mascot-expression-pack-cute-cartoon-vector-for-app-ui-and-branding) | Expression set for a cute cartoon bird, SM-controlled, fully vector. Closest **species + style** match found. | **5** | 4 |
| 3 | **Rive App Mascot — Cloud Character, 6 Expressions** | AnggaMotion | [27043-50911](https://rive.app/marketplace/27043-50911-rive-app-mascot-cloud-character-with-state-machine-and-6-expressions) | 6 expression states in one SM; author states it drops straight into Flutter/SwiftUI/React/Web. Good *state-count* template. | 3 | 4 |
| 4 | **Character Mood States** | Noushin.Pourmirza | [27893-52723](https://rive.app/marketplace/27893-52723-character-mood-states) | Exactly our problem solved: **Idle / Happy / Angry** switchable states with different expressions *and* motion behaviours. | 3 | 4 |
| 5 | **AI Orb Mascot** | aln.omrv | [28088-53050](https://rive.app/marketplace/28088-53050-ai-orb-mascot) | Idle blink+breath, lean-in on typing, jump, wince. **Every expression driven by data binding** (typing/correct/wrong/jump), not canned loops. | 2 | **5** |
| 6 | **owl mascot** | AnggaMotion | [25561-47718](https://rive.app/marketplace/25561-47718-owl-mascot) | Second owl file, simpler; useful as a contrasting reference for a rounder/blobbier bird build. | 4 | 3 |
| 7 | **Interactive Bunny Character** | raivu | [24876-46460](https://rive.app/marketplace/24876-46460-interactive-bunny-character) | "Not just animated, but alive" — every click triggers a new pose/expression. 269 likes; most popular kid-mood reference. | 4 | 4 |
| 8 | **Character Mascot Walk** | raivu | [28373-53645](https://rive.app/marketplace/28373-53645-character-mascot-walk) | Walk-cycle mascot rig. Useful for the **fledgling/songbird walking** stages. | 3 | 3 |
| 9 | **Bird** | JcToon | [1750-3467](https://rive.app/marketplace/1750-3467-bird) | A real **bird**, hybrid raster body + vector feathers/feet/eyes, bones, SM. Author is a Rive animator. | 3 | 3 |
| 10 | **Interactive Character Follow** | alinazari | [28334-53514](https://rive.app/marketplace/28334-53514-interactive-character-follow) | Cursor-following character via constraints + SM. 218 likes. Head/eye tracking for free. | 3 | 4 |
| 11 | **Curious Phone Girl** | 3dfactor | [5845-11463](https://rive.app/marketplace/5845-11463-curious-phone-girl) | Rive's own "best of 2023" pick for **smooth facial expressions** + joysticks. Gold standard for blink/smile. | 2 | 5 |
| 12 | **Batter up, Bunny!** | MikkelBorris | [28142-54082](https://rive.app/marketplace/28142-54082-batter-up-bunny) | Full emotion arc: *scared → practice → confident*. Best reference for a **fear-to-confidence** state ladder. | 3 | 5 |
| 13 | **Sobo** | Patgrivet | [28761-54484](https://rive.app/marketplace/28761-54484-sobo) | Health-partner mascot, clickable states, built for a real product. Clean brand-mascot delivery. | 3 | 4 |
| 14 | **Cat Follow Cursor Demo** | **TeamRive** (Rive staff) | [24639-46040](https://rive.app/marketplace/24639-46040-cat-follow-cursor-demo) | Official runtime demo file. Canonical cursor-tracking rig. | 3 | 3 |
| 15 | **Bone-Based Lipsync Character** | HaiDo | [20725-39009](https://rive.app/marketplace/20725-39009-bone-based-lipsync-character-animation) | All facial motion bone-driven incl. lipsync. For Pip *singing* (stage 4). | 2 | 4 |
| 16 | **Little Boy** | Ducks | [12293-23439](https://rive.app/marketplace/12293-23439-little-boy) | 651 likes; the most-remixed Ducks character. Rive's own tutorial used a Ducks file. | 2 | 4 |

**Excluded — TRADEMARK RISK, do not use despite CC BY label:**
- *Interactive Duolingo Character* (baitangzi20041012, [15790-29762](https://rive.app/marketplace/15790-29762-interactive-duolingo-character)) and *Duolingo Prototype* (jessez-BQT4G, [26100-48769](https://rive.app/marketplace/26100-48769-duolingo-prototype)). The community user's CC BY covers *their file*; it does not grant Duolingo's character design. CC BY 4.0 grants no trademark rights. **Do not copy the art.** Study the technique only.
- *Anime Girl* (xandercorp, [6418-12437](https://rive.app/marketplace/6418-12437-anime-girl)) — author states *"The image is an AI generated image trace."* CC BY covers the trace, upstream image rights are **UNVERIFIED**.

---

## 3. Top 3 commercially-usable picks

All three: **CC BY 4.0 · commercial OK · attribution required · remixing allowed.** Evidence: the Marketplace page licence badge + <https://rive.app/docs/community/marketplace-overview> + <https://rive.app/docs/legal/terms-of-service> §D-6c.

**1. Interactive Character Rig — Bones, Joysticks & Data Binding** (aln.omrv)
The single most valuable file for us. It is a **rig**, not a character — no art to inherit, no style conflict, nothing to attribute in the UI. It teaches the exact architecture that turns "barely visible motion" into expressive motion: per-vertex bone weights, five joysticks mapped to head/pupils/lids/brows, and two independent state-machine layers. Author explicitly writes *"Free to remix. Take it apart, rewire the state machine... Break it — that's the point."*

**2. Owl Mascot Expression Pack** (AnggaMotion)
The best **art + bird** match in the Marketplace. Cute cartoon vector owl, expression-driven, same flat-illustration register as Pip. Use it as the colour-weight and stroke-weight reference, and as a sanity check that "cute bird mascot" reads at our sizes.

**3. Character Mood States** (Noushin.Pourmirza)
The direct fix for the owner's complaint. Three switchable mood states (Idle / Happy / Angry) that change **both expression and motion behaviour**, not just a smile. Structurally the same shape as our happy/eating/sleepy set — but with per-state body language, which is what makes motion read at a glance.

*Honourable mention:* **AI Orb Mascot** (aln.omrv) — same author as #1 and the best example of driving a character from real product data rather than canned loops. Pip's "hunger" and "energy" are perfect view-model properties.

---

## 4. Techniques to steal

**Rig (from #1 Interactive Character Rig)**
- **Nested leaf bone chains** — one root bone per limb group, children inherit. For Pip: `body → neck → head`, `body → tail`, `body → wingL/wingR`.
- **Per-vertex weights** — parent *and* blend across bones (e.g. cheek vertices 50 % head / 50 % body) so bends look organic rather than hinged.
- **Nested clipping** for pupils and lower eyelid — the single cheapest trick for a convincing blink.
- **Five joysticks, mixed types**: head XY + pupil XY as **2D blend** joysticks; blink, eyelid, brows as **1D blend** sliders. Bind the head joystick to touch/drag so a child can physically turn Pip's head.
- Freeze/origin each bone pivot before animating (learnrive.com rigging guide).

**State machine**
- **Two parallel layers**: Layer 1 = body/pose (idle, eat, sleep, celebrate), Layer 2 = independent blink loop. Layers mix additively, so Pip blinks *while* sleeping. This is why the current moods look dead — one flat layer means blink and mood fight each other.
- **Blend states, not clips**: mood should be a *slider*, not a state flip. `mood: 0 → 1` blends sad→neutral→happy continuously. Use 1D blends for intensity (how full/sleepy), 2D for direction (look-at).
- Give every state an **entry transition with non-zero duration** (200–400 ms) so nothing ever cuts.

**Data binding (from #5 AI Orb Mascot)**
- Drive the character from a **View Model** with typed properties: `hunger: Number`, `energy: Number`, `mood: Number`, `stage: Enum` (egg/hatchling/fledgling/songbird), plus `onEat: Trigger`, `onPet: Trigger`, `onHatch: Trigger`.
- `mood` maps to a blend; `energy` maps to blink rate + posture; `stage` is an **Enum**, which lets us swap Pip's whole body without new code.
- Prefer view models over legacy state-machine inputs — Rive is migrating toward data binding.
- Fire **actions on state start/end**, not just on value change, so Pip can react at the exact beat.

**Believability layer (from #11, #12)**
- Idle is never still: breath (chest scale), micro head-bob, occasional weight shift, **randomised blink interval** (2–5 s, not a fixed loop).
- Squash & stretch on every reaction — anticipation → overshoot → settle.
- Transitions carry the personality: pop-in with overshoot for happy, slow droop for sleepy, recoil for eating.
- Randomised particles/secondary motion on click (Ryuhei's *Character Facial Animation*, [14071-26544](https://rive.app/marketplace/14071-26544-character-facial-animation) — CC BY).
- Honour **reduced motion**: Rive exposes this and we should respect it for a kids' app.

**Reuse across 4 stages**
Build one artboard per stage and use a **Global View Model** (one instance shared file-wide) so `stage` drives all four artboards from a single source of truth.

---

## 5. Unverified / open questions

- **Pricing discrepancy** between `rive.app/docs/account-admin/pricing` and `rive.app/pricing` — confirm before budgeting.
- **RiveFiles.com / "Rillic"** paid marketplace — third party, terms UNVERIFIED, not recommended.
- **"For Hire" badge semantics** — inferred from marketplace layout, not documented by Rive. No licence impact either way.
- Whether *Interactive Sprout Mascot | Tamagotchi Mini-Game* (design-QYBVX) exists with a stable URL — appeared in tag listings but no direct link resolved. Would have been an excellent pet-care reference (feed/pet/sleep loops). Worth a manual Marketplace browse.
- All **quality scores are my judgement from descriptions and tags** — the files were not opened. Open each in the Rive editor before committing to a reference.
