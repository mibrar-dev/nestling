# Orchestrator notes for P02 (mandatory)

## QA of cmp_light_2 (4.05%) — targets for the next iteration
1. The value tour is a MARKETING carousel shown before any family exists. Its sample cards are ILLUSTRATIONS: use the design's exact static copy and data (titles, "Maya · weekly", "Leo · once", "Maya · daily", coin values, "4 of 6 quests done today", date "Sat 4 Oct"), NOT the database. (This is the one exception to the data-over-mocks rule.) Same for every page of the tour.
2. Typography of copy: use the design's typographic punctuation exactly — curly double quotes “Put the bins out” and the em dash —, i.e. "Pick from 40+ ready-made jobs like “Put the bins out” — or make your own." Check every page's copy against design/html-source/screens/P02-value-tour.html character by character.
3. No truncation: "Empty the dishwasher" must render in full on one line at 390 width (match the design's title/badge widths; badge must not squeeze the title). Also check 320 width + text scale 1.3 wraps rather than ellipsises where the design has room.
4. Keep the owner's bottom-edge rule (Next panel surface runs to the screen edge) — currently correct.
