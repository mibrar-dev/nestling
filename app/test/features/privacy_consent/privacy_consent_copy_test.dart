// P04 · Privacy & consent — copy fidelity against the design source.
//
// Orchestrator COPY rule: use the design's typographic characters exactly
// (curly ’ “ ”, en/em dashes –/—, ellipsis …, non-breaking spaces where a
// phrase must not split) and compare copy character-by-character with the
// HTML source. This test reads
// `design/html-source/screens/P04-privacy.html` — the same file the UI shots
// are rendered from — decodes its entities and asserts that every string P04
// draws is byte-for-byte the decoded design text. If the design copy changes,
// this fails instead of drifting silently.
//
// The failure captions ("Oops — your choice wasn’t saved…") are product copy
// invented by the screen (plan §d), not design copy, so they are checked for
// typography only, not against the HTML.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_event.dart';
import 'package:nestling/features/privacy_consent/presentation/views/privacy_consent_view.dart';

import '../../test_scope.dart';

/// Items stream that always fails, so the failure caption renders with the
/// stored opt-in OFF (the "it stays off" wording).
class _FailingRepository implements PrivacyConsentRepository {
  const _FailingRepository();

  @override
  Future<List<ConsentOption>> getItems() => watchItems().first;

  @override
  Stream<List<ConsentOption>> watchItems() =>
      Stream<List<ConsentOption>>.error(Exception('offline'));

  @override
  Stream<bool> watchCrashConsent() => Stream<bool>.value(false);

  @override
  Future<void> setCrashConsent({required bool consent}) async {}
}

/// Loads with the opt-in already ON and fails every write, so a failed OFF
/// write lands the bloc in `failure` with `crashConsent == true` — the state
/// the "still on" caption describes (P04-6).
class _FailingWriteRepository implements PrivacyConsentRepository {
  @override
  Future<List<ConsentOption>> getItems() => watchItems().first;

  @override
  Stream<List<ConsentOption>> watchItems() =>
      Stream<List<ConsentOption>>.value(const <ConsentOption>[
        ConsentOption(
          id: ConsentOptionIds.crash,
          title: 'c',
          detail: 'd',
          enabled: true,
        ),
      ]);

  @override
  Stream<bool> watchCrashConsent() => Stream<bool>.value(true);

  @override
  Future<void> setCrashConsent({required bool consent}) async {
    throw Exception('read only');
  }
}

/// HTML entities used by the design sources (plus the common ones, so a
/// future edit to the HTML cannot crash the decoder).
const Map<String, String> _entities = <String, String>{
  '&rsquo;': '\u2019', // ’
  '&lsquo;': '\u2018', // ‘
  '&rdquo;': '\u201D', // ”
  '&ldquo;': '\u201C', // “
  '&mdash;': '\u2014', // —
  '&ndash;': '\u2013', // –
  '&hellip;': '\u2026', // …
  '&nbsp;': '\u00A0',
  '&middot;': '\u00B7', // ·
  '&amp;': '&',
  '&quot;': '"',
  '&lt;': '<',
  '&gt;': '>',
};

/// Locates the design source by walking up from the package root, so the
/// test works no matter where `flutter test` is invoked from.
File _designSource() {
  var dir = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth++) {
    final candidate = File(
      '${dir.path}/design/html-source/screens/P04-privacy.html',
    );
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'design/html-source/screens/P04-privacy.html not found above '
    '${Directory.current.path}',
  );
}

String _decode(String raw) {
  var out = raw;
  _entities.forEach((entity, glyph) {
    out = out.replaceAll(entity, glyph);
  });
  // Collapse source-line wrapping, but never touch the non-breaking space.
  return out.replaceAll(RegExp('[ \t\r\n]+'), ' ').trim();
}

String _capture(String html, String pattern) {
  final match = RegExp(pattern, dotAll: true).firstMatch(html);
  expect(
    match,
    isNotNull,
    reason: 'the design source no longer matches $pattern',
  );
  return _checked(_decode(match!.group(1)!), pattern);
}

/// Guards against a vacuous pass: an empty or markup-laden capture would let
/// `find.text(...)` succeed for the wrong reason.
String _checked(String captured, String pattern) {
  expect(captured.length, greaterThan(2), reason: 'empty capture: $pattern');
  expect(captured, isNot(contains('<')), reason: 'markup leaked: $pattern');
  return captured;
}

List<String> _captureAll(String html, String pattern) =>
    RegExp(pattern, dotAll: true)
        .allMatches(html)
        .map((m) => _checked(_decode(m.group(1)!), pattern))
        .toList(growable: false);

