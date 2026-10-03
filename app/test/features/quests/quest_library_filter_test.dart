// P10 · Quest library — pure `filterQuestIdeas` tests (plan §f item 2).
//
// The view wires the search field and the chip row to this function, but the
// view tests can only observe it through rendered rows. These tests pin the
// filter contract directly: the two filters combine with AND, the query is a
// case-insensitive substring of the title, and `Kindness` legitimately
// matches nothing.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_meta.dart';

Quest _idea(String id, String title) => Quest(
  id: id,
  title: title,
  detail: '',
  icon: 'leaf',
  coins: 5,
  repeatRule: 'daily',
  days: '',
  dueLabel: null,
  needsApproval: true,
  assigneeChildId: null,
  active: false,
);

final List<Quest> _ideas = <Quest>[
  _idea('idea-bed', 'Make your bed'),
  _idea('idea-table', 'Lay the table'),
  _idea('idea-bins', 'Put the bins out'),
  _idea('idea-dishwasher', 'Empty the dishwasher'),
  _idea('idea-hoover', 'Hoover the stairs'),
  _idea('idea-pet', 'Feed the pet'),
  _idea('idea-bag', 'Pack school bag'),
  _idea('idea-plants', 'Water the plants'),
  _idea('idea-washing', 'Help with the washing'),
  _idea('idea-reading', 'Read for 20 minutes'),
];

List<String> _ids(List<Quest> ideas) => ideas.map((q) => q.id).toList();

