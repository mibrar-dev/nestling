import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/bloc/today_state.dart';

/// Day part of the P08 greeting for a Europe/London wall-clock hour.
String dayPartForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class TodayBloc extends Bloc<TodayEvent, TodayState> {
  new({required this._repository}) : super(const TodayState()) {
    on<TodayLoadRequested>(_onLoadRequested);
  }

  final TodayRepository _repository;

  Future<void> _onLoadRequested(
    TodayLoadRequested event,
    Emitter<TodayState> emit,
  ) async {
    emit(state.copyWith(status: TodayStatus.loading));
    await emit.forEach<List<dynamic>>(
      combineLatest2(
        combineLatest2(_repository.watchItems(), _repository.watchSummaries()),
        combineLatest2(
          _repository.watchParentName(),
          _repository.watchPayoutDay(),
        ),
      ),
      onData: (parts) {
        final items = (parts[0] as List<dynamic>)[0] as List<TodayItem>;
        final summaries =
            (parts[0] as List<dynamic>)[1] as List<ChildDaySummary>;
        final parentName = (parts[1] as List<dynamic>)[0] as String;
        final payoutDay = (parts[1] as List<dynamic>)[1] as int;
        final pendingCount = items
            .where((i) => i.status == 'done_pending')
            .length;
        var happyDays = 0;
        for (final s in summaries) {
          if (s.happyDays > happyDays) happyDays = s.happyDays;
        }
        final nowLondon = toLondon(DateTime.now().toUtc());
        return state.copyWith(
          status: TodayStatus.loaded,
          items: items,
          summaries: summaries,
          pendingCount: pendingCount,
          parentName: parentName,
          greeting: dayPartForHour(nowLondon.hour),
          dateLine:
              '${formatLondonDay(DateTime.now().toUtc())} · Happy week: $happyDays days',
          happyDays: happyDays,
          payoutDay: payoutDay,
        );
      },
      onError: (error, _) => state.copyWith(
        status: TodayStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
