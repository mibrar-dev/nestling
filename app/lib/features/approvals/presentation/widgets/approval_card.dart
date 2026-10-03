// P11 · Approvals — one approval card (HTML `.appr`).
//
//   .appr        surface, radius r-l 24, shadow sh-1, padding 16
//   .appr .hd    row, gap 10, centre
//   .who         flex:1 min-width:0 — name · quest (16/22 w700, truncate)
//   .appr .qn    17/24 w700, margin-top 10 — the child's note, IN CURLY QUOTES
//   .appr .tm    13/18 ink-2, margin-top 2, `<day> <time> · <coins>`
//   .appr .row   row, gap 10, margin-top 14 — "Not yet" / "Approve"
//
// `.qn` is data, not decoration: the note is `quest_completions.kid_note`
// (schema v6, `docs/screens/_shared/completion_note_REPORT.md`), surfaced as
// `Approval.kidNote`. The seed stores the RAW text without quotes, so the marks
// are added here — U+201C … U+201D, exactly as the HTML renders them
// (`<div class="qn">“I stacked everything neatly!”</div>`). A NULL note renders
// NO line and NO gap (the design has no empty-quote state): the card is then
// 138 high instead of 172, and both heights are pinned in
// `approvals_view_geometry_test.dart`.
//
// `.qn` sets no `font-family` in the CSS, so it inherits the parent UI face
// (Inter) — measured against the PNG rather than assumed: the design's quote
// ink spans x 37.3–284.0 (246.7 px) and Inter w700 @17 advances 249.2 (≈247
// ink), while Nunito @17 advances only 232.4. The `.who` line validates the
// method: design ink 228.33 vs Inter w700 @16 = 229.99.

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

/// Which of the two card buttons the parent pressed. Only the pressed one
/// shows a spinner (BUG-P11-4): `busy` alone says "a write is in flight for
/// this card", not which decision it was, so tapping Approve used to spin the
/// "Not yet" pill too — an action the parent never took.
enum ApprovalDecision { notYet, approve }

/// One row of the approvals inbox.
///
/// [busy] marks a write in flight for THIS card only: both buttons go
/// disabled so a second tap cannot double-write while the parent is still
/// deciding, but only the button that was pressed spins. The parent owns the
/// bloc; this widget only dispatches through the two callbacks.
class ApprovalCard extends StatefulWidget {
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
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  /// The decision this card is waiting on. Only consulted while the widget's
  /// `busy` flag is true, and every path that turns `busy` true goes through
  /// [_press] first, so it needs no reset when a write completes.
  ApprovalDecision? _pending;

  void _press(ApprovalDecision decision, VoidCallback action) {
    // Set BEFORE dispatching: the bloc's busy flag only paints on the next
    // frame, and the spinner must be up for the pressed button from there on.
    setState(() => _pending = decision);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final item = widget.approval;
    final now = widget.nowUtc ?? DateTime.now().toUtc();
    final busy = widget.busy;
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
    final kidNote = item.kidNote?.trim();
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
          // `.appr .qn { margin-top: 10 }` — 10 px is below the 4 pt grid, so
          // it is written literally here (same as `.tm`'s 2 px gap token).
          // A NULL note renders NOTHING: no line, no 10 px gap, no 24 px box.
          if (kidNote != null && kidNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                // U+201C … U+201D around the stored raw note (the seed keeps
                // the text without its quotes — completion_note_REPORT.md).
                '“$kidNote”',
                style: NestType.bodyStrong(color: tokens.ink)
                    .copyWith(fontSize: 17, height: 24 / 17),
                softWrap: true,
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
                  loading: busy && _pending == ApprovalDecision.notYet,
                  onPressed: busy
                      ? null
                      : () => _press(ApprovalDecision.notYet, widget.onNotYet),
                ),
              ),
              Expanded(
                child: NestButton(
                  key: ValueKey<String>('p11_approve_${item.completionId}'),
                  label: 'Approve',
                  minHeight: 48,
                  fontSize: 15,
                  horizontalPadding: NestSpacing.s3,
                  loading: busy && _pending == ApprovalDecision.approve,
                  onPressed: busy
                      ? null
                      : () =>
                            _press(ApprovalDecision.approve, widget.onApprove),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
