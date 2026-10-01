import 'package:nestling/features/pocket_money/data/models/pocket_money_entry_model.dart';

class PocketMoneyFakeDataSource {
  const new();

  List<PocketMoneyEntryModel> getItems() {
    return const <PocketMoneyEntryModel>[
      PocketMoneyEntryModel(
        id: 'maya-owed',
        title: 'Maya is owed £4.20',
        detail: 'Payout Sat 4 Oct, base £3.00 plus quests £1.20',
      ),
      PocketMoneyEntryModel(
        id: 'lego-goal',
        title: 'Lego Friends set',
        detail: '£15.50 saved of £24.99',
      ),
    ];
  }
}
