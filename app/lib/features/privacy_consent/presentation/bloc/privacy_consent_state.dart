import 'package:equatable/equatable.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';

enum PrivacyConsentStatus { initial, loading, loaded, failure }

final class PrivacyConsentState extends Equatable {
  const new({
    this.status = PrivacyConsentStatus.initial,
    this.items = const <ConsentOption>[],
    this.crashConsent = false,
    this.errorMessage,
  });

  final PrivacyConsentStatus status;
  final List<ConsentOption> items;
  final bool crashConsent;
  final String? errorMessage;

  PrivacyConsentState copyWith({
    PrivacyConsentStatus? status,
    List<ConsentOption>? items,
    bool? crashConsent,
    String? errorMessage,
  }) {
    return PrivacyConsentState(
      status: status ?? this.status,
      items: items ?? this.items,
      crashConsent: crashConsent ?? this.crashConsent,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    crashConsent,
    errorMessage,
  ];
}
