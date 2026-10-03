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

/// Query-string contract for [QuestsRoutePaths.editor] (P09 new / edit quest).
///
/// `?id=<questId>` opens the editor in edit mode for that quest; absent =
/// new-quest mode. go_router needs no path declaration for query parameters:
/// `QuestEditorView` reads it via
/// `GoRouterState.of(context).uri.queryParameters[QuestsEditorQuery.questId]`
/// and loads the quest with `QuestsRepository.getQuest` (unknown id shows
/// `Quest not found` + a back link to the library).
abstract final class QuestsEditorQuery {
  static const String questId = 'id';

  /// Alias accepted for the same meaning: P08 Today pushes
  /// `/quest-editor?questId=<id>` (`today_loaded_body.dart:700`), written
  /// before this screen existed, and that file is another feature's. Reading
  /// both keys keeps every call site working without a cross-feature edit;
  /// `?id=` stays the documented contract for new callers.
  static const String legacyQuestId = 'questId';

  /// P10 Ideas tab pushes `/quest-editor?idea=<templateId>`
  /// (`quest_library_body.dart`, review finding 2). With no `?id=`, the
  /// editor seeds a NEW quest draft from `QuestsRepository.ideas()` (title,
  /// icon, coins, repeatRule, needsApproval) with a fresh id — never an
  /// update of the template row. Read next to the `?id=` handling in
  /// `QuestEditorView`; unknown idea ids fall back to the new-quest
  /// defaults.
  static const String ideaId = 'idea';
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
