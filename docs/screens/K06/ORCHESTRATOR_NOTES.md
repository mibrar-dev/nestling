
## UPDATE (11:30, orchestrator QA of cmp_light_1, 3.67%) — iteration 2 targets
1. Locked wardrobe items (Wellies, Crown) must use the design's locked style: a dashed 3 px ink border on the card with a white surface, per the K06 HTML class for locked items; read the CSS. The app draws them as filled tiles with no border.
2. Wardrobe icons must be the design's glyphs: Scarf (design: the scarf/flag glyph) and Wellies (design: the boot glyph). The app uses look-alikes. If a glyph is missing from NestIcons, write SHARED_REQUEST.md with the SVG from the HTML. Do not substitute.
3. Prices: the design shows Wellies 30 and Crown 60; the app shows 40 and 120. If those prices come from the seed and the seed differs from the design, write SHARED_REQUEST.md (the seed mirrors the designs). Do not hard-code prices.
4. Pip (the child's own PipAvatar) and the nest are correct.

## UPDATE (13:52) — SHARED_REQUEST §1/§2/§3/§5/§6 are being fixed on shared/shared_batch7
That covers the glyphs, the prices (the seed moves to 30/60), the pet slot params, the kid-button third row and the dashed border. They are not K06 findings meanwhile. Once main has them, switch to the shared ones and delete the local copies, following the batch-7 report.
