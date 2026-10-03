import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_category_chips.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_row.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_push_once.dart';
import 'package:nestling/features/quests/quests_routes.dart';

enum QuestLibraryTab { active, ideas }

/// P10 · Quest library scroll body.
///
/// Filter state (tab, search query, category) is local, NOT bloc state —
/// every keystroke would otherwise spam the bloc (plan §b).
class QuestLibraryBody extends StatefulWidget {
  const QuestLibraryBody({
    required this.items,
    required this.ideas,
    super.key,
    this.initialTab = QuestLibraryTab.ideas,
  });

  /// Active quests, in repository order (child order is insertion order).
  final List<Quest> items;

  /// The 10 static idea templates from `QuestsRepository.ideas()`.
  final List<Quest> ideas;

  final QuestLibraryTab initialTab;

  @override
  State<QuestLibraryBody> createState() => _QuestLibraryBodyState();
}

class _QuestLibraryBodyState extends State<QuestLibraryBody> {
  late QuestLibraryTab _tab = widget.initialTab;
  String _query = '';
  String _category = kAllQuestCategories;

  @override
  void didUpdateWidget(covariant QuestLibraryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `late final`-style caching would freeze the first value, so a parent
    // that changes `initialTab` would be ignored.
    if (oldWidget.initialTab != widget.initialTab) {
      _tab = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    // `.chipscroll { margin: 0 -20px }` cancels `.scroll > * + *`, so the
    // filter row sits flush under the search field (no 16 px gap) and carries
    // its own 20 px edge padding. Search + chips belong to the Ideas tab
    // only; the Active board has nothing to filter.
    final filtersOn = _tab == QuestLibraryTab.ideas;

    // Every push site on this screen (BUG-P10-1) goes through the per-frame
    // guard: two taps landing before the next frame would otherwise stack two
    // `/quest-editor` routes.
    return QuestPushOnce(
      builder: (context, push) => _buildList(context, tokens, filtersOn, push),
    );
  }

  /// The scroll body. [filtersOn] is false on the Active tab, which lists
  /// the whole family board and owns neither a search nor a category
  /// (BUG-P10-3: controls that filter nothing must not be rendered).
  Widget _buildList(
    BuildContext context,
    NestTokens tokens,
    bool filtersOn,
    void Function(String) pushTo,
  ) {
    final visibleIdeas = filtersOn
        ? filterQuestIdeas(widget.ideas, query: _query, category: _category)
        : widget.ideas;

    return ListView(
      // `.scroll { padding: 0 20px 32px }` — the side gutter lives on each
      // child ([_gutter]) rather than on the viewport, so the category row
      // can bleed to the screen edges (`.chipscroll { margin: 0 -20px }`).
      // Nothing is added below the content: the ParentShell tab bar runs to
      // the physical edge.
      padding: const EdgeInsets.only(bottom: NestSpacing.s8),
      children: <Widget>[
        // `.ptitle { padding-top: 8px }`.
        _gutter(const SizedBox(height: NestSpacing.s2)),
        _gutter(
          // `.ptitle` has no `text-wrap: balance`, so this is a plain Text —
          // the BALANCED HEADINGS rule does not reach a screen-local heading
          // that sets no balance.
          Text('Quests', style: NestType.h1(color: tokens.ink), maxLines: 1),
        ),
        _gutter(const SizedBox(height: NestSpacing.s4)),
        _gutter(
          NestSegmented<String>(
            semanticLabel: 'Quest lists',
            value: filtersOn ? 'ideas' : 'active',
            onChanged: (value) => setState(
              () => _tab = value == 'active'
                  ? QuestLibraryTab.active
                  : QuestLibraryTab.ideas,
            ),
            options: <NestSegmentOption<String>>[
              NestSegmentOption<String>(
                value: 'active',
                // DATA OVER MOCKS: the count comes from the seeded stream, so
                // it can never drift from the database.
                label: 'Active (${widget.items.length})',
              ),
              const NestSegmentOption<String>(value: 'ideas', label: 'Ideas'),
            ],
          ),
        ),
        if (filtersOn) ...<Widget>[
          _gutter(const SizedBox(height: NestSpacing.s4)),
          _gutter(
            // `.search { min-height:52px; padding:4px 16px; gap:10px }` with a
            // 24 px icon: the shared search slot puts the glyph at field x+16
            // and the hint at x+50 (Material's `prefixIcon` slot cannot).
            NestTextField.search(
              hintText: 'Search ideas',
              semanticLabel: 'Search quest ideas',
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          QuestCategoryChips(
            categories: kQuestCategories,
            selected: _category,
            onSelected: (value) => setState(() => _category = value),
          ),
          _gutter(const SizedBox(height: NestSpacing.s4)),
        ],
        ..._rows(visibleIdeas, activeTab: !filtersOn, pushTo: pushTo),
      ],
    );
  }

  /// `.scroll`'s 20 px side gutter, applied per child (Flutter forbids
  /// negative padding, so the bleed row cannot cancel a viewport gutter).
  static Widget _gutter(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
    child: child,
  );

  List<Widget> _rows(
    List<Quest> visibleIdeas, {
    required bool activeTab,
    required void Function(String) pushTo,
  }) {
    // `.scroll > * + *` puts a 16 px gap BETWEEN rows and none after the last
    // one; the end-of-list space is the viewport's own 32 px bottom padding
    // (BUG-P10-4 measured 48 while every row carried a trailing gap).
    if (activeTab) {
      if (widget.items.isEmpty) {
        return const <Widget>[
          NestEmptyState(
            title: 'No active quests',
            message: 'Add one from Ideas.',
          ),
        ];
      }
      return _separated(<Widget>[
        for (final Quest quest in widget.items)
          _gutter(
            QuestIdeaRow(
              key: ValueKey<String>('quest-active-${quest.id}'),
              title: quest.title,
              meta: quest.detail,
              iconAsset: questIconAsset(quest.icon),
              tint: questTileTintFor(quest.icon),
              // TODO(P10): P09 does not read a `?id=` query param yet, so
              // the editor opens blank. Same feature, no shared change.
              onTap: () => pushTo(QuestsRoutePaths.editor),
            ),
          ),
      ]);
    }

    if (visibleIdeas.isEmpty) {
      return <Widget>[
        _gutter(
          const NestEmptyState(
            title: 'No ideas found',
            message: 'Try a different search or category.',
          ),
        ),
      ];
    }

    return _separated(<Widget>[
      for (final Quest idea in visibleIdeas) _gutter(_ideaRow(idea, pushTo)),
    ]);
  }

  /// `.scroll > * + *` — a 16 px gap between children, never after the last.
  static List<Widget> _separated(List<Widget> rows) => <Widget>[
    for (var i = 0; i < rows.length; i++) ...<Widget>[
      rows[i],
      if (i < rows.length - 1) const SizedBox(height: NestSpacing.s4),
    ],
  ];

  Widget _ideaRow(Quest idea, void Function(String) pushTo) {
    final meta = questIdeaMetaFor(idea.id);
    return QuestIdeaRow(
      key: ValueKey<String>('quest-idea-${idea.id}'),
      title: idea.title,
      meta: meta?.metaFor(idea.coins) ?? idea.detail,
      iconAsset: meta?.iconAsset ?? NestIcons.questCard,
      tint: meta?.tint ?? NestTileTint.neutral,
      addSemanticLabel: 'Add ${idea.title}',
      onAdd: () => pushTo(
        // TODO(P10): P09 does not read `?idea=` yet — it opens the editor
        // blank until it does. Same feature, no shared change needed.
        '${QuestsRoutePaths.editor}?idea=${idea.id}',
      ),
    );
  }
}
