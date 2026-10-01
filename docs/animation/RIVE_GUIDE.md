# RIVE_GUIDE.md — Rive vs Lottie for Nestling, and the `pip.riv` production plan

> Research date: 30 Sep 2026. CLI tested: **rive 1.2.0** (darwin-arm64), installed at
> `tools/rive/bin/rive`. Flutter runtime tested: **rive 0.14.11 / rive_native 0.1.11**,
> **lottie 3.6.1**, **flutter_svg 2.3.0**.
>
> **Everything marked "VERIFIED" in this document was executed in this repo, not
> read from docs.** The RML source is `tools/rive/pip/scene.rml`; the built
> artefact is `app/assets/animations/rive/pip.riv`.

---

# A) VERDICT — Rive vs Lottie for Nestling

## Scores

| Criterion (weight) | Rive ^0.14 | Lottie ^3.6 | Notes |
| --- | --- | --- | --- |
| **AI authorability without a human in the editor (×5)** | **8** | 9 | Lottie is trivially generated JSON. Rive now has an official CLI + RML text format — VERIFIED working — but has three undocumented traps (see §7). Lottie cannot express Pip at all, which is why its 9 does not win the category. |
| **Interactivity (×4)** | **10** | 3 | Rive: state machines, view models, data binding, triggers, listeners, pointer gestures. Lottie: one-shot / loop / `frame` control only. |
| **File size (×2)** | **9** | 5 | VERIFIED: rigged Pip, 4 states, blink, view model, state machine = **2,115 bytes**. The equivalent hand-built Lottie JSON is typically 20–80 KB. |
| **Flutter runtime quality / performance (×2)** | **9** | 7 | Rive 0.14 is the **native C++ runtime** (`rive_native`), not Dart. Lottie rasterises vectors through Impeller in Dart. |
| **Total (weighted)** | **≈ 8.6** | **≈ 6.2** | |

## Recommendation: **"Rive now"** — for Pip. Lottie for the fire-and-forget one-shots.

The three options on the table were `"Lottie now"`, `"Rive now"`, and
`"Lottie now + Rive later for Pip once a designer is available"`.

**The third option is now obsolete, and that is the headline finding.** Its
premise was that `.riv` is a binary only the Rive Editor can produce, so an
agent-authored build had to wait for a human. As of 2026 that is false: Rive
ships an **official CLI and a text format, RML (Rive Markup Language)**, and
`rive <project> --once` writes a valid `.riv` **offline, signed out, with no
account**. VERIFIED end-to-end in this repo — see §2 and §3.

So the split is by *kind of animation*, not by *timeline*:

- **Pip (idle, blink, happy, eat, evolve, and the 4 growth stages) → Rive now.**
  It is one stateful character with continuous idle and mood-driven one-shots.
  That is exactly what a state machine is for, and the whole thing is one
  2 KB file that already exists at `app/assets/animations/rive/pip.riv`.
- **Coin burst, confetti, check tick, badge unlock, sparkles, heart pop → Lottie.**
  Pure fire-and-forget, no state, no data binding. A JSON generator is the
  right tool and costs nothing. The Lottie sub-agent is already producing these.
- **Progress bars, shakes, colour and size micro-interactions → plain Flutter.**
  See §9.

If the product owner wants exactly one of the three literal strings:
**"Rive now"**, scoped to Pip, with Lottie retained for one-shots.

## Why not "Lottie now"

Lottie can express exactly one of Pip's five behaviours (`happy`, as a
one-shot). `idle` needs a loop with a blink *inside* it at an irregular
cadence — a 3 s loop with a 2-frame blink at frame 132 is awkward as JSON but
trivial as a Rive timeline. `mood` needs to be readable and writable at
runtime; a Lottie file has no addressable properties. Stage 1→4 needs
cross-fades between artboards; Rive does this with one number. Fighting Lottie
into a mascot is how you end up with five `LottieBuilder` widgets and a
`Ticker` managing frame indices by hand.

## Why not "Rive everywhere"

Rive's state machine and binary format are pure overhead for a confetti loop.
Each `.riv` costs a native plugin surface, a state machine instance, and a
texture; each Lottie is a lazily-parsed JSON. For one-shots the two are
roughly equal in quality and Rive is worse in tooling ergonomics (binary,
review-hostile, no `git diff`). Keep Rive for the one thing that needs it.

## The catch, stated plainly

Rive authoring is **verifiable but not forgiving**. The CLI gives you three
checks (`--verify`, `inspect`, `--screenshot`) and I needed all three, because:

- `--verify` passed on a file where **all four state-machine conditions pointed
  at the wrong id**. `rive inspect` caught it as `unresolved-bind-path`.
- The compiler validates **names** rigorously (a misspelled element is a hard
  error with a suggestion) but validates almost nothing about **wiring**.
