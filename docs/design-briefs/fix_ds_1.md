QA REVIEW — round 1 (design system). Fix ALL items below via the open-design MCP (`write_file`) in project nestling-uk-family-chores-mobile-ui-e9c1, then `get_file` to verify.

BUG-1 [blocker] components.css line 20 forces `html, body { width:390px; height:844px; overflow:hidden }` on EVERY page. Result: design-system.html and index.html are clipped to a 350px column and cut off at 844px (cannot scroll). Fix: scope device sizing to screen pages only:
  `html:has(> body > .screen), body:has(> .screen) { width:390px; height:844px; margin:0; overflow:hidden; }`
  and remove the hard-coded `body { background:#E9E2D5 }` (use no global body bg; design-system.html/index.html keep var(--paper)). Verify design-system.html becomes a full-width (max 1100px) scrollable page.
BUG-2 [major] Pip evolution is not visible: stages 2, 3, 4 have the same body size/silhouette. Redraw so growth is obvious at a glance while keeping the same face (eyes, beak, outline):
  - stage-2 Hatchling: smallest round body (~55% of canvas height), fluffy, half eggshell on head, tiny stub wings.
  - stage-3 Fledgling: ~70% height, slightly pear-shaped, visible leaf-green wing tips, small head tuft, little feet.
  - stage-4 Songbird: ~85% height, taller slimmer bird silhouette with a proper tail (3 lilac tail feathers), spread lilac/leaf wings, peach scarf, confident pose, feet on ground. Must read as "grown up" next to stage 3.
  Keep all ground shadows at the same baseline so stages align when shown side by side.
BUG-3 [minor] coin.svg: the vertical leaf reads like an eye. Rotate the leaf 35° and add a short stem + midrib so it reads as a leaf; add a thin inner ring highlight.
BUG-4 [minor] index.html: when a screen file does not exist, the iframe shows a browser error page over the "Pending" placeholder. Make the iframe background transparent and put the placeholder behind it (z-index) so existing screens cover it; OR detect load errors via fetch HEAD in a small script and hide missing iframes. Either is fine; must work from file://.

Reply with a short changelog per BUG id.
