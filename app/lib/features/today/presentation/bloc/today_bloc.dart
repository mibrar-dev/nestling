import 'dart:async';

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

/// `'Happy week: 1 day'` vs `'Happy week: 4 days'`.
String happyWeekLabel(int happyDays) {
  return 'Happy week: $happyDays day${happyDays == 1 ? '' : 's'}';
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
      combineLatest3(
        combineLatest2(_repository.watchItems(), _repository.watchSummaries()),
        combineLatest2(
          _repository.watchParentName(),
          _repository.watchPayoutDay(),
        ),
        _repository.watchPendingCount(),
      ).transform(_closeOnError),
      onData: (parts) {
        final items = (parts[0] as List<dynamic>)[0] as List<TodayItem>;
        final summaries =
            (parts[0] as List<dynamic>)[1] as List<ChildDaySummary>;
        final parentName = (parts[1] as List<dynamic>)[0] as String;
        final payoutDay = (parts[1] as List<dynamic>)[1] as int;
        final pendingCount = parts[2] as int;
        var happyDays = 0;
        for (final s in summaries) {
          if (s.happyDays > happyDays) happyDays = s.happyDays;
        }
        final now = DateTime.now().toUtc();
        return state.copyWith(
          status: TodayStatus.loaded,
          items: items,
          summaries: summaries,
          pendingCount: pendingCount,
          parentName: parentName,
          greeting: dayPartForHour(toLondon(now).hour),
          dateLine: '${formatLondonDay(now)} · ${happyWeekLabel(happyDays)}',
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

/// Errors are terminal: forward the first error, then close — otherwise the
/// failed load's watchers stay subscribed and every "Try again" leaks
/// another full set (B08). Closing lets `emit.forEach` complete and cancel.
final _closeOnError =
    StreamTransformer<List<dynamic>, List<dynamic>>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        sink
          ..addError(error, stackTrace)
          ..close();
      },
    );
