import 'package:equatable/equatable.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';

enum TodayStatus { initial, loading, loaded, failure }

final class TodayState extends Equatable {
  const new({
    this.status = TodayStatus.initial,
    this.items = const <TodayItem>[],
    this.summaries = const <ChildDaySummary>[],
    this.pendingCount = 0,
    this.parentName = 'Sarah',
    this.greeting = 'Good morning',
    this.dateLine = '',
    this.happyDays = 0,
    this.payoutDay = 6,
    this.errorMessage,
  });

  final TodayStatus status;
  final List<TodayItem> items;
  final List<ChildDaySummary> summaries;

  /// Items with `status == 'done_pending'` (P08 approvals banner, P11 badge).
  final int pendingCount;
  final String parentName;

  /// Day part only ('Good morning'); the view appends `, <parentName>`.
  final String greeting;

  /// `'Sat 4 Oct · Happy week: 4 days'` (Europe/London via `london_time`).
  final String dateLine;
  final int happyDays;

  /// Payout weekday, 1 = Mon … 7 = Sun (drives `· Weekly · Sat` meta text).
  final int payoutDay;
  final String? errorMessage;

  TodayState copyWith({
    TodayStatus? status,
    List<TodayItem>? items,
    List<ChildDaySummary>? summaries,
    int? pendingCount,
    String? parentName,
    String? greeting,
    String? dateLine,
    int? happyDays,
    int? payoutDay,
    String? errorMessage,
  }) {
    return TodayState(
      status: status ?? this.status,
      items: items ?? this.items,
      summaries: summaries ?? this.summaries,
      pendingCount: pendingCount ?? this.pendingCount,
      parentName: parentName ?? this.parentName,
      greeting: greeting ?? this.greeting,
      dateLine: dateLine ?? this.dateLine,
      happyDays: happyDays ?? this.happyDays,
      payoutDay: payoutDay ?? this.payoutDay,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    summaries,
    pendingCount,
    parentName,
    greeting,
    dateLine,
    happyDays,
    payoutDay,
    errorMessage,
  ];
}
