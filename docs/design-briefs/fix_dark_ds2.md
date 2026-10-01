DARK QA round 2 — design system. Add 3 token groups (light + dark, both dark blocks), verify with get_file:
1. --scrim: light rgba(30,27,58,.45) / dark rgba(0,0,0,.62). Add `.scrim{background:var(--scrim)}` (never derive scrims from --ink — in dark, ink is near-white, which produced a light-grey wash on P13).
2. --hero-bg / --on-hero / --on-hero-2: light #1E1B3A / #FFFFFF / #C9C4DC; dark #2A2640 / #F3F0FA / #C9C4DC. Add `.card.hero{background:var(--hero-bg);color:var(--on-hero)}` (P12's balance card used var(--ink) as background and turned white in dark).
3. `.btn-apple`: light = #000 bg, #fff text; dark = #fff bg, #000 text (Apple Sign in HIG: use the white style on dark backgrounds). `.btn-google`: light = #fff bg + 1px var(--line); dark = #131314 bg, #E3E3E3 text, 1px #8E918F border (Google branding dark theme).
Reply: 3-line changelog.
