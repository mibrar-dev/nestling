import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_bloc.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_state.dart';

class RewardShopView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('K08 Reward shop')),
      body: BlocBuilder<KidShopBloc, KidShopState>(
        builder: (context, state) {
          switch (state.status) {
            case KidShopStatus.initial:
            case KidShopStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case KidShopStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Something went wrong'),
              );
            case KidShopStatus.loaded:
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
