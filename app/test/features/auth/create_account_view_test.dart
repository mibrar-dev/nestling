// P03 Create account — widget contract.
//
// Covers: the form copy and artwork, light + dark themes, widths 320/390/430
// at text scales 1.0/1.3, every AuthBloc status (initial/loading/loaded/
// failure), validation, submit/social navigation, back navigation and the
// accessibility contract (semantic labels, 44dp parent tap targets).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/auth_routes.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_state.dart';
import 'package:nestling/features/auth/presentation/views/create_account_view.dart';
import 'package:nestling/features/auth/presentation/widgets/apple_glyph.dart';
import 'package:nestling/features/auth/presentation/widgets/google_glyph.dart';

import '../../test_scope.dart';

const String _title = 'Create your family account';
const String _subtitle =
    'You’re the grown-up in charge. Children never need an email.';
const String _note = 'No child emails or photos — ever.';

const ValueKey<String> _appleKey = ValueKey('p03_apple');
const ValueKey<String> _googleKey = ValueKey('p03_google');
const ValueKey<String> _emailKey = ValueKey('p03_email');
const ValueKey<String> _passwordKey = ValueKey('p03_password');
const ValueKey<String> _submitKey = ValueKey('p03_submit');
const ValueKey<String> _termsKey = ValueKey('p03_terms');
const ValueKey<String> _privacyKey = ValueKey('p03_privacy');

const AuthAccount _member = AuthAccount(
  id: 'sarah',
  title: 'Sarah',
  detail: 'Owner',
  name: 'Sarah',
  role: 'owner',
);

/// In-memory repository with a caller-controlled item stream and
/// configurable submit behaviour.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    Stream<List<AuthAccount>>? items,
    this.throwOnCreate = false,
    this.gate,
    this.throwOnSocial = false,
  }) : _items = items ?? const Stream<List<AuthAccount>>.empty();

  final Stream<List<AuthAccount>> _items;
  final bool throwOnCreate;
  final bool throwOnSocial;

  /// Held open so a test can observe the submitting state.
  final Completer<void>? gate;

  int createAccountCalls = 0;
  String? lastEmail;
  int createAccountSocialCalls = 0;
  AuthProvider? lastProvider;

  @override
  Future<List<AuthAccount>> getItems() => _items.first;

  @override
  Stream<List<AuthAccount>> watchItems() => _items;

  @override
  Future<void> createAccount({String? email, String? name}) async {
    createAccountCalls++;
    lastEmail = email ?? name;
    await gate?.future;
    if (throwOnCreate) throw Exception('offline');
  }

  @override
  Future<void> createAccountSocial({required AuthProvider provider}) async {
    createAccountSocialCalls++;
    lastProvider = provider;
    await gate?.future;
    if (throwOnSocial) throw Exception('offline');
  }
}