- Two of my three authoring mistakes (scale units, absolute `x`/`y`) compiled
  clean and looked *plausible* in a still frame.

That is a manageable cost, and it is a known, bounded one — see §7 for the
exact list. It is not the "needs a human in the editor" wall the brief assumed.

---

# B) ANIMATION SHORTLIST — top 10 by kid impact ÷ effort

Screens: `K*` = kid-facing, `P*` = parent-facing. Assets live in
`app/assets/illustrations/`.

| # | Animation | Asset | Screens | Trigger | Duration | Loop/one-shot | Tech | Why |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **Pip idle (breathe + blink)** | `pip.riv` (built) | K03, K03b, K05, K06, K07, K09, K08 | On screen enter; loops forever | 3.0 s (180 f) | loop | **Rive** | The single highest-impact frame in the app. A static mascot reads as a sticker; a breathing one reads as alive. 2 KB, one file, already built. |
| 2 | **Pip happy jump** | `pip.riv` (built) | K05, K03b, P11, K04 | Quest marked done / `mood=1` | 1.2 s (72 f) | one-shot → idle | **Rive** | The payoff moment. Squash-stretch + wing flap already authored and verified. Squash-and-stretch is fiddly as Lottie JSON and trivial as a keyed group. |
| 3 | **Coin drop into jar → fill rises** | `pip.riv` (jar artboard) or `jar_fill.json` | K09, P12, P13, K03b | Coins credited; fill level = data | 1.6 s + settles | one-shot → holds | **Rive** | The jar is a *quantitative* readout, not a decoration. Data-binding the fill to `coins/target` means one artboard serves every child and every goal, instead of a baked JSON per amount. |
| 4 | **Coin burst** | `coins_burst.svg` → `coin_burst.json` | K05, P11, P12, K03b | On +N coins, alongside #2 | 1.0 s | one-shot | **Lottie** | Pure celebration. No state, no data. Cheapest possible authoring, and a JSON generator nails it. |
| 5 | **Check tick** | → `check_tick.json` | K03b, K05, K08, P08, P11, P13 | Quest row flips to done | 0.6 s | one-shot | **Lottie** | Highest frequency of any animation in the app — it fires once per quest row. A 0.6 s Lottie is a few hundred lines of generator code and no runtime state. |
| 6 | **Pip evolve** | `pip.riv` (built) | K07 | Coins cross a stage threshold | 1.5 s (90 f) | one-shot → idle | **Rive** | The emotional peak of the whole product. Already authored: squash, pop, highlight flare. |
| 7 | **Confetti** | `confetti.svg` → `confetti.json` | K07, P13 (payout), K05 | Evolve / money paid out | 2.5 s | one-shot | **Lottie** | Highest raw delight-per-line-of-code of anything here. Do not put this in a binary format. |
| 8 | **Progress bar fill** | none (painted) | K06, K05, K09, K11, P10, P14 | Value changes | 0.6 s, ease-out | implicit | **Flutter** | It is a number. `TweenAnimationBuilder`/`AnimatedFractionallySizedBox` is one line, respects reduced motion for free, and is crisp at any size. Shipping an animation file here would be actively worse. |
| 9 | **Pip eat** | `pip.riv` (built) | K06 | `mood=2` after a Feed tap | 1.8 s (108 f) | one-shot ×3 chews → idle | **Rive** | Reinforces the "I fed Pip" loop. Three beak chews, already keyed. |
| 10 | **Badge unlock** | `badge_*.svg` → `badge_unlock.json` | K11, K05 | Badge flips locked → earned | 0.9 s | one-shot | **Lottie** | Medal swing + shine. Same SVG for all 9 badges, so one JSON with a colour swap beats nine files. |

### Judged and deliberately cut

| Candidate | Verdict | Reason |
| --- | --- | --- |
| **Egg hatch / crack** | **Cut** | Stage-1 Pip is a static egg that resolves in one tap. A crack animation is a nice-to-have that only one child ever sees, once. Revisit if hatchling→fledgling gets the same treatment. |
| **Nest settle** | **Cut** | One decorative still under Pip. The idle breathe in #1 already sells the nest. |
| **Lock / parental-gate shake** | **Flutter, not an asset** | A shake is `Transform.translate` on a curve. No file, no decode, and it can respect reduced motion properly. |
| **Sparkles** | **Fold into #4 and #7** | Standalone sparkles add nothing next to a coin burst or confetti. Cut as a separate asset. |
| **Heart pop** | **Defer to v2** | P13/P14 rewards only. Cute, but it competes with #7 for the same celebration moment. |
| **Meadow sway** | **Flutter, or cut** | A full-screen ambient loop is the most expensive thing per unit of delight in the list. If kept, drive it from a cheap `AnimatedBuilder` sine on a static SVG rather than a looping animation file. |

