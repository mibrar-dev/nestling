# Orchestrator notes for P03 (mandatory)

## QA of cmp_light_1 (13.15%) — targets for iteration 2
1. Header ~16 px high is SHARED (fix in progress on main) — do NOT patch the back row / title position locally.
2. Title must break like the design: "Create your / family account" (constrain the title width from the HTML; no hard "\n"; must still wrap sensibly at 320 / scale 1.3).
3. The design shows the FILLED state (email sarah@example.co.uk, 18-char password, enabled green "Create account"). The empty state on launch is correct product behaviour — keep it. To compare the filled state, add a widget test that enters the design's values and asserts: button enabled with the primary green token, password dots, eye icon; and in the UI stage also capture a filled screenshot by typing into the fields on the simulator (xcrun simctl / the iOS simulator tool: tap field, type text) — compare THAT capture with the design.
4. "At least 8 characters" hint: left-aligned with the field/label edge (x = 20 px gutter), not indented 16 px; 6 px below the field.
5. Legal footer: "By continuing you agree to our Terms and" / "Privacy Notice" — two centred lines with normal line height (no big gap), links in the design's link style (underline, link colour), inside the bottom panel that runs to the screen edge (owner rule).
6. "No child emails or photos — ever." row: shield icon + text on one baseline, left edge at the 20 px gutter.

## QA of cmp_light_2 (5.08%, was 13.15%) — remaining items for iteration 3
1. Legal footer: keep "Privacy Notice" together (non-breaking space U+00A0 between the words) so it reads "By continuing you agree to our Terms and" / "Privacy Notice" exactly like the design.
2. Subtitle copy: curly apostrophe "You’re" (U+2019) as in the design/HTML; it should break "Children never / need an email." at 390 width (check the subtitle text style size/letter-spacing vs the HTML — the app's line is slightly wider).
3. The FILLED-state capture is still missing: in stage 5 type sarah@example.co.uk + an 18-character password into the fields on the simulator (tap field → type) and compare that capture with the design (enabled green button, dots, eye). Keep the empty launch state as is.
