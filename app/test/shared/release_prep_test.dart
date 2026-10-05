// Shared release_prep (no backend, on-device only) — contract tests for the
// six release-blocking fixes in docs/PRODUCTION_CHECKLIST.md:
//
// 1. Delete family account (repository + router location, never placeholder
//    view copy — screen agents own the views).
// 2. Download our data (repository-level JSON content + mocked share call).
// 3. Privacy notice + terms links (constants + injected launcher, then one
//    widget tap per control proving the tap action reaches the launcher with
//    the right URL).
// 4. Logging guards are structural (kDebugMode) — covered by inspection +
//    `flutter analyze`; messages carry no names, emails or PINs.
// 5. Notification defaults OFF for new families (DDL default + explicit
//    first-row writes); `Seed.demo` keeps the P16 design's checked toggles.
// 6. `FamilyRepositoryImpl` uses `appNowUtc()` (no `DateTime.now()` in app
//    code — the CLOCK rule; pinned by `test/flutter_test_config.dart`).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/config/legal_links.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/settings/data/family_data_export.dart';
import 'package:nestling/features/settings/data/settings_repository_impl.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../test_scope.dart';

void main() {
  group('release_prep legal links', () {
    tearDown(() {
      LegalLinks.launcherOverride = null;
    });

    test('both URLs live in one constants file', () {
      expect(LegalLinks.privacyUrl, 'https://getnestling.co.uk/privacy');
      expect(LegalLinks.termsUrl, 'https://getnestling.co.uk/terms');
      expect(LegalLinks.privacyUri, Uri.parse(LegalLinks.privacyUrl));
      expect(LegalLinks.termsUri, Uri.parse(LegalLinks.termsUrl));
    });

    test(
      'openPrivacy calls the launcher with the privacy URL in-app',
      () async {
        Uri? seenUrl;
        LaunchMode? seenMode;
        await LegalLinks.openPrivacy(
          launcher: (url, {required mode}) async {
            seenUrl = url;
            seenMode = mode;
            return true;
          },
        );

        expect(seenUrl, Uri.parse('https://getnestling.co.uk/privacy'));
        expect(seenMode, LaunchMode.inAppBrowserView);
      },
    );

    test('openTerms calls the launcher with the terms URL in-app', () async {
      Uri? seenUrl;
      LaunchMode? seenMode;
      await LegalLinks.openTerms(
        launcher: (url, {required mode}) async {
          seenUrl = url;
          seenMode = mode;
          return true;
        },
      );

      expect(seenUrl, Uri.parse('https://getnestling.co.uk/terms'));
      expect(seenMode, LaunchMode.inAppBrowserView);
    });

    test('the override seam is honoured when no launcher is passed', () async {
      final opened = <Uri>[];
      LegalLinks.launcherOverride = (url, {required mode}) async {
        expect(mode, LaunchMode.inAppBrowserView);
        opened.add(url);
        return true;
      };

      await LegalLinks.openPrivacy();
      await LegalLinks.openTerms();

      expect(opened, <Uri>[
        Uri.parse('https://getnestling.co.uk/privacy'),
        Uri.parse('https://getnestling.co.uk/terms'),
      ]);
    });

    testWidgets('P03 Terms opens the hosted terms in-app', (tester) async {
      final opened = <Uri>[];
      LegalLinks.launcherOverride = (url, {required mode}) async {
        expect(mode, LaunchMode.inAppBrowserView);
        opened.add(url);
        return true;
      };
      final handle = tester.ensureSemantics();
      await setUpTestScope(seedDemo: false);
      await pumpAppRoute(tester, '/create-account');

      // Driven as a screen reader drives it (the two overlay boxes overlap
      // where caption lines stack, so a coordinate tap can land on either).
      expect(find.semantics.byLabel('Terms'), findsOneWidget);
      tester.semantics.performAction(
        find.semantics.byLabel('Terms'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(opened, <Uri>[Uri.parse(LegalLinks.termsUrl)]);
      expect(currentPath(tester), '/create-account');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('P03 Privacy Notice opens the hosted notice in-app', (
      tester,
    ) async {
      final opened = <Uri>[];
      LegalLinks.launcherOverride = (url, {required mode}) async {
        expect(mode, LaunchMode.inAppBrowserView);
        opened.add(url);
        return true;
      };
      final handle = tester.ensureSemantics();
      await setUpTestScope(seedDemo: false);
      await pumpAppRoute(tester, '/create-account');

      expect(find.byKey(const ValueKey('p03_privacy')), findsOneWidget);
      // The label joins its words with U+00A0 (COPY rule) — match it exactly.
      const privacyLabel = 'Privacy Notice';
      expect(find.semantics.byLabel(privacyLabel), findsOneWidget);
      tester.semantics.performAction(
        find.semantics.byLabel(privacyLabel),
        SemanticsAction.tap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(opened, <Uri>[Uri.parse(LegalLinks.privacyUrl)]);
      expect(currentPath(tester), '/create-account');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('P04 modal keeps the summary and links the full notice', (
      tester,
    ) async {
      final opened = <Uri>[];
      LegalLinks.launcherOverride = (url, {required mode}) async {
        expect(mode, LaunchMode.inAppBrowserView);
        opened.add(url);
        return true;
      };
      await setUpTestScope(seedDemo: false);
      await pumpAppRoute(tester, '/privacy');

      await tester.tap(find.text('Read the full Privacy Notice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The in-app summary is unchanged (the four promise lines).
      expect(find.text('Privacy Notice'), findsWidgets);
      expect(find.text('Full privacy notice'), findsOneWidget);

      await tester.tap(find.text('Full privacy notice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(opened, <Uri>[Uri.parse(LegalLinks.privacyUrl)]);
      expect(currentPath(tester), '/privacy');

      await disposeApp(tester);
    });

    testWidgets('P07 Terms and Privacy open the hosted pages in-app', (
      tester,
    ) async {
      final opened = <Uri>[];
      LegalLinks.launcherOverride = (url, {required mode}) async {
        expect(mode, LaunchMode.inAppBrowserView);
        opened.add(url);
        return true;
      };
      await setUpTestScope();
      await pumpAppRoute(tester, '/paywall');

      await tester.tap(find.bySemanticsLabel('Terms'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.bySemanticsLabel('Privacy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(opened, <Uri>[
        Uri.parse(LegalLinks.termsUrl),
        Uri.parse(LegalLinks.privacyUrl),
      ]);
      expect(currentPath(tester), '/paywall');

      await disposeApp(tester);
    });
  });

  group('release_prep delete family account', () {
    late AppDatabase db;
    late SettingsRepository repository;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
      repository = SettingsRepositoryImpl(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('every table is empty except the fresh app_state row', () async {
      await repository.deleteFamilyAccount();

      expect(await db.select(db.families).get(), isEmpty);
      expect(await db.select(db.members).get(), isEmpty);
      expect(await db.select(db.children).get(), isEmpty);
      expect(await db.select(db.quests).get(), isEmpty);
      expect(await db.select(db.questCompletions).get(), isEmpty);
      expect(await db.select(db.ledgerEntries).get(), isEmpty);
      expect(await db.select(db.savingsGoals).get(), isEmpty);
      expect(await db.select(db.rewards).get(), isEmpty);
      expect(await db.select(db.rewardRedemptions).get(), isEmpty);
      expect(await db.select(db.badges).get(), isEmpty);
      expect(await db.select(db.earnedBadges).get(), isEmpty);
      expect(await db.select(db.pipWardrobe).get(), isEmpty);
      expect(await db.select(db.settings).get(), isEmpty);

      final state = await db.select(db.appState).getSingle();
      expect(state.onboardingComplete, isFalse);
      expect(state.appMode, 'parent');
      expect(state.subscriptionStatus, 'trial');
      expect(state.trialStart, isNull);
      expect(state.activeChildId, isNull);
    });

    test('a second launch reads a fresh install (starts at welcome)', () async {
      await repository.deleteFamilyAccount();

      // A new session on the same database — what a relaunch opens.
      final session = AppSession(db);
      await session.refresh();

      expect(session.onboardingComplete, isFalse);
      expect(session.appMode, 'parent');
      expect(session.trialExpired, isFalse);

      session.dispose();
    });
  });

  group('release_prep download our data', () {
    late AppDatabase db;
    late SettingsRepository repository;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
      repository = SettingsRepositoryImpl(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'the document carries the family data with zone + ISO timestamps',
      () async {
        final document = await repository.exportFamilyData();

        expect(
          document.keys,
          containsAll(<String>[
            'meta',
            'family',
            'members',
            'children',
            'quests',
            'completions',
            'ledger',
            'goals',
            'rewards',
            'badgesEarned',
            'settings',
          ]),
        );

        final meta = document['meta'] as Map<String, dynamic>;
        expect(meta['familyZone'], 'Europe/London');
        // Parses as a UTC instant (ISO-8601 self-description).
        expect(DateTime.parse(meta['exportedAt'] as String).isUtc, isTrue);

        final members = document['members'] as List<dynamic>;
        expect(members, hasLength(2));
        expect(
          (members.first as Map<String, dynamic>)['email'],
          'sarah@example.co.uk',
        );

        final children = document['children'] as List<dynamic>;
        expect(children, hasLength(2));
        expect(
          (children.first as Map<String, dynamic>)['coins'],
          120,
          reason: 'Maya keeps her 120 coins in the export',
        );
        for (final child in children.cast<Map<String, dynamic>>()) {
          expect(DateTime.parse(child['createdAt'] as String).isUtc, isTrue);
        }

        expect(document['quests'] as List<dynamic>, hasLength(12));
        expect(document['completions'] as List<dynamic>, isNotEmpty);
        expect(document['ledger'] as List<dynamic>, isNotEmpty);

        final goals = document['goals'] as List<dynamic>;
        expect(goals, hasLength(1));
        expect((goals.single as Map<String, dynamic>)['savedPence'], 1550);
        expect((goals.single as Map<String, dynamic>)['targetPence'], 2499);

        expect(document['rewards'] as List<dynamic>, hasLength(6));

        final badges = document['badgesEarned'] as List<dynamic>;
        expect(badges, hasLength(5));

        final settings = document['settings'] as Map<String, dynamic>;
        expect(settings['payoutDay'], 6);
        expect(settings['kidGateEnabled'], isTrue);
      },
    );

    test('no PIN hashes leave the device', () async {
      final document = await repository.exportFamilyData();

      expect(
        jsonEncode(document),
        isNot(contains('pinHash')),
        reason: 'the salted PIN hash must never appear in the export',
      );
    });

    test('the temp file name carries the date, never clock-derived ids', () {
      expect(
        exportFileName(DateTime.utc(2026, 10, 3, 8, 41)),
        'nestling-export-2026-10-03.json',
      );
    });

    test('shareExportFile calls the injected share function', () async {
      final dir = await Directory.systemTemp.createTemp('nestling-export');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/nestling-export-2026-10-03.json')
        ..writeAsStringSync('{}');

      XFile? shared;
      await shareExportFile(
        file,
        shareFn: (f) async {
          shared = f;
        },
      );

      expect(shared, isNotNull);
      expect(shared!.path, file.path);
      expect(shared!.path, contains('nestling-export-2026-10-03.json'));
    });
  });

  group('release_prep notification defaults OFF', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('a first-run database starts with notifications OFF', () async {
      final setting = await (db.select(
        db.settings,
      )..where((s) => s.familyId.equals(Seed.familyId))).getSingle();

      expect(setting.notifApprovals, isFalse);
      expect(setting.notifPayout, isFalse);
      expect(setting.notifSummary, isFalse);
      // Unrelated defaults are untouched.
      expect(setting.crashReportConsent, isFalse);
      expect(setting.kidGateEnabled, isTrue);
    });

    test(
      'Seed.empty, Seed.newFamily and Seed.onboardingKids ship OFF',
      () async {
        for (final seed in <Future<void> Function(AppDatabase)>[
          Seed.empty,
          Seed.newFamily,
          Seed.onboardingKids,
        ]) {
          await seed(db);
          final setting = await (db.select(
            db.settings,
          )..where((s) => s.familyId.equals(Seed.familyId))).getSingle();

          expect(setting.notifApprovals, isFalse);
          expect(setting.notifPayout, isFalse);
          expect(setting.notifSummary, isFalse);
        }
      },
    );

    test('Seed.demo keeps the P16 design toggles (ON)', () async {
      await Seed.demo(db);
      final setting = await (db.select(
        db.settings,
      )..where((s) => s.familyId.equals(Seed.familyId))).getSingle();

      expect(setting.notifApprovals, isTrue);
      expect(setting.notifPayout, isTrue);
      expect(setting.notifSummary, isTrue);
    });

    test('watchSettings reports OFF when no settings row exists', () async {
      await Seed.fresh(db);
      final repository = SettingsRepositoryImpl(db: db);
      final settings = await repository.watchSettings().first;

      expect(settings.notifApprovals, isFalse);
      expect(settings.notifPayout, isFalse);
      expect(settings.notifSummary, isFalse);
    });
  });

  group('release_prep clock rule', () {
    test('no DateTime.now() remains in the family repository', () async {
      final source = await File(
        'lib/features/family/data/family_repository_impl.dart',
      ).readAsString();

      expect(
        source,
        isNot(contains('DateTime.now()')),
        reason: 'app code reads time via appNowUtc()/clock.now() only',
      );
    });
  });
}
