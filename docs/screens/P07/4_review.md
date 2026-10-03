# P07 Paywall — QA code review (Stage 4, iteration 4)

Scope reviewed: `git diff main...HEAD` (paywall feature lib + tests, loop
docs), against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5, `docs/design/SPACING_SPEC.md`, the
design-system under `app/lib/core/design_system/`, and
`docs/screens/P07/ORCHESTRATOR_NOTES.md` (incl. the iteration-4
UPDATE). Evidence: `flutter analyze` (No issues found!),
`flutter test test/features/paywall/` → `+107 ~2` (all passed; skips
remain the shared `[P07-BUG-8]`/`[P07-BUG-9]` router-guard defects on
`SHARED_REQUEST.md`).

Iteration-4 diff versus iteration 3: main fd92d95 merged (NestType now
defaults `letterSpacing: 0`), `_LegalLink` re-centres its label inside
the 44px target (P07-BUG-13), the bugs file adopts P07-BUG-13 with a
`RenderParagraph` baseline proof, and a `readSubscription` one-shot
budget test pins the default-implementation regression guard.

## Findings

1. **Minor — the `·` separators did not get the remedy the
   orchestrator UPDATE prescribed.** `ORCHESTRATOR_NOTES.md`
   (UPDATE 04:08) asked for the separators to "get the same 44 px
   centred box as the links". `_LegalRow`
   (`paywall_view.dart:748-781`) still renders the dots as bare
   `Text`s; the baseline alignment is instead achieved by padding the
   link labels (`paywall_view.dart:819-825`) so the links' 44px boxes
   centre their text, which the wrap then vertically centres against
   the dots. The measurable outcome is identical (P07-BUG-13 baseline
   proof is green), but the next reader diffing against the notes will
   find the note not literally followed. Concrete fix: either wrap each
   `·` in `ConstrainedBox(minWidth/minHeight: NestDevice.tapParent)`
   + `Center` per the note, or amend the note to record the
   padding-based resolution.

2. **Minor — hero/body raw px gaps carried from iteration 2** (hero
   stack at `paywall_view.dart:283-376`, `SizedBox(height: 26/18/48)`,
   `Padding(left: 36)`). Still design-absolute; acceptable since the
   scale-down `LayoutBuilder` owns the hero and the letter-spacing
   merge shifted nothing, but annotate with `// design-absolute` where
   not token-derived.

3. **Minor — CTA caption copy still duplicated** between the static
   view render and `PaywallPlan.detail`
   (`paywall_repository_impl.dart:60-63`), as in iterations 2–3.
   Drop the caption/tag from `detail` or expose it on the entity.

4. **Minor — `PaywallRequest.restore` still doubles as "already
   subscribed"** (`paywall_bloc.dart:50-66`); and the trial guard
   remains fail-open on a `readSubscription()` error
   (`paywall_bloc.dart:86-97`). Both noted in iteration 3, unchanged
   and pinned by tests — a comment-level trade-off, no functional
   defect.

5. **Minor — title orphan ("…for 14 / days") accepted** per the
   orchestrator UPDATE (`text-wrap: balance` is MINOR, no hard break).
   Recorded here so a future iteration does not "fix" it.

## Checks passed

- **Architecture:** feature-first; domain = entities + abstract
  `PaywallRepository` with a documented default
  `readSubscription()`; one BLoC; DI + routes per feature.
- **RULES §1 paths:** diff remains inside
  `app/lib/features/paywall/**`, `app/test/features/paywall/**`,
  `docs/screens/P07/**` (plus orchestrator-driven shared merges on
  main). No shared edits by P07.
- **Design system:** tokens only for colour (`context.nest.*`),
  spacing (`NestSpacing.*`), type (`NestType.*` — now with the merged
  `letterSpacing: 0` default, and no tracking re-added), components
  (`NestBottomCta`, `NestCard`, `NestButton`, `NestIcon`,
  `PipAvatar`). No `google_fonts` anywhere in feature or tests.
- **DESIGN_SPEC §5 / COPY:** all P07 elements present; copy matches
  `P07-paywall.html` character-for-character (curly `’`, em dash
  `—`, `·` U+00B7 separators, `£`, no ASCII apostrophes/quotes/
  ellipses); UK spelling. Benefits row no longer wraps at 390 now that
  letter-spacing tracking is removed (re-measured per the UPDATE).
- **Orchestrator rules:** `PipAvatar(style: mochi, stage: 4, inNest:
  true)`, default `skin: sunny`, 120×120 slot, scaled down only below
  390dp; expired-trial close hidden (P07-BUG-10); active-subscription
  trial guard (P07-BUG-12); `AppSession` via `GetIt.instance`;
  ORCHESTRATOR_NOTES item 1 honoured; no `pip_stage_*.svg` in the
  screen.
- **Accessibility:** header semantics with `explicitChildNodes`;
  close button labelled 44×44; plan card `selected: true`; decorative
  coins/nest/ticks/connectors/dots excluded from semantics; legal
  links labelled buttons on ≥44 targets with the labels now centred on
  one baseline with the dots.
- **Performance:** `ListenableBuilder` scoped to the nav row; items
  stream belongs to a single `emit.forEach`; one-shot
  `readSubscription()` with a pinned budget; eager static column; no
  rebuild storms observed; SVGs `ExcludeSemantics`-wrapped.
- **Error handling:** load failure → "Something went wrong" + Retry;
  action failure → `showNestToast` with reason, no navigation, retry
  works; working-state double-tap no-op; CTA spinner belongs to the
  trial request only.
- **Children's Code:** parent mode only; no analytics, ads, tracking
  or child data surfaced.
- **Tests:** `+107 ~2` green; the two skips are shared-code proofs
  filed in `SHARED_REQUEST.md`; BUG-13 now fixed and its proof
  unskipped (baseline equality `linkBaseline` vs `dotBaseline`,
  `epsilon: 1`).

## Verdict basis

No blocker or major findings. All iteration 3 action items were
re-verified; the iteration-4 items (letter-spacing merge, legal-link
centring, dot centring) resolve to the design except finding 1, which
is a documentation-level deviation with the same visual outcome.

VERDICT: PASS
