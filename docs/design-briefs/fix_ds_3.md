QA ROUND 3 — design system (global fixes; they propagate to all 30 screens). Use open-design MCP write_file, verify with get_file. Do NOT rename classes.
1. tokens.css: --leaf #1F9D63 → #17804F (white 4.96:1, paper 4.64:1). --sky #3D7FF0 → #2563D6. Add --lilac-strong: #6A58E8. Keep tints as they are.
2. components.css: .btn-kid.lilac background → var(--lilac-strong); .btn-kid.sky keep white text (now 5.5:1).
3. Tap targets ≥44px (parent): .segmented buttons height 44px (container 48 incl. padding); .toggle keeps its 51×31 visual but its hit area must be ≥44px tall (wrap with padding / min-height:44px on the input or label, no visual change); day-chip / .chip-day min 44×44; search .field input min-height 44; .nav-action (text buttons like Skip/Save) min-height 44 and padding 0 12px.
4. .fab: define a floating action button class if not present: position absolute; right 20px; bottom calc(var(--tab-h) + 16px); height 52px; add a companion rule `.screen:has(.fab) .scroll { padding-bottom: calc(52px + 32px) }` so list content can scroll clear of it.
5. Add utility `.balance { text-wrap: balance }` and apply text-wrap:balance to .h1, .display, .kid-title, .kid-hero by default.
Reply with a 5-line changelog.
