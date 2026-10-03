// P11 · Approvals — the bottom action panel (HTML `.bottom-cta`).
//
// `.bottom-cta { background: var(--surface); border-top: 1px solid var(--line);
// padding: 16px 20px }` — the design's panel ends 34 px ABOVE the physical
// edge because its home-indicator strip is `paper`, which puts the 52-high
// "Approve all (N)" pill at y 734–786 (centre 760).
//
// Two owner rules reshape that, and both are honoured here:
//
// * BOTTOM EDGE — the panel surface must run to the physical screen edge (no
//   coloured strip under the bar or around the home indicator), so the design's
//   paper strip is replaced by `surface`.
// * ORCHESTRATOR_NOTES.md item 3 — the pill still has to land where the design
//   draws it. Keeping the surface-to-edge fill and the design's pill position
//   means the space BELOW the button stays `safeArea.bottom + 24`
//   (34 + 24 = 58 px at the design's home inset), not the shared component's
//   `safeArea.bottom + 16`.
//
// This is a P11-local stopgap for the shared `NestBottomCta`, which is 8 px low
// here (see `docs/screens/P11/SHARED_REQUEST.md` §3 — screens cannot edit
// `core/`). Visually identical to `NestBottomCta`: same surface fill, same 1 px
// top `line`, same 20 px gutters, same 16 px above the pill. Swap back to
// `NestBottomCta` when the shared component adopts the 24 px pad.

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// `.bottom-cta` — surface panel running to the physical bottom edge.
class ApprovalsBottomCta extends StatelessWidget {
  const ApprovalsBottomCta({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    // `MediaQuery.padding.bottom` instead of `SafeArea`: SafeArea takes
    // `max(inset, minimum)`, and the design needs the 24 px UNDER the inset,
    // not the larger of the two.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: Padding(
        // Everything the design leaves BELOW the pill: the panel's own 16 px
        // bottom padding plus its 8 px `gap` above the zero-height home
        // indicator it would otherwise draw = 24, and then the device inset,
        // because the surface — not paper — now fills that strip.
        padding: EdgeInsets.only(bottom: bottomInset + NestSpacing.s6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.padSide,
            NestSpacing.s4,
            NestSpacing.padSide,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}
