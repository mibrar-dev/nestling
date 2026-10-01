import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';

class ChildProfileView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P15 Child profile')),
      body: BlocBuilder<FamilyBloc, FamilyState>(
        builder: (context, state) {
          switch (state.status) {
            case FamilyStatus.initial:
            case FamilyStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case FamilyStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Something went wrong'),
              );
            case FamilyStatus.loaded:
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
