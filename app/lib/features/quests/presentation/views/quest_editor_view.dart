import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/data/ids.dart';
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
/// `?idea=<ideaId>` (P10's "+ Add") pre-fills that new quest from the
/// template the parent tapped. The form draft is local state; only the
/// save/delete attempt reaches the bloc (`QuestsState.editorStatus`).
class QuestEditorView extends StatefulWidget {
  const new({super.key});

  @override
  State<QuestEditorView> createState() => _QuestEditorViewState();
}

class _QuestEditorViewState extends State<QuestEditorView> {
  Future<Quest?>? _loadedQuest;

  /// `?idea=<ideaId>` (P10 Ideas → "+ Add"): the template the sheet opens
  /// pre-filled from. Null for a plain new quest (default template) and for
  /// edit mode. The template is never stored, so it is only a seed.
  Quest? _ideaSeed;

  /// Lets the sheet clear its in-flight save guard when a write fails (the
  /// bloc reports failures; the guard is local UI state).
  final GlobalKey<_QuestEditorSheetState> _sheetKey =
      GlobalKey<_QuestEditorSheetState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedQuest != null || _ideaSeeded) {
      return;
    }
    final questId = _questIdOf(context);
    if (questId != null) {
      _loadedQuest = GetIt.instance<QuestsRepository>().getQuest(questId);
      return;
    }
    // No `?id=`: new-quest mode. `?idea=` (P10's "+ Add") pre-fills the form
    // from the template row so the parent edits the idea they tapped instead
    // of the blank `Hoover the stairs` default.
    final ideaId = GoRouterState.of(context)
        .uri
        .queryParameters[QuestsEditorQuery.ideaId];
    if (ideaId != null) {
      _ideaSeed = _ideaTemplateOf(ideaId);
    }
    _ideaSeeded = true;
  }

  bool _ideaSeeded = false;

  /// The P10 template behind `?idea=`, or null when the id is unknown (a
  /// stale link then falls back to the default new-quest template instead of
  /// showing `Quest not found`, which is only for a missing *stored* quest).
  static Quest? _ideaTemplateOf(String ideaId) {
    for (final idea in GetIt.instance<QuestsRepository>().ideas()) {
      if (idea.id == ideaId) {
        return idea;
      }
    }
    return null;
  }

  /// `?id=<questId>` is the editor's own contract (`QuestsEditorQuery`).
  /// P08 Today pushes `?questId=<questId>` (`today_loaded_body.dart:700`,
  /// written before this screen existed), so that spelling is accepted as an
  /// alias: without it a tap on a quest row would open a blank NEW quest
  /// instead of editing the row. Same query contract, two accepted keys.
  static String? _questIdOf(BuildContext context) {
    final parameters = GoRouterState.of(context).uri.queryParameters;
    return parameters[QuestsEditorQuery.questId] ??
        parameters[QuestsEditorQuery.legacyQuestId];
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
      body = _QuestEditorSheet(
        key: _sheetKey,
        initialQuest: _ideaSeed,
        isEdit: false,
        onCancel: _cancel,
      );
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
          return _QuestEditorSheet(
            key: _sheetKey,
            initialQuest: quest,
            isEdit: true,
            onCancel: _cancel,
          );
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
                  // Release the sheet's in-flight save guard first: the write
                  // never left the editor, so the pill must come back.
                  _sheetKey.currentState?.clearSaveGuard();
                  showNestToast(context, error);
                }
                if (state.editorStatus == QuestEditorStatus.saved) {
                  context.go(QuestsRoutePaths.library);
                }
              },
              // The editor never reads `items`; `watchItems()` re-emits on
              // every quests-table write, so the form is not rebuilt for it.
              buildWhen: (previous, current) =>
                  previous.status != current.status,
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
      key: const ValueKey<String>('quest-editor-grabber'),
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
/// `quests.icon` stores; `aliases` are the other spellings the family's own
/// rows use, so editing a quest whose stored icon has no dedicated tile still
/// shows ONE selected tile instead of an empty radiogroup (BUG-P09-3 /
/// review finding 10). Every alias maps to the tile the seeded quest is
/// visually about, so the parent sees the right glyph:
/// `plate` → Dishes (tableware), `shirt`/`bag` → Bins (things to carry away),
/// `leaf` → Paw (growing things), `sofa` → Bed (the other tidy-the-room
/// furniture). An alias only decides which tile is *highlighted*: the stored
/// key is preserved unless the parent taps a tile.
const List<({String key, List<String> aliases, String label, String icon})>
_questIcons = <({String key, List<String> aliases, String label, String icon})>[
  // `key` is what `quests.icon` stores and the alias table resolves — it never
  // changes. The four tiles draw the exact design paths `shared_batch5` added
  // (ORCHESTRATOR_NOTES 20:09 / BUG-P09-12); `book`/`paw` were already
  // byte-identical and stay.
  (
    key: 'bed',
    aliases: <String>['sofa'],
    label: 'Bed',
    icon: NestIcons.questBed,
  ),
  (
    key: 'dishwasher',
    aliases: <String>['plate'],
    label: 'Dishes',
    icon: NestIcons.questDishes,
  ),
  (
    key: 'hoover',
    aliases: <String>[],
    label: 'Hoover',
    icon: NestIcons.questHoover,
  ),
  (key: 'book', aliases: <String>[], label: 'Book', icon: NestIcons.book),
  (
    key: 'bin',
    aliases: <String>['bins', 'shirt', 'bag'],
    label: 'Bins',
    icon: NestIcons.questBins,
  ),
  (key: 'paw', aliases: <String>['leaf'], label: 'Paw', icon: NestIcons.paw),
];

