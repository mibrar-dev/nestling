import 'package:nestling/features/badges/data/models/badge_model.dart';

class BadgesFakeDataSource {
  const new();

  List<BadgeModel> getItems() {
    return const <BadgeModel>[
      BadgeModel(
        id: 'first-quest',
        title: 'First quest',
        detail: 'Earned by Maya',
      ),
      BadgeModel(id: 'bookworm', title: 'Bookworm', detail: 'Earned by Maya'),
      BadgeModel(id: 'kind-helper', title: 'Kind helper', detail: 'Keep going'),
    ];
  }
}
