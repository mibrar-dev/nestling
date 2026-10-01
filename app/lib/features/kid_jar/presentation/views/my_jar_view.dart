import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_bloc.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_state.dart';

class MyJarView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('K09 My jar')),
      body: BlocBuilder<KidJarBloc, KidJarState>(
        builder: (context, state) {
          switch (state.status) {
            case KidJarStatus.initial:
            case KidJarStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case KidJarStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Something went wrong'),
              );
            case KidJarStatus.loaded:
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
