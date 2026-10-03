// P11 · Approvals — one approval card (HTML `.appr`).
//
//   .appr        surface, radius r-l 24, shadow sh-1, padding 16
//   .appr .hd    row, gap 10, centre
//   .who         flex:1 min-width:0 — name · quest (16/22 w700, truncate)
//   .appr .tm    13/18 ink-2, margin-top 2, `<day> <time> · <coins>`
//   .appr .row   row, gap 10, margin-top 14 — "Not yet" / "Approve"
//
// The design's `.qn` quote row (`"I stacked everything neatly!"`) is NOT
// rendered: `quest_completions` carries no child-message column, so the line
// would be hard-coded mock data. Documented in P11 plan §0 and
// `docs/screens/P11/SHARED_REQUEST.md`; the card renders without it.

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_time.dart';

/// `.avatar` tint from the child's stored `avatarColour`. Feature-private copy
/// of the switch in P08's `today_loaded_body.dart` (that one is private to
/// the today feature, so P11 cannot import it).
NestAvatarColor approvalAvatarColor(String colour) {
  switch (colour) {
    case 'lilac':
      return NestAvatarColor.lilac;
    case 'peach':
      return NestAvatarColor.peach;
    case 'sky':
      return NestAvatarColor.sky;
    case 'leaf':
      return NestAvatarColor.leaf;
    case 'coin':
      return NestAvatarColor.coin;
    default:
      return NestAvatarColor.neutral;
  }
}

/// First letter of the child's nickname, upper-cased (`.avatar` shows `M`/`L`).
String approvalInitial(String childName) {
  final trimmed = childName.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.substring(0, 1).toUpperCase();
}

/// One row of the approvals inbox.
///
/// [busy] marks a write in flight for THIS card only: both buttons go
/// disabled+loading, so a second tap cannot double-write while the parent is
/// still deciding. The parent owns the bloc; this widget only dispatches
/// through the two callbacks.
class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    required this.approval,
    required this.onNotYet,
    required this.onApprove,
    super.key,
    this.nowUtc,
    this.busy = false,
  });

  final Approval approval;
  final VoidCallback onNotYet;
  final VoidCallback onApprove;

  /// "Now" for the Today/Yesterday comparison. Injectable so widget tests
  /// pin the label instead of depending on the wall clock.
  final DateTime? nowUtc;

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final item = approval;
    final now = nowUtc ?? DateTime.now().toUtc();
    final dayLabel = approvalDayLabel(
      createdAtUtc: item.createdAt,
      storedZoneId: item.createdAtTz,
      nowUtc: now,
    );
    final timeLabel = approvalTimeLabel(
      createdAtUtc: item.createdAt,
      storedZoneId: item.createdAtTz,
    );
    final coins = item.coins;
    return NestCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // One announcement for the row content: `excludeSemantics` collapses
          // the avatar + name + time into this single label. It wraps ONLY the
          // `.hd` block — the two buttons below stay outside it, so each keeps
          // its own focusable, tappable node (wrapping the whole card instead
          // would merge the button labels into one node or hide them).
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                '${item.childName}, ${item.questTitle}, $dayLabel $timeLabel, '
                '$coins coins',
            child: Row(
              spacing: NestSpacing.gap10,
              // `.hd` is `align-items: center`, which is also Row's default.
              children: <Widget>[
                NestAvatar(
                  initial: approvalInitial(item.childName),
                  color: approvalAvatarColor(item.avatarColour),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${item.childName} · ${item.questTitle}',
                        style: NestType.bodyStrong(color: tokens.ink)
                            .copyWith(height: 22 / 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: NestSpacing.gap2),
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(text: '$dayLabel $timeLabel · '),
                              // `.money`: tabular figures + w700.
                              TextSpan(
                                text: '$coins coins',
                                style: NestType.caption(color: tokens.ink2)
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const <FontFeature>[
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                          style: NestType.caption(color: tokens.ink2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpacing.gap14),
          Row(
            spacing: NestSpacing.gap10,
            children: <Widget>[
              Expanded(
                child: NestButton(
                  key: ValueKey<String>('p11_not_yet_${item.completionId}'),
                  label: 'Not yet',
                  variant: NestButtonVariant.secondary,
                  minHeight: 48,
                  fontSize: 15,
                  horizontalPadding: NestSpacing.s3,
                  loading: busy,
                  onPressed: busy ? null : onNotYet,
                ),
              ),
              Expanded(
                child: NestButton(
                  key: ValueKey<String>('p11_approve_${item.completionId}'),
                  label: 'Approve',
                  minHeight: 48,
                  fontSize: 15,
                  horizontalPadding: NestSpacing.s3,
                  loading: busy,
                  onPressed: busy ? null : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
