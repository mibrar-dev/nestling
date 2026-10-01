import 'package:nestling/features/design_system_gallery/data/models/design_system_item_model.dart';

class DesignSystemGalleryFakeDataSource {
  const new();

  List<DesignSystemItemModel> getItems() {
    return const <DesignSystemItemModel>[
      DesignSystemItemModel(
        id: 'tokens',
        title: 'Design tokens',
        detail: 'Leaf, coin, sky, lilac, peach',
      ),
      DesignSystemItemModel(
        id: 'components',
        title: 'Components',
        detail: 'Cards, buttons, quest cards, coin pill',
      ),
    ];
  }
}