void main() {
  group('filterQuestIdeas — no filter', () {
    test('an empty query with All returns every template in order', () {
      expect(filterQuestIdeas(_ideas), hasLength(10));
      expect(_ids(filterQuestIdeas(_ideas)), _ids(_ideas));
    });

    test('the defaults are query "" and category All', () {
      expect(
        _ids(filterQuestIdeas(_ideas, query: '  ')),
        _ids(filterQuestIdeas(_ideas)),
      );
      expect(
        _ids(filterQuestIdeas(_ideas, category: 'Bedroom')),
        hasLength(3),
        reason: 'a non-default category really filters',
      );
    });

    test('the result is unmodifiable (a view must not mutate the list)', () {
      expect(
        () => filterQuestIdeas(_ideas).add(_idea('x', 'x')),
        throwsUnsupportedError,
      );
    });

    test('the source list is never reordered or mutated', () {
      filterQuestIdeas(_ideas, query: 'e', category: 'Kitchen');
      expect(_ids(_ideas), _ids(_ideas));
    });
  });

  group('filterQuestIdeas — query', () {
    test('is a case-insensitive substring match', () {
      expect(_ids(filterQuestIdeas(_ideas, query: 'MAKE')), <String>[
        'idea-bed',
      ]);
      expect(_ids(filterQuestIdeas(_ideas, query: 'make')), <String>[
        'idea-bed',
      ]);
    });

    test('matches anywhere in the title, not just the start', () {
      expect(_ids(filterQuestIdeas(_ideas, query: 'table')), <String>[
        'idea-table',
      ]);
      expect(_ids(filterQuestIdeas(_ideas, query: '20 minutes')), <String>[
        'idea-reading',
      ]);
    });

    test('trims surrounding whitespace', () {
      expect(_ids(filterQuestIdeas(_ideas, query: '  pet  ')), <String>[
        'idea-pet',
      ]);
    });

    test('a whitespace-only query matches everything', () {
      expect(filterQuestIdeas(_ideas, query: '   '), hasLength(10));
    });

    test('no match returns an empty list, never null', () {
      final result = filterQuestIdeas(_ideas, query: 'zzzz');
      expect(result, isEmpty);
    });

    test('an empty list stays empty', () {
      expect(filterQuestIdeas(const <Quest>[], query: 'bed'), isEmpty);
    });
  });

  group('filterQuestIdeas — category', () {
    test('Kitchen keeps exactly its two templates', () {
      expect(_ids(filterQuestIdeas(_ideas, category: 'Kitchen')), <String>[
        'idea-table',
        'idea-dishwasher',
      ]);
    });

    test('every category maps to its design templates', () {
      expect(_ids(filterQuestIdeas(_ideas, category: 'Bedroom')), <String>[
        'idea-bed',
        'idea-hoover',
        'idea-washing',
      ]);
      expect(_ids(filterQuestIdeas(_ideas, category: 'Outdoors')), <String>[
        'idea-bins',
        'idea-plants',
      ]);
      expect(_ids(filterQuestIdeas(_ideas, category: 'Pets')), <String>[
        'idea-pet',
      ]);
      expect(_ids(filterQuestIdeas(_ideas, category: 'School')), <String>[
        'idea-bag',
        'idea-reading',
      ]);
    });

    test('Kindness is a design chip with no templates (empty state)', () {
      expect(filterQuestIdeas(_ideas, category: 'Kindness'), isEmpty);
    });

    test('an unknown category matches nothing', () {
      expect(filterQuestIdeas(_ideas, category: 'Nonsense'), isEmpty);
    });

    test('a template id with no metadata is dropped by a category filter', () {
      final unknown = <Quest>[..._ideas, _idea('idea-x', 'Mystery quest')];
      // `All` is the identity filter, so the extra template still shows …
      expect(_ids(filterQuestIdeas(unknown)), contains('idea-x'));
      // … but no category can claim it.
      for (final category in kQuestCategories.where(
        (c) => c != kAllQuestCategories,
      )) {
        expect(
          _ids(filterQuestIdeas(unknown, category: category)),
          isNot(contains('idea-x')),
          reason: category,
        );
      }
    });
  });

  group('filterQuestIdeas — the two filters combine with AND', () {
    test('query narrows within a category', () {
      // 'the' hits Hoover the stairs and Help with the washing, both Bedroom.
      expect(
        _ids(filterQuestIdeas(_ideas, query: 'the', category: 'Bedroom')),
        <String>['idea-hoover', 'idea-washing'],
      );
      // …and inside Kitchen it hits two of its own.
      expect(
        _ids(filterQuestIdeas(_ideas, query: 'the', category: 'Kitchen')),
        <String>['idea-table', 'idea-dishwasher'],
      );
    });

    test('category narrows a query that matches outside it', () {
      // 'the' matches seven of the ten titles; only three are Kitchen.
      expect(filterQuestIdeas(_ideas, query: 'the'), hasLength(7));
      expect(
        _ids(filterQuestIdeas(_ideas, query: 'the', category: 'Kitchen')),
        <String>['idea-table', 'idea-dishwasher'],
      );
      expect(
        _ids(filterQuestIdeas(_ideas, query: 'the', category: 'Outdoors')),
        <String>['idea-bins', 'idea-plants'],
      );
      expect(
        _ids(filterQuestIdeas(_ideas, query: 'the', category: 'Pets')),
        <String>['idea-pet'],
      );
      expect(
        _ids(filterQuestIdeas(_ideas, query: 'the', category: 'School')),
        isEmpty,
        reason: 'no School title contains "the"',
      );
    });

    test('a query matching nothing in the chosen category is empty', () {
      expect(
        filterQuestIdeas(_ideas, query: 'pet', category: 'Kitchen'),
        isEmpty,
      );
    });

    test('the order of the arguments does not matter', () {
      expect(
        _ids(filterQuestIdeas(_ideas, query: 'washing', category: 'Bedroom')),
        _ids(filterQuestIdeas(_ideas, category: 'Bedroom', query: 'washing')),
      );
    });

    test('filtering is stable: the source order is preserved', () {
      final result = filterQuestIdeas(_ideas, query: 'e');
      expect(_ids(result), orderedEquals(_ids(result)));
      for (var i = 1; i < result.length; i++) {
        expect(
          _ideas.indexOf(result[i]),
          greaterThan(_ideas.indexOf(result[i - 1])),
          reason: 'results must follow source order',
        );
      }
    });
  });
}