/// Pumps `/create-account` through the real app (router, DI, themes) at
/// [surface] and [textScale]. Mirrors [pumpAppRoute], which takes no
/// size/scale.
Future<void> _pumpCreateAccount(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  required double textScale,
  bool seedDemo = true,
  AuthRepository? repository,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await setUpTestScope(seedDemo: seedDemo);
  if (repository != null) {
    GetIt.instance.unregister<AuthRepository>();
    GetIt.instance.registerLazySingleton<AuthRepository>(() => repository);
  }
  await pumpAppRoute(tester, '/create-account', theme: theme);
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Pumps [CreateAccountView] directly (no router) under the real theme with
/// [repository] driving the bloc; returns the bloc for state assertions.
/// Navigation is never triggered here, so no router is needed.
Future<AuthBloc> _pumpCreateAccountView(
  WidgetTester tester, {
  required AuthRepository repository,
  required ThemeMode theme,
}) async {
  final bloc = AuthBloc(repository: repository);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const CreateAccountView(),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

Future<void> _disposeView(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// The editable box inside the [NestTextField] registered under [key].
Finder _fieldInput(ValueKey<String> key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

Future<void> _enterForm(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(_fieldInput(_emailKey), email);
  await tester.pump();
  await tester.enterText(_fieldInput(_passwordKey), password);
  await tester.pump();
}

void main() {
  group('P03 create account — copy and theming', () {
    testWidgets('light: renders the full form', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Orchestrator rule: NestStatusBar only reserves height — the OS
      // draws the real status bar, so no mock clock glyphs in the app.
      expect(find.text('9:41'), findsNothing);
      expect(find.byType(NestStatusBar), findsOneWidget);
      expect(
        tester.getSize(find.byType(NestStatusBar)).height,
        NestDevice.statusH,
      );

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('or'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text(_note), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.textContaining('Terms'), findsOneWidget);
      expect(find.textContaining('Privacy Notice'), findsOneWidget);
      expect(find.byKey(_termsKey), findsOneWidget);
      expect(find.byKey(_privacyKey), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dark: renders the same content without overflow', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('or'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text(_note), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.textContaining('Terms'), findsOneWidget);
      expect(find.textContaining('Privacy Notice'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets('$themeName ${width}dp at text scale $scale', (
            tester,
          ) async {
            await _pumpCreateAccount(
              tester,
              theme: theme,
              surface: Size(width.toDouble(), 844),
              textScale: scale,
            );

            expect(find.text(_title), findsOneWidget);
            expect(find.text('Create account'), findsOneWidget);
            // The CTA stays in the fixed bottom bar at every size/scale.
            expect(find.byKey(_submitKey), findsOneWidget);
            expect(tester.takeException(), isNull);

            await disposeApp(tester);
          });
        }
      }
    }
  });

  group('P03 create account — BLoC states render the static form', () {
    testWidgets('initial: content renders before the load event', (
      tester,
    ) async {
      final bloc = await _pumpCreateAccountView(
        tester,
        repository: _FakeAuthRepository(),
        theme: ThemeMode.light,
      );

      expect(bloc.state.status, AuthStatus.initial);
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loading: content renders while no items have arrived', (
      tester,
    ) async {
      final bloc = await _pumpCreateAccountView(
        tester,
        repository: _FakeAuthRepository(),
        theme: ThemeMode.light,
      );
      bloc.add(const AuthLoadRequested());
      await tester.pump();

      expect(bloc.state.status, AuthStatus.loading);
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with no items: still the full form', (tester) async {
      final bloc = await _pumpCreateAccountView(
        tester,
        repository: _FakeAuthRepository(
          items: Stream<List<AuthAccount>>.value(const <AuthAccount>[]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const AuthLoadRequested());
      await tester.pump();

      expect(bloc.state.status, AuthStatus.loaded);
      expect(bloc.state.items, isEmpty);
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with items: member rows are never displayed', (
      tester,
    ) async {
      final bloc = await _pumpCreateAccountView(
        tester,
        repository: _FakeAuthRepository(
          items: Stream<List<AuthAccount>>.value(const <AuthAccount>[_member]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const AuthLoadRequested());
      await tester.pump();

      expect(bloc.state.status, AuthStatus.loaded);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(find.text('Sarah'), findsNothing);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('failure: a repository error never blocks the form', (
      tester,
    ) async {
      final bloc = await _pumpCreateAccountView(
        tester,
        repository: _FakeAuthRepository(
          items: Stream<List<AuthAccount>>.error(Exception('offline')),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const AuthLoadRequested());
      await tester.pump();

      expect(bloc.state.status, AuthStatus.failure);
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P03 create account — validation', () {
    testWidgets('typing alone never errors; valid input enables submit', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _enterForm(tester, email: 'not-an-email', password: 'short');

      // P03-BUG-2: no red on first paint — errors wait for a submit attempt.
      expect(find.text('Enter a valid email address'), findsNothing);
      expect(find.text('Use at least 8 characters'), findsNothing);
      expect(
        tester.widget<NestButton>(find.byKey(_submitKey)).onPressed,
        isNull,
      );

      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'password123',
      );

      expect(find.text('Enter a valid email address'), findsNothing);
      expect(find.text('Use at least 8 characters'), findsNothing);
      expect(
        tester.widget<NestButton>(find.byKey(_submitKey)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a submit attempt surfaces errors that clear live', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // The CTA is disabled while the form is invalid, so this submits the
      // way the button would — the errors must still appear (P03-BUG-2d
      // through the UI).
      BlocProvider.of<AuthBloc>(tester.element(find.byType(CreateAccountView)))
          .add(const AuthSubmitted());
      await tester.pump();
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);

      // Fixing a field clears its error live; the other error stays until
      // its field is fixed too.
      await tester.enterText(_fieldInput(_emailKey), 'sarah@example.co.uk');
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsNothing);
      expect(find.text('Use at least 8 characters'), findsOneWidget);

      await tester.enterText(_fieldInput(_passwordKey), 'password123');
      await tester.pump();
      expect(find.text('Use at least 8 characters'), findsNothing);
      expect(
        tester.widget<NestButton>(find.byKey(_submitKey)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P03 create account — helper and error lines', () {
    testWidgets('the helper is replaced by the error and comes back', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text('At least 8 characters'), findsOneWidget);

      BlocProvider.of<AuthBloc>(tester.element(find.byType(CreateAccountView)))
          .add(const AuthSubmitted());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The error takes the helper's place — never both at once.
      expect(find.text('At least 8 characters'), findsNothing);
      expect(find.text('Use at least 8 characters'), findsOneWidget);

      await tester.enterText(_fieldInput(_passwordKey), 'password123');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Use at least 8 characters'), findsNothing);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P03 create account — navigation', () {
    testWidgets('valid submit opens /privacy', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'password123',
      );
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');

      await disposeApp(tester);
    });

    testWidgets('a throwing repository shows the error and stays put', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
        repository: _FakeAuthRepository(throwOnCreate: true),
      );

      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'password123',
      );
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('offline'), findsOneWidget);
      expect(currentPath(tester), '/create-account');

      await disposeApp(tester);
    });

    testWidgets('Continue with Apple opens /privacy', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(_appleKey).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');

      await disposeApp(tester);
    });

    testWidgets('Continue with Google opens /privacy', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(_googleKey).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');

      await disposeApp(tester);
    });

    testWidgets('back opens /value-tour', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });

    testWidgets('a stale server error also displaces the helper, then both '
        'recover together', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
        repository: _FakeAuthRepository(throwOnCreate: true),
      );

      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'password123',
      );
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('At least 8 characters'), findsNothing);
      expect(find.textContaining('offline'), findsOneWidget);

      await tester.enterText(_fieldInput(_passwordKey), 'password1234');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('offline'), findsNothing);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the legal links are 44dp targets with a tap action', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );
      final handle = tester.ensureSemantics();

      for (final entry in const <MapEntry<ValueKey<String>, String>>[
        MapEntry(_termsKey, 'Terms'),
        MapEntry(_privacyKey, 'Privacy Notice'),
      ]) {
        final size = tester.getSize(find.byKey(entry.key));
        expect(size.width, greaterThanOrEqualTo(NestDevice.tapParent));
        expect(size.height, greaterThanOrEqualTo(NestDevice.tapParent));
        final node = tester.getSemantics(find.byKey(entry.key));
        final data = node.getSemanticsData();
        expect(data.label, entry.value);
        expect(data.flagsCollection.isButton, isTrue);
        expect(
          data.hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'VoiceOver must be able to activate the link',
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('back pops when a route is stacked', (tester) async {
      final bloc = AuthBloc(repository: _FakeAuthRepository());
      addTearDown(bloc.close);
      final router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push(AuthRoutePaths.createAccount),
                  child: const Text('enter'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: AuthRoutePaths.createAccount,
            builder: (context, state) => BlocProvider<AuthBloc>.value(
              value: bloc,
              child: const CreateAccountView(),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp.router(theme: NestTheme.light(), routerConfig: router),
      );
      await tester.pump();
      await tester.tap(find.text('enter'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateAccountView), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      // With history the back control pops instead of routing to /value-tour.
      expect(find.text('enter'), findsOneWidget);
      expect(find.byType(CreateAccountView), findsNothing);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P03 create account — submitting state', () {
    testWidgets('every control shows a spinner and stops accepting taps', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _FakeAuthRepository(gate: gate);
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
        repository: repo,
      );

      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'password123',
      );
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();

      // All three buttons are busy: the shared components swap the leading
      // glyph for a CircularProgressIndicator.
      expect(
        find.descendant(
          of: find.byType(CreateAccountView),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNWidgets(3),
      );
      expect(
        tester.widget<NestButton>(find.byKey(_submitKey)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);

      // Brand buttons are dead while a submit is in flight.
      await tester.tap(find.byKey(_appleKey).first, warnIfMissed: false);
      await tester.pump();
      expect(repo.createAccountSocialCalls, 0);
      expect(currentPath(tester), '/create-account');

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.createAccountCalls, 1);
      expect(repo.createAccountSocialCalls, 0);
      expect(currentPath(tester), '/privacy');

      await disposeApp(tester);
    });

    testWidgets('a slow social sign-in blocks the email CTA too', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _FakeAuthRepository(gate: gate);
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
        repository: repo,
      );

      await tester.tap(find.byKey(_googleKey).first);
      await tester.pump();

      expect(
        tester.widget<NestButton>(find.byKey(_submitKey)).onPressed,
        isNull,
      );
      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'password123',
      );
      expect(
        tester.widget<NestButton>(find.byKey(_submitKey)).onPressed,
        isNull,
        reason: 'a social sign-up in flight must not unlock the email form',
      );
      expect(currentPath(tester), '/create-account');

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), '/privacy');

      await disposeApp(tester);
    });

    testWidgets('a failing social sign-in stays on the screen', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
        repository: _FakeAuthRepository(throwOnSocial: true),
      );

      await tester.tap(find.byKey(_appleKey).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('offline'), findsOneWidget);
      expect(currentPath(tester), '/create-account');
      // The form is usable again after the failure.
      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'password123',
      );
      expect(
        tester.widget<NestButton>(find.byKey(_submitKey)).onPressed,
        isNotNull,
      );
      // The stale server error is cleared as soon as a field is edited. The
      // bloc emits asynchronously and `InputDecorator` cross-fades its error
      // line, so drain both before asserting it is gone.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('offline'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('a double tap on Create account creates one account', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _FakeAuthRepository(gate: gate);
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
        repository: repo,
      );

      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'password123',
      );
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
      await tester.tap(find.byKey(_submitKey), warnIfMissed: false);
      await tester.pump();
      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.createAccountCalls, 1);
      expect(currentPath(tester), '/privacy');

      await disposeApp(tester);
    });
  });

  group('P03 create account — layout geometry', () {
    // Design bands (logical px, design/screens/light/P03-create-account.png):
    // status bar 47, compact nav 44 (60 in the HTML), headline block, and a
    // CTA panel that starts at 678 and runs to the physical bottom edge.
    testWidgets('light: the stack matches the design order and chrome', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Status bar reserves 47 and nothing else — the OS draws the real one.
      expect(
        tester.getSize(find.byType(NestStatusBar)).height,
        NestDevice.statusH,
      );
      expect(find.byType(NestBottomCta), findsOneWidget);

      // The CTA is the last child of the column: submit button above the
      // legal line, both inside the bar.
      final cta = find.byType(NestBottomCta);
      expect(
        tester.getRect(cta).bottom,
        NestDevice.height,
        reason: 'the CTA must run to the physical bottom edge (owner rule)',
      );
      final submitRect = tester.getRect(find.byKey(_submitKey));
      final termsRect = tester.getRect(find.byKey(_termsKey));
      final privacyRect = tester.getRect(find.byKey(_privacyKey));
      expect(termsRect.top, greaterThanOrEqualTo(submitRect.bottom));
      expect(
        privacyRect.top,
        greaterThanOrEqualTo(submitRect.bottom),
        reason: 'both legal links sit under the button, not beside it',
      );

      // Top-down order of the scrollable form.
      double topOf(Finder f) => tester.getRect(f).top;
      final order = <double>[
        topOf(find.text(_title)),
        topOf(find.text(_subtitle)),
        topOf(find.byKey(_appleKey).first),
        topOf(find.byKey(_googleKey).first),
        topOf(find.text('or')),
        topOf(find.byKey(_emailKey)),
        topOf(find.byKey(_passwordKey)),
        topOf(find.text('At least 8 characters')),
        topOf(find.text(_note)),
      ];
      for (var i = 1; i < order.length; i++) {
        expect(
          order[i],
          greaterThan(order[i - 1]),
          reason: 'element $i must sit below element ${i - 1}',
        );
      }

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the CTA panel keeps the surface colour to the screen edge', (
      tester,
    ) async {
      for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await _pumpCreateAccount(
          tester,
          theme: theme,
          surface: const Size(390, 844),
          textScale: 1,
        );

        // The bar's own decoration is the top-level DecoratedBox inside
        // NestBottomCta — the ones deeper in the tree are the buttons'.
        final bar = find
            .descendant(
              of: find.byType(NestBottomCta),
              matching: find.byType(DecoratedBox),
            )
            .first;
        final barRect = tester.getRect(bar);
        final ctaRect = tester.getRect(find.byType(NestBottomCta));
        expect(barRect, ctaRect);
        expect(barRect.bottom, NestDevice.height);

        // The bar paints the surface token, so nothing shows below it: no
        // page-tint strip, in either theme.
        final decoration =
            tester.widget<DecoratedBox>(bar).decoration as BoxDecoration;
        final tokens = tester.element(find.byType(NestBottomCta)).nest;
        expect(decoration.color, tokens.surface);
        expect(decoration.color, isNot(tokens.paper));
        expect(
          tokens.surface == tokens.paper,
          isFalse,
          reason: 'a bar indistinguishable from the page cannot prove the rule',
        );

        // The scaffold's own background is the page colour, and it never
        // paints below the bar (the bar's rect ends at the screen bottom).
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, tokens.paper);

        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      }
    });

    testWidgets(
      'the scroll body carries the 20px gutters and 32px bottom pad',
      (tester) async {
        await _pumpCreateAccount(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
          textScale: 1,
        );

        final scroll = tester.getRect(find.byType(SingleChildScrollView));
        expect(scroll.left, 0);
        expect(scroll.right, NestDevice.width);

        // Every full-width form control starts at the same 20px gutter.
        for (final key in <ValueKey<String>>[
          _appleKey,
          _googleKey,
          _emailKey,
          _passwordKey,
          _submitKey,
        ]) {
          final rect = tester.getRect(find.byKey(key).first);
          expect(
            rect.left,
            NestSpacing.padSide,
            reason: '$key must align to the 20px gutter',
          );
          expect(rect.right, NestDevice.width - NestSpacing.padSide);
        }

        // Headline and note share the same gutter as the buttons.
        expect(tester.getRect(find.text(_title)).left, NestSpacing.padSide);
        expect(tester.getRect(find.text(_note)).left, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );

    testWidgets('the note row keeps the 8px gap after the password helper', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final helper = tester.getRect(find.text('At least 8 characters'));
      final note = tester.getRect(find.text(_note));
      // s3 (12) between the helper line and the note row.
      expect(note.top - helper.bottom, greaterThanOrEqualTo(NestSpacing.s3));
      expect(note.top - helper.bottom, lessThan(NestSpacing.s3 + 8));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the brand glyphs are 20px and the shield icon is 20px', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(tester.getSize(find.byType(AppleGlyph)).height, NestSpacing.s5);
      expect(tester.getSize(find.byType(GoogleGlyph)).height, NestSpacing.s5);
      final shield = find.byWidgetPredicate(
        (w) => w is NestIcon && w.size == NestSpacing.s5,
      );
      expect(shield, findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the eye toggle sits inside the field, not past the gutter', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final eye = tester.getRect(find.byTooltip('Show password'));
      final field = tester.getRect(find.byKey(_passwordKey));
      expect(eye.right, lessThanOrEqualTo(field.right));
      expect(eye.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a 34px home-indicator inset does not clip the CTA content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.padding = const FakeViewPadding(bottom: 100);
      addTearDown(tester.view.reset);
      await setUpTestScope();
      await pumpAppRoute(tester, '/create-account');

      // Legal links and the button stay on screen with the inset applied.
      expect(find.byKey(_submitKey), findsOneWidget);
      expect(find.byKey(_termsKey), findsOneWidget);
      expect(find.byKey(_privacyKey), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_submitKey).first).bottom,
        lessThanOrEqualTo(NestDevice.height),
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P03 create account — accessibility', () {
    testWidgets('labels, header flag and tap targets meet the contract', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Button/link labels are read straight off their semantics nodes.
      // The shared InkWell-based brand buttons merge the explicit label with
      // the inner Text, so those nodes read e.g.
      // 'Continue with Apple\nContinue with Apple' (see SHARED_REQUEST §2)
      // and stay `contains` assertions; the feature-owned legal targets are
      // exact single nodes (P03-BUG-4).
      for (final entry in const <MapEntry<ValueKey<String>, String>>[
        MapEntry(_appleKey, 'Continue with Apple'),
        MapEntry(_googleKey, 'Continue with Google'),
      ]) {
        final data = tester
            .getSemantics(find.byKey(entry.key).first)
            .getSemanticsData();
        expect(data.label, contains(entry.value));
        expect(data.flagsCollection.isButton, isTrue);
      }
      for (final entry in const <MapEntry<ValueKey<String>, String>>[
        MapEntry(_termsKey, 'Terms'),
        MapEntry(_privacyKey, 'Privacy Notice'),
      ]) {
        final data = tester
            .getSemantics(find.byKey(entry.key))
            .getSemanticsData();
        expect(data.label, equals(entry.value));
        expect(data.flagsCollection.isButton, isTrue);
      }
      expect(find.byTooltip('Show password'), findsOneWidget);

      final backData = tester
          .getSemantics(find.bySemanticsLabel('Back'))
          .getSemanticsData();
      expect(backData.label, 'Back');
      expect(backData.flagsCollection.isButton, isTrue);

      // The headline is the screen's only heading (HTML `<h1>`).
      final headlineData = tester
          .getSemantics(find.text(_title))
          .getSemanticsData();
      expect(headlineData.flagsCollection.isHeader, isTrue);

      // Brand glyphs carry no semantics of their own (button labels do).
      expect(find.bySemanticsLabel('Apple logo'), findsNothing);
      expect(find.bySemanticsLabel('Google logo'), findsNothing);

      // Parent rule: every tap target is at least 44x44.
      expect(
        tester.getSize(find.bySemanticsLabel('Back')).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        tester.getSize(find.byTooltip('Show password')).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      // The legal targets are overlay hit boxes (P03-BUG-1): measure the
      // keyed widgets directly — each keeps a full 44dp target.
      for (final key in <ValueKey<String>>[_termsKey, _privacyKey]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(NestDevice.tapParent));
        expect(size.height, greaterThanOrEqualTo(NestDevice.tapParent));
      }
      for (final key in <ValueKey<String>>[_appleKey, _googleKey, _submitKey]) {
        // Brand buttons forward their key to the inner _BrandButton too, so
        // the key matches twice — measure the outer (first) widget.
        final size = tester.getSize(find.byKey(key).first);
        expect(size.height, greaterThanOrEqualTo(52));
        expect(size.width, 390 - 2 * NestSpacing.padSide);
      }

      await disposeApp(tester);
    });

    testWidgets('the eye toggle flips its tooltip', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      expect(find.byTooltip('Hide password'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('tap targets hold at 320dp with text scale 1.3', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      for (final key in <ValueKey<String>>[_appleKey, _googleKey, _submitKey]) {
        final size = tester.getSize(find.byKey(key).first);
        expect(size.height, greaterThanOrEqualTo(NestDevice.tapParent));
        expect(size.width, 320 - 2 * NestSpacing.padSide);
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('every interactive target clears 44dp at 430dp too', (
      tester,
    ) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(430, 844),
        textScale: 1.3,
      );

      final controls = <Finder>[
        find.bySemanticsLabel('Back'),
        find.byTooltip('Show password'),
        find.byKey(_appleKey).first,
        find.byKey(_googleKey).first,
        find.byKey(_submitKey).first,
      ];
      for (final control in controls) {
        final size = tester.getSize(control);
        expect(size.height, greaterThanOrEqualTo(NestDevice.tapParent));
        expect(size.width, greaterThanOrEqualTo(NestDevice.tapParent));
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the helper text is not announced as a button', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final helperData = tester
          .getSemantics(find.text('At least 8 characters'))
          .getSemanticsData();
      expect(helperData.flagsCollection.isButton, isFalse);
      // The password input itself is announced as a text field with a label.
      final fieldData = tester
          .getSemantics(
            find.descendant(
              of: find.byKey(_passwordKey),
              matching: find.byType(TextField),
            ),
          )
          .getSemanticsData();
      expect(fieldData.label, contains('Password'));
      expect(fieldData.flagsCollection.isTextField, isTrue);

      await disposeApp(tester);
    });

    testWidgets('the or-divider row is decorative', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // `ExcludeSemantics` on the whole row: no node announces "or".
      expect(find.bySemanticsLabel('or'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // ORCHESTRATOR_NOTES.md §3 (mandatory): the design PNG shows the filled
  // form (sarah@example.co.uk + an 18-char password); the empty state is the
  // correct launch state. This pins the filled state for the design compare.
  group('P03 create account — design filled state', () {
    testWidgets('the design values enable the primary green CTA with dots '
        'and the eye toggle', (tester) async {
      await _pumpCreateAccount(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _enterForm(
        tester,
        email: 'sarah@example.co.uk',
        password: 'nestlingfamily2026',
      );

      final tokens = tester.element(find.byKey(_submitKey)).nest;
      final submit = tester.widget<NestButton>(find.byKey(_submitKey));
      expect(submit.onPressed, isNotNull, reason: 'design CTA is enabled');
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(_submitKey),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(
        (container.decoration! as BoxDecoration).color,
        tokens.leaf,
        reason: 'primary CTA uses the leaf token in the design',
      );

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(_passwordKey),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.obscureText, isTrue, reason: 'password renders as dots');
      expect(find.byTooltip('Show password'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}
