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

## 3. `tools/screens/shot.sh` can save a pre-first-frame capture (added by `5_ui.md`, iteration 2)

Need: the harness waits for the app's **process** (1 s), then takes captures
1 s apart and keeps the first two with identical md5. Because the run uses
`--no-resident`, the tool has already exited by then and Flutter may not have
painted, so the two "identical" captures can both be the pre-frame state — which
on this simulator is the **previous launch's image**. Measured on 2026-10-04,
three identical commands, no code change in between: `THEME=light` → saved a
**dark** frame, `THEME=dark` → saved a **light** frame, `THEME=light` → correct.
The first `compare.py` run therefore reported a bogus **71.31 %** mean diff for
K07 light and would have failed a screen that actually passes. A wrong-theme
capture is silent: `shot.sh` reports "stable frame saved".

Two changes, both in shared tooling (RULES §1 bars a screen agent from editing
`tools/screens/**`):

- wait for the app's **first frame**, not just the process — e.g. `sleep 5`+
  after `READY`, or poll until a capture differs from the pre-launch frame;
- require stability across **≥ 3** captures ≥ 2 s apart rather than 2 captures
  1 s apart.

Until then the workaround (verified for this stage's accepted shots) is: same
flags, `sleep 8` after `READY`, 5 captures 3 s apart, keep the first repeated
md5, then **assert the frame's identity** (sample the background and the CTA
face) before saving the PNG. Iteration 1's note stands too: the output path must
be absolute, because `shot.sh` `cd`s into the app dir before copying.

Files: `tools/screens/shot.sh`.
Blocks: **no** (K07's iteration-2 UI check was completed with the workaround).

## 4. `#3D7FF0` is an off-token literal in the K07 design source (added by iteration 3, `2b`)

Need: `K07-evolution.html:41` draws one sparkle dot at `fill="#3D7FF0"` — the
`svg.sparks` layer's only colour with no token behind it. `--sky` is `#2563D6`
(light) / `#7FA9FF` (dark), so 24/28/26 per channel away. Both design PNGs paint
that dot `#3D7FF0` (sampled at CSS 288 × 115 by this stage), so the layer is
genuinely theme-invariant — and the "tokens only" rule means K07 paints the
light `--sky` there in both themes. Either the HTML should use `var(--sky)` /
the token, or the design system should gain a `sparkBlue` token at `#3D7FF0`.
Until one of those lands the deviation is one 6 px dot, and it is pinned by
`pip_evolution_sparks_test.dart`'s "the design’s non-token #3D7FF0 dot is NOT
painted literally" so it cannot drift silently.

Files: `design/html-source/screens/K07-evolution.html` (or
`app/lib/core/design_system/tokens/colors.dart`).
Blocks: **no**.

## 5. Copy sign-off for `evolutionSub(0)` (`4_review.md` finding 2)

Need: `evolutionSub(0)` renders "Because you helped 0 times" above
"Pip grew into a Hatchling!" — a self-contradicting sentence on a celebration
screen. There is no zero case in any design source, so the wording needs the
ruling before it lands. Suggested zero line in
`pip_evolution_copy.dart`: "Pip is ready for its first adventure" (the ASCII
convention and the `switch` shape are already right; only the branch is
missing). Today's behaviour is pinned by `k07_bugs_test.dart`'s
"0 and 999999999 coins…" control, so this stage left it and will move the
assertion with the wording.

Files: `app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart`
(in-feature), `app/test/features/pip/k07_bugs_test.dart`.
Blocks: **no**.
