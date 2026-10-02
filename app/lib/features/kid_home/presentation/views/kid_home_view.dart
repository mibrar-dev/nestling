import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as nest_assets;
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_status_chip.dart';
import 'package:nestling/features/kid_jar/kid_jar_routes.dart';
import 'package:nestling/features/kid_shop/kid_shop_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';
import 'package:nestling/features/pip/pip_routes.dart';

NestAvatarColor _avatarColor(String raw) {
  return switch (raw) {
    'lilac' => NestAvatarColor.lilac,
    'peach' => NestAvatarColor.peach,
    'sky' => NestAvatarColor.sky,
    'leaf' => NestAvatarColor.leaf,
    'coin' => NestAvatarColor.coin,
    _ => NestAvatarColor.neutral,
  };
}

PipStage _pipStage(int raw) {
  return switch (raw) {
    1 => PipStage.egg,
    2 => PipStage.hatchling,
    4 => PipStage.songbird,
    _ => PipStage.fledgling,
  };
}

/// Icon tile glyph per `KidQuest.icon` (K03 glyph per `nestling_assets.dart`).
String _iconFor(String raw) {
  return switch (raw) {
    'dishwasher' => NestIcons.dishwasher,
    'book' => NestIcons.book,
    'bed' => NestIcons.bedSit,
    'bins' => NestIcons.bin,
    'hoover' => NestIcons.hoover,
    'plate' => NestIcons.table,
    'table' => NestIcons.table,
    _ => NestIcons.questCard,
  };
}

bool _isDone(KidQuest item) =>
    item.status == 'approved' || item.status == 'done_pending';

/// Card-level status text for the `{title}, {status text}` semantics label.
String _statusText(KidQuest item) {
  return switch (item.status) {
    'done_pending' => 'Waiting for Mum\u2019s thumbs-up',
    'approved' => 'Done',
    _ => 'To do',
  };
}

/// K03 Kid home (`/kid-home`): greeting header, Pip stage, happiness hearts,
/// today's quests with live counts, and the Pip/Shop/My jar dock.
class KidHomeView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<KidHomeBloc, KidHomeState>(
      listenWhen: (previous, current) =>
          previous.actionError != current.actionError &&
          current.actionError != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hmm, that did not work. Try again.')),
        );
      },
      child: BlocBuilder<KidHomeBloc, KidHomeState>(
        builder: (context, state) {
          switch (state.status) {
            case KidHomeStatus.initial:
            case KidHomeStatus.loading:
              return const _KidLoading();
            case KidHomeStatus.failure:
              return const _KidFailure();
            case KidHomeStatus.loaded:
              final child = state.child;
              if (child == null) {
                return const _NoActiveChild();
              }
              return _KidHomeBody(child: child, state: state);
          }
        },
      ),
    );
  }
}

