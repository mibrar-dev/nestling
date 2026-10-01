import 'package:nestling/features/today/data/models/today_item_model.dart';

class TodayFakeDataSource {
  const new();

  List<TodayItemModel> getItems() {
    return const <TodayItemModel>[
      TodayItemModel(
        id: 'dishwasher',
        title: 'Empty the dishwasher',
        detail: 'Maya, waiting for thumbs-up',
      ),
      TodayItemModel(
        id: 'biscuit',
        title: 'Feed Biscuit the cat',
        detail: 'Leo, to do',
      ),
      TodayItemModel(
        id: 'bins',
        title: 'Put the bins out',
        detail: 'Maya, approved',
      ),
    ];
  }
}
