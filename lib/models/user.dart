enum UserRole { mahasiswa, dosen, tendik, admin }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'token': token,
    };
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.mahasiswa;
    final r = role.toString().toLowerCase();
    if (r == 'admin') return UserRole.admin;
    if (r == 'dosen') return UserRole.dosen;
    if (r == 'tendik') return UserRole.tendik;
    return UserRole.mahasiswa;
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.mahasiswa:
        return 'Mahasiswa';
      case UserRole.dosen:
        return 'Dosen';
      case UserRole.tendik:
        return 'Tenaga Kependidikan';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}
