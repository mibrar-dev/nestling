DARK + POLISH QA — Group B (design system now has --scrim, .card.hero). Re-read components.css first, fix via write_file, verify with get_file:
P08 [bug] Subtitle "Sat 4 Oct · Pip's happy week: 4 days" is still clipped (needs 256px, has 246px). Change copy to "Sat 4 Oct · Happy week: 4 days" and keep nowrap.
P12 [bug, dark] The "Maya is owed £4.20" card uses var(--ink) as background → turns white in dark. Use `.card.hero` (var(--hero-bg), text var(--on-hero), secondary var(--on-hero-2)); the "Payout time" button inside stays .btn-primary.
P13 [bug, dark] Scrim is var(--ink)+opacity → light-grey wash in dark. Use `.scrim` / var(--scrim).
Search all 10 files for any other `var(--ink)` used as a BACKGROUND and replace with an appropriate token (--hero-bg, --surface-2, --scrim). Reply: changelog.