void main() {
  late String html;

  setUpAll(() {
    html = _designSource().readAsStringSync();
  });

  group('P04 — copy is the design copy, character by character', () {
    testWidgets('every string drawn on screen matches the HTML source', (
      tester,
    ) async {
      final h1 = _capture(html, '<h1 class="h1">(.*?)</h1>');
      final standfirst = _capture(html, '<p class="body t-ink-2">(.*?)</p>');
      final titles = _captureAll(html, '<span class="list-title">(.*?)</span>');
      final subs = _captureAll(html, '<span class="list-sub">(.*?)</span>');
      final optTitle = _capture(html, '<span class="opt-title">(.*?)</span>');
      final optSub = _capture(html, '<span class="opt-sub">(.*?)</span>');
      final cta = _capture(
        html,
        '<button class="btn btn-primary"[^>]*>(.*?)</',
      );
      final footnote = _capture(html, '<button class="footnote"[^>]*>(.*?)</');
      final shieldAlt = _capture(
        html,
        'class="shield" role="img" aria-label="(.*?)"',
      );
      final toggleLabel = _capture(html, 'class="toggle" aria-label="(.*?)"');
      final backLabel = _capture(
        html,
        'class="nav-back"[^>]*aria-label="(.*?)"',
      );

      // Sanity-check the extraction itself against the counts the design has.
      expect(titles, hasLength(4));
      expect(subs, hasLength(4));

      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      expect(find.text(h1), findsOneWidget);
      expect(find.text(standfirst), findsOneWidget);
      for (final title in titles) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      for (final sub in subs) {
        expect(find.text(sub), findsOneWidget, reason: sub);
      }
      expect(find.text(optTitle), findsOneWidget);
      expect(find.text(optSub), findsOneWidget);
      expect(find.text(cta), findsOneWidget);
      expect(find.text(footnote), findsOneWidget);
      expect(find.bySemanticsLabel(shieldAlt), findsOneWidget);
      expect(find.bySemanticsLabel(toggleLabel), findsOneWidget);
      expect(find.bySemanticsLabel(backLabel), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    test('the design typography characters survive into the app', () {
      // Spot-check the code points so a regression names the glyph that broke
      // instead of "copy differs".
      final h1 = _capture(html, '<h1 class="h1">(.*?)</h1>');
      expect(
        h1,
        'Your family\u2019s privacy',
        reason: 'the apostrophe is U+2019 (rsquo), not an ASCII quote',
      );

      final standfirst = _capture(html, '<p class="body t-ink-2">(.*?)</p>');
      expect(
        standfirst,
        'Exactly what we store \u2014 and nothing else.',
        reason: 'the dash is U+2014 (mdash), not an en dash or a hyphen',
      );

      final firstTitle = _capture(
        html,
        '<span class="list-title">(.*?)</span>',
      );
      expect(firstTitle, 'No ads or tracking \u2014 ever');

      // Nothing on this screen uses a straight quote, an ASCII hyphen or a
      // zero-width character that the design does not have.
      final rendered = <String>[
        h1,
        standfirst,
        ..._captureAll(html, '<span class="list-title">(.*?)</span>'),
        ..._captureAll(html, '<span class="list-sub">(.*?)</span>'),
        _capture(html, '<span class="opt-title">(.*?)</span>'),
        _capture(html, '<span class="opt-sub">(.*?)</span>'),
        _capture(html, '<button class="btn btn-primary"[^>]*>(.*?)</'),
        _capture(html, '<button class="footnote"[^>]*>(.*?)</'),
      ];
      for (final line in rendered) {
        for (final straight in <String>["'", '"', '-']) {
          expect(
            line.contains(straight),
            isFalse,
            reason: 'straight $straight in: $line',
          );
        }
        expect(line.contains('\u2018'), isFalse, reason: line);
        expect(line.contains('\u201C'), isFalse, reason: line);
        expect(line.contains('\u00AD'), isFalse, reason: line);
      }
    });

    test('a non-breaking space in the design would survive the copy', () {
      // NBSP is a no-op on P04 today (the design has none), so assert the
      // decoder preserves one rather than pretending the rule cannot bite:
      // if the design ever wraps a phrase in `&nbsp;`, the app copy must keep
      // U+00A0 instead of a plain space.
      expect(_decode('UK&nbsp;servers'), 'UK\u00A0servers');
      expect(_decode('A&nbsp;B').contains('\u00A0'), isTrue);
    });
  });

  group('P04 — screen-owned copy keeps the design typography', () {
    // The failure captions are not in the HTML (plan §d invents them), but
    // they sit on the same screen and must use the same characters: a curly
    // apostrophe in "wasn’t", an em dash after "Oops", and no ASCII hyphens.
    const offCaption =
        'Oops — your choice wasn’t saved. Continue anyway; it stays off.';
    const onCaption =
        'Oops — your choice wasn’t saved. Crash reports are still on. '
        'Continue anyway.';

    Future<void> pumpPrivacyView(
      WidgetTester tester,
      PrivacyConsentRepository repository,
    ) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final bloc = PrivacyConsentBloc(repository: repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: BlocProvider<PrivacyConsentBloc>.value(
            value: bloc,
            child: const PrivacyConsentView(),
          ),
        ),
      );
      bloc.add(const PrivacyConsentLoadRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    void expectTypography(String caption) {
      expect(caption, contains('\u2014'), reason: 'em dash after Oops');
      expect(caption, contains('\u2019'), reason: 'curly apostrophe');
      expect(caption.contains('-'), isFalse, reason: 'no ASCII hyphen');
      expect(caption.contains("'"), isFalse, reason: 'no straight quote');
    }

    testWidgets('the OFF caption (load failed, nothing stored)', (
      tester,
    ) async {
      await pumpPrivacyView(tester, const _FailingRepository());

      expect(find.text(offCaption), findsOneWidget);
      expectTypography(offCaption);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('the ON caption (failed OFF write, opt-in still stored)', (
      tester,
    ) async {
      await pumpPrivacyView(tester, _FailingWriteRepository());

      await tester.ensureVisible(
        find.byKey(const ValueKey('p04_crash_toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p04_crash_toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(onCaption), findsOneWidget);
      expect(find.text(offCaption), findsNothing);
      expectTypography(onCaption);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
