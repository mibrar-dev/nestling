# Shared request — P15 two design-system items P15 cannot fix inside its feature

Both items block a *pixel- and copy-exact* P15 and live in
`app/lib/core/design_system/**`, which RULES §1 forbids this screen from
editing. They are also ORCHESTRATOR_NOTES.md item 2 (mandatory).

## 1. `NestListRow` starves the main column (P15-BUG-5)

Need: `NestListRow` (`app/lib/core/design_system/components/nest_list_row.dart`,
the row's `Row`) lays out `[tile 40, gap 12, Expanded(main), gap 12, Flexible(tail)]`.
Flutter hands each flex child an EQUAL share of the free space, so the
trailing reserves half the row even when its text is 20 px wide, and
`.list-main` gets the rest of only half.

Measured on `/child-profile` at 390, text scale 1.0
(`child_profile_theme_size_test.dart`, bundled fonts loaded):

| row | main column gets | subtitle needs | result |
|---|---|---|---|
| Kid PIN | 129.0 px | 171.2 px (`On · Maya knows their code`) | **ellipsised** |
| Quests | 129.0 px | 162.1 px (`6 active · 4 daily, 2 weekly`) | **ellipsised** |
| Pocket money | 129.0 px | 169.2 px (`£3.00 a week · Owed £4.20`) | **ellipsised** |
| PIN trailing `Change ›` | 129.0 px reserved | 70.7 px intrinsic | 58.3 px wasted |

Every subtitle is also ellipsised at 320 (94.0 px available; 68–77 px cut) and
at 430 (149.0 px; 13–22 px cut), at both 1.0 and 1.3 — and at 320 the row
TITLE `Pocket money` is cut too.

The design's CSS gives the opposite (`design/html-source/components.css:116-119`):
`.list-main { flex: 1; min-width: 0 }` and `.list-trail { flex-shrink: 0 }` —
the trail takes only its intrinsic width and the main column takes the
remainder (≈187 px here, which fits every subtitle). ORCHESTRATOR_NOTES.md item 1
asks for exactly this ("the trailing `Change ›` / `›` must take only its
intrinsic width, and the subtitle column takes the rest (Expanded)").

Suggested shape: take the trailing out of the flex distribution, e.g.
`if (tail != null) Align(alignment: Alignment.centerRight, child: tail)`
(keep `Flexible` only if it is paired with `flex: 0`, or wrap it in an
`IntrinsicWidth`). One line, no public API change, and P05/P08/P11/P12/P14/P16
rows with a trailing get the design's proportions for free.

Blocks: **yes** for copy fidelity — the three subtitles are truncated on every
width (320/390/430) at text scale 1.0, so the row cannot pass a UI check.

## 2. Missing assets for two list-row icons (ORCHESTRATOR_NOTES item 2)

Need:

a. **Circled check** for the Quests row. The design draws
   `<circle cx="12" cy="12" r="9"/>` + `<path d="m8.5 12.5 2.5 2.5 4.5-5.5"/>`
   (`design/html-source/screens/P15-child-profile.html`), stroke 2, round caps
   and joins. `NestIcons` has `ic_circle.svg` (r 7, no check) and `ic_check.svg`
   (bare check, no circle) but no combined asset, and P15 currently passes
   `leadingAsset: NestIcons.check`, so the row shows a plain tick.
   Please add e.g. `assets/icons/ic_check_circle.svg`:

   ```svg
   <svg xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="m8.5 12.5 2.5 2.5 4.5-5.5"/></svg>
   ```

   and `NestIcons.checkCircle`.

b. **Coin illustration** for the Pocket money row. The design uses
   `<img src="../assets/coin.svg" width="24" height="24">` — the coloured
   `assets/illustrations/coin.svg` — while P15 passes `leadingAsset:
   NestIcons.poundCoin`, which tints `ic_pound_coin.svg` (a line £ in a circle)
   and therefore loses the gold coin. `NestListRow.leadingAsset` only accepts a
   tintable line icon (`NestIcon`). Suggest either a `leadingWidget` escape
   hatch on `NestListRow`/`NestIconTile`, or a `NestIcons`-style constant for
   the illustration so a screen can drop `SvgPicture.asset(coin.svg, size: 24)`
   into the same 40 px tile.

   (For reference, the Kid PIN row's `ic_lock.svg` already matches the design's
   `<rect x="4" y="10" width="16" height="10" rx="3"/>` + shackle path.)

Blocks: **no** for the logic/tests, **yes** for the icon comparison at stage 5.