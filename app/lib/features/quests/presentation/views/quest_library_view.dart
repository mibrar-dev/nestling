import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_state.dart';

class QuestLibraryView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P10 Quest library')),
      body: BlocBuilder<QuestsBloc, QuestsState>(
        builder: (context, state) {
          switch (state.status) {
            case QuestsStatus.initial:
            case QuestsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case QuestsStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Something went wrong'),
              );
            case QuestsStatus.loaded:
              if (state.items.isEmpty) {
                return const Center(child: Text('No items yet'));
              }
              return ListView.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.detail),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