### Sequencing

1. **#1, #2, #6, #9 (Rive / Pip)** — already built and in the repo. Wire them up.
2. **#5, #4, #7 (Lottie)** — the Lottie sub-agent's queue. Smallest effort, highest frequency.
3. **#8 (Flutter)** — trivial, do it while wiring #1.
4. **#3 (Rive jar)**, **#10 (Lottie badge)** — second pass.

---

# 1. How Rive actually works

## 1.1 The object model

| Concept | What it is |
| --- | --- |
| **Editor** | Web app + macOS/Windows desktop app. Where humans draw. The desktop app is also the MCP host. |
| **Artboard** | A named scene with its own canvas size, timeline and state machines. Roughly a "screen" or a "component instance". A `.riv` holds many. |
| **Shape** | A leaf: one path (`Ellipse`/`Rectangle`/`Triangle`/`Path`) + its paints (`Fill`, `Stroke`, gradients). Carries a transform. |
| **Node** | A transform-only group. Draws nothing, exists so children inherit its transform. **This is the rig.** |
| **LinearAnimation** | A fixed timeline of keyframes. `loopValue` = `loop` \| `oneShot` \| `pingPong`. |
| **StateMachine** | Decides *which* timeline plays and *when* it changes. Layers → states → transitions → conditions. This is what makes a file interactive rather than a video. |
| **Nested artboard** | An artboard placed inside another. Reuse, but each placement costs size. |
| **View model / data binding** | A typed data model on the artboard. The host sets values; binds push them into colours, sizes and text. |
| **Event / Listener** | Rive → host or host → Rive. A listener writes a view model property; a transition reads it. |
| **`.riv`** | The binary runtime format. Fingerprint `RIVE` (0x52 0x49 0x56 0x45), little-endian, current major version 7. |

**Z-order: the FIRST child of a container draws ON TOP.** VERIFIED — Pip's eyes
and beak were invisible until the shape list was reversed. Every list in
`tools/rive/pip/scene.rml` therefore runs front-to-back.

## 1.2 State machine inputs are DEPRECATED — use the view model

This is the single most important API change and it is easy to miss, because
the old `StateMachineBool` / `StateMachineNumber` / `StateMachineTrigger` still
load and still work.

Rive's own docs say plainly: *"Drive it with view model data, not state machine
inputs."* A property written by `ListenerViewModelChange` and read by
`TransitionViewModelCondition` does everything an input did, **and** the same
property is bindable into colours, sizes and text — which an input never was.

The RML is verbose about this. A transition condition needs a bindable
adapter and two comparators:

```xml
<StateTransition stateToId="0:911" duration="120">
    <TransitionViewModelCondition opValue="equal">
        <TransitionPropertyViewModelComparator>
            <BindablePropertyNumber>
                <DataBindContext sourcePathIds="0:800-0:810" propertyKey="636"/>
            </BindablePropertyNumber>
        </TransitionPropertyViewModelComparator>
        <TransitionValueNumberComparator value="1"/>
    </TransitionViewModelCondition>
</StateTransition>
```

`sourcePathIds` is `"<viewModelId>-<viewModelPropertyId>"` — **not** the
instance id. Getting that wrong compiles clean and `rive inspect` reports
`unresolved-bind-path`. (VERIFIED: this exact mistake cost me one build cycle.)

`BindableProperty*` `propertyKey` values are **not unique** — `Integer` and
`Trigger` both use `686`; `Asset`, `Artboard` and `ViewModel` all use `823`.
The element name is the only discriminator, so a key copied from the wrong row
is not a build error, it is a bind pointed at a property the element does not
have.

## 1.3 The Flutter `rive` ^0.14 API

^0.14 replaced the old Dart runtime with the **native C++ runtime**
(`rive_native`). The legacy `RiveAnimation.asset(...)` / `RiveAnimation.asset`
builder is gone. Current shape:

```dart
// Boot once. Optional — the first file load does it — but do it in main().
await RiveNative.init();

// Loading: a FileLoader caches the decoded File, so N widgets decode once.
final fileLoader = FileLoader.fromAsset('assets/pip.riv', riveFactory: Factory.rive);

// Rendering + state + data, with loading/error handled for you.
RiveWidgetBuilder(
  fileLoader: fileLoader,
  artboardSelector: ArtboardSelector.byName('Pip'),
  stateMachineSelector: StateMachineSelector.byName('Pip'),
  builder: (context, state) => switch (state) {
    RiveLoading() => placeholder,
    RiveFailed()  => errorView,
    RiveLoaded()  => RiveWidget(controller: state.controller, fit: Fit.contain),
  },
);

// Data binding — once per controller.
final vmi = controller.dataBind(DataBind.auto());
vmi?.number('mood')?.value = 1.0;    // ViewModelInstanceNumber is a double
vmi?.trigger('evolve')?.trigger();   // fire-once
```

