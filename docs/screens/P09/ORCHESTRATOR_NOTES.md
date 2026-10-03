
## UPDATE (17:14) — the plan file was restored
docs/screens/P09/1_plan.md was briefly overwritten with a 4-line stub by a loop bug. The full 258-line plan is back on disk. Builders: re-read it now.

## UPDATE (17:57, orchestrator QA of cmp_light_1, 1.71%)
1. Icon picker: the 6 glyphs and their ORDER must be exactly the design's (read the HTML for the icon names; light and dark PNGs). If a glyph is missing from app/assets/icons, write SHARED_REQUEST.md with the exact names and SVG source (from design/html-source) rather than substituting a look-alike.
2. "Hoover the stairs" text in the Quest name field starts at x ≈ 40; the design has x ≈ 37 (field x 20 + 1 px border + 16 px padding). Check NestTextField's horizontal content padding for this variant. If the cause is shared, write SHARED_REQUEST with the numbers.
3. Everything else is within tolerance. Do not move other elements.
