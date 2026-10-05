import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_state.dart';
import 'package:nestling/features/today/presentation/widgets/today_loaded_body.dart';

/// P08b · Today empty, route `/today-empty`.
///
/// Renders the identical widget as TodayView: the shared [TodayLoadedBody]
/// shows the P08b empty state (one empty state for the whole app) whenever
/// there are no quests.
class TodayEmptyView extends StatelessWidget {
  const TodayEmptyView({super.key});

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
                return const TodayFailureBody();
              case TodayStatus.loaded:
                return TodayLoadedBody(state: state);
            }
          },
        ),
      ),
    );
  }
}
