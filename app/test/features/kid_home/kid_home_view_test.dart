// K03 view tests over the in-memory Drift database: the full width × scale ×
// theme matrix, empty/loading/error states, every tap destination, semantics
// labels on icon buttons and kid tap sizes.
//
// Database-backed tests use `setUpTestScope` + Seed.demo (or Seed.empty);
// loading/error paths, which a healthy database cannot produce, use a
// feature-local fake repository registered over the real one in GetIt.
// Every pumped app ends with `disposeApp` (see test_scope.dart).

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_status_chip.dart';

import '../../test_scope.dart';

const KidChild _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
);

/// Maya's 6 quests in repo (alphabetical) order with demo statuses:
/// 4 done (2 approved + 2 done_pending), 2 to_do (q-reading is first).
List<KidQuest> _mayaItems() => const <KidQuest>[
  KidQuest(
    id: 'q-bins:maya',
    title: 'Put the bins out',
    detail: 'Done · +15',
    questId: 'q-bins',
    icon: 'bins',
    coins: 15,
    status: 'approved',
  ),
  KidQuest(
    id: 'q-dishwasher:maya',
    title: 'Empty the dishwasher',
    detail: "Waiting for Mum's thumbs-up · +15",
    questId: 'q-dishwasher',
    icon: 'dishwasher',
    coins: 15,
    status: 'done_pending',
  ),
  KidQuest(
    id: 'q-hoover:maya',
    title: 'Hoover the stairs',
    detail: 'Done · +20',
    questId: 'q-hoover',
    icon: 'hoover',
    coins: 20,
    status: 'approved',
  ),
  KidQuest(
    id: 'q-table:maya',
    title: 'Lay the table',
    detail: "Waiting for Mum's thumbs-up · +10",
    questId: 'q-table',
    icon: 'plate',
    coins: 10,
    status: 'done_pending',
  ),
  KidQuest(
    id: 'q-reading:maya',
    title: 'Reading – 20 minutes',
    detail: 'To do · +10',
    questId: 'q-reading',
    icon: 'book',
    coins: 10,
    status: 'to_do',
  ),
  KidQuest(
    id: 'q-tidy:maya',
    title: 'Tidy your bedroom',
    detail: 'To do · +15',
    questId: 'q-tidy',
    icon: 'bed',
    coins: 15,
    status: 'to_do',
  ),
];

/// Fake repository for the states a Drift database cannot produce:
/// silent streams (loading), stream errors (load failure) and a failing
/// completion write (actionError). Streams are rebuilt per `watch…()` call,
/// matching the Drift repository; a successful `completeQuest` flips the
/// quest to `done_pending` and re-emits, so the celebration can ride the
/// flip exactly as it does on the real repository.
class _FakeKidHomeRepository extends KidHomeRepository {
  _FakeKidHomeRepository({
    this.failLoad = false,
    this.hang = false,
    this.failComplete = false,
  });

  bool failLoad;
  bool hang;
  bool failComplete;

  final List<List<String>> completed = <List<String>>[];
  final StreamController<List<KidQuest>> _itemsPushed =
      StreamController<List<KidQuest>>.broadcast();

  List<KidQuest> _items = _mayaItems();

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() {
    if (hang) {
      return const Stream<List<KidQuest>>.empty();
    }
    if (failLoad) {
      return Stream<List<KidQuest>>.error(Exception('items down'));
    }
    return _watchItems();
  }

  Stream<List<KidQuest>> _watchItems() async* {
    yield _items;
    yield* _itemsPushed.stream;
  }

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  Stream<KidChild?> watchActiveChild() {
    if (hang) {
      return const Stream<KidChild?>.empty();
    }
    if (failLoad) {
      return Stream<KidChild?>.error(Exception('child down'));
    }
    return Stream<KidChild?>.value(_maya);
  }

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {
    completed.add(<String>[childId, questId]);
    if (failComplete) {
      throw Exception('save failed');
    }
    _items = <KidQuest>[
      for (final quest in _items)
        if (quest.questId == questId)
          KidQuest(
            id: quest.id,
            title: quest.title,
            detail: quest.detail,
            questId: quest.questId,
            icon: quest.icon,
            coins: quest.coins,
            status: 'done_pending',
          )
        else
          quest,
    ];
    _itemsPushed.add(_items);
  }
}

/// Swaps the DI-registered repository for [repo] before pumping the app.
Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

/// Pumps the full app at [route] on a [width]×844 surface with [textScale].
Future<void> _pumpRoute(
  WidgetTester tester, {
  String route = '/kid-home',
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
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

void _expectAtLeast(
  WidgetTester tester,
  Finder finder,
  double min,
  String what,
) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(min), reason: '$what width');
  expect(size.height, greaterThanOrEqualTo(min), reason: '$what height');
}

/// Scrolls the quest list until the (lazy) card column is built. At larger
/// text scales the cards start below the viewport + cache extent, so the
/// widget tree contains none of them until the list moves.
Future<void> _revealCards(WidgetTester tester) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 10; i++) {
    if (find.byType(NestKidQuestCard).evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(list, const Offset(0, -200));
    await tester.pump();
  }
}

/// Bounded route-transition pumps. `pumpAndSettle` is avoided on purpose:
/// the loading spinner is an endless animation, so a screen that is still
/// loading would spin it forever.
Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Asset names of every [SvgPicture] currently in the tree.
List<String> _svgAssets(WidgetTester tester) => find
    .byType(SvgPicture)
    .evaluate()
    .map((element) => (element.widget as SvgPicture).bytesLoader)
    .whereType<SvgAssetLoader>()
    .map((loader) => loader.assetName)
    .toList();

/// The dock's surface container: a top-only 3 px ink border (design
/// `.k3-dock`), which distinguishes it from quest cards (all-side borders).
Finder _dockSurfaceFinder() => find.byWidgetPredicate((widget) {
  if (widget is! Container) {
    return false;
  }
  final decoration = widget.decoration;
  if (decoration is! BoxDecoration) {
    return false;
  }
  final border = decoration.border;
  return border is Border && border.top.width == 3 && border.left.width == 0;
});

