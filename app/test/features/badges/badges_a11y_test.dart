// K11 · My badges — stage 3 accessibility + tap-target tests.
//
// `1_plan.md` §f item 5, split out from `badges_view_test.dart` so the
// semantics contract of the whole screen is pinned in one file (the K08
// `shop_reward_a11y_test.dart` precedent).
//
// What is pinned here:
//   * every CONTROL exposes `SemanticsAction.tap` and `performAction(tap)`
//     drives the REAL navigation (RULES §8, orchestrator ACCESSIBILITY
//     ACTIONS);
//   * every tap target is at least `NestDevice.tapKid` (56) on this kid
//     screen — the `--tap-kid` token the HTML's `.lg` boxes use
//     (`K11-badges.html:11`), never the 44 px parent floor;
//   * static content is announced once and never announced as a control:
//     one merged label per badge tile, the medal art excluded, the week
//     dots' glyphs excluded, the title / subtitle / why-line plain text.
//
// Multi-line text reaches the accessibility tree with `\n` where it wrapped,
// so every lookup here normalises whitespace first — otherwise a design line
// that happens to wrap in the test font would read as "no node".
//
// No `DateTime.now`, no `google_fonts`, no simulator. Every pumped app ends
// with `disposeApp` (test_scope.dart).

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;
import 'package:nestling/features/badges/domain/entities/badges_data.dart';
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';
import 'package:nestling/features/badges/presentation/widgets/happy_week_card.dart';

import '../../test_scope.dart';

const String _route = '/badges';

/// A repository whose `watchActiveBadges` stream never speaks, so the screen
/// stays in the loading state and the spinner's own semantics can be read
/// (a seeded database always succeeds).
class _SilentBadgesRepository implements BadgesRepository {
  @override
  Stream<BadgesData> watchActiveBadges() => const Stream<BadgesData>.empty();

  @override
  Stream<List<domain.Badge>> watchShelf(String childId) =>
      const Stream<List<domain.Badge>>.empty();

  @override
  Stream<int> watchHappyDays(String childId) => const Stream<int>.empty();

  @override
  Future<List<domain.Badge>> getItems() async => const <domain.Badge>[];

  @override
  Stream<List<domain.Badge>> watchItems() =>
      const Stream<List<domain.Badge>>.empty();
}

Future<void> _useRepository(BadgesRepository repo) async {
  await GetIt.instance.unregister<BadgesRepository>();
  GetIt.instance.registerSingleton<BadgesRepository>(repo);
}

/// A repository whose first watch fails and whose second serves a one-badge
/// shelf — the failure surface plus its recovery, on demand (a seeded
/// database always succeeds).
class _FailOnceBadgesRepository implements BadgesRepository {
  _FailOnceBadgesRepository({required this.shelf, required this.happyDays});

  final List<domain.Badge> shelf;
  final int happyDays;
  int _watches = 0;

  @override
  Stream<BadgesData> watchActiveBadges() {
    _watches++;
    if (_watches == 1) {
      return Stream<BadgesData>.error(Exception('badges down'));
    }
    return Stream<BadgesData>.value(
      BadgesData(childId: 'maya', items: shelf, happyDays: happyDays),
    );
  }

  @override
  Stream<List<domain.Badge>> watchShelf(String childId) =>
      Stream<List<domain.Badge>>.value(shelf);

  @override
  Stream<int> watchHappyDays(String childId) => Stream<int>.value(happyDays);

  @override
  Future<List<domain.Badge>> getItems() async => shelf;

  @override
  Stream<List<domain.Badge>> watchItems() =>
      Stream<List<domain.Badge>>.value(shelf);
}

domain.Badge _recoveredBadge() => const domain.Badge(
  id: 'first-quest',
  title: 'First quest',
  detail: 'Got it!',
  icon: 'medal',
  description: '',
  earned: true,
  earnedAt: null,
);

Future<void> _pumpFailure(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
}) async {
  await _useRepository(
    _FailOnceBadgesRepository(
      shelf: <domain.Badge>[_recoveredBadge()],
      happyDays: 2,
    ),
  );
  await _pumpRoute(tester, theme: theme);
}

