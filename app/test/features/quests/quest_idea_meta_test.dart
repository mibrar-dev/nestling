// P10 · Quest library — pure idea-metadata tests (plan §f item 1).
//
// `kQuestIdeaMeta` is the presentation-side source for the category chips,
// the icon tile and the `.trow .mt` meta line. The `quests` table has no
// category column and the schema is shared, so nothing else checks these
// strings — a typo here ships as wrong copy on the list.

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/data/quests_repository_impl.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';

import '../../test_scope.dart';

/// `P10 .trow .mt`, character-for-character from
/// `design/html-source/screens/P10-quest-library.html` (middot U+00B7).
const _metaLines = <String>[
  '5 coins · Ages 4+ · Bedroom',
  '10 coins · Ages 5+ · Kitchen',
  '15 coins · Ages 8+ · Outdoors',
  '15 coins · Ages 7+ · Kitchen',
  '20 coins · Ages 9+ · Bedroom',
  '5 coins · Ages 4+ · Pets',
  '5 coins · Ages 5+ · School',
  '10 coins · Ages 5+ · Outdoors',
  '15 coins · Ages 7+ · Bedroom',
  '10 coins · Ages 5+ · School',
];

const _ideaIds = <String>[
  'idea-bed',
  'idea-table',
  'idea-bins',
  'idea-dishwasher',
  'idea-hoover',
  'idea-pet',
  'idea-bag',
  'idea-plants',
  'idea-washing',
  'idea-reading',
];

/// Icon asset per template, in design order (`<span class="icon-tile …">`).
/// Parent-audience exact (P09 `questBed/questDishes/questHoover/questBins`;
/// the rest already matched).
const _iconAssets = <String>[
  NestIcons.questBed,
  NestIcons.table,
  NestIcons.questBins,
  NestIcons.questDishes,
  NestIcons.questHoover,
  NestIcons.paw,
  NestIcons.schoolBag,
  NestIcons.sprout,
  NestIcons.washingMachine,
  NestIcons.book,
];

/// Tile tint per template, in design order (`tint-*` classes).
const _tints = <NestTileTint>[
  NestTileTint.peach,
  NestTileTint.sky,
  NestTileTint.leaf,
  NestTileTint.sky,
  NestTileTint.lilac,
  NestTileTint.coin,
  NestTileTint.sky,
  NestTileTint.leaf,
  NestTileTint.peach,
  NestTileTint.lilac,
];