Also available and relevant:

- `Factory.rive` (native renderer) vs `Factory.flutter` (Skia/Impeller). Use
  `Factory.rive` for vector feathering; `Factory.flutter` when you need to
  interleave Rive and Flutter drawing.
- `RivePanel` + `SharedRenderTexture` + `RiveSurface` — many Rive widgets into
  one texture. Matters on web (browsers cap WebGL contexts at ~16) and when you
  show a lot of Rive at once. `Factory.rive` only.
- `renderResolution` — `RenderResolution.display()` (default) vs `.layout()`
  vs `.fixed(w, h)`.
- Manual mode: `await File.asset(...)` → `RiveWidgetController(file, artboardSelector: …)`.
  You then own disposal: `viewModel → controller → file`.
- Exception types: `RiveFileLoaderException`, `RiveArtboardException`,
  `RiveStateMachineException`, `RiveDataBindException`.

Source: <https://rive.app/docs/runtimes/flutter/flutter>,
<https://rive.app/docs/runtimes/flutter/migration-guide>,
<https://pub.dev/packages/rive>.

**Renderer gotcha:** Impeller is now Flutter's default. If Rive output looks
wrong on device but right in the editor, try `flutter run --no-enable-impeller`
first — that isolates an Impeller bug from an authoring bug.

## 1.4 File size and performance

- VERIFIED: Pip = **2,115 bytes** for 14 shapes, 3 nested groups, 4 animations,
  a state machine and a 4-property view model. Rive's binary is extremely
  efficient for this shape of content.
- A `.riv` embeds **every** asset variant you bind between. Data-bound images
  (`ViewModelPropertyAssetImage`) are all in the file, so swapping between
  large images is a size trap.
- Rive caches one decoded `File` per `FileLoader`; reuse the loader across
  widgets.
- Per-widget texture cost is the main scaling limit. Past ~10 simultaneous
  Rive widgets, reach for `RivePanel`.

## 1.5 Editor pricing (checked Sep 2026)

Source: <https://rive.app/docs/account-admin/pricing>

| Plan | Monthly | Annual | Gives you |
| --- | --- | --- | --- |
| **Free** | $0 | $0 | 3 collaborative files. State machines, data binding, scripting. **No runtime exports.** |
| **Cadet** | $17/seat/mo | $108/seat/yr | Runtime exports. Unlimited files. Max 3 seats. |
| **Voyager** | $39/seat/mo | $304/seat/yr | Libraries, CDN hosting, $20/seat monthly agent credits. Max 25 seats. |
| **Enterprise** | — | $1,440/seat/yr | SSO, SOC2, custom runtime support. |

**This matters to us in exactly one way:** the free plan has no exports, and
`--publish` "may add a watermark to the graphic". A clean `.riv` needs the
project bound to a file in an account on **Cadet or higher**.

**The good news:** `rive <project> --once` — an *unsigned* `.riv` written
straight to disk — **needs no account at all**, and is what we use. VERIFIED:
built and shipped `pip.riv` with no session, no watermark, no network.

---

# 2. CLI verdict

## An official Rive CLI exists and it can author, not just convert.

It is **not an npm package**. It is distributed by Rive as a signed tarball
from `https://releases.rive.app/cli`, installed by a shell script or a Homebrew
cask. `npm install rive-cli`, `brew install rive`, and a GitHub
`rive-app/rive-cli` package do not exist. Anyone telling you otherwise is
describing a different project.

**Installed locally, no global install, no sudo** — the installer honours
`RIVE_HOME` and `RIVE_INSTALL_DIR`, so it can be vendored into the repo:

```bash
RIVE_HOME="$PWD/tools/rive/.rive" \
RIVE_INSTALL_DIR="$PWD/tools/rive/bin" \
  sh -c 'curl -fsSL https://releases.rive.app/cli/install.sh | sh'
export RIVE_HOME="$PWD/tools/rive/.rive"
export PATH="$PWD/tools/rive/bin:$PATH"
```

Result: `tools/rive/bin/rive`, version 1.2.0. The script SHA-256s the tarball
against a manifest, rejects symlinks and unsafe archive paths, and clears the
macOS quarantine attribute.

### What it can do

