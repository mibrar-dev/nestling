import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_event.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_state.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';

/// P09 · New / edit quest, presented as a full-height sheet over the
/// surface-2 backdrop (`design/html-source/screens/P09-quest-editor.html`).
///
/// `?id=<questId>` opens edit mode; without it the editor creates a quest.
/// The form draft is local state; only the save/delete attempt reaches the
/// bloc (`QuestsState.editorStatus`).
class QuestEditorView extends StatefulWidget {
  const new({super.key});

  @override
  State<QuestEditorView> createState() => _QuestEditorViewState();
}

class _QuestEditorViewState extends State<QuestEditorView> {
  Future<Quest?>? _loadedQuest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedQuest != null) {
      return;
    }
    final questId = _questIdOf(context);
    _loadedQuest = questId == null
        ? null
        : GetIt.instance<QuestsRepository>().getQuest(questId);
  }

  static String? _questIdOf(BuildContext context) {
    return GoRouterState.of(context)
        .uri
        .queryParameters[QuestsEditorQuery.questId];
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(QuestsRoutePaths.library);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final loaded = _loadedQuest;

    final Widget body;
    if (loaded == null) {
      // No `?id=`: new-quest mode, nothing to fetch.
      body = _QuestEditorSheet(initialQuest: null, onCancel: _cancel);
    } else {
      body = FutureBuilder<Quest?>(
        future: loaded,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final quest = snapshot.data;
          if (quest == null) {
            return _QuestNotFound(onBack: _cancel);
          }
          return _QuestEditorSheet(initialQuest: quest, onCancel: _cancel);
        },
      );
    }

    return Scaffold(
      backgroundColor: tokens.paper,
      body: Column(
        children: <Widget>[
          const NestStatusBar(),
          Expanded(
            child: BlocConsumer<QuestsBloc, QuestsState>(
              listenWhen: (previous, current) =>
                  previous.editorStatus != current.editorStatus ||
                  previous.editorError != current.editorError,
              listener: (context, state) {
                final error = state.editorError;
                if (state.editorStatus == QuestEditorStatus.failure &&
                    error != null) {
                  showNestToast(context, error);
                }
                if (state.editorStatus == QuestEditorStatus.saved) {
                  context.go(QuestsRoutePaths.library);
                }
              },
              builder: (context, state) {
                if (state.status == QuestsStatus.failure) {
                  return _QuestLoadFailure(
                    onRetry: () => context.read<QuestsBloc>().add(
                      const QuestsLoadRequested(),
                    ),
                  );
                }
                return body;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// `.sheet::before` — the sheet's 40x5 grabber in `--line`.
class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: NestSpacing.s10,
      height: NestSpacing.gap5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.nest.line,
          borderRadius: NestRadii.allPill,
        ),
      ),
    );
  }
}

/// `?id=` pointed at a row that is gone (deleted on another screen).
class _QuestNotFound extends StatelessWidget {
  const _QuestNotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Quest not found',
              style: NestType.h2(color: tokens.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpacing.s4),
            NestButton(
              label: 'Back to quests',
              variant: NestButtonVariant.ghost,
              fullWidth: false,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

/// The library stream the route loads failed (plan §4).
class _QuestLoadFailure extends StatelessWidget {
  const _QuestLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final state = context.read<QuestsBloc>().state;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              state.errorMessage ?? 'Something went wrong',
              style: NestType.body(color: tokens.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpacing.s4),
            NestButton(
              label: 'Try again',
              variant: NestButtonVariant.ghost,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// One assignee choice in the "Due by" sheet: the wall-clock label plus the
/// `HH:MM` stored verbatim on the quest.
typedef _DueOption = ({String label, String time});

const List<_DueOption> _dueOptions = <_DueOption>[
  (label: 'Before school (8:30am)', time: '08:30'),
  (label: 'Before tea (5pm)', time: '17:00'),
  (label: 'Before bed (7:30pm)', time: '19:30'),
];

/// P09's six `.ic` tiles, in design order. The `key` field is what
/// `quests.icon` stores; `aliases` accepts the seed's existing spellings so
/// an edited quest keeps its icon when no tile matches.
const List<({String key, List<String> aliases, String label, String icon})>
_questIcons = <({String key, List<String> aliases, String label, String icon})>[
  (key: 'bed', aliases: <String>[], label: 'Bed', icon: NestIcons.bed),
  (
    key: 'dishwasher',
    aliases: <String>[],
    label: 'Dishes',
    icon: NestIcons.dishwasher,
  ),
  (key: 'hoover', aliases: <String>[], label: 'Hoover', icon: NestIcons.hoover),
  (key: 'book', aliases: <String>[], label: 'Book', icon: NestIcons.book),
  (key: 'bin', aliases: <String>['bins'], label: 'Bins', icon: NestIcons.bin),
  (key: 'paw', aliases: <String>[], label: 'Paw', icon: NestIcons.paw),
];

const List<String> _dayLetters = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const String _defaultIcon = 'hoover';
const String _defaultTitle = 'Hoover the stairs';

/// `families.coinValuePencePerCoin` is 1 in every seed, so one coin pays one
/// penny — the helper under the stepper reads `= {n}p at payout`.
const int _pencePerCoin = 1;

/// Assignee sentinel for the "Anyone" pill (a quest stores `null`).
const String _anyone = 'anyone';

class _QuestEditorSheet extends StatefulWidget {
  const _QuestEditorSheet({required this.initialQuest, required this.onCancel});

  final Quest? initialQuest;
  final VoidCallback onCancel;

  @override
  State<_QuestEditorSheet> createState() => _QuestEditorSheetState();
}

class _QuestEditorSheetState extends State<_QuestEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.initialQuest?.title ?? _defaultTitle,
  );
  late String _icon = widget.initialQuest?.icon ?? _defaultIcon;
  late int _coins = widget.initialQuest?.coins ?? 15;
  late String _repeat = widget.initialQuest?.repeatRule ?? 'weekly';
  late final Set<int> _days = _daysFromCsv(widget.initialQuest?.days);
  late bool _needsApproval = widget.initialQuest?.needsApproval ?? true;
  late String _dueLabel = widget.initialQuest?.dueLabel ?? _dueOptions[1].label;
  late String _dueTime =
      widget.initialQuest?.dueTimeLocal ?? _dueOptions[1].time;

  /// Null until the roster arrives: a new quest then defaults to the first
  /// child in creation order (never sorted alphabetically). Edit mode always
  /// seeds explicitly, so a stored `null` (`Anyone`) is never overwritten.
  String? _assignee;

  /// Latest roster emission, so a save before the first frame still resolves
  /// the same assignee the UI shows.
  List<FamilyChild> _children = const <FamilyChild>[];

  String? get _effectiveAssignee =>
      _assignee ?? (_children.isEmpty ? null : _children.first.id);

  /// One subscription for the editor's lifetime: `watchChildren()` returns a
  /// fresh Stream per call, so building a new one inside `build` would make
  /// the `StreamBuilder` resubscribe on every rebuild.
  late final Stream<List<FamilyChild>> _childrenStream =
      GetIt.instance<FamilyRepository>().watchChildren();

  @override
  void initState() {
    super.initState();
    final quest = widget.initialQuest;
    if (quest != null) {
      _assignee = quest.assigneeChildId ?? _anyone;
    }
  }

  bool get _isEdit => widget.initialQuest != null;

  bool get _weeklyDaysMissing => _repeat == 'weekly' && _days.isEmpty;

  bool get _canSave {
    return _title.text.trim().isNotEmpty && !_weeklyDaysMissing;
  }

  static Set<int> _daysFromCsv(String? csv) {
    if (csv == null || csv.isEmpty) {
      return <int>{5};
    }
    final days = <int>{};
    for (final part in csv.split(',')) {
      final value = int.tryParse(part.trim());
      if (value != null && value >= 1 && value <= 7) {
        days.add(value - 1);
      }
    }
    return days;
  }

  static String _daysToCsv(Set<int> days) {
    final sorted = days.toList()..sort();
    return sorted.map((day) => '${day + 1}').join(',');
  }

  static String _repeatLabel(String repeatRule) {
    return switch (repeatRule) {
      'daily' => 'Daily',
      'weekly' => 'Weekly',
      _ => 'Once',
    };
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    if (!_canSave) {
      return;
    }
    final quest = Quest(
      id:
          widget.initialQuest?.id ??
          'q-${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      detail: '${_repeatLabel(_repeat)} · $_coins coins',
      icon: _icon,
      coins: _coins,
      repeatRule: _repeat,
      days: _repeat == 'weekly' ? _daysToCsv(_days) : '',
      dueLabel: _dueLabel,
      dueTimeLocal: _dueTime,
      needsApproval: _needsApproval,
      assigneeChildId: switch (_effectiveAssignee) {
        null => null,
        final String id => id == _anyone ? null : id,
      },
      active: true,
    );
    context.read<QuestsBloc>().add(
      _isEdit ? QuestsUpdateRequested(quest) : QuestsCreateRequested(quest),
    );
  }

  Future<void> _delete() async {
    final quest = widget.initialQuest;
    if (quest == null) {
      return;
    }
    final buttonContext = context;
    final confirmed = await showNestModal<bool>(
      context,
      title: 'Delete this quest?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NestButton(
            label: 'Keep it',
            variant: NestButtonVariant.secondary,
            onPressed: () => Navigator.of(buttonContext).pop(false),
          ),
          const SizedBox(height: NestSpacing.s2),
          NestButton(
            label: 'Delete',
            variant: NestButtonVariant.dangerGhost,
            onPressed: () => Navigator.of(buttonContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<QuestsBloc>().add(QuestsDeleteRequested(quest.id));
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showNestBottomSheet<String>(
      context,
      title: 'Due by',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final option in _dueOptions)
            QuestDueOptionRow(
              label: option.label,
              selected: option.label == _dueLabel,
              onTap: () => Navigator.of(context).pop(option.label),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    final option = _dueOptions.firstWhere((option) => option.label == picked);
    setState(() {
      _dueLabel = option.label;
      _dueTime = option.time;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;

    return ColoredBox(
      color: tokens.surface2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: tokens.paper,
                  borderRadius: NestRadii.topXl,
                ),
                padding: const EdgeInsets.fromLTRB(
                  NestSpacing.padSide,
                  NestSpacing.s2,
                  NestSpacing.padSide,
                  NestDevice.homeH + NestSpacing.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // `.sheet::before` — 40x5 grabber, 4px above and 12px
                    // below (the same handle NestBottomSheet draws, at the
                    // offsets P09's own CSS uses).
                    const SizedBox(height: NestSpacing.s1),
                    const Center(child: _SheetGrabber()),
                    const SizedBox(height: NestSpacing.s3),
                    _header(),
                    // `.field` → `.lbl` "Icon": the design stacks them
                    // flush (no margin between the two blocks).
                    NestTextField(
                      label: 'Quest name',
                      controller: _title,
                      onChanged: (_) => setState(() {}),
                    ),
                    const QuestEditorLabel('Icon', semanticHeader: true),
                    const SizedBox(height: NestSpacing.gap6),
                    _iconRow(),
                    const QuestEditorLabel(
                      "Who's it for?",
                      semanticHeader: true,
                    ),
                    const SizedBox(height: NestSpacing.gap6),
                    _assigneeRow(),
                    const SizedBox(height: NestSpacing.s4),
                    _rewardCard(),
                    const SizedBox(height: NestSpacing.s4),
                    _repeatsGroup(),
                    const SizedBox(height: NestSpacing.s4),
                    _approvalCard(),
                    const SizedBox(height: NestSpacing.s3),
                    _dueCard(),
                    if (_isEdit) ...<Widget>[
                      const SizedBox(height: NestSpacing.s4),
                      NestButton(
                        label: 'Delete quest',
                        variant: NestButtonVariant.dangerGhost,
                        onPressed: _delete,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(
        top: NestSpacing.s1,
        bottom: NestSpacing.s2,
      ),
      child: Row(
        children: <Widget>[
          QuestCancelButton(onPressed: widget.onCancel),
          Expanded(
            child: Semantics(
              header: true,
              child: Center(
                child: Text(
                  _isEdit ? 'Edit quest' : 'New quest',
                  style: NestType.h3(color: context.nest.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          QuestSavePill(onPressed: _canSave ? _save : null),
        ],
      ),
    );
  }

  Widget _iconRow() {
    final selected = _icon;
    final tiles = <Widget>[
      for (final option in _questIcons)
        QuestIconTile(
          key: ValueKey<String>('quest-icon-${option.key}'),
          icon: option.icon,
          label: option.label,
          selected: selected == option.key || option.aliases.contains(selected),
          onTap: () => setState(() => _icon = option.key),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = NestSpacing.s2;
        final needed =
            NestDevice.tapParent * _questIcons.length +
            gap * (_questIcons.length - 1);
        if (constraints.maxWidth >= needed) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tiles,
          );
        }
        // 320-wide surfaces cannot hold 6 tiles on one line — wrap instead
        // of overflowing (plan §5).
        return Wrap(spacing: gap, runSpacing: gap, children: tiles);
      },
    );
  }

  Widget _assigneeRow() {
    return StreamBuilder<List<FamilyChild>>(
      stream: _childrenStream,
      builder: (context, snapshot) {
        final children = snapshot.data ?? const <FamilyChild>[];
        _children = children;
        // New quests default to the first child in creation order (never
        // sorted alphabetically); with no children at all, "Anyone" wins.
        final selected =
            _assignee ?? (children.isEmpty ? _anyone : children.first.id);
        return Wrap(
          spacing: NestSpacing.s2,
          runSpacing: NestSpacing.s2,
          children: <Widget>[
            for (final child in children)
              QuestPersonPill(
                key: ValueKey<String>('quest-assignee-${child.id}'),
                label: child.nickname,
                selected: selected == child.id,
                avatarInitial: _initial(child.nickname),
                avatarColour: _avatarColour(child.avatarColour),
                onTap: () => setState(() => _assignee = child.id),
              ),
            QuestPersonPill(
              key: const ValueKey<String>('quest-assignee-anyone'),
              label: 'Anyone',
              selected: selected == _anyone,
              onTap: () => setState(() => _assignee = _anyone),
            ),
          ],
        );
      },
    );
  }

  static String _initial(String nickname) {
    return nickname.isEmpty ? '?' : nickname.substring(0, 1).toUpperCase();
  }

  static NestAvatarColor _avatarColour(String colour) {
    return switch (colour) {
      'lilac' => NestAvatarColor.lilac,
      'peach' => NestAvatarColor.peach,
      'sky' => NestAvatarColor.sky,
      'leaf' => NestAvatarColor.leaf,
      'coin' => NestAvatarColor.coin,
      _ => NestAvatarColor.neutral,
    };
  }

  Widget _rewardCard() {
    final tokens = context.nest;
    return NestCard(
      variant: NestCardVariant.inset,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Reward',
                  style: questCardTitle(tokens),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '= ${_coins * _pencePerCoin}p at payout',
                  style: NestType.caption(color: tokens.ink2),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          NestStepper(
            valueText: '$_coins',
            decreaseSemanticLabel: 'Decrease reward',
            increaseSemanticLabel: 'Increase reward',
            onDecrease: _coins > 1 ? () => setState(() => _coins -= 1) : null,
            onIncrease: _coins < 100 ? () => setState(() => _coins += 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _repeatsGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const QuestEditorLabel('Repeats', semanticHeader: true),
        const SizedBox(height: NestSpacing.gap6),
        NestSegmented<String>(
          semanticLabel: 'Repeats',
          value: _repeat,
          onChanged: (value) => setState(() => _repeat = value),
          options: const <NestSegmentOption<String>>[
            NestSegmentOption<String>(value: 'once', label: 'Once'),
            NestSegmentOption<String>(value: 'daily', label: 'Daily'),
            NestSegmentOption<String>(value: 'weekly', label: 'Weekly'),
          ],
        ),
        if (_repeat == 'weekly') ...<Widget>[
          const SizedBox(height: NestSpacing.s2),
          NestDayPicker(
            days: _dayLetters,
            selected: _days,
            semanticLabel: 'Repeat days',
            onChanged: (index) => setState(() {
              if (!_days.remove(index)) {
                _days.add(index);
              }
            }),
          ),
          if (_weeklyDaysMissing) ...<Widget>[
            const SizedBox(height: NestSpacing.gap6),
            Semantics(
              liveRegion: true,
              child: Text(
                'Pick at least one day',
                style: NestType.caption(color: context.nest.danger)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _approvalCard() {
    final tokens = context.nest;
    return NestCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Needs my approval', style: questCardTitle(tokens)),
                Text(
                  'Coins land after your thumbs-up',
                  style: NestType.caption(color: tokens.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          NestToggle(
            value: _needsApproval,
            semanticLabel: 'Needs my approval',
            onChanged: (value) => setState(() => _needsApproval = value),
          ),
        ],
      ),
    );
  }

  Widget _dueCard() {
    final tokens = context.nest;
    return NestCard(
      onTap: _pickDueTime,
      semanticLabel: 'Change due time',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: QuestEditorMetrics.dueRowMinHeight,
        ),
        child: Row(
          children: <Widget>[
            Text('Due by', style: questCardTitle(tokens)),
            const SizedBox(width: NestSpacing.s3),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '$_dueLabel ',
                  style: NestType.bodySmallStrong(color: tokens.ink),
                  children: <InlineSpan>[
                    TextSpan(
                      text: '›',
                      style: NestType.bodySmallStrong(color: tokens.ink3),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
