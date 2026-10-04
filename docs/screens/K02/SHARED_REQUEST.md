# Shared request — K02 typography tokens, keypad pitch re-check, avatar-initial helper

Filed by the K02 screen loop, iteration 1. RULES §2 shape. Created because
`4_review.md` filed the missing file as a **major** process defect (the plan,
`2_build.md`, `2b_build_ui.md` and two live `TODO(K02)` sites all cite it and
it did not exist), and because stage 3 found one more genuinely shared defect
that must not be patched locally (K02-BUG-1).

Current status: **#1 and #3 open**, **#2 landed on `main`, K02 follow-up
pending**. Nothing here blocks K02 from landing — the build carries
metric-matched local stand-ins behind TODOs.

---

## #1 — `NestType.kidSay` and `NestType.kidMark` (OPEN)

**Need.** K02's CSS (`.k2-hi .say`, `.k2-hi .mark` in
`design/html-source/screens/K02-pin.html`) uses two kid type styles the shared
`NestType` does not yet carry:

| token | font | weight | size | line-height | tracking |
|---|---|---|---|---|---|
| `NestType.kidSay` | Nunito | 800 | 20 | 26/20 | 0 |
| `NestType.kidMark` | Nunito | 900 | 16 | 22/16 | **stays at the call site (1.28)** |

Per the LETTER SPACING orchestrator rule (main `fd92d95`), `NestType` styles
default to `letterSpacing: 0`; `.mark`'s `0.08em × 16 = 1.28` must be applied
with `NestType.kidMark().copyWith(letterSpacing: 1.28)` at the K02 call site,
not baked into the token. (That is the same pattern as the P12 hero amount at
`-0.4`.)

**Files.** `app/lib/core/design_system/tokens/typography.dart` (add the two
styles), `app/test/design_system/**` (a typography test pinning the metrics).

**When it lands.** Delete the two local `TextStyle`s and the two `TODO(K02)`
blocks at `app/lib/features/kid_home/presentation/views/kid_pin_view.dart`
lines `215-224` and `232-241`, and swap the greeting's explicit
`letterSpacing: 0` for the token's default.

**Blocks K02?** No — the local styles are metric-identical, so the rendered
pixels are already correct.

---

## #2 — `NestKeypad` pitch: landed on `main`, K02 re-check pending

**Need.** `5_ui.md` measured the keypad **outside** the ±2 px UI tolerance:
column pitch 96 vs design 82 (outer keys ±14 px), row pitch ~88–90 vs 82
(R4 Δ +20), and the caption below it Δ +26. Root cause is `NestKeypad`'s
spacing in the tree this branch was cut from — column gap
`NestSpacing.s6` (24), row gap `NestSpacing.s4` (16), padding `NestSpacing.s2`
(8), versus the CSS `.keypad` grid's 10.

This is **already fixed on `main`** — `b1bfb4e`, merged here as `9cac0c6`
("NestKeypad matches CSS .keypad grid"), with
`app/test/design_system/keypad_grid_test.dart` and
`docs/screens/_shared/keypad_grid_REPORT.md`. This worktree still predates
that merge, so the 5_ui drift is an artefact of the branch, **not a K02
defect**. Per `ORCHESTRATOR_NOTES.md` (07:13) K02 must **not** re-space keys
locally, and it correctly does not: the call site carries a `NOTE(K02)`.

**Remaining K02 follow-up (after the loop merges `main`).**

1. Re-run `shot.sh` for `/kid-pin` in light **and** dark and re-run
   `compare.py`; bands 4–6 must fall under ±2.
2. If the merged `NestKeypad` grew a `fit: NestKeypadFit.shrinkWrap` style of
   opt-in, decide whether K02 wants it — the loaded body
   (`kid_pin_view.dart:261`) currently wraps the keypad in no extra padding,
   so a `shrinkWrap` fit is expected to be a no-op here but must be confirmed
   against the design's grid x 77–313.
3. Report the measured y of the first control, each key row and the caption,
   design versus app (UI VERDICT RULE).

**Files.** none on `main`; K02-side only
`app/lib/features/kid_home/presentation/views/kid_pin_view.dart:261`.

**Blocks K02?** No — but it is the sole reason `5_ui` returned FAIL.

---

## #3 — grapheme-safe avatar initial (OPEN) — from `K02-BUG-1`, stage 3

**Need.** `nickname[0].toUpperCase()` indexes UTF-16 **code units**, so a
nickname starting with a non-BMP character (emoji, many CJK extensions,
regional-indicator flags) yields an unpaired surrogate, and
`String.toUpperCase()` then throws
`ArgumentError: Invalid argument(s): string is not well-formed UTF-16` during
text layout. The screen does not degrade — the whole frame fails to build.

There is **no** guard upstream: `app/lib/` contains no `inputFormatters`, no
`maxLength` and no nickname validation, so P05 accepts such a name.

**Seven call sites across four features** — a local patch anywhere leaves the
others broken, which is why this must be one shared helper:

| file | line |
|---|---|
| `features/kid_home/presentation/views/kid_pin_view.dart` | 140 |
| `features/kid_home/presentation/views/kid_home_view.dart` | 364 |
| `features/kid_home/presentation/widgets/profile_tile.dart` | 96 |
| `features/family/presentation/widgets/child_profile_body.dart` | 108 |
| `features/family/presentation/widgets/kid_card_grid.dart` | 68 |
| `features/today/presentation/widgets/today_loaded_body.dart` | 363, 571 |

**Ask.** Add one grapheme-safe initial helper to the design system — e.g.
`String nestAvatarInitial(String name)` in
`app/lib/core/design_system/` (use `characters` or `runes`, not `[0]`), with
the existing empty-name fallbacks preserved (`'?'` for a kid, `'S'` for the
parent row at `today_loaded_body.dart:363`). Then replace all seven sites.

**Also worth a decision:** whether P05 should reject or normalise leading
emoji at input time, or whether the app should simply render them safely. The
helper above is the minimum; the input rule is product's call.

**Files.** `app/lib/core/design_system/**` (new helper + test),
then the seven call sites listed.

**Blocks K02?** No — K02 currently crashes only on a nickname a parent must go
out of their way to type. But it is a **major** (a whole-screen failure, not a
cosmetic one) and K02 cannot fix it alone.

---

## Provenance

* #1 — `1_plan.md` §(g), `2_build.md:89`, `2b_build_ui.md:72`, and the live
  `TODO(K02)` comments at `kid_pin_view.dart:215` and `:232`.
* #2 — `5_ui.md` deviations 1–3, `ORCHESTRATOR_NOTES.md` (07:13),
  `4_review.md` "Carried, shared-owned" §1.
* #3 — `3_test.md` §K02-BUG-1 and `6_bugs.md` §K02-BUG-1 (stage 3 and stage 6
  reached the same finding independently).