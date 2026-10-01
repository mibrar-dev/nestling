import 'package:nestling/features/settings/data/settings_fake_data_source.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const new({required this._dataSource});

  final SettingsFakeDataSource _dataSource;

  @override
  Future<List<SettingsItem>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