Future<void> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String route = _route,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Collapses the line breaks a wrapped label carries into single spaces, so a
/// lookup can name the design's copy rather than this font's wrap points.
String _flat(String label) => label.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Every labelled semantics node on the screen.
///
/// Found through `find.bySemanticsLabel` (the K08 `shop_reward_a11y_test.dart`
/// pattern) rather than the deprecated `pipelineOwner.semanticsOwner` walk,
/// so this is exactly the tree the platform sees.
List<SemanticsNode> _nodes(WidgetTester tester) => <SemanticsNode>[
  for (final element in find.bySemanticsLabel(RegExp('.')).evaluate())
    tester.getSemantics(
      find.byElementPredicate((candidate) => identical(candidate, element)),
    ),
];

/// The first node whose whitespace-flattened label equals [label].
SemanticsNode _node(WidgetTester tester, String label) {
  for (final node in _nodes(tester)) {
    if (_flat(node.getSemanticsData().label) == label) return node;
  }
  throw StateError('no semantics node labelled "$label"');
}

/// The first node whose whitespace-flattened label contains [fragment].
SemanticsNode _nodeContaining(WidgetTester tester, String fragment) {
  for (final node in _nodes(tester)) {
    if (_flat(node.getSemanticsData().label).contains(fragment)) return node;
  }
  throw StateError('no semantics node containing "$fragment"');
}