| Capability | Command | Offline? |
| --- | --- | --- |
| Scaffold a project (`rive.yaml`, `scene.rml`, `AGENTS.md`, `CLAUDE.md`) | `rive create` | yes |
| **Author and animate** — RML is real authoring, not a converter | edit `.rml` | yes |
| **Build a real `.riv`** | `rive <dir> --once` | **yes** |
| Validate (RML + Luau + WGSL) | `rive <dir> --verify` | yes |
| Inspect the resolved scene, machine-readable | `rive inspect --json` | yes |
| **Headless render to PNG** | `rive <dir> --screenshot=out.png` | yes |
| Drive the scene: set data, simulate pointer/keys, advance time | `--data`, `--pointer`, `--key`, `--advance` | yes |
| **Read state back as JSON** — assert on it in CI | `--data-dump=-` | yes |
| Benchmark advance/render | `rive <dir> --bench=300` | yes |
| Run Luau test scripts | `rive <dir> --test` | yes |
| Look up any type's properties / property keys | `rive schema Rectangle` | yes |
| Searchable authoring docs shipped with the binary | `rive docs <topic>` | yes |
| Copy a runnable sample project | `rive samples` | yes |
| Live preview window, rebuild on save | `rive <dir>` | needs a display |
| Publish a live-link to players | `--serve` / `--headless-serve` | needs a display |
| Sign the file / publish to the web | `--publish` | **needs `rive login`** |
| Export an editor-openable `.rev` | `--rev=path.rev` | **needs `rive login`** |
| Push to / pull from a file in your Rive account | `rive push` / `rive pull` | **needs `rive login`** |
| JSON build reports for CI | `--format=json` | yes |

VERIFIED working with no account: `create`, `verify`, `inspect`, `once`,
`screenshot` with `--data`/`--advance`, `data-dump`, `schema`, `docs`, `samples`,
`doctor`.

### What it cannot do

- **No account-free signed export.** `--publish` needs `rive login` and *may
  watermark*. Our unsigned `--once` output is the clean path and is what ships.
- **No scripting-as-UI.** It is a build tool plus a preview window. Rich
  authoring still wants the Editor (or its MCP server, §4).
- **No batch vector import.** There is no "drop in 22 SVGs" command. RML shapes
  are primitives (`Ellipse`, `Rectangle`, `Triangle`, `Path`) that you author.
- **Watch mode needs a GPU context**; on Linux it needs libEGL/libGLESv2/libX11.
  `--once`/`--test`/`--screenshot` do not.
- **It validates names, not wiring.** This is the real limitation — see §7.

### Exit codes (useful in CI)

`0` ok · `1` build error · `2` bad flag · `3` not logged in · `6` test
failures · `7` service unreachable.

---

# 3. Can an AI agent generate a `.riv` programmatically?

**Yes. In 2026 there is a first-class, official, offline path.** Realistic
answer, in order of preference:

### 3.1 RML + the Rive CLI — the supported path (VERIFIED here)

RML is an XML text format. Every element is a Rive type, every attribute is one
of its properties, and the names are *the same ones the Editor uses* — so
there is no second object model to learn. The CLI compiles a folder of `.rml`
into one `.riv`.

What I actually did in this repo, unaided by the Editor:

1. `rive create` a project.
2. Read `rive docs format`, `rive docs data`, `rive docs state-machines`,
   `rive docs transforms`, `rive docs gotchas`, `rive docs skeleton`.
3. Look up property keys with `rive schema` (`rive schema Ellipse`,
   `rive schema --search ViewModelProperty`).
4. Hand-write `tools/rive/pip/scene.rml`: 14 shapes, 3 nested `Node` groups
   (the rig), 4 `LinearAnimation`s, a `StateMachine` with 4 `AnimationState`s,
   view-model-gated transitions, and a 4-property `ViewModel`.
5. `rive --verify` → clean. `rive inspect` → 1 cosmetic warning.
6. `rive --once` → **`pip.riv`, 2,115 bytes**, magic `RIVE`, format major 7.
7. `rive --screenshot` at chosen frames, plus `--data=mood=1 --advance=24` to
   drive the state machine, and `--data-dump` to assert the view model.
8. Looked at the PNGs and iterated.

Previews are in `design/animations/rive/`: `pip_rest`, `pip_idle_breath`,
`pip_blink`, `pip_happy`, `pip_eat`, `pip_evolve`.

### 3.2 Raw binary writing — possible, not advisable

