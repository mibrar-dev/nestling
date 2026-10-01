ROLE: Design-System Lead for "Nestling" (UK family chores app). You are sub-agent 1 of 4; an orchestrator (QA reviewer) will inspect your output in a browser at 390×844 for overflow, contrast and consistency.

The attached SPEC.md is the single source of truth. Read §0, §2, §3 and §6 carefully.

TASK (phase 1 only — do NOT build app screens):
Using the **open-design MCP** tools (`write_file`) into project **nestling-uk-family-chores-mobile-ui-e9c1**, create exactly these files:
1. `tokens.css` — @import Google Fonts (Nunito 700;800;900 and Inter 400;500;600;700), all tokens in §2 as CSS custom properties on :root, base reset (box-sizing border-box, margin 0), `-webkit-font-smoothing`, `font-variant-numeric: tabular-nums` utility `.num`.
2. `components.css` — every class in §3 with those EXACT class names and modifiers, pixel-accurate per spec. Include `.status-bar` markup expectations as a comment at the top (show the exact HTML snippet screen agents should paste for status bar, home indicator, tab bar with 4 tabs, keypad). Include text-overflow safety: `.truncate`, `min-width:0` on flex children in list rows/cards, `overflow-wrap:anywhere` on titles.
3. `design-system.html` — a scrollable showcase page (not device-sized; max-width 1100px) displaying: colour swatches with hex + name + contrast ratio vs white/paper, type scale samples (both fonts), spacing, radii, shadows, every component in parent & kid variants, all SVG assets, and the snippet library.
4. SVG assets per §3 "Assets": `assets/pip-stage-1.svg` … `pip-stage-4.svg`, `assets/coin.svg`, `assets/nest.svg`, `assets/app-icon.svg`. viewBox 0 0 240 240 (app icon 1024). Consistent character across stages (same eyes, beak shape, outline #1E1B3A 6px in 240-space). Cute, flat, round, UK-picture-book warmth. No gradients except one subtle highlight.
5. `index.html` — gallery exactly as §6 describes (all 30 screen iframes grouped, labelled; plus links to design-system.html). Page bg --paper, heading "Nestling — Mobile UI v1".

QUALITY BAR: no placeholder comments, full CSS (no "…"), valid HTML5, works when opened from disk (relative paths). Before finishing, call `list_files` on the project and `get_file` on each file you wrote to verify it is complete.
FINAL REPLY: table of files written (path | bytes | notes) + the exact snippet list screen agents must use.
