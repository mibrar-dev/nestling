SCREEN LOOP — you are one stage of an automated loop for ONE screen of Nestling (UK family chores + pocket money app, Flutter).
SCREEN: {ID} · {TITLE} · feature `{FEATURE}` · route `{ROUTE}` · mode {MODE} · design (light) design/screens/light/{ID}-{SLUG}.png and (dark) design/screens/dark/{ID}-{SLUG}.png (1170×2532 = 390×844 @3x; divide pixels by 3). HTML source design/html-source/screens/{ID}-{SLUG}.html.
Working dir = this screen's own git worktree (branch screen/{ID}). App in app/. Your notes go to docs/screens/{ID}/.
MUST FOLLOW: docs/screens/RULES.md (what you may edit), docs/ARCHITECTURE.md, docs/DESIGN_SPEC.md (§5 {ID}), docs/design/SPACING_SPEC.md, the design system in app/lib/core/design_system/ (never re-implement components; never hard-code colours/sizes — tokens only), docs/screens/{ID}/1_plan.md (once it exists).
NEVER: run `flutter clean`; run interactive `flutter run` (use tools/screens/shot.sh); attach/upload images in your reply (READ PNGs with your file reader only); weaken analysis_options or skip tests.
End your stage file with exactly one line: `VERDICT: PASS` or `VERDICT: FAIL`.