/// Asserts [label] is a live control: a tap action, announced as a button,
/// never reported disabled, and `performAction` that runs the real handler.
void _expectLiveControl(WidgetTester tester, String label) {
  final node = _node(tester, label);
  final data = node.getSemanticsData();
  expect(
    data.hasAction(SemanticsAction.tap),
    isTrue,
    reason: '"$label" must expose SemanticsAction.tap (RULES §8)',
  );
  expect(
    data.flagsCollection.isButton,
    isTrue,
    reason: '"$label" must announce as a button',
  );
  expect(
    data.flagsCollection.isEnabled.toBoolOrNull(),
    isNot(isFalse),
    reason: '"$label" is an enabled control, never announced as disabled',
  );
  node.owner!.performAction(node.id, SemanticsAction.tap);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  group('K11 tap targets (kid floor = NestDevice.tapKid)', () {
    testWidgets('back and the lock are both 56 px squares', (tester) async {
      await _pumpRoute(tester);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(NestIconButton)),
        const Size(NestDevice.tapKid, NestDevice.tapKid),
      );
      expect(
        tester.getSize(find.byType(NestLockButton)),
        const Size(NestDevice.tapKid, NestDevice.tapKid),
      );
      await disposeApp(tester);
    });

    testWidgets('the kid targets clear the 44 px parent floor too', (
      tester,
    ) async {
      await _pumpRoute(tester);
      for (final finder in <Finder>[
        find.byType(NestIconButton),
        find.byType(NestLockButton),
      ]) {
        expect(
          tester.getSize(finder).shortestSide,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: 'a kid control is never below the 44 px parent floor',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('nothing on the shelf is a smaller control than 44', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(tester.takeException(), isNull);
      // Every interactive node on K11 is the back or the lock — the badge
      // tiles are static cards. Proved by walking the tree for tap actions
      // rather than trusting that claim.
      final tappable = <String>[
        for (final node in _nodes(tester))
          if (node.getSemanticsData().hasAction(SemanticsAction.tap))
            _flat(node.getSemanticsData().label),
      ];
      expect(
        tappable.where((label) => label.isNotEmpty).toSet(),
        <String>{'Back', 'Grown-ups'},
        reason:
            'the only labelled controls on K11 are the back and the lock; a '
            'badge tile must never appear as one',
      );
      for (final label in tappable.where((label) => label.isNotEmpty)) {
        final box = _node(tester, label).getSemanticsData().rect;
        expect(box.shortestSide, greaterThanOrEqualTo(NestDevice.tapParent));
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a text-only surface offers no control at all', (tester) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(_SilentBadgesRepository());
      await _pumpRoute(tester);
      final tappable = <String>[
        for (final node in _nodes(tester))
          if (node.getSemanticsData().hasAction(SemanticsAction.tap))
            _flat(node.getSemanticsData().label),
      ];
      expect(tappable.where((label) => label.isNotEmpty).toSet(), <String>{
        'Back',
        'Grown-ups',
      }, reason: 'loading adds a spinner, never a new button');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the kid targets stay 56 at the 320 px / 1.3 corner', (
      tester,
    ) async {
      // The widths × scales matrix is about layout survival; the targets
      // must not shrink with it — 56 px boxes at the narrowest,
      // largest-type corner, still clearing the 44 px parent floor.
      await _pumpRoute(tester, width: 320, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(NestIconButton)),
        const Size(NestDevice.tapKid, NestDevice.tapKid),
      );
      expect(
        tester.getSize(find.byType(NestLockButton)),
        const Size(NestDevice.tapKid, NestDevice.tapKid),
      );
      final semantics = tester.ensureSemantics();
      for (final label in <String>['Back', 'Grown-ups']) {
        final box = _node(tester, label).getSemanticsData().rect;
        expect(
          box.shortestSide,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: '"$label" semantics rect at 320/1.3',
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K11 semantics labels on the icon buttons', () {
    testWidgets('the HTML aria-labels are used verbatim', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      // `aria-label="Back"` / `aria-label="Grown-ups"`
      // (`K11-badges.html:38`).
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      for (final label in <String>['Back', 'Grown-ups']) {
        expect(
          _node(
            tester,
            label,
          ).getSemanticsData().flagsCollection.isEnabled.toBoolOrNull(),
          isNot(isFalse),
          reason: '"$label" is never a disabled control',
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a screen-reader tap on Back leaves for the kid home', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      _expectLiveControl(tester, 'Back');
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      expect(find.byType(BadgeGridCell), findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a screen-reader tap on the lock opens the gate', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      _expectLiveControl(tester, 'Grown-ups');
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the chrome stays operable while the shelf is still loading', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(_SilentBadgesRepository());
      await _pumpRoute(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      _expectLiveControl(tester, 'Grown-ups');
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K11 static content is announced once, never as a control', () {
    testWidgets('each badge tile is one merged node with no tap action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final rows = await db.select(db.badges).get();
      final earned = <String>{
        for (final e in await db.select(db.earnedBadges).get())
          if (e.childId == 'maya') e.badgeId,
      };
      for (final row in rows) {
        final label =
            '${row.title}, ${earned.contains(row.id) ? 'Got it!' : 'Keep going!'}';
        final data = _node(tester, label).getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isFalse,
          reason: '$label is a static card — no destination, so no tap',
        );
        expect(
          data.flagsCollection.isButton,
          isFalse,
          reason: '$label must not announce as a button',
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a tile label is not split into name and sub nodes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      // The tile merges its children (`excludeSemantics: true`), so neither
      // the bare name nor the bare sub copy may exist as its own node.
      final labels = <String>[
        for (final node in _nodes(tester)) _flat(node.getSemanticsData().label),
      ];
      expect(labels, isNot(contains('First quest')));
      expect(labels, isNot(contains('Got it!')));
      expect(labels, contains('First quest, Got it!'));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the medal art carries no semantics of its own', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      // The medal is `ExcludeSemantics`, so the tree must not grow an extra
      // node per tile: exactly one labelled node per tile, nothing from the
      // SVG layer, and no node announcing the ribbon fallback either.
      final labels = <String>[
        for (final node in _nodes(tester))
          if (_flat(node.getSemanticsData().label).isNotEmpty)
            _flat(node.getSemanticsData().label),
      ];
      final cells = find.byType(BadgeGridCell).evaluate().length;
      final merged = labels.where((label) => label.contains('!')).length;
      expect(merged, cells, reason: 'one merged node per tile, nothing extra');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the heading, subtitle and why-line are plain text nodes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      for (final copy in <String>[
        'My badges',
        'Four shiny ones already. Pip is very impressed.',
      ]) {
        final data = _node(tester, copy).getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isFalse,
          reason: '"$copy" is text, not a control',
        );
        expect(_flat(data.label), copy, reason: 'copy reaches the tree intact');
      }
      // The week line rides in the same run as the day letters (Flutter merges
      // the card's plain-text descendants into one node), so it is matched as a
      // fragment — the copy itself is still announced character-for-character.
      final why = _nodeContaining(
        tester,
        '4 happy days this week — Pip hasn’t stopped singing.',
      ).getSemanticsData();
      expect(
        why.hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'the why-line is text, not a control',
      );
      expect(
        _flat(why.label),
        contains('4 happy days this week — Pip hasn’t stopped singing.'),
        reason:
            'em dash U+2014 and curly apostrophe U+2019 survive to the tree',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the week card announces its letters, never its glyphs', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(find.byType(HappyWeekCard), findsOneWidget);
      // The filled check / empty ring inside each dot are `ExcludeSemantics`,
      // so the card contributes exactly ONE run of plain text: the seven day
      // letters followed by the why-line. No glyph node, no per-dot control.
      final card = _nodeContaining(
        tester,
        'happy days this week',
      ).getSemanticsData();
      expect(card.hasAction(SemanticsAction.tap), isFalse);
      final lines = card.label
          .split('\n')
          .map(_flat)
          .where((l) => l.isNotEmpty);
      expect(lines.take(7).toList(), <String>[
        'M',
        'T',
        'W',
        'T',
        'F',
        'S',
        'S',
      ], reason: 'Mon–Sun in design order');
      expect(
        _flat(lines.skip(7).join(' ')),
        '4 happy days this week — Pip hasn’t stopped singing.',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the loading spinner is labelled for a screen reader', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(_SilentBadgesRepository());
      await _pumpRoute(tester);
      final data = _node(tester, 'Loading badges').getSemanticsData();
      expect(
        data.hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'the spinner reports progress; it is not a control',
      );
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K11 Try again control on the failure surface', () {
    testWidgets('the failure surface offers Back, Grown-ups and Try again', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpFailure(tester);
      expect(find.text('Something went wrong'), findsOneWidget);
      final tappable = <String>{
        for (final node in _nodes(tester))
          if (node.getSemanticsData().hasAction(SemanticsAction.tap))
            _flat(node.getSemanticsData().label),
      }.where((label) => label.isNotEmpty).toSet();
      expect(
        tappable,
        <String>{'Back', 'Grown-ups', 'Try again'},
        reason:
            'the retry surface adds exactly one control — the failure must '
            'never strand a child without a way forward',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('Try again is a kid-sized live control that reloads', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpFailure(tester);
      final data = _node(tester, 'Try again').getSemanticsData();
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: '"Try again" must expose SemanticsAction.tap (RULES §8)',
      );
      expect(
        data.flagsCollection.isButton,
        isTrue,
        reason: '"Try again" must announce as a button',
      );
      expect(
        data.flagsCollection.isEnabled.toBoolOrNull(),
        isNot(isFalse),
        reason: '"Try again" is never a disabled control',
      );
      // Kid screen, kid floor: `NestKidButton` carries min-height 64, so the
      // retry clears the 56 px kid target as well as the 44 px parent floor.
      expect(
        tester.getSize(find.byType(NestKidButton)).shortestSide,
        greaterThanOrEqualTo(NestDevice.tapKid),
      );
      expect(
        data.rect.shortestSide,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('My badges'), findsOneWidget);
      expect(find.byType(BadgeGridCell), findsOneWidget);
      expect(
        find.text('One shiny one already. Pip is very impressed.'),
        findsOneWidget,
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the failure surface renders in dark with working chrome', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpFailure(tester, theme: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      // The chrome stays operable in dark: a screen-reader tap on the lock
      // still reaches the parental gate from the failure surface.
      _expectLiveControl(tester, 'Grown-ups');
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      semantics.dispose();
      await disposeApp(tester);
    });
  });
}
