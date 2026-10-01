import 'package:nestling/features/settings/data/models/settings_item_model.dart';

class SettingsFakeDataSource {
  const new();

  List<SettingsItemModel> getItems() {
    return const <SettingsItemModel>[
      SettingsItemModel(id: 'sarah', title: 'Sarah, you', detail: 'Parent'),
      SettingsItemModel(
        id: 'james',
        title: 'James, co-parent',
        detail: 'Invited',
      ),
      SettingsItemModel(
        id: 'subscription',
        title: 'Nestling Annual',
        detail: 'Renews 18 Oct 2027',
      ),
    ];
  }
}
