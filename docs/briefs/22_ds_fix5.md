ORCHESTRATOR QA — round 5 (small). Verified on device (design/qa/sim/fix7): P08 preview now matches the design — great; K03 header fixed. Remaining:
1. K03 kid quest card title "Empty the dishwasher" ellipsizes on device ("Empty the dishwash…") while the design shows it in full at the same card width. Match design/screens/light/K03-kid-home.png exactly: kid card title Nunito 800 17/22 (check SPACING_SPEC .quest-card.kid), icon tile 48, check 56, horizontal paddings/gaps per spec; title may wrap to 2 lines (never ellipsize kid titles — kids must read the whole quest).
2. Large-title NestNavBar action: render "+" as a 44×44 NestIconButton with the ic_plus icon (leaf colour), not a small text glyph.
VERIFY ON DEVICE: `bash tools/sim_shots.sh fix8`, READ light_25_screens-k03.png + light_14_nav-bars.png (+ dark variants), iterate. Gate: format, analyze clean, tests pass. No flutter clean.
Reply: changelog + PNGs checked.
