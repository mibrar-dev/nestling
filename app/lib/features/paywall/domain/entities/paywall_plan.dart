import 'package:equatable/equatable.dart';

// The single annual plan (P07): £29.99/year after a 14-day trial.
class PaywallPlan extends Equatable {
  const new({required this.id, required this.title, required this.detail});

  final String id;
  final String title;
  final String detail;

  @override
  List<Object?> get props => <Object?>[id, title, detail];
}
