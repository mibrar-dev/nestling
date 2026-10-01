DARK QA — Group A (design system now has --scrim, .card.hero, .btn-apple, .btn-google). Re-read components.css, then fix via write_file, verify with get_file:
P03: use .btn-apple and .btn-google classes for the two sign-in buttons (no local colours) so dark mode shows the white Apple button and the dark Google button.
P17: if your scrim uses any ink-derived colour, switch to var(--scrim).
All 8 screens look good in dark otherwise. Reply: changelog.
