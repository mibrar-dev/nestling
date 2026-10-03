// P11 · Approvals — the loaded body (helper banner + card list, or the empty
// state).
//
// HTML `P11-approvals.html`:
//   .scroll           padding 0 20px 16px  (P11 override of the 32 base)
//   .scroll > * + *   margin-top 16
//   .helper           leaf-tint, radius r-m 16, padding 12px 14px,
//                     14/20 leaf-ink
//   .bottom-cta       "Approve all (N)", 52-high primary button

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_card.dart';

/// P11 helper banner copy, byte-exact from the HTML:
/// U+201C "Not yet" U+201D, then an em dash (U+2014). The middle-dot coins
/// line in the card uses U+00B7 with single spaces, as in the design.
const String approvalsHelperCopy =
    '“Not yet” sends a kind note — no coins are taken away.';

/// Loaded inbox: the helper banner above one [ApprovalCard] per pending row.
///
/// The banner only appears while there is something to approve — an empty
/// inbox shows [ApprovalsEmptyState] instead, so the screen never shows a
/// helper explaining buttons that are not there.
class ApprovalsLoadedBody extends StatelessWidget {
  const ApprovalsLoadedBody({
    required this.items,
    required this.onNotYet,
    required this.onApprove,
    super.key,
    this.busyIds = const <int>{},
    this.nowUtc,
  });

  final List<Approval> items;

  /// `(completionId)` handlers — the body stays stateless about the bloc.
  final void Function(int completionId) onNotYet;
  final void Function(int completionId) onApprove;

  /// Completion ids with a write in flight (P11 plan §1).
  final Set<int> busyIds;

  /// Injectable clock for the Today/Yesterday labels in tests.
  final DateTime? nowUtc;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const ApprovalsEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s4,
      ),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const ApprovalsHelperBanner();
        final item = items[index - 1];
        final id = item.completionId;
        // `.scroll > * + * { margin-top: 16 }` as an explicit top pad, so the
        // banner sits flush with the scroll's 0 top padding.
        return Padding(
          padding: const EdgeInsets.only(top: NestSpacing.s4),
          child: ApprovalCard(
            key: ValueKey<String>('p11_card_$id'),
            approval: item,
            busy: busyIds.contains(id),
            nowUtc: nowUtc,
            onNotYet: () => onNotYet(id),
            onApprove: () => onApprove(id),
          ),
        );
      },
    );
  }
}

/// `.helper` — the "Not yet is kind" note. Leaf tint on leaf ink; the text
/// wraps (no clamp) because the phrase is a sentence, not a label.
class ApprovalsHelperBanner extends StatelessWidget {
  const ApprovalsHelperBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: NestSpacing.s3,
        horizontal: NestSpacing.gap14,
      ),
      decoration: BoxDecoration(
        color: tokens.leafTint,
        borderRadius: NestRadii.allM,
      ),
      child: Text(
        approvalsHelperCopy,
        style: NestType.body(color: tokens.leafInk)
            .copyWith(fontSize: 14, height: 20 / 14),
        softWrap: true,
      ),
    );
  }
}

/// Empty inbox. No artwork (the design has no empty state for P11 and inventing
/// one would add a shared asset), and the copy is child-agnostic so a family
/// with no children seeded shows the same thing.
class ApprovalsEmptyState extends StatelessWidget {
  const ApprovalsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: NestEmptyState(
        title: 'All caught up',
        message:
            'When your children finish a quest, it will appear here for your '
            'thumbs-up.',
      ),
    );
  }
}
