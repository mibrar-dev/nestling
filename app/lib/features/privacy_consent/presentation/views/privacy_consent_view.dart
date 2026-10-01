import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_state.dart';

class PrivacyConsentView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P04 Privacy & consent')),
      body: BlocBuilder<PrivacyConsentBloc, PrivacyConsentState>(
        builder: (context, state) {
          switch (state.status) {
            case PrivacyConsentStatus.initial:
            case PrivacyConsentStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case PrivacyConsentStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Something went wrong'),
              );
            case PrivacyConsentStatus.loaded:
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
