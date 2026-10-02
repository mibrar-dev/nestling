# P04 · Privacy consent — QA code review (STAGE 4, iteration 5)

Feature `privacy_consent` · route `/privacy` · parent mode · branch `screen/P04`.
Reviewed surface: `git diff main...HEAD` plus the uncommitted working-tree build.
`main` is ahead on shared work (P02 merged), and `HEAD`'s merges include the
batch that finally answered P04's two open blockers.

Production code changed this iteration (two wire-ups, both one-liners):
`privacy_consent_view.dart` swaps the baked shield SVG for
`NestPrivacyShield` and the bare row-4 tile for `leadingAsset:
NestIcons.trash`, reverts `NestList` to four direct row children (the local
`showDivider` + `Stack` overlay is deleted), and the test/notes files are
rewritten around the new rendering paths. `p04_bugs_test.dart` un-skips
`[P04-2]` and `[P04-7]`; `privacy_consent_artwork_test.dart` is new (11
tests). No other production file moved.

Checks run for this review:

```
dart format --output=none --set-exit-if-changed lib/features/privacy_consent \
     test/features/privacy_consent        → 18 files, 0 changed
flutter analyze                            → No issues found! (ran in 5.5s)
flutter test test/features/privacy_consent/ → 00:05 +131: All tests passed!
flutter test  (whole app)                  → 00:29 +684 ~0: All tests passed!
tools/screens/compare.py vs ui/app_light_5.png → mean diff 4.08%
     bands 1.57 / 6.02 / 1.98 / 7.94 / 5.62 / 4.19 / 0.40 / 4.84 %
tools/screens/compare.py vs ui/app_dark_5.png  → mean diff 3.96%
     bands 1.55 / 6.29 / 1.94 / 7.87 / 5.57 / 4.44 / 0.39 / 3.55 %
```

Skipped bug proofs dropped 2 → **0**; the whole app runs with **0 skips**.
Mean diff: light 4.10% → **4.08%**, dark 5.15% → **3.96%**, and dark band 2
(211–316, the shield disc) fell **9.14% → 1.94%**.

Pixel probes (PNG ÷ 3), design vs `ui/app_{light,dark}_5.png`:

| probe | design | app it. 5 | verdict |
|---|---|---|---|
| back-chevron glyph band | 66–80 | 66–80 | Δ0 |
| h1 glyph band | 113–138 | 113–138 | Δ0 |
| subtitle glyph band | 156–170 | 156–170 | Δ0 |
| shield disc, dark | `#1A2A4A` | **`#1A2A4A`** | **Δ0 — P04-7 closed** |
| row-4 tile ink, light | `#B44A1F` | **present** | **the glyph renders** |
| bottom-CTA surface (dark) | `#1F1C2E` @ y820–838 | `#1F1C2E` | ✓ owner bottom-edge |

Histogram of the design's row-4 tile strokes: core ink `#B44A1F` (104 px),
which equals `NestColors.light.aPeach` and the design's own
`--a-peach` in `tokens.css`. The 15:27 note's hand-measured "#BA562E" is an
antialiased edge probe; P04 uses the token, so it matches both the CSS token
and the rendered core pixel. No action.

---

## Findings

### 1. MINOR — stale header comment in the widget contract test

- **Where:** `app/test/features/privacy_consent/privacy_consent_view_test.dart:8-9`
  — "The 4th promise row reserves its 40x40 peach tile behind TODO(P04)
  (docs/screens/P04/SHARED_REQUEST.md): no stand-in icon is asserted."
- **Why:** row 4 now renders `NestIcons.trash` (`privacy_consent_view.dart:107`),
  `privacy_consent_artwork_test.dart` asserts the shared glyph in both themes, and
  `p04_bugs_test.dart`'s file index marks P04-2 `[FIXED]`. The comment
  contradicts the shipped state and will mislead the next reader.
- **Fix:** delete lines 8–9 or replace with "All four promise rows render the
  shared tinted glyph in both themes (`privacy_consent_artwork_test.dart`)."

No other findings. Every previous blocker/major is closed and verified:

- **P04-2 (row-4 glyph)** — fixed. `NestIcons.trash` is rendered in the peach
  tile; `ic_trash.svg`'s path data is asserted to be the design's exact `<path
  d>` in `privacy_consent_artwork_test.dart` (the shared 57-icon sweep confirms
  only `ic_bin` (wheelie) and `ic_basket` (laundry) exist as look-alikes, and the
  test rejects either as a stand-in).
- **P04-7 (dark shield)** — fixed. `NestPrivacyShield` paints from theme tokens;
  the test rasterises the actual `CustomPainter` at 84 px and asserts every
  painted pixel is one of the four theme tokens and **no** foreign-theme token
  appears. Rendered disc is now the design's `#1A2A4A`.