const List<String> _dayLetters = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const String _defaultIcon = 'hoover';
const String _defaultTitle = 'Hoover the stairs';

/// The editor's coin range (plan §1-5). The repository enforces the same
/// bounds on write (`QuestsRepositoryImpl._checkCoins`), so these are the two
/// numbers the stepper, the helper and the save path all agree on.
const int _minCoins = 1;
const int _maxCoins = 100;

/// Assignee sentinel for the "Anyone" pill (a quest stores `null`).
const String _anyone = 'anyone';

class _QuestEditorSheet extends StatefulWidget {
  const _QuestEditorSheet({
    required this.initialQuest,
    required this.isEdit,
    required this.onCancel,
    super.key,
  });

  /// The row being edited (`?id=`) or the P10 template seeded into a new quest
  /// (`?idea=`). Null = the default new-quest template.
  final Quest? initialQuest;

  /// True only for `?id=` edit mode. A `?idea=` seed is still a CREATE — the
  /// template is not a stored row — so the mode cannot be inferred from
  /// [initialQuest] alone (review finding 2).
  final bool isEdit;

  final VoidCallback onCancel;

  @override
  State<_QuestEditorSheet> createState() => _QuestEditorSheetState();
}

class _QuestEditorSheetState extends State<_QuestEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.initialQuest?.title ?? _defaultTitle,
  );
  late String _icon = widget.initialQuest?.icon ?? _defaultIcon;

  /// The stored coin count is shown as stored (BUG-P09-4): a value outside
  /// 1..100 must never be silently rewritten just by opening the editor, and
  /// the stepper stays able to reach every value between here and the stored
  /// one. The bounds grow to include whatever the row holds, so nothing the
  /// parent can see becomes unreachable; `_save` still hands the repository
  /// an in-range number.
  late final int _storedCoins = widget.initialQuest?.coins ?? 15;

  /// The stepper's own bounds: the design's 1..100 widened to include the
  /// value the row actually holds (BUG-P09-4). A stored value outside the
  /// design range is therefore shown as stored — opening the editor never
  /// silently rewrites it — and every value between it and the design range
  /// stays reachable; `_save` still hands the repository an in-range number.
  late final int _coinFloor = _storedCoins < _minCoins
      ? _storedCoins
      : _minCoins;
  late final int _coinCeiling = _storedCoins > _maxCoins
      ? _storedCoins
      : _maxCoins;

  late int _coins = _storedCoins;
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

  /// The family roster, in creation order. Held in a field updated from ONE
  /// stream subscription (review finding 11) instead of being written during
  /// a `StreamBuilder` build, so the value a save resolves is the value the
  /// pills are painted from.
  List<FamilyChild> _children = const <FamilyChild>[];
  bool _rosterLoaded = false;

  /// `families.coinValuePencePerCoin` — the reward helper reads it from the
  /// database, never from the design (BUG-P09-1 / review finding 4). One
  /// coin pays this many pence at payout.
  int _pencePerCoin = 1;

  /// In-flight save guard (BUG-P09-2): a double tap must not dispatch a
  /// second create, and the pill is disabled while the write is out.
  bool _saving = false;

  StreamSubscription<List<FamilyChild>>? _childrenSubscription;
  StreamSubscription<int>? _coinValueSubscription;

  String? get _effectiveAssignee {
    final assignee = _assignee;
    if (assignee != null && !_isKnownAssignee(assignee)) {
      // The row points at a child who is gone (removed on another screen):
      // fall back to "Anyone" so no pill is empty and Save clears the orphan
      // id instead of writing a dangling foreign key (BUG-P09-5).
      return _anyone;
    }
    return assignee ?? (_children.isEmpty ? null : _children.first.id);
  }

  /// True when [id] is `Anyone` or a child the roster still lists.
  bool _isKnownAssignee(String id) {
    return id == _anyone ||
        _children.any((child) => child.id == id) ||
        // Before the roster arrives nothing is disproved yet.
        !_rosterLoaded;
  }

  @override
  void initState() {
    super.initState();
    final quest = widget.initialQuest;
    if (quest != null) {
      _assignee = quest.assigneeChildId ?? _anyone;
    }
    final repository = GetIt.instance<QuestsRepository>();
    _childrenSubscription = GetIt.instance<FamilyRepository>()
        .watchChildren()
        .listen(
          (children) {
            if (!mounted ||
                (_rosterLoaded && listEquals(children, _children))) {
              // Only a REAL roster change rebuilds the form — `watchChildren`
              // re-emits on every `children` write anywhere (review finding 5).
              return;
            }
            setState(() {
              _children = children;
              _rosterLoaded = true;
            });
          },
          // A stream error must not become an unhandled async error: keep the
          // last known roster (or the `Anyone`-only default) and carry on.
          onError: (_) {},
        );
    _coinValueSubscription = repository.watchCoinValuePencePerCoin().listen((
      pence,
    ) {
      if (!mounted || pence == _pencePerCoin) {
        return;
      }
      setState(() => _pencePerCoin = pence);
    }, onError: (_) {});
  }

  bool get _isEdit => widget.isEdit;

  bool get _weeklyDaysMissing => _repeat == 'weekly' && _days.isEmpty;

  /// A stored row can hold a coin count outside the repository's 1..100
  /// contract. The editor deliberately SHOWS it as stored (BUG-P09-4: opening
  /// never silently rewrites a row) and the stepper can walk it back into
  /// range, but Save used to clamp it silently — the screen promised one
  /// number and stored another (9999 shown, 100 written; 0 shown, 1 written).
  /// So an out-of-range value now BLOCKS the save with a visible reason, the
  /// same live-region pattern as `Pick at least one day` (BUG-P09-6).
  bool get _coinsOutOfRange => _coins < _minCoins || _coins > _maxCoins;

  bool get _canSave {
    return _title.text.trim().isNotEmpty &&
        !_weeklyDaysMissing &&
        !_coinsOutOfRange;
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

  @override
  void dispose() {
    unawaited(_childrenSubscription?.cancel());
    unawaited(_coinValueSubscription?.cancel());
    _title.dispose();
    super.dispose();
  }

  /// Called by the route when a write fails, so the pill becomes live again
  /// and the parent can retry (the write never left the editor).
  void clearSaveGuard() {
    if (mounted && _saving) {
      setState(() => _saving = false);
    }
  }

  void _save() {
    // One write per gesture (BUG-P09-2): the pill is disabled while saving,
    // and this guard is what makes a second tap before the router frame a
    // no-op even if it lands on an enabled frame.
    if (!_canSave || _saving) {
      return;
    }
    setState(() => _saving = true);
    final quest = Quest(
      // A `?idea=` seed is a CREATE, so the new row gets a fresh id — the
      // template's id (`idea-bed`) must never be written (review finding 2).
      // Minted with `newId` (uuid), never from the clock (IDS rule,
      // ORCHESTRATOR_NOTES 09:27): a millisecond stamp collides whenever two
      // creates land in the same millisecond — always, under the pinned test
      // clock — and the duplicate primary key left the editor open with a raw
      // SQL error toast instead of a second quest (BUG-P09-14).
      id: _isEdit ? widget.initialQuest!.id : newId('q'),
      title: _title.text.trim(),
      // `Quest.detail` is not a column — the repository recomputes
      // `'{repeat} · {coins} coins'` on every read — so the view carries no
      // copy of its own (review finding 5).
      detail: widget.initialQuest?.detail ?? '',
      icon: _icon,
      // Shown as stored, written inside the repository's 1..100 contract —
      // `_canSave` blocks the write outright while the value is out of range
      // (BUG-P09-4 shown-honestly, BUG-P09-6 no-silent-clamp), so the clamp is
      // now unreachable from the editor and only a belt-and-braces guard.
      coins: _coins.clamp(_minCoins, _maxCoins),
      repeatRule: _repeat,
      days: _repeat == 'weekly' ? _daysToCsv(_days) : '',
      dueLabel: _dueLabel,
      dueTimeLocal: _dueTime,
      needsApproval: _needsApproval,
      assigneeChildId: switch (_effectiveAssignee) {
        null => null,
        final String id => id == _anyone ? null : id,
      },
      // Editing a quest must not resurrect an archived one (review finding 9).
      // A new quest is always stored active — including a `?idea=` create,
      // whose template carries `active: false` (templates are not rows).
      active: _isEdit && widget.initialQuest!.active,
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
                // Keyed so the bottom-edge owner rule is testable: the paper
                // sheet must run to the physical bottom of the screen, never
                // leaving a `--surface-2` strip under it.
                key: const ValueKey<String>('quest-editor-sheet'),
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
                    NestTextField(label: 'Quest name', controller: _title),
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
                    if (_coinsOutOfRange) ...<Widget>[
                      const SizedBox(height: NestSpacing.gap6),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          // Screen-local validation caption, same pattern (and
                          // same wording shape) as `Pick at least one day`.
                          'Coins must be 1–100',
                          style: NestType.caption(color: tokens.danger)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
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
          // Integration (P09+P10 merge): the sheet design offers no AppBar, so
          // `Cancel` is the only way back from a pushed editor — and the only
          // element on screen a system back resolves to. No `Tooltip` wraps
          // it: a `Back` tooltip in product code existed only so
          // `WidgetTester.pageBack()` (which resolves by tooltip) could find
          // it, and it would collide with any future library back button
          // (review finding 3). The back tests use
          // `tester.binding.handlePopRoute()`, the idiom `today_view_test`
          // and `p08_bugs_test` already use.
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
          // `_canSave` reads the title's text, so only the pill needs to
          // rebuild as it changes — the six tiles, three person pills, two
          // LayoutBuilders, three cards, the segmented control and the seven
          // day cells no longer rebuild per keystroke (review finding 4).
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _title,
            builder: (context, value, _) =>
                QuestSavePill(onPressed: _canSave && !_saving ? _save : null),
          ),
        ],
      ),
    );
  }

  Widget _iconRow() {
    final selected = _icon;
    final tiles = <Widget>[
      for (final option in _questIcons)
        Builder(
          builder: (context) {
            // A tile that is ALREADY the visual selection (directly or through
            // an alias) is a radio that is already checked, so it is inert
            // (BUG-P09-7): tapping `plate`'s Dishes tile used to look like a
            // no-op while silently rewriting the stored key to `dishwasher`.
            final isSelected =
                selected == option.key || option.aliases.contains(selected);
            return QuestIconTile(
              key: ValueKey<String>('quest-icon-${option.key}'),
              icon: option.icon,
              label: option.label,
              selected: isSelected,
              onTap: () {
                if (isSelected) {
                  return;
                }
                setState(() => _icon = option.key);
              },
            );
          },
        ),
    ];

    return Semantics(
      // `.icons role="radiogroup" aria-label="Quest icon"` — one announced
      // group around the six tiles; the tiles keep their own nodes.
      container: true,
      label: 'Quest icon',
      child: LayoutBuilder(
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
      ),
    );
  }

  Widget _assigneeRow() {
    // One subscription in `initState` owns the roster (review finding 11), so
    // the pills are painted from the same value a save resolves.
    final children = _children;
    // New quests default to the first child in creation order (never sorted
    // alphabetically); with no children at all, "Anyone" wins, and so does a
    // stored assignee the roster no longer lists (BUG-P09-5).
    final selected = _effectiveAssignee ?? _anyone;
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
  }

  /// The first grapheme, not the first UTF-16 code unit (BUG-P09-8,
  /// K02-BUG-1). Delegates to the shared helper so an emoji-leading
  /// nickname (`😀 Sam`, which P05 accepts) never fails to draw.
  static String _initial(String nickname) {
    return nestAvatarInitial(nickname);
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
                  // One coin pays the family's own rate — the number comes from
                  // `families.coinValuePencePerCoin`, never from the design.
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
            onDecrease: _coins > _coinFloor
                ? () => setState(() {
                    // A corrupt, out-of-vocabulary stored value (9999, 0) blocks
                    // Save (BUG-P09-6), so the first tap in the direction of the
                    // valid band jumps straight to its boundary instead of one
                    // coin (BUG-P09-11). One tap per repair, not 99 or 9899.
                    if (_coins > _maxCoins) {
                      _coins = _maxCoins;
                    } else {
                      _coins -= 1;
                    }
                  })
                : null,
            onIncrease: _coins < _coinCeiling
                ? () => setState(() {
                    if (_coins < _minCoins) {
                      _coins = _minCoins;
                    } else {
                      _coins += 1;
                    }
                  })
                : null,
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
          // `.dayrow` → `.day { height: 44px; border: 1.5px }` is a
          // border-box: the hairline sits INSIDE the 44. `NestDayPicker`
          // paints that hairline with `Ink`, which insets its child by the
          // border and so measures 47 for an unselected cell. Capping the
          // row at the design's 44 keeps the cells, their borders and their
          // 44 tap targets where the PNG has them without touching the
          // shared component.
          SizedBox(
            height: NestDevice.tapParent,
            child: NestDayPicker(
              days: _dayLetters,
              selected: _days,
              semanticLabel: 'Repeat days',
              onChanged: (index) => setState(() {
                if (!_days.remove(index)) {
                  _days.add(index);
                }
              }),
            ),
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
    // The failing layout in iteration 2 was: row 40-high inside card padding
    // `s4/s3` (renders 72, slot offset 4.5) with a shifted toggle. Batch 5
    // changed the toggle's laid-out box to the 51x31 track, which made the
    // adjustments `toggleTrackOffset` and the `s3` padding double-count and
    // broke both the card's height (68) and the track rect (307/618.5).
    return NestCard(
      // Padding is done inside, so the Stack below covers the whole card
      // (including the padding) and the toggle's hit overhang — the
      // `_ToggleHitSlop` zone that overhangs the 51x31 track — is not
      // blocked by the row's own 40-high bounds (BUG-P09-10). Before, taps
      // 5 px above/below the track and 2 px right of it hit nothing.
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(NestSpacing.s4),
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
                // The slot the toggle occupies visually; the widget itself is
                // the [Positioned] sibling below, which is how its full 59x44
                // tap area escapes the row's 40-high hit test (BUG-P09-10).
                const SizedBox(width: QuestEditorMetrics.approvalTrackWidth),
              ],
            ),
          ),
          // The track is the toggle's own laid-out box, centred the way
          // `.switchrow { align-items: center }` centres it. The old
          // `Positioned(top: 20.5)` measured ONE frame — the design's centred
          // 72-high card — so the track rode 20/29/43.5 px high as soon as the
          // sub-line wrapped (320 dp, text scale 1.3) (P09-TEST-9). The
          // full-card `LayoutBuilder` turns the card's own height into the
          // top offset, so the switch is centred BY LAYOUT at every metric:
          // (72 − 31) / 2 = 20.5 card-local → 620.5 globally, the design rect.
          //
          // The toggle stays a DIRECT loose-slot child of a Stack that covers
          // the whole slop, because `RenderBox.hitTest` rejects any position
          // outside a box's own size: every box between here and the track
          // must contain the 59×44 `.toggle::before` area (4 px past the track
          // on each side) or those taps are silently eaten (BUG-P09-10).
          // Measured while fixing it: a tight `Positioned.fill` + `Padding`
          // region lost the 2 px-right tap, a tight vertical inset lost both
          // 5 px taps, and a `SizedBox` cannot reserve the inset at all
          // because it sizes to its child (the track landed flush to the card
          // edge at 319→370).
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    top:
                        (constraints.maxHeight -
                            QuestEditorMetrics.approvalTrackHeight) /
                        2,
                    right: NestSpacing.s4,
                    child: NestToggle(
                      value: _needsApproval,
                      semanticLabel: 'Needs my approval',
                      onChanged: (value) =>
                          setState(() => _needsApproval = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dueCard() {
    final tokens = context.nest;
    return NestCard(
      onTap: _pickDueTime,
      // The value is part of the label: `NestCard` sets
      // `excludeSemantics: semanticLabel != null`, so a bare "Change due time"
      // label DROPPED the row's own text and VoiceOver never announced the
      // current choice (review finding 6). The sheet still announces each
      // option's own label.
      semanticLabel: 'Due by, $_dueLabel',
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
