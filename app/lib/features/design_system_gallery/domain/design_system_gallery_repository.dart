import 'package:nestling/features/design_system_gallery/domain/entities/design_system_item.dart';

abstract class DesignSystemGalleryRepository {
  Future<List<DesignSystemItem>> getItems();
}
