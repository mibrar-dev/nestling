
## UPDATE (09:46, orchestrator QA of cmp_light_1, 6.47%) — exact targets for iteration 2
Measured on the 390-wide compare sheet (design → app; y in logical px):
1. Idea rows: title and meta LEFT-aligned at card x+64 (UI finding 1).
2. Search field: the icon is far too big (≈36 px; design ≈18 px glyph in a 44 px slot). The hint starts at design x ≈ 73 (UI finding 2). Field height and position: design top ≈ 173, bottom ≈ 226 (53 tall); the app field is shorter and higher. Match the HTML.
3. Segmented control (Active / Ideas): design track y ≈ 109–155 (≈46 tall, with a 4 px inner pad and the selected pill r=pill). The app track is ≈ 108–148 (≈40 tall). Match the HTML `.segmented` (padding 4, button height 40, min-height 44).
4. Category chips row: design centre y ≈ 250; app ≈ 239. List first card top: design ≈ 291; app ≈ 281. These follow items 2–3, so re-measure after fixing them.
5. Bottom tab bar (NestTabBar / parent nav): the icons and labels sit 34 px LOWER than the design (design icon centre ≈ y 749, label ≈ 772; app ≈ 783 / 806).
   - Owner rule: the bar's SURFACE runs to the physical bottom edge, but its CONTENT keeps the design's position: tab row top at the design's bar top (≈ y 726), and the extra surface sits below the labels, under the home indicator.
   - If the shared tab bar puts its content at the bottom instead, write SHARED_REQUEST.md with these numbers rather than hacking it locally.
6. List cards continue under the tab bar exactly as in the design (the 6th card peeks under the bar).
Add a real-font geometry test (FontLoader) pinning items 2–5 at 390×844.

## UPDATE (10:00) — shared items in progress
SHARED_REQUEST §1–§4 are being fixed on branch shared/shared_batch4: search field prefix, NestSegmented 52/44, tab bar content position, today test anchor. §5 decision: Active quests are ordered by CREATION order.
- Until main has these, do not hack them locally, and they are not P10 findings.
- Fix the P10-local items: row text left-aligned, plus the review/test findings that are local.
- After the merge, delete the hidden anchor.
