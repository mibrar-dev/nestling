import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
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
///
/// The PARENT audience glyph (P08/P09/P10 HTML) via the shared single source
/// `questIconFor(key, audience: NestAudience.parent)` — kept as a thin
/// wrapper so existing callers keep compiling during the merge window.
String todayIconFor(String icon) {
  return questIconFor(icon, audience: NestAudience.parent);
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
    // Only `q-living` (unassigned, so never a Today row) uses this icon —
    // kept so the map stays total over the seed's icon keys.
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

/// `'3 quests waiting for your thumbs-up'` vs `'1 quest …'` (B4).
String todayPendingLabel(int pendingCount) {
  return pendingCount == 1
      ? '1 quest waiting for your thumbs-up'
      : '$pendingCount quests waiting for your thumbs-up';
}

/// Banner subtitle from state (B3): `'Maya and Leo did brilliantly
/// yesterday'`, `'Maya did brilliantly yesterday'`,
/// `'Maya, Leo and Sam did brilliantly yesterday'`.
String todayBannerSubtitle(List<ChildDaySummary> kids) {
  final names = kids.map((k) => k.nickname).toList();
  final who = switch (names.length) {
    0 => 'Your nestlings',
    1 => names.first,
    2 => '${names[0]} and ${names[1]}',
    _ => '${names.take(names.length - 1).join(', ')} and ${names.last}',
  };
  return '$who did brilliantly yesterday';
}

PipStyle pipStyleFor(String style) {
  switch (style) {
    case 'bolt':
      return PipStyle.bolt;
    case 'storybook':
      return PipStyle.storybook;
    default:
      return PipStyle.mochi;
  }
}

PipSkin pipSkinFor(String skin) {
  switch (skin) {
    case 'berry':
      return PipSkin.berry;
    case 'sky':
      return PipSkin.sky;
    case 'mint':
      return PipSkin.mint;
    default:
      return PipSkin.sunny;
  }
}

PipAccessory pipAccessoryFor(String accessory) {
  switch (accessory) {
    case 'bow':
      return PipAccessory.bow;
    case 'cap':
      return PipAccessory.cap;
    case 'scarf':
      return PipAccessory.scarf;
    case 'glasses':
      return PipAccessory.glasses;
    default:
      return PipAccessory.none;
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

/// Pushes [location] at most once per frame: a second tap in the same frame
/// (rapid double-tap, B12) is dropped, then the guard re-arms on the next
/// frame. Unlike a flag cleared when the push future completes, this cannot
/// latch: a pushed page that leaves via `go` (B14), or a push that throws,
/// still re-arms next frame. `go` destinations need no guard (`go`
/// replaces instead of stacking).
class _PushOnce extends StatefulWidget {
  const _PushOnce({required this.location, required this.builder});

  final String location;
  final Widget Function(BuildContext context, VoidCallback push) builder;

  @override
  State<_PushOnce> createState() => _PushOnceState();
}

class _PushOnceState extends State<_PushOnce> {
  bool _armed = true;

  void _push() {
    if (!_armed) return;
    _armed = false;
    // Re-arm next frame. By then the pushed page covers this button, so a
    // later tap cannot reach it until the user returns. Plain field writes
    // only — safe if the widget is gone by then.
    WidgetsBinding.instance.addPostFrameCallback((_) => _armed = true);
    unawaited(context.push(widget.location));
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _push);
}

/// Shared loaded body for `/today` and `/today-empty` (P08 + P08b).
class TodayLoadedBody extends StatelessWidget {
  const TodayLoadedBody({required this.state, super.key});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    // ONE shared empty state for the whole app (orchestrator ruling):
    // `/today` and `/today-empty` both land here when there is nothing
    // to do — no active quests feed OR no children at all. The populated
    // P08 path below is then unreachable, so it stays byte-identical to
    // the demo-seed design.
    if (state.items.isEmpty || state.summaries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          NestSpacing.padSide,
          0,
          NestSpacing.padSide,
          NestSpacing.s8,
        ),
        children: <Widget>[
          _EmptyGreeting(
            greeting: state.greeting,
            parentName: state.parentName,
            dateLine: state.dateLine,
          ),
          const SizedBox(height: NestSpacing.s4),
          _EmptyCard(names: state.summaries.map((s) => s.nickname).toList()),
          const SizedBox(height: NestSpacing.s4),
          const _TipCard(),
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
        ..add(
          _ApprovalsBanner(
            pendingCount: state.pendingCount,
            summaries: state.summaries,
          ),
        );
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
      // Label → first card is 8; card-to-card is the 16 base rhythm.
      for (var i = 0; i < mine.length; i++) {
        children
          ..add(SizedBox(height: i == 0 ? NestSpacing.s2 : NestSpacing.s4))
          ..add(_QuestRow(item: mine[i], payoutDay: state.payoutDay));
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
    final initial = nestAvatarInitial(parentName, fallback: 'S');
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
                    style: NestType.h2(color: tokens.ink).copyWith(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.22,
                    ),
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
              _PushOnce(
                location: QuestsRoutePaths.editor,
                builder: (context, push) => NestIconButton(
                  icon: NestIcons.plus,
                  semanticLabel: 'New quest',
                  backgroundColor: tokens.leaf,
                  foregroundColor: tokens.onLeaf,
                  borderColor: Colors.transparent,
                  onPressed: push,
                ),
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
                      onTap: () => context.go(SettingsRoutePaths.settings),
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
  const _ApprovalsBanner({required this.pendingCount, required this.summaries});

  final int pendingCount;
  final List<ChildDaySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    // liveRegion with no explicit label: the children's own text announces
    // once (an explicit label would merge with the children and repeat).
    return Semantics(
      liveRegion: true,
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
                    todayPendingLabel(pendingCount),
                    style: NestType.bodyStrong(color: tokens.leafInk),
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    todayBannerSubtitle(summaries),
                    style: NestType.caption(
                      color: tokens.leafInk.withValues(alpha: 0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _PushOnce(
              location: ApprovalsRoutePaths.approvals,
              builder: (context, push) => NestButton(
                label: 'Review',
                fullWidth: false,
                minHeight: NestDevice.tapParent,
                fontSize: 15,
                horizontalPadding: 18,
                onPressed: push,
              ),
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
    // The design's 2-up grid (170 + 170, gap 10): chunk into pairs, and give
    // a lone card its own 2-up row so it keeps the 170 column, not 350.
    final rows = <Widget>[];
    final cards = summaries.map(_KidCard.new).toList();
    for (var i = 0; i < cards.length; i += 2) {
      final pair = cards.skip(i).take(2).toList();
      rows.add(
        Row(
          spacing: NestSpacing.gap10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final card in pair) Expanded(child: card),
            if (pair.length == 1) const Spacer(),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: NestSpacing.gap10,
      children: rows,
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
                initial: nestAvatarInitial(summary.nickname),
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
                  child: PipAvatar(
                    style: pipStyleFor(summary.pipStyle),
                    stage: summary.pipStage.clamp(1, 4),
                    skin: pipSkinFor(summary.pipSkin),
                    accessory: pipAccessoryFor(summary.pipAccessory),
                    size: 72,
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
            onTap: () => context.go(QuestsRoutePaths.library),
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
    final age = summary.ageYears;
    // NestSectionLabel upper-cases internally, so pass mixed case.
    final label = age == null ? summary.nickname : '${summary.nickname} · $age';
    return NestSectionLabel(label: label);
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
    return _PushOnce(
      location: '${QuestsRoutePaths.editor}?questId=${item.questId}',
      builder: (context, push) => NestQuestCard(
        title: item.title,
        maxLines: 2,
        onTap: push,
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
      ),
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
      _ => 'Hand to ${names[0]} and ${names.length - 1} others',
    };
    return NestButton(
      label: label,
      variant: NestButtonVariant.secondary,
      leading: const NestIcon(NestIcons.phone),
      onPressed: () => context.go(KidHomeRoutePaths.picker),
    );
  }
}

/// P08b empty greeting: h1 28/34, date line beneath — no plus button, no
/// avatar (unlike the populated P08 [_Greeting]).
class _EmptyGreeting extends StatelessWidget {
  const _EmptyGreeting({
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
    // No top padding: P08b's `.greet` has none (the 8 px belongs to P08's
    // own rule). The h1 wraps over two lines instead of clipping the
    // parent's name at 320 px or 1.3× (P08b's CSS sets no nowrap).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            '$greeting, $parentName',
            style: NestType.h1(color: tokens.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: NestSpacing.gap2),
          child: Text(
            dateLine,
            style: NestType.bodySmall(color: tokens.ink2)
                .copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Second sentence naming the children, in creation order (CHILD ORDER
/// ruling: Maya, then Leo — never age, never alphabetical). The caller
/// passes `state.summaries` nicknames, which `watchSummaries` keeps in
/// `watchChildren` creation order. 0 children → no sentence; UK comma-free
/// style.
String emptyMessageSuffix(List<String> names) {
  if (names.isEmpty) return '';
  final who = switch (names.length) {
    1 => names.first,
    2 => '${names[0]} and ${names[1]}',
    _ => '${names.take(names.length - 1).join(', ')} and ${names.last}',
  };
  return ' $who will see it straight away.';
}

/// P08b empty card (`.empty-card` in the HTML source): 140 Pip stage-1
/// egg, h2 title, ink-2 message, primary CTA, sky link row.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return NestCard(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        NestSpacing.s8 - NestSpacing.s1,
        NestSpacing.padSide,
        NestSpacing.s8 - NestSpacing.s1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: NestSpacing.s2,
        children: [
          Semantics(
            image: true,
            label: 'Pip the bird as a speckled egg',
            child: const ExcludeSemantics(
              child: PipAvatar(style: PipStyle.mochi, stage: 1, size: 140),
            ),
          ),
          Text(
            'Your nest is quiet',
            style: NestType.h2(color: tokens.ink),
            textAlign: TextAlign.center,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              'Add your first quest and Pip will start to hatch.'
              '${emptyMessageSuffix(names)}',
              style: NestType.bodySmall(color: tokens.ink2),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: NestSpacing.s2),
          _PushOnce(
            location: QuestsRoutePaths.editor,
            builder: (context, push) =>
                NestButton(label: 'Add a quest', onPressed: push),
          ),
          Semantics(
            button: true,
            label: 'Browse ideas',
            excludeSemantics: true,
            onTap: () => context.go(QuestsRoutePaths.library),
            child: InkWell(
              onTap: () => context.go(QuestsRoutePaths.library),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: NestDevice.tapParent,
                ),
                child: Center(
                  child: Text(
                    'Browse ideas',
                    style: NestType.bodySmallStrong(color: tokens.sky).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: tokens.sky,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.card.inset` tip under the empty card.
class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return NestCard(
      variant: NestCardVariant.inset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tip for new nests',
            style: NestType.bodySmallStrong(color: tokens.ink),
          ),
          Text(
            'Start with two daily quests each — “Make your bed” and '
            '“Reading – 20 minutes” work beautifully.',
            style: NestType.caption(color: tokens.ink2),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Failure body with the only legal retry (re-add [TodayLoadRequested]).
///
/// Renders a fixed, kind message — the raw `errorMessage` stays in the state
/// for logs and bloc tests, never on screen (B15).
class TodayFailureBody extends StatelessWidget {
  const TodayFailureBody({super.key});

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
              "We couldn't load today's quests. Your data is safe — "
              'please try again.',
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
