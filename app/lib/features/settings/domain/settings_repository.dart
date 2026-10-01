import 'package:nestling/features/settings/domain/entities/settings_item.dart';

abstract class SettingsRepository {
  Future<List<SettingsItem>> getItems();
}
