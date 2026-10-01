import 'package:equatable/equatable.dart';

// One card of the P02 value tour (static content).
class OnboardingStep extends Equatable {
  const new({required this.id, required this.title, required this.detail});

  final String id;
  final String title;
  final String detail;

  @override
  List<Object?> get props => <Object?>[id, title, detail];
}
