class FamilyModel {
  final String id;
  final String name;
  final String? inviteCode;
  final String? createdBy;
  final DateTime? createdAt;

  const FamilyModel({
    required this.id,
    required this.name,
    this.inviteCode,
    this.createdBy,
    this.createdAt,
  });

  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      inviteCode: map['invite_code'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  String get displayInviteCode {
    if (inviteCode != null && inviteCode!.trim().isNotEmpty) {
      return inviteCode!.trim().toUpperCase();
    }
    // Fallback based on ID prefix if invite_code is null in DB
    final cleanId = id.replaceAll('-', '').toUpperCase();
    return cleanId.length >= 6 ? cleanId.substring(0, 6) : cleanId;
  }
}

class FamilyMemberModel {
  final String id;
  final String? familyId;
  final String username;
  final String? fullName;
  final String? phone;
  final bool isAdmin;

  const FamilyMemberModel({
    required this.id,
    this.familyId,
    required this.username,
    this.fullName,
    this.phone,
    required this.isAdmin,
  });

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map) {
    return FamilyMemberModel(
      id: map['id'] as String,
      familyId: map['family_id'] as String?,
      username: map['username'] as String? ?? 'Unknown',
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      isAdmin: map['is_admin'] as bool? ?? false,
    );
  }

  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : username;

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
