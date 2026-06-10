class UserModel {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
      );
}
