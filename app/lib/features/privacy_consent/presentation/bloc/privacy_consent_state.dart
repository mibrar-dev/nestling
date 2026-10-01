import 'package:equatable/equatable.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';

enum PrivacyConsentStatus { initial, loading, loaded, failure }

final class PrivacyConsentState extends Equatable {
  const new({
    this.status = PrivacyConsentStatus.initial,
    this.items = const <ConsentOption>[],
    this.errorMessage,
  });

  final PrivacyConsentStatus status;
  final List<ConsentOption> items;
  final String? errorMessage;

  PrivacyConsentState copyWith({
    PrivacyConsentStatus? status,
    List<ConsentOption>? items,
    String? errorMessage,
  }) {
    return PrivacyConsentState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
