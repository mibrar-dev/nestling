// P03 Create account — AuthBloc state machine, validation and the
// Drift-backed account repository contract.
//
// The bloc owns the email/password form (the members stream from
// `AuthLoadRequested` is never displayed); the password is never persisted.
// `createAccount` keeps an optional legacy `name:` alias because the shared
// `app/test/core/data/repositories_test.dart` (out of scope per RULES §1)
// still calls it — new callers must pass `email:`.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/auth/data/auth_repository_impl.dart';
import 'package:nestling/features/auth/domain/auth_provider.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_state.dart';

import '../../test_scope.dart';

const List<AuthAccount> _demoMembers = <AuthAccount>[
  AuthAccount(
    id: 'sarah',
    title: 'Sarah',
    detail: 'Owner',
    name: 'Sarah',
    role: 'owner',
  ),
  AuthAccount(
    id: 'james',
    title: 'James',
    detail: 'Co-parent',
    name: 'James',
    role: 'co-parent',
  ),
];

/// In-memory repository with a caller-controlled item stream and
/// configurable submit behaviour.
///
/// [gate] holds `createAccount`/`createAccountSocial` open so a test can
/// observe the in-flight state; [failuresBeforeSuccess] makes the first N
/// create calls throw (transient-failure coverage).
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    Stream<List<AuthAccount>>? items,
    this.throwOnCreate = false,
    this.throwOnSocial = false,
    this.gate,
    this.failuresBeforeSuccess = 0,
  }) : _items = items ?? const Stream<List<AuthAccount>>.empty();

  final Stream<List<AuthAccount>> _items;
  final bool throwOnCreate;
  final bool throwOnSocial;
  final Completer<void>? gate;
  final int failuresBeforeSuccess;

  int createAccountCalls = 0;
  String? lastEmail;
  String? lastName;
  int createAccountSocialCalls = 0;
  AuthProvider? lastProvider;

  @override
  Future<List<AuthAccount>> getItems() => _items.first;

  @override
  Stream<List<AuthAccount>> watchItems() => _items;

  @override
  Future<void> createAccount({String? email, String? name}) async {
    createAccountCalls++;
    lastEmail = email;
    lastName = name;
    await gate?.future;
    if (throwOnCreate || createAccountCalls <= failuresBeforeSuccess) {
      throw Exception('offline');
    }
  }

  @override
  Future<void> createAccountSocial({required AuthProvider provider}) async {
    createAccountSocialCalls++;
    lastProvider = provider;
    await gate?.future;
    if (throwOnSocial) throw Exception('offline');
  }
}

