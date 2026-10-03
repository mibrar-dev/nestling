import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_event.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_state.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_library_body.dart';

/// P10 · Quest library, route `/quests` (parent mode, Quests tab).
///
/// Chrome (tab bar, status/home) comes from the app's ParentShell; this view
/// renders the scroll body only — title, Active/Ideas segmented control, idea
/// search, the category filter row and the `.trow` list. No `AppBar`, no
/// bottom bar of its own, so nothing paints below the shell's tab bar.
class QuestLibraryView extends StatelessWidget {
  const QuestLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<QuestsBloc, QuestsState>(
          builder: (context, state) {
            switch (state.status) {
              case QuestsStatus.initial:
              case QuestsStatus.loading:
                return Center(
                  child: CircularProgressIndicator(color: tokens.leaf),
                );
              case QuestsStatus.failure:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(NestSpacing.s5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: NestSpacing.s4,
                      children: <Widget>[
                        Text(
                          state.errorMessage ?? 'Something went wrong',
                          style: NestType.body(color: tokens.ink),
                          textAlign: TextAlign.center,
                        ),
                        NestButton(
                          label: 'Try again',
                          fullWidth: false,
                          variant: NestButtonVariant.secondary,
                          onPressed: () => context.read<QuestsBloc>().add(
                            const QuestsLoadRequested(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              case QuestsStatus.loaded:
                // The bloc owns every repository read: the templates are
                // static, so they ride along in `QuestsState` instead of the
                // view probing the service locator on every build (review
                // finding 2 / BUG-P10-8).
                return QuestLibraryBody(items: state.items, ideas: state.ideas);
            }
          },
        ),
      ),
    );
  }
}
