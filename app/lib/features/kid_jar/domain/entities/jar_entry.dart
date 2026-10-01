import 'package:equatable/equatable.dart';

// Recent activity in the kid's jar (K09): pocket-money history in £/p.
class JarEntry extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.type,
    required this.amountPence,
    required this.date,
  });

  final String id;
  final String title;
  final String detail;
  final String type;
  final int amountPence;
  final DateTime date;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    type,
    amountPence,
    date,
  ];
}
