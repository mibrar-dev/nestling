import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/design_system_gallery/presentation/bloc/design_system_gallery_bloc.dart';
import 'package:nestling/features/design_system_gallery/presentation/bloc/design_system_gallery_event.dart';
import 'package:nestling/features/design_system_gallery/presentation/views/design_system_gallery_view.dart';
import 'package:nestling/features/design_system_gallery/presentation/views/motion_lab_view.dart';
import 'package:nestling/features/design_system_gallery/presentation/views/pip_lab_view.dart';

abstract final class DesignSystemGalleryRouteNames {
  static const String gallery = 'design-system';
  static const String motionLab = 'design-system-motion-lab';
  static const String pipLab = 'design-system-pip-lab';
}

abstract final class DesignSystemGalleryRoutePaths {
  static const String gallery = '/design-system';
  static const String motionLab = '/motion-lab';
  static const String pipLab = '/pip-lab';
}

final GoRoute designSystemGalleryRoute = GoRoute(
  path: DesignSystemGalleryRoutePaths.gallery,
  name: DesignSystemGalleryRouteNames.gallery,
  builder: (context, state) {
    return BlocProvider<DesignSystemGalleryBloc>(
      create: (_) =>
          GetIt.instance<DesignSystemGalleryBloc>()
            ..add(const DesignSystemGalleryLoadRequested()),
      child: const DesignSystemGalleryView(),
    );
  },
);

final GoRoute designSystemGalleryMotionLabRoute = GoRoute(
  path: DesignSystemGalleryRoutePaths.motionLab,
  name: DesignSystemGalleryRouteNames.motionLab,
  builder: (context, state) {
    return const MotionLabView();
  },
);

final GoRoute designSystemGalleryPipLabRoute = GoRoute(
  path: DesignSystemGalleryRoutePaths.pipLab,
  name: DesignSystemGalleryRouteNames.pipLab,
  builder: (context, state) {
    return const PipLabView();
  },
);

final List<RouteBase> designSystemGalleryRoutes = <RouteBase>[
  designSystemGalleryRoute,
  designSystemGalleryMotionLabRoute,
  designSystemGalleryPipLabRoute,
];
