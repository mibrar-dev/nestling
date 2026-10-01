import 'package:nestling/features/auth/domain/entities/auth_account.dart';

class AuthAccountModel extends AuthAccount {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.name,
    required super.role,
  });

  factory AuthAccountModel.fromJson(Map<String, dynamic> json) {
    return AuthAccountModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'name': name,
      'role': role,
    };
  }
}
