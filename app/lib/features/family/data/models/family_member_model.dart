import 'package:nestling/features/family/domain/entities/family_member.dart';

class FamilyMemberModel extends FamilyMember {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.name,
    required super.role,
    required super.inviteStatus,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      inviteStatus: json['inviteStatus'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'name': name,
      'role': role,
      'inviteStatus': inviteStatus,
    };
  }
}
