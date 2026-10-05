# Shared request — P08b Today empty

Need: move the `todayEmptyRoute` (`/today-empty`) into the Today
`StatefulShellBranch` in `app/lib/app/router.dart` so the design's tab bar
(Today active) renders on P08b and the owner bottom-edge rule holds (the
tab-bar surface currently cannot extend to the physical edge because the
route sits outside any shell branch).

Files: `app/lib/app/router.dart`

Blocks: yes — pixel-perfect UI check (tab bar + bottom edge) is
blocked until this lands. Body work proceeds regardless. The
orchestrator's `shared/p08b_shell` branch is already doing this;
file once on main.

---

# Ruling request — P08b · does the PIP rule apply to the empty-state egg?

**STATUS: still needed.** Not a code change — a decision, so it is not a
"shared request" in the §2 sense; filed here because this screen is the only
place the ambiguity exists and three stages have now re-derived it.

**The conflict.** The loop's PIP rule reads: "wherever a screen shows Pip,
render the child's OWN Pip with `PipAvatar` … using that child's
`pip_style` / `pip_skin` / `pip_accessory` / `pip_stage` **from the
database** (Maya = Mochi·sunny·stage 3, Leo = Bolt·sky·stage 2)". The rule's
second sentence carves out "onboarding/marketing screens with **no child yet**
(P01–P07)".

P08b is neither: with the mandated `SEED=new_family` it has two children in the
database (Maya stage 3, Leo stage 2), and the empty card renders a hard-coded
`PipAvatar(style: mochi, stage: 1, size: 140)` — an egg.

**Why the app looks like that, and why I think it is right:**

- The design is unambiguous and is the copy of record. Both PNGs show a
  speckled **egg**, and the HTML is `<img src="../assets/pip-stage-1.svg"
  alt="Pip the bird as a speckled egg">` (`P08b-today-empty.html:31`). The v1
  SVG is banned, so `PipAvatar(mochi, stage: 1)` is the v2 equivalent of what
  the design shows, at the design's 140 px slot.
- The card has no "own" child. It is the family's single shared nest Pip, and
  the sentence right below it says *"Add your first quest and Pip will start
  to hatch"* — a hatched bird would contradict the copy on the same card.
- The database values are an artefact of the seed, not of this state:
  `Seed.newFamily` reuses `_childrenDemo`, so Maya carries `pipStage: 3` and
  Leo `pipStage: 2` **while the family has zero quests and zero completions**.
  Rendering "Maya's Pip" here would show a half-grown bird in a nest whose only
  quest is still to be created, and would fail the UI check against the design.

**What I need.** One line from the orchestrator, ideally added to
`ORCHESTRATOR_NOTES.md` so no future stage re-litigates it:

> The PIP rule's "child's own Pip" clause governs **per-child** Pip slots (kid
> cards, K01/K03/K06 profiles). A screen-level Pip that belongs to no single
> child — the P08b "Your nest is quiet" egg, onboarding/marketing art — renders
> `PipAvatar` at the stage **the design shows**, not a child's DB stage.

Failing that ruling the alternative is unambiguous and would need a design
change, not a code change: either the PNG/HTML move to a hatched Pip, or the
`new_family` seed resets `pipStage` to 1 for both children. Both are outside
RULES §1 for this screen.
