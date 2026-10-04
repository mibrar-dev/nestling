# Shared request — K07 background deviation + a screen-scoped load

Two items for the orchestrator. **Neither blocks the K07 build**: item 1 asks
for a note only, item 2 is an accepted-as-is finding this screen is deferring.
Everything else iteration 2 needs is in-feature (`app/lib/features/pip/**`) or
already shared.

## 1. Record the K07 KID BACKGROUND deviation (a note, no code)

Need: the loop brief's KID BACKGROUND rule says every K screen gets the sky
gradient and the meadow hills from the shared kid scope, and K07 deliberately
does not. `design/html-source/screens/K07-evolution.html:16` overrides
`.screen.kid`'s background with `--kid-stars` +
`radial-gradient(118% 62% at 50% 36%, var(--lilac-tint) 0%, var(--surface)
58%, var(--lilac-tint) 100%)`, and the K07 body has **no `.meadow` element**
at all (the `.meadow` rules at lines 7–9 are dead boilerplate), so there is
nothing for the shared hills to be placed in. Both design PNGs
(`design/screens/light|dark/K07-evolution.png`) show no sky and no hills. K07
therefore paints a screen-local `PipEvolutionGlow` (exact CSS transcription) plus
the **shared** `NestKidStarsPainter` in dark mode, and no local hills anywhere.

`4_review.md` finding 9 asked for exactly this: the deviation is right, but a
loop that only sees the KID BACKGROUND rule would "fix" it to `KidScope` and
produce blue sky + green hills on a screen whose design has neither. Please
record the exception next to D1–D3 in
`docs/screens/K07/ORCHESTRATOR_NOTES.md` (or wherever the shared kid-background
rule lives) so the next iteration does not undo it.

Files: none to change — `app/lib/core/design_system/theme/kid_meadow.dart`,
`kid_scope.dart` are used exactly as they are today.
Blocks: **no**.

## 2. A screen-scoped load event (deferred, `4_review.md` finding 2)

Need: `PipLoadRequested` opens **both** `watchNest()` (K06) and
`watchEvolution()` (K07), so on `/pip-evolution` the nest stream (child row +
wardrobe rows + the ordered-stage combine) is opened, watched and thrown away
— extra Drift table watches per screen entry for data no widget on that route
renders. `docs/ARCHITECTURE.md:85` mandates exactly one
`<Feature>LoadRequested` event per feature, which is why the screen branch did
not change it, and `4_review.md` accepted the finding as-is.

Two candidate rulings, either of which unblocks it:

- a `PipLoadScope { all, evolutionOnly }` field on the **existing**
  `PipLoadRequested` (default `all`, so K06 and every current test are
  unchanged), with `pipEvolutionRoute` passing `evolutionOnly`; or
- a second screen-scoped load event on the same bloc, if the architecture rule
  is read as "one bloc + one `initial/loading/loaded/failure` vocabulary" rather
  than "one event class".

Trade-off the screen measured, for the record: K07's failure card deliberately
shows the **last-known child's** Pip, which today comes from the nest stream.
A nest-less evolution load would replace that with the neutral
`PipAvatar(style: mochi, skin: sunny, stage 1)` on the error path — a small
regression in exchange for three fewer Drift watches per entry. If the ruling is
"both are fine", the screen is happy to take the neutral look or to keep a
`lastKnownProfile` on the bloc; if the ruling is "no", the finding stays
accepted-as-is.

Files: `app/lib/features/pip/presentation/bloc/pip_event.dart`,
`app/lib/features/pip/pip_routes.dart` (both in-feature) — the shared part is
only the ARCHITECTURE ruling itself.
Blocks: **no** (deferred to a later K07 iteration or to the feature owner).
