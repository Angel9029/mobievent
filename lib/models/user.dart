class UserModel {
  final String id;
  final String fullName;
  final String name;
  final String email;
  final String passwordHash;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.fullName,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.isAdmin = false,
  });
}
