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

  /// Sentinel distinguishing "not passed" (keep) from an explicit null
  /// (clear): without it a failure message could never be removed again.
  static const Object _unset = Object();

  PrivacyConsentState copyWith({
    PrivacyConsentStatus? status,
    List<ConsentOption>? items,
    bool? crashConsent,
    Object? errorMessage = _unset,
  }) {
    return PrivacyConsentState(
      status: status ?? this.status,
      items: items ?? this.items,
      crashConsent: crashConsent ?? this.crashConsent,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
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
