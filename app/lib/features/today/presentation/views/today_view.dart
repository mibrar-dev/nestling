import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_state.dart';
import 'package:nestling/features/today/presentation/widgets/today_loaded_body.dart';

/// P08 · Today (home), route `/today`.
///
/// Chrome (tab bar, status/home) comes from ParentShell; this view renders
/// the scroll body only: greeting, approvals banner, kids 2-up grid,
/// per-child quest groups, and the kid-mode hand-off button.
class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<TodayBloc, TodayState>(
          builder: (context, state) {
            switch (state.status) {
              case TodayStatus.initial:
              case TodayStatus.loading:
                return Center(
                  child: CircularProgressIndicator(color: tokens.leaf),
                );
              case TodayStatus.failure:
                return TodayFailureBody(
                  message: state.errorMessage ?? 'Something went wrong',
                );
              case TodayStatus.loaded:
                return TodayLoadedBody(state: state);
            }
          },
        ),
      ),
    );
  }
}
