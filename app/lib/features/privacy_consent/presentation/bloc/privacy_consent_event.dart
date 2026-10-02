import 'package:equatable/equatable.dart';

sealed class PrivacyConsentEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class PrivacyConsentLoadRequested extends PrivacyConsentEvent {
  const new();
}

final class PrivacyConsentCrashToggled extends PrivacyConsentEvent {
  const new({required this.value});

  final bool value;

  @override
  List<Object?> get props => <Object?>[value];
}