/// The nest artwork inside the pet slot: the 260 px-wide [SvgPicture] of
/// [PipNestFallback]. The Pip is drawn as a [PipAvatar] (and the v1 fallback
/// pictures live in the empty/failure states), so the width identifies it.
Finder _nestSvgFinder() => find.descendant(
  of: find.byType(PipNestFallback),
  matching: find.byWidgetPredicate(
    (widget) => widget is SvgPicture && widget.width == 260,
  ),
);

/// The 48×48 icon tile of the quest card carrying [questTitle]
/// (`.quest-card.kid .kid-icon`: radius 16, per-quest tint or surface2).
Finder _questTile(WidgetTester tester, String questTitle) => find.descendant(
  of: find.ancestor(
    of: find.text(questTitle),
    matching: find.byType(NestKidQuestCard),
  ),
  matching: find.byWidgetPredicate((widget) {
    if (widget is! Container) {
      return false;
    }
    final box = widget.decoration;
    return box is BoxDecoration &&
        box.borderRadius == BorderRadius.circular(16);
  }),
);

/// The meadow band behind progress + cards: the full-bleed [CustomPaint] that
/// wraps the quest list panel (a local painter until the design system owns a
/// meadow band — SHARED_REQUEST #6).
Finder _meadowBandFinder() => find.ancestor(
  of: find.byType(NestProgress),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == '_MeadowPainter',
  ),
);

/// v1 Pip illustrations — the orchestrator forbids them in product screens.
List<String> _v1PipAssets(WidgetTester tester) =>
    _svgAssets(tester).where((name) => name.contains('pip_stage')).toList();

