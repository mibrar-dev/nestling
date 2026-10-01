TASK: DARK MODE — design system (phase 1 of the dark pass). Project nestling-uk-family-chores-mobile-ui-e9c1, open-design MCP only (get_file / write_file, verify after).
Screen agents will audit their screens after you, so the mechanism must be global and automatic.

1. tokens.css — add a dark theme that overrides the SAME token names (no new names for screens to learn):
   `:root[data-theme="dark"] { … }` AND `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { … } }` (identical values; keep them in sync).
   Parent dark palette direction (warm plum-night, not pure black): --paper ≈ #15131F, --surface ≈ #1F1C2E, --surface-2 ≈ #2A2640, --line ≈ #363150, --ink ≈ #F3F0FA, --ink-2 ≈ #C9C4DC, --ink-3 ≈ #A09AB9.
   Brand/semantic on dark: lighten so they read on --paper (--leaf ≈ #3CC98A, --sky ≈ #7FA9FF, --lilac ≈ #A89BFF, --coin stays #F4B400, --peach ≈ #FF9E78, --danger ≈ #FF7A7A, --warning ≈ #F0A83A). Tints become deep translucent washes (e.g. --leaf-tint ≈ #173A2B, --coin-tint ≈ #3A2F10, --lilac-tint ≈ #2B2550, --sky-tint ≈ #1A2A4A, --peach-tint ≈ #3E261D) and the *-ink tokens become light (e.g. --leaf-ink ≈ #8EE6BC, --coin-ink ≈ #FFD86B).
   Add ONE new token pair used for text ON solid brand fills: --on-leaf (light: #FFFFFF; dark: #0E1A14) and --on-accent (light #FFFFFF; dark #14121F). Then in components.css make .btn-primary / .btn-kid.leaf / .fab / .tab active pill etc. use var(--on-leaf) for text so dark buttons (#3CC98A) get dark text.
   Kid-mode night theme: --kid-sky-top ≈ #1B2150, --kid-sky-bottom ≈ #2C3572, --kid-meadow ≈ #1E4A3A; kid cards use --surface. Add a subtle star field for `.screen.kid` in dark via a background-image of tiny radial-gradients (no extra files).
   Shadows in dark: use rgba(0,0,0,.35–.5).
2. components.css — audit every rule for hard-coded colours (#fff, #000, rgba(30,27,58,…), white). Replace with tokens so dark works. Status bar icons use currentColor=var(--ink). Inputs, toggles (off-track), keypad keys, sheets, scrims (dark: rgba(0,0,0,.6)), chips, segmented (selected pill = --surface), progress tracks (--surface-2), .pet-stage ground shadow.
   Illustrations (Pip, nest, coin) keep their colours; add `.pet-stage` dark treatment: a soft radial glow (rgba(255,255,255,.08)) behind Pip so the ink outline doesn't vanish into the night.
3. CONTRAST RULE: every text/background token pair used by components must be ≥4.5:1 (≥3:1 for ≥24px bold) in BOTH themes. Compute and list them.
4. design-system.html: add a Light/Dark toggle button (top-right) that sets document.documentElement.dataset.theme, and show the dark swatch table with contrast ratios.
5. index.html (gallery): add the same Light/Dark toggle. Try to set data-theme on each embedded screen via contentDocument; wrap in try/catch because file:// may block it, and in that case show a small note "Dark previews follow your system appearance". Do NOT edit any screens/*.html — screens pick up dark automatically through the @media block (the orchestrator emulates prefers-color-scheme: dark for screenshots).
Reply: changelog + contrast table (token pair → light ratio / dark ratio).
