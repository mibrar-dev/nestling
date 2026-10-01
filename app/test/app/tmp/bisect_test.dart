import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/features/today/data/today_repository_impl.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/views/today_view.dart';
import '../../test_scope.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('A: view+bloc, no router', (tester) async {
    final db = await setUpTestScope();
    final repo = TodayRepositoryImpl(db: db);
    GetIt.instance.registerFactory<TodayBloc>(() => TodayBloc(repository: repo));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TodayBloc>(
          create: (_) => TodayBloc(repository: repo)..add(const TodayLoadRequested()),
          child: const TodayView(),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('P08 Today'), findsOneWidget);
  });

  testWidgets('B: stream only, then cancel', (tester) async {
    final db = await setUpTestScope();
    final repo = TodayRepositoryImpl(db: db);
    final sub = repo.watchItems().listen((_) {});
    await tester.pump();
    await sub.cancel();
  });
}
