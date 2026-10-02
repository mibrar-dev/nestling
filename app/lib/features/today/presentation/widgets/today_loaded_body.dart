import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/approvals_routes.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/quests/quests_routes.dart';
import 'package:nestling/features/settings/settings_routes.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/bloc/today_state.dart';

/// Seed `quests.icon` → token-colourable [NestIcons] asset.
String todayIconFor(String icon) {
  switch (icon) {
    case 'dishwasher':
      return NestIcons.dishwasher;
    case 'book':
      return NestIcons.book;
    case 'bins':
    case 'bin':
      return NestIcons.bin;
    case 'bed':
      return NestIcons.bed;
    case 'hoover':
      return NestIcons.hoover;
    case 'paw':
      return NestIcons.paw;
    case 'bag':
      return NestIcons.bag;
    case 'leaf':
      return NestIcons.sprout;
    case 'shirt':
      return NestIcons.washingMachine;
    case 'plate':
      return NestIcons.table;
    default:
      return NestIcons.questCard;
  }
}

/// `.icon-tile` tint per quest icon (HTML `tint-*` classes on P08).
({Color bg, Color fg}) todayTintFor(String icon, NestTokens tokens) {
  switch (icon) {
    case 'dishwasher':
      return (bg: tokens.skyTint, fg: tokens.sky);
    case 'book':
      return (bg: tokens.lilacTint, fg: tokens.lilac);
    case 'bins':
    case 'bin':
      return (bg: tokens.leafTint, fg: tokens.leafInk);
    case 'bed':
      return (bg: tokens.peachTint, fg: tokens.aPeach);
    case 'paw':
      return (bg: tokens.coinTint, fg: tokens.coinInk);
    case 'plate':
      return (bg: tokens.lilacTint, fg: tokens.lilac);
    case 'bag':
      return (bg: tokens.leafTint, fg: tokens.leafInk);
    case 'leaf':
      return (bg: tokens.leafTint, fg: tokens.leafInk);
    case 'shirt':
      return (bg: tokens.skyTint, fg: tokens.sky);
    case 'sofa':
      return (bg: tokens.peachTint, fg: tokens.aPeach);
    default:
      return (bg: tokens.skyTint, fg: tokens.sky);
  }
}

/// Human status label for a completion status (P08 `.status-chip` text).
String todayStatusLabel(String status) {
  switch (status) {
    case 'done_pending':
      return 'Needs a look';
    case 'approved':
      return 'Approved ✓';
    case 'not_yet':
      return 'Try again';
    default:
      return 'To do';
  }
}