The format *is* documented (<https://rive.app/docs/runtimes/advanced-topic/format>):
little-endian, LEB128 varuints, a `RIVE` fingerprint, a ToC bit-array so old
runtimes can skip unknown properties, and type-key/property-key pairs defined in
`rive-cpp/dev/defs`. You could write a serializer. Do not: there is no
round-trip library, no partial-write support, and the ToC/future-compatibility
machinery is precisely what you would be reimplementing. Use the CLI.

### 3.3 The Editor MCP server — real, but not headless

Rive ships an official MCP server (<https://rive.app/docs/editor/ai/mcp>)
running at `http://127.0.0.1:9791/mcp` from the **desktop Editor app**, in
**Early Access**, Mac/Windows only. It can create artboards, shapes, layouts,
animations, state machines, view models, bindings, and run Luau/WGSL.

It is genuinely capable, and worth having when a designer is in the loop. But
it requires the Editor process to be open and logged in, so it is **not** a
CI or batch path, and it cannot replace the CLI. Community reports on the
feature are mixed, and it is Early Access. Use the CLI for automation, MCP for
interactive sessions.

**Recommendation: RML + CLI for everything automated. RML is the source of
truth and it diffs in git.**

---

# 4. Production plan for Nestling

## 4.1 File layout

```
tools/rive/pip/                  # Rive CLI project — the SOURCE OF TRUTH
  rive.yaml                      # name + main artboard
  scene.rml                      # all art, animation, state machine, view model
  build/pip.riv                  # build output (gitignored)
  AGENTS.md                      # shipped by the CLI; instructions for agents
app/assets/animations/rive/
  pip.riv                        # the committed artefact the app loads
design/animations/rive/*.png     # human review frames
```

`app/assets/animations/rive/pip.riv` is a **build product**. Never hand-edit it.
Rebuild with:

```bash
rive tools/rive/pip --verify                 # compiles?
rive tools/rive/pip --once                   # write build/pip.riv
rive inspect tools/rive/pip --summary        # problems + object counts
cp tools/rive/pip/build/pip.riv app/assets/animations/rive/pip.riv
```

## 4.2 Artboards per stage

`rive.yaml` sets `main: Pip`, so the first artboard is the default. Ship the
four stage artboards in one file:

| Artboard | Contents | Notes |
| --- | --- | --- |
| `Pip` | stage-3 Fledgling rig, 4 animations, state machine, view model | **built and shipped today** |
| `PipEgg` | stage-1 egg | no state machine needed; a single looping `wobble` |
| `PipHatchling` | stage-2 | same `Pip` state machine, different art |
| `PipSongbird` | stage-4 | same, plus a `sing` one-shot |

**Recommendation: do not build stages 1/2/4 as separate state machines.** Keep
one state machine, `Pip`, and let the artboard swap the rig. That is what the
`stage` view model property is for, and it keeps the naming contract identical
across all four so the Flutter side never branches on stage.

## 4.3 The state machine

State machine: **`Pip`** (one layer, `Body`).

| State | Animation | Loop | Exit |
| --- | --- | --- | --- |
| `0:910` idle | `idle` 180 f (3.0 s) | loop | on `mood` / `evolve` condition |
| `0:911` happy | `happy` 72 f (1.2 s) | oneShot | exit at 100% → idle, 220 ms blend |
| `0:912` eating | `eat` 108 f (1.8 s) | oneShot | exit at 100% → idle, 220 ms blend |
| `0:913` evolve | `evolve` 90 f (1.5 s) | oneShot | exit at 100% → idle, 300 ms blend |

The rig — what actually gets keyed:

```
Node "pip"            <- breathing, jump, squash. Key THIS, not the shapes.
  Shape  beak         <- chews
  Node  eye_l -> glint_l, pupil_l, white_l     <- blink keys pupil_l scaleY
  Node  eye_r -> glint_r, pupil_r, white_r
  Shape  wing_l, wing_r <- flap (rotation)
  Shape  shine        <- evolve flare (opacity)
  Shape  body         <- never keyed directly
Node "feet"           <- outside the group so a jump leaves the feet behind
Shape  shadow
```

## 4.4 Naming contract (Flutter ↔ `.riv`)

This is the contract. Changing any name on one side without the other is the
only way to break this, so it is pinned in
`app/lib/core/design_system/motion/pip_rive.dart` as constants.

| Concept | Name in `pip.riv` | Type | Dart constant |
| --- | --- | --- | --- |
| File | `assets/animations/rive/pip.riv` | — | `kPipRiveAsset` |
| Artboard | `Pip` | — | `kPipArtboard` |
| State machine | `Pip` | — | `kPipStateMachine` |
| View model | `Pip` (default instance) | — | auto-bound via `DataBind.auto()` |
| Mood | `mood` | number, `0` idle `1` happy `2` eating `3` sleepy | `PipMood` |
| Stage | `stage` | number, `1`–`4` | `PipStage` |
| Evolve | `evolve` | trigger | `PipRiveController.playEvolve()` |
| Tap | `tap` | trigger | `PipRiveController.poke()` |

Fallback SVGs: `assets/illustrations/pip_stage_<N>.svg`.

**Versioning rule:** the file format's *major* version must match the runtime's.
A `.riv` from a newer major will hard-error on load. Bump `rive` in
`pubspec.yaml` and re-export together, never one at a time.

## 4.5 Designer hand-off checklist

Hand this to whoever opens the `.riv` in the Editor. A designer should be able
to take the file over and improve it without reading any Dart.

**Before opening**
- [ ] Install the Rive **desktop** app (macOS/Windows). The web editor works, but
      the desktop app also hosts the MCP server.
- [ ] `rive create myproject --from-remote-file` **or** ask engineering to export
      a `.rev` (`rive tools/rive/pip --rev=pip.rev`, needs a session on Cadet+).
      Opening the raw `.riv` in the Editor is not supported.
- [ ] Read `tools/rive/pip/AGENTS.md` — the CLI writes it, it is aimed at agents
      but explains the project layout.

**Structure**
- [ ] Artboards named exactly `Pip`, `PipEgg`, `PipHatchling`, `PipSongbird`.
- [ ] State machine named exactly `Pip`, present on every artboard, and set as
      the artboard's **default state machine**. Without it, no data binds and no
      pointer input reach the artboard.
- [ ] View model named `Pip` with a default instance, and the artboard's
      `viewModelInstanceId` pointing at it (otherwise the artboard opens
      *unpopulated* in the editor even though it works at runtime).
- [ ] Property names exactly `mood`, `stage`, `evolve`, `tap`. Names are the
      public surface; **renaming one is a breaking change** in a way that
      renumbering an id is not.
- [ ] View models and custom enums PascalCase; properties camelCase. No leading
      digit, no Lua keywords (`type` is the trap).

**Animation**
- [ ] Timings unchanged: idle 180 f, happy 72 f, eat 108 f, evolve 90 f, all
      at 60 fps. Flutter and design must agree on these.
- [ ] One-shots return to idle at 100% exit time. The Flutter side sets `mood`
      and relies on the machine to come home.
- [ ] All keyframes `hold`/`linear`/`cubic` only. No expressions — the Flutter
      runtime does not support them (this applies to Lottie too).
- [ ] Reduced-motion path still works: `pip_rive.dart` swaps to the static SVG,
      so nothing may be communicated *only* by motion.

**Palette**
- [ ] ink `#1E1B3A`, coin `#F4B400`, leaf `#17804F`, lilac `#7C6CF2`,
      peach `#FF8A5B`, Pip yellow `#FFD93D`, Pip green `#1F9D63`.

**Before shipping**
- [ ] `rive tools/rive/pip --verify` → 0 errors
- [ ] `rive inspect tools/rive/pip --json | jq '.problems'` → empty
- [ ] `rive tools/rive/pip --screenshot=out.png` and **look at it**
- [ ] `rive tools/rive/pip --data=mood=1 --advance=24 --screenshot=happy.png` —
      a bind pointing at the wrong property passes `--verify` and `inspect`
- [ ] Confirm every artboard has a default state machine (`inspect` warns
      `no-default-state-machine`)
- [ ] Copy the rebuilt `.riv` to `app/assets/animations/rive/`
- [ ] `cd app && flutter analyze` → 0 issues
- [ ] Reduced-motion pass: enable the OS setting and re-check K03, K05, K06, K07

---

# 5. Flutter integration

Full, analysed, shipping file:
**`app/lib/core/design_system/motion/pip_rive.dart`**

`cd app && flutter analyze` → **No issues found!** (`flutter test` also passes.)

```dart
// The whole integration surface.
PipAvatar(stage: PipStage.fledgling, mood: PipMood.idle, size: 160)

// Imperative one-shots.
final pip = PipRive.of(context);
pip?.celebrate();      // mood = happy
pip?.playEvolve();     // fire the evolve trigger
pip?.rest();           // back to idle
```

### How the fallback works

`pip_rive.dart` resolves, once per app run, whether
`assets/animations/rive/pip.riv` is actually bundled **and** starts with the
`RIVE` magic bytes. If it is missing, corrupt, or the platform requests reduced
motion, the widget renders `assets/illustrations/pip_stage_<N>.svg` through
`flutter_svg` instead.

That means the `.riv` and the static SVGs can ship in either order, the app
never shows an empty hole, and reduced motion is a first-class path rather than
a retrofit.

```yaml
# app/pubspec.yaml
flutter:
  assets:
    - assets/animations/rive/
    - assets/animations/lottie/
    - assets/illustrations/
    - assets/icons/
    - assets/brand/
    - assets/images/
```

### Reduced motion

`MediaQuery.disableAnimationsOf(context)` → the widget renders the static SVG
and the state machine never starts. No animation in Nestling may carry
information that motion alone conveys.

---

# 6. Tech split

| Need | Tech | Why |
| --- | --- | --- |
| Continuous idle loop | **Rive** | Cheapest per-frame state to hold; a state machine is already ticking. |
| Mood/state-driven character | **Rive** | View models are the only one of the three with addressable runtime properties. |
| Data-bound continuous value (jar fill, bar) | **Rive** if it shares a file, else **Flutter** | Avoid a separate binary for a number — but the jar is already in `pip.riv`. |
| Fire-and-forget celebration | **Lottie** | JSON, git-diffable, no state, no native surface. |
| Progress bar, count-up, colour/size tween | **Flutter** | `TweenAnimationBuilder`, `AnimatedFractionallySizedBox`. One line, free reduced-motion, crisp at any DPR. |
| Shake, pulse, press-scale, ripple | **Flutter** | Transform-only. An asset file is the wrong tool. |
| Ambient background loop | **Flutter**, or cut | Highest runtime cost per unit of delight. |

---

# 7. Gotchas — every one of these was hit in this repo

`rive docs gotchas` exists and is good. These are the ones that actually bit,
in the order they cost time.

1. **`--verify` is not enough. Run `rive inspect`.** VERIFIED: a file with all
   four state-machine conditions pointing at the wrong id passed `--verify`
   with 0 errors and was caught only by `inspect`'s `unresolved-bind-path`.
   A clean exit code means no *name* was misspelled — not that the file works.

2. **Keyframe scale is a MULTIPLIER, not a percentage.** VERIFIED by measuring
   rendered pixels: `0.5` → 0.50×, `1.0` → 1.00×, `1.5` → 1.50×, `2.0` →
   2.00×. Writing `100` (the After Effects habit) means **100×** and explodes
   the artboard. The authored attribute default is `1.0`, matching the
   multiplier. The renderer appears to clamp around 3×, which makes a 100× key
   look merely "very wrong" rather than obviously broken.

3. **Keyed `x`/`y` are ABSOLUTE, not deltas.** VERIFIED: keying `y = -22` on a
   node authored at `y=132` teleports it to the top of the artboard. Restate
   the full position: `132 → 110 → 132`. Same trap as (2) in that it compiles
   clean.

4. **The first child draws on top.** VERIFIED: Pip's eyes, beak and highlight
   were fully hidden behind the body until the shape list was reversed. Write
   your RML front-to-back.

5. **A screenshot with no `--advance` renders the rest pose**, before the
   animation has been applied. Both bugs in (2) and (3) looked *fine* in that
   mode. **Always render with `--advance=N`** when checking an animation.

6. **`exitTimeIsPercetange` is misspelled in the format itself.** The correct
   spelling is rejected. Write the typo.

7. **Transition `duration` is milliseconds; everything else is frames.**
   `exitTime` is milliseconds unless `exitTimeIsPercetange="true"`, in which
   case it is 0–100 %.

8. **States carry no `name`** — they are identified only by id, and `name` on a
   state is a build error. Every state needs `x`/`y` or they all stack on one
   point in the Editor graph.

9. **Declare the `StateMachine` before any `LinearAnimation`.** The Editor's
   animation list follows source order.

10. **Transition conditions live on the state they leave**, as children of an
    `AnimationState` — not as siblings in the layer.

11. **Without `defaultStateMachineId` the artboard is half alive** in the
    previewer: data binds are never applied, pointer input is never routed,
    and *animations still play*, which is exactly what makes it look fine.
    `inspect` warns `no-default-state-machine`.

12. **A plain nested artboard inherits its parent's data context.** For a
    view-model-driven machine to work, the placement must set `isStateful="true"`.

13. **Enums are the one validated thing.** An unrecognised enum name is a hard
    error listing the accepted values. Prefer symbolic names over integers.

---

# 8. Sources

**Rive**
- Flutter runtime: <https://rive.app/docs/runtimes/flutter/flutter>
- Migration guide (0.14 / 0.15): <https://rive.app/docs/runtimes/flutter/migration-guide>
- pub.dev: <https://pub.dev/packages/rive> · GitHub: <https://github.com/rive-app/rive-flutter>
- **CLI overview:** <https://rive.app/docs/cli/overview>
- **CLI getting started:** <https://rive.app/docs/cli/getting-started>
- **CLI command reference:** <https://rive.app/docs/cli/reference/commands>
- **RML:** <https://rive.app/docs/runtimes/advanced-topic/rml>
- `.riv` binary format: <https://rive.app/docs/runtimes/advanced-topic/format>
- Pricing: <https://rive.app/docs/account-admin/pricing>
- Editor MCP: <https://rive.app/docs/editor/ai/mcp>
- Runtime repo: <https://github.com/rive-app/rive-runtime>
- CLI releases: <https://releases.rive.app/cli>

**Lottie**
- <https://pub.dev/packages/lottie>

**In this repo**
- Rive CLI project: `tools/rive/pip/`
- Built artefact: `app/assets/animations/rive/pip.riv`
- Flutter widget: `app/lib/core/design_system/motion/pip_rive.dart`
- Rendered previews: `design/animations/rive/`
