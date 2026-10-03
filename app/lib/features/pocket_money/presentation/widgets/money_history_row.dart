import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_pounds.dart';

/// `.hrow` (P12 HTML source): `display:flex; align-items:center; gap:12px;
/// min-height:56px` — a 40×40 tile, a flexible middle and a nowrap amount.
/// No dividers and no tap target: ledger rows are display-only.
///
/// The tile colours come from the shared [NestTileTint] mapping so the
/// ledger matches `NestListRow`; the row itself is local because
/// `quest_bonus` renders the coin *illustration* (own colours, never
/// [NestIcon]) and the amounts are per-type signed copy.
class MoneyHistoryRow extends StatelessWidget {
  const MoneyHistoryRow({
    required this.entry,
    required this.familyZoneId,
    super.key,
  });

  final PocketMoneyEntry entry;

  /// Current `families.time_zone` — payout/weekly-base labels render in it.
  final String familyZoneId;

  /// `.hrow` min-height 56 (design CSS), not a tap target: the row is
  /// display-only.
  static const double _minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final tint = _tint(entry.type);
    final Color tileBg;
    final Color tileFg;
    switch (tint) {
      case NestTileTint.neutral:
        tileBg = tokens.surface2;
        tileFg = tokens.ink;
      case NestTileTint.leaf:
        tileBg = tokens.leafTint;
        tileFg = tokens.leafInk;
      case NestTileTint.coin:
        tileBg = tokens.coinTint;
        tileFg = tokens.coinInk;
      case NestTileTint.sky:
        tileBg = tokens.skyTint;
        tileFg = tokens.sky;
      case NestTileTint.lilac:
        tileBg = tokens.lilacTint;
        tileFg = tokens.lilac;
      case NestTileTint.peach:
        tileBg = tokens.peachTint;
        tileFg = tokens.aPeach;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Row(
        children: <Widget>[
          // Display-only art: excluded from semantics, the row is text.
          ExcludeSemantics(
            child: Container(
              width: NestSpacing.s10,
              height: NestSpacing.s10,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(NestSpacing.s3),
              ),
              alignment: Alignment.center,
              child: entry.type == 'quest_bonus'
                  ? SvgPicture.asset(
                      NestlingIllustrations.coin,
                      width: NestSpacing.s6,
                      height: NestSpacing.s6,
                    )
                  : NestIcon(_iconFor(entry.type), color: tileFg),
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _titleFor(entry, familyZoneId),
                  style: NestType.bodySmallStrong(color: tokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtitleFor(entry, familyZoneId),
                  style: NestType.caption(color: tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          Text(
            _amountFor(entry),
            style: NestType.money(color: tokens.ink),
            maxLines: 1,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  static NestTileTint _tint(String type) {
    switch (type) {
      case 'weekly_base':
        return NestTileTint.sky;
      case 'quest_bonus':
        return NestTileTint.coin;
      case 'gift':
      case 'savings_move':
        return NestTileTint.lilac;
      case 'spend':
        return NestTileTint.peach;
      case 'payout':
        return NestTileTint.leaf;
      default:
        return NestTileTint.neutral;
    }
  }

  static String _iconFor(String type) {
    switch (type) {
      case 'weekly_base':
        return NestIcons.poundCoin;
      case 'gift':
        return NestIcons.gift;
      case 'spend':
        return NestIcons.bag;
      case 'payout':
        return NestIcons.check;
      case 'savings_move':
        return NestIcons.saved;
      default:
        return NestIcons.money;
    }
  }

  static String _titleFor(PocketMoneyEntry entry, String familyZoneId) {
    switch (entry.type) {
      case 'weekly_base':
        return 'Weekly pocket money';
      case 'quest_bonus':
        return 'Quest bonus $kMoneyDot ${entry.note}';
      case 'spend':
        return 'Spent $kMoneyDot ${entry.note}';
      case 'payout':
        return 'Paid $kMoneyDot ${_day(entry, familyZoneId)}';
      // `gift` / `savings_move` print the seeded note verbatim
      // ("Birthday money (added by Mum)", "Birthday money → Lego fund").
      case 'gift':
      case 'savings_move':
        return entry.note;
      default:
        return entry.title;
    }
  }

  static String _subtitleFor(PocketMoneyEntry entry, String familyZoneId) {
    switch (entry.type) {
      case 'weekly_base':
        return _day(entry, familyZoneId);
      case 'quest_bonus':
        return '+${moneyPence(entry.amountPence)} $kMoneyDot Approved';
      case 'gift':
      case 'savings_move':
        return 'To savings goal';
      case 'spend':
        return 'Recorded by Mum';
      case 'payout':
        return 'Cash from Mum';
      default:
        return entry.detail;
    }
  }

  static String _amountFor(PocketMoneyEntry entry) {
    switch (entry.type) {
      case 'weekly_base':
      case 'quest_bonus':
      case 'gift':
      case 'savings_move':
        return moneyPlus(entry.amountPence);
      case 'spend':
        return moneyMinus(entry.amountPence);
      // The design prints the payout without a sign (`£3.80`).
      case 'payout':
        return moneyPounds(entry.amountPence);
      default:
        return entry.amountPence < 0
            ? moneyMinus(entry.amountPence)
            : moneyPounds(entry.amountPence);
    }
  }

  static String _day(PocketMoneyEntry entry, String familyZoneId) {
    return formatDay(entry.date, entry.dateTz, familyZoneId: familyZoneId);
  }
}
