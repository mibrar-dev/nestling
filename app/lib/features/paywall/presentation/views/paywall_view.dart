import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_state.dart';

class PaywallView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P07 Paywall')),
      body: BlocBuilder<PaywallBloc, PaywallState>(
        builder: (context, state) {
          switch (state.status) {
            case PaywallStatus.initial:
            case PaywallStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case PaywallStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Something went wrong'),
              );
            case PaywallStatus.loaded:
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
