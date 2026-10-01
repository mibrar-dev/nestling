import 'package:nestling/features/today/domain/entities/today_item.dart';

abstract class TodayRepository {
  Future<List<TodayItem>> getItems();
}
