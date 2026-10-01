import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';

abstract class PocketMoneyRepository {
  Future<List<PocketMoneyEntry>> getItems();
}
