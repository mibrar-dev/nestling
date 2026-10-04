# Shared request — K09 My jar

Need: move the `kid: true` gloss in `NestProgress` inside the fill. It
currently paints the white 55% gloss across the whole track
(`Positioned(left: s1, right: s1)` in
`app/lib/core/design_system/components/nest_progress.dart:43-58`), but the
design (`components.css:160`, `span::after` inside `span`) clips it to the
fill — measured on `design/screens/dark/K09-jar.png`: fill leaf runs
x 43.7…229.3 and the gloss stops at the fill's right edge. In dark mode the
app renders a white band over the empty 38% of the bar; light mode hides it
(white on white). One-line fix: wrap the fill in a `Stack` and put the
`Positioned` gloss there, or clip the gloss to
`FractionallySizedBox(widthFactor: f)`. Pre-existing app-wide
(`kid_home_view.dart:495`, `pip_growth_card.dart:83` ship the same bar), so
the fix benefits every screen.
Files: `app/lib/core/design_system/components/nest_progress.dart`
Blocks: no — K09 lands without it; stage 5 must not attribute the dark-mode
band to K09.