/// Adds a quest-less child and makes them the active child.
Future<void> _addQuestlessChild(
  WidgetTester tester, {
  required String id,
  required String nickname,
}) async {
  final db = GetIt.instance<AppDatabase>();
  await tester.runAsync(() async {
    await db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: Seed.familyId,
            nickname: nickname,
          ),
        );
    await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(activeChildId: Value<String?>(id)),
    );
    await GetIt.instance<AppSession>().refresh();
  });
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('K03 layout matrix', () {
    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];
    const widths = <double>[320, 390, 430];
    const scales = <double>[1, 1.3];

    for (final (String themeName, ThemeMode theme) in themes) {
      for (final width in widths) {
        for (final scale in scales) {
          testWidgets(
            '$themeName ${width.toInt()}px scale $scale renders without overflow',
            (tester) async {
              await _pumpRoute(
                tester,
                width: width,
                textScale: scale,
                theme: theme,
              );
              expect(find.text('Hi Maya!'), findsOneWidget);
              expect(find.text('120'), findsOneWidget);
              expect(find.text('4 of 6 done'), findsOneWidget);
              await _revealCards(tester);
              expect(find.byType(NestKidQuestCard), findsNWidgets(6));
              expect(find.text('Pip'), findsOneWidget);
              expect(find.text('Shop'), findsOneWidget);
              expect(find.text('My jar'), findsOneWidget);
              expect(find.textContaining('£'), findsNothing);
              expect(tester.takeException(), isNull);
              await disposeApp(tester);
            },
          );
        }
      }
    }
  });

  group('K03 layout invariants', () {
    // The orchestrator's absolute band targets (ORCHESTRATOR_NOTES, QA of
    // cmp_light_4: hearts 443 / section 490 / progress 520 / card 560 /
    // dock 720) are capture rows for one device + inset combination, so the
    // UI stage measures them. What a test can pin deterministically is the
    // layout CONTRACT: the block order and the specified gaps from
    // `1_plan.md` §(a) / SPACING §8, which any future trim must preserve.
    testWidgets('blocks stack in order with the specified gaps', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final pet = tester.getRect(find.byType(NestPetStage));
      final hearts = tester.getRect(find.byType(NestHeart).first);
      final section = tester.getRect(find.text("Today's quests"));
      final progress = tester.getRect(find.byType(NestProgress));
      final card1 = tester.getRect(find.byType(NestKidQuestCard).first);
      final card2 = tester.getRect(find.byType(NestKidQuestCard).at(1));
      final dock = tester.getRect(_dockSurfaceFinder());

      // Order: pet → hearts → section → progress → cards, with the scroll
      // viewport ending exactly where the fixed dock starts (content
      // scrolls behind the bar, as the design intends).
      expect(pet.top, lessThan(hearts.top));
      expect(hearts.bottom, lessThanOrEqualTo(section.top));
      expect(section.bottom, lessThanOrEqualTo(progress.top));
      expect(progress.bottom, lessThanOrEqualTo(card1.top));
      expect(
        tester.getRect(find.byType(ListView)).bottom,
        closeTo(dock.top, 0.5),
        reason: 'the quest list ends at the dock, never under it',
      );

      // Gaps between blocks whose heights are fixed by the design system,
      // so they cannot drift with the test font:
      //  · hearts → section: 16 (the heart is a fixed 26 px slot)
      //  · progress → first card: 16 (meadow panel column spacing)
      //  · card → card: 12 (the card's 6 px shadow reserve is inside its
      //    own rect, so the inter-card gap is the bare 12 px token)
      // The section → progress gap is NOT asserted: the section title is
      // the only block whose height depends on glyph metrics (it wraps to
      // two lines in the test font), so the exact value is a font fact,
      // not a layout fact.
      expect(section.top - hearts.bottom, closeTo(NestSpacing.s4, 1));
      expect(
        progress.top - section.bottom,
        greaterThanOrEqualTo(NestSpacing.s4),
        reason: 'the progress bar never rides up into the section header',
      );
      expect(card1.top - progress.bottom, closeTo(NestSpacing.s4, 1));
      expect(card2.top - card1.bottom, closeTo(NestSpacing.s3, 1));
      await disposeApp(tester);
    });

    testWidgets('the pet slot carries the design speech bubble', (
      tester,
    ) async {
      await _pumpRoute(tester);
      expect(find.text("Let's do some quests!"), findsOneWidget);
      final petStage = tester.widget<NestPetStage>(find.byType(NestPetStage));
      expect(petStage.speech, "Let's do some quests!");
      expect(petStage.pip, isA<PipAvatar>());
      await disposeApp(tester);
    });
  });

  group('K03 pet slot (explicit size)', () {
    // ORCHESTRATOR_NOTES #1 + review finding 1: the slot is the design's own
    // composition — a 260 px nest with a 152 px Pip — expressed through the
    // shared `NestPetStage` explicit size mode (SHARED_REQUEST #11), never a
    // feature-local scene fork. Sizes only: centring is K03-BUG-13's proof.
    testWidgets('the nest is 260 wide and the Pip exactly 152 tall', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final stage = tester.widget<NestPetStage>(find.byType(NestPetStage));
      expect(stage.nestWidth, 260, reason: '.k3-pet .nest is 260 px wide');
      expect(stage.fixedPipHeight, 152, reason: '.k3-pet .pip is 152 px tall');
      final fallback = tester.widget<PipNestFallback>(
        find.byType(PipNestFallback),
      );
      expect(fallback.nestW, 260);
      expect(fallback.pipH, 152);
      // Rendered shapes, not only the props: the previous derived sizing
      // rendered a 217 px nest with a 119 px Pip on this very viewport.
      final pip = tester.getRect(find.byType(PipAvatar));
      expect(pip.width, closeTo(152, 0.5));
      expect(pip.height, closeTo(152, 0.5));
      // The fallback paints the nest twice (back + front rim), same 260 width.
      expect(_nestSvgFinder(), findsNWidgets(2));
      final nest = tester.getRect(_nestSvgFinder().first);
      expect(nest.width, closeTo(260, 0.5));
      await disposeApp(tester);
    });

    testWidgets('the slot box keeps the 20 px gutters', (tester) async {
      await _pumpRoute(tester);
      final slot = tester.getRect(find.byType(PipNestFallback));
      expect(slot.left, closeTo(NestSpacing.padSide, 0.5));
      expect(slot.right, closeTo(NestDevice.width - NestSpacing.padSide, 0.5));
      await disposeApp(tester);
    });
  });

  group('K03 typography (NestType, zero tracking)', () {
    // The K03 CSS sets no `letter-spacing` anywhere, and main fd92d95 made
    // NestType default to 0, so every string on this screen must render in a
    // shared NestType style with no tracking — Material's default must not
    // creep back in. Sizes/weights are the design's own
    // (.k3-name 22/26 w900, .k3-sub + .kcap 15/20 w700, .kchip 15/15 w800,
    // .kid-title 28/34 w900, .speech 16 w800).
    testWidgets('every K03 string uses the shared kid styles with tracking 0', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final expected = <String, (double, double, FontWeight)>{
        'Hi Maya!': (22, 26 / 22, FontWeight.w900), // .k3-name
        '4 done today': (15, 20 / 15, FontWeight.w700), // .k3-sub
        'Pip is happy today': (15, 20 / 15, FontWeight.w700), // .kcap
        "Today's quests": (28, 34 / 28, FontWeight.w900), // .kid-title
        '4 of 6 done': (15, 15 / 15, FontWeight.w800), // .kchip
        "Let's do some quests!": (16, 24 / 16, FontWeight.w800), // .speech
        '120': (16, 16 / 16, FontWeight.w800), // .coin-pill
      };
      for (final MapEntry(key: text, value: spec) in expected.entries) {
        final finder = find.text(text);
        expect(finder, findsOneWidget, reason: 'copy: $text');
        final style = tester.widget<Text>(finder).style!;
        final (size, height, weight) = spec;
        expect(style.fontSize, size, reason: 'font size: $text');
        expect(style.height, closeTo(height, 0.001), reason: 'line box: $text');
        expect(style.fontWeight, weight, reason: 'weight: $text');
        expect(
          style.letterSpacing ?? 0,
          0,
          reason: '$text must carry no tracking (design sets none)',
        );
      }
      // The shared styles, not a screen-local fork (review finding 3): the
      // kid styles now exist in the type scale.
      expect(NestType.kidName().fontSize, 22);
      expect(NestType.kidCaption().fontSize, 15);
      expect(NestType.kidTitle().fontSize, 28);
      expect(NestType.kidChipLabel().fontSize, 15);
      await disposeApp(tester);
    });
  });

  group('K03 meadow band', () {
    // 5_ui.md finding 1 (dark-only FAIL driver): the band behind progress +
    // cards must grade from `kidHorizon` at its top toward the meadow tone —
    // in BOTH themes, or dark renders a flat navy block.
    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];
    for (final (themeName, theme) in themes) {
      testWidgets('$themeName: the band grades horizon → meadow', (
        tester,
      ) async {
        await _pumpRoute(tester, theme: theme);
        await _revealCards(tester);
        final tokens = Theme.of(tester.element(find.byType(NestProgress)))
            .extension<NestTokens>()!;
        // `_MeadowPainter` is feature-private, so its fields cannot be named
        // from the test library; reading them through `dynamic` is the only
        // way to pin the gradient the screen actually paints.
        final painter = tester.widget<CustomPaint>(_meadowBandFinder()).painter;
        final top = (painter! as dynamic).top as Color;
        final bottom = (painter as dynamic).bottom as Color;
        expect(
          top,
          tokens.kidHorizon,
          reason: 'the band starts at the horizon tone',
        );
        expect(
          bottom,
          Color.lerp(tokens.kidHorizon, tokens.kidMeadow, 0.5),
          reason: 'the band must grade toward the meadow tone, not stay flat',
        );
        // Full-bleed horizontally, behind progress and the card column.
        final bandRect = tester.getRect(_meadowBandFinder());
        expect(bandRect.left, 0);
        expect(bandRect.right, closeTo(NestDevice.width, 0.5));
        expect(
          bandRect.top,
          lessThan(tester.getRect(find.byType(NestProgress)).top),
        );
        expect(
          bandRect.bottom,
          greaterThan(tester.getRect(find.byType(NestKidQuestCard).first).top),
        );
        await disposeApp(tester);
      });
    }
  });

  group('K03 shapes (pills and rects, not just text)', () {
    // Orchestrator rule: a UI check compares the visible BACKGROUND/BORDER
    // rect, not only where the text lands.
    testWidgets('the section chip is a 32 px leaf-tint pill', (tester) async {
      await _pumpRoute(tester);
      final chip = find.ancestor(
        of: find.text('4 of 6 done'),
        matching: find.byType(KidStatusChip),
      );
      final rect = tester.getRect(chip);
      expect(rect.height, closeTo(32, 0.5), reason: '.kchip is 32 px tall');
      final container = tester.widget<Container>(
        find.descendant(of: chip, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final tokens = Theme.of(tester.element(find.byType(NestProgress)))
          .extension<NestTokens>()!;
      expect(decoration.color, tokens.leafTint, reason: '.kchip background');
      expect(
        decoration.borderRadius,
        NestRadii.allPill,
        reason: '.kchip is a pill',
      );
      // The 12 px horizontal padding keeps the label off the pill edge.
      expect(
        rect.left,
        closeTo(
          tester.getRect(find.text('4 of 6 done')).left - NestSpacing.s3,
          0.5,
        ),
      );
      await disposeApp(tester);
    });

    testWidgets('the card tile is 48 px and the check a 56 px ink circle', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await _revealCards(tester);
      final card = find.byType(NestKidQuestCard).first;
      // `.quest-card.kid .kid-icon`: 48×48, radius 16.
      final tile = find.descendant(
        of: card,
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) {
            return false;
          }
          final box = widget.decoration;
          return box is BoxDecoration &&
              box.borderRadius == BorderRadius.circular(16);
        }),
      );
      expect(tile, findsOneWidget);
      expect(tester.getSize(tile), const Size(48, 48));
      // `.quest-check`: 56×56. The first demo card is already done, so read a
      // to-do quest's check node (`.quest-card.kid .quest-check`).
      final check = find.bySemanticsLabel('Mark done');
      expect(check, findsWidgets);
      expect(tester.getSize(check.first), const Size(56, 56));
      await disposeApp(tester);
    });
  });

  group('K03 iteration-7 chrome', () {
    // Review finding 4 + the BALANCED HEADINGS rule: the section heading is
    // `<h2 class="kid-title">`, and the CSS balances that class, so it must
    // render through `NestBalancedText` — same copy, style and maxLines, with
    // the design's line breaking. Body/caption copy must NOT use it.
    testWidgets('the .kid-title heading renders through NestBalancedText', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final balanced = tester.widget<NestBalancedText>(
        find.byType(NestBalancedText),
      );
      expect(balanced.text, "Today's quests");
      expect(balanced.style.fontSize, 28, reason: '.kid-title is 28 px');
      expect(balanced.style.fontWeight, FontWeight.w900);
      expect(balanced.maxLines, 2);
      expect(balanced.textAlign, TextAlign.start);
      expect(balanced.style.letterSpacing ?? 0, 0);
      // The copy is unchanged and still sits on the left gutter.
      expect(find.text("Today's quests"), findsOneWidget);
      expect(
        tester.getRect(find.byType(NestBalancedText)).left,
        closeTo(NestSpacing.padSide, 0.5),
      );
      // Exactly one balanced heading on the screen: no body/caption copy was
      // switched over (the rule forbids it there).
      expect(find.byType(NestBalancedText), findsOneWidget);
      await disposeApp(tester);
    });

    // Review finding 5 / SHARED_REQUEST #9 (`NestKidButton.wrapLabel`): the
    // dock labels must never wrap, so the three buttons keep equal heights at
    // every supported width and text scale. Iteration 5 could not compare the
    // heights because the fallback test font wrapped "My jar" (80 vs 72 px).
    for (final (width, scale) in <(double, double)>[
      (320, 1),
      (390, 1.3),
      (320, 1.3),
      (430, 1),
    ]) {
      testWidgets(
        'dock labels stay on one line at ${width.toInt()}px / ${scale}x',
        (tester) async {
          await _pumpRoute(tester, width: width, textScale: scale);
          final buttons = <Rect>[
            for (var i = 0; i < 3; i++)
              tester.getRect(find.byType(NestKidButton).at(i)),
          ];
          expect(
            buttons[1].height,
            closeTo(buttons[0].height, 0.5),
            reason: 'the middle button must not wrap and grow',
          );
          expect(
            buttons[2].height,
            closeTo(buttons[0].height, 0.5),
            reason: '"My jar" must not wrap and grow',
          );
          for (final label in <String>['Pip', 'Shop', 'My jar']) {
            final text = tester.widget<Text>(
              find.descendant(
                of: find.byType(NestKidButton),
                matching: find.text(label),
              ),
            );
            expect(text.maxLines, 1, reason: '$label stays on one line');
            expect(text.softWrap, isFalse, reason: '$label never soft-wraps');
          }
          expect(tester.takeException(), isNull);
          await disposeApp(tester);
        },
      );
    }

    testWidgets('the dock does not grow when the viewport narrows', (
      tester,
    ) async {
      await _pumpRoute(tester, width: 430);
      final wide = tester.getRect(_dockSurfaceFinder()).height;
      await disposeApp(tester);
      await _pumpRoute(tester, width: 320);
      final narrow = tester.getRect(_dockSurfaceFinder()).height;
      expect(
        narrow,
        closeTo(wide, 0.5),
        reason: 'a wrapped label would make the dock taller on the narrow slot',
      );
      await disposeApp(tester);
    });

    // Review finding 5 / SHARED_REQUEST #1 (`tileBackground`): the design tints
    // each quest's icon tile (`.quest-card.kid .kid-icon`), and the shared card
    // falls back to `surface2` when the screen passes no tint.
    testWidgets('quest tiles carry the design per-quest tint', (tester) async {
      await _pumpRoute(tester);
      final tokens = Theme.of(tester.element(find.byType(NestProgress)))
          .extension<NestTokens>()!;
      final expected = <String, Color>{
        'Empty the dishwasher': tokens.skyTint, // --sky-tint
        'Reading – 20 minutes': tokens.lilacTint, // --lilac-tint
        'Tidy your bedroom': tokens.peachTint, // --peach-tint
        'Hoover the stairs': tokens.surface2, // unmapped icon → neutral tile
      };
      for (final MapEntry(key: title, value: tint) in expected.entries) {
        final tile = _questTile(tester, title);
        final decoration = tester.widget<Container>(tile).decoration!;
        expect(
          (decoration as BoxDecoration).color,
          tint,
          reason: 'tile tint for "$title"',
        );
        expect(tester.getSize(tile), const Size(48, 48));
      }
      await disposeApp(tester);
    });

    // Review finding 8: the design puts `margin-left:2px` on the hearts
    // caption, so the gap after the fifth heart is the row's 8 px plus 2 px.
    testWidgets('the hearts caption keeps the design 10 px gap', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final lastHeart = tester.getRect(find.byType(NestHeart).last);
      final caption = tester.getRect(find.text('Pip is happy today'));
      expect(
        caption.left - lastHeart.right,
        closeTo(NestSpacing.s2 + NestSpacing.gap2, 0.5),
        reason: '.k3-hearts gap 8 + the caption 2 px inset',
      );
      await disposeApp(tester);
    });
  });

  group('K03 states', () {
    testWidgets('light: no active child offers the picker', (tester) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pumpRoute(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.byType(NestKidQuestCard), findsNothing);
      expect(find.byType(NestLockButton), findsOneWidget);
      await tester.tap(find.text('Choose'));
      await _settleRoute(tester);
      expect(find.text('K01 Who is playing'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('dark: no active child offers the picker', (tester) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pumpRoute(tester, theme: ThemeMode.dark);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.byType(NestKidQuestCard), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a child with no quests shows the gentle empty state', (
      tester,
    ) async {
      await _addQuestlessChild(tester, id: 'nina', nickname: 'Nina');
      await _pumpRoute(tester);
      expect(find.text('Hi Nina!'), findsOneWidget);
      expect(find.text('0 done today'), findsOneWidget);
      expect(find.text('No quests today'), findsOneWidget);
      expect(find.text('Enjoy playing with Pip!'), findsOneWidget);
      expect(find.byType(NestKidQuestCard), findsNothing);
      // The dock stays usable when there is nothing to do.
      expect(find.text('Pip'), findsOneWidget);
      expect(find.text('My jar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];

    for (final (String themeName, ThemeMode theme) in themes) {
      testWidgets('$themeName: silent streams keep the loading state', (
        tester,
      ) async {
        await _useFakeRepository(_FakeKidHomeRepository(hang: true));
        final semantics = tester.ensureSemantics();
        await _pumpRoute(tester, theme: theme);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.bySemanticsLabel('Loading your quests'), findsOneWidget);
        expect(find.byType(NestKidQuestCard), findsNothing);
        expect(tester.takeException(), isNull);
        semantics.dispose();
        await disposeApp(tester);
      });

      testWidgets('$themeName: load failure retries into the loaded home', (
        tester,
      ) async {
        final repo = _FakeKidHomeRepository(failLoad: true);
        await _useFakeRepository(repo);
        await _pumpRoute(tester, theme: theme);
        expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
        expect(find.text("Let's try again."), findsOneWidget);
        expect(find.byType(NestKidQuestCard), findsNothing);
        repo.failLoad = false;
        await tester.tap(find.text('Try again'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Hi Maya!'), findsOneWidget);
        expect(find.byType(NestKidQuestCard), findsNWidgets(6));
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }

    testWidgets('a failed completion keeps the list and shows the snack bar', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failComplete: true);
      await _useFakeRepository(repo);
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      expect(find.text('Hmm, that did not work. Try again.'), findsOneWidget);
      // A failed write never celebrates (K03-BUG-2).
      expect(find.text('K05 Quest complete'), findsNothing);
      expect(repo.completed, <List<String>>[
        <String>['maya', 'q-reading'],
      ]);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K03 grown-ups lock (every kid state)', () {
    // DESIGN_SPEC §5 Group C: "Top-right on every kid screen: small lock
    // button that leads to P17" (review finding 11).
    testWidgets('loaded home: the lock opens the parental gate', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await _settleRoute(tester);
      expect(find.text('P17 Parental gate'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('no active child: the lock still opens the parental gate', (
      tester,
    ) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await _settleRoute(tester);
      expect(find.text('P17 Parental gate'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('failure state: the lock still opens the parental gate', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failLoad: true);
      await _useFakeRepository(repo);
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await _settleRoute(tester);
      expect(find.text('P17 Parental gate'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('loading state: the lock is reachable and opens the gate', (
      tester,
    ) async {
      await _useFakeRepository(_FakeKidHomeRepository(hang: true));
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await _settleRoute(tester);
      expect(find.text('P17 Parental gate'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K03 Pip (orchestrator mandate)', () {
    testWidgets("the pet slot renders the child's own PipAvatar", (
      tester,
    ) async {
      await _pumpRoute(tester);
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      expect(avatar.accessory, PipAccessory.none);
      expect(avatar.stage, 3);
      // The shared slot sizes the avatar: design cap 152, scaled by width.
      final slot = tester.widget<NestPetStage>(find.byType(NestPetStage));
      expect(slot.pipSize, 152);
      expect(_v1PipAssets(tester), isEmpty);
      await disposeApp(tester);
    });

    testWidgets("the active child's database look drives PipAvatar (Leo)", (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      expect(find.text('Hi Leo!'), findsOneWidget);
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.bolt);
      expect(avatar.skin, PipSkin.sky);
      expect(avatar.accessory, PipAccessory.none);
      expect(avatar.stage, 2);
      expect(_v1PipAssets(tester), isEmpty);
      await disposeApp(tester);
    });

    testWidgets("the empty-quests state shows the child's own Pip", (
      tester,
    ) async {
      await _addQuestlessChild(tester, id: 'nina', nickname: 'Nina');
      await _pumpRoute(tester);
      expect(find.text('No quests today'), findsOneWidget);
      expect(find.byType(PipAvatar), findsOneWidget);
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      expect(avatar.stage, 1);
      expect(_v1PipAssets(tester), isEmpty);
      await disposeApp(tester);
    });

    testWidgets('no product state renders the v1 pip_stage_*.svg art', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failLoad: true);
      await _useFakeRepository(repo);
      await _pumpRoute(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(_v1PipAssets(tester), isEmpty);
      await disposeApp(tester);
    });

    testWidgets('an accessorised child drives the full look mapping', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'ali',
                familyId: Seed.familyId,
                nickname: 'Ali',
                pipStyle: const Value('storybook'),
                pipSkin: const Value('mint'),
                pipAccessory: const Value('scarf'),
                pipStage: const Value(4),
              ),
            );
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('ali')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.storybook);
      expect(avatar.skin, PipSkin.mint);
      expect(avatar.accessory, PipAccessory.scarf);
      expect(avatar.stage, 4);
      expect(_v1PipAssets(tester), isEmpty);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the pet slot announces the child stage, not a generic label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      // Review finding 12: the alt text carries the growth stage, so a
      // screen reader never hears a bare "mascot".
      expect(
        tester.getSemantics(find.byType(NestPetStage)).label,
        contains('Pip the Fledgling, stage 3 of 4'),
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets(
      'the stage name follows the active child (Leo is a hatchling)',
      (tester) async {
        final db = GetIt.instance<AppDatabase>();
        await tester.runAsync(() async {
          await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
            const AppStateCompanion(activeChildId: Value<String?>('leo')),
          );
          await GetIt.instance<AppSession>().refresh();
        });
        final semantics = tester.ensureSemantics();
        await _pumpRoute(tester);
        expect(find.text('Hi Leo!'), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(NestPetStage)).label,
          contains('Pip the Hatchling, stage 2 of 4'),
        );
        semantics.dispose();
        await disposeApp(tester);
      },
    );

    testWidgets('hearts mirror happiness and clamp to 0..5', (tester) async {
      await _pumpRoute(tester);
      expect(find.byType(NestHeart), findsNWidgets(5));
      // Maya: happiness 4 → four filled, one outline.
      expect(
        <bool>[
          for (var i = 0; i < 5; i++)
            tester.widget<NestHeart>(find.byType(NestHeart).at(i)).filled,
        ],
        <bool>[true, true, true, true, false],
      );

      final db = GetIt.instance<AppDatabase>();
      Future<void> setHappiness(int value) async {
        await tester.runAsync(() async {
          await (db.update(db.children)..where((c) => c.id.equals('maya')))
              .write(ChildrenCompanion(happiness: Value(value)));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }

      await setHappiness(0);
      expect(
        <bool>[
          for (var i = 0; i < 5; i++)
            tester.widget<NestHeart>(find.byType(NestHeart).at(i)).filled,
        ],
        <bool>[false, false, false, false, false],
        reason: 'happiness 0 fills nothing and never frames Pip negatively',
      );
      await setHappiness(9);
      expect(
        <bool>[
          for (var i = 0; i < 5; i++)
            tester.widget<NestHeart>(find.byType(NestHeart).at(i)).filled,
        ],
        <bool>[true, true, true, true, true],
        reason: 'happiness above 5 clamps to five hearts',
      );
      await disposeApp(tester);
    });
  });

  group('K03 periods (PERIODS ruling)', () {
    /// Replaces every completion with one for [questId] at [at].
    Future<void> seedCompletion(
      WidgetTester tester, {
      required String questId,
      required String status,
      required DateTime at,
      int coins = 10,
    }) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db.delete(db.questCompletions).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: questId,
                childId: 'maya',
                familyId: Seed.familyId,
                status: Value(status),
                coins: Value(coins),
                createdAt: Value(at),
                decidedAt: Value(at),
              ),
            );
      });
    }

    /// Moves the completion for [questId] to [at] and pumps the emission.
    Future<void> moveCompletion(
      WidgetTester tester,
      String questId,
      DateTime at,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(
          db.questCompletions,
        )..where((c) => c.questId.equals(questId))).write(
          QuestCompletionsCompanion(createdAt: Value(at), decidedAt: Value(at)),
        );
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('daily: before the London day start reads to do again', (
      tester,
    ) async {
      final now = DateTime.now().toUtc();
      final dayStart = londonDayStartUtc(now);
      await seedCompletion(
        tester,
        questId: 'q-reading',
        status: 'approved',
        at: dayStart.subtract(const Duration(minutes: 1)),
      );
      await _pumpRoute(tester);
      expect(find.text('0 done today'), findsOneWidget);
      await _revealCards(tester);
      final card = find.ancestor(
        of: find.text('Reading – 20 minutes'),
        matching: find.byType(NestKidQuestCard),
      );
      expect(
        find.descendant(of: card, matching: find.text('Done')),
        findsNothing,
      );
      // The to-do rendering is the coin pill, not a status chip.
      expect(
        find.descendant(of: card, matching: find.text('+10')),
        findsOneWidget,
      );
      // Move the completion inside today's London day: it counts again.
      await moveCompletion(tester, 'q-reading', now);
      expect(find.text('1 done today'), findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('Done')),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets("weekly: last week's completion reads to do again", (
      tester,
    ) async {
      final now = DateTime.now().toUtc();
      final weekStart = londonWeekStartUtc(now);
      await seedCompletion(
        tester,
        questId: 'q-bins',
        status: 'approved',
        at: weekStart.subtract(const Duration(minutes: 1)),
        coins: 15,
      );
      await _pumpRoute(tester);
      expect(find.text('0 done today'), findsOneWidget);
      await _revealCards(tester);
      final card = find.ancestor(
        of: find.text('Put the bins out'),
        matching: find.byType(NestKidQuestCard),
      );
      expect(
        find.descendant(of: card, matching: find.text('Done')),
        findsNothing,
      );
      // Inside this London week (Mon 00:00) it counts.
      await moveCompletion(
        tester,
        'q-bins',
        weekStart.add(const Duration(minutes: 1)),
      );
      expect(
        find.descendant(of: card, matching: find.text('Done')),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('once: a completion from long ago still counts', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db
            .into(db.quests)
            .insert(
              QuestsCompanion.insert(
                id: 'q-once',
                familyId: Seed.familyId,
                title: 'Old one-off quest',
                coins: const Value(5),
                assigneeChildId: const Value('maya'),
              ),
            );
        await db.delete(db.questCompletions).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-once',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('approved'),
                coins: const Value(5),
                createdAt: Value(
                  DateTime.now().toUtc().subtract(const Duration(days: 400)),
                ),
              ),
            );
      });
      await _pumpRoute(tester);
      expect(find.text('1 done today'), findsOneWidget);
      await _revealCards(tester);
      final card = find.ancestor(
        of: find.text('Old one-off quest'),
        matching: find.byType(NestKidQuestCard),
      );
      expect(
        find.descendant(of: card, matching: find.text('Done')),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('a period-expired daily quest starts a fresh completion', (
      tester,
    ) async {
      final now = DateTime.now().toUtc();
      final dayStart = londonDayStartUtc(now);
      await seedCompletion(
        tester,
        questId: 'q-reading',
        status: 'approved',
        at: dayStart.subtract(const Duration(minutes: 1)),
      );
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      await _revealCards(tester);
      final card = find.ancestor(
        of: find.text('Reading – 20 minutes'),
        matching: find.byType(NestKidQuestCard),
      );
      final check = find.descendant(
        of: card,
        matching: find.bySemanticsLabel('Mark done'),
      );
      expect(check, findsOneWidget);
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      // The new completion celebrates, so the home is offstage until back.
      expect(find.text('K05 Quest complete'), findsOneWidget);
      await tester.pageBack();
      await _settleRoute(tester);
      expect(
        find.descendant(of: card, matching: find.text('Waiting for Mum')),
        findsOneWidget,
      );
      expect(find.text('1 done today'), findsOneWidget);
      // The old out-of-period row is untouched; a fresh one carries the tap.
      final rows = await tester.runAsync(() async {
        final db = GetIt.instance<AppDatabase>();
        final query = db.select(db.questCompletions)
          ..where((c) => c.questId.equals('q-reading'));
        return await query.get();
      });
      expect(rows, hasLength(2));
      expect(rows!.map((row) => row.status).toSet(), <String>{
        'approved',
        'done_pending',
      });
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K03 bottom edge (owner rules)', () {
    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];

    testWidgets('gutters align on both edges and the dock matches the cards', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await _revealCards(tester);
      const gutter = NestSpacing.padSide;
      const gap = NestSpacing.s3;
      // Header: avatar on the left gutter, lock on the right one.
      expect(
        tester.getRect(find.byType(NestAvatar)).left,
        closeTo(gutter, 0.5),
      );
      expect(
        tester.getRect(find.byType(NestLockButton)).right,
        closeTo(NestDevice.width - gutter, 0.5),
      );
      // Quest cards, progress bar and section chip share the same edges.
      final card = tester.getRect(find.byType(NestKidQuestCard).first);
      expect(card.left, closeTo(gutter, 0.5));
      expect(card.right, closeTo(NestDevice.width - gutter, 0.5));
      expect(
        tester.getRect(find.byType(NestProgress)).left,
        closeTo(gutter, 0.5),
      );
      expect(
        tester.getRect(find.byType(NestProgress)).right,
        closeTo(NestDevice.width - gutter, 0.5),
      );
      expect(
        tester
            .getRect(
              find.ancestor(
                of: find.text('4 of 6 done'),
                matching: find.byType(KidStatusChip),
              ),
            )
            .right,
        closeTo(NestDevice.width - gutter, 0.5),
      );
      // Dock: three equal buttons, outer edges on the card edges, 12 gaps.
      final buttons = <Rect>[
        for (var i = 0; i < 3; i++)
          tester.getRect(find.byType(NestKidButton).at(i)),
      ];
      expect(buttons.first.left, closeTo(gutter, 0.5));
      expect(buttons.last.right, closeTo(NestDevice.width - gutter, 0.5));
      expect(buttons[1].left - buttons[0].right, closeTo(gap, 0.5));
      expect(buttons[2].left - buttons[1].right, closeTo(gap, 0.5));
      expect(buttons[0].width, closeTo(buttons[1].width, 0.5));
      expect(buttons[1].width, closeTo(buttons[2].width, 0.5));
      await disposeApp(tester);
    });

    testWidgets('the bar spans the full width to the edge and the buttons stay '
        'above the inset', (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
      await _pumpRoute(tester);
      final bar = tester.getRect(_dockSurfaceFinder());
      expect(bar.left, 0);
      expect(bar.right, NestDevice.width);
      expect(bar.bottom, NestDevice.height);
      // The bar runs to the edge; its content does not slide under the OS
      // home indicator.
      expect(
        tester.getRect(find.byType(NestKidButton).first).bottom,
        lessThanOrEqualTo(NestDevice.height - 34),
      );
      await disposeApp(tester);
    });

    testWidgets('430px: the bar still runs to the edge with an inset', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
      await _pumpRoute(tester, width: 430);
      final bar = tester.getRect(_dockSurfaceFinder());
      expect(bar.left, 0);
      expect(bar.right, 430);
      expect(bar.bottom, NestDevice.height);
      expect(
        tester.getRect(find.byType(NestKidQuestCard).first).left,
        closeTo(NestSpacing.padSide, 0.5),
      );
      await disposeApp(tester);
    });

    testWidgets(
      'a top inset reserves the status bar and leaves the bar intact',
      (tester) async {
        // iPhone-like insets: 59 top, 34 bottom (physical px at 3x).
        tester.view.viewPadding = const FakeViewPadding(
          top: 59 * 3,
          bottom: 34 * 3,
        );
        tester.view.padding = const FakeViewPadding(
          top: 59 * 3,
          bottom: 34 * 3,
        );
        await _pumpRoute(tester);
        // STATUS BAR rule: the widget only reserves height; content starts
        // below the OS inset.
        expect(
          tester.getRect(find.byType(NestAvatar)).top,
          greaterThanOrEqualTo(59),
        );
        // BOTTOM EDGE rule is unaffected by the top inset.
        expect(tester.getRect(_dockSurfaceFinder()).bottom, NestDevice.height);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );

    for (final (themeName, theme) in themes) {
      testWidgets('$themeName: the dock owns the OS bottom inset', (
        tester,
      ) async {
        // A 34 px system inset (physical px at 3x) must lift the chrome.
        tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
        await _pumpRoute(tester, theme: theme);
        final safeArea = find
            .ancestor(of: find.text('Pip'), matching: find.byType(SafeArea))
            .first;
        expect(tester.widget<SafeArea>(safeArea).top, isFalse);
        // The OS draws the home pill: the shared indicator reserves nothing.
        expect(tester.getSize(find.byType(NestHomeIndicator)), Size.zero);
        // OWNER RULE (bottom edge): the bar's surface runs to the physical
        // screen edge — no meadow strip under the dock or home indicator.
        final dock = _dockSurfaceFinder();
        expect(dock, findsOneWidget);
        expect(
          tester.getRect(dock).bottom,
          closeTo(844, 0.5),
          reason: 'the dock surface must cover the OS inset to the edge',
        );
        final insetTop = tester.getRect(find.byType(NestKidButton).first).top;
        // Without the inset the dock sits exactly 34 px lower.
        tester.view.resetPadding();
        await tester.pump();
        final noInsetTop = tester.getRect(find.byType(NestKidButton).first).top;
        expect(noInsetTop - insetTop, closeTo(34, 0.5));
        // The chrome still reaches the bottom edge; the inset sits below it.
        expect(tester.getRect(safeArea).bottom, closeTo(844, 0.5));
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  });

  group('K03 navigation', () {
    testWidgets('card tap opens quest detail with questId + childId', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final card = find.text('Reading – 20 minutes');
      await tester.ensureVisible(card);
      await tester.pump();
      await tester.tap(card);
      await _settleRoute(tester);
      expect(find.text('K04 Quest detail'), findsOneWidget);
      final state = GoRouter.of(tester.element(find.text('K04 Quest detail')))
          .state;
      expect(state.uri.path, '/quest-detail');
      final extra = state.extra! as Map<String, Object?>;
      expect(extra['questId'], 'q-reading');
      expect(extra['childId'], 'maya');
      await disposeApp(tester);
    });

    testWidgets('check tap completes, persists and opens the celebration', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      final state = GoRouter.of(tester.element(find.text('K05 Quest complete')))
          .state;
      expect(state.uri.path, '/quest-complete');
      final extra = state.extra! as Map<String, Object?>;
      expect(extra['questId'], 'q-reading');
      expect(extra['childId'], 'maya');
      expect(extra['coins'], 10);
      // The tap persisted a done_pending completion in the database.
      final items = await tester.runAsync(
        () => GetIt.instance<KidHomeRepository>().getItems(),
      );
      expect(
        items!.singleWhere((quest) => quest.questId == 'q-reading').status,
        'done_pending',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('done check falls through to detail and never re-completes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final card = find.ancestor(
        of: find.text('Empty the dishwasher'),
        matching: find.byType(NestKidQuestCard),
      );
      await tester.ensureVisible(card);
      await tester.pump();
      // The done check is display-only (excluded from semantics by the
      // shared card contract): tap its centre — card padding 12 plus half
      // of the 56 check — and verify the tap falls through to the card.
      final cardRect = tester.getRect(card);
      await tester.tapAt(
        Offset(
          cardRect.right - NestSpacing.s3 - NestDevice.tapKid / 2,
          cardRect.center.dy,
        ),
      );
      await _settleRoute(tester);
      // No completion action on the check; the card beneath opens detail
      // and the pending-approval count is untouched.
      expect(find.text('K04 Quest detail'), findsOneWidget);
      final pending = await tester.runAsync(
        () => GetIt.instance<AppDatabase>()
            .watchPendingApprovals(Seed.familyId)
            .first,
      );
      expect(pending, hasLength(3));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('double-tapping the check completes once', (tester) async {
      final repo = _FakeKidHomeRepository();
      await _useFakeRepository(repo);
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      // Two taps inside one frame: the tap guard must swallow the second.
      await tester.tap(check);
      await tester.tap(check);
      await _settleRoute(tester);
      expect(repo.completed, hasLength(1));
      expect(find.text('K05 Quest complete'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a failed check tap can be retried and then celebrates', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failComplete: true);
      await _useFakeRepository(repo);
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      expect(find.text('Hmm, that did not work. Try again.'), findsOneWidget);
      expect(find.text('K05 Quest complete'), findsNothing);
      // Let the SnackBar go, then retry the same check: the failure reset
      // must release the tap guard.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      repo.failComplete = false;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      expect(repo.completed, hasLength(2));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('lock opens the parental gate', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('P17 Parental gate'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('dock Pip opens /pip', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.text('Pip'));
      await _settleRoute(tester);
      expect(find.text('K06 Pip nest'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('dock Shop opens /reward-shop', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.text('Shop'));
      await _settleRoute(tester);
      expect(find.text('K08 Reward shop'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('dock My jar opens /my-jar', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.text('My jar'));
      await _settleRoute(tester);
      expect(find.text('K09 My jar'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('K03 accessibility', () {
    testWidgets('icon buttons and key labels expose kid semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      expect(find.bySemanticsLabel('120 coins'), findsOneWidget);
      expect(find.bySemanticsLabel('Hi Maya, 4 done today'), findsOneWidget);
      expect(
        find.bySemanticsLabel("4 of 6 of today's quests done"),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Pip is happy today, 4 of 5 hearts'),
        findsOneWidget,
      );
      await _revealCards(tester);
      // The two to-do checks are functional ('Mark done'); done checks
      // are display-only and excluded from semantics by the shared card
      // contract, so their status is announced at the card level
      // instead (asserted below).
      expect(find.bySemanticsLabel('Mark done'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Done'), findsNothing);
      // Card nodes merge title + status into one label (read via the merged
      // node, since `bySemanticsLabel` cannot see merged nodes). Descendant
      // texts append after the button label, so match the prefix.
      expect(
        tester.getSemantics(find.text('Empty the dishwasher')).label,
        startsWith("Empty the dishwasher, Waiting for Mum's thumbs-up"),
      );
      expect(
        tester.getSemantics(find.text('Put the bins out')).label,
        startsWith('Put the bins out, Done'),
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('kid tap targets meet the 56 minimum', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      _expectAtLeast(
        tester,
        find.byType(NestLockButton),
        NestDevice.tapKid,
        'lock button',
      );
      await _revealCards(tester);
      _expectAtLeast(
        tester,
        find.bySemanticsLabel('Mark done').first,
        NestDevice.tapKid,
        'to-do check',
      );
      final dockButtons = find.byType(NestKidButton).evaluate().length;
      expect(dockButtons, 3);
      for (var i = 0; i < dockButtons; i++) {
        _expectAtLeast(
          tester,
          find.byType(NestKidButton).at(i),
          NestDevice.tapKid,
          'dock button $i',
        );
      }
      final cards = find.byType(NestKidQuestCard).evaluate().length;
      expect(cards, 6);
      for (var i = 0; i < cards; i++) {
        _expectAtLeast(
          tester,
          find.byType(NestKidQuestCard).at(i),
          NestDevice.tapKid,
          'quest card row $i',
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('320px at 1.3 scale keeps lock and progress semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester, width: 320, textScale: 1.3);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('Pip'), findsOneWidget);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      expect(
        find.bySemanticsLabel("4 of 6 of today's quests done"),
        findsOneWidget,
      );
      await _revealCards(tester);
      expect(find.byType(NestKidQuestCard), findsNWidgets(6));
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });
  });
}