class _KidLoading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Loading your quests',
                  child: CircularProgressIndicator(color: tokens.leaf),
                ),
              ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _KidFailure extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NestSpacing.padSide,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: NestSpacing.s2,
                    children: [
                      SvgPicture.asset(
                        nest_assets.NestlingIllustrations.pipStage1,
                        width: 140,
                        height: 140,
                        placeholderBuilder: (_) => const SizedBox.shrink(),
                      ),
                      Text(
                        'Oh no! Pip got lost.',
                        style: NestType.h2(color: tokens.ink),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Let\u2019s try again.',
                        style: NestType.bodySmall(color: tokens.ink2),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: NestSpacing.s1),
                      NestKidButton(
                        label: 'Try again',
                        color: NestKidButtonColor.white,
                        fullWidth: false,
                        onPressed: () => context.read<KidHomeBloc>().add(
                          const KidHomeLoadRequested(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _NoActiveChild extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: NestSpacing.s3,
                  children: [
                    Text(
                      'Who\u2019s playing?',
                      style: NestType.h2(color: tokens.ink),
                      textAlign: TextAlign.center,
                    ),
                    NestKidButton(
                      label: 'Choose',
                      color: NestKidButtonColor.lilac,
                      fullWidth: false,
                      onPressed: () => context.go(KidHomeRoutePaths.picker),
                    ),
                  ],
                ),
              ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _KidHomeBody extends StatelessWidget {
  const new({required this.child, required this.state});

  final KidChild child;
  final KidHomeState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final nickname = child.nickname;
    final initial = nickname.isEmpty ? '?' : nickname[0].toUpperCase();
    final done = state.doneCount;
    final total = state.totalCount;
    final filledHearts = child.happiness.clamp(0, 5);
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                NestSpacing.s1,
                NestSpacing.padSide,
                NestSpacing.gap10,
              ),
              child: Row(
                spacing: NestSpacing.s2,
                children: [
                  NestAvatar(
                    initial: initial,
                    size: NestAvatarSize.s64,
                    color: _avatarColor(child.avatarColour),
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Hi $nickname, $done done today',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hi $nickname!',
                            // Screen-exact `.k3-name`: Nunito 22/26 w900 ink.
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              height: 26 / 22,
                              fontWeight: FontWeight.w900,
                              color: tokens.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$done done today',
                            // Screen-exact `.k3-sub`: Nunito 15/20 w700 ink2.
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              height: 20 / 15,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  NestCoinPill(amount: '${child.coins}'),
                  NestLockButton(
                    semanticLabel: 'Grown-ups',
                    onPressed: () => context.push(ParentalGateRoutePaths.gate),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.items.isEmpty
                  ? const _KidEmptyQuests()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        NestSpacing.padSide,
                        0,
                        NestSpacing.padSide,
                        NestSpacing.s8,
                      ),
                      children: [
                        NestPetStage(
                          stage: _pipStage(child.pipStage),
                          speech: 'Let\u2019s do some quests!',
                        ),
                        const SizedBox(height: NestSpacing.s4),
                        Semantics(
                          image: true,
                          label:
                              'Pip is happy today, $filledHearts of 5 hearts',
                          excludeSemantics: true,
                          child: Row(
                            spacing: NestSpacing.s2,
                            children: [
                              for (var i = 0; i < 5; i++)
                                if (i < filledHearts)
                                  NestIcon(
                                    NestIcons.heart,
                                    size: 26,
                                    color: tokens.coin,
                                  )
                                else
                                  NestIcon(
                                    NestIcons.heartOutline,
                                    size: 26,
                                    color: tokens.ink3,
                                  ),
                              Flexible(
                                child: Text(
                                  'Pip is happy today',
                                  // Screen-exact `.kcap`: Nunito 15/20 w700.
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    height: 20 / 15,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NestSpacing.s4),
                        Row(
                          spacing: NestSpacing.gap10,
                          children: [
                            Expanded(
                              child: Text(
                                'Today\u2019s quests',
                                style: NestType.kidTitle(color: tokens.ink),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            KidStatusChip(label: '$done of $total done'),
                          ],
                        ),
                        const SizedBox(height: NestSpacing.s4),
                        NestProgress(
                          fraction: state.fraction,
                          kid: true,
                          semanticLabel:
                              '$done of $total of today\u2019s quests done',
                        ),
                        const SizedBox(height: NestSpacing.s4),
                        Column(
                          spacing: NestSpacing.s3,
                          children: [
                            for (final item in state.items)
                              _QuestCard(child: child, item: item),
                          ],
                        ),
                      ],
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(top: BorderSide(color: tokens.ink, width: 3)),
              ),
              padding: const EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                NestSpacing.s3,
                NestSpacing.padSide,
                NestSpacing.gap10,
              ),
              child: Row(
                spacing: NestSpacing.s3,
                children: [
                  Expanded(
                    child: NestKidButton(
                      label: 'Pip',
                      color: NestKidButtonColor.lilac,
                      icon: const NestIcon(NestIcons.pipFace),
                      axis: Axis.vertical,
                      gap: NestSpacing.s1,
                      minHeight: 66,
                      fontSize: 17,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: NestSpacing.gap6,
                      ),
                      onPressed: () => context.go(PipRoutePaths.nest),
                    ),
                  ),
                  Expanded(
                    child: NestKidButton(
                      label: 'Shop',
                      color: NestKidButtonColor.coin,
                      icon: const NestIcon(NestIcons.bag),
                      axis: Axis.vertical,
                      gap: NestSpacing.s1,
                      minHeight: 66,
                      fontSize: 17,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: NestSpacing.gap6,
                      ),
                      onPressed: () => context.go(KidShopRoutePaths.shop),
                    ),
                  ),
                  Expanded(
                    child: NestKidButton(
                      label: 'My jar',
                      icon: const NestIcon(NestIcons.jar),
                      axis: Axis.vertical,
                      gap: NestSpacing.s1,
                      minHeight: 66,
                      fontSize: 17,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: NestSpacing.gap6,
                      ),
                      onPressed: () => context.go(KidJarRoutePaths.jar),
                    ),
                  ),
                ],
              ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const new({required this.child, required this.item});

  final KidChild child;
  final KidQuest item;

  void _complete(BuildContext context) {
    context.read<KidHomeBloc>().add(
      KidHomeQuestCompleted(
        childId: child.id,
        questId: item.questId,
        coins: item.coins,
      ),
    );
    unawaited(
      context.push(
        KidHomeRoutePaths.complete,
        extra: <String, Object>{
          'questId': item.questId,
          'childId': child.id,
          'coins': item.coins,
        },
      ),
    );
  }

  void _openDetail(BuildContext context) {
    unawaited(
      context.push(
        KidHomeRoutePaths.detail,
        extra: <String, Object>{'questId': item.questId, 'childId': child.id},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final done = _isDone(item);
    return NestKidQuestCard(
      title: item.title,
      icon: NestIcon(_iconFor(item.icon), size: 28, color: tokens.ink),
      coinAmount: done ? null : '+${item.coins}',
      metaChip: done
          ? KidStatusChip(
              label: item.status == 'done_pending' ? 'Waiting for Mum' : 'Done',
            )
          : null,
      done: done,
      // Pending/approved checks are display-only; only `to_do` taps complete.
      onToggled: done ? null : (_) => _complete(context),
      onTap: () => _openDetail(context),
      semanticLabel: '${item.title}, ${_statusText(item)}',
    );
  }
}

class _KidEmptyQuests extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s8,
      ),
      children: [
        NestEmptyState(
          art: SvgPicture.asset(
            nest_assets.NestlingIllustrations.pipStage1,
            width: 160,
            height: 160,
            placeholderBuilder: (_) => const SizedBox.shrink(),
          ),
          title: 'No quests today',
          message: 'Enjoy playing with Pip!',
        ),
      ],
    );
  }
}
