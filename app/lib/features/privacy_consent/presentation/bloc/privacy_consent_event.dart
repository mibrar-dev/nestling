import 'package:equatable/equatable.dart';

sealed class PrivacyConsentEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class PrivacyConsentLoadRequested extends PrivacyConsentEvent {
  const new();
}