void main() {
  // `rootBundle` (the SVG existence check below) needs the services binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuestIdeaMeta — repository templates', () {
    late List<Quest> ideas;

    setUp(() async {
      final db = await setUpTestScope();
      ideas = QuestsRepositoryImpl(db: db).ideas();
    });

    test('every template the repository ships has metadata', () {
      expect(ideas.map((q) => q.id), orderedEquals(_ideaIds));
      for (final id in ideas.map((q) => q.id)) {
        expect(questIdeaMetaFor(id), isNotNull, reason: id);
      }
      expect(
        kQuestIdeaMeta.keys.toSet().difference(ideas.map((q) => q.id).toSet()),
        isEmpty,
        reason: 'no orphan metadata entry without a template',
      );
    });

    test('no extra metadata entries and no missing ones', () {
      expect(kQuestIdeaMeta, hasLength(ideas.length));
      expect(questIdeaMetaFor('idea-nope'), isNull);
    });

    test('meta line matches the design copy character-for-character', () {
      for (var i = 0; i < _ideaIds.length; i++) {
        final meta = questIdeaMetaFor(_ideaIds[i])!;
        expect(
          meta.metaFor(ideas[i].coins),
          _metaLines[i],
          reason: _ideaIds[i],
        );
      }
    });

    test('the middot is U+00B7, never a hyphen or a bullet', () {
      final line = questIdeaMetaFor('idea-bed')!.metaFor(5);
      expect(line, contains('·'));
      expect(line.codeUnits, contains(0x00B7));
      expect(line, isNot(contains('•')));
      expect(line, isNot(contains(' - ')));
    });

    test('categories are a subset of the chip row', () {
      for (final id in _ideaIds) {
        expect(
          kQuestCategories,
          contains(questIdeaMetaFor(id)!.category),
          reason: id,
        );
      }
      // The chip row lists exactly the design's seven categories, in order.
      expect(kQuestCategories, <String>[
        'All',
        'Bedroom',
        'Kitchen',
        'Outdoors',
        'Pets',
        'School',
        'Kindness',
      ]);
    });

    test('the chip row never offers a category nothing can match', () {
      // `Kindness` is in the design's chip row but has no template: selecting
      // it must reach the empty state, never an "unreachable filter".
      final covered = _ideaIds
          .map((id) => questIdeaMetaFor(id)!.category)
          .toSet();
      expect(kQuestCategories.where((c) => !covered.contains(c)), <String>[
        'All',
        'Kindness',
      ]);
    });

    test('min ages match the design, in design order', () {
      expect(_ideaIds.map((id) => questIdeaMetaFor(id)!.minAge), <int>[
        4,
        5,
        8,
        7,
        9,
        4,
        5,
        5,
        7,
        5,
      ]);
    });

    test('icon asset matches the design tile, in design order', () {
      for (var i = 0; i < _ideaIds.length; i++) {
        expect(
          questIdeaMetaFor(_ideaIds[i])!.iconAsset,
          _iconAssets[i],
          reason: _ideaIds[i],
        );
      }
    });

    test('tile tint matches the design, in design order', () {
      for (var i = 0; i < _ideaIds.length; i++) {
        expect(
          questIdeaMetaFor(_ideaIds[i])!.tint,
          _tints[i],
          reason: _ideaIds[i],
        );
      }
    });

    test('the meta line never uses Quest.detail', () {
      // The repository formats `detail` as `5 coins · age 4+` — lowercase
      // `age`, no category. Using it on a row would ship wrong copy.
      expect(ideas.first.detail, '5 coins · age 4+');
      expect(
        questIdeaMetaFor(ideas.first.id)!.metaFor(ideas.first.coins),
        isNot(ideas.first.detail),
      );
    });
  });

  group('QuestIdeaMeta — icon assets are bundled', () {
    test('every template icon resolves to a real bundled SVG', () async {
      for (final id in _ideaIds) {
        final asset = questIdeaMetaFor(id)!.iconAsset;
        expect(asset, startsWith('assets/icons/'), reason: id);
        expect(asset, endsWith('.svg'), reason: id);
        final svg = await rootBundle.loadString(asset);
        expect(svg, contains('viewBox="0 0 24 24'), reason: id);
      }
    });

    test('every live-quest icon resolves to a real bundled SVG', () async {
      for (final icon in _seedIconKeys) {
        final asset = questIconAsset(icon);
        expect(asset, startsWith('assets/icons/'), reason: icon);
        await rootBundle.loadString(asset);
      }
    });

    test('an unknown icon key falls back to the quest card', () {
      expect(questIconAsset('definitely-not-an-icon'), NestIcons.questCard);
      expect(questTileTintFor('definitely-not-an-icon'), NestTileTint.neutral);
    });
  });

  group('QuestIdeaMeta — live quest icon map (Active tab)', () {
    test('the map is total over the demo seed icon keys', () {
      // `Seed._questsDemo` writes exactly these keys; an unmapped key would
      // silently fall through to the neutral quest card.
      expect(_seedIconKeys, <String>[
        'dishwasher',
        'book',
        'bins',
        'bed',
        'hoover',
        'plate',
        'paw',
        'bag',
        'leaf',
        'shirt',
        'sofa',
      ]);
      for (final icon in _seedIconKeys) {
        expect(
          questIconAsset(icon),
          _activeIconBySeedKey[icon],
          reason: 'icon key `$icon`',
        );
      }
    });

    test('every seeded quest gets a tinted tile, never the grey default', () {
      // `.icon-tile` is always tinted on P10 and on P08 (`todayTintFor`),
      // whose switch is total over the same keys and has no neutral branch.
      // A neutral tile means the key fell through and the quest renders
      // visually flat next to every other row.
      for (final icon in _seedIconKeys) {
        expect(
          questTileTintFor(icon),
          isNot(NestTileTint.neutral),
          reason: 'icon key `$icon` renders an untinted tile',
        );
      }
    });

    test('the same quest title keeps one tile tint across both tabs', () {
      // `kQuestIdeaMeta` (Ideas) and `questTileTintFor` (Active) must agree
      // for every quest that appears in both lists, otherwise the same title
      // changes colour when the user switches tab.
      const shared = <String, String>{
        'plate': 'idea-table',
        'dishwasher': 'idea-dishwasher',
        'hoover': 'idea-hoover',
        'bed': 'idea-bed',
        'paw': 'idea-pet',
        'bag': 'idea-bag',
        'leaf': 'idea-plants',
        'shirt': 'idea-washing',
        'bins': 'idea-bins',
        'book': 'idea-reading',
      };
      for (final entry in shared.entries) {
        expect(
          questTileTintFor(entry.key),
          questIdeaMetaFor(entry.value)!.tint,
          reason: '`${entry.key}` (Active) vs `${entry.value}` (Ideas)',
        );
      }
    });
  });
}

/// The `quests.icon` keys `Seed.demo()` writes (`core/data/seed.dart`).
const List<String> _seedIconKeys = <String>[
  'dishwasher',
  'book',
  'bins',
  'bed',
  'hoover',
  'plate',
  'paw',
  'bag',
  'leaf',
  'shirt',
  'sofa',
];

/// Icon asset the Active tab shows per seed icon key.
///
/// Ground truth is the parent-audience single source
/// `questIconFor(key, audience: NestAudience.parent)` (P09/P10/P08 HTML):
/// `q-living` (`sofa`) has no icon of its own and deliberately falls back to
/// the quest card, exactly as P08 does.
const _activeIconBySeedKey = <String, String>{
  'dishwasher': NestIcons.questDishes,
  'book': NestIcons.book,
  'bins': NestIcons.questBins,
  'bed': NestIcons.questBed,
  'hoover': NestIcons.questHoover,
  'plate': NestIcons.table,
  'paw': NestIcons.paw,
  'bag': NestIcons.schoolBag,
  'leaf': NestIcons.sprout,
  'shirt': NestIcons.washingMachine,
  'sofa': NestIcons.questCard,
};
