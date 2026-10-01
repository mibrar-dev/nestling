ROLE: App Store Optimisation (ASO) designer. New sub-agent. Project nestling-uk-family-chores-mobile-ui-e9c1; open-design MCP only (list_files/get_file to study screens; write_file to create).
Nestling = UK family chores & pocket-money app (see SPEC.md attached). All 30 app screens already exist in `screens/*.html` (390×844 each). You will compose MARKETING SCREENSHOTS that embed the real screens.

METHOD (best practice from leading App Store screenshot skills):
- Screenshots are ads, not docs: each slide sells ONE benefit, headline readable in 1 second at thumbnail size (≤ 6 words headline, optional ≤ 8-word subline).
- Never repeat the same phone placement on adjacent slides (alternate: centred-large, tilted-left, bleed-bottom, two-phones overlap, phone-right with callout, etc.).
- Consistent brand system across the set: Nestling tokens (link ../../tokens.css — it has fonts & colours), Nunito 900 headlines, alternating backgrounds (cream --paper, brand leaf #17804F with white text, lilac-tint, kid night-sky gradient). Pip mascot (../../assets/pip-stage-*.svg) may peek/perch on devices; coins (../../assets/coin.svg) as accents. Keep 5% safe margins.
- Device: draw a GENERIC modern phone frame in CSS (rounded 12% radius, 2.2% bezel, dark #0D0C14 body, small pill camera). Do NOT use Apple product names/logos or copyrighted frames. The screen inside is an <iframe src="../../screens/XXX.html" width="390" height="844" scrolling="no"> scaled with CSS transform to fit the frame exactly (transform-origin: top left; compute scale = innerScreenWidth/390).
- STORE POLICY: Apple 2.3.8 / 5.1.4(b) apply to screenshots: NO "for kids"/"for children" wording and nothing implying children are the main audience. Speak to parents ("your family", "your children"). No prices except "14-day free trial" on the final slide. No fake reviews/awards/ratings. UK spelling.

DELIVERABLES (exact files):
A) iOS 6.9" set — canvas exactly 1320×2868 (html,body{width:1320px;height:2868px;margin:0;overflow:hidden}): `store/ios/01-hero.html` … `store/ios/08-privacy.html`
   01 hero: "Chores they actually want to do" — K03-kid-home (big, centred), Pip perched on phone top, app icon + "Nestling" wordmark.
   02 "Set a quest in seconds" — P09-quest-editor (tilted left 6°) + floating P10 template chips.
   03 "Pip grows as they help" — K07-evolution + a row of the 4 Pip stages under it.
   04 "Pocket money, sorted" (sub: "No bank card needed") — P12-money.
   05 "Approve with one tap" — P11-approvals.
   06 "Rewards you choose together" — K08-shop.
   07 "Payout day, made fun" — two phones: P13-payout (parent, back) + K10-payout-day (child, front, overlapping).
   08 "Private by design" (sub: "No ads. No tracking. Data kept in the UK.") — P04-privacy + "Try free for 14 days" pill.
B) Google Play phone set — canvas exactly 1080×1920: `store/play/01-hero.html` … `store/play/08-privacy.html` — same stories re-laid out for the 9:16 ratio (not a squashed copy).
C) Google Play feature graphic — exactly 1024×500: `store/play/feature-graphic.html` — cream background, Pip stage 4 on nest left, headline "Chores that feel like a game." right, no device frame, no text in the outer 15% edges except logo.
D) `store/index.html` — a review board showing all 17 compositions scaled down with labels.

QUALITY: award-level, cohesive, bold typography (iOS headline ~118px/1.05, Play ~96px), generous whitespace, no clutter, no overflow outside canvas. The orchestrator will render every file headlessly to PNG at exact size and QA for text overflow, clipped devices, low contrast and policy wording, and send fixes back.
Reply: table of files + headline per file.
