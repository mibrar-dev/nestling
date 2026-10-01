POLISH — Group B, 1 item (open-design MCP write_file, verify with get_file):
P08 Today: the greeting now wraps ("Good morning, / Sarah") and the subtitle orphans "days". Fix the header: row = [greeting block (flex:1, min-width:0)] [+ button 44] [S avatar 44] with 8px gap. Greeting font h2 (22/28) Nunito 900 on ONE line: "Good morning, Sarah". Subtitle 15px on one line: "Sat 4 Oct · Pip's happy week: 4 days" (use .truncate if needed but it should fit: check width). No orphans anywhere on the screen.
Also: replace every hard-coded colour in your 10 screens (hex/rgb/white) outside SVG artwork with design-system tokens (a dark theme is coming). SVG UI icons must use currentColor.
Reply: changelog.
