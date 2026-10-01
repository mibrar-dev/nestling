import 'package:nestling/features/design_system_gallery/data/design_system_gallery_fake_data_source.dart';
import 'package:nestling/features/design_system_gallery/domain/design_system_gallery_repository.dart';
import 'package:nestling/features/design_system_gallery/domain/entities/design_system_item.dart';

class DesignSystemGalleryRepositoryImpl
    implements DesignSystemGalleryRepository {
  const new({required this._dataSource});

  final DesignSystemGalleryFakeDataSource _dataSource;

  @override
  Future<List<DesignSystemItem>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
