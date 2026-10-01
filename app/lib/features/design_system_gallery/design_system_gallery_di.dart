import 'package:get_it/get_it.dart';
import 'package:nestling/features/design_system_gallery/data/design_system_gallery_fake_data_source.dart';
import 'package:nestling/features/design_system_gallery/data/design_system_gallery_repository_impl.dart';
import 'package:nestling/features/design_system_gallery/domain/design_system_gallery_repository.dart';
import 'package:nestling/features/design_system_gallery/presentation/bloc/design_system_gallery_bloc.dart';

void registerDesignSystemGallery(GetIt sl) {
  if (!sl.isRegistered<DesignSystemGalleryFakeDataSource>()) {
    sl.registerLazySingleton<DesignSystemGalleryFakeDataSource>(
      () => const DesignSystemGalleryFakeDataSource(),
    );
  }
  if (!sl.isRegistered<DesignSystemGalleryRepository>()) {
    sl.registerLazySingleton<DesignSystemGalleryRepository>(
      () => DesignSystemGalleryRepositoryImpl(
        dataSource: sl<DesignSystemGalleryFakeDataSource>(),
      ),
    );
  }
  if (!sl.isRegistered<DesignSystemGalleryBloc>()) {
    sl.registerFactory<DesignSystemGalleryBloc>(
      () => DesignSystemGalleryBloc(
        repository: sl<DesignSystemGalleryRepository>(),
      ),
    );
  }
}
