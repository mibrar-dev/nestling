# 3 TEST (iteration 4) — K02 Kid PIN (`kid_home`, `/kid-pin`)

Scope: `app/test/features/kid_home/**` + this file (RULES §1). **No product
code was touched by this stage.** No simulator was booted, installed on,
screenshot or driven.

The iteration-4 build (`2_build.md`) closed **K02-TEST-BUG-A** — the finding
this stage raised in iterations 2 and 3 — by routing all three `kid_home`
avatar-initial call sites through a new grapheme-safe helper,
`kidAvatarInitial()` in `presentation/widgets/kid_style_helpers.dart`
(`kid_pin_view.dart:168`, `kid_home_view.dart:364`, `profile_tile.dart:94`).
The brief's new mandatory rule for this iteration is **AVATAR INITIALS: use
`nestAvatarInitial(name)` (grapheme-safe). Never `name[0]`**, so this stage's
job was to make that rule *enforceable* for the feature, not just true today.

## Tests added — new file `kid_avatar_initial_test.dart` (8 tests)

`nestAvatarInitial` does not exist in `core/design_system/` yet (still
SHARED_REQUEST #3), so `kid_home` uses the feature-local interim helper. These
tests pin that interim state in three layers, and are written so they survive
the helper's move:

| Layer | Test | What it pins |
|---|---|---|
| 1 — the helper's contract | `an empty nickname uses the fallback` | `''` → `?`, and the `fallback` parameter (the parent row's `'S'`) is honoured rather than branched at the call site |
| | `a plain name upper-cases its first character` | ASCII, leading space, digit-leading names |
| | `a non-ASCII first character survives whole (never a lone surrogate)` | the crash class itself: `Åsa`, `Émile`, `𝒜da` (astral), `🐝 Bee`, `🇬🇧 Ben` (a regional-indicator **pair** — the first rune only, never half a flag), `👨‍👩‍👧 Family` (ZWJ sequence — first rune, not the cluster). Each result is exactly **one** well-formed code point that survives `toUpperCase()` |
| | `a leading combining mark does not throw` | a decomposed `A`+U+0308 first character: the helper takes the base letter and the frame still builds |
| 2 — the third render site | `the picker builds and shows the emoji initial` | **K01's profile tile** was the one migrated site with no render proof (the iteration-4 build covered K02 and K03). `/who-is-playing` must build with `🐝 Bee` (`takeException() == null`) *and* show the emoji as the tile's avatar initial — so a placeholder substitution cannot pass — with the roster still in creation order (Maya's tile first) and the name itself unchanged on screen |
| 3 — the rule itself | `no call site indexes a name with [0]` | scans the four `kid_home` presentation files for `nickname[0]` / `child.nickname[0]` / `name [ 0 ]` with comments stripped first (the helper's doc comment legitimately *names* the anti-pattern) |
| | `the guard itself bites (a reintroduced index is caught)` | a guard that cannot fail is not a guard: the pattern is proven against the three forbidden shapes, proven silent on the fixed call sites, and `_codeOnly` is proven to strip prose |
| | `the helper itself is rune-based` | `runes.first` stays in the helper, so a future edit cannot quietly change the mechanism |

When `nestAvatarInitial` lands in `core/design_system/`, delete layers 1 and
the helper reference in layer 2 and keep layer 3 — it is what stops the
regression coming back through a re-inlined copy.

Also re-verified unchanged after this build: `kid_pin_view_test.dart` (58,
including the two gate-detour tests the build repaired for the post-P17
`Back to Pip` exit and the `NestRadii.allPill` token move), the bloc suite
(13 K02 tests), the bugs suite (33) and the design-anchor geometry.

## Gates

```
dart format --set-exit-if-changed --output=none test/features/kid_home lib/features/kid_home
Formatted 37 files (0 changed) in 0.23 seconds.

flutter analyze
Analyzing app...
No issues found! (ran in 5.6s)

flutter test --timeout 120s test/features/kid_home/kid_pin_view_test.dart test/features/kid_home/kid_avatar_initial_test.dart
00:05 +66: All tests passed!

flutter test --timeout 120s test/features/kid_home
00:23 +452 ~1: All tests passed!

flutter test --timeout 120s                    (whole app)
04:35 +3373 ~2: All tests passed!
```

Every run used `--timeout 120s` (TEST TIMEOUTS rule); the largest K02 file is
4 s, the whole feature directory 23 s. The `~2` skips are the sibling parks
(`K01-BUG-7`, P12) — no skip was added by this stage, and no assertion was
weakened or removed.

## Bugs

**None found by this stage.** No test I added exposed a defect in
`kid_pin_view.dart`, the bloc or the interim helper.

**K02-TEST-BUG-A is closed for `kid_home`** — the crash class I reported in
iterations 2 and 3 (whole-frame `ArgumentError: string is not well-formed
UTF-16` on a P05-legal `🐝 Bee` nickname) no longer reproduces on any of the
three screens, and is now pinned from outside the helper: K02 by
`kid_pin_view_test.dart`, K03 by `kid_home_view_test.dart`, K01 by this stage's
picker render test. All three go through `kidAvatarInitial`.

**Still open, shared-owned, not this stage's to fix:**

* `nestAvatarInitial` itself (SHARED_REQUEST #3, `core/design_system/**`) — the
  rule in this iteration's brief names it, but it is not in the tree; the
  interim helper carries a `TODO(K02)` to delete it on arrival.
* Four code-unit sites remain **outside** this feature —
  `today_loaded_body.dart:571`, `kid_card_grid.dart:68`,
  `child_profile_body.dart:108`, `parental_gate_view.dart:400` — now covered
  by the same AVATAR INITIALS rule for the `today`, `family` and
  `parental_gate` loops. Out of RULES §1 here (other features), so recorded
  rather than patched.

## Notes for the next iteration

1. **K02 is done.** 58 view tests + 13 bloc tests + 33 bug proofs + 8
   avatar-initial tests, geometry pinned at unit level and pixel-verified by
   5_ui, design copy read from the HTML source. Further K02 test work should
   only follow a behaviour change.
2. **When the shared helper lands**, the migration order is: move the helper
   to `core/design_system/`, switch the three `kid_home` call sites, delete
   layers 1–2 of `kid_avatar_initial_test.dart`, keep layer 3 (the `[0]` guard)
   and widen its file list to the four features.
3. Unchanged harness rules, still the two that cost the most time here: one
   `tester.runAsync` cycle per `testWidgets` (two deadlock the binding), and
   settle past the page transition before asserting a previous route is gone.
4. `find.bySemanticsLabel` still needs a `RegExp` for merged nodes (dots, toast).

VERDICT: PASS