- **P04-4 (divider drift)** — the iteration-4 local overlay is deleted; the four
  rows are direct `NestList` children again and the shared zero-height overlay
  owns the separators. List geometry probes now match the design exactly
  (implicitly covered by the probe row in the table above).
- **Review finding 4 (mechanism-pinning assertion)** — the contract test now
  asserts the result (`dividerOf(0)` finds nothing, separator `dy ==` row top,
  `dx` offset 72, colour = `palette.line`) and the one Stack-lookup is a
  mechanism-independent locator of the shared overlay container.
- **Review finding 5 (misquoted runner output)** — `2_build.md` and
  `3_test.md` now quote the real strings (`All tests passed!`, 0 skips).

---

## Verified correct (no action)

- **Architecture:** unchanged and compliant — `domain/` holds the entity (plus
  `ConsentOptionIds`) and the abstract repository only; one bloc per feature with
  `LoadRequested` and initial/loading/loaded/failure; DI and routes per feature,
  untouched. `analysis_options.yaml` untouched; the only non-feature working-tree
  edit is the regenerated `Podfile.lock`, which already matches `main`'s (it is
  the loop's merge reconciliation of main's K03 `flutter_timezone` plugin, not a
  hand edit).
- **Design-system usage:** `NestStatusBar`, `NestNavBar`, `NestList`, `NestCard`,
  `NestToggle`, `NestButton`, `NestBottomCta`, `NestIcon`, `NestPrivacyShield`,
  `showNestModal` all reused; only the promise row and the notice link are
  feature-private, both justified inline. No new hex, size or type literals;
  the `SvgPicture`/`flutter_svg` import in the view is gone with the last baked
  asset reference.
- **DESIGN_SPEC §5 P04 / COPY rule:** every element present in order; copy
  identical to the HTML source, locked by `privacy_consent_copy_test.dart`
  (unchanged this iteration). `CHILD ORDER` is not applicable — no children are
  read or rendered.
- **Accessibility:** shield announced as `image: true` with the design's alt
  text (asserted); row-4 glyph uses the shared tinted `NestIcon` like the other
  three rows, so the "all four icons find their SvgPicture/Icon" requirement is
  now met by `privacy_consent_artwork_test.dart` in light and dark; rows remain
  non-button `Semantics(container: true)`; toggle/back/links keep their labels
  and ≥ 44 px targets; rows wrap (no `maxLines`) inside the three-width ×
  two-scale matrix. Contrast unchanged.
- **Performance:** `const Center(child: NestPrivacyShield(...))` replaces a
  per-build `SvgPicture`, so the shield no longer re-decodes the asset on a
  toggle rebuild; no new layout passes; the four-row `Column` inside the scroll
  view is `MainAxisSize`-bounded by the scroll parent; the bloc's
  optimistic-then-reconcile flow is untouched, no rebuild storms, no leaked
  streams (all guards green).
- **Error handling:** the first-run upsert is transactional (last-write-wins);
  the failure caption is state-aware and truthful; a stale message clears on the
  next successful emission; no other write paths exist.
- **Children's Code:** no analytics, ads, trackers or SDKs anywhere in the diff;
  no child data read; the single write is an optional, parent-only, default-OFF
  consent flag; the kid-mode guard is green.
- **OWNER BOTTOM-EDGE rule: correct** — `#1F1C2E` at y 820/838 in dark, `#FFFFFF`
  in light, matching the CTA surface, while the design PNGs show a strip there
  (the HTML `.home-indicator`). The app is the intended behaviour.
- **OWNER ALIGNMENT rule: met** — probes show the header block and card
  positions at design values; band-6 blank-paper ≈ 0.4% confirms no phantom
  drift.

## ORCHESTRATOR_NOTES status

| Item | Status |
|---|---|
| 1 — red-ink bin glyph + a test that all four rows find their glyph | **Met** — `NestIcons.trash` wired, path data is the design's `<path d>`, ink is `NestColors.*.aPeach` (= the design `#B44A1F`), a test pins all four rows light+dark |
| 2 — header block ≈ design | **Met** since the shared compact-nav merge; probes Δ0 |
| 3 — row heights/divider → opt card ≈528, Continue ≈690 | **Met** — list and opt card now match the design pixel-for-pixel |
| 4 — bottom panel to the edge, perfect alignment | **Met** |
| 12:03 / 13:42 / 15:27 UPDATEs | Trash glyph, themed shield and shared separator overlay all landed on main and are consumed; iteration-4 minor findings resolved |
| COPY rule | **Met** and locked by test |
| CHILD ORDER rule | N/A — no children on this screen |

VERDICT: PASS