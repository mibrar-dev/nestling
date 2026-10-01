import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_event.dart';
import 'package:nestling/features/quests/presentation/views/quest_editor_view.dart';
import 'package:nestling/features/quests/presentation/views/quest_library_view.dart';

abstract final class QuestsRouteNames {
  static const String editor = 'quests-editor';
  static const String library = 'quests-library';
}

abstract final class QuestsRoutePaths {
  static const String editor = '/quest-editor';
  static const String library = '/quests';
}

final GoRoute questEditorRoute = GoRoute(
  path: QuestsRoutePaths.editor,
  name: QuestsRouteNames.editor,
  builder: (context, state) {
    return BlocProvider<QuestsBloc>(
      create: (_) =>
          GetIt.instance<QuestsBloc>()..add(const QuestsLoadRequested()),
      child: const QuestEditorView(),
    );
  },
);

final GoRoute questLibraryRoute = GoRoute(
  path: QuestsRoutePaths.library,
  name: QuestsRouteNames.library,
  builder: (context, state) {
    return BlocProvider<QuestsBloc>(
      create: (_) =>
          GetIt.instance<QuestsBloc>()..add(const QuestsLoadRequested()),
      child: const QuestLibraryView(),
    );
  },
);

final List<RouteBase> questsRoutes = <RouteBase>[
  questEditorRoute,
  questLibraryRoute,
];
