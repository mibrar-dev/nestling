import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_bloc.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_state.dart';

class BadgesView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('K11 Badges')),
      body: BlocBuilder<BadgesBloc, BadgesState>(
        builder: (context, state) {
          switch (state.status) {
            case BadgesStatus.initial:
            case BadgesStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case BadgesStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Something went wrong'),
              );
            case BadgesStatus.loaded:
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