void main() {
  group('AuthState', () {
    test('copyWith replaces only the given fields', () {
      const state = AuthState();
      expect(state.email, isEmpty);
      expect(state.password, isEmpty);
      expect(state.emailError, isNull);
      expect(state.passwordError, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.submitted, isFalse);
      expect(state.formError, isNull);

      final withEmail = state.copyWith(email: 'sarah@example.co.uk');
      expect(withEmail.email, 'sarah@example.co.uk');
      expect(withEmail.password, isEmpty);

      final errored = withEmail.copyWith(emailError: authEmailErrorText);
      expect(errored.emailError, authEmailErrorText);

      final cleared = errored.copyWith(clearEmailError: true);
      expect(cleared.emailError, isNull);
      expect(cleared.email, withEmail.email);
    });

    test('equality is driven by every field', () {
      const a = AuthState(email: 'sarah@example.co.uk');
      const b = AuthState(email: 'sarah@example.co.uk');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const AuthState()));
      expect(a, isNot(a.copyWith(password: 'password123')));
      expect(a, isNot(a.copyWith(submitted: true)));
    });

    test('email validation accepts a trimmed addr and rejects the rest', () {
      expect(isAuthEmailValid('sarah@example.co.uk'), isTrue);
      expect(isAuthEmailValid('  sarah@example.co.uk  '), isTrue);
      expect(isAuthEmailValid(''), isFalse);
      expect(isAuthEmailValid('not-an-email'), isFalse);
      expect(isAuthEmailValid('a@b'), isFalse);
      expect(isAuthEmailValid('a@b c.com'), isFalse);
    });

    test('password validation needs 8 characters', () {
      expect(isAuthPasswordValid('12345678'), isTrue);
      expect(isAuthPasswordValid('nestlingfamily2026'), isTrue);
      expect(isAuthPasswordValid('short'), isFalse);
      expect(isAuthPasswordValid(''), isFalse);
    });

    test('canSubmit needs a valid pair and no flight', () {
      const valid = AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
      );
      expect(valid.canSubmit, isTrue);
      expect(valid.copyWith(email: 'bad').canSubmit, isFalse);
      expect(valid.copyWith(password: 'short').canSubmit, isFalse);
      expect(valid.copyWith(isSubmitting: true).canSubmit, isFalse);
      expect(const AuthState().canSubmit, isFalse);
    });
  });

  group('AuthBloc', () {
    test('starts initial with an empty untouched form', () {
      final bloc = AuthBloc(repository: _FakeAuthRepository());
      addTearDown(bloc.close);

      expect(bloc.state, const AuthState());
      expect(bloc.state.status, AuthStatus.initial);
      expect(bloc.state.emailError, isNull);
      expect(bloc.state.passwordError, isNull);
    });

    blocTest<AuthBloc, AuthState>(
      'load on the Drift repository emits loading then the demo members',
      setUp: setUpTestScope,
      build: () => AuthBloc(repository: GetIt.instance<AuthRepository>()),
      act: (bloc) => bloc.add(const AuthLoadRequested()),
      expect: () => const <AuthState>[
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.loaded, items: _demoMembers),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'typing an invalid email errors live; fixing it clears',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      act: (bloc) => bloc
        ..add(const AuthEmailChanged('not-an-email'))
        ..add(const AuthEmailChanged('sarah@example.co.uk')),
      expect: () => const <AuthState>[
        AuthState(email: 'not-an-email', emailError: authEmailErrorText),
        AuthState(email: 'sarah@example.co.uk'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'typing a short password errors live; fixing it clears',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      act: (bloc) => bloc
        ..add(const AuthPasswordChanged('short'))
        ..add(const AuthPasswordChanged('password123')),
      expect: () => const <AuthState>[
        AuthState(password: 'short', passwordError: authPasswordErrorText),
        AuthState(password: 'password123'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'submit with an empty form sets both errors and never calls the repo',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      act: (bloc) => bloc.add(const AuthSubmitted()),
      expect: () => const <AuthState>[
        AuthState(
          emailError: authEmailErrorText,
          passwordError: authPasswordErrorText,
        ),
      ],
    );

    test('submit invalid leaves the repository untouched', () async {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(repository: repo);
      addTearDown(bloc.close);

      bloc
        ..add(const AuthEmailChanged('bad'))
        ..add(const AuthPasswordChanged('short'));
      await bloc.stream.firstWhere((s) => s.passwordError != null);
      bloc.add(const AuthSubmitted());
      await Future<void>.delayed(Duration.zero);

      expect(repo.createAccountCalls, 0);
      expect(bloc.state.emailError, authEmailErrorText);
      expect(bloc.state.passwordError, authPasswordErrorText);
      expect(bloc.state.submitted, isFalse);
    });

    blocTest<AuthBloc, AuthState>(
      'submit valid calls createAccount(email:) once and submits',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
      ),
      act: (bloc) => bloc.add(const AuthSubmitted()),
      expect: () => const <AuthState>[
        AuthState(
          email: 'sarah@example.co.uk',
          password: 'password123',
          isSubmitting: true,
        ),
        AuthState(
          email: 'sarah@example.co.uk',
          password: 'password123',
          submitted: true,
        ),
      ],
    );

    test('submit valid forwards the trimmed email', () async {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(repository: repo);
      addTearDown(bloc.close);

      bloc
        ..add(const AuthEmailChanged('  sarah@example.co.uk  '))
        ..add(const AuthPasswordChanged('password123'));
      await bloc.stream.firstWhere((s) => s.canSubmit);
      bloc.add(const AuthSubmitted());
      await bloc.stream.firstWhere((s) => s.submitted);

      expect(repo.createAccountCalls, 1);
      expect(repo.lastEmail, 'sarah@example.co.uk');
      expect(bloc.state.isSubmitting, isFalse);
    });

    blocTest<AuthBloc, AuthState>(
      'a throwing repository becomes a formError without submitting',
      build: () =>
          AuthBloc(repository: _FakeAuthRepository(throwOnCreate: true)),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
      ),
      act: (bloc) => bloc.add(const AuthSubmitted()),
      expect: () => <Matcher>[
        isA<AuthState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isTrue)
            .having((s) => s.submitted, 'submitted', isFalse),
        isA<AuthState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having((s) => s.submitted, 'submitted', isFalse)
            .having((s) => s.formError, 'formError', contains('offline')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'social apple succeeds and submits',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      act: (bloc) => bloc.add(const AuthSocialSubmitted(AuthProvider.apple)),
      expect: () => const <AuthState>[
        AuthState(isSubmitting: true),
        AuthState(submitted: true),
      ],
    );

    test('social google forwards its provider', () async {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(repository: repo);
      addTearDown(bloc.close);

      bloc.add(const AuthSocialSubmitted(AuthProvider.google));
      await bloc.stream.firstWhere((s) => s.submitted);

      expect(repo.createAccountSocialCalls, 1);
      expect(repo.lastProvider, AuthProvider.google);
    });

    blocTest<AuthBloc, AuthState>(
      'a throwing social becomes a formError without submitting',
      build: () =>
          AuthBloc(repository: _FakeAuthRepository(throwOnSocial: true)),
      act: (bloc) => bloc.add(const AuthSocialSubmitted(AuthProvider.apple)),
      expect: () => <Matcher>[
        isA<AuthState>().having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<AuthState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having((s) => s.formError, 'formError', contains('offline')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSubmitConsumed clears submitted after navigation',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
        submitted: true,
      ),
      act: (bloc) => bloc.add(const AuthSubmitConsumed()),
      expect: () => const <AuthState>[
        AuthState(email: 'sarah@example.co.uk', password: 'password123'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSubmitConsumed is a no-op when nothing was submitted',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      act: (bloc) => bloc.add(const AuthSubmitConsumed()),
      expect: () => const <AuthState>[],
    );

    blocTest<AuthBloc, AuthState>(
      'a failing members stream still yields loaded-then-failure status',
      build: () => AuthBloc(
        repository: _FakeAuthRepository(
          items: Stream<List<AuthAccount>>.error(Exception('offline')),
        ),
      ),
      act: (bloc) => bloc.add(const AuthLoadRequested()),
      expect: () => <Matcher>[
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', contains('offline')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'submit while one is already in flight is ignored (no second call)',
      build: () {
        final repo = _FakeAuthRepository(gate: Completer<void>());
        return AuthBloc(repository: repo);
      },
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
      ),
      act: (bloc) => bloc
        ..add(const AuthSubmitted())
        ..add(const AuthSubmitted()),
      wait: const Duration(milliseconds: 50),
      expect: () => const <AuthState>[
        AuthState(
          email: 'sarah@example.co.uk',
          password: 'password123',
          isSubmitting: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'social while an email submit is in flight is ignored',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
        isSubmitting: true,
      ),
      act: (bloc) => bloc.add(const AuthSocialSubmitted(AuthProvider.apple)),
      expect: () => const <AuthState>[],
    );

    blocTest<AuthBloc, AuthState>(
      'email submit while a social submit is in flight is ignored',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
        isSubmitting: true,
      ),
      act: (bloc) => bloc.add(const AuthSubmitted()),
      expect: () => const <AuthState>[],
    );

    blocTest<AuthBloc, AuthState>(
      'fields stay editable while a submit is in flight',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
        isSubmitting: true,
      ),
      act: (bloc) => bloc.add(const AuthPasswordChanged('longer-password')),
      expect: () => const <AuthState>[
        AuthState(
          email: 'sarah@example.co.uk',
          password: 'longer-password',
          isSubmitting: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'a retry after a transient failure reaches submitted',
      build: () =>
          AuthBloc(repository: _FakeAuthRepository(failuresBeforeSuccess: 1)),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
      ),
      act: (bloc) => bloc
        ..add(const AuthSubmitted())
        ..add(const AuthSubmitted()),
      expect: () => const <AuthState>[
        AuthState(
          email: 'sarah@example.co.uk',
          password: 'password123',
          isSubmitting: true,
        ),
        AuthState(
          email: 'sarah@example.co.uk',
          password: 'password123',
          formError: 'Exception: offline',
        ),
        AuthState(
          email: 'sarah@example.co.uk',
          password: 'password123',
          isSubmitting: true,
        ),
        AuthState(
          email: 'sarah@example.co.uk',
          password: 'password123',
          submitted: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'editing a field after a form error clears the error',
      build: () =>
          AuthBloc(repository: _FakeAuthRepository(throwOnCreate: true)),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
        formError: 'Exception: offline',
      ),
      act: (bloc) => bloc.add(const AuthPasswordChanged('password1234')),
      expect: () => const <AuthState>[
        AuthState(email: 'sarah@example.co.uk', password: 'password1234'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'editing the email after a form error clears it too',
      build: () =>
          AuthBloc(repository: _FakeAuthRepository(throwOnCreate: true)),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
        formError: 'Exception: offline',
      ),
      act: (bloc) =>
          bloc.add(const AuthEmailChanged('sarah+tag@example.co.uk')),
      expect: () => const <AuthState>[
        AuthState(email: 'sarah+tag@example.co.uk', password: 'password123'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'a social submit leaves a stale field error alone but submits',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      seed: () => const AuthState(emailError: authEmailErrorText),
      act: (bloc) => bloc.add(const AuthSocialSubmitted(AuthProvider.google)),
      expect: () => const <AuthState>[
        AuthState(emailError: authEmailErrorText, isSubmitting: true),
        AuthState(emailError: authEmailErrorText, submitted: true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'load never disturbs an in-progress form',
      build: () => AuthBloc(repository: _FakeAuthRepository()),
      seed: () => const AuthState(
        email: 'sarah@example.co.uk',
        password: 'password123',
      ),
      act: (bloc) => bloc.add(const AuthLoadRequested()),
      expect: () => <Matcher>[
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.loading)
            .having((s) => s.email, 'email', 'sarah@example.co.uk')
            .having((s) => s.password, 'password', 'password123'),
      ],
    );
  });

  group('AuthRepository (in-memory Drift)', () {
    late AppDatabase db;
    late AuthRepositoryImpl repository;

    setUp(() {
      db = AppDatabase.memory();
      repository = AuthRepositoryImpl(db: db);
    });

    tearDown(() => db.close());

    test('watchItems emits the demo owner row', () async {
      await repository.createAccount(email: 'sarah@example.co.uk');
      final watched = await repository.watchItems().first;
      expect(watched.map((a) => a.name), contains('sarah'));
    });

    test(
      'createAccount derives the owner name from the email local-part',
      () async {
        await repository.createAccount(email: 'sarah@example.co.uk');
        expect(await repository.getItems(), hasLength(1));
        expect((await repository.getItems()).single.name, 'sarah');

        // No-op once an owner row exists (matches the shared seed behaviour).
        await repository.createAccount(email: 'other@example.co.uk');
        expect(await repository.getItems(), hasLength(1));
      },
    );

    test('an empty local-part falls back to Parent', () async {
      await repository.createAccount(email: '@example.co.uk');
      expect((await repository.getItems()).single.name, 'Parent');
    });

    test('legacy name: alias still ensures the owner row', () async {
      await repository.createAccount(name: 'Sarah');
      expect((await repository.getItems()).single.name, 'Sarah');
    });

    test('createAccountSocial ensures the owner row', () async {
      await repository.createAccountSocial(provider: AuthProvider.apple);
      expect((await repository.getItems()).single.name, 'Parent');
      await repository.createAccountSocial(provider: AuthProvider.google);
      expect(await repository.getItems(), hasLength(1));
    });

    test('a local-part with dots and plus tags is kept verbatim', () async {
      await repository.createAccount(
        email: '  sarah.jones+home@example.co.uk  ',
      );
      expect((await repository.getItems()).single.name, 'sarah.jones+home');
    });

    test('a whitespace-only local-part falls back to Parent', () async {
      await repository.createAccount(email: '   @example.co.uk');
      expect((await repository.getItems()).single.name, 'Parent');
    });

    test('an existing owner row is never renamed', () async {
      await repository.createAccount(email: 'first@example.co.uk');
      await repository.createAccount(email: 'second@example.co.uk');
      expect((await repository.getItems()).single.name, 'first');
    });

    test('the owner row carries the owner role and Owner detail', () async {
      await repository.createAccount(email: 'sarah@example.co.uk');
      final account = (await repository.getItems()).single;
      expect(account.id, 'owner');
      expect(account.role, 'owner');
      expect(account.detail, 'Owner');
      expect(account.title, account.name);
    });

    test('a second call after a social sign-in keeps one row', () async {
      await repository.createAccountSocial(provider: AuthProvider.google);
      await repository.createAccount(email: 'sarah@example.co.uk');
      expect(await repository.getItems(), hasLength(1));
    });

    test('no password column is written anywhere (local-only stub)', () async {
      await repository.createAccount(email: 'sarah@example.co.uk');
      final rows = await db.select(db.members).get();
      // The members table has no email/password columns at all — the form's
      // password can never be persisted (schema change is out of scope).
      expect(rows.single.name, 'sarah');
      expect(
        db.members.$columns.map((c) => c.name),
        isNot(contains(anyOf('email', 'password'))),
      );
    });
  });
}
