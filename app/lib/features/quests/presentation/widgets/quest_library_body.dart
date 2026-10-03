import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_category_chips.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_row.dart';
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
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final visibleIdeas = filterQuestIdeas(
      widget.ideas,
      query: _query,
      category: _category,
    );

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
          NestBalancedText(
            'Quests',
            style: NestType.h1(color: tokens.ink),
            textAlign: TextAlign.left,
            maxLines: 1,
          ),
        ),
        _gutter(const SizedBox(height: NestSpacing.s4)),
        _gutter(
          NestSegmented<String>(
            semanticLabel: 'Quest lists',
            value: _tab == QuestLibraryTab.active ? 'active' : 'ideas',
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
        _gutter(const SizedBox(height: NestSpacing.s4)),
        _gutter(
          Semantics(
            label: 'Search quest ideas',
            textField: true,
            child: NestTextField(
              hintText: 'Search ideas',
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              prefixIcon: NestIcon(NestIcons.search, color: tokens.ink3),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
        // `.chipscroll { margin: 0 -20px }` cancels `.scroll > * + *`, so
        // the filter row sits flush under the search field (no 16 px gap)
        // and carries its own 20 px edge padding.
        QuestCategoryChips(
          categories: kQuestCategories,
          selected: _category,
          onSelected: (value) => setState(() => _category = value),
        ),
        _gutter(const SizedBox(height: NestSpacing.s4)),
        ..._rows(visibleIdeas),
      ],
    );
  }

  /// `.scroll`'s 20 px side gutter, applied per child (Flutter forbids
  /// negative padding, so the bleed row cannot cancel a viewport gutter).
  static Widget _gutter(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
    child: child,
  );

  List<Widget> _rows(List<Quest> visibleIdeas) {
    if (_tab == QuestLibraryTab.active) {
      if (widget.items.isEmpty) {
        return const <Widget>[
          NestEmptyState(
            title: 'No active quests',
            message: 'Add one from Ideas.',
          ),
        ];
      }
      return <Widget>[
        for (final Quest quest in widget.items) ...<Widget>[
          Builder(
            builder: (context) => _gutter(
              QuestIdeaRow(
                key: ValueKey<String>('quest-active-${quest.id}'),
                title: quest.title,
                meta: quest.detail,
                iconAsset: questIconAsset(quest.icon),
                tint: questTileTintFor(quest.icon),
                // TODO(P10): P09 does not read a `?id=` query param yet, so
                // the editor opens blank. Same feature, no shared change.
                onTap: () => context.push(QuestsRoutePaths.editor),
              ),
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
        ],
      ];
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

    return <Widget>[
      for (final Quest idea in visibleIdeas) ...<Widget>[
        Builder(builder: (context) => _gutter(_ideaRow(context, idea))),
        const SizedBox(height: NestSpacing.s4),
      ],
    ];
  }

  Widget _ideaRow(BuildContext context, Quest idea) {
    final meta = questIdeaMetaFor(idea.id);
    return QuestIdeaRow(
      key: ValueKey<String>('quest-idea-${idea.id}'),
      title: idea.title,
      meta: meta?.metaFor(idea.coins) ?? idea.detail,
      iconAsset: meta?.iconAsset ?? NestIcons.questCard,
      tint: meta?.tint ?? NestTileTint.neutral,
      addSemanticLabel: 'Add ${idea.title}',
      onAdd: () => context.push(
        // TODO(P10): P09 does not read `?idea=` yet — it opens the editor
        // blank until it does. Same feature, no shared change needed.
        '${QuestsRoutePaths.editor}?idea=${idea.id}',
      ),
    );
  }
}