/// `'· Daily'`-style repeat text (HTML `.quest-meta`).
String todayRepeatText(String repeatRule, int payoutDay) {
  const days = <int, String>{
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
  switch (repeatRule) {
    case 'daily':
      return '· Daily';
    case 'weekly':
      return '· Weekly · ${days[payoutDay] ?? 'Sat'}';
    default:
      return '· Once';
  }
}

String pipStageAsset(int stage) {
  switch (stage) {
    case 1:
      return NestlingIllustrations.pipStage1;
    case 2:
      return NestlingIllustrations.pipStage2;
    case 4:
      return NestlingIllustrations.pipStage4;
    default:
      return NestlingIllustrations.pipStage3;
  }
}

String pipStageName(int stage) {
  switch (stage) {
    case 1:
      return 'an egg';
    case 2:
      return 'a hatchling';
    case 4:
      return 'a songbird';
    default:
      return 'a fledgling';
  }
}

NestAvatarColor avatarColorFor(String colour) {
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

/// P08 status chip: 26px pill at base scale (HTML `.status-chip`).
class TodayStatusChip extends StatelessWidget {
  const TodayStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final (Color bg, Color fg) = switch (status) {
      'done_pending' => (tokens.coinTint, tokens.coinInk),
      'approved' => (tokens.leafTint, tokens.leafInk),
      _ => (tokens.surface2, tokens.ink2),
    };
    // No fixed height/alignment: the pill sizes to its label (12/16 text +
    // 5px vertical padding = 26px tall) so it never stretches to the full
    // run width when the card's Wrap moves it onto its own line.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NestSpacing.gap10,
        vertical: NestSpacing.gap5,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: NestRadii.allPill),
      child: Text(
        todayStatusLabel(status),
        style: NestType.chipSmall(color: fg),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Shared loaded body for `/today` and `/today-empty` (P08 + P08b).
class TodayLoadedBody extends StatelessWidget {
  const TodayLoadedBody({required this.state, super.key});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    if (state.summaries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          NestSpacing.padSide,
          0,
          NestSpacing.padSide,
          NestSpacing.s8,
        ),
        children: <Widget>[
          _Greeting(
            greeting: state.greeting,
            parentName: state.parentName,
            dateLine: state.dateLine,
          ),
          const SizedBox(height: NestSpacing.s4),
          const _EmptyCard(),
        ],
      );
    }
    final children = <Widget>[
      _Greeting(
        greeting: state.greeting,
        parentName: state.parentName,
        dateLine: state.dateLine,
      ),
    ];
    if (state.pendingCount > 0) {
      children
        ..add(const SizedBox(height: NestSpacing.s4))
        ..add(_ApprovalsBanner(pendingCount: state.pendingCount));
    }
    children
      ..add(const SizedBox(height: NestSpacing.s4))
      ..add(_KidsGrid(summaries: state.summaries))
      ..add(const SizedBox(height: NestSpacing.s4))
      ..add(const _SectionHeader());
    for (final summary in state.summaries) {
      children
        ..add(const SizedBox(height: NestSpacing.s4))
        ..add(_GroupLabel(summary: summary));
      final mine = state.items
          .where((i) => i.childId == summary.childId)
          .toList();
      for (final item in mine) {
        children
          ..add(const SizedBox(height: NestSpacing.s2))
          ..add(_QuestRow(item: item, payoutDay: state.payoutDay));
      }
    }
    children
      ..add(const SizedBox(height: NestSpacing.s4))
      ..add(_HandButton(summaries: state.summaries));
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s8,
      ),
      children: children,
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.greeting,
    required this.parentName,
    required this.dateLine,
  });

  final String greeting;
  final String parentName;
  final String dateLine;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final initial = parentName.isEmpty ? 'S' : parentName[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(top: NestSpacing.s2),
      child: Row(
        spacing: NestSpacing.s2,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '$greeting, $parentName',
                    style: NestType.h2(color: tokens.ink)
                        .copyWith(fontSize: 22, height: 28 / 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: NestSpacing.gap2),
                  child: Text(
                    dateLine,
                    style: NestType.bodySmall(color: tokens.ink2).copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            spacing: NestSpacing.s2,
            mainAxisSize: MainAxisSize.min,
            children: [
              NestIconButton(
                icon: NestIcons.plus,
                semanticLabel: 'New quest',
                backgroundColor: tokens.leaf,
                foregroundColor: tokens.onLeaf,
                borderColor: Colors.transparent,
                onPressed: () => context.go(QuestsRoutePaths.editor),
              ),
              SizedBox.square(
                dimension: NestDevice.tapParent,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.go(SettingsRoutePaths.settings),
                    child: Semantics(
                      button: true,
                      label: "$parentName's profile",
                      excludeSemantics: true,
                      child: Center(
                        child: NestAvatar(
                          initial: initial,
                          color: NestAvatarColor.leaf,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalsBanner extends StatelessWidget {
  const _ApprovalsBanner({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      liveRegion: true,
      label: '$pendingCount quests waiting for your thumbs-up',
      child: Container(
        padding: const EdgeInsets.all(NestSpacing.s4),
        decoration: BoxDecoration(
          color: tokens.leafTint,
          borderRadius: NestRadii.allL,
          boxShadow: tokens.cardShadow,
        ),
        child: Row(
          spacing: NestSpacing.s3,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pendingCount quests waiting for your thumbs-up',
                    style: NestType.bodyStrong(color: tokens.leafInk),
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Your little birds did brilliantly',
                    style: NestType.caption(
                      color: tokens.leafInk.withValues(alpha: 0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            NestButton(
              label: 'Review',
              fullWidth: false,
              minHeight: NestDevice.tapParent,
              fontSize: 15,
              horizontalPadding: 18,
              onPressed: () => context.go(ApprovalsRoutePaths.approvals),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidsGrid extends StatelessWidget {
  const _KidsGrid({required this.summaries});

  final List<ChildDaySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final cards = summaries.map(_KidCard.new).toList();
    if (cards.length == 1) return cards.single;
    return Row(
      spacing: NestSpacing.gap10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final card in cards) Expanded(child: card)],
    );
  }
}

class _KidCard extends StatelessWidget {
  const _KidCard(this.summary);

  final ChildDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final fraction = summary.total > 0 ? summary.done / summary.total : 0.0;
    return NestCard(
      padding: const EdgeInsets.all(NestSpacing.gap14),
      onTap: () => context.go(
        '${FamilyRoutePaths.childProfile}?childId=${summary.childId}',
      ),
      semanticLabel:
          '${summary.nickname}, ${summary.done} of ${summary.total} quests, ${summary.coins} coins',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: NestSpacing.s2,
            children: [
              NestAvatar(
                initial: summary.nickname.isEmpty
                    ? '?'
                    : summary.nickname[0].toUpperCase(),
                size: NestAvatarSize.s32,
                color: avatarColorFor(summary.avatarColour),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summary.nickname,
                      style: NestType.h3(color: tokens.ink)
                          .copyWith(fontSize: 17, height: 22 / 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${summary.done} of ${summary.total} quests',
                      style: NestType.caption(color: tokens.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                top: NestSpacing.gap6,
                bottom: NestSpacing.gap2,
              ),
              child: Semantics(
                image: true,
                label:
                    "${summary.nickname}'s Pip, ${pipStageName(summary.pipStage)}",
                child: ExcludeSemantics(
                  child: SvgPicture.asset(
                    pipStageAsset(summary.pipStage),
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
            ),
          ),
          NestProgress(
            fraction: fraction,
            semanticLabel: "${summary.nickname}'s quest progress",
          ),
          Padding(
            padding: const EdgeInsets.only(top: NestSpacing.gap10),
            child: NestCoinPill(amount: '${summary.coins}'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            "Today's quests",
            style: NestType.h3(color: tokens.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: () => context.go(QuestsRoutePaths.library),
          child: Semantics(
            button: true,
            label: 'See all quests',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: NestSpacing.s3,
                horizontal: NestSpacing.s2,
              ),
              child: Text(
                'See all',
                style: NestType.chipLabel(color: tokens.leaf),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.summary});

  final ChildDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final age = summary.ageYears;
    final label = age == null
        ? summary.nickname.toUpperCase()
        : '${summary.nickname.toUpperCase()} · $age';
    return Text(label, style: NestType.sectionLabel(color: tokens.ink2));
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.item, required this.payoutDay});

  final TodayItem item;
  final int payoutDay;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final tint = todayTintFor(item.iconKey, tokens);
    return NestQuestCard(
      title: item.title,
      maxLines: 2,
      onTap: () =>
          context.go('${QuestsRoutePaths.editor}?questId=${item.questId}'),
      semanticLabel:
          '${item.title}, ${item.coins} coins, ${todayStatusLabel(item.status)}',
      leading: ExcludeSemantics(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint.bg,
            borderRadius: NestRadii.allM,
          ),
          alignment: Alignment.center,
          child: NestIcon(todayIconFor(item.iconKey), color: tint.fg),
        ),
      ),
      // Order matches the HTML (coin → repeat → status); the card's Wrap
      // keeps all three on one line at 390px and moves the content-sized
      // status chip onto a second line at narrow widths (never overflows).
      metaChips: [
        NestCoinPill(amount: '${item.coins}', size: NestCoinPillSize.xSmall),
        Text(
          todayRepeatText(item.repeatRule, payoutDay),
          style: NestType.caption(color: tokens.ink2),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
        TodayStatusChip(status: item.status),
      ],
    );
  }
}

/// Hand-off button (HTML `btn-secondary` + phone glyph).
class _HandButton extends StatelessWidget {
  const _HandButton({required this.summaries});

  final List<ChildDaySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final names = summaries.map((s) => s.nickname).toList();
    final label = switch (names.length) {
      0 => 'Hand to child',
      1 => 'Hand to ${names[0]}',
      2 => 'Hand to ${names[0]} or ${names[1]}',
      _ => 'Hand to ${names[0]} and friends',
    };
    return NestButton(
      label: label,
      variant: NestButtonVariant.secondary,
      leading: const NestIcon(NestIcons.phone),
      onPressed: () => context.go(KidHomeRoutePaths.picker),
    );
  }
}

/// P08b empty state (`.empty-card` + pip-stage-1 egg).
class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return NestCard(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        NestSpacing.s8 - NestSpacing.s1,
        NestSpacing.padSide,
        NestSpacing.s8 - NestSpacing.s1,
      ),
      child: NestEmptyState(
        art: SizedBox.square(
          dimension: 140,
          child: SvgPicture.asset(NestlingIllustrations.pipStage1),
        ),
        title: 'Your nest is quiet',
        message: 'Add your first quest and Pip will start to hatch.',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: NestSpacing.s2,
          children: [
            NestButton(
              label: 'Add a quest',
              onPressed: () => context.go(QuestsRoutePaths.editor),
            ),
            NestButton(
              label: 'Browse ideas',
              variant: NestButtonVariant.ghost,
              onPressed: () => context.go(QuestsRoutePaths.library),
            ),
          ],
        ),
      ),
    );
  }
}

/// Failure body with the only legal retry (re-add [TodayLoadRequested]).
class TodayFailureBody extends StatelessWidget {
  const TodayFailureBody({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: NestSpacing.s4,
          children: [
            Text(
              message,
              style: NestType.bodySmall(color: tokens.ink2),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            NestButton(
              label: 'Try again',
              variant: NestButtonVariant.secondary,
              fullWidth: false,
              onPressed: () =>
                  context.read<TodayBloc>().add(const TodayLoadRequested()),
            ),
          ],
        ),
      ),
    );
  }
}
